"""! @file test_business_dominio.py
@brief Test del Business Tier cablato al DataAccessManager — OFFLINE, client fake.

Esercitano i casi d'uso di dominio chiusi in FASE 1 (geofencing AP.06/AP.08 e ciclo
corsa UT.02/UT.03/UT.04/UT.10/UT.12) iniettando un @ref DataAccessManager su
@ref ClienteFalsoFirestore: nessuna credenziale, nessun emulatore (testabilità §12.2).
"""

from __future__ import annotations

import unittest
from datetime import UTC, datetime, timedelta

from server.business_tier.gestore_assistenza_ticket import GestoreAssistenzaTicket
from server.business_tier.gestore_corse import GestoreCorse
from server.business_tier.gestore_geofencing import GestoreGeofencing
from server.business_tier.gestore_profili_ekyc import GestoreProfiliEkyc
from server.business_tier.motore_analitica import CO2_KG_PER_KM, MotoreAnalitica
from server.integration_tier.data_access_manager import DataAccessManager
from server.integration_tier.data_access_manager import collezioni as col
from server.integration_tier.data_access_manager.cliente_falso import ClienteFalsoFirestore

#! Poligono che racchiude il punto di prova (41.12, 16.87).
_QUADRATO = [
    {"lat": 41.10, "lon": 16.85},
    {"lat": 41.10, "lon": 16.90},
    {"lat": 41.14, "lon": 16.90},
    {"lat": 41.14, "lon": 16.85},
]


class TestGeofencing(unittest.TestCase):
    """! @brief Regole geografiche cablate al DAO (interdizione e slow-zone)."""

    def setUp(self) -> None:
        """! @brief DAO su client fake con un'area interdetta e una slow-zone sovrapposte."""
        self._dao = DataAccessManager(ClienteFalsoFirestore())
        self._dao.crea(
            col.AREE_LIMITATE,
            {
                "nome": "Cantiere",
                "tipo": "interdizione_totale",
                "stato": "attiva",
                "geometria": _QUADRATO,
            },
            id_doc="vietata",
        )
        self._dao.crea(
            col.AREE_LIMITATE,
            {
                "nome": "ZTL",
                "tipo": "slow_zone",
                "stato": "attiva",
                "limite_velocita_kmh": 10,
                "geometria": _QUADRATO,
            },
            id_doc="slow",
        )
        self._geo = GestoreGeofencing(self._dao)

    def test_punto_in_area_vietata(self) -> None:
        """! @brief AP.06: un punto dentro l'interdizione è vietato, fuori no."""
        self.assertTrue(self._geo.punto_in_area_vietata(41.12, 16.87))
        self.assertFalse(self._geo.punto_in_area_vietata(0.0, 0.0))

    def test_limite_velocita(self) -> None:
        """! @brief AP.08: dentro la slow-zone si applica il limite; fuori nessuno."""
        self.assertEqual(self._geo.limite_velocita(41.12, 16.87), 10)
        self.assertIsNone(self._geo.limite_velocita(0.0, 0.0))

    def test_perimetro_operativo_op04(self) -> None:
        """! @brief OP.04: senza perimetro nessuna restrizione; con perimetro vale dentro/fuori."""
        # Nessuna area_operativa configurata → rilascio sempre consentito.
        self.assertTrue(self._geo.dentro_area_operativa(41.12, 16.87))
        self.assertTrue(self._geo.dentro_area_operativa(0.0, 0.0))
        # Definito un perimetro operativo: dentro consentito, fuori no.
        self._dao.crea(
            col.AREE_LIMITATE,
            {
                "nome": "Perimetro Città",
                "tipo": "area_operativa",
                "stato": "attiva",
                "geometria": _QUADRATO,
            },
            id_doc="operativa",
        )
        self.assertTrue(self._geo.dentro_area_operativa(41.12, 16.87))
        self.assertFalse(self._geo.dentro_area_operativa(0.0, 0.0))

    def test_crea_area_normalizza_poligono(self) -> None:
        """! @brief crea_area: poligono [[lat,lon]] -> geometria [{lat,lon}] (no array annidati).

        Firestore rifiuta gli array annidati: il contratto API `poligono` deve essere
        normalizzato in `geometria` (lista di mappe) per essere persistibile e per
        partecipare al point-in-polygon del DAO (che legge `geometria`, §6.7). L'area di
        test è in una regione separata da quelle del setUp per isolarne il limite.
        """
        self._dao.crea_account("OP", "op@leaf.test", "hash", id_doc="op-test")
        id_area = self._geo.crea_area(
            {
                "tipo": "slow_zone",
                "nome": "Slow Zone Test",
                "poligono": [[40.50, 15.50], [40.50, 15.52], [40.48, 15.52], [40.48, 15.50]],
                "limite_velocita_kmh": 20,
            },
            "op-test",
        )
        doc = self._dao.leggi(col.AREE_LIMITATE, id_area)
        assert doc is not None
        self.assertNotIn("poligono", doc)  # nessun array annidato persistito
        self.assertEqual(doc["geometria"][0], {"lat": 40.50, "lon": 15.50})
        # L'area appena creata partecipa davvero al geofencing (legge `geometria`).
        self.assertEqual(self._geo.limite_velocita(40.49, 15.51), 20)


