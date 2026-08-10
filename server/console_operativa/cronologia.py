"""! @file cronologia.py
@brief Cronologia persistente delle operazioni eseguite dalla console operativa.
"""

from __future__ import annotations

import json
import threading
from datetime import datetime
from pathlib import Path


class CronologiaConsole:
    """! @brief Registro persistente (JSON Lines) dei comandi eseguiti in console.

    Salva su disco ogni operazione (comando + esito sintetico + timestamp) cosi'
    che le ultime attivita' possano essere ripristinate al riavvio della console,
    anche dopo una chiusura imprevista. E' indipendente dall'audit del runtime:
    l'audit traccia le azioni lato server (IIN-13), questa traccia l'uso della
    console e sopravvive anche a runtime spento.

    @param percorso File di destinazione della cronologia (JSON Lines).
    @param massimo Numero massimo di voci conservate (le piu' vecchie vengono potate).
    """

    def __init__(self, percorso: Path, massimo: int = 500) -> None:
        """! @brief Inizializza la cronologia creando la cartella contenitore.
        @param percorso Percorso del file di cronologia.
        @param massimo Numero massimo di voci conservate.
        """
        self._percorso = percorso
        self._massimo = max(1, massimo)
        self._lock = threading.Lock()
        self._percorso.parent.mkdir(parents=True, exist_ok=True)

    def aggiungi(self, comando: str, esito: str) -> None:
        """! @brief Aggiunge un'operazione alla cronologia e applica la potatura.
        @param comando Riga di comando digitata dall'operatore.
        @param esito Esito sintetico ("ok", "errore", "info").
        @return Nessuno.
        """
        voce = {
            "ts": datetime.now().astimezone().isoformat(timespec="seconds"),
            "comando": comando,
            "esito": esito,
        }
        with self._lock:
            righe = self._righe_grezze()
            righe.append(json.dumps(voce, ensure_ascii=False))
            righe = righe[-self._massimo :]
            self._percorso.write_text("\n".join(righe) + "\n", encoding="utf-8")

    def ultime(self, n: int = 20) -> list[dict[str, object]]:
        """! @brief Restituisce le ultime n operazioni registrate.
        @param n Numero massimo di voci da restituire.
        @return Lista di voci (ts, comando, esito) in ordine cronologico.
        """
        with self._lock:
            righe = self._righe_grezze()
        voci: list[dict[str, object]] = []
        for riga in righe[-n:]:
            try:
                voci.append(json.loads(riga))
            except json.JSONDecodeError:
                continue
        return voci

    def _righe_grezze(self) -> list[str]:
        """! @brief Legge le righe non vuote del file di cronologia.
        @return Lista delle righe grezze (vuota se il file non esiste).
        @note Da invocare con il lock gia' acquisito.
        """
        if not self._percorso.is_file():
            return []
        return [r for r in self._percorso.read_text(encoding="utf-8").splitlines() if r.strip()]
