"""! @package server.integration_tier.gateway_routing
@brief Routing, heatmap e sistemaTPL INTEGRATO (§4 — nessun modulo separato, §13).
"""

from __future__ import annotations

import unicodedata
from typing import Any

from server.integration_tier.data_access_manager.geo import distanza_m

#! Velocità media (km/h) per modalità, usate per l'ETA deterministico della simulazione.
_VELOCITA_KMH: dict[str, float] = {"sharing": 18.0, "tpl": 24.0}

#! Gazetteer locale di punti di interesse (Bari): nome canonico → coordinate (lat, lon).
#! Sorgente deterministica del geocoding (nome luogo → coordinate, UT.07) senza provider
#! esterno né rete (coerente con la simulazione locale del gateway e col vincolo "server in
#! locale, niente download"). Allineato ai luoghi mostrati dai client; la chiave di ricerca
#! è normalizzata (@ref _normalizza) per tollerare accenti, punteggiatura e il suffisso "Bari".
_GAZETTEER: dict[str, tuple[float, float]] = {
    "Stazione Bari Centrale": (41.1171, 16.8719),
    "Piazza Umberto I – Bari": (41.1185, 16.8690),
    "Lungomare di Bari": (41.1258, 16.8760),
    "Ospedale Policlinico – Bari": (41.1095, 16.8770),
    "Quartiere Libertà – Bari": (41.1130, 16.8560),
    "Quartiere Poggiofranco": (41.1050, 16.8520),
    "Bari Vecchia – Basilica San Nicola": (41.1308, 16.8702),
    "Teatro Petruzzelli – Bari": (41.1255, 16.8694),
    "Fiera del Levante": (41.1330, 16.8480),
    "Aeroporto Karol Wojtyla – Bari": (41.1389, 16.7606),
    "Piazza Moro – Bari": (41.1175, 16.8710),
    "Carrassi – Bari": (41.1075, 16.8650),
    "Japigia – Bari": (41.0960, 16.8800),
    "Torre a Mare – Bari": (41.0830, 16.9290),
}


def _normalizza(testo: str) -> str:
    """! @brief Normalizza un nome di luogo per il confronto del geocoding.

    Minuscolizza, rimuove gli accenti (decomposizione Unicode), elimina il rumore
    ("bari", trattini/punteggiatura) e comprime gli spazi: così "Stazione Bari
    Centrale" e "stazione centrale" collimano.

    @param testo Nome grezzo digitato o canonico del gazetteer.
    @return Stringa normalizzata (token alfanumerici separati da spazio singolo).
    """
    senza_accenti = "".join(
        c for c in unicodedata.normalize("NFD", testo.lower()) if unicodedata.category(c) != "Mn"
    )
    pulito = "".join(c if c.isalnum() else " " for c in senza_accenti)
    token = [t for t in pulito.split() if t and t != "bari"]
    return " ".join(token)


class GatewayRouting:
    """! @brief Calcolo percorsi multimodali e interrogazione del ServizioMappa (UT.07/UT.08).

    Responsabilita': opzioni di percorso ordinate per tempo, integrazione
    informativa col Trasporto Pubblico Locale (sistemaTPL) e dati per le heatmap.

    @warning Il sistemaTPL e' INTEGRATO nativamente qui: NON deve mai diventare un
             modulo separato (§3 / §4.1).
    @note **Simulazione locale deterministica** (§3): in assenza di provider mappa
          esterno, distanza e tempi derivano da formule pure (emisenoverso + velocità
          medie costanti); nessuna chiamata di rete. La firma resta invariata per il
          cablaggio reale del provider.
    """

    def percorsi_multimodali(
        self, origine: tuple[float, float], destinazione: tuple[float, float]
    ) -> list[dict[str, object]]:
        """! @brief Calcola percorsi multimodali (sharing + TPL) verso la destinazione (UT.07).
        @param origine Coordinate (lat, lon) di partenza.
        @param destinazione Coordinate (lat, lon) di arrivo.
        @return Elenco di percorsi (modalità/distanza/durata) ordinati per tempo crescente.
        """
        metri = distanza_m(origine[0], origine[1], destinazione[0], destinazione[1])
        km = metri / 1000.0
        percorsi: list[dict[str, Any]] = [
            {
                "modalita": modalita,
                "distanza_m": round(metri, 1),
                "durata_min": round(km / velocita * 60.0, 1),
            }
            for modalita, velocita in _VELOCITA_KMH.items()
        ]
        percorsi.sort(key=lambda p: p["durata_min"])
        return percorsi

    def geocodifica(self, nome: str) -> tuple[float, float] | None:
        """! @brief Risolve un nome di luogo in coordinate sul gazetteer locale (UT.07).

        Strategia deterministica: corrispondenza esatta normalizzata, poi per
        sottostringa (la query è contenuta in un nome canonico o viceversa).

        @param nome Nome del luogo digitato o selezionato dai suggerimenti.
        @return Coordinate (lat, lon) del luogo, o None se non riconosciuto.
        """
        query = _normalizza(nome)
        if not query:
            return None
        for canonico, coord in _GAZETTEER.items():
            if _normalizza(canonico) == query:
                return coord
        for canonico, coord in _GAZETTEER.items():
            chiave = _normalizza(canonico)
            if query in chiave or chiave in query:
                return coord
        return None

    def suggerisci(self, query: str, limite: int = 8) -> list[dict[str, object]]:
        """! @brief Suggerimenti di luogo per l'autocompletamento della ricerca (UT.07).

        @param query Testo parziale digitato dall'utente.
        @param limite Numero massimo di suggerimenti restituiti (default 8).
        @return Elenco di {nome, lat, lon} dei luoghi che contengono la query;
                lista vuota se la query è vuota.
        """
        normale = _normalizza(query)
        if not normale:
            return []
        risultati: list[dict[str, object]] = []
        for canonico, (lat, lon) in _GAZETTEER.items():
            if normale in _normalizza(canonico):
                risultati.append({"nome": canonico, "lat": lat, "lon": lon})
            if len(risultati) >= limite:
                break
        return risultati
