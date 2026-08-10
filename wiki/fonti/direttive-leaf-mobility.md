---
tipo: fonte
creato: 2026-06-12
aggiornato: 2026-06-25
tag: [leaf-mobility, direttive, governance, architettura]
fonti: [raw/2026-06-12-direttive-leaf-mobility.md]
---

# Direttive LEAF Mobility (snapshot 12/06/2026)

> Fonte: [raw/2026-06-12-direttive-leaf-mobility.md](../raw/2026-06-12-direttive-leaf-mobility.md) — snapshot verbatim del file direttivo unico e autoritativo del progetto [[leaf-mobility]] (all'epoca `directives/CLAUDE.md`; dal 12/06/2026 il canone vive in `wiki/DIRECTIVES.md`, con shim per-modello `CLAUDE.md`/`GeminiV1.md`). Il file vivo evolve: ad ogni revisione significativa va ingerito un nuovo snapshot datato.

## In una frase

Il contratto operativo completo del progetto d'esame: cosa costruire (piattaforma smart mobility per Zootropolis), come costruirlo ([[architettura-three-tier]], Flutter senza MVC, stack Python/FastAPI + **Cloud Firestore** NoSQL server-mediato) e con quale disciplina (DOE, CI/CD automatica, SQALE, prompt-logging, commit approvati).

> **⚠️ Nota persistenza:** la versione originaria delle direttive citava **PostgreSQL/PostGIS + SQLAlchemy**; dal 22/06/2026 il team ha **superato** quella scelta a favore di **Cloud Firestore** (NoSQL document store, `firebase-admin`, accesso server-mediato). Il canone aggiornato è in `wiki/DIRECTIVES.md` §6/§13. NON usare SQL/SQLAlchemy.

## Struttura del documento (19 sezioni)

| §§ | Contenuto |
|---|---|
| 1–2 | Visione del sistema e framework **DOE** (Directive · Orchestration · Execution): le regole stanno in `directives/`, l'agente orchestra, la complessità va nel codice deterministico |
| 3–5 | Regole di condotta dell'agente (chiedere permesso, mai refactoring/rinomine non richiesti, **mai MVC**, documentazione in italiano), vincoli architetturali e albero delle directory |
| 6–8 | Stack tecnologico, standard di codifica (Doxygen obbligatorio, ISO 25000, AES-256, KYC solo PDF/JPG/PNG) e schema di versioning/APK |
| 9–10 | Protocollo di **prompt-logging** (ID sequenziali a 6 cifre, testo verbatim, file per sprint) e pianificazione sprint (Sprint 1: UI dei due client, scadenza 24/05/2026; Sprint 3 dal 10/06/2026) |
| 11–13 | Auto-apprendimento dagli errori, protocollo **CI/CD di sessione** (matrice AG-CI-01…09 + AG-SEC-01…04, max 3 iterazioni di autocorrezione, report obbligatorio) e sistemi esterni black-box |
| 14–15 | Requisiti funzionali: **59 user story** (25 UT + 12 AP + 22 OP) e **24 requisiti non funzionali IIN** — in italiano, da non tradurre |
| 16–18 | Glossario, governance del **debito tecnico SQALE** (soglia 20% = blocco sviluppo) e protocollo git di sessione (sync a inizio, commit proposto e approvato a fine, CHANGELOG) |
| 19 | Protocollo di questa wiki (LLM Wiki "second brain") |

## Punti cardine da ricordare

1. **Tre ruoli RBAC:** UT (utente finale), OP (operatore del servizio), AP/PA (amministrazione pubblica). MFA obbligatoria per OP/AP, opzionale per UT.
2. **Architettura server bloccata:** [[architettura-three-tier]] esclusiva — Presentation / Business / Integration, senza import tra tier non adiacenti; il `sistemaTPL` resta integrato in `gateway_routing`, mai modulo separato.
3. **Vincoli di sicurezza ricorrenti:** AES-256 at rest, log senza PII, KYC limitato a PDF/JPG/PNG, anonimizzazione dei dati per le dashboard AP, audit log immutabile (IIN-13).
4. **Discipline di processo:** ogni sessione inizia con sync git (§18.1) e check CI/CD (§12); ogni prompt di sviluppo è loggato (§9); ogni commit è approvato dallo sviluppatore (§18.2); debito tecnico sorvegliato col metodo SQALE (§17).
5. **Prestazioni chiave (IIN):** dashboard ≤ 5 s di refresh, SOS ≤ 5 s, notifiche critiche ≤ 10 s, propagazione geofencing ≤ 30 s, precisione tracciamento 99%.
6. **Diagrammi UML** (componenti, casi d'uso, classi, 16 sequenze) vivono in `wiki/raw/assets/` dal 12/06/2026 (in precedenza in `directives/`, cartella poi eliminata).

## Pagine collegate

- [[leaf-mobility]] — la scheda del progetto
- [[architettura-three-tier]] — il vincolo architetturale centrale
- [[llm-wiki-pattern]] — il §19 è l'istanza locale di quel pattern
