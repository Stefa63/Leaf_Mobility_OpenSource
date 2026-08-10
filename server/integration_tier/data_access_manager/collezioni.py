"""! @file collezioni.py
@brief Mappa del modello fisico Firestore allineata allo schema logico (Report/schema_logico_db.md).

Costanti che traducono lo **schema logico ER** (`Report/schema_logico_db.md`, fonte
autoritativa) nel document model di Firestore. Centralizza i nomi (in `snake_case`,
§1) delle collezioni e subcollezioni, dei registri di unicità (§4), il discriminante
del tipo di mezzo (Decisione B), la mappa ruolo→collezione della generalizzazione
Account a **chiave condivisa** (§6.1 #1-3), l'elenco dei campi sensibili 🔒 (§6.5) e
l'integrità referenziale applicativa (§6.3). Nessuna logica: sola configurazione,
usata dal @ref DataAccessManager.

@note **Account normalizzato** (≠ scheletro storico con map `datiUtente/...` embedded):
      `account` porta solo le credenziali e i campi di lifecycle; il profilo vive in
      `utenti`/`operatori`/`amministrazioni_pubbliche` con **document ID = id_account**
      (relazione 1:1 a chiave condivisa, §6.1).
@note **`mezzi.posizione`**: lo schema (§6.5) la marca 🔒. Decisione: la coordinata fine
      è cifrata AES-256 (IIN-4) come leaf JSON `posizione`; il `geohash` resta in chiaro
      a grana di cella (non re-identificante, §6.7) ed è il campo di range-query per la
      prossimità. La geo-query non si rompe: il `geohash` filtra i candidati, la
      distanza esatta si calcola sulla `posizione` decifrata del solo set ristretto.
"""

from __future__ import annotations

# ── Collezioni top-level (schema §2/§6.2, naming snake_case §1) ────────────────
#! Account: credenziali + lifecycle. Generalizzazione a chiave condivisa con i profili.
ACCOUNT = "account"
#! Profilo Utente (UT): document ID = id_account (§6.1 #1).
UTENTI = "utenti"
#! Profilo Operatore/Tecnico-gestione (OP): document ID = id_account (§6.1 #2).
OPERATORI = "operatori"
#! Profilo Amministrazione Pubblica (PA): document ID = id_account (§6.1 #3).
AMMINISTRAZIONI_PUBBLICHE = "amministrazioni_pubbliche"
#! Tecnici manutentori (collezione autonoma, ≠ account).
TECNICI = "tecnici"
#! Documenti ufficiali KYC (collezione isolata top-level, §2).
DOCUMENTI_UFFICIALI = "documenti_ufficiali"
#! Mezzi (generalizzazione con discriminante tipo_mezzo + map attributi_specifici).
MEZZI = "mezzi"
FLOTTE = "flotte"
STAZIONI_RICARICA = "stazioni_ricarica"
PRENOTAZIONI = "prenotazioni"
CORSE = "corse"
PAGAMENTI = "pagamenti"
FATTURE = "fatture"
ABBONAMENTI = "abbonamenti"
PIANI_ABBONAMENTO = "piani_abbonamento"
PROMOZIONI = "promozioni"
AREE_LIMITATE = "aree_limitate"
TICKET_ASSISTENZA = "ticket_assistenza"
TICKET_MANUTENZIONE = "ticket_manutenzione"
MANUTENZIONI = "manutenzioni"
#! Soglie di allerta configurate dall'operatore (mezzi minimi per area / batteria, OP.02/OP.22).
SOGLIE = "soglie"
#! Notifiche utente/broadcast (scadenza prenotazione UT.15, interruzione servizio UT.19).
NOTIFICHE = "notifiche"
STATISTICHE_USO = "statistiche_uso"
STATISTICHE_AMBIENTALI = "statistiche_ambientali"
AUDIT_LOG = "audit_log"
SEGNALAZIONI_EMERGENZA = "segnalazioni_emergenza"

