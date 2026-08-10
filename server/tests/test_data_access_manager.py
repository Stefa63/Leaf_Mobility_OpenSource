"""! @file test_data_access_manager.py
@brief Test del layer di persistenza Firestore (DataAccessManager) — OFFLINE, client fake.

Esercitano CRUD, gerarchie ISA, subcollezioni, cifratura dei campi 🔒, primitive geo,
integrità referenziale e i vincoli §6.9 (IIN-14, blocco esclusivo, XOR) usando il
@ref ClienteFalsoFirestore in-memory: nessuna credenziale, nessun emulatore, nessun
progetto Google (testabilità §12.2).
"""

from __future__ import annotations

import base64
import importlib.util
import os
import unittest

from server.integration_tier.data_access_manager import (
    DataAccessManager,
    ErroreIntegrita,
    LimiteDispositivi,
    MezzoNonDisponibile,
    ViolazioneUnicita,
    ViolazioneXor,
)
from server.integration_tier.data_access_manager import collezioni as col
from server.integration_tier.data_access_manager.cifratura import (
    CifrarioAes256Gcm,
    CifrarioNullo,
    cifrario_da_ambiente,
)
from server.integration_tier.data_access_manager.cliente_falso import ClienteFalsoFirestore
from server.integration_tier.data_access_manager.geo import (
    geohash,
    punto_in_poligono,
    riquadro,
)


class _CifrarioTest:
    """! @brief Cifrario reversibile di test (per verificare il routing dei campi 🔒)."""

    attivo: bool = True

    def cifra(self, testo: str) -> str:
        """! @brief Cifra fittizia (prefisso + inversione). @param testo Valore. @return Token."""
        return "ENC:" + testo[::-1]

    def decifra(self, token: str) -> str:
        """! @brief Decifra fittizia. @param token Token. @return Valore in chiaro."""
        return token[len("ENC:") :][::-1]


