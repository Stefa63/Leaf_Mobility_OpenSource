"""! @file test_kyc_format.py
@brief Gate AG-SEC-01 (IIN-6): validazione server-side dei formati documentali KYC.

Verifica che @ref GestoreProfiliEkyc.formato_kyc_valido accetti **solo** PDF/JPG/PNG e
blocchi qualsiasi altra estensione (incluse quelle ingannevoli a doppia estensione),
indipendentemente da maiuscole/minuscole e dalla presenza di un percorso nel nome.
"""

from __future__ import annotations

import unittest

from server.business_tier.gestore_profili_ekyc import FORMATI_KYC_AMMESSI, GestoreProfiliEkyc


class TestKycFormatValidation(unittest.TestCase):
    """! @brief AG-SEC-01: solo PDF/JPG/PNG ammessi per i documenti KYC (IIN-6)."""

    def setUp(self) -> None:
        """! @brief Gestore eKYC senza DAO (la validazione di formato è pura, no persistenza)."""
        self._ekyc = GestoreProfiliEkyc()

    def test_accetta_formati_ammessi(self) -> None:
        """! @brief PDF/JPG/JPEG/PNG sono accettati, anche con percorso e maiuscole."""
        for nome in (
            "patente.pdf",
            "fronte.jpg",
            "retro.jpeg",
            "selfie.png",
            "DOCUMENTO.PDF",
            "Carta.Jpg",
            "/tmp/upload/identita.PNG",
            "C:\\Users\\x\\carta identita.jpeg",
        ):
            with self.subTest(nome=nome):
                self.assertTrue(self._ekyc.formato_kyc_valido(nome))

    def test_rifiuta_estensioni_non_ammesse(self) -> None:
        """! @brief Eseguibili, archivi, documenti office e immagini non ammesse sono bloccati."""
        for nome in (
            "malware.exe",
            "script.sh",
            "vettore.svg",
            "animazione.gif",
            "foto.heic",
            "note.txt",
            "contratto.docx",
            "archivio.zip",
            "payload.bat",
        ):
            with self.subTest(nome=nome):
                self.assertFalse(self._ekyc.formato_kyc_valido(nome))

    def test_rifiuta_doppia_estensione_ingannevole(self) -> None:
        """! @brief Un nome che maschera un eseguibile dietro un'estensione lecita è bloccato."""
        self.assertFalse(self._ekyc.formato_kyc_valido("documento.pdf.exe"))
        self.assertFalse(self._ekyc.formato_kyc_valido("immagine.png.js"))

    def test_rifiuta_senza_estensione_o_vuoto(self) -> None:
        """! @brief Nessuna estensione o nome vuoto non è un formato ammesso."""
        for nome in ("documento", "", "pdf", ".", "archivio."):
            with self.subTest(nome=nome):
                self.assertFalse(self._ekyc.formato_kyc_valido(nome))

    def test_insieme_formati_ammessi_e_il_canone(self) -> None:
        """! @brief L'allowlist coincide esattamente con il canone IIN-6 (PDF/JPG/JPEG/PNG)."""
        self.assertEqual(FORMATI_KYC_AMMESSI, frozenset({".pdf", ".jpg", ".jpeg", ".png"}))


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
