"""! @file app_factory.py
@brief Costruzione dell'app FastAPI del runtime (middleware, controllo, lifespan).
"""

from __future__ import annotations

import asyncio
import contextlib
import os
from collections.abc import AsyncIterator
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from server.presentation_tier.api_pubblica import crea_router_api
from server.runtime.controllo_router import crea_router
from server.runtime.impostazioni import Impostazioni
from server.runtime.log_strutturato import configura_logging
from server.runtime.metriche_middleware import MiddlewareMetriche
from server.runtime.middleware_log import MiddlewareLog
from server.runtime.middleware_sicurezza import (
    LimitatoreRichieste,
    MiddlewareRateLimit,
    MiddlewareSicurezza,
)
from server.runtime.servizi import ServiziRuntime


def _percorso_pid(impostazioni: Impostazioni) -> Path:
    """! @brief Percorso del file PID del processo server.
    @param impostazioni Configurazione del runtime.
    @return Path del file server.pid nella cartella dati.
    """
    return impostazioni.dati_dir / "server.pid"


async def _ciclo_backup_auto(servizi: ServiziRuntime) -> None:
    """! @brief Task di backup automatico periodico.

    L'intervallo e la retention sono riletti a ogni giro dallo stato runtime,
    cosi' le modifiche a caldo (comando `set`) hanno effetto senza riavvio.

    @param servizi Servizi runtime condivisi (contiene flag e gestore backup).
    @return Nessuno (esegue finche' non viene cancellato).
    """
    while True:
        await asyncio.sleep(max(5, servizi.backup_intervallo_s))
        if servizi.backup_auto_attivo:
            meta = await asyncio.to_thread(servizi.backup.crea_archivio, "auto")
            servizi.audit.registra("backup", "ok", {"nome": meta["nome"], "nota": "auto"})


def crea_app(impostazioni: Impostazioni | None = None) -> FastAPI:
    """! @brief Crea l'app FastAPI del runtime con strumentazione e controllo.
    @param impostazioni Configurazione opzionale; se assente viene caricata da env/.env.
    @return Istanza FastAPI pronta per essere servita da uvicorn.
    """
    imp = impostazioni or Impostazioni.carica()
    imp.dati_dir.mkdir(parents=True, exist_ok=True)
    configura_logging(imp.dati_dir, imp.log_level)
    servizi = ServiziRuntime(imp)

    @contextlib.asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        """! @brief Ciclo di vita: scrive il PID, avvia il backup auto, pulisce in uscita.
        @param app App FastAPI in avvio.
        @return Iteratore asincrono del contesto di vita.
        """
        pid_file = _percorso_pid(imp)
        pid_file.write_text(str(os.getpid()), encoding="utf-8")
        task = asyncio.create_task(_ciclo_backup_auto(servizi))
        try:
            yield
        finally:
            task.cancel()
            with contextlib.suppress(asyncio.CancelledError):
                await task
            pid_file.unlink(missing_ok=True)

    app = FastAPI(
        title="LEAF Mobility — Runtime operativo",
        version="0.1.0",
        lifespan=lifespan,
    )
    app.state.servizi = servizi
    # Pila middleware (FastAPI: l'ultimo aggiunto è il più esterno). Ordine effettivo
    # dall'esterno: CORS → Sicurezza (request-id+header) → RateLimit(/api/v1) →
    # Metriche → Log. Il Log è il più interno: vede il request-id già impostato da
    # Sicurezza e registra l'esito reale dell'handler (IP client, stato, durata).
    app.add_middleware(MiddlewareLog)
    app.add_middleware(
        MiddlewareMetriche,
        registro=servizi.metriche,
        host_esclusi=frozenset({imp.host}),  # esclude la macchina host dal conteggio dispositivi
    )
    app.add_middleware(
        MiddlewareRateLimit,
        limitatore=LimitatoreRichieste(imp.rate_limit, imp.rate_window_s),
    )
    app.add_middleware(MiddlewareSicurezza)
    # CORS: consente ai client web (WebDashboard) e mobile di chiamare la API
    # pubblica da un'origine diversa. Origini configurabili (LEAF_CORS_ORIGINS).
    app.add_middleware(
        CORSMiddleware,
        allow_origins=list(imp.cors_origins),
        allow_methods=["*"],
        allow_headers=["*"],
    )
    # Router di controllo (loopback, console) + API pubblica client-facing (mobile/web).
    app.include_router(crea_router(servizi))
    app.include_router(crea_router_api(servizi))
    return app


#! Istanza usata da uvicorn come target d'import: "server.runtime.app_factory:app".
app = crea_app()
