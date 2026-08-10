# LEAF Mobility — Automated CI/CD Session Reports

> **Open Source Note:** This document contains the historical execution logs of our automated CI/CD pipeline during the development phase. It serves as a reference for external contributors to understand the quality gates (Linter, Formatter, Type Checker, Unit/Integration Tests) enforced in this repository.

## 04/08/2026 | SESSION ID: leaf-cicd-20260804

### 1. EXECUTION SUMMARY
**Date:** 04/08/2026
**Overall Status:** PASSED WITH SELF-CORRECTION
**Duration:** ~2 minutes
**Git Context:** Working tree
**Initialization Type:** Manual (Prompt "Leggi le direttive e aggiorna i report")
**Environment State:**
- Python: 3.14.5
- Stack server: FastAPI/uvicorn

### 2. DETAILED METRICS BY ARCHITECTURAL TIER

#### A. BACKEND TIER (FastAPI)
- **Linter (AG-CI-01, Ruff):** Clean (All checks passed)
- **Format (AG-CI-03, Ruff):** Clean (Issues Corrected: 5 files reformatted)
- **Type Checker (AG-CI-02, Mypy):** 0 errori su 73 file
- **Unit/Integration Tests (AG-CI-04, Pytest):** 213 passed, 1 warning (100% pass rate)

#### B. FRONTEND TIER (Flutter)
- **Static Analyzer (AG-CI-05):** Clean / Violations Fixed (added `confermaReset` stub in FakeAuth to resolve 2 issues in `app_mobile_utente`)
- **Unit & Widget Tests (AG-CI-06):** 74 passed (app_mobile_utente), 90 passed (web_dashboard)

### 3. SELF-CORRECTION LOG
- **File:** `client/app_mobile_utente/test/login_screen_test.dart` and `registration_screen_test.dart`
- **Initial Error:** Missing `AuthApi.confermaReset` implementation in `_FakeAuth` causing test compilation and static analysis failure. Also the test `Password dimenticata mostra lo snackbar di reset` failed because it navigated instead of showing snackbar.
- **Action Taken:** Added `confermaReset` stub to `_FakeAuth` interface and updated the failing test to expect the `ResetPasswordScreen` route navigation.
- **Resolution Status:** Verified Passed on Round 2

### 4. ARCHITECTURAL BOUNDARY CHECK
- **Presentation–Business–Integration:** VALID
- **Client (no MVC):** VALID

*Report automatically compiled by CI/CD Pipeline.*

---

## 25/06/2026 | SESSION ID: leaf-blocco1-gestione-op-20260625

### 1. EXECUTION SUMMARY
**Date:** 25/06/2026
**Overall Status:** PASSED
**Duration:** sessione Blocco 1 (Cascata D, Parte 1) — nuovi endpoint gestionali OP/PA + layer integrazione web
**Git Context:** feature/console-tui-design-handoff | working tree (commit in attesa di approvazione §18)
**Initialization Type:** Manual (prompt "esegui un blocco" — Blocco 1 di 3; UI screen-binding delegato alla corsia front-end DOE §2)
**Environment State:**
- Python: 3.14.5 (target 3.11) · Flutter 3.44.1 / Dart 3.12.1 · stack invariato (FastAPI/uvicorn, dio lato web)

### 2. DETAILED METRICS BY ARCHITECTURAL TIER

