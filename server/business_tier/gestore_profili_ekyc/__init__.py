"""! @package server.business_tier.gestore_profili_ekyc
@brief Profili utente e verifica documentale KYC.
"""

from __future__ import annotations

import re
import secrets
import string
from datetime import UTC, datetime, timedelta
from typing import TYPE_CHECKING, Any

from passlib.context import CryptContext

from server.integration_tier.data_access_manager import ErrorePersistenza, ottieni_dao_opzionale
from server.integration_tier.gateway_email import GatewayEmail
from server.integration_tier.gateway_pagamenti import GatewayPagamenti

if TYPE_CHECKING:
    from server.integration_tier.data_access_manager import DataAccessManager

#! Formati documentali KYC ammessi (IIN-6 / AG-SEC-01). Tutto il resto va bloccato.
FORMATI_KYC_AMMESSI: frozenset[str] = frozenset({".pdf", ".jpg", ".jpeg", ".png"})
#! Contesto di hashing password (Passlib, schema pbkdf2_sha256: Â§6, puro Python).
_CTX_PASSWORD = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")
#! Lunghezza minima della password (IIN-5).
_PASSWORD_MIN = 8
#! ValiditÃ  (minuti) del link/codice di reset password (IIN-11, monouso).
RESET_TTL_MINUTI = 15
#! Campi del profilo aggiornabili dall'utente via API (whitelist, UT.21).
CAMPI_PROFILO_MODIFICABILI: frozenset[str] = frozenset(
    {"nome", "cognome", "telefono", "data_nascita", "residenza"}
)
#! Campi di account mai esposti nella vista profilo pubblica (redazione, IIN-4/IIN-13).
_CAMPI_ACCOUNT_RISERVATI: frozenset[str] = frozenset(
    {"password_hash", "tentativi_falliti", "bloccato_fino"}
)
#! Stati account gestibili manualmente dall'operatore (OP.10 sospendi / OP.18 sblocca).
#! "eliminato" non Ã¨ impostabile da questa via (lifecycle separato, data-retention IIN-17).
STATI_ACCOUNT_GESTIBILI: frozenset[str] = frozenset({"attivo", "sospeso"})
#! Tipi di consenso GDPR ammessi (valore della @ref TipoConsenso, IIN-16).
TIPI_CONSENSO: frozenset[str] = frozenset({"geolocalizzazione", "marketing", "trattamento_dati"})
#! Tipi di documento ufficiale ammessi per il KYC (valore della @ref TipoDocumento, UT.22.2).
TIPI_DOCUMENTO_KYC: frozenset[str] = frozenset({"patente", "carta_identita"})
#! Token inclusi di default in un abbonamento quando il piano non li specifica (punto 7).
#! ASSUNZIONE da confermare col team: 1 token = 1 corsa coperta dall'abbonamento.
TOKEN_ABBONAMENTO_DEFAULT = 50


def _genera_password_temporanea(lunghezza: int = 14) -> str:
    """! @brief Genera una password temporanea casuale conforme a IIN-5 (provisioning PA, OP.17).

    Garantisce almeno una maiuscola, una cifra e un carattere speciale (politica IIN-5);
    il resto Ã¨ riempito da un alfabeto misto. Usa @c secrets (CSPRNG). Replica la logica
    di @ref server.runtime.provisioning_op.ProvisioningOP senza importarla, per non far
    dipendere il Business Tier dal runtime (Â§4: tier isolati dai framework di piattaforma).

    @param lunghezza Lunghezza totale (>= 8).
    @return Password in chiaro, mostrata una sola volta all'operatore che la provisiona.
    """
    lunghezza = max(8, lunghezza)
    speciali = "!@#$%?*-_"
    obbligatori = [
        secrets.choice(string.ascii_uppercase),
        secrets.choice(string.ascii_lowercase),
        secrets.choice(string.digits),
        secrets.choice(speciali),
    ]
    alfabeto = string.ascii_letters + string.digits + speciali
    resto = [secrets.choice(alfabeto) for _ in range(lunghezza - len(obbligatori))]
    caratteri = obbligatori + resto
    secrets.SystemRandom().shuffle(caratteri)
    return "".join(caratteri)


def password_conforme(password: str) -> bool:
    """! @brief Verifica la robustezza minima della password (IIN-5).

    Politica IIN-5: almeno 8 caratteri, con almeno una maiuscola, una cifra e un
    carattere speciale (non alfanumerico).

    @param password Password in chiaro da validare.
    @return True se la password rispetta la politica, False altrimenti.
    """
    if len(password) < _PASSWORD_MIN:
        return False
    return bool(
        re.search(r"[A-Z]", password)
        and re.search(r"\d", password)
        and re.search(r"[^A-Za-z0-9]", password)
    )


def _normalizza_indirizzo(indirizzo: str) -> str:
    """! @brief Normalizza un indirizzo per il confronto residenzaâ†”fatturazione (punto 4).

    Confronto tollerante a maiuscole/minuscole e spaziatura ridondante: minuscolizza,
    comprime gli spazi interni e rimuove gli spazi ai bordi. Non altera la punteggiatura,
    sufficiente a verificare la coincidenza richiesta senza falsi negativi banali.

    @param indirizzo Indirizzo grezzo inserito dall'utente.
    @return Forma normalizzata per il confronto di uguaglianza.
    """
    return " ".join(indirizzo.lower().split())


