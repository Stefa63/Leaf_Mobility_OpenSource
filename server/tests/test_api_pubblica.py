"""! @file test_api_pubblica.py
@brief Test della API client-facing /api/v1 (dispositivi esterni: mobile e web).
"""

from __future__ import annotations

import os
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from fastapi.testclient import TestClient

from server.integration_tier.data_access_manager import azzera_dao
from server.presentation_tier.api_pubblica import PREFISSO_API
from server.runtime.app_factory import crea_app
from server.runtime.impostazioni import Impostazioni


class TestApiPubblica(unittest.TestCase):
    """! @brief Verifica info, salute, CORS e inviluppo "in sviluppo" della API."""

    def setUp(self) -> None:
        """! @brief Costruisce un'app con cartelle dati temporanee e client.

        Isola la configurazione di persistenza (svuota @c LEAF_FIREBASE_CRED e
        @c FIRESTORE_EMULATOR_HOST): l'inviluppo "in sviluppo" deve valere a
        prescindere da un eventuale .env/credenziali reali presenti in locale.
        """
        self._env = mock.patch.dict(
            os.environ, {"LEAF_FIREBASE_CRED": "", "FIRESTORE_EMULATOR_HOST": ""}
        )
        self._env.start()
        azzera_dao()  # nessun DAO reale dalla cache di esecuzioni precedenti
        self._tmp = tempfile.TemporaryDirectory()
        base = Path(self._tmp.name)
        self._imp = Impostazioni(dati_dir=base / "dati", backup_dir=base / "backups")
        self._client = TestClient(crea_app(self._imp))
        self._client.__enter__()

    def tearDown(self) -> None:
        """! @brief Chiude il client, ripristina l'ambiente e rimuove le cartelle."""
        self._client.__exit__(None, None, None)
        azzera_dao()
        self._env.stop()
        self._tmp.cleanup()

    def test_info_pubblica(self) -> None:
        """! @brief /api/v1/info espone versione, capacità e stato del DB."""
        info = self._client.get(f"{PREFISSO_API}/info").json()
        self.assertEqual(info["api"], "v1")
        self.assertEqual(info["database"], "in sviluppo")
        self.assertIn("veicoli", info["capacita"])
        self.assertFalse(info["esposto_in_rete"])  # loopback di default

    def test_salute_pubblica(self) -> None:
        """! @brief /api/v1/salute risponde ok con uptime e dispositivi."""
        s = self._client.get(f"{PREFISSO_API}/salute").json()
        self.assertEqual(s["stato"], "ok")
        self.assertIn("dispositivi", s)

    def test_login_in_sviluppo(self) -> None:
        """! @brief Con persistenza non configurata il login risponde 503 (contratto dio)."""
        resp = self._client.post(
            f"{PREFISSO_API}/auth/login",
            json={"identita": "ut@leaf.test", "password": "x"},
        )
        self.assertEqual(resp.status_code, 503)
        self.assertIn("sviluppo", resp.json()["detail"].lower())

    def test_login_validazione(self) -> None:
        """! @brief Un corpo non conforme allo schema è rifiutato dalla validazione (422)."""
        resp = self._client.post(
            f"{PREFISSO_API}/auth/login",
            json={"identita": "x", "password": ""},  # identita < 3, password vuota
        )
        self.assertEqual(resp.status_code, 422)

    def test_registrazione_in_sviluppo(self) -> None:
        """! @brief La registrazione UT risponde 503 quando la persistenza non è configurata."""
        resp = self._client.post(
            f"{PREFISSO_API}/auth/registrazione",
            json={"email": "nuovo@leaf.test", "username": "nuovo", "password": "Aa1!aa1!"},
        )
        self.assertEqual(resp.status_code, 503)

    def test_reset_sempre_positivo(self) -> None:
        """! @brief Il reset password risponde 503 in sviluppo (anti-enumerazione a DB cablato)."""
        resp = self._client.post(
            f"{PREFISSO_API}/auth/password/reset", json={"identita": "ut@leaf.test"}
        )
        self.assertEqual(resp.status_code, 503)

    def test_reset_conferma_password_debole(self) -> None:
        """! @brief La conferma reset valida IIN-5 prima del DB: password debole → 400."""
        resp = self._client.post(
            f"{PREFISSO_API}/auth/password/reset/conferma",
            json={"identita": "ut@leaf.test", "codice": "123456", "nuova_password": "deboleee"},
        )
        self.assertEqual(resp.status_code, 400)

    def test_reset_conferma_in_sviluppo(self) -> None:
        """! @brief La conferma reset con password valida risponde 503 senza persistenza."""
        resp = self._client.post(
            f"{PREFISSO_API}/auth/password/reset/conferma",
            json={"identita": "ut@leaf.test", "codice": "123456", "nuova_password": "Aa1!aa1!"},
        )
        self.assertEqual(resp.status_code, 503)

    def test_logout_idempotente(self) -> None:
        """! @brief Il logout è idempotente: risponde ok anche senza sessione attiva."""
        resp = self._client.post(f"{PREFISSO_API}/auth/logout")
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.json()["stato"], "ok")

    def test_dashboard_richiede_ruolo(self) -> None:
        """! @brief Gli endpoint OP/PA rifiutano l'accesso senza sessione (401)."""
        self.assertEqual(self._client.get(f"{PREFISSO_API}/flotta").status_code, 401)
        self.assertEqual(self._client.get(f"{PREFISSO_API}/analitiche").status_code, 401)

    def test_ricerca_percorsi_nelle_capacita(self) -> None:
        """! @brief /info espone le nuove capacità di ricerca percorsi (UT.07)."""
        info = self._client.get(f"{PREFISSO_API}/info").json()
        self.assertIn("geocoding", info["capacita"])
        self.assertIn("percorsi", info["capacita"])

    def test_ricerca_percorsi_richiede_sessione(self) -> None:
        """! @brief Geocoding e percorsi richiedono una sessione valida (401 senza token)."""
        self.assertEqual(self._client.get(f"{PREFISSO_API}/geocoding?q=bari").status_code, 401)
        self.assertEqual(
            self._client.get(f"{PREFISSO_API}/percorsi?da=Stazione&a=Teatro").status_code, 401
        )

    def test_corsa_richiede_sessione_valida(self) -> None:
        """! @brief L'avvio corsa senza Authorization è 401; con token non valido pure (401)."""
        senza = self._client.post(f"{PREFISSO_API}/corse", json={"id_mezzo": "BK-1"})
        self.assertEqual(senza.status_code, 401)
        # Un Bearer non risolvibile (nessuna sessione attiva) è rifiutato.
        con = self._client.post(
            f"{PREFISSO_API}/corse",
            json={"id_mezzo": "BK-1"},
            headers={"Authorization": "Bearer fittizio"},
        )
        self.assertEqual(con.status_code, 401)

    def test_cors_preflight(self) -> None:
        """! @brief Il preflight CORS è gestito (header Allow-Origin presente)."""
        resp = self._client.options(
            f"{PREFISSO_API}/veicoli",
            headers={
                "Origin": "https://dashboard.leaf.local",
                "Access-Control-Request-Method": "GET",
            },
        )
        self.assertIn("access-control-allow-origin", {k.lower() for k in resp.headers})

    def test_richieste_api_contano_come_dispositivi(self) -> None:
        """! @brief Le chiamate alla API pubblica incrementano i dispositivi collegati."""
        self._client.get(f"{PREFISSO_API}/info")
        snap = self._client.get("/__admin__/metriche").json()
        self.assertGreaterEqual(snap["dispositivi_collegati"], 1)

    def test_header_sicurezza_e_request_id(self) -> None:
        """! @brief Ogni risposta porta X-Request-ID e gli header di sicurezza."""
        resp = self._client.get(f"{PREFISSO_API}/info")
        self.assertTrue(resp.headers.get("x-request-id"))
        self.assertEqual(resp.headers.get("x-content-type-options"), "nosniff")
        self.assertEqual(resp.headers.get("x-frame-options"), "DENY")

    def test_request_id_propagato(self) -> None:
        """! @brief Un X-Request-ID fornito dal client viene propagato in risposta."""
        resp = self._client.get(f"{PREFISSO_API}/info", headers={"X-Request-ID": "corr-123"})
        self.assertEqual(resp.headers.get("x-request-id"), "corr-123")


