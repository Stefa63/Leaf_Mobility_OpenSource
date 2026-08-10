"""! @file controllo_router.py
@brief Router degli endpoint di controllo loopback usati dalla console operativa.
"""

from __future__ import annotations

from fastapi import APIRouter, Header, HTTPException
from pydantic import BaseModel, Field

from server.runtime.servizi import ServiziRuntime

#! Prefisso degli endpoint operativi (non sono API client-facing).
PREFISSO = "/__admin__"


class CreaOpRichiesta(BaseModel):
    """! @brief Corpo della richiesta di creazione di un account OP."""

    username: str = Field(min_length=1, max_length=64)
    nome: str = Field(min_length=1, max_length=128)
    email: str = Field(min_length=3, max_length=254)


class QueryRichiesta(BaseModel):
    """! @brief Corpo di una interrogazione amministrativa."""

    sql: str = Field(min_length=1)


class RestoreRichiesta(BaseModel):
    """! @brief Corpo della richiesta di ripristino da archivio."""

    nome: str = Field(min_length=1)


class AutoBackupRichiesta(BaseModel):
    """! @brief Corpo del toggle del backup automatico."""

    attivo: bool


class ConfigRichiesta(BaseModel):
    """! @brief Corpo dell'aggiornamento delle impostazioni personalizzabili a caldo."""

    backup_auto: bool | None = None
    backup_intervallo_s: int | None = Field(default=None, ge=5)
    backup_retention: int | None = Field(default=None, ge=1)
    soglia_cpu: float | None = Field(default=None, gt=0, le=100)
    soglia_ram: float | None = Field(default=None, gt=0, le=100)


