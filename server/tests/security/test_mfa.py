"""! @file test_mfa.py
@brief Gate AG-SEC-03 (IIN-9): MFA obbligatorio per OP/PA — login impossibile senza OTP valido.

Verifica che @ref ApiGatewaySicurezza apra per OP/PA una sessione MFA **senza** emettere
il token finché l'OTP non è verificato, che l'OTP errato non emetta token, che la sessione
MFA sia a uso singolo, e che l'utente UT (senza obbligo MFA) riceva invece il token diretto.
"""

from __future__ import annotations

import unittest

from passlib.context import CryptContext

from server.integration_tier.data_access_manager import (
    DataAccessManager,
    azzera_dao,
    imposta_dao,
)
from server.integration_tier.data_access_manager.cliente_falso import ClienteFalsoFirestore
from server.presentation_tier.api_gateway_sicurezza import ApiGatewaySicurezza

#! Stesso schema Passlib del DataAccessManager: produce hash verificabili da verifica_credenziali.
_PW = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")
_PASSWORD = "Segreta!123"


def _otp_diverso(otp: str) -> str:
    """! @brief Restituisce un OTP a 6 cifre sicuramente diverso da quello dato.
    @param otp OTP corretto (6 cifre).
    @return Un OTP errato deterministico.
    """
    return "000000" if otp != "000000" else "111111"


class TestMfaEnforcement(unittest.TestCase):
    """! @brief AG-SEC-03: enforcement del secondo fattore per OP/PA (IIN-9)."""

    def setUp(self) -> None:
        """! @brief DAO fake con un OP, un PA e un UT; gateway che lo risolve dall'ambiente."""
        self._dao = DataAccessManager(ClienteFalsoFirestore())
        self._dao.crea_account("OP", "op@leaf.test", _PW.hash(_PASSWORD), id_doc="op1")
        self._dao.crea_account("PA", "pa@leaf.test", _PW.hash(_PASSWORD), id_doc="pa1")
        self._dao.crea_account("UT", "ut@leaf.test", _PW.hash(_PASSWORD), id_doc="ut1")
        imposta_dao(self._dao)
        self._gw = ApiGatewaySicurezza()

    def tearDown(self) -> None:
        """! @brief Rimuove il DAO iniettato per non contaminare altri test."""
        azzera_dao()

    def test_op_login_apre_sessione_mfa_senza_token(self) -> None:
        """! @brief Il login OP con credenziali valide NON emette token: apre la sessione MFA."""
        esito = self._gw.autentica("op@leaf.test", _PASSWORD)
        self.assertTrue(esito.get("autenticato"))
        self.assertTrue(esito.get("mfaRichiesto"))
        self.assertIn("sessione", esito)
        self.assertNotIn("token", esito)  # nessun accesso prima dell'OTP

    def test_pa_login_apre_sessione_mfa_senza_token(self) -> None:
        """! @brief Anche la PA è soggetta a MFA obbligatorio (IIN-9)."""
        esito = self._gw.autentica("pa@leaf.test", _PASSWORD)
        self.assertTrue(esito.get("mfaRichiesto"))
        self.assertIn("sessione", esito)
        self.assertNotIn("token", esito)

    def test_token_emesso_solo_dopo_otp_valido(self) -> None:
        """! @brief Il token di sessione OP arriva solo dopo la verifica dell'OTP corretto."""
        esito = self._gw.autentica("op@leaf.test", _PASSWORD)
        sessione = str(esito["sessione"])
        otp = str(esito["otp_simulato"])

        # OTP errato: nessun token.
        ko = self._gw.verifica_mfa(sessione, _otp_diverso(otp))
        self.assertFalse(ko.get("valido"))
        self.assertNotIn("token", ko)

        # OTP corretto: token emesso e risolvibile come sessione OP.
        ok = self._gw.verifica_mfa(sessione, otp)
        self.assertTrue(ok.get("valido"))
        token = str(ok["token"])
        sessione_attiva = self._gw.risolvi_sessione(token)
        assert sessione_attiva is not None
        self.assertEqual(sessione_attiva["ruolo"], "OP")

    def test_sessione_mfa_a_uso_singolo(self) -> None:
        """! @brief Una sessione MFA già consumata non può emettere un secondo token."""
        esito = self._gw.autentica("op@leaf.test", _PASSWORD)
        sessione = str(esito["sessione"])
        otp = str(esito["otp_simulato"])
        self.assertTrue(self._gw.verifica_mfa(sessione, otp).get("valido"))
        # Riuso della stessa sessione: rifiutato.
        self.assertFalse(self._gw.verifica_mfa(sessione, otp).get("valido"))

    def test_otp_errato_non_emette_token(self) -> None:
        """! @brief Un OTP errato non produce alcun token (login OP impossibile)."""
        esito = self._gw.autentica("op@leaf.test", _PASSWORD)
        sessione = str(esito["sessione"])
        otp = str(esito["otp_simulato"])
        ko = self._gw.verifica_mfa(sessione, _otp_diverso(otp))
        self.assertFalse(ko.get("valido"))

    def test_credenziali_errate_non_aprono_mfa(self) -> None:
        """! @brief Password errata: nessuna autenticazione e nessuna sessione MFA."""
        esito = self._gw.autentica("op@leaf.test", "password-sbagliata")
        self.assertFalse(esito.get("autenticato"))
        self.assertNotIn("sessione", esito)
        self.assertNotIn("token", esito)

    def test_ut_riceve_token_diretto_senza_mfa(self) -> None:
        """! @brief L'utente finale (UT) non è soggetto a MFA: token diretto, nessuna sessione."""
        esito = self._gw.autentica("ut@leaf.test", _PASSWORD)
        self.assertTrue(esito.get("autenticato"))
        self.assertFalse(esito.get("mfaRichiesto"))
        self.assertIn("token", esito)
        self.assertNotIn("sessione", esito)


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
