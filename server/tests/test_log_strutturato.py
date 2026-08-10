"""! @file test_log_strutturato.py
@brief Il logging strutturato espone i parametri diagnostici richiesti e il
MiddlewareLog inietta l'IP del client nella riga di log della richiesta.
"""

from __future__ import annotations

import asyncio
import logging
from collections.abc import MutableMapping
from typing import Any

from server.runtime.log_strutturato import (
    FORMATO,
    FiltroContestoRichiesta,
    imposta_contesto_richiesta,
    ripristina_contesto_richiesta,
)
from server.runtime.middleware_log import MiddlewareLog


def test_formato_contiene_parametri_diagnostici() -> None:
    """! @brief Il formato include i 6 parametri richiesti per la diagnosi."""
    for atteso in ("asctime", "name", "levelname", "process", "thread", "ip_client", "message"):
        assert atteso in FORMATO


def test_filtro_inietta_ip_e_request_id() -> None:
    """! @brief Il filtro popola ip_client/request_id dal contesto corrente."""
    token = imposta_contesto_richiesta("10.0.0.5", "abc123")
    try:
        record = logging.LogRecord("m", logging.INFO, __file__, 1, "ciao", None, None)
        assert FiltroContestoRichiesta().filter(record) is True
        assert record.__dict__["ip_client"] == "10.0.0.5"
        assert record.__dict__["request_id"] == "abc123"
    finally:
        ripristina_contesto_richiesta(token)


async def _app_vuota(scope: Any, receive: Any, send: Any) -> None:  # noqa: ANN401, ARG001
    """! @brief App ASGI minima che risponde 200 vuoto."""
    await send({"type": "http.response.start", "status": 200, "headers": []})
    await send({"type": "http.response.body", "body": b""})


async def _ricevi() -> dict[str, Any]:
    """! @brief Evento ASGI di richiesta vuota."""
    return {"type": "http.request", "body": b"", "more_body": False}


async def _invia(_messaggio: MutableMapping[str, Any]) -> None:
    """! @brief Sink degli eventi ASGI in uscita."""


def test_middleware_logga_esito_richiesta(caplog: Any) -> None:
    """! @brief Il MiddlewareLog registra metodo, percorso e stato della richiesta.

    L'iniezione dell'IP nella riga formattata è garantita dal @ref
    FiltroContestoRichiesta (coperto da @ref test_filtro_inietta_ip_e_request_id),
    agganciato agli handler in @c configura_logging; qui si verifica l'esito loggato.
    """
    # Aggancia il filtro di contesto al logger esercitato (in runtime lo fa
    # configura_logging sugli handler radice): così la riga formattata porta l'IP.
    filtro = FiltroContestoRichiesta()
    logging.getLogger("api_accesso").addFilter(filtro)
    formatter = logging.Formatter(FORMATO)
    middleware = MiddlewareLog(_app_vuota)
    scope = {
        "type": "http",
        "method": "GET",
        "path": "/api/v1/salute",
        "client": ("10.0.0.5", 5555),
        "request_id": "req-1",
    }
    try:
        with caplog.at_level(logging.INFO, logger="api_accesso"):
            asyncio.run(middleware(scope, _ricevi, _invia))
        record = next(r for r in caplog.records if r.name == "api_accesso")
        assert "GET /api/v1/salute -> 200" in record.getMessage()
        assert formatter.format(record).count("10.0.0.5") == 1
    finally:
        logging.getLogger("api_accesso").removeFilter(filtro)
