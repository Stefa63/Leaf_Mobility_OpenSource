"""! @package server.presentation_tier.api_gateway_sicurezza
@brief Gateway API e sicurezza perimetrale (autenticazione, MFA, RBAC, rate limit).
"""

from __future__ import annotations

import contextlib
import secrets
import time

from server.business_tier.gestore_profili_ekyc import GestoreProfiliEkyc
from server.integration_tier.data_access_manager import ErrorePersistenza

#! Durata di validità di una sessione MFA in attesa di OTP, in secondi (IIN-9).
TTL_SESSIONE_MFA_S = 300.0
#! Durata di validità di un token di sessione autenticato, in secondi.
TTL_SESSIONE_S = 3600.0


class ApiGatewaySicurezza:
    """! @brief Punto di ingresso sicuro delle richieste client.

    Responsabilita': terminazione delle richieste HTTP, autenticazione,
    enforcement MFA per OP/AP (IIN-9), RBAC (IIN-5), account lockout (IIN-10),
    audit logging degli accessi (IIN-13). Instrada verso il Business Tier
    (@ref GestoreProfiliEkyc); NON accede direttamente all'Integration Tier (§4.1).

    @note Il secondo fattore (OTP) è una **simulazione locale deterministica** (§3):
          non esiste un gateway SMS/email cablato, quindi l'OTP generato viene
          restituito nel campo `otp_simulato` della risposta di login — solo in questa
          modalità di sviluppo — e in produzione sarebbe recapitato fuori banda.
    """

    def __init__(self) -> None:
        """! @brief Costruisce il gateway e gli store in-memory delle sessioni (MFA + token)."""
        self._profili = GestoreProfiliEkyc()
        #! sessione MFA pendente → {id_account, otp, scadenza_monotonic}.
        self._sessioni_mfa: dict[str, dict[str, object]] = {}
        #! token di sessione autenticato → {id_account, ruolo, scadenza_monotonic}.
        self._sessioni_attive: dict[str, dict[str, object]] = {}

    def _emetti_token(self, id_account: str, ruolo: str, device_id: str | None = None) -> str:
        """! @brief Emette e memorizza un token di sessione opaco (Bearer).
        @param id_account Id dell'account autenticato.
        @param ruolo Ruolo RBAC associato alla sessione.
        @param device_id Dispositivo registrato all'accesso (IIN-14), da liberare al logout.
        @return Token di sessione (opaco, da usare come Bearer).
        """
        token = secrets.token_urlsafe(24)
        self._sessioni_attive[token] = {
            "id_account": id_account,
            "ruolo": ruolo,
            "device_id": device_id,
            "scadenza": time.monotonic() + TTL_SESSIONE_S,
        }
        return token

    def risolvi_sessione(self, token: str) -> dict[str, object] | None:
        """! @brief Risolve un token di sessione nell'identità autenticata (RBAC).
        @param token Token opaco fornito nell'header Authorization (Bearer).
        @return {id_account, ruolo} se il token è valido e non scaduto, altrimenti None.
        """
        dati = self._sessioni_attive.get(token)
        if dati is None:
            return None
        if float(dati["scadenza"]) < time.monotonic():  # type: ignore[arg-type]
            self._sessioni_attive.pop(token, None)
            return None
        return {"id_account": dati["id_account"], "ruolo": dati["ruolo"]}

    def revoca_sessione(self, token: str) -> bool:
        """! @brief Invalida un token di sessione attivo e libera il dispositivo (logout, IIN-14).

        Oltre a rimuovere il token, se la sessione era legata a un dispositivo registrato al
        login (UT) ne libera lo slot (@ref GestoreProfiliEkyc.rimuovi_dispositivo) così che un
        nuovo accesso da un altro dispositivo rientri nel limite di 3. La liberazione è
        best-effort: un errore di persistenza non rende il logout meno idempotente.

        @param token Token opaco da revocare.
        @return True se una sessione è stata rimossa, False se il token era già assente.
        """
        dati = self._sessioni_attive.pop(token, None)
        if dati is None:
            return False
        device_id = dati.get("device_id")
        if device_id:
            # logout resta idempotente anche se lo slot non è liberabile (persistenza assente).
            with contextlib.suppress(NotImplementedError, ErrorePersistenza):
                self._profili.rimuovi_dispositivo(str(dati.get("id_account")), str(device_id))
        return True

    def autentica(
        self, email: str, password: str, dispositivo: str | None = None
    ) -> dict[str, object]:
        """! @brief Autentica un soggetto (UT/OP/AP) con credenziali (IIN-1/IIN-5/IIN-10/IIN-14).

        Per UT, se le credenziali sono valide, registra il dispositivo applicando il limite di
        3 accessi simultanei (IIN-14) e poi emette il **token di sessione**: se il limite è
        superato solleva @c LimiteDispositivi e nessun token viene emesso. Per OP/AP apre invece
        una **sessione MFA** pendente con un OTP a 6 cifre (simulazione locale) e la restituisce
        per il secondo passo (@ref verifica_mfa); il token sarà emesso solo dopo la verifica
        dell'OTP.

        @param email Email/username di accesso (IIN-1).
        @param password Password in chiaro, verificata contro l'hash a DB.
        @param dispositivo Identificativo stabile del dispositivo (UT, IIN-14); se assente ne
                           viene generato uno una tantum.
        @return Esito con autenticazione, ruolo RBAC, token (UT) o sessione/OTP MFA (OP/AP).
        @throws NotImplementedError Se la persistenza non e' configurata (slice "in sviluppo", §9).
        @throws LimiteDispositivi Se l'utente ha già 3 dispositivi attivi (IIN-14).
        """
        esito = self._profili.autentica(email, password)
        if not esito.get("autenticato"):
            return esito
        id_account = str(esito.get("idAccount"))
        ruolo = str(esito.get("ruolo"))
        if esito.get("mfaRichiesto"):
            sessione = secrets.token_urlsafe(16)
            otp = f"{secrets.randbelow(1_000_000):06d}"
            self._sessioni_mfa[sessione] = {
                "id_account": id_account,
                "ruolo": ruolo,
                "otp": otp,
                "scadenza": time.monotonic() + TTL_SESSIONE_MFA_S,
            }
            # Punto 15: recapito OTP via email, delegato al Business Tier per non importare
            # l'Integration Tier dalla Presentation (vincolo §4). Best-effort (no-op senza
            # app password); l'otp_simulato resta per la modalità di sviluppo.
            self._profili.invia_otp(str(esito.get("email") or ""), otp)
            return {**esito, "sessione": sessione, "otp_simulato": otp}
        # UT: registra il dispositivo (limite di 3, IIN-14) prima di emettere il token.
        device_id = dispositivo or secrets.token_urlsafe(16)
        self._profili.registra_dispositivo(id_account, device_id)
        return {**esito, "token": self._emetti_token(id_account, ruolo, device_id)}

    def verifica_mfa(self, sessione: str, otp: str) -> dict[str, object]:
        """! @brief Verifica l'OTP MFA obbligatorio per OP/AP ed emette il token (IIN-9).

        Consuma la sessione MFA (uso singolo): se è scaduta, inesistente o l'OTP non
        combacia restituisce {valido: False}; in caso di successo invalida la sessione MFA,
        emette il token di sessione autenticato e segnala se l'account deve cambiare la
        password al primo accesso (IIN-12).

        @param sessione Identificativo di sessione in attesa di secondo fattore.
        @param otp One-Time Password fornito dall'utente.
        @return {valido, token?, richiede_cambio_password?}: presenti solo a verifica riuscita.
        """
        dati = self._sessioni_mfa.get(sessione)
        if dati is None:
            return {"valido": False}
        if float(dati["scadenza"]) < time.monotonic():  # type: ignore[arg-type]
            self._sessioni_mfa.pop(sessione, None)
            return {"valido": False}
        if not secrets.compare_digest(str(dati["otp"]), otp):
            return {"valido": False}
        self._sessioni_mfa.pop(sessione, None)
        id_account = str(dati["id_account"])
        token = self._emetti_token(id_account, str(dati["ruolo"]))
        return {
            "valido": True,
            "token": token,
            "richiede_cambio_password": self._profili.richiede_cambio_password(id_account),
        }