class TestCrudIsa(unittest.TestCase):
    """! @brief CRUD generico e gerarchie ISA (account/mezzi)."""

    def setUp(self) -> None:
        """! @brief Crea un DAO su client fake."""
        self._dao = DataAccessManager(ClienteFalsoFirestore())

    def test_crud_round_trip(self) -> None:
        """! @brief crea/leggi/aggiorna/elimina/elenca su una collezione top-level."""
        id_tec = self._dao.crea(col.TECNICI, {"nome": "Ada", "stato": "disponibile"}, id_doc="t1")
        self.assertEqual(id_tec, "t1")
        letto = self._dao.leggi(col.TECNICI, "t1")
        assert letto is not None
        self.assertEqual(letto["nome"], "Ada")
        self.assertEqual(letto["_id"], "t1")
        self._dao.aggiorna(col.TECNICI, "t1", {"stato": "occupato"})
        letto2 = self._dao.leggi(col.TECNICI, "t1")
        assert letto2 is not None
        self.assertEqual(letto2["stato"], "occupato")
        self.assertEqual(len(self._dao.elenca(col.TECNICI)), 1)
        self._dao.elimina(col.TECNICI, "t1")
        self.assertIsNone(self._dao.leggi(col.TECNICI, "t1"))

    def test_collezione_non_prevista(self) -> None:
        """! @brief Una collezione fuori dal modello §10.2 è rifiutata."""
        with self.assertRaises(ValueError):
            self._dao.crea("collezione_inventata", {"x": 1})

    def test_account_chiave_condivisa(self) -> None:
        """! @brief Account normalizzato: doc account + profilo utenti a chiave condivisa (§6.1)."""
        id_acc = self._dao.crea_account(
            "UT", "a@b.c", "hash", profilo={"saldo_km": 10}, id_doc="u1"
        )
        self.assertEqual(id_acc, "u1")
        acc = self._dao.leggi(col.ACCOUNT, "u1")
        assert acc is not None
        self.assertEqual(acc["ruolo"], "UT")
        self.assertEqual(acc["stato_account"], "attivo")
        self.assertNotIn("datiUtente", acc)  # niente map embedded: profilo normalizzato
        profilo = self._dao.leggi_profilo(acc)
        assert profilo is not None
        self.assertEqual(profilo["_id"], "u1")  # document ID = id_account
        self.assertEqual(profilo["saldo_km"], 10)
        self.assertEqual(profilo["dispositivi_attivi"], 0)

    def test_account_email_duplicata(self) -> None:
        """! @brief §6.4/IIN-1: una seconda email uguale è rifiutata dal registro di unicità."""
        self._dao.crea_account("UT", "dup@b.c", "hash", id_doc="u1")
        with self.assertRaises(ViolazioneUnicita):
            self._dao.crea_account("UT", "dup@b.c", "hash", id_doc="u2")

    def test_ruolo_non_valido(self) -> None:
        """! @brief Un ruolo fuori dalla gerarchia Account è rifiutato."""
        with self.assertRaises(ValueError):
            self._dao.crea_account("ROOT", "a@b.c", "hash")

    def test_mezzo_con_geohash_e_indice(self) -> None:
        """! @brief Mezzo: discriminante + attributi_specifici + geohash + registro codice."""
        id_mezzo = self._dao.crea_mezzo(
            "ebike",
            {
                "codice_identificativo": "BK-1",
                "stato_operativo": "disponibile",
                "lat": 41.117,
                "lon": 16.871,
            },
            attributi={"num_marce": 7},
        )
        mezzo = self._dao.leggi(col.MEZZI, id_mezzo)
        assert mezzo is not None
        self.assertEqual(mezzo["tipo_mezzo"], "ebike")
        self.assertEqual(mezzo["attributi_specifici"]["num_marce"], 7)
        self.assertEqual(mezzo["geohash"], geohash(41.117, 16.871))
        self.assertEqual(mezzo["posizione"], {"lat": 41.117, "lon": 16.871})
        # Lookup per chiave naturale tramite il registro mezzo_index.
        per_codice = self._dao.leggi_mezzo_per_codice("BK-1")
        assert per_codice is not None
        self.assertEqual(per_codice["_id"], id_mezzo)

    def test_esegui_query_non_supportato(self) -> None:
        """! @brief esegui_query (SQL) non è supportato su Firestore."""
        with self.assertRaises(NotImplementedError):
            self._dao.esegui_query("SELECT 1")

    def test_connesso(self) -> None:
        """! @brief connesso() riflette la presenza del client."""
        self.assertTrue(self._dao.connesso())
        self.assertFalse(DataAccessManager().connesso())


class TestSubcollezioniECifratura(unittest.TestCase):
    """! @brief Subcollezioni 1:N e cifratura dei campi 🔒."""

    def test_subcollezione_metodi_pagamento(self) -> None:
        """! @brief crea_in_sub/elenca_sub su utenti/{id}/metodi_pagamento."""
        dao = DataAccessManager(ClienteFalsoFirestore())
        dao.crea_account("UT", "a@b.c", "hash", id_doc="u1")
        dao.crea_in_sub(
            col.UTENTI, "u1", col.SUB_METODI_PAGAMENTO, {"brand": "Visa", "ultime4_cifre": "4242"}
        )
        metodi = dao.elenca_sub(col.UTENTI, "u1", col.SUB_METODI_PAGAMENTO)
        self.assertEqual(len(metodi), 1)
        self.assertEqual(metodi[0]["brand"], "Visa")

    def test_subcollezione_non_ammessa(self) -> None:
        """! @brief Una subcollezione non prevista per il padre è rifiutata."""
        dao = DataAccessManager(ClienteFalsoFirestore())
        dao.crea_account("UT", "a@b.c", "hash", id_doc="u1")
        with self.assertRaises(ValueError):
            dao.crea_in_sub(col.UTENTI, "u1", "inventata", {"x": 1})

    def test_cifratura_campi_sensibili(self) -> None:
        """! @brief Campi 🔒 del profilo utenti: cifrati a riposo, decifrati in lettura (IIN-4)."""
        cliente = ClienteFalsoFirestore()
        dao = DataAccessManager(cliente, cifrario=_CifrarioTest())
        dao.crea_account("UT", "a@b.c", "hash", profilo={"nome": "Giulia"}, id_doc="u1")
        # Valore grezzo a riposo nel profilo utenti: cifrato (diverso dall'originale).
        grezzo = cliente.collection(col.UTENTI).document("u1").get().to_dict()
        assert grezzo is not None
        self.assertNotEqual(grezzo["nome"], "Giulia")
        self.assertTrue(grezzo["nome"].startswith("ENC:"))
        # Lettura tramite DAO: decifrato.
        profilo = dao.leggi(col.UTENTI, "u1")
        assert profilo is not None
        self.assertEqual(profilo["nome"], "Giulia")


