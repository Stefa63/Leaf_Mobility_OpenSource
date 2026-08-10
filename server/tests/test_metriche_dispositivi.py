"""! @file test_metriche_dispositivi.py
@brief Il conteggio dei dispositivi collegati esclude la macchina host del server
(loopback + IP di bind) e conta i soli dispositivi client esterni (IIN-14).
"""

from __future__ import annotations

import asyncio
from collections.abc import MutableMapping
from typing import Any

from server.runtime.metriche_middleware import MiddlewareMetriche
from server.runtime.registro_metriche import RegistroMetriche


async def _app_vuota(scope: Any, receive: Any, send: Any) -> None:  # noqa: ANN401, ARG001
    """! @brief App ASGI minima che risponde 200 vuoto."""
    await send({"type": "http.response.start", "status": 200, "headers": []})
    await send({"type": "http.response.body", "body": b""})


async def _ricevi() -> dict[str, Any]:
    """! @brief Evento ASGI di richiesta vuota."""
    return {"type": "http.request", "body": b"", "more_body": False}


async def _invia(_messaggio: MutableMapping[str, Any]) -> None:
    """! @brief Sink degli eventi ASGI in uscita."""


def _richiesta_da(middleware: MiddlewareMetriche, host: str) -> None:
    """! @brief Esegue una richiesta HTTP simulata da un dato host client.
    @param middleware Middleware da esercitare.
    @param host Host (IP) del client della richiesta.
    """
    scope = {"type": "http", "path": "/api/v1/salute", "client": (host, 1234)}
    asyncio.run(middleware(scope, _ricevi, _invia))


def test_host_server_escluso_dal_conteggio() -> None:
    """! @brief Loopback e IP di bind del server non concorrono al conteggio."""
    registro = RegistroMetriche()
    middleware = MiddlewareMetriche(_app_vuota, registro, host_esclusi=frozenset({"192.168.1.60"}))

    _richiesta_da(middleware, "127.0.0.1")  # console/health dell'host → escluso
    _richiesta_da(middleware, "192.168.1.60")  # IP di bind (LAN self) → escluso
    assert registro.snapshot()["dispositivi_collegati"] == 0

    _richiesta_da(middleware, "10.0.0.5")  # dispositivo client esterno → contato
    assert registro.snapshot()["dispositivi_collegati"] == 1