#! Elenco completo delle collezioni top-level dello schema logico (§6.2).
COLLEZIONI_TOP_LEVEL: tuple[str, ...] = (
    ACCOUNT,
    UTENTI,
    OPERATORI,
    AMMINISTRAZIONI_PUBBLICHE,
    TECNICI,
    DOCUMENTI_UFFICIALI,
    MEZZI,
    FLOTTE,
    STAZIONI_RICARICA,
    PRENOTAZIONI,
    CORSE,
    PAGAMENTI,
    FATTURE,
    ABBONAMENTI,
    PIANI_ABBONAMENTO,
    PROMOZIONI,
    AREE_LIMITATE,
    TICKET_ASSISTENZA,
    TICKET_MANUTENZIONE,
    MANUTENZIONI,
    SOGLIE,
    NOTIFICHE,
    STATISTICHE_USO,
    STATISTICHE_AMBIENTALI,
    AUDIT_LOG,
    SEGNALAZIONI_EMERGENZA,
)

# ── Registri di unicità (struttura fisica §4, NON nello schema logico) ─────────
# Firestore non offre UNIQUE: l'unicità (UK §6.4) si garantisce con collezioni-registro
# a chiave deterministica scritte in transazione (IIN-1). Non sono in COLLEZIONI_TOP_LEVEL
# (sono artefatti fisici): vi si accede solo dai metodi transazionali del DataAccessManager.
#! Registro email→id_account (account.email univoca, §6.4).
EMAIL_INDEX = "email_index"
#! Registro username→id_account (account.username univoco, §6.4).
USERNAME_INDEX = "username_index"
#! Registro codice_identificativo→id_mezzo (mezzi.codice_identificativo univoco, §6.4).
MEZZO_INDEX = "mezzo_index"
#! Store dei token di reset password (IIN-11): artefatto fisico effimero, NON nello schema
#! logico. Document ID = id_account (una nuova richiesta sostituisce la precedente → monouso).
#! Accesso solo via i metodi dedicati del DataAccessManager (come i registri di unicità).
RESET_TOKEN = "reset_token"

# ── Subcollezioni (composizione/sottocoll., schema §1/§6.2) ────────────────────
#! Subcollezioni di utenti/{id} (metodi di pagamento, dispositivi ≤3 attivi IIN-14).
SUB_METODI_PAGAMENTO = "metodi_pagamento"
SUB_DISPOSITIVI = "dispositivi"
#! Subcollezione di mezzi/{id} (telemetria ad alta scrittura, OP.07/OP.14).
SUB_EVENTI_TELEMETRIA = "eventi_telemetria"
#! Subcollezione di corse/{id} (tracciato GPS, OP.07).
SUB_PUNTI_TRACCIA = "punti_traccia"

#! Subcollezioni ammesse per ciascuna collezione padre (integrità dei percorsi).
SUBCOLLEZIONI: dict[str, tuple[str, ...]] = {
    UTENTI: (SUB_METODI_PAGAMENTO, SUB_DISPOSITIVI),
    MEZZI: (SUB_EVENTI_TELEMETRIA,),
    CORSE: (SUB_PUNTI_TRACCIA,),
}

# ── Generalizzazione Account a chiave condivisa (§6.1) ─────────────────────────
#! Campo discriminante del ruolo RBAC su account (UT/OP/PA).
DISCR_RUOLO = "ruolo"
#! Ruolo → collezione del profilo (document ID condiviso con account).
MAP_RUOLO_COLLEZIONE: dict[str, str] = {
    "UT": UTENTI,
    "OP": OPERATORI,
    "PA": AMMINISTRAZIONI_PUBBLICHE,
}
#! Ruoli RBAC ammessi (copertura totale ed esclusiva della gerarchia Account).
RUOLI_AMMESSI: frozenset[str] = frozenset(MAP_RUOLO_COLLEZIONE)

# ── Generalizzazione Mezzo (Decisione B): discriminante + map attributi ────────
#! Campo discriminante del tipo di mezzo su mezzi.
DISCR_TIPO_MEZZO = "tipo_mezzo"
#! Nome della map embedded dei campi specifici del sottotipo di mezzo (§3).
MAP_ATTRIBUTI_MEZZO = "attributi_specifici"
#! Tipi di mezzo ammessi (copertura totale ed esclusiva della gerarchia Mezzo, §3).
TIPI_MEZZO_AMMESSI: frozenset[str] = frozenset({"ebike", "monopattino", "ecar", "emotorbike"})

