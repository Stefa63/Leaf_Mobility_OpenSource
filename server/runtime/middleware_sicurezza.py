"""! @file middleware_sicurezza.py
@brief Middleware ASGI di sicurezza per la API pubblica: request-id, header, rate limit.

Predispone i controlli perimetrali standard ora che il server può accettare
richieste da dispositivi esterni: un identificativo di correlazione per ogni
richiesta (X-Request-ID, tracciabile), gli header di sicurezza di base sulle
risposte e un rate limiting per host sugli endpoint pubblici `/api/v1`.
"""

from __future__ import annotations

import json
import threading
import time
from collections.abc import Awaitable, Callable, MutableMapping
from typing import Any
from uuid import uuid4

#! Alias dei tipi ASGI per leggibilità.
Scope = MutableMapping[str, Any]
Message = MutableMapping[str, Any]
Receive = Callable[[], Awaitable[Message]]
Send = Callable[[Message], Awaitable[None]]
AppAsgi = Callable[[Scope, Receive, Send], Awaitable[None]]

#! Header di sicurezza applicati a ogni risposta HTTP (difesa in profondità di base).
HEADER_SICUREZZA: tuple[tuple[bytes, bytes], ...] = (
    (b"x-content-type-options", b"nosniff"),
    (b"x-frame-options", b"DENY"),
    (b"referrer-policy", b"no-referrer"),
)


class LimitatoreRichieste:
    """! @brief Rate limiter a finestra fissa per host (thread-safe, in memoria).

    Conta le richieste di ciascuna chiave (host del client) entro una finestra
    temporale e nega quelle eccedenti. Un massimo <= 0 disabilita il limite.

    @param massimo Numero massimo di richieste per finestra (<=0 => nessun limite).
    @param finestra_s Ampiezza della finestra in secondi.
    """

    def __init__(self, massimo: int, finestra_s: float) -> None:
        """! @brief Inizializza il limitatore.
        @param massimo Numero massimo di richieste per finestra.
        @param finestra_s Ampiezza della finestra in secondi.
        """
        self._massimo = massimo
        self._finestra = max(1.0, finestra_s)
        self._lock = threading.Lock()
        self._stato: dict[str, tuple[float, int]] = {}

    def consenti(self, chiave: str) -> bool:
        """! @brief Verifica e contabilizza una richiesta della chiave indicata.
        @param chiave Identificativo del chiamante (tipicamente l'host del client).
        @return True se la richiesta è consentita, False se eccede il limite.
        """
        if self._massimo <= 0:
            return True
        ora = time.monotonic()
        with self._lock:
            inizio, conteggio = self._stato.get(chiave, (ora, 0))
            if ora - inizio >= self._finestra:
                inizio, conteggio = ora, 0
            conteggio += 1
            self._stato[chiave] = (inizio, conteggio)
            return conteggio <= self._massimo


class MiddlewareSicurezza:
    """! @brief Aggiunge X-Request-ID e header di sicurezza a ogni risposta HTTP.

    Genera (o propaga) un identificativo di correlazione per ogni richiesta e lo
    rende disponibile nello scope ASGI (`scope["request_id"]`) e nell'header di
    risposta `X-Request-ID`, utile per tracciare una richiesta end-to-end.

    @param app Applicazione ASGI sottostante.
    """

    def __init__(self, app: AppAsgi) -> None:
        """! @brief Inizializza il middleware.
        @param app Applicazione ASGI da avvolgere.
        """
        self._app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        """! @brief Inietta request-id e header di sicurezza nelle risposte HTTP.
        @param scope Scope ASGI della connessione.
        @param receive Callable per ricevere gli eventi in ingresso.
        @param send Callable per inviare gli eventi in uscita.
        @return Nessuno.
        """
        if scope.get("type") != "http":
            await self._app(scope, receive, send)
            return
        intestazioni = dict(scope.get("headers") or [])
        grezzo = intestazioni.get(b"x-request-id")
        request_id = grezzo.decode("latin-1") if grezzo else uuid4().hex
        scope["request_id"] = request_id

        async def send_wrap(messaggio: Message) -> None:
            if messaggio["type"] == "http.response.start":
                righe = list(messaggio.get("headers") or [])
                righe.append((b"x-request-id", request_id.encode("latin-1")))
                righe.extend(HEADER_SICUREZZA)
                messaggio["headers"] = righe
            await send(messaggio)

        await self._app(scope, receive, send_wrap)


class MiddlewareRateLimit:
    """! @brief Applica un rate limit per host agli endpoint pubblici (`/api/v1`).

    Le richieste eccedenti ricevono `429 Too Many Requests` con l'inviluppo
    standard, senza raggiungere l'applicazione. Gli endpoint di controllo
    loopback (`/__admin__`) e gli altri percorsi non sono limitati.

    @param app Applicazione ASGI sottostante.
    @param limitatore Rate limiter condiviso.
    @param prefisso Prefisso dei percorsi soggetti a limite.
    """

    def __init__(
        self, app: AppAsgi, limitatore: LimitatoreRichieste, prefisso: str = "/api/v1"
    ) -> None:
        """! @brief Inizializza il middleware di rate limiting.
        @param app Applicazione ASGI da avvolgere.
        @param limitatore Rate limiter condiviso.
        @param prefisso Prefisso dei percorsi pubblici da limitare.
        """
        self._app = app
        self._limitatore = limitatore
        self._prefisso = prefisso

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        """! @brief Nega le richieste pubbliche oltre il limite, altrimenti prosegue.
        @param scope Scope ASGI della connessione.
        @param receive Callable per ricevere gli eventi in ingresso.
        @param send Callable per inviare gli eventi in uscita.
        @return Nessuno.
        """
        if scope.get("type") != "http" or not str(scope.get("path", "")).startswith(self._prefisso):
            await self._app(scope, receive, send)
            return
        client = scope.get("client")
        host = str(client[0]) if client else "sconosciuto"
        if self._limitatore.consenti(host):
            await self._app(scope, receive, send)
            return
        await self._nega(send)

    @staticmethod
    async def _nega(send: Send) -> None:
        """! @brief Invia una risposta 429 con l'inviluppo standard della API.
        @param send Callable ASGI per l'invio della risposta.
        @return Nessuno.
        """
        corpo = json.dumps(
            {
                "disponibile": False,
                "messaggio": "Troppe richieste: riprova più tardi.",
                "dati": None,
            }
        ).encode("utf-8")
        await send(
            {
                "type": "http.response.start",
                "status": 429,
                "headers": [
                    (b"content-type", b"application/json"),
                    (b"retry-after", b"1"),
                ],
            }
        )
        await send({"type": "http.response.body", "body": corpo})
