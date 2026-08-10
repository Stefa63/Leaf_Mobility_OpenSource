"""! @file test_e2e_blocco1.py
@brief E2E dei flussi del Blocco 1 (gestione OP/PA) su HTTP — Cascata D, Parte 1.

Copre i nuovi endpoint cablati nel Blocco 1 attraverso l'intero stack ASGI
(middleware sicurezza, gateway, business, integration), OFFLINE su
@ref ClienteFalsoFirestore popolato dal seed (testabilità §12.2):
- Gestione utenti/AP: elenco, sospensione/sblocco (OP.10/OP.18), provisioning PA (OP.17);
- Ticket di manutenzione: creazione, elenco, tecnici, assegnazione, chiusura (OP.16/OP.19);
- Promozioni/incentivi geografici: creazione, elenco, disattivazione (OP.09/OP.15);
- Grandi eventi cittadini: creazione ed elenco (AP.09);
- Sicurezza al confine HTTP: RBAC (IIN-5) sugli endpoint riservati.
"""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from fastapi.testclient import TestClient

from server.integration_tier.data_access_manager import (
    DataAccessManager,
    azzera_dao,
    imposta_dao,
)
from server.integration_tier.data_access_manager.bootstrap_seed import PASSWORD_DEMO, esegui_seed
from server.integration_tier.data_access_manager.cliente_falso import ClienteFalsoFirestore
from server.presentation_tier.api_pubblica import PREFISSO_API
from server.runtime.app_factory import crea_app
from server.runtime.impostazioni import Impostazioni