# ── Campi sensibili 🔒 → cifratura AES-256 applicativa (IIN-4, schema §6.5) ─────
# Percorsi in notazione puntata (es. "attributi_specifici.targa" = chiave annidata).
# La `password_hash` NON è qui: è già un hash non reversibile (Passlib) — cifrarla
# impedirebbe solo la verifica e non aggiunge riservatezza (lo schema §6.5 lo annota
# esplicitamente: "già hash Passlib"). La `posizione` dei mezzi È invece cifrata
# (coordinata fine), mentre il geohash resta in chiaro (vedi nota di modulo).
CAMPI_SENSIBILI: dict[str, tuple[str, ...]] = {
    UTENTI: ("nome", "cognome", "data_nascita", "codice_fiscale", "telefono", "indirizzo"),
    DOCUMENTI_UFFICIALI: ("numero_documento", "storage_path"),
    MEZZI: ("posizione", "attributi_specifici.targa"),
    CORSE: ("posizione_partenza", "posizione_arrivo", "tracciato_gps"),
    SEGNALAZIONI_EMERGENZA: ("posizione",),
}
#! Campi sensibili delle subcollezioni (chiave = nome subcollezione, §6.5).
CAMPI_SENSIBILI_SUB: dict[str, tuple[str, ...]] = {
    SUB_METODI_PAGAMENTO: ("token_provider", "intestatario"),
    SUB_EVENTI_TELEMETRIA: ("posizione",),
    SUB_PUNTI_TRACCIA: ("punto",),
}

# ── Integrità referenziale applicativa (§6.3): reference id_X → collezione ──────
# Niente FK del DBMS: il DataAccessManager verifica (best-effort) che i reference
# valorizzati puntino a documenti esistenti. Mappa: collezione → {campo: collezione bersaglio}.
# Solo i reference obbligatori/opzionali verso collezioni top-level (i path delle
# subcollezioni — es. pagamenti.id_metodo — non sono verificati qui).
RIFERIMENTI: dict[str, dict[str, str]] = {
    DOCUMENTI_UFFICIALI: {"id_utente": UTENTI},
    MEZZI: {"id_flotta": FLOTTE},
    FLOTTE: {"id_operatore_responsabile": OPERATORI, "id_area_operativa": AREE_LIMITATE},
    PRENOTAZIONI: {"id_utente": UTENTI, "id_mezzo": MEZZI},
    CORSE: {
        "id_utente": UTENTI,
        "id_mezzo": MEZZI,
        "id_prenotazione": PRENOTAZIONI,
        "id_promozione": PROMOZIONI,
    },
    PAGAMENTI: {"id_utente": UTENTI, "id_corsa": CORSE, "id_abbonamento": ABBONAMENTI},
    FATTURE: {"id_pagamento": PAGAMENTI},
    ABBONAMENTI: {"id_utente": UTENTI, "id_piano": PIANI_ABBONAMENTO},
    PROMOZIONI: {"creata_da": OPERATORI, "id_area": AREE_LIMITATE},
    AREE_LIMITATE: {"creata_da": ACCOUNT},
    TICKET_ASSISTENZA: {"id_utente": UTENTI, "id_operatore": OPERATORI, "id_corsa": CORSE},
    TICKET_MANUTENZIONE: {
        "id_mezzo": MEZZI,
        "id_operatore_creatore": OPERATORI,
        "id_tecnico": TECNICI,
    },
    MANUTENZIONI: {"id_mezzo": MEZZI, "id_tecnico": TECNICI, "id_ticket_man": TICKET_MANUTENZIONE},
    SEGNALAZIONI_EMERGENZA: {"id_utente": UTENTI, "id_corsa": CORSE},
    AUDIT_LOG: {"id_account": ACCOUNT},
}

# ── Campi denormalizzati 📎 (§6.6): copia di lettura riallineata alla create ────
# Sorgente: mezzi. Riallineamento alla create (codice immutabile). Usati dal
# DataAccessManager per popolare la copia di lettura sui documenti ospiti.
#! Collezioni che denormalizzano codice_identificativo_mezzo + tipo_mezzo dai mezzi.
DENORM_MEZZO_COMPLETO: frozenset[str] = frozenset({PRENOTAZIONI, CORSE})
#! Collezioni/subcollezioni che denormalizzano il solo codice_identificativo_mezzo.
DENORM_MEZZO_CODICE: frozenset[str] = frozenset({TICKET_MANUTENZIONE, SUB_EVENTI_TELEMETRIA})