class TestCicloCorsa(unittest.TestCase):
    """! @brief Ciclo di vita della corsa: stima → avvia → pausa → termina (costi)."""

    def setUp(self) -> None:
        """! @brief DAO su client fake con un utente e un'ebike disponibile."""
        self._dao = DataAccessManager(ClienteFalsoFirestore())
        self._dao.crea_account("UT", "u@leaf.test", "hash", id_doc="u1")
        self._dao.crea_mezzo(
            "ebike",
            {
                "codice_identificativo": "BK-1",
                "stato_operativo": "disponibile",
                "lat": 41.12,
                "lon": 16.87,
            },
            id_doc="M1",
        )
        self._corse = GestoreCorse(self._dao)

    def test_stima_costo_deterministica(self) -> None:
        """! @brief UT.03: la stima usa la tariffa locale (ebike: 50 + 15·min)."""
        self.assertEqual(self._corse.stima_costo("M1", durata_min=10), 50 + 15 * 10)

    def test_ciclo_completo(self) -> None:
        """! @brief UT.10/UT.12/UT.04: avvio sblocca il mezzo, termine lo libera e tariffa."""
        avvio = self._corse.avvia("u1", "M1")
        id_corsa = str(avvio["id_corsa"])
        self.assertEqual(avvio["costo_stimato_cent"], 50 + 15 * 15)
        mezzo = self._dao.leggi(col.MEZZI, "M1")
        assert mezzo is not None
        self.assertEqual(mezzo["stato_operativo"], "in_uso")

        self.assertEqual(self._corse.pausa(id_corsa)["stato"], "in_pausa")

        esito = self._corse.termina(id_corsa, km_percorsi=2.5)
        self.assertEqual(esito["costo_finale_cent"], 50 + 15 * int(esito["durata_min"]))
        corsa = self._dao.leggi(col.CORSE, id_corsa)
        assert corsa is not None
        self.assertEqual(corsa["stato"], "conclusa")
        self.assertEqual(corsa["km_percorsi"], 2.5)
        liberato = self._dao.leggi(col.MEZZI, "M1")
        assert liberato is not None
        self.assertEqual(liberato["stato_operativo"], "disponibile")

    def test_avvia_mezzo_non_disponibile(self) -> None:
        """! @brief Un mezzo già in uso non può avviare una seconda corsa."""
        self._corse.avvia("u1", "M1")
        from server.integration_tier.data_access_manager import MezzoNonDisponibile

        with self.assertRaises(MezzoNonDisponibile):
            self._corse.avvia("u1", "M1")

    def test_corsa_attiva_recuperabile(self) -> None:
        """! @brief Punto 2: la corsa in corso è recuperabile, sparisce al termine."""
        self.assertIsNone(self._corse.corsa_attiva("u1"))
        avvio = self._corse.avvia("u1", "M1")
        attiva = self._corse.corsa_attiva("u1")
        assert attiva is not None
        self.assertEqual(str(attiva["_id"]), str(avvio["id_corsa"]))
        self.assertEqual(attiva["stato"], "in_corso")
        self._corse.termina(str(avvio["id_corsa"]))
        self.assertIsNone(self._corse.corsa_attiva("u1"))

    def test_prenotazioni_attive_e_annullo_operatore(self) -> None:
        """! @brief OP.12: l'operatore vede le prenotazioni attive e ne forza l'annullamento."""
        id_pren = self._corse.prenota("u1", "M1")
        attive = self._corse.prenotazioni_attive_tutte()
        self.assertEqual(len(attive), 1)
        self.assertEqual(str(attive[0]["_id"]), id_pren)
        esito = self._corse.annulla_prenotazione_op(id_pren)
        self.assertTrue(esito["annullata"])
        self.assertEqual(self._corse.prenotazioni_attive_tutte(), [])
        liberato = self._dao.leggi(col.MEZZI, "M1")
        assert liberato is not None
        self.assertEqual(liberato["stato_operativo"], "disponibile")

    def test_termina_con_gps_segnala_fuori_area_op04(self) -> None:
        """! @brief OP.04/OP.05: con perimetro operativo, il rilascio fuori è segnalato (soft)."""
        self._dao.crea(
            col.AREE_LIMITATE,
            {
                "nome": "Perimetro",
                "tipo": "area_operativa",
                "stato": "attiva",
                "geometria": [
                    {"lat": 41.10, "lon": 16.85},
                    {"lat": 41.10, "lon": 16.90},
                    {"lat": 41.14, "lon": 16.90},
                    {"lat": 41.14, "lon": 16.85},
                ],
            },
            id_doc="op-area",
        )
        avvio = self._corse.avvia("u1", "M1")
        esito = self._corse.termina(str(avvio["id_corsa"]), km_percorsi=1.0, lat=0.0, lon=0.0)
        self.assertTrue(esito["fuori_area_operativa"])  # soft: segnalato, non bloccato
        corsa = self._dao.leggi(col.CORSE, str(avvio["id_corsa"]))
        assert corsa is not None
        self.assertTrue(corsa["fuori_area_operativa"])
        self.assertEqual(corsa["stato"], "conclusa")  # il rilascio avviene comunque

    def test_dettaglio_costo_separa_sblocco_e_corsa(self) -> None:
        """! @brief Punto 8: lo sblocco e la corsa sono voci separate, poi la somma."""
        dettaglio = GestoreCorse.dettaglio_costo("ebike", 10)
        self.assertEqual(dettaglio["sblocco_cent"], 50)
        self.assertEqual(dettaglio["corsa_cent"], 15 * 10)
        self.assertEqual(dettaglio["totale_cent"], 50 + 15 * 10)


