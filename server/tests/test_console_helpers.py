"""! @file test_console_helpers.py
@brief Test degli helper puri della console e del wiring di comandi/tema/mascotte.
"""

from __future__ import annotations

import unittest

from server.console_operativa import console as mod
from server.console_operativa.mascotte import ALTEZZA_MASCOTTE, foglia_formattata
from server.console_operativa.tema import stile_tui


class TestConsoleHelpers(unittest.TestCase):
    """! @brief Verifica conversioni numeriche, comandi e risorse di rendering."""

    def test_num_conversioni(self) -> None:
        """! @brief _num converte int/float/str/bool e degrada al default."""
        self.assertEqual(mod._num({"a": 3}, "a"), 3.0)
        self.assertEqual(mod._num({"a": "2.5"}, "a"), 2.5)
        self.assertEqual(mod._num({"a": "x"}, "a", 9.0), 9.0)
        self.assertEqual(mod._num({}, "mancante", 1.0), 1.0)

    def test_intero_conversioni(self) -> None:
        """! @brief _intero estrae interi in modo type-safe."""
        self.assertEqual(mod._intero({"n": 4.9}, "n"), 4)
        self.assertEqual(mod._intero({}, "n", 7), 7)

    def test_comandi_nuovi_presenti(self) -> None:
        """! @brief I nuovi comandi e alias sono registrati."""
        for nome in ("set", "cronologia"):
            self.assertIn(nome, mod.COMANDI)
        self.assertEqual(mod.ALIAS["history"], "cronologia")
        self.assertEqual(mod.ALIAS["config"], "set")

    def test_mascotte_logo_allungato(self) -> None:
        """! @brief Il logo a foglia e' piu' alto (>= 12 righe) e ben formato."""
        self.assertGreaterEqual(ALTEZZA_MASCOTTE, 12)
        frammenti = foglia_formattata()
        self.assertEqual(frammenti.count(("", "\n")), ALTEZZA_MASCOTTE - 1)

    def test_tema_include_dispositivi(self) -> None:
        """! @brief Lo stile della TUI definisce la classe dei dispositivi collegati."""
        selettori = [sel for sel, _ in stile_tui().style_rules]
        self.assertTrue(any("devices" in sel for sel in selettori))


if __name__ == "__main__":
    unittest.main()
