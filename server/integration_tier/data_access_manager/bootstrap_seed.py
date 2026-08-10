"""! @file bootstrap_seed.py
@brief Seed/bootstrap idempotente delle collezioni Firestore (deliverable §4).

Popola le collezioni del modello §10 con dati iniziali coerenti, riusando dove
sensato gli identificativi dei mock dei client (mezzi BK/SC/CA/EM e stazioni di
ricarica con le stesse posizioni di `client/.../fleet_data.dart`, così la vista
server coincide con quella utente). Firestore è schemaless → nessun DDL.

**Idempotenza:** ogni documento usa un id naturale stabile e viene scritto con `set`
(sovrascrittura), quindi rieseguire il seed non duplica i dati. L'ordine di
inserimento rispetta l'integrità referenziale applicativa (prima i bersagli dei
reference, poi i documenti che li referenziano).

Uso (offline, contro l'emulatore Firestore):
@code
  export FIRESTORE_EMULATOR_HOST=localhost:8080
  python -m server.integration_tier.data_access_manager.bootstrap_seed
@endcode
"""

from __future__ import annotations

from passlib.context import CryptContext

from server.integration_tier.data_access_manager import DataAccessManager
from server.integration_tier.data_access_manager import collezioni as col
from server.integration_tier.data_access_manager.cifratura import cifrario_da_ambiente
from server.integration_tier.data_access_manager.cliente_firestore import inizializza_firestore
from server.runtime.impostazioni import RADICE_SERVER, _carica_dotenv

#! Contesto di hashing password (coerente con provisioning_op/DataAccessManager).
_CTX = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")
#! Password demo degli account di seed (conforme IIN-5). Solo per sviluppo/test.
PASSWORD_DEMO = "Leaf!2026"

#! Mezzi di seed: (codice, tipo, lat, lon, batteria, stato_operativo). Il codice è
#! l'id_doc (chiave naturale stabile per il seed idempotente); il registro mezzo_index
#! garantisce comunque l'unicità (§6.4). I mezzi sono distribuiti nell'area operativa di
#! Bari in prossimità delle stazioni di ricarica (§ _STAZIONI), con un'ampia base di mezzi
#! "disponibile" così che la mappa utente (UT.01/UT.05) risulti popolata.
_MEZZI: tuple[tuple[str, str, float, float, int, str], ...] = (
    # Flotta storica (stati misti: uso/manutenzione/scarico per le dashboard OP).
    ("SC-001", "monopattino", 41.1171, 16.8715, 78, "in_uso"),
    ("SC-009", "monopattino", 41.1188, 16.8742, 52, "disponibile"),
    ("SC-012", "monopattino", 41.1258, 16.8702, 90, "disponibile"),
    ("SC-014", "monopattino", 41.1205, 16.8655, 67, "disponibile"),
    ("SC-021", "monopattino", 41.1148, 16.8665, 41, "in_manutenzione"),
    ("SC-037", "monopattino", 41.1085, 16.8585, 9, "scarico"),
    ("BK-003", "ebike", 41.1278, 16.8665, 91, "in_uso"),
    ("BK-007", "ebike", 41.1060, 16.8560, 74, "disponibile"),
    ("BK-011", "ebike", 41.1242, 16.8718, 88, "in_uso"),
    ("BK-018", "ebike", 41.1162, 16.8718, 67, "disponibile"),
    ("BK-026", "ebike", 41.1185, 16.8730, 12, "scarico"),
    ("CA-007", "ecar", 41.1157, 16.8705, 65, "in_uso"),
    ("CA-011", "ecar", 41.1005, 16.8742, 82, "disponibile"),
    ("CA-015", "ecar", 41.0838, 16.8688, 48, "in_manutenzione"),
    ("CA-027", "ecar", 41.1135, 16.8638, 55, "disponibile"),
    ("EM-002", "emotorbike", 41.1052, 16.8702, 85, "in_uso"),
    ("EM-005", "emotorbike", 41.0855, 16.8628, 60, "disponibile"),
    ("EM-012", "emotorbike", 41.1190, 16.8640, 88, "disponibile"),
    # Mezzi aggiuntivi disponibili presso le stazioni di ricarica (mappa più popolata).
    ("SC-002", "monopattino", 41.1185, 16.8690, 84, "disponibile"),  # Bari Centrale
    ("BK-001", "ebike", 41.1178, 16.8682, 76, "disponibile"),  # Bari Centrale
    ("SC-003", "monopattino", 41.1248, 16.8740, 69, "disponibile"),  # Crollalanza
    ("CA-001", "ecar", 41.1255, 16.8730, 91, "disponibile"),  # Crollalanza
    ("BK-002", "ebike", 41.1262, 16.8680, 88, "disponibile"),  # C.so Vitt. Emanuele
    ("EM-001", "emotorbike", 41.1258, 16.8688, 73, "disponibile"),  # C.so Vitt. Emanuele
    ("SC-004", "monopattino", 41.1190, 16.8820, 62, "disponibile"),  # Corso Sydney
    ("BK-004", "ebike", 41.1196, 16.8830, 80, "disponibile"),  # Corso Sydney
    ("SC-005", "monopattino", 41.1122, 16.8638, 57, "disponibile"),  # Policlinico
    ("CA-002", "ecar", 41.1115, 16.8628, 85, "disponibile"),  # Policlinico
    ("BK-005", "ebike", 41.1060, 16.8745, 71, "disponibile"),  # Parco Due Giugno
    ("EM-003", "emotorbike", 41.1055, 16.8752, 66, "disponibile"),  # Parco Due Giugno
    ("SC-006", "monopattino", 41.1028, 16.8678, 90, "disponibile"),  # Poggiofranco Petroni
    ("BK-006", "ebike", 41.1023, 16.8670, 64, "disponibile"),  # Poggiofranco Petroni
    ("SC-007", "monopattino", 41.1343, 16.8360, 83, "disponibile"),  # Fiera del Levante
    ("CA-003", "ecar", 41.1349, 16.8352, 79, "disponibile"),  # Fiera del Levante
)