def _token_reset_valido(token: dict[str, Any], codice: str) -> bool:
    """! @brief Verifica scadenza e corrispondenza del codice di reset (IIN-11, monouso).

    Il token e' valido solo se non e' scaduto (campo `scadenza` ISO 8601 UTC ancora futuro)
    e il `codice` fornito combacia con l'hash Passlib memorizzato. Usa @c verify a tempo
    costante; ogni campo malformato e' trattato come token non valido.

    @param token Documento token {codice_hash, scadenza}.
    @param codice Codice monouso fornito dall'utente.
    @return True se il token e' integro, non scaduto e il codice corrisponde.
    """
    scadenza = token.get("scadenza")
    codice_hash = token.get("codice_hash")
    if not isinstance(scadenza, str) or not isinstance(codice_hash, str):
        return False
    try:
        if datetime.fromisoformat(scadenza) <= datetime.now(UTC):
            return False
    except ValueError:  # pragma: no cover - timestamp malformato
        return False
    return _CTX_PASSWORD.verify(codice, codice_hash)


class GestoreProfiliEkyc:
    """! @brief Gestisce profili e onboarding documentale (UT.22.1/UT.22.2, IIN-6).

    Responsabilita': creazione profilo, validazione formato KYC (solo PDF/JPG/PNG,
    blocco server-side delle altre estensioni), stato di idoneita' alla guida,
    autenticazione delle credenziali (IIN-1/IIN-5). La persistenza cifrata (AES-256)
    e' delegata al @ref DataAccessManager (Integration Tier, tier adiacente Â§4).

    @param dao DataAccessManager opzionale; se None viene risolto dall'ambiente
               (@ref ottieni_dao_opzionale) â€” None finche' la persistenza non e' configurata.
    """

    def __init__(
        self,
        dao: DataAccessManager | None = None,
        pagamenti: GatewayPagamenti | None = None,
        email: GatewayEmail | None = None,
    ) -> None:
        """! @brief Costruisce il gestore, opzionalmente con DAO e gateway iniettati (test).
        @param dao DataAccessManager da usare; se None risolto dall'ambiente.
        @param pagamenti Gateway pagamenti per la validazione carta (default sim. locale).
        @param email Gateway email per gli invii transazionali (default sim. locale,
            no-op senza app password).
        """
        self._dao = dao
        self._pagamenti = pagamenti or GatewayPagamenti()
        self._email = email or GatewayEmail()

    def formato_kyc_valido(self, nome_file: str) -> bool:
        """! @brief Verifica che l'estensione del documento KYC sia ammessa (IIN-6).
        @param nome_file Nome o percorso del file caricato.
        @return True se l'estensione e' PDF/JPG/PNG, False altrimenti.
        """
        nome = nome_file.lower()
        return any(nome.endswith(ext) for ext in FORMATI_KYC_AMMESSI)

    def autentica(self, email: str, password: str) -> dict[str, object]:
        """! @brief Autentica un soggetto verificando le credenziali su Firestore (IIN-1/IIN-5).

        Legge l'account per email tramite il DataAccessManager e verifica la password
        contro l'hash Passlib, applicando il lockout per tentativi falliti (IIN-10). Per
        OP/PA segnala che serve il secondo fattore MFA (IIN-9): la verifica OTP e
        l'emissione del token di sessione sono gestite da @ref ApiGatewaySicurezza.

        @param email Email/username di accesso.
        @param password Password in chiaro.
        @return Esito {autenticato, bloccato?, ruolo?, idAccount?, mfaRichiesto?}.
        @throws NotImplementedError Se la persistenza non e' configurata (slice "in sviluppo", Â§9).
        """
        dao = self._dao or ottieni_dao_opzionale()
        if dao is None:
            raise NotImplementedError("DataAccessManager/DB in sviluppo")
        account = dao.leggi_account_per_email(email)
        if account is None:
            account = dao.leggi_account_per_username(email)
        if account is None:
            return {"autenticato": False}
        if dao.account_bloccato(account):  # lockout attivo (IIN-10)
            return {"autenticato": False, "bloccato": True}
        if account.get("stato_account") == "sospeso":  # sospensione manuale OP.10
            return {"autenticato": False, "sospeso": True}
        if not dao.verifica_credenziali(account, password):
            esito_fallito = dao.registra_tentativo_fallito(account)
            return {"autenticato": False, "bloccato": esito_fallito["bloccato"]}
        dao.registra_accesso_riuscito(str(account.get("_id")))  # reset lockout + ultimo accesso
        ruolo = account.get("ruolo")
        if ruolo == "UT":
            # Avviso di sicurezza best-effort: nuovo accesso al proprio account. Per UT il
            # login si conclude qui (senza MFA); per OP/PA l'accesso completa dopo l'OTP.
            self._notifica_accesso(str(account.get("email") or ""))
        return {
            "autenticato": True,
            "ruolo": ruolo,
            "idAccount": account.get("_id"),
            "email": account.get("email"),  # recapito per l'OTP via email (IIN-9, punto 15)
            "mfaRichiesto": ruolo in ("OP", "PA"),  # MFA obbligatorio per OP/PA (IIN-9)
        }

    def _notifica_accesso(self, email: str) -> None:
        """! @brief Email best-effort di avviso "nuovo accesso" all'utente UT (IIN-13).

        Avvisa l'utente di un nuovo accesso riuscito al proprio account sull'indirizzo
        registrato. Best-effort: senza app password Ã¨ un no-op (gateway disattivato) e non
        interrompe il login; eventuali errori SMTP sono assorbiti dal @ref GatewayEmail.

        @param email Indirizzo email registrato dell'utente.
        @return Nessuno.
        """
        if not email or not self._email.configurato:
            return
        from datetime import UTC, datetime

        istante = datetime.now(UTC).strftime("%d/%m/%Y %H:%M UTC")
        self._email.invia(
            email,
            "LEAF Mobility - Nuovo accesso al tuo account",
            f"Ciao,\n\nabbiamo registrato un nuovo accesso al tuo account LEAF Mobility "
            f"il {istante}.\n\nSe non sei stato tu, contatta subito l'assistenza "
            "(support@leafmobility.example.com) e cambia la password.\n\nIl team LEAF Mobility\n",
        )

    def invia_otp(self, email: str, otp: str) -> None:
        """! @brief Invia via email l'OTP di accesso MFA (IIN-9, punto 15), best-effort e asincrono.

        Recapita l'OTP fuori banda all'indirizzo registrato. Il gateway di sicurezza
        (Presentation) genera l'OTP e delega qui l'invio per non importare l'Integration
        Tier (vincolo Â§4). L'invio Ã¨ **non bloccante** (thread daemon): il login OP/PA
        risponde subito senza attendere la connessione SMTP (~1-3s), che altrimenti
        rallenterebbe l'accesso alla dashboard bloccando l'event loop. Best-effort: senza
        app password Ã¨ un no-op e non interrompe mai il login.

        @param email Indirizzo email del destinatario.
        @param otp Codice OTP generato dal gateway di sicurezza.
        @return Nessuno (invio delegato in background; l'esito Ã¨ tracciato nei log).
        """
        self._email.invia_in_background(
            email,
            "LEAF Mobility - Codice di accesso OTP",
            f"Il tuo codice di accesso (OTP) e': {otp}\nScade tra pochi minuti (IIN-9).",
        )

    def _dao_o_errore(self) -> DataAccessManager:
        """! @brief Restituisce il DAO disponibile o segnala la persistenza in sviluppo.
        @return DataAccessManager pronto.
        @throws NotImplementedError Se la persistenza non e' configurata (slice "in sviluppo", Â§9).
        """
        dao = self._dao or ottieni_dao_opzionale()
        if dao is None:
            raise NotImplementedError("DataAccessManager/DB in sviluppo")
        return dao

    def registra(
        self,
        email: str,
        username: str,
        password: str,
        *,
        data_nascita: str | None = None,
        nome: str | None = None,
        cognome: str | None = None,
        residenza: str | None = None,
    ) -> str:
        """! @brief Registra un nuovo utente finale UT con credenziali (UT.22.1, IIN-5).

        Valida la robustezza della password (IIN-5), ne calcola l'hash Passlib (mai in
        chiaro) e crea l'Account UT e il profilo a chiave condivisa in transazione tramite
        @ref DataAccessManager.crea_account. Email e username sono univoci (registri Â§6.4):
        un duplicato solleva @c ViolazioneUnicita (mappata a 409 dalla Presentation).

        @param email Email di accesso univoca (IIN-1).
        @param username Username univoco scelto dall'utente.
        @param password Password in chiaro (validata IIN-5, mai persistita).
        @param data_nascita Data di nascita ISO-8601 (opzionale, UT.22.1; etÃ  â†’ verifica documenti).
        @param nome Nome anagrafico (opzionale, UT.22.1; campo ðŸ”’).
        @param cognome Cognome anagrafico (opzionale, UT.22.1; campo ðŸ”’).
        @param residenza Indirizzo di residenza, usato anche come indirizzo di fatturazione
                         (opzionale, UT.22.1; coincide con la via di fatturazione, punto 4/5).
        @return Id dell'account creato (= id del profilo).
        @throws ValueError Se la password non rispetta la politica IIN-5.
        @throws NotImplementedError Se la persistenza non e' configurata.
        @throws ViolazioneUnicita Se email o username sono gia' registrati.
        """
        if not password_conforme(password):
            raise ValueError(
                "Password non conforme: minimo 8 caratteri con maiuscola, cifra e simbolo (IIN-5)"
            )
        dao = self._dao_o_errore()
        profilo: dict[str, Any] = {}
        if data_nascita:
            profilo["data_nascita"] = data_nascita
        if nome:
            profilo["nome"] = nome
        if cognome:
            profilo["cognome"] = cognome
        if residenza:
            profilo["residenza"] = residenza
        return dao.crea_account(
            "UT",
            email,
            _CTX_PASSWORD.hash(password),
            profilo,
            username=username,
        )

    def cambia_password(self, id_account: str, nuova_password: str) -> dict[str, Any]:
        """! @brief Cambia la password dell'account, obbligatoria al primo accesso (IIN-12).

        Valida la robustezza (IIN-5), ricalcola l'hash Passlib e azzera il flag
        `password_temporanea` (per AP/OP provisionati, OP.17): completato il cambio,
        l'account non Ã¨ piÃ¹ in stato di primo accesso forzato.

        @param id_account Id dell'account autenticato.
        @param nuova_password Nuova password in chiaro (validata IIN-5).
        @return {id_account, password_aggiornata}.
        @throws ValueError Se la password non rispetta IIN-5 o l'account non esiste.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        if not password_conforme(nuova_password):
            raise ValueError(
                "Password non conforme: minimo 8 caratteri con maiuscola, cifra e simbolo (IIN-5)"
            )
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        account = dao.leggi(col.ACCOUNT, id_account)
        if account is None:
            raise ValueError(f"Account '{id_account}' inesistente")
        dao.aggiorna(
            col.ACCOUNT,
            id_account,
            {"password_hash": _CTX_PASSWORD.hash(nuova_password), "password_temporanea": False},
        )
        return {"id_account": id_account, "password_aggiornata": True}

    def richiede_cambio_password(self, id_account: str) -> bool:
        """! @brief Indica se l'account deve cambiare la password al primo accesso (IIN-12).

        Legge il flag `password_temporanea` dell'account (impostato da @ref provisiona_operatore
        / @ref provisiona_amministrazione per OP/PA, azzerato da @ref cambia_password): finchÃ© Ã¨
        attivo l'accesso alla dashboard Ã¨ in stato di primo accesso forzato.

        @param id_account Id dell'account autenticato.
        @return True se Ã¨ richiesto il cambio password obbligatorio, False altrimenti.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        account = dao.leggi(col.ACCOUNT, id_account)
        return bool(account and account.get("password_temporanea"))

    # â”€â”€ Dispositivi attivi al login/logout (IIN-14 / Â§6.1 #8) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    def registra_dispositivo(self, id_utente: str, device_id: str) -> str:
        """! @brief Registra un dispositivo attivo applicando il limite di 3 (IIN-14).

        Delega all'Integration Tier (@ref DataAccessManager.registra_dispositivo) il vincolo
        transazionale: il Business Tier media l'accesso ai dati per il gateway di sicurezza,
        che non tocca mai direttamente l'Integration Tier (Â§4).

        @param id_utente Id dell'utente (= id_account) che accede.
        @param device_id Identificativo stabile del dispositivo.
        @return Id del documento dispositivo registrato.
        @throws LimiteDispositivi Se l'utente ha giÃ  3 dispositivi attivi (IIN-14).
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        return self._dao_o_errore().registra_dispositivo(id_utente, device_id)

    def rimuovi_dispositivo(self, id_utente: str, device_id: str) -> bool:
        """! @brief Libera lo slot di un dispositivo al logout (IIN-14).
        @param id_utente Id dell'utente (= id_account).
        @param device_id Identificativo del dispositivo da disattivare.
        @return True se uno slot Ã¨ stato liberato, False se non c'era nulla da liberare.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        return self._dao_o_errore().rimuovi_dispositivo(id_utente, device_id)

    def richiedi_reset(self, identita: str) -> dict[str, object]:
        """! @brief Avvia il reset della password via email registrata (UT.24/AP.12, IIN-11).

        Per non rivelare l'esistenza di un account (anti-enumerazione), restituisce sempre
        un esito positivo. Se l'account esiste, genera un codice monouso a validitÃ  limitata
        (@ref RESET_TTL_MINUTI). Non essendo cablato un gateway email (Â§3, simulazione locale),
        il codice Ã¨ restituito nel campo `codice_simulato` solo in questa modalitÃ  di sviluppo:
        in produzione sarebbe recapitato fuori banda all'indirizzo registrato.

        @param identita Email/username dichiarato dall'utente.
        @return Esito {inviato: True, scadenza_minuti, codice_simulato?}.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        account = dao.leggi_account_per_email(identita)
        if account is None:
            account = dao.leggi_account_per_username(identita)
        esito: dict[str, object] = {"inviato": True, "scadenza_minuti": RESET_TTL_MINUTI}
        if account is not None:
            codice = f"{secrets.randbelow(1_000_000):06d}"
            scadenza = (datetime.now(UTC) + timedelta(minutes=RESET_TTL_MINUTI)).isoformat()
            dao.memorizza_token_reset(str(account["_id"]), _CTX_PASSWORD.hash(codice), scadenza)
            esito["codice_simulato"] = codice
            # Punto 15: invio email best-effort del codice di reset (no-op senza app password).
            # Asincrono: la richiesta di reset non attende la connessione SMTP (~1-3s).
            self._email.invia_in_background(
                str(account.get("email") or ""),
                "LEAF Mobility - Reset della password",
                f"Il tuo codice di reset e': {codice}\n"
                f"E' valido {RESET_TTL_MINUTI} minuti ed e' monouso (IIN-11).",
            )
        return esito

    def conferma_reset(
        self, identita: str, codice: str, nuova_password: str | None = None
    ) -> dict[str, object]:
        """! @brief Conferma il reset password con codice monouso e imposta la nuova (IIN-11).

        Verifica il token emesso da @ref richiedi_reset: deve esistere, non essere scaduto
        (@ref RESET_TTL_MINUTI) e il codice deve combaciare con l'hash memorizzato. Al successo
        aggiorna l'hash password (IIN-5), azzera il flag `password_temporanea` e consuma il
        token (monouso). Mantiene la semantica anti-enumerazione: un esito negativo non rivela
        se a fallire e' l'identita', il codice o la scadenza. Se `nuova_password` Ã¨ omessa,
        viene generata una password casuale temporanea.

        @param identita Email/username dichiarato dall'utente (UT.24/AP.12).
        @param codice Codice monouso ricevuto fuori banda.
        @param nuova_password Nuova password in chiaro (validata IIN-5). Opzionale.
        @return Esito {reimpostata: bool, requires_password_change: bool, id_account, ruolo}.
        @throws ValueError Se la nuova password non rispetta la politica IIN-5.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        if nuova_password is not None and not password_conforme(nuova_password):
            raise ValueError(
                "Password non conforme: minimo 8 caratteri con maiuscola, cifra e simbolo (IIN-5)"
            )
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        account = dao.leggi_account_per_email(identita)
        if account is None:
            account = dao.leggi_account_per_username(identita)
        if account is None:
            return {"reimpostata": False}
        id_account = str(account["_id"])
        token = dao.leggi_token_reset(id_account)
        if token is None or not _token_reset_valido(token, codice):
            return {"reimpostata": False}

        if nuova_password is not None:
            temp_pass = False
            hash_pass = _CTX_PASSWORD.hash(nuova_password)
        else:
            temp_pass = True
            hash_pass = _CTX_PASSWORD.hash(_genera_password_temporanea())

        dao.aggiorna(
            col.ACCOUNT,
            id_account,
            {"password_hash": hash_pass, "password_temporanea": temp_pass},
        )
        dao.elimina_token_reset(id_account)
        return {
            "reimpostata": True,
            "id_account": id_account,
            "ruolo": str(account.get("ruolo", "")),
            "richiede_cambio_password": temp_pass,
        }

    def profilo(self, id_account: str) -> dict[str, Any]:
        """! @brief Vista profilo dell'utente autenticato, con dati riservati redatti (UT.21).

        Compone i dati di account (esclusi i campi riservati: hash password, lockout) con
        il documento di profilo a chiave condivisa (utenti/operatori/amministrazioni).

        @param id_account Id dell'account autenticato.
        @return Vista pubblica del profilo (mai contenente `password_hash`).
        @throws NotImplementedError Se la persistenza non e' configurata.
        @throws ValueError Se l'account non esiste.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        account = dao.leggi(col.ACCOUNT, id_account)
        if account is None:
            raise ValueError(f"Account '{id_account}' inesistente")
        vista: dict[str, Any] = {
            chiave: valore
            for chiave, valore in account.items()
            if chiave not in _CAMPI_ACCOUNT_RISERVATI
        }
        profilo = dao.leggi_profilo(account)
        if profilo is not None:
            vista["profilo"] = profilo
        return vista

    def aggiorna_profilo(self, id_account: str, modifiche: dict[str, Any]) -> dict[str, Any]:
        """! @brief Aggiorna i dati anagrafici del profilo utente (UT.21).

        Applica solo i campi della whitelist @ref CAMPI_PROFILO_MODIFICABILI sul documento
        di profilo a chiave condivisa; ignora qualsiasi altro campo (no privilege escalation).

        @param id_account Id dell'account autenticato.
        @param modifiche Coppie campoâ†’valore proposte dal client.
        @return Vista profilo aggiornata (@ref profilo).
        @throws NotImplementedError Se la persistenza non e' configurata.
        @throws ValueError Se l'account non esiste o nessun campo Ã¨ aggiornabile.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        account = dao.leggi(col.ACCOUNT, id_account)
        if account is None:
            raise ValueError(f"Account '{id_account}' inesistente")
        ammesse = {
            chiave: valore
            for chiave, valore in modifiche.items()
            if chiave in CAMPI_PROFILO_MODIFICABILI
        }
        if not ammesse:
            raise ValueError("Nessun campo aggiornabile nella richiesta")
        collezione = col.MAP_RUOLO_COLLEZIONE[str(account.get("ruolo"))]
        dao.aggiorna(collezione, id_account, ammesse)
        return self.profilo(id_account)

    # â”€â”€ Amministrazione account (OP.10/OP.17/OP.18) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    def elenca_account(self, ruolo: str | None = None) -> list[dict[str, Any]]:
        """! @brief Elenca gli account per la gestione operatore, campi riservati redatti (OP.10).

        Vista gestionale (â‰  @ref profilo, che Ã¨ la self-view dell'utente): restituisce gli
        account con stato_account e ruolo per consentire all'operatore sospensione/sblocco;
        i campi segreti (@ref _CAMPI_ACCOUNT_RISERVATI) non sono mai esposti.

        @param ruolo Filtro opzionale sul ruolo RBAC (UT/OP/PA); None = tutti.
        @return Lista di account con campi non riservati (mai `password_hash`).
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        filtri = [("ruolo", "==", ruolo)] if ruolo else None
        risultato: list[dict[str, Any]] = []
        for a in dao.elenca(col.ACCOUNT, filtri=filtri):
            vista = {c: v for c, v in a.items() if c not in _CAMPI_ACCOUNT_RISERVATI}
            vista["nominativo"] = self._nominativo(dao, a)
            risultato.append(vista)
        return risultato

    @staticmethod
    def _nominativo(dao: DataAccessManager, account: dict[str, Any]) -> str:
        """! @brief Ricava un'etichetta leggibile dell'account dal profilo a chiave condivisa.

        Per UT/OP compone "Nome Cognome"; per PA usa l'ente. In assenza del profilo (o dei
        campi) ripiega su username/email, cosÃ¬ la vista gestionale non resta mai senza
        etichetta. I campi ðŸ”’ (nome/cognome) sono giÃ  decifrati da @ref DataAccessManager.leggi.

        @param dao DataAccessManager connesso.
        @param account Documento account (con `_id` e `ruolo`).
        @return Etichetta leggibile del titolare dell'account.
        """
        profilo = dao.leggi_profilo(account) or {}
        if account.get("ruolo") == "PA":
            ente = profilo.get("ente")
            if ente:
                return str(ente)
        else:
            nominativo = " ".join(str(profilo[c]) for c in ("nome", "cognome") if profilo.get(c))
            if nominativo:
                return nominativo
        return str(account.get("username") or account.get("email") or "")

    def imposta_stato_account(self, id_account: str, stato: str) -> dict[str, Any]:
        """! @brief Sospende o riattiva un account utente (OP.10 sospendi / OP.18 sblocca).

        OP.10: sospendere inibisce l'accesso ai servizi di prenotazione/noleggio (il check Ã¨ in
        @ref autentica). OP.18: riattivare ripristina l'accesso. Lo stato "eliminato" non Ã¨
        impostabile da qui (lifecycle/retention separato, IIN-17).

        @param id_account Id dell'account su cui agire.
        @param stato Nuovo stato: "attivo" oppure "sospeso".
        @return Vista account aggiornata (campi riservati redatti).
        @throws ValueError Se lo stato non e' gestibile o l'account non esiste.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        if stato not in STATI_ACCOUNT_GESTIBILI:
            raise ValueError(f"Stato account non gestibile: {stato}")
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        account = dao.leggi(col.ACCOUNT, id_account)
        if account is None:
            raise ValueError(f"Account '{id_account}' inesistente")
        dao.aggiorna(col.ACCOUNT, id_account, {"stato_account": stato})
        aggiornato = dao.leggi(col.ACCOUNT, id_account) or {}
        return {c: v for c, v in aggiornato.items() if c not in _CAMPI_ACCOUNT_RISERVATI}

    def provisiona_amministrazione(
        self,
        email: str,
        username: str,
        ente: str,
        email_istituzionale: str,
    ) -> dict[str, Any]:
        """! @brief Crea un account Amministrazione Pubblica con password temporanea (OP.17/IIN-12).

        L'operatore provisiona l'accesso PA (no registrazione pubblica): genera una password
        temporanea robusta (IIN-5), ne salva solo l'hash, marca l'account `password_temporanea`
        (cambio obbligatorio al primo accesso, IIN-12) e abilita l'MFA (IIN-9, giÃ  imposto da
        @ref DataAccessManager.crea_account per ruolo PA). Email/username univoci (registri Â§6.4).

        @param email Email di accesso istituzionale univoca (IIN-1).
        @param username Username univoco dell'account PA.
        @param ente Nome dell'ente di Amministrazione Pubblica.
        @param email_istituzionale Email istituzionale per il reset credenziali (AP.12).
        @return {id_account, password_temporanea} â€” la password va mostrata una sola volta.
        @throws NotImplementedError Se la persistenza non e' configurata.
        @throws ViolazioneUnicita Se email o username sono gia' registrati.
        """
        dao = self._dao_o_errore()
        temporanea = _genera_password_temporanea()
        id_account = dao.crea_account(
            "PA",
            email,
            _CTX_PASSWORD.hash(temporanea),
            {"ente": ente, "email_istituzionale": email_istituzionale},
            username=username,
            extra={"password_temporanea": True},  # IIN-12: cambio obbligatorio al 1Â° accesso
        )
        # Punto 15 / IIN-12: invio email best-effort della password temporanea
        # (no-op senza app password). Asincrono: il provisioning dalla dashboard non
        # attende la connessione SMTP (~1-3s).
        self._email.invia_in_background(
            email_istituzionale,
            "LEAF Mobility - Primo accesso",
            f"Account creato per l'ente {ente}.\nUsername: {username}\n"
            f"Password temporanea (da cambiare al primo accesso, IIN-12): {temporanea}",
        )
        return {"id_account": id_account, "password_temporanea": temporanea}

    def provisiona_operatore(
        self,
        email: str,
        username: str,
        nome: str,
    ) -> dict[str, Any]:
        """! @brief Crea un account Operatore con password temporanea (OP.17/IIN-12).

        Simmetrico a @ref provisiona_amministrazione: genera una password temporanea
        robusta (IIN-5), ne salva solo l'hash, marca l'account `password_temporanea`
        (cambio obbligatorio al primo accesso, IIN-12) e abilita l'MFA (IIN-9).
        Email/username univoci (registri Â§6.4): un duplicato solleva @c ViolazioneUnicita.

        @param email Email di accesso univoca (IIN-1).
        @param username Username univoco dell'operatore.
        @param nome Nome completo dell'operatore (campo del profilo).
        @return {id_account, email, nome, password_temporanea}.
        @throws NotImplementedError Se la persistenza non e' configurata.
        @throws ViolazioneUnicita Se email o username sono gia' registrati.
        """
        dao = self._dao_o_errore()
        temporanea = _genera_password_temporanea()
        id_account = dao.crea_account(
            "OP",
            email,
            _CTX_PASSWORD.hash(temporanea),
            {"nome": nome},
            username=username,
            extra={"password_temporanea": True},
        )
        # Punto 15 / IIN-12: invio email best-effort della password temporanea
        # (no-op senza app password). Asincrono: il provisioning dalla dashboard non
        # attende la connessione SMTP (~1-3s).
        self._email.invia_in_background(
            email,
            "LEAF Mobility - Primo accesso operatore",
            f"Account operatore creato.\nUsername: {username}\n"
            f"Password temporanea (da cambiare al primo accesso, IIN-12): {temporanea}",
        )
        return {
            "id_account": id_account,
            "email": email,
            "nome": nome,
            "password_temporanea": temporanea,
        }

    # â”€â”€ Profilo esteso: pagamenti, abbonamenti, consensi, KYC (UT.11/18/22.2) â”€â”€
    def registra_metodo_pagamento(
        self,
        id_utente: str,
        numero: str,
        mese: int,
        anno: int,
        titolare: str,
        *,
        cvv: str | None = None,
        indirizzo_fatturazione: str | None = None,
    ) -> dict[str, Any]:
        """! @brief Registra un metodo di pagamento verificato nel profilo (UT.11, punto 4).

        Tokenizza la carta tramite il gateway pagamenti (simulazione locale Â§13): il PAN
        in chiaro NON Ã¨ mai persistito (PCI) â€” si salva solo il PAN mascherato e un token
        provider ðŸ”’ (cifrato at-rest, IIN-4) nella subcollezione `metodi_pagamento`. Il
        **CVV (codice di sicurezza a 3 cifre)** Ã¨ verificato ma **mai persistito** (PCI). L'
        **indirizzo di fatturazione** Ã¨ obbligatorio e deve **coincidere con la residenza**
        del profilo (punto 4/5): se differisce la registrazione Ã¨ rifiutata.

        @param id_utente Id dell'utente proprietario.
        @param numero Numero della carta (solo le ultime 4 cifre vengono conservate).
        @param mese Mese di scadenza (1-12).
        @param anno Anno di scadenza.
        @param titolare Intestatario della carta (campo ðŸ”’).
        @param cvv Codice di sicurezza a 3 cifre (verificato, mai persistito â€” PCI).
        @param indirizzo_fatturazione Via di fatturazione; deve coincidere con la residenza.
        @return {id_metodo, pan_mascherato}.
        @throws ValueError Se la carta, il CVV o l'indirizzo di fatturazione non sono validi.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        # Punto 10: validazione server della carta (lunghezza, Luhn, scadenza).
        self._pagamenti.valida_carta(numero, mese, anno)
        # Punto 4: CVV esattamente 3 cifre (verificato, mai persistito â€” PCI).
        cvv_cifre = "".join(c for c in (cvv or "") if c.isdigit())
        if len(cvv_cifre) != 3:
            raise ValueError("Codice di sicurezza non valido: sono richieste esattamente 3 cifre")
        # Punto 4/5: l'indirizzo di fatturazione deve coincidere con la residenza del profilo.
        fatturazione = str(indirizzo_fatturazione or "").strip()
        if not fatturazione:
            raise ValueError(
                "Indirizzo di fatturazione obbligatorio (deve coincidere con la residenza)"
            )
        residenza = str((dao.leggi(col.UTENTI, id_utente) or {}).get("residenza") or "").strip()
        if not residenza:
            # Profilo senza residenza (account creato prima dell'introduzione del campo):
            # la si imposta dalla fatturazione fornita, cosÃ¬ coincidono per definizione e
            # l'utente non resta bloccato sull'aggiunta della carta (UT.11/UT.21, punto 4/5).
            dao.aggiorna(col.UTENTI, id_utente, {"residenza": fatturazione})
        elif _normalizza_indirizzo(fatturazione) != _normalizza_indirizzo(residenza):
            raise ValueError(
                "L'indirizzo di fatturazione deve coincidere con la residenza del profilo (punto 4)"
            )
        cifre = "".join(c for c in numero if c.isdigit())
        pan_mascherato = f"**** **** **** {cifre[-4:]}"
        id_metodo = dao.crea_in_sub(
            col.UTENTI,
            id_utente,
            col.SUB_METODI_PAGAMENTO,
            {
                "pan_mascherato": pan_mascherato,
                "token_provider": f"tok_sim_{cifre[-4:]}",  # ðŸ”’ token gateway (no PAN, PCI)
                "intestatario": titolare,  # ðŸ”’ cifrato at-rest
                "scadenza": f"{int(mese):02d}/{anno}",
                "indirizzo_fatturazione": fatturazione,  # ðŸ”’ = residenza (punto 4/5)
                "stato": "verificato",
            },
        )
        return {"id_metodo": id_metodo, "pan_mascherato": pan_mascherato}

    @staticmethod
    def _abbonamento_attivo(dao: DataAccessManager, id_utente: str) -> dict[str, Any] | None:
        """! @brief Restituisce l'abbonamento attivo (non scaduto) dell'utente, o None (punto 8).
        @param dao DataAccessManager connesso.
        @param id_utente Id dell'utente.
        @return L'abbonamento attivo non scaduto, oppure None se non presente.
        """
        from server.integration_tier.data_access_manager import collezioni as col

        ora = datetime.now(UTC)
        for abb in dao.elenca(
            col.ABBONAMENTI, filtri=[("id_utente", "==", id_utente), ("stato", "==", "attivo")]
        ):
            fine = abb.get("data_fine")
            if not fine:
                return abb
            try:
                if datetime.fromisoformat(str(fine)) > ora:
                    return abb
            except ValueError:  # data malformata: prudenzialmente considerata attiva
                return abb
        return None

    def sottoscrivi_abbonamento(self, id_utente: str, id_piano: str) -> dict[str, Any]:
        """! @brief Sottoscrive un piano di abbonamento periodico (UT.18).

        Punto 8: e' ammesso **un solo abbonamento attivo alla volta** â€” se ne esiste gia'
        uno non scaduto la sottoscrizione e' rifiutata. Punto 7: l'abbonamento include un
        bucket di token (consumati dalle corse al posto dell'addebito monetario).

        @param id_utente Id dell'utente sottoscrittore.
        @param id_piano Id del piano (deve esistere in `piani_abbonamento`).
        @return {id_abbonamento, id_piano, data_fine, token_residui}.
        @throws ValueError Se il piano non esiste.
        @throws ErrorePersistenza Se l'utente ha gia' un abbonamento attivo (punto 8).
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        if self._abbonamento_attivo(dao, id_utente) is not None:
            raise ErrorePersistenza("Esiste gia' un abbonamento attivo per questo utente")
        piano = dao.leggi(col.PIANI_ABBONAMENTO, id_piano)
        if piano is None:
            raise ValueError(f"Piano '{id_piano}' inesistente")
        inizio = datetime.now(UTC)
        fine = inizio + timedelta(days=int(piano.get("durata_giorni") or 30))
        token_inclusi = int(piano.get("token_inclusi") or TOKEN_ABBONAMENTO_DEFAULT)
        id_abbonamento = dao.crea(
            col.ABBONAMENTI,
            {
                "id_utente": id_utente,
                "id_piano": id_piano,
                "stato": "attivo",
                "data_inizio": inizio.isoformat(),
                "data_fine": fine.isoformat(),
                "prezzo_cent": int(piano.get("prezzo_cent") or 0),
                "token_inclusi": token_inclusi,  # punto 7: token consumati dalle corse
                "token_residui": token_inclusi,
            },
        )
        return {
            "id_abbonamento": id_abbonamento,
            "id_piano": id_piano,
            "data_fine": fine.isoformat(),
            "token_residui": token_inclusi,
        }

    def abbonamenti(self, id_utente: str) -> list[dict[str, Any]]:
        """! @brief Elenca gli abbonamenti dell'utente, dal piÃ¹ recente (UT.18/UT.21).
        @param id_utente Id dell'utente di cui elencare gli abbonamenti.
        @return Lista degli abbonamenti (documenti con id_piano, stato, date, prezzo).
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        elenco = dao.elenca(col.ABBONAMENTI, filtri=[("id_utente", "==", id_utente)])
        elenco.sort(key=lambda a: str(a.get("data_inizio") or ""), reverse=True)
        return elenco

    def registra_consenso(
        self, id_utente: str, tipo: str, concesso: bool, versione_privacy: str
    ) -> dict[str, Any]:
        """! @brief Registra un consenso GDPR esplicito nel profilo utente (IIN-16).

        Mantiene l'ultimo stato per ciascun tipo di consenso in un campo `consensi` sul
        documento di profilo (no nuova collezione, additivo). Sostituisce l'eventuale
        consenso precedente dello stesso tipo, conservando timestamp e versione informativa.

        @param id_utente Id dell'utente.
        @param tipo Tipo di consenso (@ref TIPI_CONSENSO).
        @param concesso True se concesso, False se revocato.
        @param versione_privacy Versione dell'informativa accettata.
        @return {tipo, concesso}.
        @throws ValueError Se il tipo non Ã¨ ammesso o il profilo non esiste.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        if tipo not in TIPI_CONSENSO:
            raise ValueError(f"Tipo consenso non valido: {tipo}")
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        utente = dao.leggi(col.UTENTI, id_utente)
        if utente is None:
            raise ValueError(f"Profilo utente '{id_utente}' inesistente")
        esistenti = utente.get("consensi")
        consensi = (
            [c for c in esistenti if c.get("tipo") != tipo] if isinstance(esistenti, list) else []
        )
        consensi.append(
            {
                "tipo": tipo,
                "concesso": bool(concesso),
                "versione_privacy": versione_privacy,
                "timestamp": datetime.now(UTC).isoformat(),
            }
        )
        dao.aggiorna(col.UTENTI, id_utente, {"consensi": consensi})
        return {"tipo": tipo, "concesso": bool(concesso)}

    def carica_documento_kyc(self, id_utente: str, tipo: str, nome_file: str) -> dict[str, Any]:
        """! @brief Carica un documento KYC con validazione del formato (UT.22.2, IIN-6/AG-SEC-01).

        Blocca server-side ogni estensione diversa da PDF/JPG/PNG (@ref formato_kyc_valido).
        Il binario va su Cloud Storage (stub `storage_path` ðŸ”’); su Firestore si conserva solo
        il riferimento e lo stato di verifica (in attesa di revisione operatore).

        @param id_utente Id dell'utente proprietario.
        @param tipo Tipo di documento (@ref TIPI_DOCUMENTO_KYC).
        @param nome_file Nome del file caricato (estensione validata).
        @return {id_documento, stato_verifica}.
        @throws ValueError Se il tipo o il formato non sono ammessi.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        if tipo not in TIPI_DOCUMENTO_KYC:
            raise ValueError(f"Tipo documento non valido: {tipo}")
        if not self.formato_kyc_valido(nome_file):
            raise ValueError("Formato documento non ammesso: solo PDF, JPG, PNG (IIN-6)")
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        id_documento = dao.crea(
            col.DOCUMENTI_UFFICIALI,
            {
                "id_utente": id_utente,
                "tipo_documento": tipo,
                "nome_file": nome_file,
                "storage_path": f"kyc/{id_utente}/{nome_file}",  # ðŸ”’ riferimento Cloud Storage
                "stato_verifica": "in_attesa",
            },
        )
        return {"id_documento": id_documento, "stato_verifica": "in_attesa"}

    # â”€â”€ Notifiche (scadenza prenotazione UT.15, interruzione servizio UT.19) â”€â”€
    def crea_notifica(
        self,
        id_destinatario: str | None,
        tipo: str,
        titolo: str,
        messaggio: str,
    ) -> str:
        """! @brief Crea una notifica per un destinatario o in broadcast (UT.15/UT.19, IIN-19).
        @param id_destinatario Id dell'account destinatario; None = broadcast a tutti.
        @param tipo Categoria (es. "prenotazione"/"servizio").
        @param titolo Titolo breve.
        @param messaggio Corpo del messaggio.
        @return Id della notifica creata.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        return dao.crea(
            col.NOTIFICHE,
            {
                "id_destinatario": id_destinatario,
                "tipo": tipo,
                "titolo": titolo,
                "messaggio": messaggio,
                "letta": False,
                "timestamp": datetime.now(UTC).isoformat(),
            },
        )

    def notifiche(self, id_account: str, solo_non_lette: bool = False) -> list[dict[str, Any]]:
        """! @brief Notifiche di un account piÃ¹ i broadcast, dalla piÃ¹ recente (UT.15/19, IIN-19).
        @param id_account Id dell'account destinatario.
        @param solo_non_lette Se True restituisce solo le notifiche non lette.
        @return Elenco di notifiche ordinate per timestamp decrescente.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        proprie = [
            n
            for n in dao.elenca(col.NOTIFICHE)
            if n.get("id_destinatario") in (id_account, None)
            and (not solo_non_lette or not n.get("letta"))
        ]
        return sorted(proprie, key=lambda n: str(n.get("timestamp", "")), reverse=True)

    def segna_notifica_letta(self, id_notifica: str) -> dict[str, Any]:
        """! @brief Marca una notifica come letta (UT.15/UT.19).
        @param id_notifica Id della notifica.
        @return {id_notifica, letta}.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        dao.aggiorna(col.NOTIFICHE, id_notifica, {"letta": True})
        return {"id_notifica": id_notifica, "letta": True}
