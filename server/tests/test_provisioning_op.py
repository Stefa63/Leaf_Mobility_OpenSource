"""! @file test_provisioning_op.py
@brief Test del provisioning OP (locale e su Firestore).
"""

from __future__ import annotations

import re
import tempfile
import unittest
from pathlib import Path

from server.integration_tier.data_access_manager import (
    DataAccessManager,
    ViolazioneUnicita,
    azzera_dao,
    imposta_dao,
)
from server.integration_tier.data_access_manager.cliente_falso import ClienteFalsoFirestore
from server.runtime.provisioning_op import ProvisioningOP


class TestProvisioningOP(unittest.TestCase):
    """! @brief Verifica policy password, creazione e unicita' degli account OP."""

    def setUp(self) -> None:
        """! @brief Crea uno store temporaneo."""
        self._tmp = tempfile.TemporaryDirectory()
        self._store = Path(self._tmp.name) / "op_store.json"

    def tearDown(self) -> None:
        """! @brief Rimuove lo store temporaneo."""
        self._tmp.cleanup()

    def test_password_conforme_iin5(self) -> None:
        """! @brief La password temporanea rispetta IIN-5 (>=8, maiuscola, cifra, speciale)."""
        pwd = ProvisioningOP.genera_password_temporanea()
        self.assertGreaterEqual(len(pwd), 8)
        self.assertTrue(re.search(r"[A-Z]", pwd))
        self.assertTrue(re.search(r"[0-9]", pwd))
        self.assertTrue(re.search(r"[^A-Za-z0-9]", pwd))

    def test_crea_e_elenca(self) -> None:
        """! @brief La creazione restituisce una password e marca il cambio obbligatorio."""
        p = ProvisioningOP(self._store)
        temporanea = p.crea_op("op_mario")
        self.assertTrue(temporanea)
        self.assertTrue(p.esiste("op_mario"))
        elenco = p.elenco()
        self.assertEqual(elenco[0]["username"], "op_mario")
        self.assertTrue(elenco[0]["deve_cambiare_password"])

    def test_duplicato_rifiutato(self) -> None:
        """! @brief Creare due volte lo stesso username solleva ValueError."""
        p = ProvisioningOP(self._store)
        p.crea_op("op_dup")
        with self.assertRaises(ValueError):
            p.crea_op("op_dup")

    def test_hash_non_in_chiaro(self) -> None:
        """! @brief Lo store non contiene la password in chiaro (§7.3)."""
        p = ProvisioningOP(self._store)
        temporanea = p.crea_op("op_secret")
        contenuto = self._store.read_text(encoding="utf-8")
        self.assertNotIn(temporanea, contenuto)
        self.assertIn("hash_password", contenuto)


class TestProvisioningOPFirestore(unittest.TestCase):
    """! @brief Creazione OP reale su Firestore: nome/email, unicita', login post-creazione."""

    def setUp(self) -> None:
        """! @brief Inietta un DAO su client fake."""
        self._dao = DataAccessManager(ClienteFalsoFirestore())
        imposta_dao(self._dao)

    def tearDown(self) -> None:
        """! @brief Azzera l'iniezione del DAO."""
        azzera_dao()

    def test_crea_op_firestore(self) -> None:
        """! @brief Creazione OP salva nome, email, password hash su Firestore."""
        from server.business_tier.gestore_profili_ekyc import GestoreProfiliEkyc

        profili = GestoreProfiliEkyc()
        esito = profili.provisiona_operatore("op.test@leaf.test", "op_test", "Mario Rossi")
        self.assertIn("id_account", esito)
        self.assertEqual(esito["email"], "op.test@leaf.test")
        self.assertEqual(esito["nome"], "Mario Rossi")
        self.assertTrue(esito["password_temporanea"])
        self.assertGreaterEqual(len(esito["password_temporanea"]), 8)

    def test_unicita_email_op(self) -> None:
        """! @brief Email duplicata solleva ViolazioneUnicita."""
        from server.business_tier.gestore_profili_ekyc import GestoreProfiliEkyc

        profili = GestoreProfiliEkyc()
        profili.provisiona_operatore("dup@leaf.test", "op_primo", "Primo")
        with self.assertRaises(ViolazioneUnicita):
            profili.provisiona_operatore("dup@leaf.test", "op_secondo", "Secondo")

    def test_login_dopo_creazione(self) -> None:
        """! @brief Login con le credenziali temporanee riesce dopo la creazione."""
        from server.business_tier.gestore_profili_ekyc import GestoreProfiliEkyc

        profili = GestoreProfiliEkyc()
        esito = profili.provisiona_operatore("login.op@leaf.test", "op_login", "Login Test")
        auth = profili.autentica("login.op@leaf.test", esito["password_temporanea"])
        self.assertTrue(auth.get("autenticato"))
        self.assertEqual(auth.get("ruolo"), "OP")
        self.assertTrue(auth.get("mfaRichiesto"))

    def test_account_op_ha_flag_password_temporanea(self) -> None:
        """! @brief L'account OP creato ha il flag password_temporanea=True (IIN-12)."""
        from server.business_tier.gestore_profili_ekyc import GestoreProfiliEkyc
        from server.integration_tier.data_access_manager import collezioni as col

        profili = GestoreProfiliEkyc()
        esito = profili.provisiona_operatore("flag.op@leaf.test", "op_flag", "Flag Test")
        account = self._dao.leggi(col.ACCOUNT, esito["id_account"])
        self.assertIsNotNone(account)
        assert account is not None  # narrowing per mypy --strict (dopo assertIsNotNone)
        self.assertTrue(account["password_temporanea"])


if __name__ == "__main__":
    unittest.main()