class TestGeo(unittest.TestCase):
    """! @brief Primitive geospaziali e ricerca per prossimità."""

    def test_geohash_deterministico(self) -> None:
        """! @brief Il geohash è deterministico e della precisione richiesta."""
        self.assertEqual(geohash(41.117, 16.871), geohash(41.117, 16.871))
        self.assertEqual(len(geohash(41.117, 16.871, 7)), 7)

    def test_riquadro_contiene_centro(self) -> None:
        """! @brief Il bounding-box contiene il centro e cresce col raggio."""
        lat_min, lat_max, lon_min, lon_max = riquadro(41.117, 16.871, 1000)
        self.assertLess(lat_min, 41.117)
        self.assertGreater(lat_max, 41.117)
        self.assertLess(lon_min, 16.871)
        self.assertGreater(lon_max, 16.871)

    def test_punto_in_poligono(self) -> None:
        """! @brief Il ray-casting distingue interno/esterno al poligono."""
        quad = [(0.0, 0.0), (0.0, 10.0), (10.0, 10.0), (10.0, 0.0)]
        self.assertTrue(punto_in_poligono(5.0, 5.0, quad))
        self.assertFalse(punto_in_poligono(20.0, 20.0, quad))

    def test_mezzi_disponibili_per_prossimita(self) -> None:
        """! @brief mezzi_disponibili filtra per stato_operativo/bbox e ordina per distanza."""
        dao = DataAccessManager(ClienteFalsoFirestore())
        dao.crea_mezzo(
            "ebike", {"stato_operativo": "disponibile", "lat": 41.1170, "lon": 16.8710}, id_doc="A"
        )
        dao.crea_mezzo(
            "ebike", {"stato_operativo": "disponibile", "lat": 41.1180, "lon": 16.8720}, id_doc="B"
        )
        dao.crea_mezzo(
            "ecar", {"stato_operativo": "in_uso", "lat": 41.1171, "lon": 16.8711}, id_doc="C"
        )
        dao.crea_mezzo(
            "ebike", {"stato_operativo": "disponibile", "lat": 45.0, "lon": 9.0}, id_doc="LONTANO"
        )
        vicini = dao.mezzi_disponibili(lat=41.1170, lon=16.8710, raggio_m=2000)
        ids = [m["_id"] for m in vicini]
        self.assertEqual(ids, ["A", "B"])  # ordinati per distanza, esclusi in_uso e lontano

    def test_aree_contenenti(self) -> None:
        """! @brief aree_contenenti applica il point-in-polygon alle aree attive."""
        dao = DataAccessManager(ClienteFalsoFirestore())
        dao.crea(
            col.AREE_LIMITATE,
            {
                "nome": "Q",
                "tipo": "slow_zone",
                "stato": "attiva",
                "geometria": [
                    {"lat": 41.10, "lon": 16.85},
                    {"lat": 41.10, "lon": 16.90},
                    {"lat": 41.14, "lon": 16.90},
                    {"lat": 41.14, "lon": 16.85},
                ],
            },
            id_doc="area1",
        )
        dentro = dao.aree_contenenti(41.12, 16.87)
        self.assertEqual([a["_id"] for a in dentro], ["area1"])
        self.assertEqual(dao.aree_contenenti(0.0, 0.0), [])