#! Stazioni di ricarica di seed: (id, lat, lon, colonnine, zona). Posizioni reali su Bari
#! fornite dal team (coordinate convertite da DMS a gradi decimali). Gli id CHG-01..CHG-10
#! sono chiavi naturali stabili: rieseguire il seed sovrascrive le stazioni precedenti
#! (gli id storici CHG-01/02/05/09 ricadono in questo intervallo → nessun documento orfano).
_STAZIONI: tuple[tuple[str, float, float, int, str], ...] = (
    ("CHG-01", 41.118083, 16.868694, 6, "Stazione Bari Centrale"),
    ("CHG-02", 41.125167, 16.873694, 4, "Lungomare Crollalanza"),
    ("CHG-03", 41.126028, 16.868278, 4, "Corso Vittorio Emanuele"),
    ("CHG-04", 41.119250, 16.882639, 4, "Corso Sydney"),
    ("CHG-05", 41.111889, 16.863278, 5, "Policlinico"),
    ("CHG-06", 41.105778, 16.874889, 3, "Parco Due Giugno"),
    ("CHG-07", 41.134611, 16.835722, 6, "Fiera del Levante"),
    ("CHG-08", 41.137056, 16.827222, 4, "Lungomare San Girolamo"),
    ("CHG-09", 41.102556, 16.867361, 3, "Poggiofranco / Via Petroni"),
    ("CHG-10", 41.097944, 16.854083, 3, "Poggiofranco / Via Caccuri"),
)

#! Piani abbonamento di seed: (id, nome, durata_giorni, prezzo_cent).
_PIANI: tuple[tuple[str, str, int, int], ...] = (
    ("piano-base", "LEAF Base", 30, 999),
    ("piano-plus", "LEAF Plus", 30, 1999),
    ("piano-annuale", "LEAF Annuale", 365, 14900),
)

#! Tecnici di seed: (id, nome, cognome, specializzazione).
_TECNICI: tuple[tuple[str, str, str, str], ...] = (
    ("tec-01", "Marco", "Greco", "elettronica"),
    ("tec-02", "Sara", "Lopez", "meccanica"),
)

#! Poligono dell'area operativa di Bari centro (lat, lon), per il geofencing.
_POLIGONO_BARI: tuple[tuple[float, float], ...] = (
    (41.135, 16.855),
    (41.135, 16.880),
    (41.105, 16.880),
    (41.105, 16.855),
)


