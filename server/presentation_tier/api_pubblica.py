"""! @file api_pubblica.py
@brief Router client-facing (`/api/v1`) per i dispositivi esterni (mobile e web).

Predispone la superficie di accesso ai servizi: instradamento, validazione dei
contratti (pydantic), gateway di sicurezza e audit. La logica applicativa è
delegata al Presentation Tier (@ref ApiGatewaySicurezza, @ref GestoreAttivita);
finché il Business Tier e il DataAccessManager/DB sono in sviluppo, gli endpoint
rispondono con un **inviluppo uniforme** `{disponibile, messaggio, dati}` invece
di dati reali. Questo soddisfa "metà" del lavoro di accesso ai servizi: rotte,
contratti, sicurezza perimetrale e CORS pronti; resta da cablare il dominio.
"""

from __future__ import annotations

import asyncio
from datetime import UTC, datetime, timedelta
from typing import Any

from fastapi import APIRouter, Header, HTTPException
from pydantic import BaseModel, Field

from server.integration_tier.data_access_manager import ErrorePersistenza, LimiteDispositivi
from server.presentation_tier.api_gateway_sicurezza import ApiGatewaySicurezza
from server.presentation_tier.gestore_attivita import GestoreAttivita
from server.runtime.servizi import ServiziRuntime

#! Prefisso versionato della API client-facing (mobile/web).
PREFISSO_API = "/api/v1"


class LoginRichiesta(BaseModel):
    """! @brief Credenziali di accesso di un client (UT/OP/PA), contratto del layer dio."""

    identita: str = Field(min_length=3, max_length=254)
    password: str = Field(min_length=1, max_length=256)
    dispositivo: str | None = Field(default=None, max_length=128)


class MfaRichiesta(BaseModel):
    """! @brief Secondo fattore (OTP) per OP/PA (IIN-9), contratto del layer dio."""

    id_account: str = Field(min_length=1, max_length=128)
    otp: str = Field(min_length=4, max_length=10)
    dispositivo: str | None = Field(default=None, max_length=128)


class RegistrazioneRichiesta(BaseModel):
    """! @brief Dati di registrazione di un nuovo utente UT (UT.22.1)."""

    email: str = Field(min_length=3, max_length=254)
    username: str = Field(min_length=3, max_length=64)
    password: str = Field(min_length=1, max_length=256)
    data_nascita: str | None = Field(default=None, max_length=32)
    nome: str | None = Field(default=None, max_length=128)
    cognome: str | None = Field(default=None, max_length=128)
    residenza: str | None = Field(default=None, max_length=256)


class ResetRichiesta(BaseModel):
    """! @brief Richiesta di reset password via email registrata (UT.24/AP.12, IIN-11)."""

    identita: str = Field(min_length=3, max_length=254)


class ResetConfermaRichiesta(BaseModel):
    """! @brief Conferma reset password con codice monouso e nuova password (IIN-11)."""

    identita: str = Field(min_length=3, max_length=254)
    codice: str = Field(min_length=4, max_length=12)
    nuova_password: str | None = Field(default=None, min_length=8, max_length=256)


class PrimoAccessoRichiesta(BaseModel):
    """! @brief Cambio password obbligatorio al primo accesso AP/OP (IIN-12)."""

    nuova_password: str = Field(min_length=8, max_length=256)


class ProfiloAggiornaRichiesta(BaseModel):
    """! @brief Aggiornamento dei dati anagrafici del profilo (UT.21)."""

    nome: str | None = Field(default=None, max_length=128)
    cognome: str | None = Field(default=None, max_length=128)
    telefono: str | None = Field(default=None, max_length=32)
    data_nascita: str | None = Field(default=None, max_length=32)
    residenza: str | None = Field(default=None, max_length=256)


class AreaRichiesta(BaseModel):
    """! @brief Creazione di un'area limitata (cantiere/interdizione/slow-zone, AP.04/06/08)."""

    tipo: str = Field(min_length=1, max_length=64)
    nome: str = Field(min_length=1, max_length=128)
    poligono: list[list[float]] = Field(default_factory=list)
    geohash: str | None = Field(default=None, max_length=32)
    limite_velocita_kmh: int | None = Field(default=None, ge=1, le=130)


class AssistenzaApriRichiesta(BaseModel):
    """! @brief Apertura di una richiesta di assistenza da parte dell'utente (UT.09)."""

    oggetto: str = Field(min_length=1, max_length=160)
    messaggio: str = Field(min_length=1, max_length=4000)
    id_corsa: str | None = Field(default=None, max_length=64)


class AssistenzaRispostaRichiesta(BaseModel):
    """! @brief Presa in carico / risposta a un ticket di assistenza (OP.08)."""

    risposta: str = Field(min_length=1, max_length=4000)
    stato: str = Field(default="in_lavorazione", pattern="^(aperto|in_lavorazione|chiuso)$")


class PrenotaRichiesta(BaseModel):
    """! @brief Prenotazione di un mezzo (UT.02)."""

    id_mezzo: str = Field(min_length=1, max_length=64)
    durata_min: int | None = Field(default=None, ge=1, le=1440)


class CorsaRichiesta(BaseModel):
    """! @brief Avvio di una corsa su un mezzo (UT.10)."""

    id_mezzo: str = Field(min_length=1, max_length=64)
    id_prenotazione: str | None = Field(default=None, max_length=64)


class TerminaRichiesta(BaseModel):
    """! @brief Conclusione di una corsa (UT.04); coordinate GPS di chiusura opzionali (OP.05)."""

    km: float = Field(default=0.0, ge=0)
    lat: float | None = Field(default=None, ge=-90, le=90)
    lon: float | None = Field(default=None, ge=-180, le=180)


class StimaRichiesta(BaseModel):
    """! @brief Stima preventiva del costo di una corsa su un mezzo (UT.03)."""

    id_mezzo: str = Field(min_length=1, max_length=64)
    durata_min: int | None = Field(default=None, ge=1, le=1440)


class ValutazioneRichiesta(BaseModel):
    """! @brief Valutazione a stelle di una corsa conclusa (UT.16)."""

    stelle: int = Field(ge=1, le=5)


class MetodoPagamentoRichiesta(BaseModel):
    """! @brief Registrazione di un metodo di pagamento verificato (UT.11)."""

    numero: str = Field(min_length=12, max_length=23)
    mese: int = Field(ge=1, le=12)
    anno: int = Field(ge=2024, le=2100)
    titolare: str = Field(min_length=1, max_length=128)
    cvv: str = Field(min_length=3, max_length=4)
    indirizzo_fatturazione: str = Field(min_length=1, max_length=256)


class AbbonamentoRichiesta(BaseModel):
    """! @brief Sottoscrizione di un piano di abbonamento periodico (UT.18)."""

    id_piano: str = Field(min_length=1, max_length=64)


class ConsensoRichiesta(BaseModel):
    """! @brief Registrazione di un consenso GDPR esplicito (IIN-16)."""

    tipo: str = Field(pattern="^(geolocalizzazione|marketing|trattamento_dati)$")
    concesso: bool = True
    versione_privacy: str = Field(default="1.0", max_length=32)


class KycRichiesta(BaseModel):
    """! @brief Caricamento di un documento KYC (UT.22.2, IIN-6)."""

    tipo: str = Field(pattern="^(patente|carta_identita)$")
    nome_file: str = Field(min_length=3, max_length=256)


class SosRichiesta(BaseModel):
    """! @brief Segnalazione di emergenza SOS con la posizione (UT.20, IIN-18)."""

    lat: float = Field(ge=-90, le=90)
    lon: float = Field(ge=-180, le=180)
    id_corsa: str | None = Field(default=None, max_length=64)


class SosStatoRichiesta(BaseModel):
    """! @brief Aggiornamento stato di una segnalazione SOS (presa in carico/chiusura, OP.08)."""

    stato: str = Field(pattern="^(inoltrata|presa_in_carico|chiusa)$")


class NotificaRichiesta(BaseModel):
    """! @brief Notifica broadcast di interruzione/avviso di servizio (UT.19, OP/PA)."""

    titolo: str = Field(min_length=1, max_length=160)
    messaggio: str = Field(min_length=1, max_length=2000)
    tipo: str = Field(default="servizio", max_length=32)


class StatoAccountRichiesta(BaseModel):
    """! @brief Sospensione/sblocco manuale di un account utente (OP.10/OP.18)."""

    stato: str = Field(pattern="^(attivo|sospeso)$")


class ProvisioningPaRichiesta(BaseModel):
    """! @brief Provisioning di un account Amministrazione Pubblica da parte dell'OP (OP.17)."""

    email: str = Field(min_length=3, max_length=254)
    username: str = Field(min_length=3, max_length=64)
    ente: str = Field(min_length=1, max_length=160)
    email_istituzionale: str = Field(min_length=3, max_length=254)


class ManutenzioneRichiesta(BaseModel):
    """! @brief Apertura di un ticket di manutenzione su un mezzo guasto (OP.16/OP.19)."""

    id_mezzo: str = Field(min_length=1, max_length=64)
    descrizione: str = Field(min_length=1, max_length=2000)
    priorita: str = Field(default="media", pattern="^(bassa|media|alta)$")


class AssegnaTecnicoRichiesta(BaseModel):
    """! @brief Assegnazione di un ticket di manutenzione a un tecnico (OP.16)."""

    id_tecnico: str = Field(min_length=1, max_length=64)


class SogliaAreaRichiesta(BaseModel):
    """! @brief Soglia minima di mezzi per un'area con alert (OP.02)."""

    id_area: str = Field(min_length=1, max_length=64)
    minimo: int = Field(ge=0, le=10000)


