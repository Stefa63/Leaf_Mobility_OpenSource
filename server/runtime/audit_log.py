"""! @file audit_log.py
@brief Log di audit append-only delle azioni operative (IIN-13).
"""

from __future__ import annotations

import json
import threading
from datetime import UTC, datetime
from pathlib import Path


class AuditLog:
    """! @brief Registro append-only, non riscritto, delle azioni della console.

    Ogni azione operativa (start/stop, creazione OP, query, backup) viene scritta
    come riga JSON con timestamp UTC, allineandosi al requisito di audit logging
    non modificabile (IIN-13). Le scritture sono serializzate da un lock.

    @param percorso File di destinazione del log (JSON Lines).
    """

    def __init__(self, percorso: Path) -> None:
        """! @brief Inizializza il log creando la cartella contenitore.
        @param percorso Percorso del file di audit.
        """
        self._percorso = percorso
        self._lock = threading.Lock()
        self._percorso.parent.mkdir(parents=True, exist_ok=True)

    def registra(self, azione: str, esito: str, dettagli: dict[str, object] | None = None) -> None:
        """! @brief Aggiunge una voce immutabile al log di audit.
        @param azione Nome dell'azione (es. "op_create", "server_stop").
        @param esito Esito sintetico (es. "ok", "errore").
        @param dettagli Metadati aggiuntivi non sensibili (no PII in chiaro, §7.3).
        @return Nessuno.
        """
        voce = {
            "ts": datetime.now(UTC).isoformat(timespec="seconds"),
            "azione": azione,
            "esito": esito,
            "dettagli": dettagli or {},
        }
        riga = json.dumps(voce, ensure_ascii=False)
        with self._lock, self._percorso.open("a", encoding="utf-8") as f:
            f.write(riga + "\n")

    def ultime(self, n: int = 20) -> list[dict[str, object]]:
        """! @brief Restituisce le ultime n voci di audit.
        @param n Numero massimo di voci da restituire.
        @return Lista delle voci piu' recenti (ordine cronologico).
        """
        if not self._percorso.is_file():
            return []
        with self._lock:
            righe = self._percorso.read_text(encoding="utf-8").splitlines()
        voci: list[dict[str, object]] = []
        for riga in righe[-n:]:
            try:
                voci.append(json.loads(riga))
            except json.JSONDecodeError:
                continue
        return voci
