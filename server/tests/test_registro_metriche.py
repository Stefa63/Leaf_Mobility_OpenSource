"""! @file test_registro_metriche.py
@brief Test del registro metriche (stdlib, nessuna dipendenza esterna).
"""

from __future__ import annotations

import unittest

from server.runtime.registro_metriche import RegistroMetriche


class TestRegistroMetriche(unittest.TestCase):
    """! @brief Verifica conteggi, concorrenza e statistiche dei tempi di risposta."""

    def test_conteggi_e_byte(self) -> None:
        """! @brief I byte e i conteggi vengono accumulati correttamente."""
        r = RegistroMetriche()
        r.inizio_richiesta()
        r.fine_richiesta(100, 250, 0.010, errore=False)
        r.inizio_richiesta()
        r.fine_richiesta(50, 80, 0.030, errore=True)
        snap = r.snapshot()
        self.assertEqual(snap["byte_in"], 150)
        self.assertEqual(snap["byte_out"], 330)
        self.assertEqual(snap["richieste_totali"], 2)
        self.assertEqual(snap["richieste_errore"], 1)
        self.assertEqual(snap["richieste_attive"], 0)

    def test_picco_concorrenza(self) -> None:
        """! @brief Il picco di concorrenza riflette il massimo delle richieste attive."""
        r = RegistroMetriche()
        r.inizio_richiesta()
        r.inizio_richiesta()
        r.inizio_richiesta()
        self.assertEqual(r.snapshot()["picco_concorrenza"], 3)
        self.assertEqual(r.snapshot()["richieste_attive"], 3)

    def test_io_applicativo(self) -> None:
        """! @brief I dati letti/scritti vengono contabilizzati separatamente."""
        r = RegistroMetriche()
        r.registra_io(letti=1000, scritti=2000)
        snap = r.snapshot()
        self.assertEqual(snap["dati_letti"], 1000)
        self.assertEqual(snap["dati_scritti"], 2000)

    def test_tempo_medio(self) -> None:
        """! @brief Il tempo medio di risposta e' coerente coi campioni inseriti."""
        r = RegistroMetriche()
        for _ in range(4):
            r.inizio_richiesta()
            r.fine_richiesta(0, 0, 0.020, errore=False)
        medio = r.snapshot()["tempo_risposta_medio_ms"]
        assert isinstance(medio, float)
        self.assertAlmostEqual(medio, 20.0, places=1)


if __name__ == "__main__":
    unittest.main()
