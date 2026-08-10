"""! @package server.business_tier.gestore_geofencing
@brief Aree geografiche: interdizioni, slow-zone, parcheggi incentivati, operativita'.
"""

from __future__ import annotations

from typing import TYPE_CHECKING, Any

from server.integration_tier.data_access_manager import ottieni_dao_opzionale

if TYPE_CHECKING:
    from server.integration_tier.data_access_manager import DataAccessManager

#! Tipi di area che vietano la circolazione/sosta (interdizione, AP.06).
TIPI_VIETATI: frozenset[str] = frozenset({"interdizione_totale", "cantiere"})
#! Tipi di area che impongono un limite di velocita' (slow-zone, AP.08).
TIPI_LIMITE_VELOCITA: frozenset[str] = frozenset({"slow_zone", "evento"})
#! Tipo di area che delimita il perimetro operativo di fine-noleggio (OP.04).
TIPO_AREA_OPERATIVA = "area_operativa"
#! Categorie ammesse di evento cittadino (sotto-tipo dell'area "evento", AP.09/AP.04).
#! Distinte dal `tipo` d'area: classificano l'evento per il potenziamento flotta.
CATEGORIE_EVENTO: frozenset[str] = frozenset({"grande_evento", "cantiere", "interruzione"})


class GestoreGeofencing:
    """! @brief Gestisce i perimetri geografici e le relative regole (AP.04/06/08, OP.04/09).

    Responsabilita': aree di interdizione totale, slow-zone con limite di
    velocita', perimetri di fine-noleggio, aree di parcheggio incentivato.
    La verifica spaziale (point-in-polygon sul `geohash`/poligono in chiaro, §6.7) è
    delegata al @ref DataAccessManager (Integration Tier, tier adiacente §4).

    @param dao DataAccessManager opzionale; se None risolto dall'ambiente
               (@ref ottieni_dao_opzionale).
    """

    def __init__(self, dao: DataAccessManager | None = None) -> None:
        """! @brief Costruisce il gestore, opzionalmente con un DAO iniettato (test).
        @param dao DataAccessManager da usare; se None risolto dall'ambiente.
        """
        self._dao = dao

    def _dao_o_errore(self) -> DataAccessManager:
        """! @brief Restituisce il DAO disponibile o segnala la persistenza in sviluppo.
        @return DataAccessManager pronto.
        @throws NotImplementedError Se la persistenza non e' configurata (slice "in sviluppo", §9).
        """
        dao = self._dao or ottieni_dao_opzionale()
        if dao is None:
            raise NotImplementedError("DataAccessManager/DB in sviluppo")
        return dao

    def elenca_aree(self, solo_attive: bool = False) -> list[dict[str, Any]]:
        """! @brief Elenca le aree limitate configurate (AP.04/06/08, dashboard PA).
        @param solo_attive Se True, restituisce solo le aree con `attiva` == True.
        @return Lista delle aree limitate (interdizioni, slow-zone, parcheggi).
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        # Flag "attiva" canonico = stato:"attiva" (coerente col seed e con la query
        # spaziale aree_contenenti); evita il filtro su un campo booleano inesistente.
        filtri = [("stato", "==", "attiva")] if solo_attive else None
        return dao.elenca(col.AREE_LIMITATE, filtri=filtri)

    def crea_area(self, dati: dict[str, Any], creata_da: str) -> str:
        """! @brief Crea un'area limitata sulla mappa (cantiere/interdizione/slow-zone).
        @param dati Campi dell'area (tipo, nome, poligono/geohash, limite_velocita_kmh, …).
        @param creata_da Id dell'account (PA/OP) che traccia l'area (FK → account, §6.9).
        @return Id dell'area creata.
        @throws NotImplementedError Se la persistenza non e' configurata.
        @throws ErroreIntegrita Se `creata_da` non esiste (integrità referenziale).
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        documento = {"stato": "attiva", **dati, "creata_da": creata_da}
        # Firestore non ammette array annidati: il poligono [[lat,lon],…] del contratto
        # API viene normalizzato in geometria [{lat,lon}] (stessa forma del seed), così è
        # persistibile e partecipa al point-in-polygon del DAO, che legge `geometria` (§6.7).
        poligono = documento.pop("poligono", None)
        if isinstance(poligono, list) and "geometria" not in documento:
            documento["geometria"] = [
                {"lat": float(p[0]), "lon": float(p[1])}
                for p in poligono
                if isinstance(p, (list, tuple)) and len(p) >= 2
            ]
        return dao.crea(col.AREE_LIMITATE, documento)

    def elimina_area(self, id_area: str) -> None:
        """! @brief Rimuove un'area limitata (riapertura al transito, AP.04).
        @param id_area Id dell'area da eliminare.
        @return Nessuno.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        dao.elimina(col.AREE_LIMITATE, id_area)

    # ── Grandi eventi cittadini (AP.09) ───────────────────────────────────────
    def crea_evento(self, dati: dict[str, Any], creata_da: str) -> str:
        """! @brief Inserisce un grande evento cittadino su mappa con date e coordinate (AP.09).

        Un evento è modellato come area limitata di tipo "evento" (riconosciuta da
        @ref TIPI_LIMITE_VELOCITA): porta il perimetro geografico più le date di
        validità, così gli operatori sono informati delle zone che richiederanno il
        potenziamento preventivo della flotta. La `categoria` (@ref CATEGORIE_EVENTO)
        classifica l'evento (grande evento/cantiere/interruzione) ed è distinta dal
        `tipo` d'area; l'etichetta `area` indica il quartiere/zona interessata. Riusa
        @ref crea_area per la normalizzazione del poligono e l'integrità referenziale
        di `creata_da`.

        @param dati Campi dell'evento (nome, categoria, area, poligono/geohash, date, …).
        @param creata_da Id dell'account PA che inserisce l'evento (FK → account, §6.9).
        @return Id dell'evento (area_limitata) creato.
        @throws ValueError Se `categoria` non è tra @ref CATEGORIE_EVENTO.
        @throws NotImplementedError Se la persistenza non e' configurata.
        @throws ErroreIntegrita Se `creata_da` non esiste (integrità referenziale).
        """
        categoria = str(dati.get("categoria") or "grande_evento")
        if categoria not in CATEGORIE_EVENTO:
            raise ValueError(f"Categoria evento non valida: {categoria}")
        return self.crea_area({**dati, "tipo": "evento", "categoria": categoria}, creata_da)

    def elenca_eventi(self) -> list[dict[str, Any]]:
        """! @brief Elenca i grandi eventi cittadini configurati (AP.09).
        @return Lista delle aree limitate di tipo "evento" (con date e perimetro).
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        return dao.elenca(col.AREE_LIMITATE, filtri=[("tipo", "==", "evento")])

    def elimina_evento(self, id_evento: str) -> None:
        """! @brief Rimuove un grande evento cittadino dalla mappa (AP.09).

        Un evento è un'area limitata di tipo "evento" (@ref crea_evento): la rimozione
        riusa @ref elimina_area sulla stessa collezione, riaprendo la zona al normale
        esercizio una volta concluso o annullato l'evento.

        @param id_evento Id dell'evento (area_limitata) da eliminare.
        @return Nessuno.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        self.elimina_area(id_evento)

    def aree_per_punto(self, lat: float, lon: float) -> list[dict[str, Any]]:
        """! @brief Aree limitate attive che contengono un punto (AP.06/OP.04).
        @param lat Latitudine del punto.
        @param lon Longitudine del punto.
        @return Aree attive il cui poligono contiene il punto.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        return self._dao_o_errore().aree_contenenti(lat, lon)

    def dentro_area_operativa(self, lat: float, lon: float) -> bool:
        """! @brief Verifica se un punto è entro il perimetro operativo di fine-noleggio (OP.04).

        OP.04: l'operatore definisce uno o più perimetri `area_operativa` entro cui è
        consentito il rilascio dei mezzi. Se **nessun** perimetro operativo è configurato
        non c'è restrizione (ritorna True). Se ne esiste almeno uno, il punto è valido solo
        se cade dentro uno di essi.

        @param lat Latitudine del punto di rilascio.
        @param lon Longitudine del punto di rilascio.
        @return True se il rilascio è consentito (dentro perimetro o nessun perimetro).
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        operative = [
            a
            for a in dao.elenca(col.AREE_LIMITATE, filtri=[("tipo", "==", TIPO_AREA_OPERATIVA)])
            if a.get("stato") == "attiva"
        ]
        if not operative:
            return True  # nessun perimetro definito → nessuna restrizione
        return any(a.get("tipo") == TIPO_AREA_OPERATIVA for a in self.aree_per_punto(lat, lon))

    def punto_in_area_vietata(self, lat: float, lon: float) -> bool:
        """! @brief Verifica se una coordinata cade in un'area interdetta (AP.06).
        @param lat Latitudine del punto.
        @param lon Longitudine del punto.
        @return True se il punto e' in un perimetro di interdizione/cantiere.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        return any(a.get("tipo") in TIPI_VIETATI for a in self.aree_per_punto(lat, lon))

    def limite_velocita(self, lat: float, lon: float) -> int | None:
        """! @brief Limite di velocita' piu' restrittivo applicabile a un punto (AP.08).

        Considera le aree attive contenenti il punto di tipo slow-zone/evento con
        `limite_velocita_kmh` valorizzato e restituisce il minimo.

        @param lat Latitudine del punto.
        @param lon Longitudine del punto.
        @return Limite in km/h piu' basso applicabile, o None se nessun limite.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        limiti = [
            int(a["limite_velocita_kmh"])
            for a in self.aree_per_punto(lat, lon)
            if a.get("tipo") in TIPI_LIMITE_VELOCITA and a.get("limite_velocita_kmh") is not None
        ]
        return min(limiti) if limiti else None
