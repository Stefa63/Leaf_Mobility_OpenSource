"""! @file verifica_e2e_live.py
@brief Verifica E2E dei flussi client→server su HTTP REALE (Cascata C, Parte 1).

NON è un test pytest (nome senza prefisso `test_`, non raccolto): è uno script di
verifica on-demand che colpisce il **runtime già avviato** su socket reale (uvicorn),
con la persistenza su **emulatore Firestore** popolato dal seed. A differenza di
@ref test_e2e_flussi.py (in-process, client ASGI), qui le richieste viaggiano su
socket di rete come dai client veri (app mobile / web).

Prerequisiti (vedi `tool/avvia_stack_e2e.ps1`, che li predispone in un colpo):
  1. emulatore Firestore avviato e `FIRESTORE_EMULATOR_HOST` impostato;
  2. seed eseguito (`python -m server.integration_tier.data_access_manager.bootstrap_seed`);
  3. runtime avviato (console operativa → `start`, oppure uvicorn) su loopback.

Uso (dalla repo root, stack avviato):
    LEAF_E2E_BASE=http://127.0.0.1:8770 PYTHONPATH=. python server/tests/verifica_e2e_live.py

Riproduce: login UT → prenota/avvia/termina + fattura · profilo/storico/fatture ·
OP login+MFA → flotta/analitiche/geofencing CRUD/assistenza · ricerca percorsi (UT.07).
"""

from __future__ import annotations

import os
import sys

import httpx

from server.integration_tier.data_access_manager.bootstrap_seed import PASSWORD_DEMO

#! Base URL del runtime avviato (loopback di default; override con LEAF_E2E_BASE).
BASE = os.environ.get("LEAF_E2E_BASE", "http://127.0.0.1:8770")
API = f"{BASE}/api/v1"


def _ok(esito: bool, etichetta: str) -> bool:
    """! @brief Stampa l'esito di un controllo e lo restituisce.
    @param esito True se il controllo è superato.
    @param etichetta Nome del controllo.
    @return L'esito ricevuto.
    """
    print(f"  [{'PASS' if esito else 'FAIL'}] {etichetta}")
    return esito


def _bearer(token: str) -> dict[str, str]:
    """! @brief Header Authorization Bearer dal token dato.
    @param token Token di sessione.
    @return Header con il Bearer.
    """
    return {"Authorization": f"Bearer {token}"}


def _token_ut(c: httpx.Client) -> str:
    """! @brief Login UT demo → token di sessione.
    @param c Client HTTP verso il runtime.
    @return Token di sessione UT.
    """
    corpo = c.post(
        f"{API}/auth/login",
        json={"identita": "utente.demo@leaf.test", "password": PASSWORD_DEMO},
    ).json()
    return str(corpo["access_token"])


def _token_mfa(c: httpx.Client, identita: str) -> str:
    """! @brief Login OP/PA + verifica MFA → token di sessione (IIN-9).
    @param c Client HTTP verso il runtime.
    @param identita Email dell'account OP/PA.
    @return Token di sessione post-OTP.
    """
    login = c.post(
        f"{API}/auth/login", json={"identita": identita, "password": PASSWORD_DEMO}
    ).json()
    corpo = c.post(
        f"{API}/auth/mfa",
        json={"id_account": login["id_account"], "otp": login["otp_simulato"]},
    ).json()
    return str(corpo["access_token"])


def _verifica_ciclo_corsa(c: httpx.Client, h: dict[str, str], risultati: list[bool]) -> None:
    """! @brief Flusso UT: prenota → avvia → termina con fattura (UT.02/10/04/25).
    @param c Client HTTP.
    @param h Header Bearer dell'utente.
    @param risultati Lista degli esiti a cui appendere i controlli.
    """
    pren = c.post(f"{API}/prenotazioni", json={"id_mezzo": "BK-018"}, headers=h).json()
    risultati.append(_ok(pren.get("disponibile") is True, "prenotazione mezzo"))
    avvio = c.post(
        f"{API}/corse",
        json={"id_mezzo": "BK-018", "id_prenotazione": pren["dati"]["id_prenotazione"]},
        headers=h,
    ).json()["dati"]
    risultati.append(_ok(bool(avvio.get("sbloccato")), "avvio corsa (sblocco IoT)"))
    fine = c.post(f"{API}/corse/{avvio['id_corsa']}/termina", json={"km": 3.0}, headers=h).json()[
        "dati"
    ]
    risultati.append(
        _ok(
            fine.get("costo_finale_cent", 0) > 0 and bool(fine.get("id_fattura")),
            "termine + fattura",
        )
    )


