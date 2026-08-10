"""! @file impostazioni.py
@brief Configurazione del runtime server, letta da variabili d'ambiente / .env.
"""

from __future__ import annotations

import json
import os
from dataclasses import dataclass, field
from pathlib import Path

#! Chiavi di configurazione personalizzabili a caldo e persistite in config.json.
CHIAVI_PERSONALIZZABILI: tuple[str, ...] = (
    "backup_auto",
    "backup_intervallo_s",
    "backup_retention",
    "soglia_cpu",
    "soglia_ram",
)

#! Radice del pacchetto server/ (la cartella che contiene questo modulo padre).
RADICE_SERVER: Path = Path(__file__).resolve().parent.parent


def _carica_dotenv(percorso: Path) -> None:
    """! @brief Carica un file .env minimale in os.environ (senza dipendenze esterne).
    @param percorso Percorso del file .env da leggere; ignorato se assente.
    @return Nessuno. Le chiavi gia' presenti nell'ambiente NON vengono sovrascritte.
    """
    if not percorso.is_file():
        return
    for riga in percorso.read_text(encoding="utf-8").splitlines():
        riga = riga.strip()
        if not riga or riga.startswith("#") or "=" not in riga:
            continue
        chiave, _, valore = riga.partition("=")
        os.environ.setdefault(chiave.strip(), valore.strip())


