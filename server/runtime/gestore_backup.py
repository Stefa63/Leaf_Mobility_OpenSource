"""! @file gestore_backup.py
@brief Backup manuale e automatico dei dati operativi (store OP, audit, snapshot).
"""

from __future__ import annotations

import threading
import zipfile
from datetime import UTC, datetime
from pathlib import Path

#! Prefisso dei file di archivio prodotti dai backup.
_PREFISSO = "backup_"


class GestoreBackup:
    """! @brief Gestisce backup manuali e automatici della cartella dati.

    Crea archivi ZIP datati della cartella dati operativa (store OP, audit log,
    eventuali snapshot), applica una politica di retention e consente il
    ripristino. Il backup automatico e' guidato dal lifespan del runtime
    (@ref server.runtime.app_factory) tramite @ref crea_archivio a intervalli.

    @param dati_dir Cartella sorgente dei dati da archiviare.
    @param backup_dir Cartella di destinazione degli archivi.
    @param retention Numero massimo di archivi da conservare.
    """

    def __init__(self, dati_dir: Path, backup_dir: Path, retention: int = 10) -> None:
        """! @brief Inizializza il gestore creando le cartelle necessarie.
        @param dati_dir Cartella sorgente dei dati.
        @param backup_dir Cartella di destinazione degli archivi.
        @param retention Numero massimo di archivi conservati (>=1).
        """
        self._dati_dir = dati_dir
        self._backup_dir = backup_dir
        #! Numero massimo di archivi conservati (modificabile a caldo via comando `set`).
        self.retention = max(1, retention)
        self._lock = threading.Lock()
        self._dati_dir.mkdir(parents=True, exist_ok=True)
        self._backup_dir.mkdir(parents=True, exist_ok=True)

    def crea_archivio(self, nota: str = "manuale") -> dict[str, object]:
        """! @brief Crea un archivio ZIP dei dati correnti e applica la retention.
        @param nota Etichetta dell'origine del backup (es. "manuale", "auto").
        @return Metadati dell'archivio creato (nome, byte, file, timestamp).
        @throws OSError In caso di errore di scrittura su disco.
        """
        timestamp = datetime.now(UTC).strftime("%Y%m%d_%H%M%S")
        destinazione = self._backup_dir / f"{_PREFISSO}{timestamp}.zip"
        n_file = 0
        with self._lock:
            with zipfile.ZipFile(destinazione, "w", zipfile.ZIP_DEFLATED) as zf:
                for percorso in sorted(self._dati_dir.rglob("*")):
                    if percorso.is_file():
                        zf.write(percorso, percorso.relative_to(self._dati_dir))
                        n_file += 1
            self._applica_retention()
        return {
            "nome": destinazione.name,
            "byte": destinazione.stat().st_size,
            "file": n_file,
            "nota": nota,
            "ts": datetime.now(UTC).isoformat(timespec="seconds"),
        }

    def _applica_retention(self) -> None:
        """! @brief Elimina gli archivi piu' vecchi oltre la soglia di retention.
        @return Nessuno.
        """
        archivi = sorted(self._backup_dir.glob(f"{_PREFISSO}*.zip"))
        for vecchio in archivi[: -self.retention] if len(archivi) > self.retention else []:
            vecchio.unlink(missing_ok=True)

    def elenco(self) -> list[dict[str, object]]:
        """! @brief Elenca gli archivi di backup disponibili.
        @return Lista di archivi (nome, byte) ordinati dal piu' recente.
        """
        archivi = sorted(self._backup_dir.glob(f"{_PREFISSO}*.zip"), reverse=True)
        return [{"nome": a.name, "byte": a.stat().st_size} for a in archivi]

    def ripristina(self, nome_archivio: str) -> dict[str, object]:
        """! @brief Ripristina i dati da un archivio esistente nella cartella dati.
        @param nome_archivio Nome del file di archivio (es. "backup_20260620_101500.zip").
        @return Metadati dell'operazione (archivio, file ripristinati).
        @throws FileNotFoundError Se l'archivio non esiste.
        """
        sorgente = self._backup_dir / nome_archivio
        if not sorgente.is_file():
            raise FileNotFoundError(f"Archivio inesistente: {nome_archivio}")
        with self._lock, zipfile.ZipFile(sorgente, "r") as zf:
            membri = zf.namelist()
            zf.extractall(self._dati_dir)
        return {"archivio": nome_archivio, "file_ripristinati": len(membri)}