class TestVincoli(unittest.TestCase):
    """! @brief Vincoli §6.9 via transazioni e integrità referenziale."""

    def setUp(self) -> None:
        """! @brief DAO su client fake con un utente e un mezzo disponibili."""
        self._dao = DataAccessManager(ClienteFalsoFirestore())
        self._dao.crea_account("UT", "u@leaf.test", "hash", id_doc="u1")
        self._id_mezzo = self._dao.crea_mezzo(
            "ebike",
            {
                "codice_identificativo": "M1",
                "stato_operativo": "disponibile",
                "lat": 41.1,
                "lon": 16.8,
            },
            id_doc="M1",
        )

    def test_limite_tre_dispositivi(self) -> None:
        """! @brief IIN-14: il 4° dispositivo attivo è rifiutato (§6.1 #8)."""
        for i in range(3):
            self._dao.registra_dispositivo("u1", f"dev{i}")
        with self.assertRaises(LimiteDispositivi):
            self._dao.registra_dispositivo("u1", "dev3")
        profilo = self._dao.leggi(col.UTENTI, "u1")
        assert profilo is not None
        self.assertEqual(profilo["dispositivi_attivi"], 3)

    def test_relogin_stesso_dispositivo_non_consuma_slot(self) -> None:
        """! @brief IIN-14: ri-registrare lo STESSO device non incrementa il contatore (fix login).

        Senza idempotenza, ogni login (dopo riavvio app/server con sessioni in-memory perse)
        gonfiava `dispositivi_attivi` causando falsi "limite dispositivi superato".
        """
        self._dao.registra_dispositivo("u1", "telefono-ste")
        self._dao.registra_dispositivo("u1", "telefono-ste")
        self._dao.registra_dispositivo("u1", "telefono-ste")
        profilo = self._dao.leggi(col.UTENTI, "u1")
        assert profilo is not None
        self.assertEqual(profilo["dispositivi_attivi"], 1)  # un solo slot, non tre
        # E un device già attivo continua ad accedere anche a contatore "pieno".
        self._dao.registra_dispositivo("u1", "dev-a")
        self._dao.registra_dispositivo("u1", "dev-b")
        self.assertEqual(self._dao.registra_dispositivo("u1", "telefono-ste"), "telefono-ste")

    def test_dispositivo_utente_inesistente(self) -> None:
        """! @brief Registrare un dispositivo su un utente inesistente è errore."""
        with self.assertRaises(ErroreIntegrita):
            self._dao.registra_dispositivo("ignoto", "dev")

    def test_blocco_esclusivo_prenotazione(self) -> None:
        """! @brief UT.02: una seconda prenotazione sullo stesso mezzo è rifiutata (§6.1 #24)."""
        self._dao.prenota_mezzo("u1", "M1")
        mezzo = self._dao.leggi(col.MEZZI, "M1")
        assert mezzo is not None
        self.assertEqual(mezzo["stato_operativo"], "prenotato")
        with self.assertRaises(MezzoNonDisponibile):
            self._dao.prenota_mezzo("u1", "M1")
        # La prenotazione denormalizza codice e tipo del mezzo (📎, §6.6).
        prenotazioni = self._dao.elenca(col.PRENOTAZIONI)
        self.assertEqual(prenotazioni[0]["codice_identificativo_mezzo"], "M1")
        self.assertEqual(prenotazioni[0]["tipo_mezzo"], "ebike")

    def test_pagamento_xor(self) -> None:
        """! @brief Pagamento corsa/abbonamento con XOR violato è rifiutato."""
        self._dao.crea(col.CORSE, {"id_utente": "u1", "id_mezzo": "M1"}, id_doc="c1")
        # Esattamente uno valorizzato: ok.
        self._dao.registra_pagamento(
            {"tipo": "corsa", "importo_cent": 350, "id_utente": "u1", "id_corsa": "c1"}
        )
        # Entrambi valorizzati: errore.
        with self.assertRaises(ViolazioneXor):
            self._dao.registra_pagamento(
                {"tipo": "corsa", "id_corsa": "c1", "id_abbonamento": "ab1"}
            )
        # Nessuno valorizzato: errore.
        with self.assertRaises(ViolazioneXor):
            self._dao.registra_pagamento({"tipo": "abbonamento", "importo_cent": 999})

    def test_integrita_referenziale(self) -> None:
        """! @brief Un reference id_X inesistente è rifiutato (integrità applicativa)."""
        with self.assertRaises(ErroreIntegrita):
            self._dao.crea(col.CORSE, {"id_utente": "ignoto", "id_mezzo": "M1"})