def _attributi_mezzo(tipo: str) -> dict[str, object]:
    """! @brief Costruisce la map `attributi_specifici` in base al tipo di mezzo (§3).
    @param tipo Tipo del mezzo (ebike/monopattino/ecar/emotorbike).
    @return Map dei campi specifici del sottotipo (chiavi snake_case, §3).
    """
    if tipo == "ebike":
        return {"tipo_telaio": "city", "assistenza_pedalata": True, "num_marce": 7}
    if tipo == "monopattino":
        return {"peso_max_utente_kg": 120, "num_ruote": 2}
    if tipo == "ecar":
        return {"targa": "BA000XX", "num_posti": 4, "capacita_bagagliaio_l": 280}
    return {"targa": "BA111YY", "cilindrata_equivalente_cc": 125, "num_caschi": 2}


def _assicura_account(
    dao: DataAccessManager,
    ruolo: str,
    email: str,
    password_hash: str,
    *,
    profilo: dict[str, object],
    username: str,
    id_doc: str,
) -> None:
    """! @brief Crea l'account se assente; se gia' presente lo lascia (reset dispositivi UT).

    Rende il seed idempotente sugli account: a differenza di @ref DataAccessManager.crea_account
    (che solleva ViolazioneUnicita su email gia' registrata), salta la creazione quando
    l'account esiste gia'. Per gli utenti UT azzera inoltre il contatore `dispositivi_attivi`
    (IIN-14), liberando eventuali registrazioni rimaste appese durante i test.

    @param dao DataAccessManager connesso.
    @param ruolo Ruolo RBAC (UT/OP/PA).
    @param email Email di accesso (chiave di unicita').
    @param password_hash Hash della password demo.
    @param profilo Campi del profilo (chiave keyword-only).
    @param username Username (chiave keyword-only).
    @param id_doc Id desiderato dell'account/profilo (chiave keyword-only).
    @return Nessuno.
    """
    if dao.leggi_account_per_email(email) is None:
        dao.crea_account(
            ruolo, email, password_hash, profilo=profilo, username=username, id_doc=id_doc
        )
        return
    if ruolo == "UT":
        dao.aggiorna(col.UTENTI, id_doc, {"dispositivi_attivi": 0})