class TestE2EBlocco1(unittest.TestCase):
    """! @brief E2E dei flussi gestionali OP/PA del Blocco 1 su HTTP."""

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

    # ── Helper di autenticazione ──────────────────────────────────────────────
    def _token_ut(
        self, identita: str = "utente.demo@leaf.test", password: str = PASSWORD_DEMO
    ) -> str:
        """! @brief Login UT → token di sessione (Bearer)."""
        corpo = self._client.post(
            f"{PREFISSO_API}/auth/login",
            json={"identita": identita, "password": password},
        ).json()
        return str(corpo["access_token"])

    def _token_mfa(self, identita: str, password: str = PASSWORD_DEMO) -> str:
        """! @brief Login OP/PA + verifica MFA (IIN-9) → token di sessione."""
        login = self._client.post(
            f"{PREFISSO_API}/auth/login",
            json={"identita": identita, "password": password},
        ).json()
        self.assertEqual(login["stato"], "mfa_richiesta")
        corpo = self._client.post(
            f"{PREFISSO_API}/auth/mfa",
            json={"id_account": login["id_account"], "otp": login["otp_simulato"]},
        ).json()
        return str(corpo["access_token"])

    @staticmethod
    def _bearer(token: str) -> dict[str, str]:
        """! @brief Header Authorization Bearer dal token dato."""
        return {"Authorization": f"Bearer {token}"}

    def _op(self) -> dict[str, str]:
        """! @brief Header Bearer di un operatore autenticato (MFA)."""
        return self._bearer(self._token_mfa("operatore.demo@leaf.test"))

    def _pa(self) -> dict[str, str]:
        """! @brief Header Bearer di un'amministrazione pubblica autenticata (MFA)."""
        return self._bearer(self._token_mfa("pa.demo@leaf.test"))

    # ── ① Gestione utenti/AP (OP.10/OP.17/OP.18) ──────────────────────────────
    def test_elenco_utenti_op(self) -> None:
        """! @brief OP elenca gli account filtrando per ruolo; nessun campo segreto (OP.10)."""
        op = self._op()
        risp = self._client.get(f"{PREFISSO_API}/utenti", params={"ruolo": "UT"}, headers=op).json()
        self.assertTrue(risp["disponibile"])
        self.assertGreaterEqual(risp["dati"]["totale"], 1)
        for account in risp["dati"]["account"]:
            self.assertEqual(account["ruolo"], "UT")
            self.assertNotIn("password_hash", account)

    def test_sospendi_e_sblocca_utente(self) -> None:
        """! @brief OP sospende un UT (login negato 403) e poi lo sblocca (OP.10/OP.18)."""
        op = self._op()
        sosp = self._client.put(
            f"{PREFISSO_API}/utenti/ut-demo/stato", json={"stato": "sospeso"}, headers=op
        ).json()
        self.assertEqual(sosp["dati"]["account"]["stato_account"], "sospeso")
        # L'utente sospeso non può più autenticarsi (OP.10 → 403).
        negato = self._client.post(
            f"{PREFISSO_API}/auth/login",
            json={"identita": "utente.demo@leaf.test", "password": PASSWORD_DEMO},
        )
        self.assertEqual(negato.status_code, 403)
        # Sblocco (OP.18): l'accesso torna possibile.
        self._client.put(
            f"{PREFISSO_API}/utenti/ut-demo/stato", json={"stato": "attivo"}, headers=op
        )
        ok = self._client.post(
            f"{PREFISSO_API}/auth/login",
            json={"identita": "utente.demo@leaf.test", "password": PASSWORD_DEMO},
        )
        self.assertEqual(ok.status_code, 200)

    def test_elenco_amministrazioni_op(self) -> None:
        """! @brief OP elenca le PA provvisionate; solo ruolo PA, nessun campo segreto (OP.17)."""
        op = self._op()
        # Provisiona una PA per garantire almeno un elemento in elenco.
        self._client.post(
            f"{PREFISSO_API}/amministrazioni",
            json={
                "email": "elenco.pa@comune.test",
                "username": "pa.elenco",
                "ente": "Comune di Zootropolis",
                "email_istituzionale": "elenco@comune.test",
            },
            headers=op,
        )
        risp = self._client.get(f"{PREFISSO_API}/amministrazioni", headers=op).json()
        self.assertTrue(risp["disponibile"])
        self.assertGreaterEqual(risp["dati"]["totale"], 1)
        for account in risp["dati"]["account"]:
            self.assertEqual(account["ruolo"], "PA")
            self.assertNotIn("password_hash", account)

    def test_amministrazioni_riservato_op(self) -> None:
        """! @brief L'elenco PA è riservato a OP: UT riceve 403 (RBAC IIN-5)."""
        ut = self._bearer(self._token_ut())
        risp = self._client.get(f"{PREFISSO_API}/amministrazioni", headers=ut)
        self.assertEqual(risp.status_code, 403)

    def test_primo_accesso_pa(self) -> None:
        """! @brief PA provisionata cambia la password temporanea al 1° accesso (OP.17/IIN-12)."""
        op = self._op()
        creazione = self._client.post(
            f"{PREFISSO_API}/amministrazioni",
            json={
                "email": "primo.pa@comune.test",
                "username": "pa.primo",
                "ente": "Comune di Zootropolis",
                "email_istituzionale": "primo@comune.test",
            },
            headers=op,
        ).json()
        temporanea = creazione["dati"]["password_temporanea"]
        token = self._token_mfa("primo.pa@comune.test", password=temporanea)

        nuova = "NuovaScelta1!"
        cambio = self._client.post(
            f"{PREFISSO_API}/auth/password/primo-accesso",
            json={"nuova_password": nuova},
            headers=self._bearer(token),
        )
        self.assertEqual(cambio.status_code, 200)
        # La nuova password consente l'accesso (la temporanea è superata).
        self.assertTrue(self._token_mfa("primo.pa@comune.test", password=nuova))

    def test_primo_accesso_password_debole(self) -> None:
        """! @brief Una nuova password non conforme a IIN-5 è respinta (400)."""
        token = self._token_mfa("pa.demo@leaf.test")
        risp = self._client.post(
            f"{PREFISSO_API}/auth/password/primo-accesso",
            json={"nuova_password": "debole12"},
            headers=self._bearer(token),
        )
        self.assertEqual(risp.status_code, 400)

    def test_provisioning_pa(self) -> None:
        """! @brief OP provisiona un account PA con password temporanea valida (OP.17/IIN-12)."""
        op = self._op()
        creazione = self._client.post(
            f"{PREFISSO_API}/amministrazioni",
            json={
                "email": "nuova.pa@comune.test",
                "username": "pa.nuova",
                "ente": "Comune di Zootropolis",
                "email_istituzionale": "mobilita2@comune.test",
            },
            headers=op,
        )
        self.assertEqual(creazione.status_code, 201)
        dati = creazione.json()["dati"]
        self.assertTrue(dati["id_account"])
        temporanea = dati["password_temporanea"]
        # La PA appena creata può autenticarsi (MFA obbligatorio) con la temporanea.
        token = self._token_mfa("nuova.pa@comune.test", password=temporanea)
        self.assertTrue(token)

    def test_utenti_riservato_op(self) -> None:
        """! @brief La gestione utenti è riservata a OP: UT riceve 403 (RBAC IIN-5)."""
        ut = self._bearer(self._token_ut())
        self.assertEqual(self._client.get(f"{PREFISSO_API}/utenti", headers=ut).status_code, 403)

    # ── ② Ticket di manutenzione (OP.16/OP.19) ────────────────────────────────
    def test_ciclo_manutenzione(self) -> None:
        """! @brief OP crea, elenca, assegna a un tecnico e chiude un ticket (OP.16/OP.19)."""
        op = self._op()
        creato = self._client.post(
            f"{PREFISSO_API}/manutenzione",
            json={
                "id_mezzo": "SC-021",
                "descrizione": "Freno posteriore allentato",
                "priorita": "alta",
            },
            headers=op,
        )
        self.assertEqual(creato.status_code, 201)
        id_ticket = creato.json()["dati"]["id_ticket"]

        coda = self._client.get(f"{PREFISSO_API}/manutenzione", headers=op).json()
        self.assertTrue(any(t["_id"] == id_ticket for t in coda["dati"]["ticket"]))

        tecnici = self._client.get(f"{PREFISSO_API}/tecnici", headers=op).json()
        self.assertGreaterEqual(tecnici["dati"]["totale"], 2)
        id_tecnico = tecnici["dati"]["tecnici"][0]["_id"]

        assegna = self._client.put(
            f"{PREFISSO_API}/manutenzione/{id_ticket}/assegna",
            json={"id_tecnico": id_tecnico},
            headers=op,
        ).json()
        self.assertTrue(assegna["dati"]["assegnato"])

        chiudi = self._client.put(
            f"{PREFISSO_API}/manutenzione/{id_ticket}/chiudi", headers=op
        ).json()
        self.assertTrue(chiudi["dati"]["chiuso"])
        chiusi = self._client.get(
            f"{PREFISSO_API}/manutenzione", params={"stato": "chiuso"}, headers=op
        ).json()
        self.assertTrue(any(t["_id"] == id_ticket for t in chiusi["dati"]["ticket"]))

    # ── ③ Promozioni e incentivi geografici (OP.09/OP.15) ─────────────────────
    def test_ciclo_promozione(self) -> None:
        """! @brief OP crea una promozione, la vede in elenco e la disattiva (OP.09/OP.15)."""
        op = self._op()
        creata = self._client.post(
            f"{PREFISSO_API}/promozioni",
            json={
                "tipo": "sconto_geografico",
                "descrizione": "Sconto 20% avvii in periferia",
                "valore": 20,
                "id_area": "area-bari-centro",
            },
            headers=op,
        )
        self.assertEqual(creata.status_code, 201)
        id_promo = creata.json()["dati"]["id_promozione"]

        attive = self._client.get(
            f"{PREFISSO_API}/promozioni", params={"solo_attive": True}, headers=op
        ).json()
        self.assertTrue(any(p["_id"] == id_promo for p in attive["dati"]["promozioni"]))

        self._client.delete(f"{PREFISSO_API}/promozioni/{id_promo}", headers=op)
        dopo = self._client.get(
            f"{PREFISSO_API}/promozioni", params={"solo_attive": True}, headers=op
        ).json()
        self.assertFalse(any(p["_id"] == id_promo for p in dopo["dati"]["promozioni"]))

    # ── ④ Grandi eventi cittadini (AP.09) ─────────────────────────────────────
    def test_eventi_pa(self) -> None:
        """! @brief PA inserisce un evento tipizzato, lo ritrova in elenco e lo elimina (AP.09)."""
        pa = self._pa()
        creato = self._client.post(
            f"{PREFISSO_API}/eventi",
            json={
                "nome": "Concerto Lungomare",
                "categoria": "grande_evento",
                "area": "Lungomare",
                "data_inizio": "2026-07-10",
                "data_fine": "2026-07-11",
                "poligono": [[41.13, 16.86], [41.13, 16.87], [41.12, 16.87], [41.12, 16.86]],
            },
            headers=pa,
        )
        self.assertEqual(creato.status_code, 201)
        id_evento = creato.json()["dati"]["id_evento"]

        elenco = self._client.get(f"{PREFISSO_API}/eventi", headers=pa).json()
        trovato = [e for e in elenco["dati"]["eventi"] if e["_id"] == id_evento]
        self.assertEqual(len(trovato), 1)
        self.assertEqual(trovato[0]["tipo"], "evento")
        self.assertEqual(trovato[0]["categoria"], "grande_evento")
        self.assertEqual(trovato[0]["area"], "Lungomare")

        # Eliminazione dell'evento (AP.09): la zona torna libera e sparisce dall'elenco.
        elimina = self._client.delete(f"{PREFISSO_API}/eventi/{id_evento}", headers=pa).json()
        self.assertTrue(elimina["dati"]["eliminato"])
        dopo = self._client.get(f"{PREFISSO_API}/eventi", headers=pa).json()
        self.assertFalse(any(e["_id"] == id_evento for e in dopo["dati"]["eventi"]))

    def test_categoria_evento_non_valida(self) -> None:
        """! @brief Una categoria evento fuori dominio è rifiutata al confine (422, AP.09)."""
        pa = self._pa()
        risp = self._client.post(
            f"{PREFISSO_API}/eventi",
            json={
                "nome": "Evento Errato",
                "categoria": "festa_abusiva",
                "data_inizio": "2026-07-10",
                "data_fine": "2026-07-11",
                "poligono": [[41.13, 16.86], [41.13, 16.87], [41.12, 16.87]],
            },
            headers=pa,
        )
        self.assertEqual(risp.status_code, 422)

    # ── ⑤ Reportistica AP granulare (AP.01/02/03/07, IIN-15) ──────────────────
    def test_analitiche_granulari_pa(self) -> None:
        """! @brief PA estrae i 4 report (noleggi/flussi/operativi/CO2) anonimi (AP.01/02/03/07)."""
        pa = self._pa()

        noleggi = self._client.get(f"{PREFISSO_API}/analitiche/noleggi", headers=pa).json()
        self.assertTrue(noleggi["disponibile"])
        self.assertIsInstance(noleggi["dati"]["noleggi"], dict)

        flussi = self._client.get(f"{PREFISSO_API}/analitiche/flussi", headers=pa).json()
        self.assertEqual(len(flussi["dati"]["flussi"]), 24)  # una voce per ogni ora 0-23

        operativi = self._client.get(f"{PREFISSO_API}/analitiche/operativi", headers=pa).json()
        perc = operativi["dati"]["operativi"]
        # Le percentuali per stato non superano il 100% complessivo (mezzi partizionati).
        self.assertLessEqual(
            perc["operativi"] + perc["manutenzione"] + perc["scarico"], 100.0 + 0.1
        )

        co2 = self._client.get(f"{PREFISSO_API}/analitiche/co2", headers=pa).json()
        self.assertGreaterEqual(co2["dati"]["km_totali"], 0.0)
        self.assertGreaterEqual(co2["dati"]["co2_risparmiata_kg"], 0.0)
        # Anonimato IIN-15: nessun identificativo nei report.
        for chiave in ("_id", "id_utente", "id_mezzo"):
            self.assertNotIn(chiave, co2["dati"])

    def test_analitiche_riservato(self) -> None:
        """! @brief I report granulari sono riservati a OP/PA: UT riceve 403 (RBAC IIN-5)."""
        ut = self._bearer(self._token_ut())
        for rotta in ("noleggi", "flussi", "operativi", "co2"):
            risp = self._client.get(f"{PREFISSO_API}/analitiche/{rotta}", headers=ut)
            self.assertEqual(risp.status_code, 403, rotta)

    # ── ⑥ Flotta / guasti / soglie (OP.02/03/13/22) ───────────────────────────
    def test_mezzi_guasti_e_report(self) -> None:
        """! @brief OP consulta i mezzi guasti e il report giornaliero della flotta (OP.03/13)."""
        op = self._op()
        guasti = self._client.get(f"{PREFISSO_API}/mezzi-guasti", headers=op).json()
        self.assertTrue(guasti["disponibile"])
        for m in guasti["dati"]["mezzi"]:
            self.assertEqual(m["stato_operativo"], "guasto")

        report = self._client.get(f"{PREFISSO_API}/flotta/report", headers=op).json()
        self.assertIn("per_stato", report["dati"])
        self.assertGreaterEqual(report["dati"]["totale"], 1)
        self.assertGreaterEqual(report["dati"]["batteria_scarica"], 0)

    def test_soglia_batteria_genera_allerta(self) -> None:
        """! @brief OP imposta una soglia batteria alta e la ritrova fra le allerte (OP.22)."""
        op = self._op()
        creata = self._client.post(
            f"{PREFISSO_API}/soglie/batteria", json={"percentuale": 100}, headers=op
        )
        self.assertEqual(creata.status_code, 201)
        self.assertTrue(creata.json()["dati"]["id_soglia"])
        allerte = self._client.get(f"{PREFISSO_API}/soglie/allerte", headers=op).json()
        # Con soglia 100% ogni mezzo non perfettamente carico genera un'allerta batteria.
        self.assertTrue(any(a["tipo"] == "batteria" for a in allerte["dati"]["allerte"]))

    def test_soglia_area_genera_allerta(self) -> None:
        """! @brief OP impone un minimo di mezzi irraggiungibile su un'area → allerta (OP.02)."""
        op = self._op()
        aree = self._client.get(f"{PREFISSO_API}/aree", headers=op).json()["dati"]["aree"]
        if not aree:
            self.skipTest("seed senza aree")
        id_area = aree[0]["_id"]
        self._client.post(
            f"{PREFISSO_API}/soglie/area",
            json={"id_area": id_area, "minimo": 9999},
            headers=op,
        )
        allerte = self._client.get(f"{PREFISSO_API}/soglie/allerte", headers=op).json()
        self.assertTrue(any(a["tipo"] == "mezzi_area" for a in allerte["dati"]["allerte"]))

    def test_soglie_riservato_op(self) -> None:
        """! @brief Le soglie sono riservate a OP: UT riceve 403 (RBAC IIN-5)."""
        ut = self._bearer(self._token_ut())
        self.assertEqual(
            self._client.get(f"{PREFISSO_API}/soglie/allerte", headers=ut).status_code, 403
        )

    # ── ⑦ Telemetria e blocco motore remoto (OP.07/11/14) ─────────────────────
    def test_blocco_motore_traccia_telemetria(self) -> None:
        """! @brief OP blocca un mezzo da remoto e ne ritrova l'evento nel log (OP.11/14)."""
        op = self._op()
        blocco = self._client.post(f"{PREFISSO_API}/mezzi/SC-001/blocco-motore", headers=op)
        self.assertEqual(blocco.status_code, 201)
        self.assertTrue(blocco.json()["dati"]["bloccato"])

        log = self._client.get(f"{PREFISSO_API}/mezzi/SC-001/telemetria", headers=op).json()
        eventi = log["dati"]["eventi"]
        self.assertTrue(any(e["tipo"] == "blocco" for e in eventi))

    def test_blocco_motore_mezzo_inesistente(self) -> None:
        """! @brief Il blocco su un mezzo inesistente è respinto (input non valido → 400)."""
        op = self._op()
        risp = self._client.post(f"{PREFISSO_API}/mezzi/ZZ-999/blocco-motore", headers=op)
        self.assertEqual(risp.status_code, 400)

    def test_sblocco_motore_traccia_telemetria(self) -> None:
        """! @brief OP sblocca un mezzo da remoto e ne ritrova l'evento nel log (OP.11/14)."""
        op = self._op()
        sblocco = self._client.post(f"{PREFISSO_API}/mezzi/SC-001/sblocco-motore", headers=op)
        self.assertEqual(sblocco.status_code, 201)
        self.assertTrue(sblocco.json()["dati"]["sbloccato"])

        log = self._client.get(f"{PREFISSO_API}/mezzi/SC-001/telemetria", headers=op).json()
        eventi = log["dati"]["eventi"]
        self.assertTrue(any(e["tipo"] == "sblocco" for e in eventi))

    def test_sblocco_motore_riservato_op(self) -> None:
        """! @brief Lo sblocco motore è riservato a OP: UT riceve 403 (RBAC IIN-5)."""
        ut = self._bearer(self._token_ut())
        self.assertEqual(
            self._client.post(
                f"{PREFISSO_API}/mezzi/SC-001/sblocco-motore", headers=ut
            ).status_code,
            403,
        )

    def test_telemetria_riservata_op(self) -> None:
        """! @brief Telemetria e blocco motore sono riservati a OP: UT riceve 403 (RBAC IIN-5)."""
        ut = self._bearer(self._token_ut())
        self.assertEqual(
            self._client.get(f"{PREFISSO_API}/mezzi/SC-001/telemetria", headers=ut).status_code, 403
        )
        self.assertEqual(
            self._client.post(f"{PREFISSO_API}/mezzi/SC-001/blocco-motore", headers=ut).status_code,
            403,
        )

    def test_eventi_solo_pa(self) -> None:
        """! @brief L'inserimento eventi è riservato alla PA: OP riceve 403 (RBAC IIN-5)."""
        op = self._op()
        risp = self._client.post(
            f"{PREFISSO_API}/eventi",
            json={
                "nome": "Test",
                "data_inizio": "2026-07-10",
                "data_fine": "2026-07-11",
                "poligono": [[41.13, 16.86], [41.13, 16.87], [41.12, 16.87]],
            },
            headers=op,
        )
        self.assertEqual(risp.status_code, 403)


if __name__ == "__main__":
    unittest.main()