class SogliaBatteriaRichiesta(BaseModel):
    """! @brief Soglia di allerta batteria, opzionalmente per tipologia (OP.22)."""

    percentuale: int = Field(ge=1, le=100)
    tipo_mezzo: str | None = Field(default=None, max_length=32)


class PromozioneRichiesta(BaseModel):
    """! @brief Configurazione di una promozione/incentivo geografico (OP.09/OP.15)."""

    tipo: str = Field(
        pattern="^(sconto_percentuale|credito_bonus_parcheggio|sconto_geografico|tariffa_evento)$"
    )
    descrizione: str = Field(min_length=1, max_length=400)
    valore: float | None = Field(default=None, ge=0)
    id_area: str | None = Field(default=None, max_length=64)


class EventoRichiesta(BaseModel):
    """! @brief Inserimento di un grande evento cittadino su mappa (AP.09/AP.04)."""

    nome: str = Field(min_length=1, max_length=160)
    categoria: str = Field(
        default="grande_evento",
        pattern="^(grande_evento|cantiere|interruzione)$",
    )
    area: str | None = Field(default=None, max_length=120)
    data_inizio: str = Field(min_length=4, max_length=32)
    data_fine: str = Field(min_length=4, max_length=32)
    poligono: list[list[float]] = Field(default_factory=list)
    geohash: str | None = Field(default=None, max_length=32)


def _inviluppo(disponibile: bool, messaggio: str, dati: object = None) -> dict[str, object]:
    """! @brief Costruisce l'inviluppo uniforme di risposta della API pubblica.
    @param disponibile True se il servizio ha prodotto dati reali.
    @param messaggio Messaggio leggibile dal client.
    @param dati Payload applicativo (None finché il dominio è in sviluppo).
    @return Dizionario serializzabile con la struttura di risposta standard.
    """
    return {"disponibile": disponibile, "messaggio": messaggio, "dati": dati}


