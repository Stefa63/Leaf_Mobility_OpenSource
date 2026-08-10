"""! @file test_slice_persistenza.py
@brief Slice verticale: /api/v1/auth/login e /api/v1/veicoli su Firestore (deliverable §9).

Verifica end-to-end (Presentation → Business → Integration) che, con la persistenza
configurata (qui un @ref ClienteFalsoFirestore popolato dal seed), il login verifichi
l'account e l'elenco veicoli legga da `mezzi`, smettendo di rispondere "in sviluppo".
Tutto OFFLINE: nessuna credenziale, nessun emulatore (testabilità §12.2).
"""

from __future__ import annotations

import os
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from fastapi.testclient import TestClient

from server.integration_tier.data_access_manager import (
    DataAccessManager,
    azzera_dao,
    imposta_dao,
)
from server.integration_tier.data_access_manager import collezioni as col
from server.integration_tier.data_access_manager.bootstrap_seed import PASSWORD_DEMO, esegui_seed
from server.integration_tier.data_access_manager.cliente_falso import ClienteFalsoFirestore
from server.presentation_tier.api_pubblica import PREFISSO_API
from server.runtime.app_factory import crea_app
from server.runtime.impostazioni import Impostazioni


class TestSlicePersistenzaConfigurata(unittest.TestCase):
    """! @brief Slice con persistenza configurata: login e veicoli usano Firestore."""

    def setUp(self) -> None:
        """! @brief Inietta un DAO su client fake popolato dal seed e costruisce l'app."""
        self._tmp = tempfile.TemporaryDirectory()
        base = Path(self._tmp.name)
        self._dao = DataAccessManager(ClienteFalsoFirestore())
        esegui_seed(self._dao)
        imposta_dao(self._dao)
        imp = Impostazioni(dati_dir=base / "dati", backup_dir=base / "backups")
        self._client = TestClient(crea_app(imp))
        self._client.__enter__()

    def tearDown(self) -> None:
        """! @brief Chiude il client, azzera l'iniezione del DAO e pulisce le cartelle."""
        self._client.__exit__(None, None, None)
        azzera_dao()
        self._tmp.cleanup()

    def test_login_credenziali_valide(self) -> None:
        """! @brief Login UT valido: stato ok con access_token e ruolo (contratto dio)."""
        resp = self._client.post(
            f"{PREFISSO_API}/auth/login",
            json={"identita": "utente.demo@leaf.test", "password": PASSWORD_DEMO},
        )
        self.assertEqual(resp.status_code, 200)
        corpo = resp.json()
        self.assertEqual(corpo["stato"], "ok")
        self.assertEqual(corpo["ruolo"], "UT")
        self.assertTrue(corpo["access_token"])

    def test_login_password_errata(self) -> None:
        """! @brief Login con password errata: 401 Credenziali non valide."""
        resp = self._client.post(
            f"{PREFISSO_API}/auth/login",
            json={"identita": "utente.demo@leaf.test", "password": "sbagliata"},
        )
        self.assertEqual(resp.status_code, 401)

    def test_login_op_richiede_mfa(self) -> None:
        """! @brief Login OP valido: stato mfa_richiesta (IIN-9), nessun token immediato."""
        resp = self._client.post(
            f"{PREFISSO_API}/auth/login",
            json={"identita": "operatore.demo@leaf.test", "password": PASSWORD_DEMO},
        )
        corpo = resp.json()
        self.assertEqual(corpo["stato"], "mfa_richiesta")
        self.assertTrue(corpo["id_account"])
        self.assertNotIn("access_token", corpo)

    def test_mfa_flusso_completo(self) -> None:
        """! @brief OP: login apre la sessione MFA, l'OTP corretto emette il token (IIN-9)."""
        login = self._client.post(
            f"{PREFISSO_API}/auth/login",
            json={"identita": "operatore.demo@leaf.test", "password": PASSWORD_DEMO},
        ).json()
        self.assertEqual(login["stato"], "mfa_richiesta")
        verifica = self._client.post(
            f"{PREFISSO_API}/auth/mfa",
            json={"id_account": login["id_account"], "otp": login["otp_simulato"]},
        )
        self.assertEqual(verifica.status_code, 200)
        self.assertTrue(verifica.json()["access_token"])
        # Uso singolo: lo stesso id_account non è più in attesa di OTP.
        riuso = self._client.post(
            f"{PREFISSO_API}/auth/mfa",
            json={"id_account": login["id_account"], "otp": login["otp_simulato"]},
        )
        self.assertEqual(riuso.status_code, 401)

    def test_mfa_otp_errato(self) -> None:
        """! @brief Un OTP errato non valida la sessione MFA (401)."""
        login = self._client.post(
            f"{PREFISSO_API}/auth/login",
            json={"identita": "operatore.demo@leaf.test", "password": PASSWORD_DEMO},
        ).json()
        verifica = self._client.post(
            f"{PREFISSO_API}/auth/mfa",
            json={"id_account": login["id_account"], "otp": "000000"},
        )
        self.assertEqual(verifica.status_code, 401)

    def test_lockout_dopo_tentativi(self) -> None:
        """! @brief IIN-10: dopo 5 password errate l'account è bloccato (423)."""
        ultimo = None
        for _ in range(5):
            ultimo = self._client.post(
                f"{PREFISSO_API}/auth/login",
                json={"identita": "utente.demo@leaf.test", "password": "errata"},
            )
        assert ultimo is not None
        self.assertEqual(ultimo.status_code, 423)  # 5° tentativo: account bloccato
        # Anche con la password giusta l'accesso è negato finché dura il blocco.
        valido = self._client.post(
            f"{PREFISSO_API}/auth/login",
            json={"identita": "utente.demo@leaf.test", "password": PASSWORD_DEMO},
        )
        self.assertEqual(valido.status_code, 423)

    def test_lockout_istituzionale(self) -> None:
        """! @brief IIN-10: AP/OP bloccati dopo 3 tentativi (423)."""
        ultimo = None
        for _ in range(3):
            ultimo = self._client.post(
                f"{PREFISSO_API}/auth/login",
                json={"identita": "operatore.demo@leaf.test", "password": "errata"},
            )
        assert ultimo is not None
        self.assertEqual(ultimo.status_code, 423)  # 3° tentativo: account bloccato
        valido = self._client.post(
            f"{PREFISSO_API}/auth/login",
            json={"identita": "operatore.demo@leaf.test", "password": PASSWORD_DEMO},
        )
        self.assertEqual(valido.status_code, 423)

    def _login_token(self) -> str:
        """! @brief Esegue il login UT demo e restituisce il token di sessione (Bearer)."""
        corpo = self._client.post(
            f"{PREFISSO_API}/auth/login",
            json={"identita": "utente.demo@leaf.test", "password": PASSWORD_DEMO},
        ).json()
        return str(corpo["access_token"])

    def test_ciclo_corsa_e2e(self) -> None:
        """! @brief E2E /prenotazioni→/corse→termina: sblocco, addebito, fattura, mezzo liberato."""
        headers = {"Authorization": f"Bearer {self._login_token()}"}
        pren = self._client.post(
            f"{PREFISSO_API}/prenotazioni", json={"id_mezzo": "BK-007"}, headers=headers
        ).json()
        self.assertTrue(pren["disponibile"])
        avvio = self._client.post(
            f"{PREFISSO_API}/corse",
            json={"id_mezzo": "BK-007", "id_prenotazione": pren["dati"]["id_prenotazione"]},
            headers=headers,
        ).json()["dati"]
        self.assertTrue(avvio["sbloccato"])
        id_corsa = avvio["id_corsa"]
        fine = self._client.post(
            f"{PREFISSO_API}/corse/{id_corsa}/termina", json={"km": 3.0}, headers=headers
        ).json()["dati"]
        self.assertGreater(fine["costo_finale_cent"], 0)
        self.assertTrue(fine["id_pagamento"])
        self.assertTrue(fine["id_fattura"])
        # Mezzo liberato, pagamento e fattura persistiti.
        mezzo = self._dao.leggi(col.MEZZI, "BK-007")
        assert mezzo is not None
        self.assertEqual(mezzo["stato_operativo"], "disponibile")
        pagamento = self._dao.leggi(col.PAGAMENTI, fine["id_pagamento"])
        assert pagamento is not None
        self.assertEqual(pagamento["id_corsa"], id_corsa)
        self.assertIsNotNone(self._dao.leggi(col.FATTURE, fine["id_fattura"]))

    def _login_op_token(self) -> str:
        """! @brief Login OP demo + verifica MFA; restituisce il token di sessione (IIN-9)."""
        login = self._client.post(
            f"{PREFISSO_API}/auth/login",
            json={"identita": "operatore.demo@leaf.test", "password": PASSWORD_DEMO},
        ).json()
        corpo = self._client.post(
            f"{PREFISSO_API}/auth/mfa",
            json={"id_account": login["id_account"], "otp": login["otp_simulato"]},
        ).json()
        return str(corpo["access_token"])

    def test_profilo_utente(self) -> None:
        """! @brief GET /profilo espone i dati dell'utente senza campi riservati (UT.21/IIN-4)."""
        headers = {"Authorization": f"Bearer {self._login_token()}"}
        corpo = self._client.get(f"{PREFISSO_API}/profilo", headers=headers).json()
        self.assertTrue(corpo["disponibile"])
        self.assertEqual(corpo["dati"]["email"], "utente.demo@leaf.test")
        self.assertNotIn("password_hash", corpo["dati"])

    def test_storico_e_fatture_dopo_corsa(self) -> None:
        """! @brief Dopo una corsa, /corse e /fatture restituiscono lo storico (UT.17/UT.25)."""
        headers = {"Authorization": f"Bearer {self._login_token()}"}
        pren = self._client.post(
            f"{PREFISSO_API}/prenotazioni", json={"id_mezzo": "BK-007"}, headers=headers
        ).json()
        avvio = self._client.post(
            f"{PREFISSO_API}/corse",
            json={"id_mezzo": "BK-007", "id_prenotazione": pren["dati"]["id_prenotazione"]},
            headers=headers,
        ).json()["dati"]
        self._client.post(
            f"{PREFISSO_API}/corse/{avvio['id_corsa']}/termina", json={"km": 2.0}, headers=headers
        )
        storico = self._client.get(f"{PREFISSO_API}/corse", headers=headers).json()
        self.assertTrue(storico["disponibile"])
        self.assertGreaterEqual(storico["dati"]["totale"], 1)
        fatture = self._client.get(f"{PREFISSO_API}/fatture", headers=headers).json()
        self.assertGreaterEqual(fatture["dati"]["totale"], 1)

    def test_flotta_rbac(self) -> None:
        """! @brief /flotta è riservata a OP/PA: UT riceve 403, OP riceve l'elenco (AP.03/OP.20)."""
        ut = self._client.get(
            f"{PREFISSO_API}/flotta",
            headers={"Authorization": f"Bearer {self._login_token()}"},
        )
        self.assertEqual(ut.status_code, 403)
        op = self._client.get(
            f"{PREFISSO_API}/flotta",
            headers={"Authorization": f"Bearer {self._login_op_token()}"},
        ).json()
        self.assertTrue(op["disponibile"])
        self.assertGreater(op["dati"]["totale"], 0)

    def test_analitiche_anonime(self) -> None:
        """! @brief /analitiche è accessibile a OP/PA e non espone identificativi (IIN-15)."""
        op_headers = {"Authorization": f"Bearer {self._login_op_token()}"}
        corpo = self._client.get(f"{PREFISSO_API}/analitiche", headers=op_headers).json()
        self.assertTrue(corpo["disponibile"])
        for aggregato in corpo["dati"]["per_tipo"]:
            self.assertNotIn("id_utente", aggregato)
            self.assertNotIn("_id", aggregato)

    def test_corse_senza_sessione_401(self) -> None:
        """! @brief Senza token di sessione valido l'avvio corsa è negato (401)."""
        resp = self._client.post(
            f"{PREFISSO_API}/corse",
            json={"id_mezzo": "BK-007"},
            headers={"Authorization": "Bearer inesistente"},
        )
        self.assertEqual(resp.status_code, 401)

    def test_veicoli_legge_da_mezzi(self) -> None:
        """! @brief /veicoli restituisce i mezzi disponibili dal seed (UT.01/UT.05)."""
        resp = self._client.get(f"{PREFISSO_API}/veicoli")
        corpo = resp.json()
        self.assertTrue(corpo["disponibile"])
        self.assertGreater(corpo["dati"]["totale"], 0)
        self.assertTrue(all(m["stato_operativo"] == "disponibile" for m in corpo["dati"]["mezzi"]))

    def test_veicoli_per_prossimita(self) -> None:
        """! @brief /veicoli con lat/lon filtra per vicinanza (bounding-box)."""
        resp = self._client.get(f"{PREFISSO_API}/veicoli", params={"lat": 41.117, "lon": 16.871})
        corpo = resp.json()
        self.assertTrue(corpo["disponibile"])
        self.assertGreaterEqual(corpo["dati"]["totale"], 1)


