"""! @file test_gestore_backup.py
@brief Test del gestore di backup (stdlib, nessuna dipendenza esterna).
"""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from server.runtime.gestore_backup import GestoreBackup


class TestGestoreBackup(unittest.TestCase):
    """! @brief Verifica creazione archivi, retention e ripristino."""

    def setUp(self) -> None:
        """! @brief Predispone cartelle temporanee dati/backup con un file di prova."""
        self._tmp = tempfile.TemporaryDirectory()
        base = Path(self._tmp.name)
        self._dati = base / "dati"
        self._backup = base / "backups"
        self._dati.mkdir()
        (self._dati / "op_store.json").write_text('{"op":1}', encoding="utf-8")

    def tearDown(self) -> None:
        """! @brief Rimuove le cartelle temporanee."""
        self._tmp.cleanup()

    def test_crea_e_elenca(self) -> None:
        """! @brief Un backup manuale produce un archivio elencabile."""
        g = GestoreBackup(self._dati, self._backup, retention=10)
        meta = g.crea_archivio("manuale")
        self.assertEqual(meta["file"], 1)
        self.assertTrue(str(meta["nome"]).startswith("backup_"))
        self.assertEqual(len(g.elenco()), 1)

    def test_retention(self) -> None:
        """! @brief La retention mantiene solo il numero massimo di archivi."""
        g = GestoreBackup(self._dati, self._backup, retention=2)
        for _ in range(4):
            g.crea_archivio("auto")
        self.assertLessEqual(len(g.elenco()), 2)

    def test_ripristino(self) -> None:
        """! @brief Il ripristino reintroduce i file nell'area dati."""
        g = GestoreBackup(self._dati, self._backup, retention=5)
        meta = g.crea_archivio("manuale")
        (self._dati / "op_store.json").unlink()
        esito = g.ripristina(str(meta["nome"]))
        self.assertEqual(esito["file_ripristinati"], 1)
        self.assertTrue((self._dati / "op_store.json").is_file())

    def test_ripristino_inesistente(self) -> None:
        """! @brief Il ripristino di un archivio assente solleva FileNotFoundError."""
        g = GestoreBackup(self._dati, self._backup)
        with self.assertRaises(FileNotFoundError):
            g.ripristina("backup_inesistente.zip")


if __name__ == "__main__":
    unittest.main()
