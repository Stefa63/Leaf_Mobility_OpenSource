"""! @file log_strutturato.py
@brief Logging strutturato del runtime server (diagnostica connettività ed errori).

Configura un logging standard, leggibile e completo per la diagnosi dei problemi
(in particolare di connettività dei client). Ogni riga riporta i parametri chiave:

    Timestamp | Modulo | Livello | PID/TID | IP client | Messaggio

L'IP del client non è un dato globale ma cambia per ogni richiesta: viene
trasportato in una @c ContextVar impostata dal @ref MiddlewareLog e iniettato
nei record da un @ref FiltroContestoRichiesta, così la stessa riga di log porta
sempre l'IP del dispositivo che ha originato l'operazione.

@note Usa la sola libreria standard (`logging`): nessuna nuova dipendenza.
"""

from __future__ import annotations

import logging
from contextvars import ContextVar
from logging.handlers import RotatingFileHandler
from pathlib import Path

#! Valore mostrato quando l'IP del client non è disponibile (es. attività interne).
IP_NON_DISPONIBILE = "-"

#! IP del client della richiesta corrente (per-task, sicuro in contesto asincrono).
_ip_client_corrente: ContextVar[str] = ContextVar("ip_client", default=IP_NON_DISPONIBILE)

#! Request-id di correlazione della richiesta corrente (impostato dal middleware).
_request_id_corrente: ContextVar[str] = ContextVar("request_id", default=IP_NON_DISPONIBILE)

#! Formato delle righe di log con tutti i parametri diagnostici richiesti.
FORMATO = (
    "%(asctime)s | %(name)s | %(levelname)s | "
    "PID:%(process)d/TID:%(thread)d | %(ip_client)s | req:%(request_id)s | %(message)s"
)

#! Formato del timestamp (ISO-like con secondi; il logging aggiunge i ms separati).
FORMATO_DATA = "%Y-%m-%dT%H:%M:%S"

#! Sentinella per evitare la riconfigurazione multipla del logging.
_configurato = False


def imposta_contesto_richiesta(ip_client: str, request_id: str) -> tuple[object, object]:
    """! @brief Imposta IP client e request-id per la richiesta corrente.
    @param ip_client Indirizzo IP del dispositivo client che ha originato la richiesta.
    @param request_id Identificativo di correlazione della richiesta (X-Request-ID).
    @return Coppia di token per il successivo ripristino con @ref ripristina_contesto_richiesta.
    """
    token_ip = _ip_client_corrente.set(ip_client or IP_NON_DISPONIBILE)
    token_req = _request_id_corrente.set(request_id or IP_NON_DISPONIBILE)
    return token_ip, token_req


def ripristina_contesto_richiesta(token: tuple[object, object]) -> None:
    """! @brief Ripristina il contesto precedente (fine richiesta), evitando perdite.
    @param token Coppia di token restituita da @ref imposta_contesto_richiesta.
    @return Nessuno.
    """
    token_ip, token_req = token
    _ip_client_corrente.reset(token_ip)  # type: ignore[arg-type]
    _request_id_corrente.reset(token_req)  # type: ignore[arg-type]


class FiltroContestoRichiesta(logging.Filter):
    """! @brief Filtro che inietta IP client e request-id correnti in ogni record.

    Garantisce che gli attributi `ip_client` e `request_id` siano sempre presenti
    nel record (anche per i log esterni come quelli di uvicorn), così il formatter
    non solleva mai un KeyError.
    """

    def filter(self, record: logging.LogRecord) -> bool:
        """! @brief Aggiunge gli attributi di contesto al record.
        @param record Record di log da arricchire.
        @return Sempre True (il record non viene mai scartato).
        """
        record.ip_client = _ip_client_corrente.get()
        record.request_id = _request_id_corrente.get()
        return True


def configura_logging(dati_dir: Path, livello: str = "INFO") -> Path:
    """! @brief Configura il logging strutturato del runtime (idempotente).

    Installa due handler sul logger radice: un file rotante in
    `dati_dir/server_app.log` (5 MB × 5 backup) e la console. Entrambi usano il
    @ref FORMATO completo e il @ref FiltroContestoRichiesta. Allinea anche i logger
    di uvicorn allo stesso formato. Chiamabile più volte senza duplicare gli handler.

    @param dati_dir Cartella dati del runtime dove scrivere il file di log.
    @param livello Livello minimo (DEBUG/INFO/WARNING/ERROR); default INFO.
    @return Percorso del file di log creato.
    """
    global _configurato
    dati_dir.mkdir(parents=True, exist_ok=True)
    percorso = dati_dir / "server_app.log"
    if _configurato:
        return percorso

    formatter = logging.Formatter(FORMATO, datefmt=FORMATO_DATA)
    filtro = FiltroContestoRichiesta()
    livello_num = getattr(logging, livello.upper(), logging.INFO)

    file_handler = RotatingFileHandler(
        percorso, maxBytes=5 * 1024 * 1024, backupCount=5, encoding="utf-8"
    )
    file_handler.setFormatter(formatter)
    file_handler.addFilter(filtro)

    console_handler = logging.StreamHandler()
    console_handler.setFormatter(formatter)
    console_handler.addFilter(filtro)

    radice = logging.getLogger()
    radice.setLevel(livello_num)
    radice.addHandler(file_handler)
    radice.addHandler(console_handler)

    # Allinea i logger di uvicorn al formato del progetto (niente handler propri).
    for nome in ("uvicorn", "uvicorn.error", "uvicorn.access"):
        logger_uv = logging.getLogger(nome)
        logger_uv.handlers.clear()
        logger_uv.propagate = True

    _configurato = True
    logging.getLogger("runtime").info("Logging strutturato attivo (livello=%s)", livello.upper())
    return percorso


def ottieni_logger(nome: str) -> logging.Logger:
    """! @brief Restituisce un logger nominato (il nome compare come "Modulo" nei log).
    @param nome Nome del modulo/componente (es. "gateway_email", "api_pubblica").
    @return Logger configurato che eredita gli handler del logger radice.
    """
    return logging.getLogger(nome)
