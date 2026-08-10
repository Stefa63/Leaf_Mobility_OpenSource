"""! @file middleware_log.py
@brief Middleware ASGI che registra ogni richiesta HTTP nel log strutturato.

Completa la diagnostica di connettività: per ogni richiesta imposta il contesto
(IP del client + request-id) e registra un riepilogo (metodo, percorso, stato,
durata). Le eccezioni non gestite sono loggate con traceback e ri-sollevate, così
nessun errore resta invisibile. Non altera il corpo né lo stato della risposta.
"""

from __future__ import annotations

import time
from collections.abc import Awaitable, Callable, MutableMapping
from typing import Any

from server.runtime.log_strutturato import (
    IP_NON_DISPONIBILE,
    imposta_contesto_richiesta,
    ottieni_logger,
    ripristina_contesto_richiesta,
)

#! Alias dei tipi ASGI per leggibilità.
Scope = MutableMapping[str, Any]
Message = MutableMapping[str, Any]
Receive = Callable[[], Awaitable[Message]]
Send = Callable[[Message], Awaitable[None]]
AppAsgi = Callable[[Scope, Receive, Send], Awaitable[None]]


class MiddlewareLog:
    """! @brief Registra accessi ed errori HTTP con IP client, stato e durata.

    @param app Applicazione ASGI sottostante.
    """

    def __init__(self, app: AppAsgi) -> None:
        """! @brief Inizializza il middleware di logging.
        @param app Applicazione ASGI da avvolgere.
        """
        self._app = app
        self._log = ottieni_logger("api_accesso")

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        """! @brief Imposta il contesto di richiesta e registra esito e durata.
        @param scope Scope ASGI della connessione.
        @param receive Callable per ricevere gli eventi in ingresso.
        @param send Callable per inviare gli eventi in uscita.
        @return Nessuno.
        """
        if scope.get("type") != "http":
            await self._app(scope, receive, send)
            return

        client = scope.get("client")
        ip_client = str(client[0]) if client else IP_NON_DISPONIBILE
        request_id = str(scope.get("request_id", IP_NON_DISPONIBILE))
        metodo = str(scope.get("method", "?"))
        percorso = str(scope.get("path", "?"))
        token = imposta_contesto_richiesta(ip_client, request_id)
        inizio = time.monotonic()
        stato = {"code": 0}

        async def send_wrap(messaggio: Message) -> None:
            if messaggio["type"] == "http.response.start":
                stato["code"] = int(messaggio["status"])
            await send(messaggio)

        try:
            await self._app(scope, receive, send_wrap)
        except Exception:
            durata_ms = (time.monotonic() - inizio) * 1000.0
            self._log.exception(
                "Errore non gestito %s %s dopo %.1f ms", metodo, percorso, durata_ms
            )
            raise
        else:
            durata_ms = (time.monotonic() - inizio) * 1000.0
            livello = self._log.warning if stato["code"] >= 500 else self._log.info
            livello("%s %s -> %d (%.1f ms)", metodo, percorso, stato["code"], durata_ms)
        finally:
            ripristina_contesto_richiesta(token)