class TestPatenteEAbbonamento(unittest.TestCase):
    """! @brief Gate patente (punto 6) e billing abbonamento a token (punto 8)."""

    def setUp(self) -> None:
        """! @brief DAO con utente, un'ebike e un'auto elettrica disponibili."""
        self._dao = DataAccessManager(ClienteFalsoFirestore())
        self._dao.crea_account("UT", "u@leaf.test", "hash", id_doc="u1")
        self._dao.crea_mezzo(
            "ebike",
            {"codice_identificativo": "BK-1", "stato_operativo": "disponibile"},
            id_doc="BK",
        )
        self._dao.crea_mezzo(
            "ecar", {"codice_identificativo": "CA-1", "stato_operativo": "disponibile"}, id_doc="CA"
        )
        self._corse = GestoreCorse(self._dao)

    def test_auto_senza_patente_respinta(self) -> None:
        """! @brief Punto 6: avviare un'auto elettrica senza patente è inibito."""
        with self.assertRaises(ValueError):
            self._corse.avvia("u1", "CA")
        # Anche la prenotazione è inibita.
        with self.assertRaises(ValueError):
            self._corse.prenota("u1", "CA")

    def test_auto_con_patente_ammessa(self) -> None:
        """! @brief Punto 6: con la patente caricata l'auto è noleggiabile; l'ebike sempre."""
        self._dao.crea(
            col.DOCUMENTI_UFFICIALI,
            {"id_utente": "u1", "tipo_documento": "patente", "nome_file": "p.pdf"},
        )
        avvio = self._corse.avvia("u1", "CA")
        self.assertTrue(avvio["id_corsa"])
        # L'ebike non richiede patente in nessun caso.
        self.assertTrue(self._corse.avvia("u1", "BK")["id_corsa"])

    def test_termina_con_abbonamento_scala_token(self) -> None:
        """! @brief Punto 8: con abbonamento attivo si scala 1 token, importo 0, sblocco gratis."""
        fine = (datetime.now(UTC) + timedelta(days=10)).isoformat()
        self._dao.crea(
            col.ABBONAMENTI,
            {
                "id_utente": "u1",
                "stato": "attivo",
                "data_fine": fine,
                "token_inclusi": 5,
                "token_residui": 5,
            },
            id_doc="ab1",
        )
        avvio = self._corse.avvia("u1", "BK")
        esito = self._corse.termina(str(avvio["id_corsa"]))
        self.assertEqual(esito["costo_finale_cent"], 0)
        self.assertTrue(esito["coperto_da_abbonamento"])
        self.assertEqual(esito["token_residui"], 4)
        abbonamento = self._dao.leggi(col.ABBONAMENTI, "ab1")
        assert abbonamento is not None
        self.assertEqual(abbonamento["token_residui"], 4)