class TestCifrarioAes(unittest.TestCase):
    """! @brief Cifrario AES-256-GCM reale e selezione della strategia da ambiente (IIN-4)."""

    def test_chiave_lunghezza_errata(self) -> None:
        """! @brief Una chiave non di 32 byte è rifiutata."""
        with self.assertRaises(ValueError):
            CifrarioAes256Gcm(b"corta")

    @unittest.skipUnless(
        importlib.util.find_spec("cryptography") is not None, "cryptography non installata"
    )
    def test_round_trip_aes(self) -> None:
        """! @brief cifra→decifra restituisce il valore originale; il token differisce."""
        cifrario = CifrarioAes256Gcm(b"0" * 32)
        token = cifrario.cifra("dato sensibile 🔒")
        self.assertNotEqual(token, "dato sensibile 🔒")
        self.assertEqual(cifrario.decifra(token), "dato sensibile 🔒")
        # Nonce casuale: due cifrature dello stesso testo danno token diversi.
        self.assertNotEqual(cifrario.cifra("x"), cifrario.cifra("x"))

    def test_cifrario_da_ambiente_default_nullo(self) -> None:
        """! @brief Senza LEAF_AES_KEY la strategia è passthrough (non cifra)."""
        precedente = os.environ.pop("LEAF_AES_KEY", None)
        try:
            self.assertIsInstance(cifrario_da_ambiente(), CifrarioNullo)
        finally:
            if precedente is not None:
                os.environ["LEAF_AES_KEY"] = precedente

    @unittest.skipUnless(
        importlib.util.find_spec("cryptography") is not None, "cryptography non installata"
    )
    def test_cifrario_da_ambiente_attivo_con_chiave(self) -> None:
        """! @brief Con LEAF_AES_KEY valida la strategia è AES-256 attiva."""
        chiave = base64.b64encode(b"1" * 32).decode("ascii")
        precedente = os.environ.get("LEAF_AES_KEY")
        os.environ["LEAF_AES_KEY"] = chiave
        try:
            cifrario = cifrario_da_ambiente()
            self.assertIsInstance(cifrario, CifrarioAes256Gcm)
            self.assertTrue(cifrario.attivo)
        finally:
            if precedente is None:
                os.environ.pop("LEAF_AES_KEY", None)
            else:
                os.environ["LEAF_AES_KEY"] = precedente


