"""! @file test_email_transazionali.py
@brief Test delle email transazionali automatiche â€” OFFLINE, client e SMTP fittizi.

Verificano che il ciclo prenotazione/corsa (@ref GestoreCorse) e il login UT
(@ref GestoreProfiliEkyc) inneschino l'invio dell'email all'indirizzo registrato
dell'utente, senza alcuna rete reale: il @ref GatewayEmail Ã¨ sostituito da un finto
che registra gli invii, e la persistenza Ã¨ un @ref DataAccessManager su
@ref ClienteFalsoFirestore (testabilitÃ  Â§12.2). Gli invii restano best-effort: il
fallimento non deve alterare l'esito di dominio (coperto altrove, qui si verifica
solo l'aggancio).
"""

from __future__ import annotations

import unittest

from server.business_tier.gestore_corse import GestoreCorse
from server.business_tier.gestore_profili_ekyc import GestoreProfiliEkyc
from server.integration_tier.data_access_manager import DataAccessManager
from server.integration_tier.data_access_manager.cliente_falso import ClienteFalsoFirestore
from server.integration_tier.gateway_email import GatewayEmail


class EmailFinta(GatewayEmail):
    """! @brief Gateway email finto: configurato e con invio registrato in memoria.

    Eredita da @ref GatewayEmail per restare type-compatibile (mypy --strict): Ã¨
    `configurato` (mittente/password valorizzati) ma sovrascrive @ref invia per
    registrare l'invio senza aprire alcuna connessione SMTP reale.
    """

    def __init__(self) -> None:
        """! @brief Costruisce il finto con credenziali fittizie e lista invii vuota."""
        super().__init__(mittente="support@leafmobility.example.com", password="segreto-finto")
        #! Invii registrati: (destinatario, oggetto, corpo).
        self.inviate: list[tuple[str, str, str]] = []

    def invia(self, destinatario: str, oggetto: str, corpo: str) -> bool:
        """! @brief Registra l'invio in memoria (nessuna rete) e ritorna sempre True.
        @param destinatario Indirizzo email del destinatario.
        @param oggetto Oggetto del messaggio.
        @param corpo Corpo testuale del messaggio.
        @return True (invio sempre "riuscito" nel finto).
        """
        self.inviate.append((destinatario, oggetto, corpo))
        return True


class TestEmailCorse(unittest.TestCase):
    """! @brief Email automatiche su prenotazione, avvio, termine e annullo corsa."""

    def setUp(self) -> None:
        """! @brief DAO finto con un utente UT e un'ebike disponibile, email finta iniettata."""
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
        self._email = EmailFinta()
        self._corse = GestoreCorse(self._dao, email=self._email)

    def test_email_inizio_prenotazione(self) -> None:
        """! @brief UT.02: prenotare un mezzo invia l'email di conferma all'utente."""
        self._corse.prenota("u1", "M1")
        self.assertEqual(len(self._email.inviate), 1)
        destinatario, oggetto, _ = self._email.inviate[0]
        self.assertEqual(destinatario, "u@leaf.test")
        self.assertIn("Prenotazione confermata", oggetto)

    def test_email_fine_prenotazione(self) -> None:
        """! @brief UT.12: annullare la prenotazione invia l'email di annullamento."""
        id_pren = self._corse.prenota("u1", "M1")
        self._email.inviate.clear()  # isola l'email di annullo da quella di conferma
        self._corse.annulla_prenotazione(id_pren, "u1")
        self.assertEqual(len(self._email.inviate), 1)
        _, oggetto, _ = self._email.inviate[0]
        self.assertIn("Prenotazione annullata", oggetto)

    def test_email_inizio_noleggio(self) -> None:
        """! @brief UT.10: avviare la corsa invia l'email di inizio noleggio."""
        self._corse.avvia("u1", "M1")
        self.assertEqual(len(self._email.inviate), 1)
        destinatario, oggetto, _ = self._email.inviate[0]
        self.assertEqual(destinatario, "u@leaf.test")
        self.assertIn("Noleggio iniziato", oggetto)

    def test_email_fine_noleggio(self) -> None:
        """! @brief UT.04: terminare la corsa invia l'email di fine noleggio."""
        avvio = self._corse.avvia("u1", "M1")
        self._email.inviate.clear()  # isola l'email di termine da quella di inizio
        self._corse.termina(str(avvio["id_corsa"]), km_percorsi=2.5)
        oggetti = [o for _, o, _ in self._email.inviate]
        self.assertTrue(any("Noleggio terminato" in o for o in oggetti))

    def test_email_disattivata_nessun_invio(self) -> None:
        """! @brief Gateway non configurato: nessun invio, l'operazione di dominio riesce."""
        corse = GestoreCorse(self._dao, email=GatewayEmail(mittente="", password=""))
        id_pren = corse.prenota("u1", "M1")  # non deve sollevare
        self.assertTrue(id_pren)


class TestEmailLoginUtente(unittest.TestCase):
    """! @brief Email di avviso "nuovo accesso" sul login UT riuscito (IIN-13)."""

    def test_email_accesso_account(self) -> None:
        """! @brief Un login UT corretto invia l'email di nuovo accesso all'utente."""
        dao = DataAccessManager(ClienteFalsoFirestore())
        email = EmailFinta()
        profili = GestoreProfiliEkyc(dao, email=email)
        profili.registra("nuovo@leaf.test", "nuovo.utente", "Leaf!2026")
        email.inviate.clear()  # isola l'email di accesso da eventuali invii di registrazione

        esito = profili.autentica("nuovo@leaf.test", "Leaf!2026")
        self.assertTrue(esito["autenticato"])
        oggetti = [o for _, o, _ in email.inviate]
        self.assertTrue(any("Nuovo accesso" in o for o in oggetti))
        self.assertTrue(all(d == "nuovo@leaf.test" for d, _, _ in email.inviate))


if __name__ == "__main__":  # pragma: no cover - esecuzione diretta del modulo di test
    unittest.main()