def esegui_seed(dao: DataAccessManager) -> dict[str, int]:
    """! @brief Popola le collezioni con i dati iniziali (idempotente).

    Inserisce in ordine di dipendenza: piani, tecnici, account (UT/OP/PA), aree,
    flotte, mezzi, stazioni di ricarica. Tutte le scritture usano id naturali stabili.

    @param dao DataAccessManager connesso (client reale, emulatore o fake).
    @return Mappa collezione → numero di documenti scritti.
    @throws ErrorePersistenza Se il DAO non e' connesso a Firestore.
    """
    conteggi: dict[str, int] = {}

    for id_piano, nome, durata, prezzo_cent in _PIANI:
        dao.crea(
            col.PIANI_ABBONAMENTO,
            {"nome": nome, "durata_giorni": durata, "prezzo_cent": prezzo_cent},
            id_doc=id_piano,
        )
    conteggi[col.PIANI_ABBONAMENTO] = len(_PIANI)

    for id_tec, nome, cognome, spec in _TECNICI:
        dao.crea(
            col.TECNICI,
            {
                "nome": nome,
                "cognome": cognome,
                "specializzazione": spec,
                "stato": "disponibile",
            },
            id_doc=id_tec,
        )
    conteggi[col.TECNICI] = len(_TECNICI)

    hash_pw = _CTX.hash(PASSWORD_DEMO)
    _assicura_account(
        dao,
        "UT",
        "utente.demo@leaf.test",
        hash_pw,
        profilo={"nome": "Giulia", "cognome": "Rossi", "saldo_km": 50.0, "stato_kyc": "verificato"},
        username="giulia.rossi",
        id_doc="ut-demo",
    )
    _assicura_account(
        dao,
        "OP",
        "operatore.demo@leaf.test",
        hash_pw,
        profilo={"nome": "Luca", "cognome": "Bianchi", "codice_operatore": "OP-001"},
        username="op.bianchi",
        id_doc="op-demo",
    )
    _assicura_account(
        dao,
        "PA",
        "pa.demo@leaf.test",
        hash_pw,
        profilo={
            "ente": "Comune di Zootropolis",
            "email_istituzionale": "mobilita@comune.test",
        },
        username="pa.zootropolis",
        id_doc="pa-demo",
    )
    conteggi[col.ACCOUNT] = 3

    dao.crea(
        col.AREE_LIMITATE,
        {
            "nome": "Bari Centro — Area Operativa",
            "tipo": "area_operativa",
            "geometria": [{"lat": la, "lon": lo} for la, lo in _POLIGONO_BARI],
            "stato": "attiva",
            "creata_da": "op-demo",
        },
        id_doc="area-bari-centro",
    )
    dao.crea(
        col.AREE_LIMITATE,
        {
            "nome": "Bari Vecchia — Slow Zone",
            "tipo": "slow_zone",
            "geometria": [{"lat": la, "lon": lo} for la, lo in _POLIGONO_BARI],
            "limite_velocita_kmh": 10,
            "stato": "attiva",
            "creata_da": "pa-demo",
        },
        id_doc="area-bari-slow",
    )
    conteggi[col.AREE_LIMITATE] = 2

    dao.crea(
        col.FLOTTE,
        {
            "nome": "Flotta Bari Centro",
            "id_operatore_responsabile": "op-demo",
            "id_area_operativa": "area-bari-centro",
            "soglia_minima_mezzi": 5,
        },
        id_doc="flotta-bari-centro",
    )
    conteggi[col.FLOTTE] = 1

    for codice, tipo, lat, lon, batteria, stato in _MEZZI:
        if dao.leggi(col.MEZZI, codice) is not None:
            # Mezzo gia' presente: ripristina stato operativo e batteria del seed,
            # riportando a "disponibile" i mezzi rimasti appesi (prenotato/in_uso)
            # nelle sessioni di test. La posizione/geo resta quella della prima creazione.
            dao.aggiorna(
                col.MEZZI,
                codice,
                {"stato_operativo": stato, "livello_batteria_pct": batteria},
            )
        else:
            dao.crea_mezzo(
                tipo,
                {
                    "codice_identificativo": codice,
                    "stato_operativo": stato,
                    "livello_batteria_pct": batteria,
                    "lat": lat,
                    "lon": lon,
                    "timestamp_posizione": None,
                    "id_flotta": "flotta-bari-centro",
                },
                attributi=_attributi_mezzo(tipo),
                id_doc=codice,
            )
    conteggi[col.MEZZI] = len(_MEZZI)

    for id_staz, lat, lon, colonnine, zona in _STAZIONI:
        dao.crea(
            col.STAZIONI_RICARICA,
            {
                "nome": zona,
                "lat": lat,
                "lon": lon,
                "num_colonnine": colonnine,
                "num_disponibili": colonnine,
                "stato": "attiva",
            },
            id_doc=id_staz,
        )
    conteggi[col.STAZIONI_RICARICA] = len(_STAZIONI)

    return conteggi


def main() -> int:
    """! @brief Punto d'ingresso CLI: costruisce il client dall'ambiente ed esegue il seed.
    @return Codice di uscita (0 = ok; 1 = persistenza non configurata).
    """
    # Carica server/.env quando il seed gira da CLI (il runtime lo fa gia' da solo).
    _carica_dotenv(RADICE_SERVER / ".env")
    cliente = inizializza_firestore()
    if cliente is None:
        print(
            "Persistenza non configurata: valorizzare FIRESTORE_EMULATOR_HOST (dev/test) "
            "o LEAF_FIREBASE_CRED (cloud) e installare firebase-admin."
        )
        return 1
    conteggi = esegui_seed(DataAccessManager(cliente, cifrario_da_ambiente()))
    totale = sum(conteggi.values())
    print(f"Seed completato: {totale} documenti")
    for collezione, numero in conteggi.items():
        print(f"  - {collezione}: {numero}")
    return 0


if __name__ == "__main__":  # pragma: no cover - punto d'ingresso CLI
    raise SystemExit(main())