class TestTicketManutenzione(unittest.TestCase):
    """! @brief Ticket di manutenzione cablati al DAO (creazione + assegnazione)."""

    def setUp(self) -> None:
        """! @brief DAO con un operatore, un tecnico e un mezzo guasto."""
        self._dao = DataAccessManager(ClienteFalsoFirestore())
        self._dao.crea_account("OP", "op@leaf.test", "hash", id_doc="op1")
        self._dao.crea(col.TECNICI, {"nome": "Ada", "stato": "disponibile"}, id_doc="tec1")
        self._dao.crea_mezzo(
            "ecar", {"codice_identificativo": "CA-1", "stato_operativo": "guasto"}, id_doc="M1"
        )
        self._ticket = GestoreAssistenzaTicket(self._dao)

    def test_crea_e_assegna(self) -> None:
        """! @brief OP.16/19: il ticket nasce aperto con codice 📎 e si assegna a un tecnico."""
        id_t = self._ticket.crea_ticket("M1", "op1", "Freno guasto", priorita="alta")
        tk = self._dao.leggi(col.TICKET_MANUTENZIONE, id_t)
        assert tk is not None
        self.assertEqual(tk["stato"], "aperto")
        self.assertEqual(tk["codice_identificativo_mezzo"], "CA-1")  # denorm §6.6
        self._ticket.assegna_tecnico(id_t, "tec1")
        tk2 = self._dao.leggi(col.TICKET_MANUTENZIONE, id_t)
        assert tk2 is not None
        self.assertEqual(tk2["stato"], "assegnato")
        self.assertEqual(tk2["id_tecnico"], "tec1")

    def test_priorita_non_valida(self) -> None:
        """! @brief Una priorità fuori dall'enum è rifiutata."""
        with self.assertRaises(ValueError):
            self._ticket.crea_ticket("M1", "op1", "x", priorita="urgentissima")


class TestSosCoda(unittest.TestCase):
    """! @brief Coda SOS operatore: registrazione, elenco con etichetta utente (UT.20/OP.08)."""

    def setUp(self) -> None:
        """! @brief DAO con un utente (profilo + username) per l'etichetta della coda SOS."""
        self._dao = DataAccessManager(ClienteFalsoFirestore())
        self._dao.crea_account(
            "UT",
            "u@leaf.test",
            "hash",
            {"nome": "Mario", "cognome": "Rossi"},
            username="mrossi",
            id_doc="u1",
        )
        self._ticket = GestoreAssistenzaTicket(self._dao)

    def test_segnala_elenca_e_stato(self) -> None:
        """! @brief UT.20/OP.08: l'SOS si registra, compare in coda e cambia stato."""
        esito = self._ticket.segnala_sos("u1", 41.12, 16.87)
        self.assertEqual(esito["stato"], "inoltrata")
        coda = self._ticket.elenca_sos()
        self.assertEqual(len(coda), 1)
        self.assertEqual(coda[0]["nominativo"], "Mario Rossi")
        self.assertEqual(coda[0]["username"], "mrossi")
        self._ticket.aggiorna_stato_sos(
            esito["id_segnalazione"], "presa_in_carico", id_operatore="op1"
        )
        self.assertEqual(self._ticket.elenca_sos(stato="inoltrata"), [])
        prese = self._ticket.elenca_sos(stato="presa_in_carico")
        self.assertEqual(len(prese), 1)
        self.assertEqual(prese[0]["id_operatore"], "op1")

    def test_stato_non_valido(self) -> None:
        """! @brief Uno stato SOS fuori dall'enum è rifiutato."""
        esito = self._ticket.segnala_sos("u1", 41.0, 16.0)
        with self.assertRaises(ValueError):
            self._ticket.aggiorna_stato_sos(esito["id_segnalazione"], "boh")


