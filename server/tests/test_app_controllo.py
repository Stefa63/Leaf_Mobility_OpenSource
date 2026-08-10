"""! @file test_app_controllo.py
@brief Test end-to-end degli endpoint di controllo (richiede fastapi/psutil/passlib).
"""

from __future__ import annotations

import tempfile
import unittest
import uuid
from pathlib import Path

from fastapi.testclient import TestClient

from server.runtime.app_factory import crea_app
from server.runtime.controllo_router import PREFISSO
from server.runtime.impostazioni import Impostazioni


class TestAppControllo(unittest.TestCase):
    """! @brief Verifica metriche, hardware, provisioning, query e backup via HTTP."""

    def setUp(self) -> None:
        """! @brief Costruisce un'app con cartelle dati temporanee e ne apre il client."""
        self._tmp = tempfile.TemporaryDirectory()
        base = Path(self._tmp.name)
        self._imp = Impostazioni(dati_dir=base / "dati", backup_dir=base / "backups")
        self._client = TestClient(crea_app(self._imp))
        self._client.__enter__()  # innesca il lifespan (PID, backup auto)

    def tearDown(self) -> None:
        """! @brief Chiude il client e rimuove le cartelle temporanee."""
        self._client.__exit__(None, None, None)
        self._tmp.cleanup()

    def test_salute_e_metriche(self) -> None:
        """! @brief Health check e metriche rispondono con la struttura attesa."""
        self.assertEqual(self._client.get(f"{PREFISSO}/salute").json()["stato"], "ok")
        snap = self._client.get(f"{PREFISSO}/metriche").json()
        for chiave in ("byte_in", "byte_out", "richieste_totali", "tempo_risposta_medio_ms"):
            self.assertIn(chiave, snap)

    def test_hardware(self) -> None:
        """! @brief L'endpoint hardware espone CPU/RAM e le soglie."""
        hw = self._client.get(f"{PREFISSO}/hardware").json()
        self.assertIn("cpu_sistema_pct", hw)
        self.assertIn("soglia_cpu", hw)

    def test_crea_op_e_duplicato(self) -> None:
        """! @brief La creazione OP restituisce la password; il duplicato e' 409."""
        # Username/email univoci per test: evita il leak di stato verso una
        # persistenza condivisa (Firestore reale/emulatore) che renderebbe la
        # prima creazione gia' duplicata (409) tra run successive.
        username = f"op_test_{uuid.uuid4().hex[:8]}"
        email = f"{username}@leaf.test"
        corpo = {"username": username, "nome": "Test OP", "email": email}
        resp = self._client.post(f"{PREFISSO}/op", json=corpo)
        self.assertEqual(resp.status_code, 200)
        creato = resp.json()
        self.assertTrue(creato["password_temporanea"])
        self.assertTrue(creato["deve_cambiare_password"])
        dup = self._client.post(f"{PREFISSO}/op", json=corpo)
        self.assertEqual(dup.status_code, 409)
        # GET /op riflette solo lo store locale provvisorio: l'OP vi compare
        # esclusivamente quando la persistenza e' locale (non Firestore).
        if creato.get("persistenza") == "locale":
            elenco = self._client.get(f"{PREFISSO}/op").json()["op"]
            self.assertTrue(any(v["username"] == username for v in elenco))

    def test_query_db_in_sviluppo(self) -> None:
        """! @brief L'interrogazione e' tracciata ma non eseguibile (DB in sviluppo)."""
        resp = self._client.post(f"{PREFISSO}/query", json={"sql": "SELECT 1"})
        self.assertEqual(resp.status_code, 200)
        self.assertFalse(resp.json()["disponibile"])

    def test_backup_manuale(self) -> None:
        """! @brief Un backup manuale crea un archivio elencabile."""
        meta = self._client.post(f"{PREFISSO}/backup").json()
        self.assertTrue(str(meta["nome"]).startswith("backup_"))
        archivi = self._client.get(f"{PREFISSO}/backup").json()["archivi"]
        self.assertGreaterEqual(len(archivi), 1)

    def test_audit_registra_azioni(self) -> None:
        """! @brief Le azioni operative compaiono nel log di audit (IIN-13)."""
        self._client.post(
            f"{PREFISSO}/op",
            json={"username": "op_audit", "nome": "Audit OP", "email": "op.audit@leaf.test"},
        )
        voci = self._client.get(f"{PREFISSO}/audit", params={"n": 10}).json()["voci"]
        self.assertTrue(any(v["azione"] == "op_create" for v in voci))

    def test_dispositivi_collegati(self) -> None:
        """! @brief Le metriche espongono il numero di dispositivi client collegati."""
        snap = self._client.get(f"{PREFISSO}/metriche").json()
        self.assertIn("dispositivi_collegati", snap)
        self.assertGreaterEqual(snap["dispositivi_collegati"], 1)
        self.assertGreaterEqual(snap["picco_dispositivi"], 1)

    def test_config_lettura_e_aggiornamento(self) -> None:
        """! @brief /config legge e aggiorna a caldo le impostazioni, persistendole."""
        attuale = self._client.get(f"{PREFISSO}/config").json()
        self.assertIn("backup_intervallo_s", attuale)
        aggiornata = self._client.post(
            f"{PREFISSO}/config",
            json={"backup_intervallo_s": 120, "backup_auto": True, "soglia_cpu": 70},
        ).json()
        self.assertEqual(aggiornata["backup_intervallo_s"], 120)
        self.assertTrue(aggiornata["backup_auto"])
        self.assertEqual(aggiornata["soglia_cpu"], 70.0)
        # La soglia aggiornata si riflette nello snapshot hardware.
        hw = self._client.get(f"{PREFISSO}/hardware").json()
        self.assertEqual(hw["soglia_cpu"], 70.0)

    def test_config_persistita_su_disco(self) -> None:
        """! @brief Le impostazioni modificate sono scritte in config.json (sopravvivono)."""
        self._client.post(f"{PREFISSO}/config", json={"backup_retention": 3})
        cfg = self._imp.file_config
        self.assertTrue(cfg.is_file())
        self.assertIn("backup_retention", cfg.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
