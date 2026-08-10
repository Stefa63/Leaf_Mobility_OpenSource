"""! @file verifica_emulatore_live.py
@brief Verifica E2E dei gate AG-SEC contro l'emulatore Firestore LIVE (FASE 3).

NON è un test pytest (nome senza prefisso `test_`, non raccolto): è uno script di
verifica manuale eseguito on-demand con l'emulatore Firestore in esecuzione e
`firebase-admin` installato. Punta il @ref DataAccessManager all'emulatore
(`FIRESTORE_EMULATOR_HOST`), con cifratura AES-256-GCM reale, e riproduce i quattro
controlli di sicurezza su persistenza Firestore vera (non sul client fake):

  AG-SEC-01 (KYC format) · AG-SEC-02 (AES-256 at-rest) · AG-SEC-03 (MFA OP/PA) ·
  AG-SEC-04 (anonimizzazione PA).

Uso (dalla repo root, emulatore avviato):
    FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 PYTHONPATH=. \
        python server/tests/verifica_emulatore_live.py
"""

from __future__ import annotations

import base64
import os
import sys

from passlib.context import CryptContext

from server.business_tier.gestore_profili_ekyc import GestoreProfiliEkyc
from server.business_tier.motore_analitica import MotoreAnalitica
from server.integration_tier.data_access_manager import (
    DataAccessManager,
    imposta_dao,
)
from server.integration_tier.data_access_manager import (
    collezioni as col,
)
from server.integration_tier.data_access_manager.cifratura import (
    CifrarioAes256Gcm,
    CifrarioNullo,
)
from server.integration_tier.data_access_manager.cliente_firestore import inizializza_firestore
from server.presentation_tier.api_gateway_sicurezza import ApiGatewaySicurezza

_PW = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")
_SUFFISSO = base64.b16encode(os.urandom(3)).decode().lower()  # evita collisioni tra esecuzioni
_CHIAVE = b"leaf-mobility-test-key-32-bytes!"


def _ok(esito: bool, etichetta: str) -> bool:
    """! @brief Stampa l'esito di un controllo e lo restituisce.
    @param esito True se il controllo è superato.
    @param etichetta Nome del controllo.
    @return L'esito ricevuto.
    """
    print(f"  [{'PASS' if esito else 'FAIL'}] {etichetta}")
    return esito


def main() -> int:
    """! @brief Esegue i quattro controlli AG-SEC contro l'emulatore e riporta l'esito.
    @return 0 se tutti i controlli passano, 1 altrimenti.
    """
    cliente = inizializza_firestore()
    if cliente is None:
        print(
            "ERRORE: nessun client Firestore. Imposta FIRESTORE_EMULATOR_HOST e avvia l'emulatore."
        )  # noqa: E501
        return 2

    dao = DataAccessManager(cliente, CifrarioAes256Gcm(_CHIAVE))
    dao_raw = DataAccessManager(cliente, CifrarioNullo())  # legge i valori grezzi a riposo
    print(f"Connesso all'emulatore: {dao.connesso()} (suffisso run={_SUFFISSO})")

    risultati: list[bool] = []

    # ── AG-SEC-01 — formato KYC (logica pura, indipendente dalla persistenza) ──
    print("AG-SEC-01 — validazione formato KYC (IIN-6)")
    ekyc = GestoreProfiliEkyc()
    risultati.append(_ok(ekyc.formato_kyc_valido("patente.PDF"), "PDF/JPG/PNG ammessi"))
    risultati.append(
        _ok(not ekyc.formato_kyc_valido("malware.pdf.exe"), "estensione ingannevole bloccata")
    )

    # ── AG-SEC-02 — cifratura AES-256 at-rest su Firestore vero ──
    print("AG-SEC-02 — cifratura AES-256 at-rest (IIN-4)")
    uid = f"u_{_SUFFISSO}"
    dao.crea_account(
        "UT",
        f"giulia_{_SUFFISSO}@leaf.test",
        "hash",
        profilo={"nome": "Giulia", "codice_fiscale": "RSSGLI90A41A662S"},
        id_doc=uid,
    )
    dao.crea(
        col.DOCUMENTI_UFFICIALI,
        {"id_utente": uid, "numero_documento": "AB1234567", "storage_path": "gs://kyc/x.pdf"},
        id_doc=f"d_{_SUFFISSO}",
    )
    grezzo = dao_raw.leggi(col.UTENTI, uid) or {}
    grezzo_doc = dao_raw.leggi(col.DOCUMENTI_UFFICIALI, f"d_{_SUFFISSO}") or {}
    chiaro = dao.leggi(col.UTENTI, uid) or {}
    risultati.append(_ok(grezzo.get("codice_fiscale") != "RSSGLI90A41A662S", "CF cifrato a riposo"))
    risultati.append(
        _ok(grezzo_doc.get("numero_documento") != "AB1234567", "numero documento KYC cifrato")
    )
    risultati.append(
        _ok(chiaro.get("codice_fiscale") == "RSSGLI90A41A662S", "CF decifrato in lettura")
    )

    # ── AG-SEC-03 — MFA OP/PA contro il DAO live ──
    print("AG-SEC-03 — MFA obbligatorio OP/PA (IIN-9)")
    email_op = f"op_{_SUFFISSO}@leaf.test"
    dao.crea_account("OP", email_op, _PW.hash("Segreta!1"), id_doc=f"op_{_SUFFISSO}")
    imposta_dao(dao)
    gw = ApiGatewaySicurezza()
    esito = gw.autentica(email_op, "Segreta!1")
    risultati.append(
        _ok(bool(esito.get("mfaRichiesto")) and "token" not in esito, "OP: nessun token senza OTP")
    )
    otp = str(esito["otp_simulato"])
    ko = gw.verifica_mfa(str(esito["sessione"]), "000000" if otp != "000000" else "111111")
    risultati.append(_ok(not ko.get("valido"), "OTP errato: nessun token"))
    ok = gw.verifica_mfa(str(esito["sessione"]), otp)
    risultati.append(_ok(bool(ok.get("valido")) and "token" in ok, "OTP valido: token emesso"))

    # ── AG-SEC-04 — anonimizzazione analitiche PA ──
    print("AG-SEC-04 — anonimizzazione dati PA (IIN-15)")
    for i, (tipo, km) in enumerate([("ebike", 5.0), ("ebike", 3.0), ("ecar", 12.0)]):
        cliente.collection(col.CORSE).document(f"c_{_SUFFISSO}_{i}").set(
            {
                "stato": "conclusa",
                "tipo_mezzo": tipo,
                "km_percorsi": km,
                "durata_min": 15.0,
                "id_utente": f"utente_{i}",
                "id_mezzo": f"mezzo_{i}",
                "data_ora_inizio": "2026-06-01T10:00:00",
            }
        )
    righe = MotoreAnalitica(dao).aggrega_uso()
    anonimo = all("id_utente" not in r and "id_mezzo" not in r and "_id" not in r for r in righe)
    risultati.append(_ok(bool(righe) and anonimo, "output aggregato e privo di id individuali"))

    print(f"\nRisultato: {sum(risultati)}/{len(risultati)} controlli superati")
    return 0 if all(risultati) else 1


if __name__ == "__main__":
    sys.exit(main())
