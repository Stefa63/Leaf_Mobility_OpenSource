"""! @file test_cronologia.py
@brief Test della cronologia persistente delle operazioni di console (stdlib).
"""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from server.console_operativa.cronologia import CronologiaConsole


class TestCronologiaConsole(unittest.TestCase):
    """! @brief Verifica persistenza, ripristino e potatura della cronologia."""

    def setUp(self) -> None:
        """! @brief Predispone una cartella temporanea per il file di cronologia."""
        self._tmp = tempfile.TemporaryDirectory()
        self._percorso = Path(self._tmp.name) / "cronologia_console.log"

    def tearDown(self) -> None:
        """! @brief Rimuove la cartella temporanea."""
        self._tmp.cleanup()

    def test_aggiunge_e_rilegge(self) -> None:
        """! @brief Le operazioni aggiunte sono rilette in ordine cronologico."""
        cron = CronologiaConsole(self._percorso)
        cron.aggiungi("start", "ok")
        cron.aggiungi("backup", "ok")
        voci = cron.ultime(10)
        self.assertEqual([v["comando"] for v in voci], ["start", "backup"])
        self.assertEqual(voci[-1]["esito"], "ok")

    def test_persistenza_tra_istanze(self) -> None:
        """! @brief La cronologia sopravvive alla creazione di una nuova istanza."""
        CronologiaConsole(self._percorso).aggiungi("op create mario", "ok")
        ripresa = CronologiaConsole(self._percorso)
        self.assertEqual(ripresa.ultime(5)[0]["comando"], "op create mario")

    def test_potatura_massimo(self) -> None:
        """! @brief La cronologia conserva al piu' il numero massimo di voci."""
        cron = CronologiaConsole(self._percorso, massimo=3)
        for i in range(6):
            cron.aggiungi(f"comando{i}", "ok")
        voci = cron.ultime(100)
        self.assertEqual(len(voci), 3)
        self.assertEqual(voci[0]["comando"], "comando3")


if __name__ == "__main__":
    unittest.main()