def crea_router_api(servizi: ServiziRuntime) -> APIRouter:
    """! @brief Costruisce il router client-facing legato ai servizi runtime.

    @param servizi Contenitore dei servizi condivisi (audit, metriche, impostazioni).
    @return APIRouter con gli endpoint pubblici versionati `/api/v1`.
    """
    router = APIRouter(prefix=PREFISSO_API, tags=["api-pubblica"])
    gateway = ApiGatewaySicurezza()
    attivita = GestoreAttivita()
    #! Ponte MFA a livello API: id_account → {sessione, ruolo} in attesa di OTP. Tiene il
    #! contratto del layer dio mobile (che rimanda `id_account`) senza alterare il gateway,
    #! che internamente indicizza per token di sessione opaco (§3, additivo).
    sessioni_mfa_per_account: dict[str, dict[str, str]] = {}

    async def _delega(azione: str, chiamata: Any) -> dict[str, object]:  # noqa: ANN401
        """! @brief Esegue una chiamata di dominio convertendo gli stub in inviluppo.
        @param azione Nome dell'azione (per l'audit).
        @param chiamata Callable senza argomenti che invoca il dominio.
        @return Inviluppo con i dati reali oppure il messaggio "in sviluppo".
        """
        try:
            dati = await asyncio.to_thread(chiamata)
        except NotImplementedError as exc:
            servizi.audit.registra(f"api_{azione}", "in_sviluppo", None)
            return _inviluppo(False, str(exc), None)
        except ValueError as exc:  # input/entità non valida (es. mezzo inesistente) → 400
            servizi.audit.registra(f"api_{azione}", "invalido", None)
            raise HTTPException(status_code=400, detail=str(exc)) from exc
        except ErrorePersistenza as exc:  # conflitto/violazione di dominio → 409
            servizi.audit.registra(f"api_{azione}", "conflitto", None)
            raise HTTPException(status_code=409, detail=str(exc)) from exc
        servizi.audit.registra(f"api_{azione}", "ok", None)
        return _inviluppo(True, "ok", dati)

    def _id_utente(authorization: str | None) -> str:
        """! @brief Ricava l'id utente dal token di sessione (Bearer), o solleva 401.
        @param authorization Header Authorization (atteso "Bearer <token>").
        @return Id dell'account autenticato.
        @throws HTTPException 401 se il token manca o non è valido/scaduto.
        """
        if not authorization:
            raise HTTPException(status_code=401, detail="Autenticazione richiesta")
        token = authorization.removeprefix("Bearer ").strip()
        sessione = gateway.risolvi_sessione(token)
        if sessione is None:
            raise HTTPException(status_code=401, detail="Sessione non valida o scaduta")
        return str(sessione["id_account"])

    def _sessione(authorization: str | None) -> dict[str, object]:
        """! @brief Risolve la sessione completa (id_account + ruolo) dal Bearer, o 401.
        @param authorization Header Authorization (atteso "Bearer <token>").
        @return Sessione {id_account, ruolo} dell'account autenticato.
        @throws HTTPException 401 se il token manca o non è valido/scaduto.
        """
        if not authorization:
            raise HTTPException(status_code=401, detail="Autenticazione richiesta")
        token = authorization.removeprefix("Bearer ").strip()
        sessione = gateway.risolvi_sessione(token)
        if sessione is None:
            raise HTTPException(status_code=401, detail="Sessione non valida o scaduta")
        return sessione

    def _richiedi_ruolo(authorization: str | None, *ruoli: str) -> dict[str, object]:
        """! @brief Autorizza l'accesso a un endpoint riservato a determinati ruoli (RBAC, IIN-5).
        @param authorization Header Bearer del token di sessione.
        @param ruoli Ruoli ammessi (es. "OP", "PA").
        @return Sessione {id_account, ruolo} se il ruolo è autorizzato.
        @throws HTTPException 401 senza sessione valida; 403 se il ruolo non è autorizzato.
        """
        sessione = _sessione(authorization)
        if str(sessione.get("ruolo")) not in ruoli:
            raise HTTPException(status_code=403, detail="Operazione non consentita per il ruolo")
        return sessione

    async def _auth(azione: str, chiamata: Any) -> dict[str, object]:  # noqa: ANN401
        """! @brief Esegue un'azione di autenticazione con mappatura HTTP coerente col client.

        A differenza di @ref _delega (inviluppo dati), gli endpoint di autenticazione
        rispondono con il contratto atteso dal layer dio mobile e mappano la persistenza
        non configurata a 503 (servizio non disponibile) invece dell'inviluppo.

        @param azione Nome dell'azione (per l'audit).
        @param chiamata Callable senza argomenti che produce la risposta.
        @return Il dizionario prodotto dalla chiamata.
        @throws HTTPException 503 se la persistenza non è configurata; 409 su conflitto di dominio.
        """
        try:
            dati: dict[str, object] = await asyncio.to_thread(chiamata)
        except NotImplementedError as exc:
            servizi.audit.registra(f"api_{azione}", "in_sviluppo", None)
            raise HTTPException(status_code=503, detail=str(exc)) from exc
        except ValueError as exc:  # input non valido (es. password IIN-5)
            servizi.audit.registra(f"api_{azione}", "invalido", None)
            raise HTTPException(status_code=400, detail=str(exc)) from exc
        except LimiteDispositivi as exc:  # limite di 3 dispositivi superato (IIN-14) → 403
            servizi.audit.registra(f"api_{azione}", "limite_dispositivi", None)
            raise HTTPException(status_code=403, detail="limite_dispositivi_superato") from exc
        except ErrorePersistenza as exc:  # conflitto/violazione di dominio → 409
            servizi.audit.registra(f"api_{azione}", "conflitto", None)
            raise HTTPException(status_code=409, detail=str(exc)) from exc
        servizi.audit.registra(f"api_{azione}", "ok", None)
        return dati

    @router.get("/info")
    async def info() -> dict[str, object]:
        """! @brief Informazioni pubbliche sul server per i client (mobile/web).
        @return Nome, versione, ambiente, capacità e stato del database.
        """
        return {
            "nome": "LEAF Mobility",
            "componente": "runtime operativo",
            "versione": "0.1.0",
            "api": "v1",
            "database": "in sviluppo",
            "esposto_in_rete": servizi.impostazioni.esposto_in_rete,
            "capacita": [
                "auth",
                "registrazione",
                "veicoli",
                "geocoding",
                "percorsi",
                "corse",
                "profilo",
                "fatture",
                "flotta",
                "assistenza",
                "sos",
                "analitiche",
                "aree",
                "utenti",
                "amministrazioni",
                "manutenzione",
                "tecnici",
                "promozioni",
                "eventi",
            ],
        }

    @router.get("/salute")
    async def salute() -> dict[str, object]:
        """! @brief Health check pubblico per i client.
        @return Stato del runtime e uptime.
        """
        snap = servizi.metriche.snapshot()
        return {
            "stato": "ok",
            "uptime_s": snap["uptime_s"],
            "dispositivi": snap["dispositivi_collegati"],
        }

    @router.post("/auth/login")
    async def login(corpo: LoginRichiesta) -> dict[str, object]:
        """! @brief Autenticazione di un client (UT/OP/PA) — IIN-1/IIN-5/IIN-9/IIN-10.

        Per UT emette subito il token; per OP/PA apre la sessione MFA (IIN-9) e restituisce
        `id_account` da rimandare con l'OTP. Risposta nel contratto del layer dio mobile:
        `{stato, access_token?, id_account?, ruolo?, otp_simulato?}`.

        @param corpo Credenziali di accesso (identita/password) e dispositivo opzionale.
        @return Esito tipizzato per il client; 401 se credenziali errate, 423 se bloccato.
        @throws HTTPException 401/423/503 secondo l'esito.
        """
        esito = await _auth(
            "login", lambda: gateway.autentica(corpo.identita, corpo.password, corpo.dispositivo)
        )
        if not esito.get("autenticato"):
            if esito.get("bloccato"):
                raise HTTPException(status_code=423, detail="Account bloccato: troppi tentativi")
            if esito.get("sospeso"):  # sospensione manuale operatore (OP.10)
                raise HTTPException(status_code=403, detail="Account sospeso")
            raise HTTPException(status_code=401, detail="Credenziali non valide")
        id_account = str(esito.get("idAccount"))
        ruolo = str(esito.get("ruolo"))
        if esito.get("mfaRichiesto"):
            sessioni_mfa_per_account[id_account] = {
                "sessione": str(esito.get("sessione")),
                "ruolo": ruolo,
            }
            return {
                "stato": "mfa_richiesta",
                "id_account": id_account,
                "otp_simulato": esito.get("otp_simulato"),
            }
        return {
            "stato": "ok",
            "access_token": esito.get("token"),
            "id_account": id_account,
            "ruolo": ruolo,
        }

    @router.post("/auth/mfa")
    async def mfa(corpo: MfaRichiesta) -> dict[str, object]:
        """! @brief Verifica del secondo fattore MFA per OP/PA ed emette il token (IIN-9).
        @param corpo id_account in attesa e OTP (contratto del layer dio mobile).
        @return `{stato:'ok', access_token, id_account, ruolo}` a verifica riuscita.
        @throws HTTPException 401 se la sessione MFA è assente/scaduta o l'OTP è errato.
        """
        pendente = sessioni_mfa_per_account.get(corpo.id_account)
        if pendente is None:
            raise HTTPException(status_code=401, detail="Sessione MFA assente o scaduta")
        esito = gateway.verifica_mfa(pendente["sessione"], corpo.otp)
        if not esito.get("valido"):
            raise HTTPException(status_code=401, detail="OTP non valido")
        sessioni_mfa_per_account.pop(corpo.id_account, None)
        servizi.audit.registra("api_mfa", "ok", None)
        return {
            "stato": "ok",
            "access_token": esito.get("token"),
            "id_account": corpo.id_account,
            "ruolo": pendente["ruolo"],
            # IIN-12: la dashboard reindirizza al cambio password se è il primo accesso OP/PA.
            "richiede_cambio_password": bool(esito.get("richiede_cambio_password")),
        }

    @router.post("/auth/registrazione", status_code=201)
    async def registrazione(corpo: RegistrazioneRichiesta) -> dict[str, object]:
        """! @brief Registra un nuovo utente UT (UT.22.1, IIN-5).
        @param corpo Email, username, password e data di nascita opzionale.
        @return `{stato:'ok', id_account}`; 400 password debole; 409 email/username già in uso.
        @throws HTTPException 400/409/503 secondo l'esito.
        """
        esito = await _auth(
            "registrazione",
            lambda: attivita.instrada(
                "registra_utente",
                {
                    "email": corpo.email,
                    "username": corpo.username,
                    "password": corpo.password,
                    "data_nascita": corpo.data_nascita,
                },
            ),
        )
        return {"stato": "ok", **esito}

    @router.post("/auth/password/reset")
    async def reset_password(corpo: ResetRichiesta) -> dict[str, object]:
        """! @brief Avvia il reset password via email registrata (UT.24/AP.12, IIN-11).
        @param corpo Identità (email/username) dichiarata dall'utente.
        @return `{stato:'ok', ...}` — sempre positivo (anti-enumerazione).
        @throws HTTPException 503 se la persistenza non è configurata.
        """
        esito = await _auth(
            "reset_password",
            lambda: attivita.instrada("richiedi_reset", {"identita": corpo.identita}),
        )
        return {"stato": "ok", **esito}

    @router.post("/auth/password/reset/conferma")
    async def reset_password_conferma(corpo: ResetConfermaRichiesta) -> dict[str, object]:
        """! @brief Conferma il reset password con codice monouso e nuova password (UT.24/AP.12).

        Al successo emette un token di sessione (auto-accesso): il codice via email è
        già un secondo fattore, quindi l'OTP MFA è bypassato. Restituisce anche
        `id_account` e `ruolo` per consentire al client di completare l'accesso.

        @param corpo Identità, codice ricevuto fuori banda e nuova password (IIN-5/IIN-11).
        @return `{stato:'ok', reimpostata, access_token?, id_account?, ruolo?}` — token
            emesso solo se `reimpostata=True`; `reimpostata=False` se codice errato/scaduto
            (anti-enumerazione); 400 se la nuova password è debole.
        @throws HTTPException 400 password debole; 503 se la persistenza non è configurata.
        """
        esito = await _auth(
            "conferma_reset",
            lambda: attivita.instrada(
                "conferma_reset",
                {
                    "identita": corpo.identita,
                    "codice": corpo.codice,
                    "nuova_password": corpo.nuova_password,
                },
            ),
        )
        # Auto-accesso: il codice via email funge da secondo fattore (IIN-9/IIN-11).
        if esito.get("reimpostata"):
            token = gateway._emetti_token(str(esito["id_account"]), str(esito["ruolo"]))
            esito["access_token"] = token
        return {"stato": "ok", **esito}

    @router.post("/auth/password/primo-accesso")
    async def primo_accesso(
        corpo: PrimoAccessoRichiesta, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Cambio password obbligatorio al primo accesso AP/OP (IIN-12).
        @param corpo Nuova password (validata IIN-5).
        @param authorization Header Bearer del token di sessione.
        @return `{stato:'ok', ...}` con esito del cambio.
        @throws HTTPException 401 senza sessione valida; 400 se la password è debole.
        """
        id_account = _id_utente(authorization)
        esito = await _auth(
            "cambia_password",
            lambda: attivita.instrada(
                "cambia_password",
                {"id_account": id_account, "nuova_password": corpo.nuova_password},
            ),
        )
        return {"stato": "ok", **esito}

    @router.get("/auth/io")
    async def auth_io(authorization: str | None = Header(default=None)) -> dict[str, object]:
        """! @brief Identità della sessione corrente ("chi sono") per i client.
        @param authorization Header Bearer del token di sessione.
        @return Inviluppo con `{id_account, ruolo}` della sessione autenticata.
        @throws HTTPException 401 senza sessione valida.
        """
        sessione = _sessione(authorization)
        return _inviluppo(
            True,
            "ok",
            {"id_account": sessione.get("id_account"), "ruolo": sessione.get("ruolo")},
        )

    @router.post("/auth/logout")
    async def logout(authorization: str | None = Header(default=None)) -> dict[str, object]:
        """! @brief Termina la sessione corrente invalidando il token (logout).
        @param authorization Header Bearer del token di sessione.
        @return `{stato:'ok'}` (idempotente: vale anche se il token è già assente).
        """
        if authorization:
            token = authorization.removeprefix("Bearer ").strip()
            gateway.revoca_sessione(token)
            servizi.audit.registra("api_logout", "ok", None)
        return {"stato": "ok"}

    @router.get("/veicoli")
    async def veicoli(
        lat: float | None = None,
        lon: float | None = None,
        authorization: str | None = Header(default=None),
    ) -> dict[str, object]:
        """! @brief Elenco dei mezzi disponibili nei pressi (UT.01/UT.05).
        @param lat Latitudine opzionale del centro di ricerca.
        @param lon Longitudine opzionale del centro di ricerca.
        @param authorization Header Bearer del token di sessione (se presente).
        @return Inviluppo con i mezzi (reale a Business Tier cablato) o "in sviluppo".
        """
        payload: dict[str, object] = {"lat": lat, "lon": lon, "autenticato": bool(authorization)}
        return await _delega("veicoli", lambda: attivita.instrada("ricerca_mezzi", payload))

    @router.get("/geocoding")
    async def geocoding(
        q: str, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Suggerimenti di luogo per l'autocompletamento della ricerca percorsi (UT.07).
        @param q Testo parziale digitato dall'utente.
        @param authorization Header Bearer del token di sessione.
        @return Inviluppo con l'elenco {nome, lat, lon} dei luoghi suggeriti.
        @throws HTTPException 401 senza sessione valida.
        """
        _sessione(authorization)
        return await _delega(
            "geocoding", lambda: attivita.instrada("suggerisci_luoghi", {"query": q})
        )

    @router.get("/percorsi")
    async def percorsi(
        da: str | None = None,
        a: str | None = None,
        da_lat: float | None = None,
        da_lon: float | None = None,
        a_lat: float | None = None,
        a_lon: float | None = None,
        authorization: str | None = Header(default=None),
    ) -> dict[str, object]:
        """! @brief Opzioni di percorso multimodali tra due luoghi (UT.07/UT.08).

        Accetta i luoghi per nome (geocodificati sul gazetteer locale) oppure per
        coordinate esplicite (es. posizione corrente), che prevalgono sul nome. Se un
        nome non è riconosciuto, risponde con inviluppo non disponibile (messaggio di
        dominio), così il client mostra lo stato d'errore senza un 500.

        @param da Nome del luogo di partenza.
        @param a Nome del luogo di arrivo.
        @param da_lat Latitudine di partenza (prevale su @p da).
        @param da_lon Longitudine di partenza (prevale su @p da).
        @param a_lat Latitudine di arrivo (prevale su @p a).
        @param a_lon Longitudine di arrivo (prevale su @p a).
        @param authorization Header Bearer del token di sessione.
        @return Inviluppo con {origine, destinazione, percorsi, totale} o messaggio di errore.
        @throws HTTPException 401 senza sessione valida.
        """
        _sessione(authorization)
        carico: dict[str, object] = {
            "da": da,
            "a": a,
            "da_lat": da_lat,
            "da_lon": da_lon,
            "a_lat": a_lat,
            "a_lon": a_lon,
        }
        try:
            dati = attivita.instrada("cerca_percorsi", carico)
        except ValueError as exc:  # luogo non riconosciuto dal gazetteer
            servizi.audit.registra("api_percorsi", "non_riconosciuto", None)
            return _inviluppo(False, str(exc), None)
        servizi.audit.registra("api_percorsi", "ok", None)
        return _inviluppo(True, "ok", dati)

    @router.get("/stazioni")
    async def stazioni_ricarica(
        authorization: str | None = Header(default=None),
    ) -> dict[str, object]:
        """! @brief Elenca le stazioni di ricarica attive sulla mappa (UT.14).
        @param authorization Header Bearer del token di sessione.
        @return Inviluppo con l'elenco stazioni o "in sviluppo".
        @throws HTTPException 401 senza sessione valida.
        """
        _id_utente(authorization)  # autenticazione richiesta
        return await _delega(
            "stazioni_ricarica", lambda: attivita.instrada("stazioni_ricarica", {})
        )

    @router.get("/geofencing/stato")
    async def stato_geofencing(
        lat: float, lon: float, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Stato geofencing di un punto: area vietata e limite di velocità (AP.06/AP.08).
        @param lat Latitudine del punto da valutare.
        @param lon Longitudine del punto da valutare.
        @param authorization Header Bearer del token di sessione.
        @return Inviluppo con `{vietata, limite_velocita_kmh}` o "in sviluppo".
        @throws HTTPException 401 senza sessione valida.
        """
        _sessione(authorization)
        return await _delega(
            "stato_geofencing",
            lambda: attivita.instrada("stato_geofencing", {"lat": lat, "lon": lon}),
        )

    @router.post("/sos", status_code=201)
    async def segnala_sos(
        corpo: SosRichiesta, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Inoltra una segnalazione SOS con la posizione (UT.20, IIN-18).
        @param corpo Coordinate correnti dell'utente ed eventuale corsa in atto.
        @param authorization Header Bearer del token di sessione.
        @return Inviluppo con `{id_segnalazione, stato}` o "in sviluppo".
        @throws HTTPException 401 senza sessione valida.
        """
        id_utente = _id_utente(authorization)
        return await _delega(
            "segnala_sos",
            lambda: attivita.instrada(
                "segnala_sos",
                {
                    "id_utente": id_utente,
                    "lat": corpo.lat,
                    "lon": corpo.lon,
                    "id_corsa": corpo.id_corsa,
                },
            ),
        )

    @router.get("/sos")
    async def coda_sos(
        stato: str | None = None, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Coda live delle segnalazioni SOS in entrata per l'operatore (OP.08, UT.20).
        @param stato Filtro opzionale su stato (inoltrata/presa_in_carico/chiusa).
        @param authorization Header Bearer del token di sessione (OP).
        @return Inviluppo con l'elenco SOS (con etichetta utente) o "in sviluppo".
        @throws HTTPException 401/403 senza sessione OP valida.
        """
        _richiedi_ruolo(authorization, "OP")
        return await _delega(
            "elenca_sos", lambda: attivita.instrada("elenca_sos", {"stato": stato})
        )

    @router.put("/sos/{id_segnalazione}/stato")
    async def aggiorna_stato_sos(
        id_segnalazione: str,
        corpo: SosStatoRichiesta,
        authorization: str | None = Header(default=None),
    ) -> dict[str, object]:
        """! @brief Aggiorna lo stato di una segnalazione SOS: presa in carico/chiusura (OP.08).
        @param id_segnalazione Id della segnalazione.
        @param corpo Nuovo stato (inoltrata/presa_in_carico/chiusa).
        @param authorization Header Bearer del token di sessione (OP).
        @return Inviluppo con `{id_segnalazione, stato}` o "in sviluppo".
        @throws HTTPException 401/403 senza sessione OP valida; 400 se lo stato non è valido.
        """
        sessione = _richiedi_ruolo(authorization, "OP")
        return await _delega(
            "aggiorna_stato_sos",
            lambda: attivita.instrada(
                "aggiorna_stato_sos",
                {
                    "id_segnalazione": id_segnalazione,
                    "stato": corpo.stato,
                    "id_operatore": str(sessione.get("id_account")),
                },
            ),
        )

    @router.get("/notifiche")
    async def elenca_notifiche(
        solo_non_lette: bool = False, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Notifiche dell'utente autenticato e broadcast (UT.15/UT.19, IIN-19).
        @param solo_non_lette Se True restituisce solo le notifiche non lette.
        @param authorization Header Bearer del token di sessione.
        @return Inviluppo con l'elenco notifiche o "in sviluppo".
        @throws HTTPException 401 senza sessione valida.
        """
        id_account = _id_utente(authorization)
        return await _delega(
            "elenca_notifiche",
            lambda: attivita.instrada(
                "elenca_notifiche",
                {"id_account": id_account, "solo_non_lette": solo_non_lette},
            ),
        )

    @router.post("/notifiche/{id_notifica}/letta")
    async def segna_notifica_letta(
        id_notifica: str, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Marca una notifica come letta (UT.15/UT.19).
        @param id_notifica Id della notifica.
        @param authorization Header Bearer del token di sessione.
        @return Inviluppo con `{id_notifica, letta}` o "in sviluppo".
        @throws HTTPException 401 senza sessione valida.
        """
        _id_utente(authorization)  # autenticazione richiesta
        return await _delega(
            "segna_notifica_letta",
            lambda: attivita.instrada("segna_notifica_letta", {"id_notifica": id_notifica}),
        )

    @router.post("/notifiche", status_code=201)
    async def crea_notifica(
        corpo: NotificaRichiesta, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Pubblica una notifica broadcast di servizio (interruzione, UT.19, OP/PA).
        @param corpo Titolo, messaggio e tipo della notifica.
        @param authorization Header Bearer del token di sessione (OP/PA).
        @return Inviluppo con `{id_notifica}` o "in sviluppo".
        @throws HTTPException 401/403 senza sessione OP/PA valida.
        """
        _richiedi_ruolo(authorization, "OP", "PA")
        return await _delega(
            "crea_notifica",
            lambda: attivita.instrada(
                "crea_notifica",
                {
                    "id_destinatario": None,
                    "tipo": corpo.tipo,
                    "titolo": corpo.titolo,
                    "messaggio": corpo.messaggio,
                },
            ),
        )

    @router.post("/prenotazioni")
    async def prenota(
        corpo: PrenotaRichiesta, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Prenotazione di un mezzo con blocco esclusivo (UT.02).
        @param corpo Identificativo del mezzo e durata della riserva in minuti (opzionale, UT.15).
        @param authorization Header Bearer del token di sessione.
        @return Inviluppo con l'id prenotazione (reale a DB cablato) o "in sviluppo".
        @throws HTTPException 401 senza sessione valida; 409 se il mezzo non è disponibile.
        """
        id_utente = _id_utente(authorization)
        scadenza = (
            (datetime.now(UTC) + timedelta(minutes=corpo.durata_min)).isoformat()
            if corpo.durata_min is not None
            else None
        )
        return await _delega(
            "prenota",
            lambda: attivita.instrada(
                "prenota_mezzo",
                {"id_utente": id_utente, "id_mezzo": corpo.id_mezzo, "scadenza": scadenza},
            ),
        )

    @router.get("/prenotazioni")
    async def elenca_prenotazioni(
        authorization: str | None = Header(default=None),
    ) -> dict[str, object]:
        """! @brief Prenotazioni attive dell'utente autenticato (UT.02/UT.21).
        @param authorization Header Bearer del token di sessione.
        @return Inviluppo con l'elenco delle prenotazioni attive o "in sviluppo".
        @throws HTTPException 401 senza sessione valida.
        """
        id_utente = _id_utente(authorization)
        return await _delega(
            "elenca_prenotazioni",
            lambda: attivita.instrada("elenca_prenotazioni", {"id_utente": id_utente}),
        )

    @router.post("/prenotazioni/{id_prenotazione}/annulla")
    async def annulla_prenotazione(
        id_prenotazione: str, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Annulla una prenotazione attiva dell'utente e libera il mezzo (UT.12).
        @param id_prenotazione Id della prenotazione da annullare.
        @param authorization Header Bearer del token di sessione.
        @return Inviluppo con `{id_prenotazione, id_mezzo, annullata}` o "in sviluppo".
        @throws HTTPException 401 senza sessione valida; 409 se non è più attiva.
        """
        id_utente = _id_utente(authorization)
        return await _delega(
            "annulla_prenotazione",
            lambda: attivita.instrada(
                "annulla_prenotazione",
                {"id_prenotazione": id_prenotazione, "id_utente": id_utente},
            ),
        )

    @router.get("/prenotazioni/attive")
    async def prenotazioni_attive_op(
        authorization: str | None = Header(default=None),
    ) -> dict[str, object]:
        """! @brief Tutte le prenotazioni attive per la console operatore (OP.12).
        @param authorization Header Bearer del token di sessione (OP).
        @return Inviluppo con l'elenco prenotazioni attive (con etichetta utente) o "in sviluppo".
        @throws HTTPException 401/403 senza sessione OP valida.
        """
        _richiedi_ruolo(authorization, "OP")
        return await _delega(
            "prenotazioni_attive_op",
            lambda: attivita.instrada("prenotazioni_attive_op", {}),
        )

    @router.post("/prenotazioni/{id_prenotazione}/annulla-op")
    async def annulla_prenotazione_op(
        id_prenotazione: str, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Forza l'annullamento di una prenotazione attiva da parte dell'operatore (OP.12).
        @param id_prenotazione Id della prenotazione da annullare.
        @param authorization Header Bearer del token di sessione (OP).
        @return Inviluppo con `{id_prenotazione, id_mezzo, annullata}` o "in sviluppo".
        @throws HTTPException 401/403 senza sessione OP valida; 409 se non più attiva.
        """
        _richiedi_ruolo(authorization, "OP")
        return await _delega(
            "annulla_prenotazione_op",
            lambda: attivita.instrada(
                "annulla_prenotazione_op", {"id_prenotazione": id_prenotazione}
            ),
        )

    @router.post("/corse")
    async def avvia_corsa(
        corpo: CorsaRichiesta, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Avvio di una corsa su un mezzo (UT.10).
        @param corpo Mezzo da sbloccare ed eventuale prenotazione da convertire.
        @param authorization Header Bearer del token di sessione.
        @return Inviluppo con l'esito (reale a DB cablato) o "in sviluppo".
        @throws HTTPException 401 senza sessione valida; 409 se il mezzo non è sbloccabile.
        """
        id_utente = _id_utente(authorization)
        return await _delega(
            "avvia_corsa",
            lambda: attivita.instrada(
                "avvia_corsa",
                {
                    "id_utente": id_utente,
                    "id_mezzo": corpo.id_mezzo,
                    "id_prenotazione": corpo.id_prenotazione,
                },
            ),
        )

    @router.post("/corse/{id_corsa}/termina")
    async def termina_corsa(
        id_corsa: str,
        corpo: TerminaRichiesta,
        authorization: str | None = Header(default=None),
    ) -> dict[str, object]:
        """! @brief Conclusione di una corsa: costo finale, addebito e fattura (UT.04).
        @param id_corsa Identificativo della corsa da concludere.
        @param corpo Chilometri percorsi.
        @param authorization Header Bearer del token di sessione.
        @return Inviluppo con l'esito (reale a DB cablato) o "in sviluppo".
        @throws HTTPException 401 senza sessione valida.
        """
        _id_utente(authorization)  # autenticazione richiesta
        return await _delega(
            "termina_corsa",
            lambda: attivita.instrada(
                "termina_corsa",
                {"id_corsa": id_corsa, "km": corpo.km, "lat": corpo.lat, "lon": corpo.lon},
            ),
        )

    @router.get("/corse/attiva")
    async def corsa_attiva(
        authorization: str | None = Header(default=None),
    ) -> dict[str, object]:
        """! @brief Corsa in corso/pausa dell'utente per il recupero post-riavvio (UT.10/UT.12).

        Consente all'app di ripristinare la corsa attiva dopo essere stata chiusa/ricaricata
        (lo stato locale è volatile, punto 2): restituisce `{corsa: {...}}` oppure
        `{corsa: null}` se non c'è alcuna corsa in svolgimento.

        @param authorization Header Bearer del token di sessione.
        @return Inviluppo con `{corsa}` (documento o null) o "in sviluppo".
        @throws HTTPException 401 senza sessione valida.
        """
        id_utente = _id_utente(authorization)
        return await _delega(
            "corsa_attiva",
            lambda: attivita.instrada("corsa_attiva", {"id_utente": id_utente}),
        )

    @router.post("/corse/stima")
    async def stima_corsa(
        corpo: StimaRichiesta, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Stima preventiva del costo di una corsa prima di confermare (UT.03).
        @param corpo Mezzo selezionato ed eventuale durata stimata in minuti.
        @param authorization Header Bearer del token di sessione.
        @return Inviluppo con `{costo_stimato_cent}` o "in sviluppo".
        @throws HTTPException 401 senza sessione valida; 400 se il mezzo non esiste.
        """
        id_utente = _id_utente(authorization)  # autenticazione richiesta
        return await _delega(
            "stima_corsa",
            lambda: attivita.instrada(
                "stima_corsa",
                {
                    "id_mezzo": corpo.id_mezzo,
                    "durata_min": corpo.durata_min,
                    "id_utente": id_utente,
                },
            ),
        )

    @router.post("/corse/{id_corsa}/pausa")
    async def pausa_corsa(
        id_corsa: str, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Mette in pausa una corsa mantenendo il mezzo bloccato (UT.12).
        @param id_corsa Identificativo della corsa.
        @param authorization Header Bearer del token di sessione.
        @return Inviluppo con `{id_corsa, stato}` o "in sviluppo".
        @throws HTTPException 401 senza sessione valida.
        """
        _id_utente(authorization)  # autenticazione richiesta
        return await _delega(
            "pausa_corsa", lambda: attivita.instrada("pausa_corsa", {"id_corsa": id_corsa})
        )

    @router.post("/corse/{id_corsa}/riprendi")
    async def riprendi_corsa(
        id_corsa: str, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Riprende una corsa precedentemente messa in pausa (UT.12).
        @param id_corsa Identificativo della corsa.
        @param authorization Header Bearer del token di sessione.
        @return Inviluppo con `{id_corsa, stato}` o "in sviluppo".
        @throws HTTPException 401 senza sessione valida.
        """
        _id_utente(authorization)  # autenticazione richiesta
        return await _delega(
            "riprendi_corsa", lambda: attivita.instrada("riprendi_corsa", {"id_corsa": id_corsa})
        )

    @router.post("/corse/{id_corsa}/valutazione", status_code=201)
    async def valuta_corsa(
        id_corsa: str,
        corpo: ValutazioneRichiesta,
        authorization: str | None = Header(default=None),
    ) -> dict[str, object]:
        """! @brief Registra la valutazione a stelle di una corsa conclusa (UT.16).
        @param id_corsa Identificativo della corsa da valutare.
        @param corpo Valutazione da 1 a 5 stelle.
        @param authorization Header Bearer del token di sessione.
        @return Inviluppo con `{id_corsa, valutazione}` o "in sviluppo".
        @throws HTTPException 401 senza sessione valida; 400 se le stelle sono fuori range.
        """
        _id_utente(authorization)  # autenticazione richiesta
        return await _delega(
            "valuta_corsa",
            lambda: attivita.instrada(
                "valuta_corsa", {"id_corsa": id_corsa, "stelle": corpo.stelle}
            ),
        )

    # ── Profilo utente (UT.21) ────────────────────────────────────────────────
    @router.get("/profilo")
    async def profilo(authorization: str | None = Header(default=None)) -> dict[str, object]:
        """! @brief Dati del profilo dell'utente autenticato (UT.21).
        @param authorization Header Bearer del token di sessione.
        @return Inviluppo con la vista profilo (dati riservati redatti) o "in sviluppo".
        @throws HTTPException 401 senza sessione valida.
        """
        id_account = _id_utente(authorization)
        return await _delega(
            "profilo", lambda: attivita.instrada("profilo", {"id_account": id_account})
        )

    @router.put("/profilo")
    async def aggiorna_profilo(
        corpo: ProfiloAggiornaRichiesta, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Aggiorna i dati anagrafici del profilo (UT.21).
        @param corpo Campi del profilo da aggiornare (whitelist).
        @param authorization Header Bearer del token di sessione.
        @return Inviluppo con la vista profilo aggiornata o "in sviluppo".
        @throws HTTPException 401 senza sessione valida; 409 su conflitto.
        """
        id_account = _id_utente(authorization)
        modifiche = corpo.model_dump(exclude_none=True)
        return await _delega(
            "aggiorna_profilo",
            lambda: attivita.instrada(
                "aggiorna_profilo", {"id_account": id_account, "modifiche": modifiche}
            ),
        )

    @router.post("/profilo/pagamenti", status_code=201)
    async def registra_pagamento(
        corpo: MetodoPagamentoRichiesta, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Registra un metodo di pagamento verificato (UT.11).
        @param corpo Dati della carta (il PAN non viene mai persistito in chiaro).
        @param authorization Header Bearer del token di sessione.
        @return Inviluppo con `{id_metodo, pan_mascherato}` o "in sviluppo".
        @throws HTTPException 401 senza sessione valida; 400 se la carta non è valida.
        """
        id_account = _id_utente(authorization)
        return await _delega(
            "registra_metodo_pagamento",
            lambda: attivita.instrada(
                "registra_metodo_pagamento",
                {
                    "id_account": id_account,
                    "numero": corpo.numero,
                    "mese": corpo.mese,
                    "anno": corpo.anno,
                    "titolare": corpo.titolare,
                    "cvv": corpo.cvv,
                    "indirizzo_fatturazione": corpo.indirizzo_fatturazione,
                },
            ),
        )

    @router.post("/profilo/abbonamenti", status_code=201)
    async def sottoscrivi_abbonamento(
        corpo: AbbonamentoRichiesta, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Sottoscrive un piano di abbonamento periodico (UT.18).
        @param corpo Identificativo del piano scelto.
        @param authorization Header Bearer del token di sessione.
        @return Inviluppo con `{id_abbonamento, id_piano, data_fine}` o "in sviluppo".
        @throws HTTPException 401 senza sessione valida; 400 se il piano non esiste.
        """
        id_account = _id_utente(authorization)
        return await _delega(
            "sottoscrivi_abbonamento",
            lambda: attivita.instrada(
                "sottoscrivi_abbonamento", {"id_account": id_account, "id_piano": corpo.id_piano}
            ),
        )

    @router.get("/profilo/abbonamenti")
    async def elenca_abbonamenti(
        authorization: str | None = Header(default=None),
    ) -> dict[str, object]:
        """! @brief Elenca gli abbonamenti dell'utente autenticato (UT.18/UT.21).
        @param authorization Header Bearer del token di sessione.
        @return Inviluppo con l'elenco abbonamenti o "in sviluppo".
        @throws HTTPException 401 senza sessione valida.
        """
        id_account = _id_utente(authorization)
        return await _delega(
            "abbonamenti_utente",
            lambda: attivita.instrada("abbonamenti_utente", {"id_account": id_account}),
        )

    @router.post("/profilo/consensi", status_code=201)
    async def registra_consenso(
        corpo: ConsensoRichiesta, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Registra un consenso GDPR esplicito (IIN-16).
        @param corpo Tipo di consenso, valore e versione dell'informativa.
        @param authorization Header Bearer del token di sessione.
        @return Inviluppo con `{tipo, concesso}` o "in sviluppo".
        @throws HTTPException 401 senza sessione valida.
        """
        id_account = _id_utente(authorization)
        return await _delega(
            "registra_consenso",
            lambda: attivita.instrada(
                "registra_consenso",
                {
                    "id_account": id_account,
                    "tipo": corpo.tipo,
                    "concesso": corpo.concesso,
                    "versione_privacy": corpo.versione_privacy,
                },
            ),
        )

    @router.post("/profilo/kyc", status_code=201)
    async def carica_kyc(
        corpo: KycRichiesta, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Carica un documento KYC (solo PDF/JPG/PNG, UT.22.2, IIN-6/AG-SEC-01).
        @param corpo Tipo di documento e nome del file (estensione validata server-side).
        @param authorization Header Bearer del token di sessione.
        @return Inviluppo con `{id_documento, stato_verifica}` o "in sviluppo".
        @throws HTTPException 401 senza sessione valida; 400 se formato/tipo non ammessi.
        """
        id_account = _id_utente(authorization)
        return await _delega(
            "carica_kyc",
            lambda: attivita.instrada(
                "carica_kyc",
                {"id_account": id_account, "tipo": corpo.tipo, "nome_file": corpo.nome_file},
            ),
        )

    # ── Storico corse e fatture (UT.17/UT.25) ─────────────────────────────────
    @router.get("/corse")
    async def storico_corse(authorization: str | None = Header(default=None)) -> dict[str, object]:
        """! @brief Storico delle corse dell'utente autenticato (UT.17).
        @param authorization Header Bearer del token di sessione.
        @return Inviluppo con l'elenco corse o "in sviluppo".
        @throws HTTPException 401 senza sessione valida.
        """
        id_utente = _id_utente(authorization)
        return await _delega(
            "storico_corse", lambda: attivita.instrada("storico_corse", {"id_utente": id_utente})
        )

    @router.get("/fatture")
    async def fatture(authorization: str | None = Header(default=None)) -> dict[str, object]:
        """! @brief Elenco delle fatture dell'utente autenticato (UT.25).
        @param authorization Header Bearer del token di sessione.
        @return Inviluppo con l'elenco fatture o "in sviluppo".
        @throws HTTPException 401 senza sessione valida.
        """
        id_utente = _id_utente(authorization)
        return await _delega(
            "fatture", lambda: attivita.instrada("fatture_utente", {"id_utente": id_utente})
        )

    # ── Dashboard OP: flotta e coda assistenza (AP.03/OP.03/OP.08/OP.20) ──────
    @router.get("/flotta")
    async def flotta(
        stato: str | None = None, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Stato della flotta per la dashboard operatore (AP.03/OP.03/OP.20).
        @param stato Filtro opzionale su stato operativo (es. "guasto").
        @param authorization Header Bearer del token di sessione (OP/PA).
        @return Inviluppo con l'elenco mezzi o "in sviluppo".
        @throws HTTPException 401/403 senza sessione OP/PA valida.
        """
        _richiedi_ruolo(authorization, "OP", "PA")
        return await _delega("flotta", lambda: attivita.instrada("elenco_flotta", {"stato": stato}))

    @router.get("/mezzi-guasti")
    async def mezzi_guasti(
        authorization: str | None = Header(default=None),
    ) -> dict[str, object]:
        """! @brief Elenca i mezzi in stato "Guasto" da ritirare (OP.03).
        @param authorization Header Bearer del token di sessione (OP).
        @return Inviluppo con l'elenco mezzi guasti o "in sviluppo".
        @throws HTTPException 401/403 senza sessione OP valida.
        """
        _richiedi_ruolo(authorization, "OP")
        return await _delega("mezzi_guasti", lambda: attivita.instrada("mezzi_guasti", {}))

    @router.get("/flotta/report")
    async def report_flotta(
        authorization: str | None = Header(default=None),
    ) -> dict[str, object]:
        """! @brief Report giornaliero dei mezzi per stato e batteria scarica (OP.13).
        @param authorization Header Bearer del token di sessione (OP).
        @return Inviluppo con `{per_stato, batteria_scarica, totale}` o "in sviluppo".
        @throws HTTPException 401/403 senza sessione OP valida.
        """
        _richiedi_ruolo(authorization, "OP")
        return await _delega("report_flotta", lambda: attivita.instrada("report_flotta", {}))

    @router.post("/soglie/area", status_code=201)
    async def imposta_soglia_area(
        corpo: SogliaAreaRichiesta, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Imposta la soglia minima di mezzi per un'area (OP.02).
        @param corpo Id area e numero minimo di mezzi.
        @param authorization Header Bearer del token di sessione (OP).
        @return Inviluppo con l'id della soglia creata o "in sviluppo".
        @throws HTTPException 401/403 senza sessione OP valida.
        """
        sessione = _richiedi_ruolo(authorization, "OP")
        return await _delega(
            "imposta_soglia_area",
            lambda: attivita.instrada(
                "imposta_soglia_area",
                {
                    "id_area": corpo.id_area,
                    "minimo": corpo.minimo,
                    "id_operatore": str(sessione.get("id_account")),
                },
            ),
        )

    @router.post("/soglie/batteria", status_code=201)
    async def imposta_soglia_batteria(
        corpo: SogliaBatteriaRichiesta, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Imposta la soglia di allerta batteria (OP.22).
        @param corpo Percentuale di allerta ed eventuale tipologia di mezzo.
        @param authorization Header Bearer del token di sessione (OP).
        @return Inviluppo con l'id della soglia creata o "in sviluppo".
        @throws HTTPException 401/403 senza sessione OP valida.
        """
        sessione = _richiedi_ruolo(authorization, "OP")
        return await _delega(
            "imposta_soglia_batteria",
            lambda: attivita.instrada(
                "imposta_soglia_batteria",
                {
                    "percentuale": corpo.percentuale,
                    "tipo_mezzo": corpo.tipo_mezzo,
                    "id_operatore": str(sessione.get("id_account")),
                },
            ),
        )

    @router.get("/soglie/allerte")
    async def soglie_allerte(
        authorization: str | None = Header(default=None),
    ) -> dict[str, object]:
        """! @brief Valuta le soglie configurate e restituisce le allerte attive (OP.02/OP.22).
        @param authorization Header Bearer del token di sessione (OP).
        @return Inviluppo con l'elenco di allerte o "in sviluppo".
        @throws HTTPException 401/403 senza sessione OP valida.
        """
        _richiedi_ruolo(authorization, "OP")
        return await _delega("verifica_soglie", lambda: attivita.instrada("verifica_soglie", {}))

    @router.get("/mezzi/{codice}/telemetria")
    async def telemetria_mezzo(
        codice: str, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Registro telemetrico di un mezzo (sblocchi, urti, anomalie, GPS) (OP.07/14).
        @param codice Codice identificativo del mezzo.
        @param authorization Header Bearer del token di sessione (OP).
        @return Inviluppo con l'elenco eventi telemetrici o "in sviluppo".
        @throws HTTPException 401/403 senza sessione OP valida.
        """
        _richiedi_ruolo(authorization, "OP")
        return await _delega(
            "log_telemetria",
            lambda: attivita.instrada("log_telemetria", {"codice_mezzo": codice}),
        )

    @router.post("/mezzi/{codice}/blocco-motore", status_code=201)
    async def blocco_motore_mezzo(
        codice: str, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Invia il blocco motore remoto anti-spostamento a un mezzo (OP.11).
        @param codice Codice identificativo del mezzo da immobilizzare.
        @param authorization Header Bearer del token di sessione (OP).
        @return Inviluppo con l'esito del comando o "in sviluppo".
        @throws HTTPException 401/403 senza sessione OP valida.
        """
        _richiedi_ruolo(authorization, "OP")
        return await _delega(
            "blocca_motore",
            lambda: attivita.instrada("blocca_motore", {"codice_mezzo": codice}),
        )

    @router.post("/mezzi/{codice}/sblocco-motore", status_code=201)
    async def sblocco_motore_mezzo(
        codice: str, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Revoca il blocco motore remoto di un mezzo e lo riabilita (OP.11).
        @param codice Codice identificativo del mezzo da riabilitare.
        @param authorization Header Bearer del token di sessione (OP).
        @return Inviluppo con l'esito del comando o "in sviluppo".
        @throws HTTPException 401/403 senza sessione OP valida.
        """
        _richiedi_ruolo(authorization, "OP")
        return await _delega(
            "sblocca_motore",
            lambda: attivita.instrada("sblocca_motore", {"codice_mezzo": codice}),
        )

    @router.get("/assistenza")
    async def coda_assistenza(
        stato: str | None = None, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Coda centralizzata delle richieste di assistenza (OP.08).
        @param stato Filtro opzionale su stato (es. "aperto").
        @param authorization Header Bearer del token di sessione (OP).
        @return Inviluppo con l'elenco ticket o "in sviluppo".
        @throws HTTPException 401/403 senza sessione OP valida.
        """
        _richiedi_ruolo(authorization, "OP")
        return await _delega(
            "elenca_assistenza", lambda: attivita.instrada("elenca_assistenza", {"stato": stato})
        )

    @router.post("/assistenza", status_code=201)
    async def apri_assistenza(
        corpo: AssistenzaApriRichiesta, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Apre una richiesta di assistenza per l'utente autenticato (UT.09).
        @param corpo Oggetto, messaggio ed eventuale corsa correlata.
        @param authorization Header Bearer del token di sessione (UT).
        @return Inviluppo con l'id del ticket creato o "in sviluppo".
        @throws HTTPException 401 senza sessione valida.
        """
        id_utente = _id_utente(authorization)
        return await _delega(
            "apri_assistenza",
            lambda: attivita.instrada(
                "apri_assistenza",
                {
                    "id_utente": id_utente,
                    "oggetto": corpo.oggetto,
                    "messaggio": corpo.messaggio,
                    "id_corsa": corpo.id_corsa,
                },
            ),
        )

    @router.put("/assistenza/{id_ticket}/risposta")
    async def rispondi_assistenza(
        id_ticket: str,
        corpo: AssistenzaRispostaRichiesta,
        authorization: str | None = Header(default=None),
    ) -> dict[str, object]:
        """! @brief Prende in carico e risponde a un ticket di assistenza (OP.08).
        @param id_ticket Id del ticket di assistenza.
        @param corpo Risposta e nuovo stato.
        @param authorization Header Bearer del token di sessione (OP).
        @return Inviluppo con l'esito o "in sviluppo".
        @throws HTTPException 401/403 senza sessione OP valida.
        """
        sessione = _richiedi_ruolo(authorization, "OP")
        return await _delega(
            "rispondi_assistenza",
            lambda: attivita.instrada(
                "rispondi_assistenza",
                {
                    "id_ticket": id_ticket,
                    "id_operatore": str(sessione.get("id_account")),
                    "risposta": corpo.risposta,
                    "stato": corpo.stato,
                },
            ),
        )

    # ── Dashboard PA: analitiche e geofencing (AP.01/02/04/06/07/08) ──────────
    @router.get("/analitiche")
    async def analitiche(
        dalla_data: str | None = None,
        alla_data: str | None = None,
        authorization: str | None = Header(default=None),
    ) -> dict[str, object]:
        """! @brief Report di mobilità aggregati e anonimi per la PA (AP.01/02/07, IIN-15).
        @param dalla_data Inizio intervallo (ISO-8601) opzionale.
        @param alla_data Fine intervallo (ISO-8601) opzionale.
        @param authorization Header Bearer del token di sessione (PA/OP).
        @return Inviluppo con gli aggregati anonimi o "in sviluppo".
        @throws HTTPException 401/403 senza sessione PA/OP valida.
        """
        _richiedi_ruolo(authorization, "PA", "OP")
        return await _delega(
            "analitiche",
            lambda: attivita.instrada(
                "analitiche", {"dalla_data": dalla_data, "alla_data": alla_data}
            ),
        )

    @router.get("/analitiche/noleggi")
    async def analitiche_noleggi(
        dalla_data: str | None = None,
        alla_data: str | None = None,
        authorization: str | None = Header(default=None),
    ) -> dict[str, object]:
        """! @brief Conteggio noleggi per tipologia di mezzo, anonimo (AP.01, IIN-15).
        @param dalla_data Inizio intervallo (ISO-8601) opzionale.
        @param alla_data Fine intervallo (ISO-8601) opzionale.
        @param authorization Header Bearer del token di sessione (PA/OP).
        @return Inviluppo con `{noleggi: {tipo: conteggio}}` o "in sviluppo".
        @throws HTTPException 401/403 senza sessione PA/OP valida.
        """
        _richiedi_ruolo(authorization, "PA", "OP")
        return await _delega(
            "report_noleggi",
            lambda: attivita.instrada(
                "report_noleggi", {"dalla_data": dalla_data, "alla_data": alla_data}
            ),
        )

    @router.get("/analitiche/flussi")
    async def analitiche_flussi(
        dalla_data: str | None = None,
        alla_data: str | None = None,
        authorization: str | None = Header(default=None),
    ) -> dict[str, object]:
        """! @brief Distribuzione dei noleggi per fascia oraria, anonima (AP.02, IIN-15).
        @param dalla_data Inizio intervallo (ISO-8601) opzionale.
        @param alla_data Fine intervallo (ISO-8601) opzionale.
        @param authorization Header Bearer del token di sessione (PA/OP).
        @return Inviluppo con `{flussi: {ora: conteggio}}` o "in sviluppo".
        @throws HTTPException 401/403 senza sessione PA/OP valida.
        """
        _richiedi_ruolo(authorization, "PA", "OP")
        return await _delega(
            "flussi_orari",
            lambda: attivita.instrada(
                "flussi_orari", {"dalla_data": dalla_data, "alla_data": alla_data}
            ),
        )

    @router.get("/analitiche/operativi")
    async def analitiche_operativi(
        authorization: str | None = Header(default=None),
    ) -> dict[str, object]:
        """! @brief Percentuale mezzi operativi vs manutenzione vs scarico (AP.03).
        @param authorization Header Bearer del token di sessione (PA/OP).
        @return Inviluppo con `{operativi: {operativi, manutenzione, scarico}}` o "in sviluppo".
        @throws HTTPException 401/403 senza sessione PA/OP valida.
        """
        _richiedi_ruolo(authorization, "PA", "OP")
        return await _delega("mezzi_operativi", lambda: attivita.instrada("mezzi_operativi", {}))

    @router.get("/analitiche/co2")
    async def analitiche_co2(
        dalla_data: str | None = None,
        alla_data: str | None = None,
        authorization: str | None = Header(default=None),
    ) -> dict[str, object]:
        """! @brief Stima della CO2 risparmiata dalla flotta elettrica, anonima (AP.07, IIN-15).
        @param dalla_data Inizio intervallo (ISO-8601) opzionale.
        @param alla_data Fine intervallo (ISO-8601) opzionale.
        @param authorization Header Bearer del token di sessione (PA/OP).
        @return Inviluppo con `{km_totali, co2_risparmiata_kg, km_per_tipo}` o "in sviluppo".
        @throws HTTPException 401/403 senza sessione PA/OP valida.
        """
        _richiedi_ruolo(authorization, "PA", "OP")
        return await _delega(
            "co2",
            lambda: attivita.instrada("co2", {"dalla_data": dalla_data, "alla_data": alla_data}),
        )

    @router.get("/aree")
    async def elenca_aree(
        solo_attive: bool = False, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Elenca le aree limitate configurate (AP.04/06/08).
        @param solo_attive Se True, restituisce solo le aree attive.
        @param authorization Header Bearer del token di sessione.
        @return Inviluppo con l'elenco aree o "in sviluppo".
        @throws HTTPException 401 senza sessione valida.
        """
        _sessione(authorization)
        return await _delega(
            "elenca_aree", lambda: attivita.instrada("elenca_aree", {"solo_attive": solo_attive})
        )

    @router.post("/aree", status_code=201)
    async def crea_area(
        corpo: AreaRichiesta, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Crea un'area limitata sulla mappa (AP.04/06/08).
        @param corpo Definizione dell'area (tipo, nome, poligono, limite velocità).
        @param authorization Header Bearer del token di sessione (PA/OP).
        @return Inviluppo con l'id dell'area creata o "in sviluppo".
        @throws HTTPException 401/403 senza sessione PA/OP valida.
        """
        sessione = _richiedi_ruolo(authorization, "PA", "OP")
        return await _delega(
            "crea_area",
            lambda: attivita.instrada(
                "crea_area",
                {
                    "dati": corpo.model_dump(exclude_none=True),
                    "creata_da": sessione.get("id_account"),
                },
            ),
        )

    @router.delete("/aree/{id_area}")
    async def elimina_area(
        id_area: str, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Rimuove un'area limitata (AP.04).
        @param id_area Id dell'area da eliminare.
        @param authorization Header Bearer del token di sessione (PA/OP).
        @return Inviluppo con l'esito o "in sviluppo".
        @throws HTTPException 401/403 senza sessione PA/OP valida.
        """
        _richiedi_ruolo(authorization, "PA", "OP")
        return await _delega(
            "elimina_area", lambda: attivita.instrada("elimina_area", {"id_area": id_area})
        )

    # ── Gestione utenti/AP (OP.10/OP.17/OP.18) ────────────────────────────────
    @router.get("/utenti")
    async def elenca_utenti(
        ruolo: str | None = None, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Elenca gli account per la gestione operatore (OP.10/OP.18).
        @param ruolo Filtro opzionale sul ruolo RBAC (UT/OP/PA).
        @param authorization Header Bearer del token di sessione (OP).
        @return Inviluppo con l'elenco account (campi riservati redatti) o "in sviluppo".
        @throws HTTPException 401/403 senza sessione OP valida.
        """
        _richiedi_ruolo(authorization, "OP")
        return await _delega(
            "elenca_account", lambda: attivita.instrada("elenca_account", {"ruolo": ruolo})
        )

    @router.get("/amministrazioni")
    async def elenca_amministrazioni(
        authorization: str | None = Header(default=None),
    ) -> dict[str, object]:
        """! @brief Elenca gli account Amministrazione Pubblica provvisionati (OP.17).
        @param authorization Header Bearer del token di sessione (OP).
        @return Inviluppo con l'elenco account PA (campi riservati redatti) o "in sviluppo".
        @throws HTTPException 401/403 senza sessione OP valida.
        """
        _richiedi_ruolo(authorization, "OP")
        return await _delega(
            "elenca_account", lambda: attivita.instrada("elenca_account", {"ruolo": "PA"})
        )

    @router.put("/utenti/{id_account}/stato")
    async def imposta_stato_utente(
        id_account: str,
        corpo: StatoAccountRichiesta,
        authorization: str | None = Header(default=None),
    ) -> dict[str, object]:
        """! @brief Sospende o riattiva un account utente (OP.10 sospendi / OP.18 sblocca).
        @param id_account Id dell'account su cui agire.
        @param corpo Nuovo stato ("attivo" o "sospeso").
        @param authorization Header Bearer del token di sessione (OP).
        @return Inviluppo con la vista account aggiornata o "in sviluppo".
        @throws HTTPException 401/403 senza sessione OP valida.
        """
        _richiedi_ruolo(authorization, "OP")
        return await _delega(
            "imposta_stato_account",
            lambda: attivita.instrada(
                "imposta_stato_account", {"id_account": id_account, "stato": corpo.stato}
            ),
        )

    @router.post("/amministrazioni", status_code=201)
    async def provisiona_amministrazione(
        corpo: ProvisioningPaRichiesta, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Provisiona un account Amministrazione Pubblica (OP.17, IIN-12).
        @param corpo Email, username, ente ed email istituzionale del nuovo account PA.
        @param authorization Header Bearer del token di sessione (OP).
        @return Inviluppo con {id_account, password_temporanea} o "in sviluppo".
        @throws HTTPException 401/403 senza sessione OP valida; 409 se email/username già in uso.
        """
        _richiedi_ruolo(authorization, "OP")
        return await _delega(
            "provisiona_pa",
            lambda: attivita.instrada(
                "provisiona_pa",
                {
                    "email": corpo.email,
                    "username": corpo.username,
                    "ente": corpo.ente,
                    "email_istituzionale": corpo.email_istituzionale,
                },
            ),
        )

    # ── Ticket di manutenzione veicoli (OP.16/OP.19) ──────────────────────────
    @router.get("/manutenzione")
    async def elenca_manutenzione(
        stato: str | None = None, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Elenca i ticket di manutenzione per la dashboard operatore (OP.19).
        @param stato Filtro opzionale su stato (aperto/assegnato/chiuso).
        @param authorization Header Bearer del token di sessione (OP).
        @return Inviluppo con l'elenco ticket o "in sviluppo".
        @throws HTTPException 401/403 senza sessione OP valida.
        """
        _richiedi_ruolo(authorization, "OP")
        return await _delega(
            "elenca_manutenzione",
            lambda: attivita.instrada("elenca_manutenzione", {"stato": stato}),
        )

    @router.post("/manutenzione", status_code=201)
    async def crea_manutenzione(
        corpo: ManutenzioneRichiesta, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Crea e traccia un ticket di manutenzione per un mezzo guasto (OP.16/OP.19).
        @param corpo Mezzo, descrizione del guasto e priorità.
        @param authorization Header Bearer del token di sessione (OP).
        @return Inviluppo con l'id del ticket creato o "in sviluppo".
        @throws HTTPException 401/403 senza sessione OP valida; 409 se il mezzo non esiste.
        """
        sessione = _richiedi_ruolo(authorization, "OP")
        return await _delega(
            "crea_manutenzione",
            lambda: attivita.instrada(
                "crea_manutenzione",
                {
                    "id_mezzo": corpo.id_mezzo,
                    "id_operatore": str(sessione.get("id_account")),
                    "descrizione": corpo.descrizione,
                    "priorita": corpo.priorita,
                },
            ),
        )

    @router.put("/manutenzione/{id_ticket}/assegna")
    async def assegna_manutenzione(
        id_ticket: str,
        corpo: AssegnaTecnicoRichiesta,
        authorization: str | None = Header(default=None),
    ) -> dict[str, object]:
        """! @brief Assegna un ticket di manutenzione a un tecnico registrato (OP.16).
        @param id_ticket Id del ticket di manutenzione.
        @param corpo Id del tecnico assegnatario.
        @param authorization Header Bearer del token di sessione (OP).
        @return Inviluppo con l'esito o "in sviluppo".
        @throws HTTPException 401/403 senza sessione OP valida.
        """
        _richiedi_ruolo(authorization, "OP")
        return await _delega(
            "assegna_manutenzione",
            lambda: attivita.instrada(
                "assegna_manutenzione", {"id_ticket": id_ticket, "id_tecnico": corpo.id_tecnico}
            ),
        )

    @router.put("/manutenzione/{id_ticket}/chiudi")
    async def chiudi_manutenzione(
        id_ticket: str, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Chiude un ticket di manutenzione a intervento concluso (OP.19).
        @param id_ticket Id del ticket di manutenzione.
        @param authorization Header Bearer del token di sessione (OP).
        @return Inviluppo con l'esito o "in sviluppo".
        @throws HTTPException 401/403 senza sessione OP valida.
        """
        _richiedi_ruolo(authorization, "OP")
        return await _delega(
            "chiudi_manutenzione",
            lambda: attivita.instrada("chiudi_manutenzione", {"id_ticket": id_ticket}),
        )

    @router.get("/tecnici")
    async def elenca_tecnici(
        authorization: str | None = Header(default=None),
    ) -> dict[str, object]:
        """! @brief Elenca i tecnici manutentori assegnabili ai ticket (OP.16).
        @param authorization Header Bearer del token di sessione (OP).
        @return Inviluppo con l'elenco tecnici o "in sviluppo".
        @throws HTTPException 401/403 senza sessione OP valida.
        """
        _richiedi_ruolo(authorization, "OP")
        return await _delega("elenca_tecnici", lambda: attivita.instrada("elenca_tecnici", {}))

    # ── Promozioni e incentivi geografici (OP.09/OP.15) ───────────────────────
    @router.get("/promozioni")
    async def elenca_promozioni(
        solo_attive: bool = False, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Elenca le promozioni/incentivi configurati (OP.09/OP.15).
        @param solo_attive Se True, restituisce solo le promozioni attive.
        @param authorization Header Bearer del token di sessione (OP/PA).
        @return Inviluppo con l'elenco promozioni o "in sviluppo".
        @throws HTTPException 401/403 senza sessione OP/PA valida.
        """
        _richiedi_ruolo(authorization, "OP", "PA")
        return await _delega(
            "elenca_promozioni",
            lambda: attivita.instrada("elenca_promozioni", {"solo_attive": solo_attive}),
        )

    @router.post("/promozioni", status_code=201)
    async def crea_promozione(
        corpo: PromozioneRichiesta, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Configura una promozione/incentivo geografico o di parcheggio (OP.09/OP.15).
        @param corpo Tipo, descrizione, valore ed area opzionale della promozione.
        @param authorization Header Bearer del token di sessione (OP).
        @return Inviluppo con l'id della promozione creata o "in sviluppo".
        @throws HTTPException 401/403 senza sessione OP valida.
        """
        sessione = _richiedi_ruolo(authorization, "OP")
        return await _delega(
            "crea_promozione",
            lambda: attivita.instrada(
                "crea_promozione",
                {
                    "dati": corpo.model_dump(exclude_none=True),
                    "creata_da": str(sessione.get("id_account")),
                },
            ),
        )

    @router.delete("/promozioni/{id_promozione}")
    async def disattiva_promozione(
        id_promozione: str, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Disattiva una promozione configurata (OP.15).
        @param id_promozione Id della promozione da disattivare.
        @param authorization Header Bearer del token di sessione (OP).
        @return Inviluppo con l'esito o "in sviluppo".
        @throws HTTPException 401/403 senza sessione OP valida.
        """
        _richiedi_ruolo(authorization, "OP")
        return await _delega(
            "disattiva_promozione",
            lambda: attivita.instrada("disattiva_promozione", {"id_promozione": id_promozione}),
        )

    # ── Grandi eventi cittadini (AP.09) ───────────────────────────────────────
    @router.get("/eventi")
    async def elenca_eventi(
        authorization: str | None = Header(default=None),
    ) -> dict[str, object]:
        """! @brief Elenca i grandi eventi cittadini configurati (AP.09).
        @param authorization Header Bearer del token di sessione (OP/PA).
        @return Inviluppo con l'elenco eventi o "in sviluppo".
        @throws HTTPException 401/403 senza sessione OP/PA valida.
        """
        _richiedi_ruolo(authorization, "OP", "PA")
        return await _delega("elenca_eventi", lambda: attivita.instrada("elenca_eventi", {}))

    @router.post("/eventi", status_code=201)
    async def crea_evento(
        corpo: EventoRichiesta, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Inserisce un grande evento cittadino su mappa (AP.09).
        @param corpo Nome, date di validità e perimetro geografico dell'evento.
        @param authorization Header Bearer del token di sessione (PA).
        @return Inviluppo con l'id dell'evento creato o "in sviluppo".
        @throws HTTPException 401/403 senza sessione PA valida.
        """
        sessione = _richiedi_ruolo(authorization, "PA")
        return await _delega(
            "crea_evento",
            lambda: attivita.instrada(
                "crea_evento",
                {
                    "dati": corpo.model_dump(exclude_none=True),
                    "creata_da": str(sessione.get("id_account")),
                },
            ),
        )

    @router.delete("/eventi/{id_evento}")
    async def elimina_evento(
        id_evento: str, authorization: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Elimina un grande evento cittadino dalla mappa (AP.09).
        @param id_evento Id dell'evento (area_limitata di tipo "evento") da rimuovere.
        @param authorization Header Bearer del token di sessione (PA).
        @return Inviluppo con l'esito dell'eliminazione o "in sviluppo".
        @throws HTTPException 401/403 senza sessione PA valida.
        """
        _richiedi_ruolo(authorization, "PA")
        return await _delega(
            "elimina_evento",
            lambda: attivita.instrada("elimina_evento", {"id_evento": id_evento}),
        )

    return router
