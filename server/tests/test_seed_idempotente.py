"""! @file test_seed_idempotente.py
@brief Il seed e' idempotente: rieseguirlo su un DB gia' popolato non solleva
eccezioni (no ViolazioneUnicita), non duplica documenti e ripristina lo stato
operativo del seed sui mezzi rimasti appesi (prenotato/in_uso → disponibile).
"""

from __future__ import annotations

from server.integration_tier.data_access_manager import DataAccessManager
from server.integration_tier.data_access_manager import collezioni as col
from server.integration_tier.data_access_manager.bootstrap_seed import esegui_seed
from server.integration_tier.data_access_manager.cliente_falso import ClienteFalsoFirestore


def test_seed_rieseguibile_e_ripristina_mezzi() -> None:
    """! @brief Doppia esecuzione del seed: nessun errore, nessun duplicato, stato ripristinato."""
    dao = DataAccessManager(ClienteFalsoFirestore())
    conteggi = esegui_seed(dao)

    # Simula uno stato "appeso" lasciato dai test: un mezzo disponibile va in_uso.
    dao.aggiorna(col.MEZZI, "SC-014", {"stato_operativo": "in_uso"})
    appeso = dao.leggi(col.MEZZI, "SC-014")
    assert appeso is not None
    assert appeso["stato_operativo"] == "in_uso"

    # Riesecuzione del seed: deve completare senza eccezioni e con gli stessi conteggi.
    conteggi_ribadito = esegui_seed(dao)
    assert conteggi_ribadito == conteggi

    # Il mezzo appeso e' tornato allo stato del seed ("disponibile").
    ripristinato = dao.leggi(col.MEZZI, "SC-014")
    assert ripristinato is not None
    assert ripristinato["stato_operativo"] == "disponibile"

    # Nessun duplicato di mezzi/stazioni dopo la riesecuzione (id naturali stabili).
    assert len(dao.elenca(col.MEZZI)) == conteggi[col.MEZZI]
    assert len(dao.elenca(col.STAZIONI_RICARICA)) == conteggi[col.STAZIONI_RICARICA]