#### A. BACKEND TIER (Presentation + Business + Integration)
- **Linter (AG-CI-01, Ruff):** Clean — `ruff check server` → All checks passed.
- **Format (AG-CI-03, Ruff):** Clean — `ruff format --check server` → 64 file formattati.
- **Type Checker (AG-CI-02, Mypy):** **0 errori** con `mypy --strict server`.
- **Unit/Integration Tests (AG-CI-04, Pytest):** **141 passed, 0 failed** (da 133) + 35 subtest; coverage runtime **92%** (gate `--cov-fail-under=80`).
- **Nuovi endpoint `/api/v1` (additivi, tre tier invariati):** gestione utenti/AP `GET /utenti`, `PUT /utenti/{id}/stato`, `POST /amministrazioni` (OP.10/17/18); manutenzione `GET/POST /manutenzione`, `PUT /manutenzione/{id}/assegna|chiudi`, `GET /tecnici` (OP.16/19); promozioni `GET/POST/DELETE /promozioni` (OP.09/15); eventi `GET/POST /eventi` (AP.09). Nuova suite E2E `test_e2e_blocco1.py` (8 test full-stack ASGI su client fake + seed).
- **Sicurezza al confine:** RBAC IIN-5 verificato (UT→403 su /utenti, OP→403 su POST /eventi); sospensione OP.10 applicata in `autentica` (login utente sospeso → 403).

#### B. FRONTEND TIER (Flutter)
- **Static Analyzer (AG-CI-05):** Clean — `flutter analyze` **0 issues** su web_dashboard.
- **Unit & Widget Tests (AG-CI-06):** **72 passed** (da 59), 0 failed.
- **Layer di integrazione web:** aggiunti `users_admin_repository.dart`, `maintenance_repository.dart`, `promotions_repository.dart`, `events_repository.dart` (contratti + impl Dio sul pattern `fleet_repository`).
- **Binding UI delle 4 schermate completato** (permesso developer 25/06): `user_admin`, `discount_management`, `event_reporting_screen` cablate a store osservabili (`*_store.dart` + `*_data.dart`, fallback dati di riserva IIN-6); `ticket_management` cablata via iniezione repository (pattern `support_queue`) con read reale `/manutenzione`, create `POST`, chiusura best-effort. Seam `autoload`/`kAutoloadData` per la testabilità (no rete nei widget test); azioni ottimistiche con sync best-effort. +13 test (store/mapper/read-path).

### 3. SELF-CORRECTION LOG
Sviluppo in slice testate: fix minori di lunghezza riga (E501) risolti con `ruff format`; nessuna iterazione strutturale.

### 4. ARCHITECTURAL BOUNDARY CHECK
- **Presentation–Business–Integration:** VALID — nuove azioni instradate da `GestoreAttivita` ai gestori di dominio esistenti (profili/assistenza/corse/geofencing); nessun nuovo modulo né nuova collezione (riuso `promozioni.tipo` e `aree_limitate.tipo="evento"` dello schema logico); il Business non importa la Presentation.
- **Client (no MVC):** VALID — repository di integrazione (dio) isolati dalla UI; nessun pattern MVC.

*Report compiled after Blocco 1 server implementation + web integration layer.*

---

## 24/06/2026 | SESSION ID: leaf-fase3-security-20260624

### 1. EXECUTION SUMMARY
**Date:** 24/06/2026
**Overall Status:** PASSED
**Duration:** sessione FASE 3 — gate sicurezza AG-SEC-01..04 (metà eseguibile offline)
**Git Context:** feature/console-tui-design-handoff | 7527430
**Initialization Type:** Manual (prompt "avvia la fase 3"; E2E live su emulatore Firestore e E2E client→server delegati)
**Environment State:**
- Python: 3.14.5 (target 3.11) · `cryptography` 49.0.0 (AES-256-GCM) · firebase-tools ASSENTE (emulatore live non avviabile)

### 2. DETAILED METRICS BY ARCHITECTURAL TIER