class TestAnaliticaAnonima(unittest.TestCase):
    """! @brief Analitica aggregata e anonima (IIN-15): nessun riferimento al cittadino."""

    def setUp(self) -> None:
        """! @brief DAO con un utente, un'ebike e due corse concluse."""
        self._dao = DataAccessManager(ClienteFalsoFirestore())
        self._dao.crea_account("UT", "u@leaf.test", "hash", id_doc="u1")
        self._dao.crea_mezzo(
            "ebike",
            {"codice_identificativo": "BK-1", "stato_operativo": "disponibile"},
            id_doc="M1",
        )
        for km, durata in ((3.0, 10), (5.0, 20)):
            self._dao.crea(
                col.CORSE,
                {
                    "id_utente": "u1",
                    "id_mezzo": "M1",
                    "stato": "conclusa",
                    "km_percorsi": km,
                    "durata_min": durata,
                    "data_ora_inizio": "2026-06-01T10:00:00+00:00",
                },
            )
        self._analitica = MotoreAnalitica(self._dao)

    def test_aggregato_anonimo(self) -> None:
        """! @brief AP.02/AP.07: aggregato per tipo_mezzo, senza id utente/mezzo (IIN-15)."""
        agg = self._analitica.aggrega_uso()
        self.assertEqual(len(agg), 1)
        riga = agg[0]
        self.assertEqual(riga["tipo_mezzo"], "ebike")
        self.assertEqual(riga["num_corse"], 2)
        self.assertEqual(riga["km_totali"], 8.0)
        self.assertEqual(riga["durata_media_min"], 15.0)
        self.assertEqual(riga["co2_risparmiata_kg"], round(8.0 * CO2_KG_PER_KM, 2))
        self.assertNotIn("id_utente", riga)
        self.assertNotIn("id_mezzo", riga)

    def test_filtro_temporale(self) -> None:
        """! @brief Il filtro su data_ora_inizio esclude le corse fuori intervallo."""
        agg = self._analitica.aggrega_uso(dalla_data="2026-07-01T00:00:00+00:00")
        self.assertEqual(agg, [])


class TestRoutingSimulato(unittest.TestCase):
    """! @brief Routing multimodale come simulazione locale deterministica (UT.07)."""

    def test_percorsi_ordinati_per_tempo(self) -> None:
        """! @brief percorsi: due modalità (sharing/TPL), con distanza/tempo, ordinati."""
        corse = GestoreCorse(DataAccessManager(ClienteFalsoFirestore()))
        percorsi = corse.percorsi((41.117, 16.871), (41.125, 16.866))
        self.assertEqual(len(percorsi), 2)
        self.assertEqual({p["modalita"] for p in percorsi}, {"sharing", "tpl"})
        self.assertTrue(all(p["distanza_m"] > 0 for p in percorsi))
        durate = [p["durata_min"] for p in percorsi]
        self.assertEqual(durate, sorted(durate))  # ordinati per tempo crescente

    def test_suggerimenti_luoghi(self) -> None:
        """! @brief suggerisci_luoghi: autocompletamento sul gazetteer locale (UT.07)."""
        corse = GestoreCorse(DataAccessManager(ClienteFalsoFirestore()))
        luoghi = corse.suggerisci_luoghi("petruzzelli")
        self.assertTrue(any("Petruzzelli" in str(luogo["nome"]) for luogo in luoghi))
        self.assertTrue(all({"nome", "lat", "lon"} <= set(luogo) for luogo in luoghi))
        self.assertEqual(corse.suggerisci_luoghi(""), [])  # query vuota → nessun suggerimento

    def test_pianifica_percorsi_per_nome(self) -> None:
        """! @brief pianifica_percorsi: geocodifica i nomi e arricchisce le opzioni (UT.07)."""
        corse = GestoreCorse(DataAccessManager(ClienteFalsoFirestore()))
        esito = corse.pianifica_percorsi(da="Stazione Bari Centrale", a="Teatro Petruzzelli")
        self.assertEqual(esito["totale"], 2)
        self.assertIn("lat", esito["origine"])
        nomi = {str(p["nome"]) for p in esito["percorsi"]}
        self.assertEqual(nomi, {"Percorso diretto", "Con TPL integrato"})
        self.assertTrue(any(p["ha_tpl"] for p in esito["percorsi"]))
        self.assertTrue(all(p["distanza_km"] > 0 for p in esito["percorsi"]))

    def test_pianifica_percorsi_luogo_sconosciuto(self) -> None:
        """! @brief pianifica_percorsi: luogo fuori gazetteer → ValueError (UT.07)."""
        corse = GestoreCorse(DataAccessManager(ClienteFalsoFirestore()))
        with self.assertRaises(ValueError):
            corse.pianifica_percorsi(da="Luogo Inesistente XYZ", a="Teatro Petruzzelli")