def crea_router(servizi: ServiziRuntime) -> APIRouter:
    """! @brief Costruisce il router di controllo legato ai servizi runtime.
    @param servizi Contenitore dei servizi condivisi del processo server.
    @return APIRouter con gli endpoint operativi (metriche, hardware, OP, backup, query).
    """
    router = APIRouter(prefix=PREFISSO, tags=["controllo"])

    def _verifica_admin(token: str | None) -> None:
        """! @brief Autorizza le operazioni admin (interrogazioni).
        @param token Token fornito nell'header X-Admin-Token.
        @throws HTTPException 403 se e' configurato un token e non corrisponde.
        """
        atteso = servizi.impostazioni.admin_token
        if atteso and token != atteso:
            raise HTTPException(status_code=403, detail="Operazione riservata all'admin")

    @router.get("/salute")
    async def salute() -> dict[str, object]:
        """! @brief Health check del runtime.
        @return Stato e uptime del server.
        """
        snap = servizi.metriche.snapshot()
        return {"stato": "ok", "uptime_s": snap["uptime_s"]}

    @router.get("/metriche")
    async def metriche() -> dict[str, object]:
        """! @brief Metriche di carico correnti.
        @return Snapshot del registro metriche (byte, richieste, tempi, concorrenza).
        """
        return servizi.metriche.snapshot()

    @router.get("/hardware")
    async def hardware() -> dict[str, object]:
        """! @brief Sforzo hardware corrente.
        @return Snapshot di CPU/RAM/I/O e le soglie di allerta configurate.
        """
        dati = servizi.monitor.istantanea()
        dati["soglia_cpu"] = servizi.soglia_cpu
        dati["soglia_ram"] = servizi.soglia_ram
        return dati

    @router.get("/config")
    async def leggi_config() -> dict[str, object]:
        """! @brief Restituisce le impostazioni personalizzabili correnti.
        @return Mappa delle impostazioni configurabili a caldo.
        """
        return servizi.configurazione()

    @router.post("/config")
    async def aggiorna_config(
        corpo: ConfigRichiesta, x_admin_token: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Aggiorna a caldo le impostazioni personalizzabili (solo admin).

        Applica solo i campi forniti (non nulli), aggiorna lo stato runtime e
        persiste la scelta in config.json (sopravvive al riavvio del runtime).

        @param corpo Impostazioni da modificare (campi opzionali).
        @param x_admin_token Token admin (header X-Admin-Token), se configurato.
        @return Configurazione personalizzata aggiornata.
        @throws HTTPException 403 se non autorizzato.
        """
        _verifica_admin(x_admin_token)
        modifiche = {k: v for k, v in corpo.model_dump().items() if v is not None}
        aggiornata = servizi.aggiorna_config(modifiche)
        servizi.audit.registra("config", "ok", modifiche)
        return aggiornata

    @router.get("/op")
    async def elenco_op() -> dict[str, object]:
        """! @brief Elenca gli account OP provvisori.
        @return Lista degli OP (senza dati segreti).
        """
        return {"op": servizi.provisioning.elenco()}

    @router.post("/op")
    async def crea_op(corpo: CreaOpRichiesta) -> dict[str, object]:
        """! @brief Crea un OP con password temporanea (OP.17, IIN-12).

        Tenta la creazione reale su Firestore (via @ref GestoreProfiliEkyc); se la
        persistenza non e' configurata, cade sullo store locale provvisorio.

        @param corpo Richiesta con username, nome ed email dell'operatore.
        @return Username, nome, email, password temporanea e tipo di persistenza.
        @throws HTTPException 409 se email/username gia' in uso.
        """
        from server.integration_tier.data_access_manager import (
            ErrorePersistenza,
        )
        from server.presentation_tier.gestore_attivita import GestoreAttivita

        try:
            attivita = GestoreAttivita()
            esito = attivita.instrada(
                "provisiona_op",
                {"email": corpo.email, "username": corpo.username, "nome": corpo.nome},
            )
            servizi.audit.registra(
                "op_create", "ok", {"username": corpo.username, "persistenza": "firestore"}
            )
            return {
                "username": corpo.username,
                "nome": corpo.nome,
                "email": corpo.email,
                "password_temporanea": esito["password_temporanea"],
                "deve_cambiare_password": True,
                "persistenza": "firestore",
            }
        except NotImplementedError:
            pass
        except ErrorePersistenza as exc:
            servizi.audit.registra("op_create", "errore", {"username": corpo.username})
            raise HTTPException(status_code=409, detail=str(exc)) from exc
        try:
            temporanea = servizi.provisioning.crea_op(corpo.username)
        except ValueError as exc:
            servizi.audit.registra("op_create", "errore", {"username": corpo.username})
            raise HTTPException(status_code=409, detail=str(exc)) from exc
        servizi.audit.registra(
            "op_create", "ok", {"username": corpo.username, "persistenza": "locale"}
        )
        return {
            "username": corpo.username,
            "nome": corpo.nome,
            "email": corpo.email,
            "password_temporanea": temporanea,
            "deve_cambiare_password": True,
            "persistenza": "locale",
        }

    @router.post("/query")
    async def interroga(
        corpo: QueryRichiesta, x_admin_token: str | None = Header(default=None)
    ) -> dict[str, object]:
        """! @brief Interrogazione amministrativa (solo admin).
        @param corpo Richiesta contenente l'istruzione SQL.
        @param x_admin_token Token admin (header X-Admin-Token), se configurato.
        @return Esito dell'interrogazione; in questa fase il DB e' in sviluppo.
        @throws HTTPException 403 se non autorizzato.
        """
        _verifica_admin(x_admin_token)
        servizi.audit.registra("query", "rifiutata_db_in_sviluppo", {"sql": corpo.sql[:120]})
        return {
            "disponibile": False,
            "messaggio": "Database in sviluppo: interrogazioni non ancora eseguibili.",
            "sql_ricevuto": corpo.sql,
        }

    @router.get("/backup")
    async def elenco_backup() -> dict[str, object]:
        """! @brief Elenca gli archivi di backup disponibili.
        @return Lista archivi e stato del backup automatico.
        """
        return {"archivi": servizi.backup.elenco(), "auto_attivo": servizi.backup_auto_attivo}

    @router.post("/backup")
    async def backup_manuale() -> dict[str, object]:
        """! @brief Esegue un backup manuale dei dati operativi.
        @return Metadati dell'archivio creato.
        """
        meta = servizi.backup.crea_archivio("manuale")
        servizi.audit.registra("backup", "ok", {"nome": meta["nome"], "nota": "manuale"})
        return meta

    @router.post("/backup/auto")
    async def backup_auto(corpo: AutoBackupRichiesta) -> dict[str, object]:
        """! @brief Attiva/disattiva il backup automatico a caldo.
        @param corpo Richiesta con il flag desiderato.
        @return Stato aggiornato del backup automatico.
        """
        servizi.backup_auto_attivo = corpo.attivo
        servizi.audit.registra("backup_auto", "ok", {"attivo": corpo.attivo})
        return {"auto_attivo": servizi.backup_auto_attivo}

    @router.post("/backup/restore")
    async def backup_restore(corpo: RestoreRichiesta) -> dict[str, object]:
        """! @brief Ripristina i dati da un archivio di backup.
        @param corpo Richiesta con il nome dell'archivio.
        @return Metadati del ripristino.
        @throws HTTPException 404 se l'archivio non esiste.
        """
        try:
            meta = servizi.backup.ripristina(corpo.nome)
        except FileNotFoundError as exc:
            raise HTTPException(status_code=404, detail=str(exc)) from exc
        servizi.audit.registra("backup_restore", "ok", {"nome": corpo.nome})
        return meta

    @router.get("/audit")
    async def audit(n: int = 20) -> dict[str, object]:
        """! @brief Restituisce le ultime voci del log di audit.
        @param n Numero di voci da restituire.
        @return Lista delle ultime voci di audit.
        """
        return {"voci": servizi.audit.ultime(n)}

    return router