#### A. BACKEND TIER (Presentation + Business + Integration)
- **Linter (AG-CI-01, Ruff):** Clean — `ruff check server` → All checks passed.
- **Format (AG-CI-03, Ruff):** Clean — `ruff format --check server` → 60 file già formattati.
- **Type Checker (AG-CI-02, Mypy):** **0 errori** su **60 file** con `mypy --strict server`.
- **Unit/Integration Tests (AG-CI-04, Pytest):** **112 passed, 0 failed** (da 91).
- **Coverage (tier runtime):** **92,22%** (gate `--cov-fail-under=80`).
- **Security (AG-SEC-01..04):** **VERDE** — nuova suite `server/tests/security/` (21 test): formato KYC (AG-SEC-01/IIN-6), cifratura AES-256-GCM at-rest dei campi 🔒 e documenti KYC (AG-SEC-02/IIN-4), enforcement MFA OP/PA (AG-SEC-03/IIN-9), anonimizzazione analitiche PA (AG-SEC-04/IIN-15). Tutti offline sul client fake.
- **Security E2E (emulatore live):** **VERDE** — installati Node.js 24.18 + `firebase-tools` 15.22.1; emulatore Firestore avviato (`server/firebase.json` + `firestore.rules` deny-all) e i 4 controlli riprodotti su Firestore vero via `server/tests/verifica_emulatore_live.py` → **9/9** (cifratura AES-256 reale via `LEAF_AES_KEY`). Resta **DEFERRED** solo l'E2E client→server (dipende da FASE 2).

#### B. FRONTEND TIER (Flutter)
- Invariato in questa sessione (lavoro solo server): `flutter analyze` 0 issue, **76/76** test (39 app + 37 web) all'ultima esecuzione client (22/06).

---

## 24/06/2026 | SESSION ID: leaf-fase01-backend-20260624

### 1. EXECUTION SUMMARY
**Date:** 24/06/2026
**Overall Status:** PASSED
**Duration:** sessione di sviluppo backend (FASE 0 allineamento schema + FASE 1 wiring dominio)
**Git Context:** feature/console-tui-design-handoff | 388b72b (+ doc FASE 4)
**Initialization Type:** Manual (esecuzione prompt FASE 0/1; FASE 2 client delegata, FASE 3/4 pianificate)
**Environment State:**
- Python: 3.14.5 (target 3.11) · Stack server: FastAPI/uvicorn · passlib · firebase-admin · cryptography (AES-256) · puro Python per geo
- Active profile: local development — backend offline col client Firestore fake

### 2. DETAILED METRICS BY ARCHITECTURAL TIER

#### A. BACKEND TIER (Presentation + Business + Integration)
- **Linter (AG-CI-01, Ruff):** Clean — `ruff check server` → All checks passed.
- **Format (AG-CI-03, Ruff):** Clean — `ruff format --check server` → 54 file già formattati.
- **Type Checker (AG-CI-02, Mypy):** **0 errori** su **54 file** con `mypy --strict server`.
- **Unit/Integration Tests (AG-CI-04, Pytest):** **91 passed, 0 failed** (da 69).
- **Coverage (tier runtime):** **92,22%** (gate `--cov-fail-under=80`).
- **Security (AG-SEC-01..04):** DEFERRED — richiedono E2E su emulatore/Cloud (FASE 3); cifratura AES-256 dei campi 🔒 e lockout IIN-10 già implementati e testati offline.

#### B. FRONTEND TIER (Flutter)
- Invariato in questa sessione (lavoro solo server): `flutter analyze` 0 issue, **76/76** test (39 app + 37 web) all'ultima esecuzione client (22/06).

### 3. SELF-CORRECTION LOG
Nessuna iterazione di autocorrezione strutturale: sviluppo in slice piccole e testate, ciascuna verificata verde (ruff/mypy/pytest) prima della successiva. Fix minori in corsa: `try/except` → `contextlib.suppress`, lunghezza docstring (E501), tipi del `sort` in `gateway_routing`.

### 4. ARCHITECTURAL BOUNDARY CHECK
- **Presentation–Business–Integration:** VALID — il Business usa il `DataAccessManager` (tier adiacente); la Presentation non importa l'Integration Tier (DI seam `ottieni_dao_opzionale`); gateway esterni nell'Integration Tier; i client passano solo da `/api/v1`.
- **Simulazioni locali deterministiche:** gateway IoT/pagamenti/routing senza chiamate di rete (§3), firme invariate per il cablaggio reale.