def _leggi_config(percorso: Path) -> dict[str, object]:
    """! @brief Legge le impostazioni personalizzate da un file JSON.
    @param percorso Percorso di config.json; se assente o illeggibile restituisce {}.
    @return Mappa chiave -> valore delle impostazioni personalizzate.
    """
    if not percorso.is_file():
        return {}
    try:
        dati = json.loads(percorso.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return {}
    return dati if isinstance(dati, dict) else {}


def _origini(valore: str) -> tuple[str, ...]:
    """! @brief Converte una lista CSV di origini CORS in tupla.
    @param valore Stringa con origini separate da virgola (es. "https://a,https://b").
    @return Tupla di origini non vuote; ("*",) se la stringa è vuota.
    """
    voci = tuple(v.strip() for v in valore.split(",") if v.strip())
    return voci or ("*",)


def _bool(valore: str) -> bool:
    """! @brief Converte una stringa di ambiente in booleano.
    @param valore Stringa grezza (es. "true", "1", "yes").
    @return True per valori affermativi, False altrimenti.
    """
    return valore.strip().lower() in {"1", "true", "yes", "on", "si"}


@dataclass(frozen=True)
class Impostazioni:
    """! @brief Parametri immutabili del runtime server.

    @note Caricati una volta da .env / variabili d'ambiente tramite @ref carica().
    """

    host: str = "127.0.0.1"
    porta: int = 8770
    workers: int = 1
    backup_auto: bool = False
    backup_intervallo_s: int = 900
    backup_retention: int = 10
    soglia_cpu: float = 85.0
    soglia_ram: float = 85.0
    #! Token amministratore per le interrogazioni (solo admin). Vuoto => fiducia loopback.
    admin_token: str = ""
    #! Origini consentite per le richieste cross-origin dei client web (CORS).
    cors_origins: tuple[str, ...] = ("*",)
    #! Rate limit della API pubblica: richieste/finestra per host (<=0 => disattivato).
    rate_limit: int = 120
    #! Ampiezza della finestra del rate limit in secondi.
    rate_window_s: int = 60
    #! Livello minimo del logging strutturato (DEBUG/INFO/WARNING/ERROR).
    log_level: str = "INFO"
    dati_dir: Path = field(default_factory=lambda: RADICE_SERVER / "dati")
    backup_dir: Path = field(default_factory=lambda: RADICE_SERVER / "backups")

    @property
    def esposto_in_rete(self) -> bool:
        """! @brief Indica se il bind accetta connessioni da dispositivi esterni.
        @return True se l'host non è il solo loopback (es. 0.0.0.0 o IP di LAN).
        """
        return self.host not in {"127.0.0.1", "localhost", "::1"}

    @property
    def base_url(self) -> str:
        """! @brief URL base dell'endpoint di controllo, sempre via loopback.

        Il controllo/health della console passa sempre per il loopback. Se il
        bind è su un host jolly (`0.0.0.0`/`::`, usato per esporre la API pubblica
        in LAN) NON ci si può connettere a quell'indirizzo come destinazione (su
        Windows fallisce): va rimappato sull'indirizzo di loopback corrispondente,
        altrimenti la console avvia il runtime ma non riesce a confermarlo
        raggiungibile e lo dichiara erroneamente "non avviato".
        @return URL nella forma http://host:porta verso il loopback.
        """
        host = self.host
        if host in {"0.0.0.0", ""}:  # noqa: S104 — rimappatura del client, non un bind
            host = "127.0.0.1"
        elif host in {"::", "[::]"}:
            host = "[::1]"
        return f"http://{host}:{self.porta}"

    @property
    def file_store_op(self) -> Path:
        """! @brief Percorso dello store provvisorio degli account OP.
        @return Path del file JSON degli OP provvisori.
        """
        return self.dati_dir / "op_store.json"

    @property
    def file_audit(self) -> Path:
        """! @brief Percorso del log di audit append-only (IIN-13).
        @return Path del file di audit (JSON Lines).
        """
        return self.dati_dir / "audit.log"

    @property
    def file_config(self) -> Path:
        """! @brief Percorso del file delle impostazioni personalizzate (override a caldo).
        @return Path di config.json nella cartella dati.
        """
        return self.dati_dir / "config.json"

    @property
    def file_cronologia_console(self) -> Path:
        """! @brief Percorso della cronologia persistente dei comandi di console.
        @return Path del file di cronologia (JSON Lines) nella cartella dati.
        """
        return self.dati_dir / "cronologia_console.log"

    def configurabili(self) -> dict[str, object]:
        """! @brief Sottoinsieme delle impostazioni personalizzabili a caldo.
        @return Mappa chiave -> valore corrente delle voci configurabili.
        """
        return {chiave: getattr(self, chiave) for chiave in CHIAVI_PERSONALIZZABILI}

    def salva_config(self, modifiche: dict[str, object]) -> dict[str, object]:
        """! @brief Persiste le impostazioni personalizzate in config.json.

        Unisce le @p modifiche alla configurazione personalizzata gia' salvata e
        riscrive config.json. Solo le chiavi in @ref CHIAVI_PERSONALIZZABILI sono
        accettate; le altre vengono ignorate.

        @param modifiche Mappa parziale chiave -> nuovo valore.
        @return Configurazione personalizzata completa dopo l'aggiornamento.
        """
        attuale = _leggi_config(self.file_config)
        for chiave, valore in modifiche.items():
            if chiave in CHIAVI_PERSONALIZZABILI:
                attuale[chiave] = valore
        self.dati_dir.mkdir(parents=True, exist_ok=True)
        self.file_config.write_text(
            json.dumps(attuale, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        return attuale

    @staticmethod
    def carica() -> Impostazioni:
        """! @brief Costruisce le impostazioni da .env, ambiente e config.json.

        Precedenza: i default sicuri sono sovrascritti dalle variabili d'ambiente
        (.env incluso) e, infine, dalle impostazioni personalizzate persistite in
        config.json (scelte a caldo dall'operatore tramite il comando `set`).

        @return Istanza di Impostazioni con i valori risolti (default sicuri).
        """
        _carica_dotenv(RADICE_SERVER / ".env")
        env = os.environ.get
        dati_dir = RADICE_SERVER / "dati"
        cfg = _leggi_config(dati_dir / "config.json")
        return Impostazioni(
            host=env("LEAF_HOST", "127.0.0.1"),
            porta=int(env("LEAF_PORT", "8770")),
            workers=int(env("LEAF_WORKERS", "1")),
            backup_auto=bool(cfg.get("backup_auto", _bool(env("LEAF_BACKUP_AUTO", "false")))),
            backup_intervallo_s=int(
                str(cfg.get("backup_intervallo_s", env("LEAF_BACKUP_INTERVAL_S", "900")))
            ),
            backup_retention=int(
                str(cfg.get("backup_retention", env("LEAF_BACKUP_RETENTION", "10")))
            ),
            soglia_cpu=float(str(cfg.get("soglia_cpu", env("LEAF_SOGLIA_CPU", "85")))),
            soglia_ram=float(str(cfg.get("soglia_ram", env("LEAF_SOGLIA_RAM", "85")))),
            admin_token=env("LEAF_ADMIN_TOKEN", ""),
            cors_origins=_origini(env("LEAF_CORS_ORIGINS", "*")),
            rate_limit=int(env("LEAF_RATE_LIMIT", "120")),
            rate_window_s=int(env("LEAF_RATE_WINDOW_S", "60")),
            log_level=env("LEAF_LOG_LEVEL", "INFO"),
        )