class TestResetPassword(unittest.TestCase):
    """! @brief Reset password con codice monouso e conferma (UT.24/AP.12, IIN-11)."""

    def setUp(self) -> None:
        """! @brief DAO su client fake con un utente registrato e il gestore profili."""
        self._dao = DataAccessManager(ClienteFalsoFirestore())
        self._dao.crea_account("UT", "u@leaf.test", "hash-vecchio", id_doc="u1")
        self._profili = GestoreProfiliEkyc(self._dao)

    def test_flusso_reset_completo(self) -> None:
        """! @brief IIN-11: richiesta → codice → conferma imposta la password e consuma il token."""
        richiesta = self._profili.richiedi_reset("u@leaf.test")
        codice = str(richiesta["codice_simulato"])
        esito = self._profili.conferma_reset("u@leaf.test", codice, "NuovaPass1!")
        self.assertTrue(esito["reimpostata"])
        # La nuova password autentica; il token è consumato (monouso).
        account = self._dao.leggi_account_per_email("u@leaf.test")
        assert account is not None
        self.assertTrue(self._dao.verifica_credenziali(account, "NuovaPass1!"))
        self.assertIsNone(self._dao.leggi_token_reset("u1"))

    def test_codice_errato_non_reimposta(self) -> None:
        """! @brief IIN-11: codice errato → reimpostata False, token ancora valido."""
        self._profili.richiedi_reset("u@leaf.test")
        esito = self._profili.conferma_reset("u@leaf.test", "000000", "NuovaPass1!")
        self.assertFalse(esito["reimpostata"])
        self.assertIsNotNone(self._dao.leggi_token_reset("u1"))

    def test_token_scaduto_non_reimposta(self) -> None:
        """! @brief IIN-11: codice scaduto (oltre il TTL) → reimpostata False."""
        scaduto = (datetime.now(UTC) - timedelta(minutes=1)).isoformat()
        self._dao.memorizza_token_reset("u1", _hash_codice("123456"), scaduto)
        esito = self._profili.conferma_reset("u@leaf.test", "123456", "NuovaPass1!")
        self.assertFalse(esito["reimpostata"])

    def test_identita_sconosciuta_non_reimposta(self) -> None:
        """! @brief IIN-11: identità inesistente → reimpostata False (anti-enumerazione)."""
        esito = self._profili.conferma_reset("ignoto@leaf.test", "123456", "NuovaPass1!")
        self.assertFalse(esito["reimpostata"])

    def test_password_debole_rifiutata(self) -> None:
        """! @brief IIN-5: la conferma con password debole solleva ValueError prima di tutto."""
        richiesta = self._profili.richiedi_reset("u@leaf.test")
        codice = str(richiesta["codice_simulato"])
        with self.assertRaises(ValueError):
            self._profili.conferma_reset("u@leaf.test", codice, "debole")


def _hash_codice(codice: str) -> str:
    """! @brief Hash Passlib di un codice di reset, per i test che scrivono token a mano."""
    from server.business_tier.gestore_profili_ekyc import _CTX_PASSWORD

    return str(_CTX_PASSWORD.hash(codice))


if __name__ == "__main__":
    unittest.main()
