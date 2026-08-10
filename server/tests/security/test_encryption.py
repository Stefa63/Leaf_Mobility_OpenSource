"""! @file test_encryption.py
@brief Gate AG-SEC-02 (IIN-4): cifratura AES-256 dei campi 🔒 e dei documenti KYC a riposo.

Usa la cifratura **reale** @ref CifrarioAes256Gcm (non il cifrario di test): i campi
sensibili devono risultare cifrati nel documento a riposo (illeggibili in chiaro) e
tornare in chiaro solo in lettura tramite il @ref DataAccessManager. Verifica inoltre la
non-determinismo (nonce), il rilevamento di manomissioni (GCM) e il vincolo sulla chiave.
"""

from __future__ import annotations

import unittest

from server.integration_tier.data_access_manager import DataAccessManager
from server.integration_tier.data_access_manager import collezioni as col
from server.integration_tier.data_access_manager.cifratura import CifrarioAes256Gcm
from server.integration_tier.data_access_manager.cliente_falso import ClienteFalsoFirestore

#! Chiave AES-256 deterministica per i test (32 byte). In produzione viene da LEAF_AES_KEY.
_CHIAVE = b"leaf-mobility-test-key-32-bytes!"  # 31 char + '!' = 32 byte (vedi setUp)


class TestCifraturaCampiAtRest(unittest.TestCase):
    """! @brief AG-SEC-02: campi 🔒 e documenti KYC cifrati AES-256 a riposo (IIN-4)."""

    def setUp(self) -> None:
        """! @brief DAO su client fake con cifratura AES-256-GCM reale attiva."""
        self.assertEqual(len(_CHIAVE), 32)  # garanzia di chiave a 256 bit
        self._cliente = ClienteFalsoFirestore()
        self._dao = DataAccessManager(self._cliente, cifrario=CifrarioAes256Gcm(_CHIAVE))

    def _grezzo(self, collezione: str, id_doc: str) -> dict[str, object]:
        """! @brief Legge il documento così com'è memorizzato (bypassando la decifratura del DAO).
        @param collezione Collezione Firestore.
        @param id_doc Id del documento.
        @return Il dizionario grezzo a riposo.
        """
        snap = self._cliente.collection(collezione).document(id_doc).get().to_dict()
        assert snap is not None
        return snap

    def test_pii_utente_cifrata_a_riposo_e_decifrata_in_lettura(self) -> None:
        """! @brief I campi PII del profilo utente sono cifrati a riposo, in chiaro solo via DAO."""
        profilo = {
            "nome": "Giulia",
            "cognome": "Rossi",
            "codice_fiscale": "RSSGLI90A41A662S",
            "telefono": "+39 333 1234567",
            "indirizzo": "Via Sparano 1, Bari",
        }
        self._dao.crea_account("UT", "giulia@leaf.test", "hash", profilo=profilo, id_doc="u1")

        grezzo = self._grezzo(col.UTENTI, "u1")
        for campo, chiaro in profilo.items():
            with self.subTest(campo=campo):
                self.assertNotEqual(grezzo[campo], chiaro)  # cifrato a riposo
                self.assertNotIn(str(chiaro), str(grezzo[campo]))  # nessun residuo in chiaro

        riletto = self._dao.leggi(col.UTENTI, "u1")
        assert riletto is not None
        for campo, chiaro in profilo.items():
            with self.subTest(campo=campo):
                self.assertEqual(riletto[campo], chiaro)  # decifrato in lettura

    def test_documento_kyc_cifrato_a_riposo(self) -> None:
        """! @brief Numero documento e storage_path del KYC sono cifrati a riposo (IIN-4/IIN-6)."""
        self._dao.crea_account("UT", "marco@leaf.test", "hash", id_doc="u2")
        self._dao.crea(
            col.DOCUMENTI_UFFICIALI,
            {
                "id_utente": "u2",
                "tipo_documento": "patente",
                "numero_documento": "AB1234567",
                "storage_path": "gs://leaf-kyc/u2/patente.pdf",
                "stato_verifica": "in_attesa",
            },
            id_doc="d1",
        )

        grezzo = self._grezzo(col.DOCUMENTI_UFFICIALI, "d1")
        self.assertNotEqual(grezzo["numero_documento"], "AB1234567")
        self.assertNotEqual(grezzo["storage_path"], "gs://leaf-kyc/u2/patente.pdf")

        riletto = self._dao.leggi(col.DOCUMENTI_UFFICIALI, "d1")
        assert riletto is not None
        self.assertEqual(riletto["numero_documento"], "AB1234567")
        self.assertEqual(riletto["storage_path"], "gs://leaf-kyc/u2/patente.pdf")

    def test_cifratura_non_deterministica(self) -> None:
        """! @brief Lo stesso valore cifrato due volte produce token diversi (nonce casuale)."""
        cifrario = CifrarioAes256Gcm(_CHIAVE)
        self.assertNotEqual(cifrario.cifra("dato 🔒"), cifrario.cifra("dato 🔒"))
        # ma entrambi decifrano all'originale
        token = cifrario.cifra("dato 🔒")
        self.assertEqual(cifrario.decifra(token), "dato 🔒")

    def test_gcm_rileva_manomissione(self) -> None:
        """! @brief AES-GCM rileva la manomissione del ciphertext (autenticità)."""
        cifrario = CifrarioAes256Gcm(_CHIAVE)
        from cryptography.exceptions import InvalidTag

        token = cifrario.cifra("integro")
        manomesso = ("A" if token[0] != "A" else "B") + token[1:]
        with self.assertRaises(InvalidTag):  # GCM rileva il ciphertext manomesso
            cifrario.decifra(manomesso)

    def test_chiave_di_lunghezza_errata_rifiutata(self) -> None:
        """! @brief Una chiave non di 32 byte non è ammessa (AES-256)."""
        with self.assertRaises(ValueError):
            CifrarioAes256Gcm(b"troppo-corta")


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
