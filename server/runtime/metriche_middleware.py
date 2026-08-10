"""! @file metriche_middleware.py
@brief Middleware ASGI che strumenta ogni richiesta HTTP per il registro metriche.
"""

from __future__ import annotations

import time
from collections.abc import Awaitable, Callable, MutableMapping
from typing import Any

from server.runtime.registro_metriche import RegistroMetriche

#! Alias dei tipi ASGI per leggibilita'.
Scope = MutableMapping[str, Any]
Message = MutableMapping[str, Any]
Receive = Callable[[], Awaitable[Message]]
Send = Callable[[Message], Awaitable[None]]
AppAsgi = Callable[[Scope, Receive, Send], Awaitable[None]]

#! Host di loopback della macchina che ospita il server: SEMPRE esclusi dal conteggio
#! dei dispositivi collegati (console operativa, health-check, controllo loopback). Il
#! conteggio rappresenta i soli dispositivi client esterni, non la macchina host.
_HOST_LOOPBACK: frozenset[str] = frozenset({"127.0.0.1", "::1", "localhost"})


class MiddlewareMetriche:
    """! @brief Middleware ASGI che misura byte, durata, concorrenza ed errori.

    Avvolge receive/send per contare i byte effettivi del corpo di richiesta e
    risposta e cronometrare il tempo di servizio, aggiornando il
    @ref RegistroMetriche condiviso senza alterare la logica applicativa.

    @param app Applicazione ASGI sottostante.
    @param registro Registro metriche condiviso da aggiornare.
    @param host_esclusi Host client da NON contare tra i dispositivi collegati (oltre al
        loopback, sempre escluso): tipicamente l'IP di bind del server, così la macchina
        che ospita il server non rientra mai nel conteggio dei dispositivi (IIN-14).
    """

    def __init__(
        self, app: AppAsgi, registro: RegistroMetriche, host_esclusi: frozenset[str] = frozenset()
    ) -> None:
        """! @brief Inizializza il middleware.
        @param app Applicazione ASGI da avvolgere.
        @param registro Registro metriche condiviso.
        @param host_esclusi Host client esclusi dal conteggio dispositivi (uniti al loopback).
        """
        self._app = app
        self._registro = registro
        self._host_esclusi = _HOST_LOOPBACK | host_esclusi

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        """! @brief Punto di ingresso ASGI: strumenta solo le richieste HTTP.
        @param scope Scope ASGI della connessione.
        @param receive Callable per ricevere gli eventi in ingresso.
        @param send Callable per inviare gli eventi in uscita.
        @return Nessuno.
        """
        if scope.get("type") != "http":
            await self._app(scope, receive, send)
            return

        self._registro.inizio_richiesta()
        client = scope.get("client")
        if client:
            host = str(client[0])
            # Esclude la macchina host (loopback + IP di bind): solo i dispositivi
            # client esterni concorrono al conteggio dei dispositivi collegati.
            if host not in self._host_esclusi:
                self._registro.segna_dispositivo(host)
        inizio = time.monotonic()
        contatori = {"in": 0, "out": 0, "status": 200}

        async def receive_misurato() -> Message:
            messaggio = await receive()
            if messaggio["type"] == "http.request":
                contatori["in"] += len(messaggio.get("body", b""))
            return messaggio

        async def send_misurato(messaggio: Message) -> None:
            if messaggio["type"] == "http.response.start":
                contatori["status"] = int(messaggio["status"])
            elif messaggio["type"] == "http.response.body":
                contatori["out"] += len(messaggio.get("body", b""))
            await send(messaggio)

        try:
            await self._app(scope, receive_misurato, send_misurato)
        finally:
            durata = time.monotonic() - inizio
            self._registro.fine_richiesta(
                contatori["in"], contatori["out"], durata, contatori["status"] >= 400
            )