class TestSlicePersistenzaNonConfigurata(unittest.TestCase):
    """! @brief Senza persistenza configurata lo slice resta sull'inviluppo "in sviluppo"."""

    def setUp(self) -> None:
        """! @brief Costruisce l'app SENZA iniettare alcun DAO.

        Svuota @c LEAF_FIREBASE_CRED e @c FIRESTORE_EMULATOR_HOST per la durata del
        test: lo stato "non configurato" deve valere a prescindere da un eventuale
        .env/credenziali reali presenti in locale (l'import-time di app_factory
        carica .env in os.environ).
        """
        self._env = mock.patch.dict(
            os.environ, {"LEAF_FIREBASE_CRED": "", "FIRESTORE_EMULATOR_HOST": ""}
        )
        self._env.start()
        azzera_dao()  # nessun DAO iniettato, nessun client reale (offline)
        self._tmp = tempfile.TemporaryDirectory()
        base = Path(self._tmp.name)
        imp = Impostazioni(dati_dir=base / "dati", backup_dir=base / "backups")
        self._client = TestClient(crea_app(imp))
        self._client.__enter__()

    def tearDown(self) -> None:
        """! @brief Chiude il client, ripristina l'ambiente e pulisce le cartelle."""
        self._client.__exit__(None, None, None)
        azzera_dao()
        self._env.stop()
        self._tmp.cleanup()

    def test_login_in_sviluppo(self) -> None:
        """! @brief Login senza DB configurato risponde 503 (servizio non disponibile)."""
        resp = self._client.post(
            f"{PREFISSO_API}/auth/login",
            json={"identita": "x@y.z", "password": "p"},
        )
        self.assertEqual(resp.status_code, 503)
        self.assertIn("sviluppo", resp.json()["detail"].lower())


if __name__ == "__main__":
    unittest.main()