class TestCollezioniSchema(unittest.TestCase):
    """! @brief Collezioni/registri dello schema logico: documenti, telemetria, unicità."""

    def setUp(self) -> None:
        """! @brief DAO con cifrario di test per verificare i campi 🔒 a riposo."""
        self._dao = DataAccessManager(ClienteFalsoFirestore(), cifrario=_CifrarioTest())
        self._dao.crea_account("UT", "u@leaf.test", "hash", id_doc="u1")

    def test_documenti_ufficiali_cifrati(self) -> None:
        """! @brief documenti_ufficiali: campi 🔒 (numero/storage_path) cifrati a riposo (§6.5)."""
        id_doc = self._dao.crea(
            col.DOCUMENTI_UFFICIALI,
            {
                "id_utente": "u1",
                "tipo": "patente",
                "numero_documento": "BA1234567",
                "storage_path": "kyc/u1/patente.pdf",
                "formato": "pdf",
                "stato_verifica": "in_attesa",
            },
        )
        letto = self._dao.leggi(col.DOCUMENTI_UFFICIALI, id_doc)
        assert letto is not None
        self.assertEqual(letto["numero_documento"], "BA1234567")  # decifrato in lettura
        self.assertEqual(letto["storage_path"], "kyc/u1/patente.pdf")

    def test_documento_riferimento_inesistente(self) -> None:
        """! @brief documenti_ufficiali con id_utente inesistente è rifiutato (integrità)."""
        with self.assertRaises(ErroreIntegrita):
            self._dao.crea(col.DOCUMENTI_UFFICIALI, {"id_utente": "ignoto", "tipo": "patente"})

    def test_punti_traccia_sottocoll_corsa(self) -> None:
        """! @brief punti_traccia: sottocoll. di corse con punto GPS 🔒 cifrato (OP.07)."""
        self._dao.crea(col.CORSE, {"id_utente": "u1"}, id_doc="c1")
        self._dao.crea_in_sub(
            col.CORSE,
            "c1",
            col.SUB_PUNTI_TRACCIA,
            {"punto": "41.12,16.87", "t": "2026-06-01T10:00"},
        )
        punti = self._dao.elenca_sub(col.CORSE, "c1", col.SUB_PUNTI_TRACCIA)
        self.assertEqual(len(punti), 1)
        self.assertEqual(punti[0]["punto"], "41.12,16.87")  # decifrato in lettura

    def test_eventi_telemetria_denorm_e_cifratura(self) -> None:
        """! @brief eventi_telemetria: denorm codice mezzo (📎) + posizione 🔒 (§6.6/§6.5)."""
        id_mezzo = self._dao.crea_mezzo(
            "monopattino", {"codice_identificativo": "SC-9", "stato_operativo": "in_uso"}
        )
        self._dao.crea_in_sub(
            col.MEZZI,
            id_mezzo,
            col.SUB_EVENTI_TELEMETRIA,
            {"id_mezzo": id_mezzo, "tipo_evento": "sblocco", "posizione": "41.1,16.8"},
        )
        eventi = self._dao.elenca_sub(col.MEZZI, id_mezzo, col.SUB_EVENTI_TELEMETRIA)
        self.assertEqual(eventi[0]["codice_identificativo_mezzo"], "SC-9")  # 📎 denorm
        self.assertEqual(eventi[0]["posizione"], "41.1,16.8")  # 🔒 decifrato in lettura

    def test_username_index_duplicato(self) -> None:
        """! @brief §6.4: lo stesso username su due account è rifiutato (username_index)."""
        self._dao.crea_account("UT", "a@b.c", "hash", username="mario", id_doc="a1")
        with self.assertRaises(ViolazioneUnicita):
            self._dao.crea_account("UT", "c@d.e", "hash", username="mario", id_doc="a2")

    def test_mezzo_index_codice_duplicato(self) -> None:
        """! @brief §6.4: lo stesso codice_identificativo su due mezzi è rifiutato (mezzo_index)."""
        self._dao.crea_mezzo("ebike", {"codice_identificativo": "BK-DUP"})
        with self.assertRaises(ViolazioneUnicita):
            self._dao.crea_mezzo("ecar", {"codice_identificativo": "BK-DUP"})


if __name__ == "__main__":
    unittest.main()