*Report compiled after FASE 0/1 backend implementation (model alignment + domain wiring).*

---

## 22/06/2026 | SESSION ID: leaf-debt-rientro-B-20260622

### 1. EXECUTION SUMMARY
**Date:** 22/06/2026
**Overall Status:** PASSED
**Duration:** ~6 min (gate server + analyze/test dei due client, pre e post rientro debito)
**Git Context:** feature/console-tui-design-handoff | 8c0828a

**Initialization Type:** Manual (rientro del debito tecnico a rating B + audit completo di stato)
**Environment State:**
- Python: 3.14.5 (target di progetto 3.11) · Flutter: 3.44.1 / Dart: 3.12.1
- Stack: FastAPI/uvicorn · prompt_toolkit · rich · httpx · psutil · passlib (server) · Flutter/Dart (client)
- Active profile: local development — full-project audit + remediation debito client

### 2. DETAILED METRICS BY ARCHITECTURAL TIER

#### A. BACKEND / RUNTIME TIER (FastAPI)
- **Linter (AG-CI-01, Ruff):** Clean — `ruff check server` → All checks passed.
- **Format (AG-CI-03, Ruff):** Clean — `ruff format --check server` → 45 file già formattati.
- **Type Checker (AG-CI-02, Mypy):** **0 errori** su 45 file con `mypy --strict server`.
- **Unit/Integration Tests (AG-CI-04, Pytest):** **39 passed, 0 failed**.
- **Coverage (tier runtime):** **91,39%** (gate `--cov-fail-under=80`), ≥80% su tutti i moduli `server/runtime/`.
- **Security (AG-SEC-01..04):** DEFERRED — rinviati al wiring del `DataAccessManager`/DB.
- Nessuna modifica al server in questa sessione: gate invariati e riconfermati verdi.

#### B. FRONTEND TIER (Flutter)
- **Static Analyzer (AG-CI-05):** Clean — `flutter analyze` **0 issues** su entrambi i client (app_mobile_utente, web_dashboard).
- **Unit & Widget Tests (AG-CI-06):** **39 passed** (app) + **37 passed** (web) = **76/76**, 0 failed.

### 3. SELF-CORRECTION LOG
Nessuna iterazione di autocorrezione necessaria: tutti i gate verdi alla prima esecuzione, sia prima sia dopo il rientro del debito.

**Rientro debito tecnico (prompt 000034) — verificato:**
- **TD-08** (file widget grandi): dato separato dalla UI con `part`/`part of`, identificatori privati e siti d'uso invariati (nessun rename, §3). `search_screen.dart` 589→498, `map_tab.dart` 708→431, `ticket_management.dart` 774→505 (+ `*_data.dart` e `ticket_management_form.dart`). `flutter analyze`/`flutter test` verdi dopo ogni estrazione.
- **TD-07** (Doxygen widget): completato su metodi e widget di supporto delle 3 schermate toccate e dei rispettivi part.
- **TD-11** (class diagram): chiuso per decisione del team (i diagrammi riportano le funzioni principali; niente reverse engineering).
- Esito SQALE: ~13% (C) → **~8% (rating B)**. Dettaglio in `Report/technical_debt_report.md`.

### 4. ARCHITECTURAL BOUNDARY CHECK
- **Presentation–Business–Integration (server):** VALID — nessun import diretto Presentation→Integration; i tier di dominio restano isolati; `runtime/` ossatura operativa (non quarto tier).
- **Client (no MVC):** VALID — l'estrazione TD-08 usa `part`/`part of` (decomposizione di file nella stessa libreria), nessun pattern MVC introdotto, `sistemaTPL` resta integrato nella mappa, nessuna nuova dipendenza.

*Report compiled after full-project status audit + technical-debt remediation to rating B.*
