"""! @file test_anonymization.py
@brief Gate AG-SEC-04 (IIN-15): i dati delle dashboard PA sono aggregati e non re-identificabili.

Anche quando le corse sorgenti contengono identificativi individuali (id_utente/id_mezzo),
l'output di @ref MotoreAnalitica.aggrega_uso deve essere **aggregato per tipo di mezzo** e
non contenere alcun riferimento al singolo cittadino o mezzo (anonimato totale, IIN-15).
"""

from __future__ import annotations

import unittest

from server.business_tier.motore_analitica import CO2_KG_PER_KM, MotoreAnalitica
from server.integration_tier.data_access_manager import DataAccessManager
from server.integration_tier.data_access_manager import collezioni as col
from server.integration_tier.data_access_manager.cliente_falso import ClienteFalsoFirestore

#! Corse sorgente: (id, tipo_mezzo, km, durata_min) con identificativi individuali a monte.
_CORSE = [
    ("c1", "ebike", 5.0, 20.0),
    ("c2", "ebike", 3.0, 12.0),
    ("c3", "monopattino", 2.0, 10.0),
    ("c4", "ecar", 12.0, 25.0),
]


class TestAnonimizzazionePa(unittest.TestCase):
    """! @brief AG-SEC-04: nessun dato re-identificabile nelle analitiche PA (IIN-15)."""

    def setUp(self) -> None:
        """! @brief DAO fake popolato con corse concluse che CONTENGONO id individuali a monte."""
        self._cliente = ClienteFalsoFirestore()
        self._dao = DataAccessManager(self._cliente)
        for id_corsa, tipo, km, durata in _CORSE:
            # Scrittura grezza: corse reali con id_utente/id_mezzo presenti nel dato sorgente.
            self._cliente.collection(col.CORSE).document(id_corsa).set(
                {
                    "stato": "conclusa",
                    "tipo_mezzo": tipo,
                    "km_percorsi": km,
                    "durata_min": durata,
                    "id_utente": f"utente_{id_corsa}",
                    "id_mezzo": f"mezzo_{id_corsa}",
                    "data_ora_inizio": "2026-06-01T10:00:00",
                }
            )
        self._motore = MotoreAnalitica(self._dao)

    def test_output_aggregato_per_tipo_mezzo(self) -> None:
        """! @brief L'output è una riga per tipo di mezzo, con i conteggi attesi (AP.01/AP.02)."""
        righe = self._motore.aggrega_uso()
        per_tipo = {r["tipo_mezzo"]: r for r in righe}
        self.assertEqual(set(per_tipo), {"ebike", "monopattino", "ecar"})
        self.assertEqual(per_tipo["ebike"]["num_corse"], 2)
        self.assertEqual(per_tipo["ebike"]["km_totali"], 8.0)

    def test_nessun_identificativo_individuale_in_output(self) -> None:
        """! @brief Nessuna riga espone id_utente/id_mezzo/_id: anonimato totale (IIN-15)."""
        righe = self._motore.aggrega_uso()
        self.assertTrue(righe)  # ci sono dati da controllare
        for riga in righe:
            with self.subTest(tipo=riga.get("tipo_mezzo")):
                self.assertNotIn("id_utente", riga)
                self.assertNotIn("id_mezzo", riga)
                self.assertNotIn("_id", riga)

    def test_co2_risparmiata_derivata_dai_km(self) -> None:
        """! @brief AP.07: la CO2 risparmiata è funzione deterministica dei km aggregati."""
        per_tipo = {r["tipo_mezzo"]: r for r in self._motore.aggrega_uso()}
        self.assertEqual(per_tipo["ecar"]["co2_risparmiata_kg"], round(12.0 * CO2_KG_PER_KM, 2))

    def test_filtro_temporale_non_re_identifica(self) -> None:
        """! @brief Anche con filtro temporale l'output resta aggregato e anonimo."""
        righe = self._motore.aggrega_uso(dalla_data="2026-06-01", alla_data="2026-06-30")
        for riga in righe:
            self.assertNotIn("id_utente", riga)
            self.assertNotIn("id_mezzo", riga)


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
