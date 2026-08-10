"""! @file test_e2e_flussi.py
@brief E2E dei flussi client→server su HTTP (Cascata C, Parte 1 — automatizzabile).

Completa @ref test_slice_persistenza.py coprendo i flussi finora non verificati E2E
attraverso l'intero stack ASGI (middleware sicurezza, CORS, rate-limit, gateway,
business, integration): dashboard PA (geofencing CRUD), coda assistenza
(UT apre → OP prende in carico), ricerca percorsi (UT.07: geocoding + percorsi) e i
controlli di sicurezza al confine HTTP (MFA enforcement IIN-9, RBAC IIN-5,
anonimizzazione IIN-15). Tutto OFFLINE su @ref ClienteFalsoFirestore popolato dal
seed: nessun emulatore né rete (testabilità §12.2). La verifica su socket/uvicorn
reale + emulatore Firestore è in @ref verifica_e2e_live.py (on-demand).
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


class TestE2EFlussi(unittest.TestCase):
    """! @brief E2E dei flussi dashboard, assistenza, percorsi e sicurezza su HTTP."""

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
    def _token_ut(self) -> str:
        """! @brief Login UT demo → token di sessione (Bearer)."""
        corpo = self._client.post(
            f"{PREFISSO_API}/auth/login",
            json={"identita": "utente.demo@leaf.test", "password": PASSWORD_DEMO},
        ).json()
        return str(corpo["access_token"])

    def _token_mfa(self, identita: str) -> str:
        """! @brief Login OP/PA + verifica MFA (IIN-9) → token di sessione."""
        login = self._client.post(
            f"{PREFISSO_API}/auth/login",
            json={"identita": identita, "password": PASSWORD_DEMO},
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

    # ── Dashboard PA: geofencing CRUD (AP.04/06/08) ───────────────────────────
    def test_geofencing_crud_e2e(self) -> None:
        """! @brief PA: elenca, crea ed elimina un'area limitata via HTTP (AP.04/08)."""
        h = self._bearer(self._token_mfa("pa.demo@leaf.test"))
        iniziali = self._client.get(f"{PREFISSO_API}/aree", headers=h).json()["dati"]["totale"]
        self.assertGreaterEqual(iniziali, 2)  # due aree dal seed

        creata = self._client.post(
            f"{PREFISSO_API}/aree",
            json={
                "tipo": "slow_zone",
                "nome": "Lungomare — Slow Zone Test",
                "poligono": [[41.13, 16.86], [41.13, 16.87], [41.12, 16.87], [41.12, 16.86]],
                "limite_velocita_kmh": 10,
            },
            headers=h,
        )
        self.assertEqual(creata.status_code, 201)
        id_area = creata.json()["dati"]["id_area"]
        self.assertTrue(id_area)

        dopo_crea = self._client.get(f"{PREFISSO_API}/aree", headers=h).json()["dati"]["totale"]
        self.assertEqual(dopo_crea, iniziali + 1)

        elimina = self._client.delete(f"{PREFISSO_API}/aree/{id_area}", headers=h).json()
        self.assertTrue(elimina["dati"]["eliminata"])
        dopo_elim = self._client.get(f"{PREFISSO_API}/aree", headers=h).json()["dati"]["totale"]
        self.assertEqual(dopo_elim, iniziali)

    # ── Ciclo corsa esteso: stima, pausa/ripresa, valutazione (UT.03/12/16) ────
    def test_ciclo_corsa_esteso_e2e(self) -> None:
        """! @brief UT stima, avvia, mette in pausa/riprende, termina e valuta una corsa."""
        ut = self._bearer(self._token_ut())

        stima = self._client.post(
            f"{PREFISSO_API}/corse/stima",
            json={"id_mezzo": "BK-007", "durata_min": 15},
            headers=ut,
        )
        self.assertEqual(stima.status_code, 200)
        self.assertGreater(stima.json()["dati"]["costo_stimato_cent"], 0)

        avvio = self._client.post(f"{PREFISSO_API}/corse", json={"id_mezzo": "BK-007"}, headers=ut)
        self.assertEqual(avvio.status_code, 200)
        id_corsa = avvio.json()["dati"]["id_corsa"]

        pausa = self._client.post(f"{PREFISSO_API}/corse/{id_corsa}/pausa", headers=ut).json()
        self.assertEqual(pausa["dati"]["stato"], "in_pausa")
        ripresa = self._client.post(f"{PREFISSO_API}/corse/{id_corsa}/riprendi", headers=ut).json()
        self.assertEqual(ripresa["dati"]["stato"], "in_corso")

        termina = self._client.post(
            f"{PREFISSO_API}/corse/{id_corsa}/termina", json={"km": 2.0}, headers=ut
        )
        self.assertEqual(termina.status_code, 200)

        valuta = self._client.post(
            f"{PREFISSO_API}/corse/{id_corsa}/valutazione", json={"stelle": 5}, headers=ut
        )
        self.assertEqual(valuta.status_code, 201)
        self.assertEqual(valuta.json()["dati"]["valutazione"], 5)

    def test_stima_mezzo_inesistente(self) -> None:
        """! @brief La stima su un mezzo inesistente è respinta (input non valido → 400)."""
        ut = self._bearer(self._token_ut())
        risp = self._client.post(
            f"{PREFISSO_API}/corse/stima", json={"id_mezzo": "ZZ-999"}, headers=ut
        )
        self.assertEqual(risp.status_code, 400)

    def test_valutazione_fuori_range(self) -> None:
        """! @brief Una valutazione fuori dall'intervallo 1-5 è respinta dal contratto (422)."""
        ut = self._bearer(self._token_ut())
        risp = self._client.post(
            f"{PREFISSO_API}/corse/xyz/valutazione", json={"stelle": 9}, headers=ut
        )
        self.assertEqual(risp.status_code, 422)

    # ── Profilo esteso: pagamenti, abbonamenti, consensi, KYC (UT.11/18/22.2) ──
    def test_profilo_esteso_e2e(self) -> None:
        """! @brief UT registra carta, sottoscrive un piano, dà un consenso e carica un KYC."""
        ut = self._bearer(self._token_ut())

        # Punto 4/5: l'indirizzo di fatturazione deve coincidere con la residenza del profilo.
        self._client.put(
            f"{PREFISSO_API}/profilo",
            json={"residenza": "Via Roma 1, Bari"},
            headers=ut,
        )
        pag = self._client.post(
            f"{PREFISSO_API}/profilo/pagamenti",
            json={
                "numero": "4242424242424242",
                "mese": 12,
                "anno": 2030,
                "titolare": "Mario Rossi",
                "cvv": "123",
                "indirizzo_fatturazione": "Via Roma 1, Bari",
            },
            headers=ut,
        )
        self.assertEqual(pag.status_code, 201)
        self.assertTrue(pag.json()["dati"]["pan_mascherato"].endswith("4242"))

        abb = self._client.post(
            f"{PREFISSO_API}/profilo/abbonamenti", json={"id_piano": "piano-plus"}, headers=ut
        )
        self.assertEqual(abb.status_code, 201)
        self.assertTrue(abb.json()["dati"]["id_abbonamento"])

        cons = self._client.post(
            f"{PREFISSO_API}/profilo/consensi",
            json={"tipo": "geolocalizzazione", "concesso": True},
            headers=ut,
        )
        self.assertEqual(cons.status_code, 201)
        self.assertTrue(cons.json()["dati"]["concesso"])

        kyc = self._client.post(
            f"{PREFISSO_API}/profilo/kyc",
            json={"tipo": "patente", "nome_file": "patente.pdf"},
            headers=ut,
        )
        self.assertEqual(kyc.status_code, 201)
        self.assertEqual(kyc.json()["dati"]["stato_verifica"], "in_attesa")

    def test_abbonamenti_elenco_e2e(self) -> None:
        """! @brief UT sottoscrive un piano e lo ritrova nell'elenco abbonamenti (UT.18/UT.21)."""
        ut = self._bearer(self._token_ut())

        vuoto = self._client.get(f"{PREFISSO_API}/profilo/abbonamenti", headers=ut).json()
        self.assertEqual(vuoto["dati"]["totale"], 0)

        self._client.post(
            f"{PREFISSO_API}/profilo/abbonamenti", json={"id_piano": "piano-base"}, headers=ut
        )
        elenco = self._client.get(f"{PREFISSO_API}/profilo/abbonamenti", headers=ut).json()
        self.assertEqual(elenco["dati"]["totale"], 1)
        abbonamento = elenco["dati"]["abbonamenti"][0]
        self.assertEqual(abbonamento["id_piano"], "piano-base")
        self.assertEqual(abbonamento["stato"], "attivo")

    def test_kyc_formato_non_ammesso(self) -> None:
        """! @brief Un KYC con estensione non PDF/JPG/PNG è bloccato (IIN-6/AG-SEC-01 → 400)."""
        ut = self._bearer(self._token_ut())
        risp = self._client.post(
            f"{PREFISSO_API}/profilo/kyc",
            json={"tipo": "patente", "nome_file": "malware.exe"},
            headers=ut,
        )
        self.assertEqual(risp.status_code, 400)

    def test_abbonamento_piano_inesistente(self) -> None:
        """! @brief La sottoscrizione di un piano inesistente è respinta (400)."""
        ut = self._bearer(self._token_ut())
        risp = self._client.post(
            f"{PREFISSO_API}/profilo/abbonamenti", json={"id_piano": "piano-fantasma"}, headers=ut
        )
        self.assertEqual(risp.status_code, 400)

    # ── Identità di sessione (auth/io) ────────────────────────────────────────
    def test_auth_io(self) -> None:
        """! @brief GET /auth/io restituisce id_account e ruolo della sessione corrente."""
        ut = self._bearer(self._token_ut())
        io = self._client.get(f"{PREFISSO_API}/auth/io", headers=ut).json()
        self.assertTrue(io["disponibile"])
        self.assertEqual(io["dati"]["ruolo"], "UT")
        self.assertTrue(io["dati"]["id_account"])
        self.assertEqual(self._client.get(f"{PREFISSO_API}/auth/io").status_code, 401)

    # ── Reset password con conferma codice (IIN-11 / UT.24 / AP.12) ────────────
    def test_reset_password_conferma_e2e(self) -> None:
        """! @brief IIN-11: richiesta reset → codice → conferma → login con la nuova password."""
        identita = "utente.demo@leaf.test"
        richiesta = self._client.post(
            f"{PREFISSO_API}/auth/password/reset", json={"identita": identita}
        )
        self.assertEqual(richiesta.status_code, 200)
        codice = str(richiesta.json()["codice_simulato"])

        nuova = "NuovaPass1!"
        conferma = self._client.post(
            f"{PREFISSO_API}/auth/password/reset/conferma",
            json={"identita": identita, "codice": codice, "nuova_password": nuova},
        )
        self.assertEqual(conferma.status_code, 200)
        self.assertTrue(conferma.json()["reimpostata"])

        # La nuova password autentica (token UT diretto); la vecchia è ora respinta.
        ok = self._client.post(
            f"{PREFISSO_API}/auth/login", json={"identita": identita, "password": nuova}
        )
        self.assertEqual(ok.status_code, 200)
        self.assertTrue(ok.json()["access_token"])
        ko = self._client.post(
            f"{PREFISSO_API}/auth/login",
            json={"identita": identita, "password": PASSWORD_DEMO},
        )
        self.assertEqual(ko.status_code, 401)

    def test_reset_codice_errato_non_reimposta(self) -> None:
        """! @brief IIN-11: codice errato → reimpostata False (anti-enumerazione), nessun 500."""
        identita = "utente.demo@leaf.test"
        self._client.post(f"{PREFISSO_API}/auth/password/reset", json={"identita": identita})
        conferma = self._client.post(
            f"{PREFISSO_API}/auth/password/reset/conferma",
            json={"identita": identita, "codice": "000000", "nuova_password": "NuovaPass1!"},
        )
        self.assertEqual(conferma.status_code, 200)
        self.assertFalse(conferma.json()["reimpostata"])
        # La password originale continua a funzionare (token non compromesso).
        ancora = self._client.post(
            f"{PREFISSO_API}/auth/login",
            json={"identita": identita, "password": PASSWORD_DEMO},
        )
        self.assertEqual(ancora.status_code, 200)

    # ── Notifiche: OP pubblica broadcast → UT la legge e la marca (UT.19/UT.15) ─
    def test_notifiche_broadcast_e2e(self) -> None:
        """! @brief OP pubblica un avviso di servizio, l'UT lo vede e lo marca come letto."""
        op = self._bearer(self._token_mfa("operatore.demo@leaf.test"))
        creata = self._client.post(
            f"{PREFISSO_API}/notifiche",
            json={"titolo": "Interruzione servizio", "messaggio": "Manutenzione rete 22-23"},
            headers=op,
        )
        self.assertEqual(creata.status_code, 201)
        id_notifica = creata.json()["dati"]["id_notifica"]

        ut = self._bearer(self._token_ut())
        elenco = self._client.get(f"{PREFISSO_API}/notifiche", headers=ut).json()
        self.assertTrue(any(n["_id"] == id_notifica for n in elenco["dati"]["notifiche"]))

        letta = self._client.post(
            f"{PREFISSO_API}/notifiche/{id_notifica}/letta", headers=ut
        ).json()
        self.assertTrue(letta["dati"]["letta"])
        non_lette = self._client.get(
            f"{PREFISSO_API}/notifiche", params={"solo_non_lette": True}, headers=ut
        ).json()
        self.assertFalse(any(n["_id"] == id_notifica for n in non_lette["dati"]["notifiche"]))

    def test_notifiche_broadcast_riservato(self) -> None:
        """! @brief La pubblicazione broadcast è riservata a OP/PA: UT riceve 403 (RBAC IIN-5)."""
        ut = self._bearer(self._token_ut())
        risp = self._client.post(
            f"{PREFISSO_API}/notifiche",
            json={"titolo": "x", "messaggio": "y"},
            headers=ut,
        )
        self.assertEqual(risp.status_code, 403)

    # ── Stazioni di ricarica e SOS (UT.14/UT.20) ──────────────────────────────
    def test_stazioni_e_sos_e2e(self) -> None:
        """! @brief UT vede le stazioni di ricarica e attiva un SOS con la posizione."""
        ut = self._bearer(self._token_ut())

        stazioni = self._client.get(f"{PREFISSO_API}/stazioni", headers=ut).json()
        self.assertTrue(stazioni["disponibile"])
        self.assertGreaterEqual(stazioni["dati"]["totale"], 1)

        sos = self._client.post(
            f"{PREFISSO_API}/sos", json={"lat": 41.117, "lon": 16.871}, headers=ut
        )
        self.assertEqual(sos.status_code, 201)
        self.assertEqual(sos.json()["dati"]["stato"], "inoltrata")
        self.assertTrue(sos.json()["dati"]["id_segnalazione"])

    def test_stazioni_richiede_sessione(self) -> None:
        """! @brief Le stazioni richiedono autenticazione: senza token → 401."""
        self.assertEqual(self._client.get(f"{PREFISSO_API}/stazioni").status_code, 401)

    # ── Coda assistenza: UT apre → OP prende in carico (UT.09/OP.08) ──────────
    def test_assistenza_e2e(self) -> None:
        """! @brief UT apre un ticket, OP lo vede in coda e risponde (UT.09/OP.08)."""
        ut = self._bearer(self._token_ut())
        apertura = self._client.post(
            f"{PREFISSO_API}/assistenza",
            json={"oggetto": "Mezzo bloccato", "messaggio": "Il monopattino non si sblocca."},
            headers=ut,
        )
        self.assertEqual(apertura.status_code, 201)
        id_ticket = apertura.json()["dati"]["id_ticket"]
        self.assertTrue(id_ticket)

        op = self._bearer(self._token_mfa("operatore.demo@leaf.test"))
        coda = self._client.get(f"{PREFISSO_API}/assistenza", headers=op).json()
        self.assertTrue(coda["disponibile"])
        self.assertGreaterEqual(coda["dati"]["totale"], 1)

        risposta = self._client.put(
            f"{PREFISSO_API}/assistenza/{id_ticket}/risposta",
            json={"risposta": "Inviamo un tecnico.", "stato": "in_lavorazione"},
            headers=op,
        ).json()
        self.assertTrue(risposta["dati"]["aggiornato"])

    def test_assistenza_riservata_op(self) -> None:
        """! @brief La coda assistenza è riservata a OP: UT riceve 403 (RBAC IIN-5)."""
        ut = self._bearer(self._token_ut())
        self.assertEqual(
            self._client.get(f"{PREFISSO_API}/assistenza", headers=ut).status_code, 403
        )

    # ── Ricerca percorsi (UT.07): geocoding + percorsi ────────────────────────
    def test_geocoding_e_percorsi_e2e(self) -> None:
        """! @brief UT: autocompletamento e opzioni di percorso reali via HTTP (UT.07/UT.08)."""
        h = self._bearer(self._token_ut())
        sugg = self._client.get(
            f"{PREFISSO_API}/geocoding", params={"q": "stazione"}, headers=h
        ).json()
        self.assertTrue(sugg["disponibile"])
        nomi = [luogo["nome"] for luogo in sugg["dati"]["luoghi"]]
        self.assertTrue(any("Stazione" in n for n in nomi))

        perc = self._client.get(
            f"{PREFISSO_API}/percorsi",
            params={"da": "Stazione Bari Centrale", "a": "Teatro Petruzzelli"},
            headers=h,
        ).json()
        self.assertTrue(perc["disponibile"])
        self.assertEqual(perc["dati"]["totale"], 2)
        self.assertTrue(any(p["ha_tpl"] for p in perc["dati"]["percorsi"]))

    def test_percorsi_luogo_sconosciuto(self) -> None:
        """! @brief Un luogo fuori gazetteer risponde 'non disponibile' (no 500)."""
        h = self._bearer(self._token_ut())
        perc = self._client.get(
            f"{PREFISSO_API}/percorsi",
            params={"da": "Luogo Inesistente XYZ", "a": "Teatro Petruzzelli"},
            headers=h,
        )
        self.assertEqual(perc.status_code, 200)
        self.assertFalse(perc.json()["disponibile"])

    def test_ricerca_richiede_sessione(self) -> None:
        """! @brief Geocoding e percorsi richiedono una sessione valida (401)."""
        self.assertEqual(self._client.get(f"{PREFISSO_API}/geocoding?q=bari").status_code, 401)
        self.assertEqual(self._client.get(f"{PREFISSO_API}/percorsi?da=A&a=B").status_code, 401)

    # ── Limite di 3 dispositivi simultanei (IIN-14) ───────────────────────────
    def _login_ut_dispositivo(self, device_id: str) -> int:
        """! @brief Login UT demo con un device_id esplicito; restituisce lo status HTTP."""
        risposta = self._client.post(
            f"{PREFISSO_API}/auth/login",
            json={
                "identita": "utente.demo@leaf.test",
                "password": PASSWORD_DEMO,
                "dispositivo": device_id,
            },
        )
        return int(risposta.status_code)

    def test_limite_dispositivi_quarto_respinto(self) -> None:
        """! @brief IIN-14: i primi 3 dispositivi accedono, il 4° è respinto con 403."""
        for n in range(1, 4):
            self.assertEqual(self._login_ut_dispositivo(f"dev-{n}"), 200)
        quarto = self._client.post(
            f"{PREFISSO_API}/auth/login",
            json={
                "identita": "utente.demo@leaf.test",
                "password": PASSWORD_DEMO,
                "dispositivo": "dev-4",
            },
        )
        self.assertEqual(quarto.status_code, 403)
        self.assertEqual(quarto.json()["detail"], "limite_dispositivi_superato")

    def test_logout_libera_uno_slot_dispositivo(self) -> None:
        """! @brief IIN-14: il logout libera uno slot, così un nuovo dispositivo può accedere."""
        # Primo dispositivo: ne conserviamo il token per il logout successivo.
        login1 = self._client.post(
            f"{PREFISSO_API}/auth/login",
            json={
                "identita": "utente.demo@leaf.test",
                "password": PASSWORD_DEMO,
                "dispositivo": "d-1",
            },
        )
        self.assertEqual(login1.status_code, 200)
        token1 = str(login1.json()["access_token"])
        # Altri due dispositivi saturano il limite di 3.
        self.assertEqual(self._login_ut_dispositivo("d-2"), 200)
        self.assertEqual(self._login_ut_dispositivo("d-3"), 200)
        # Con 3 slot occupati il 4° dispositivo è respinto.
        self.assertEqual(self._login_ut_dispositivo("d-4"), 403)
        # Il logout del primo dispositivo libera il suo slot.
        logout = self._client.post(f"{PREFISSO_API}/auth/logout", headers=self._bearer(token1))
        self.assertEqual(logout.status_code, 200)
        # Liberato lo slot di d-1, un nuovo dispositivo rientra nel limite.
        self.assertEqual(self._login_ut_dispositivo("d-5"), 200)

    # ── Cambio password obbligatorio al 1° accesso OP/PA (IIN-12) ──────────────
    def test_richiede_cambio_password_primo_accesso(self) -> None:
        """! @brief IIN-12: un OP provisionato segnala il cambio password e poi lo azzera."""
        from server.business_tier.gestore_profili_ekyc import GestoreProfiliEkyc

        prov = GestoreProfiliEkyc(self._dao).provisiona_operatore(
            "op.nuovo@leaf.test", "op.nuovo", "Nuovo Operatore"
        )
        temporanea = str(prov["password_temporanea"])

        # Primo accesso: login + MFA segnalano richiede_cambio_password = True.
        login = self._client.post(
            f"{PREFISSO_API}/auth/login",
            json={"identita": "op.nuovo@leaf.test", "password": temporanea},
        ).json()
        self.assertEqual(login["stato"], "mfa_richiesta")
        mfa = self._client.post(
            f"{PREFISSO_API}/auth/mfa",
            json={"id_account": login["id_account"], "otp": login["otp_simulato"]},
        ).json()
        self.assertTrue(mfa["richiede_cambio_password"])

        # Cambio password (IIN-5): dopo, il flag è azzerato a un nuovo accesso.
        cambio = self._client.post(
            f"{PREFISSO_API}/auth/password/primo-accesso",
            json={"nuova_password": "NuovaForte1!"},
            headers=self._bearer(str(mfa["access_token"])),
        )
        self.assertEqual(cambio.status_code, 200)

        login2 = self._client.post(
            f"{PREFISSO_API}/auth/login",
            json={"identita": "op.nuovo@leaf.test", "password": "NuovaForte1!"},
        ).json()
        mfa2 = self._client.post(
            f"{PREFISSO_API}/auth/mfa",
            json={"id_account": login2["id_account"], "otp": login2["otp_simulato"]},
        ).json()
        self.assertFalse(mfa2["richiede_cambio_password"])

    def test_login_op_demo_senza_cambio_password(self) -> None:
        """! @brief IIN-12: l'OP demo (password definitiva) non richiede il cambio password."""
        login = self._client.post(
            f"{PREFISSO_API}/auth/login",
            json={"identita": "operatore.demo@leaf.test", "password": PASSWORD_DEMO},
        ).json()
        mfa = self._client.post(
            f"{PREFISSO_API}/auth/mfa",
            json={"id_account": login["id_account"], "otp": login["otp_simulato"]},
        ).json()
        self.assertFalse(mfa["richiede_cambio_password"])

    # ── Sicurezza al confine HTTP: MFA enforcement (AG-SEC-03 / IIN-9) ─────────
    def test_mfa_enforcement_su_http(self) -> None:
        """! @brief OP non riceve token prima dell'OTP e non raggiunge endpoint protetti (IIN-9)."""
        login = self._client.post(
            f"{PREFISSO_API}/auth/login",
            json={"identita": "operatore.demo@leaf.test", "password": PASSWORD_DEMO},
        ).json()
        # Login OP: nessun access_token finché l'OTP non è verificato.
        self.assertEqual(login["stato"], "mfa_richiesta")
        self.assertNotIn("access_token", login)
        # Senza token la dashboard flotta è irraggiungibile (401).
        self.assertEqual(self._client.get(f"{PREFISSO_API}/flotta").status_code, 401)
        # Completato l'MFA, l'accesso è consentito.
        h = self._bearer(self._token_mfa("operatore.demo@leaf.test"))
        self.assertTrue(self._client.get(f"{PREFISSO_API}/flotta", headers=h).json()["disponibile"])


if __name__ == "__main__":
    unittest.main()