class TestRateLimit(unittest.TestCase):
    """! @brief Verifica il rate limiting per host sugli endpoint pubblici."""

    def setUp(self) -> None:
        """! @brief App con limite basso (2/finestra) per provocare il 429."""
        self._tmp = tempfile.TemporaryDirectory()
        base = Path(self._tmp.name)
        imp = Impostazioni(
            dati_dir=base / "dati", backup_dir=base / "backups", rate_limit=2, rate_window_s=60
        )
        self._client = TestClient(crea_app(imp))
        self._client.__enter__()

    def tearDown(self) -> None:
        """! @brief Chiude il client e rimuove le cartelle temporanee."""
        self._client.__exit__(None, None, None)
        self._tmp.cleanup()

    def test_oltre_limite_429(self) -> None:
        """! @brief Oltre il limite la API pubblica risponde 429; /__admin__ è esente."""
        self.assertEqual(self._client.get(f"{PREFISSO_API}/info").status_code, 200)
        self.assertEqual(self._client.get(f"{PREFISSO_API}/info").status_code, 200)
        bloccata = self._client.get(f"{PREFISSO_API}/info")
        self.assertEqual(bloccata.status_code, 429)
        self.assertFalse(bloccata.json()["disponibile"])
        # L'endpoint di controllo loopback non è soggetto al rate limit.
        self.assertEqual(self._client.get("/__admin__/salute").status_code, 200)


if __name__ == "__main__":
    unittest.main()