def main() -> int:
    """! @brief Esegue il percorso E2E completo su HTTP reale e riporta l'esito.
    @return 0 se tutti passano; 1 se qualcuno fallisce; 2 se lo stack non è raggiungibile.
    """
    risultati: list[bool] = []
    try:
        with httpx.Client(timeout=10.0) as c:
            info = c.get(f"{API}/info")
            if info.status_code != 200:
                print(f"ERRORE: runtime non raggiungibile su {BASE} (info → {info.status_code}).")
                return 2
            capacita = info.json().get("capacita", [])
            risultati.append(_ok("percorsi" in capacita, "runtime raggiungibile, capacita ricerca"))

            # Verifica che la persistenza/seed siano pronti (login non 503).
            login = c.post(
                f"{API}/auth/login",
                json={"identita": "utente.demo@leaf.test", "password": PASSWORD_DEMO},
            )
            if login.status_code == 503:
                print("ERRORE: persistenza non configurata o seed assente. Avvia emulatore + seed.")
                return 2

            print("Flusso utente (UT.01/02/04/10/17/25)")
            ut = _bearer(str(login.json()["access_token"]))
            veicoli = c.get(f"{API}/veicoli").json()
            risultati.append(_ok(veicoli["dati"]["totale"] > 0, "elenco veicoli disponibili"))
            _verifica_ciclo_corsa(c, ut, risultati)
            profilo = c.get(f"{API}/profilo", headers=ut).json()
            risultati.append(
                _ok(
                    profilo["dati"]["email"] == "utente.demo@leaf.test",
                    "profilo senza campi riservati",
                )
            )
            storico = c.get(f"{API}/corse", headers=ut).json()
            risultati.append(_ok(storico["dati"]["totale"] >= 1, "storico corse"))
            fatture = c.get(f"{API}/fatture", headers=ut).json()
            risultati.append(_ok(fatture["dati"]["totale"] >= 1, "fatture (UT.25)"))

            print("Ricerca percorsi (UT.07/UT.08)")
            sugg = c.get(f"{API}/geocoding", params={"q": "stazione"}, headers=ut).json()
            risultati.append(
                _ok(
                    any("Stazione" in luogo["nome"] for luogo in sugg["dati"]["luoghi"]),
                    "geocoding suggerimenti",
                )
            )
            perc = c.get(
                f"{API}/percorsi",
                params={"da": "Stazione Bari Centrale", "a": "Teatro Petruzzelli"},
                headers=ut,
            ).json()
            risultati.append(
                _ok(
                    perc["dati"]["totale"] == 2
                    and any(p["ha_tpl"] for p in perc["dati"]["percorsi"]),
                    "opzioni di percorso (con TPL)",
                )
            )

            print("Dashboard OP/PA (AP.03/04/08/OP.08/IIN-9/15)")
            risultati.append(
                _ok(
                    c.get(f"{API}/flotta").status_code == 401, "MFA/RBAC: flotta senza token -> 401"
                )
            )
            op = _bearer(_token_mfa(c, "operatore.demo@leaf.test"))
            flotta = c.get(f"{API}/flotta", headers=op).json()
            risultati.append(_ok(flotta["dati"]["totale"] > 0, "flotta (OP, post-MFA)"))
            anal = c.get(f"{API}/analitiche", headers=op).json()
            anonimo = all("id_utente" not in r and "_id" not in r for r in anal["dati"]["per_tipo"])
            risultati.append(_ok(anonimo, "analitiche anonime (IIN-15)"))
            # Assistenza: UT apre, OP vede e risponde.
            tic = c.post(
                f"{API}/assistenza",
                json={"oggetto": "Test E2E", "messaggio": "Verifica coda assistenza."},
                headers=ut,
            ).json()["dati"]["id_ticket"]
            coda = c.get(f"{API}/assistenza", headers=op).json()
            risultati.append(_ok(coda["dati"]["totale"] >= 1, "coda assistenza (OP.08)"))
            risp = c.put(
                f"{API}/assistenza/{tic}/risposta",
                json={"risposta": "Preso in carico.", "stato": "in_lavorazione"},
                headers=op,
            ).json()
            risultati.append(_ok(bool(risp["dati"]["aggiornato"]), "presa in carico assistenza"))
            # Geofencing CRUD (PA).
            pa = _bearer(_token_mfa(c, "pa.demo@leaf.test"))
            prima = c.get(f"{API}/aree", headers=pa).json()["dati"]["totale"]
            id_area = c.post(
                f"{API}/aree",
                json={
                    "tipo": "slow_zone",
                    "nome": "E2E Slow Zone",
                    "poligono": [[41.13, 16.86], [41.13, 16.87], [41.12, 16.87]],
                    "limite_velocita_kmh": 10,
                },
                headers=pa,
            ).json()["dati"]["id_area"]
            c.delete(f"{API}/aree/{id_area}", headers=pa)
            dopo = c.get(f"{API}/aree", headers=pa).json()["dati"]["totale"]
            risultati.append(_ok(dopo == prima, "geofencing CRUD (crea+elimina)"))
    except httpx.HTTPError as exc:
        print(f"ERRORE di connessione verso {BASE}: {exc}")
        print("Avvia lo stack con tool/avvia_stack_e2e.ps1 (emulatore + seed + runtime).")
        return 2

    print(f"\nRisultato: {sum(risultati)}/{len(risultati)} controlli E2E superati")
    return 0 if all(risultati) else 1


if __name__ == "__main__":
    sys.exit(main())
