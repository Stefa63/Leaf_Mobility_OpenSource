# DIRECTIVES.md — LEAF Mobility Project Directives

> **SOLE AUTHORITATIVE DIRECTIVE FILE FOR ALL AI AGENTS** (Claude Code, Google Antigravity, …).
> You MUST read this file at the start of every session and whenever explicitly requested.
> This is a self-contained directive set. If this file and any other file conflict, THIS FILE takes precedence.
> Per-agent entrypoints (`wiki/CLAUDE.md`, `wiki/GeminiV1.md`) are thin shims that point here; the canon lives only in this file.

---

## 1. PROJECT OVERVIEW

**System:** LEAF Mobility — smart urban mobility platform for the City of Zootropolis.
**Vehicles:** electric bicycles, electric scooters, electric cars (shared).
**Roles (RBAC):** User (UT) · Service Operator (OP) · Public Administration (AP/PA).
**Clients:** `AppMobileUtente` (Flutter) · `WebDashboard` (Flutter Web).
**Business model:** pay-per-use rentals, periodic subscriptions, parking incentives, geographic discounts.

---

## 2. FRAMEWORK: DOE (Directive · Orchestration · Execution)

| Layer | Role | Responsibility |
|---|---|---|
| **[D] Directive** | The Manager | All rules, SOPs, and architectural constraints live in this file (`wiki/DIRECTIVES.md`). Read before acting. |
| **[O] Orchestration** | The AI agent (per-model roles below) | Act as orchestrator; structure logic and push it into deterministic code — never leave functional logic to LLM stochasticity. |
| **[E] Execution** | The Tools | All logic MUST be deterministic code: Python in `server/`, Dart in `client/`. Push complexity into code, not into prompts. |

**Per-model roles (layer [O]):**

| AI agent | Primary responsibility | Model |
|---|---|---|
| **Claude Code** | Backend logic, architectural structuring, debugging | `claude opus 4.8` |
| **Google Antigravity** | Frontend / UI aesthetic tasks | `gemini 3.1 Pro` |

Whichever agent is active: backend logic, architectural structuring and debugging default to **`claude opus 4.8`**; frontend/UI aesthetic work to **`gemini 3.1 Pro`**.

---

## 3. AGENT CONDUCT RULES (NON-NEGOTIABLE)

- **ASK PERMISSION** before: architectural changes, adding dependencies, refactoring any code block.
- **LIST ALL PROPOSED CHANGES** and WAIT for approval before proceeding.
- **NEVER alter** the defined three-tier layered structure.
- **NEVER refactor** unless explicitly asked.
- **NEVER rename** methods, variables, or classes.
- **NEVER use MVC** pattern — strictly prohibited on server AND client application architecture.
- **NEVER separate** the `sistemaTPL` (Local Public Transportation) into its own module — it MUST be natively integrated inside the map management module.
- Be **clear and direct** — no padding that wastes tokens.
- Maintain a **professional, technical, software-engineering tone**.
- You **MUST** be clear and direct; **NO** beating around the bush that could waste tokens.
- **YOU MUST ALWAYS** provide details of what you are doing when making requests, proposing plans or, in general, submitting any proposal that REQUIRES the developers’ approval.
- **EVERYTHING MUST BE** documented and tracked, with detailed specifications as indicated, in Italian.

---

## 4. ARCHITECTURE CONSTRAINTS

### 4.1 Server — Three-Tier Architecture (EXCLUSIVE)
```
Presentation Tier  →  api_gateway_sicurezza, gestore_attivita
Business Tier      →  gestore_corse, gestore_profili_ekyc, gestore_geofencing,
                       motore_analitica, gestore_assistenza_ticket, gestore_flotta
Integration Tier   →  gateway_pagamenti, data_access_manager,
                       gateway_iot, gateway_routing (sistemaTPL INTEGRATED here)
```
- No direct imports between non-adjacent tiers (no leaky abstractions).
- Presentation Tier MUST NOT import Integration Tier endpoints directly.
- Business Tier MUST remain isolated from platform-specific frameworks.

#### 4.1.1 Operational tooling — `server/runtime/` + `server/console_operativa/`
Cross-cutting **operational tooling**, NOT a fourth tier: it does NOT alter the three-tier
structure (§4.3 below still holds). `runtime/` hosts the FastAPI bootstrap, request
instrumentation (metrics middleware/registry), hardware monitor (psutil), audit log, OP
provisioning and backup, plus a **loopback-only** control endpoint. `console_operativa/` is a
terminal UI (Claude-Code style) that acts as a **client** of that endpoint — multiple console
instances may operate concurrently. Design: `Report/architettura_server.md`.

### 4.2 Client — Flutter (Dart)
- No MVC pattern.
- UI aesthetic: **strictly MINIMALIST** — clean design, simple lines, essential color palette, information architecture optimized for on-the-go use.
- `AppMobileUtente`: focus on navigation and vehicle unlocking.
- `WebDashboard`: OP/PA access protected by MFA.

---

## 5. DIRECTORY STRUCTURE

You MUST organize code exactly as follows:

```
Leaf_Mobility_OpenSource/
├── CHANGELOG.md                 # high-level change log, updated at every commit (§18)
├── client/                      # NO MVC pattern
│   ├── app_mobile_utente/       # MINIMALIST design, navigation & vehicle unlock focus
│   └── web_dashboard/           # OP/PA access protected by MFA
├── server/                      # NO MVC pattern
│   ├── presentation_tier/
│   │   ├── api_gateway_sicurezza/
│   │   └── gestore_attivita/
│   ├── business_tier/
│   │   ├── gestore_corse/
│   │   ├── gestore_profili_ekyc/
│   │   ├── gestore_geofencing/
│   │   ├── motore_analitica/
│   │   ├── gestore_assistenza_ticket/
│   │   └── gestore_flotta/
│   ├── integration_tier/
│   │   ├── gateway_pagamenti/
│   │   ├── data_access_manager/
│   │   ├── gateway_iot/
│   │   └── gateway_routing/     # sistemaTPL strictly INTEGRATED here (no separate module)
│   ├── runtime/                 # operational backbone (NOT a 4th tier): FastAPI bootstrap,
│   │                            #   metrics middleware/registry, hardware monitor, audit,
│   │                            #   OP provisioning, backup. Hosts the loopback control endpoint.
│   ├── console_operativa/       # operations TUI (Claude-Code style): client of the runtime
│   ├── tests/                   # runtime/console tests (unittest/pytest)
│   ├── requirements.txt         # one-command install of the stack (§6)
│   ├── pyproject.toml           # ruff + mypy config (§7.4)
│   ├── pytest.ini               # test config (§7.4)
│   └── .env.example             # runtime config template (loopback defaults)
├── Report/
│   ├── Prompt_Sprint_1.md
│   ├── Prompt_Sprint_2.md
│   ├── Prompt_Sprint_3.md
│   ├── session_cicd_report.md
│   ├── technical_debt_report.md  ← SQALE debt log (§17)
│   ├── analisi_database.md       ← database analysis (entities/attributes → E-R → volumes & accesses)
│   ├── architettura_server.md    ← server design: operational runtime + console (§4/§5)
│   ├── kpi_economici.md          ← budget and earned value analysis
│   ├── kpi_non_economici.md      ← ESG, team, risks and operational metrics analysis
│   └── dashboard_kpi_opensource.py ← open-source Plotly/Dash dashboard template for non-financial KPIs
├── wiki/                        # LLM Wiki "second brain" (§19) + directive home — NOT part of the software
│   └── DIRECTIVES.md            ← THIS FILE (single authoritative canon for all AI agents)
├── releases/                    # Pre-compiled APKs
└── .github/                     # GitHub Actions, Issue/PR templates
```

> Directories MUST be created even if no code is placed within them yet.

---

## 6. TECHNOLOGY STACK

### Server — Python 3.11+
| Concern | Library |
|---|---|
| API Framework | FastAPI (async) + uvicorn (ASGI server) |
| Data validation / KYC | Pydantic |
| Database access | `firebase-admin` — Cloud Firestore client, used **server-side only** by `DataAccessManager` (clients never touch Firestore directly) |
| Security / MFA | Passlib (`pbkdf2_sha256`), PyJWT |
| Geofencing / spatial | Shapely or GeoPy |
| Hardware monitoring (console) | `psutil` |
| Operations TUI (console) | `rich` (rendering) + `prompt_toolkit` (REPL) |
| Control endpoint client (console) | `httpx` (HTTP/JSON over loopback) |

> **Stack note — final state (Sprint 3 concluded).** FastAPI/uvicorn host both the **operational
> control endpoint** (loopback, `server/runtime/`) and the **client-facing API** `/api/v1`
> (`presentation_tier/api_pubblica.py`, CORS-enabled, Bearer sessions) now wired end-to-end to the
> Flutter clients. The console stack (`psutil`/`rich`/`prompt_toolkit`/`httpx`) was approved for the
> operations console. Persistence is Cloud Firestore via `firebase-admin` with AES-256-GCM at rest.
> Passlib uses the pure-Python `pbkdf2_sha256` scheme (no native bcrypt dependency — avoids the
> passlib+bcrypt breakage on Python 3.14). Full one-command install: `server/requirements.txt`.

> ## ⚠️ TUNNEL = CLOUDFLARE ESCLUSIVAMENTE. MAI PIÙ LOCALTUNNEL.
> Il tunnel pubblico del runtime è **Cloudflare** (`api.leafmobility.org`), gestito come
> **servizio Windows autonomo** (`cloudflared`). Il supervisore (`supervisore.py`) ne verifica
> solo lo stato (read-only) tramite `_servizio_cloudflared_attivo()` — **non avvia né gestisce
> tunnel in-process**. `py-localtunnel` è marcato LEGACY in `requirements.txt` e **non deve mai
> essere reintrodotto**. In caso di regressione (pull, merge, cherry-pick) che riportasse
> LocalTunnel: ripristinare immediatamente `supervisore.py` alla versione Cloudflare senza
> attendere approvazione (è un fix di emergenza, non una modifica architetturale).

### Database

> ## ⚠️ PERSISTENZA = CLOUD FIRESTORE (NoSQL). MAI SQL / SQLAlchemy / PostgreSQL.
> Il database è **Cloud Firestore** (document store NoSQL). **NON** usare, importare o introdurre
> SQL, SQLAlchemy, ORM relazionali, `mapped_column`/`declarative_base`, PostgreSQL/PostGIS, psycopg.
> L'**unico** accesso ai dati è il `DataAccessManager` (Integration Tier) via **`firebase-admin`**
> con metodi **CRUD/query a documenti** (`crea`/`leggi`/`aggiorna`/`elimina`/`elenca`/`crea_in_sub`…).
> Il modello E-R relazionale di `Report/analisi_database.md` è **solo concettuale**; il modello
> **fisico** è il design a **collezioni** Firestore. Un nuovo agente che parte da zero tende a
> ricadere automaticamente sullo stile SQL: **questo è vietato e non richiesto dal team.**

**Cloud Firestore** (NoSQL document store, Firebase). Accessed **only server-side** via `firebase-admin` inside the Integration Tier (`DataAccessManager`); the Flutter clients never use the Firestore SDK — they reach data exclusively through `/api/v1`, so the three-tier constraint (§4) is preserved. KYC files and other large binaries (PDF/JPG/PNG) go to **Firebase Cloud Storage**, referenced by URL from the Firestore document (documents are not used as a blob store). Geospatial: Firestore has no native polygon/radius queries — proximity (geohash) and point-in-polygon are computed **server-side** (Shapely/GeoPy).

> **Deviation note (2026-06-22, developer-approved).** The original target was PostgreSQL + PostGIS (relational + spatial) with SQLAlchemy. The team switched persistence to **Cloud Firestore** for zero-cost hosting and faster delivery, keeping **server-mediated** access so §4 is unchanged. Consequence: the relational E-R in `Report/analisi_database.md` stays the **conceptual model**; the **physical model** is the Firestore collection design (§10 of that document). SQLAlchemy/PostGIS are no longer used; encryption at rest is provided by Firestore by default, with AES-256 app-level encryption on sensitive fields before write (IIN-4).

### Client — Flutter (Dart)
| Concern | Library |
|---|---|
| Map rendering | `google_maps_flutter` |
| Analytics charts | `fl_chart` |
| State management | `ValueNotifier` (static observable stores) |
| API communication | `dio` (with the Business/Integration Tier) |

> **Client state & networking note:** the client currently uses lightweight `ValueNotifier`-based
> static stores (no `provider`/`bloc`); adopt `provider`/`bloc` only if state complexity later
> warrants it. `dio` is introduced together with the Business/Integration Tier — there is no
> network layer until the backend exists.

---

## 7. CODING STANDARDS

### 7.1 Documentation — Doxygen (MANDATORY for every class, method, interface, function)
Always include: `@param`, `@return`, `@throws`, and a brief description of responsibilities.

### 7.2 Quality — ISO 25000
- **Maintainability:** clean, readable, linted code.
- **Performance Efficiency:** dashboard real-time update ≤ 5 seconds.
- **Reliability:** fault-tolerant, especially for offline rental state sync.

### 7.3 Security
- **AES-256** encryption at rest for all sensitive data and GPS logs.
- **Log redaction** — no PII in plain-text logs.
- **KYC files** accepted formats ONLY: PDF, JPG, PNG (block all other extensions server-side).
- **Data anonymization** for all AP/PA dashboard data.

### 7.4 Repository Config Files (READ BEFORE WRITING CODE)
You MUST read and conform to these files — do NOT invent rules:

| File | Scope | Purpose |
|---|---|---|
| `pyproject.toml` / `ruff.toml` | Server | Ruff linter & formatter (replaces Flake8, Black, isort) |
| `mypy.ini` (or `pyproject.toml` section) | Server | Strict static type checking |
| `pytest.ini` | Server | Test paths, markers, minimum coverage via `pytest-cov` |
| `analysis_options.yaml` | Client | Dart linting (const constructors, type strictness) |
| `pubspec.yaml` | Client | Locked dependencies (`flutter_test`, `mockito`) |

---

## 8. VERSIONING & APK NAMING

Assign a version number to every update. Use this scheme:

| Stage | Version Format | Example |
|---|---|---|
| Pre-Alpha | `0.x.x.x-dev` or `0.x.x.x-alpha.1` | `0.1.0.0-dev` |
| Alpha | `1.0.0.0-alpha.1` | Features incomplete, many bugs |
| Pre-Beta | `1.0.0.0-alpha.2` or `1.0.0.0-beta.0` | Evolved alpha |
| Beta | `1.0.0.0-beta.1` | Feature-complete, known bugs |
| Release Candidate | `1.0.0.0-rc.1` | Stable, awaiting final verification |
| Release | `1.0.0.0` | Stable, no suffix |

**APK:** Create a new APK for EVERY mobile update.
**APK naming format:** `Leaf_Mobility[version]` — e.g., `Leaf_Mobility1.0.0.0-beta.1`

> **Pubspec/semver mapping:** the logical stage scheme above (`1.0.0.0-alpha.N`) maps to the
> Dart/pubspec `version` form `major.minor.patch-stage.N+build` (semver does not allow a 4th
> dotted segment before `+`). Example: logical `1.0.0.0-alpha.15` → pubspec `1.0.0-alpha.15+15`
> → APK `Leaf_Mobility1.0.0-alpha.15`.

---

## 9. PROMPT LOGGING PROTOCOL

Save a copy of every prompt to the correct file:
- **Sprint 1** → `Report/Prompt_Sprint_1.md` — **CLOSED** (archive, read-only)
- **Sprint 2** → `Report/Prompt_Sprint_2.md` — **CLOSED** (archive, read-only)
- **Sprint 3** → `Report/Prompt_Sprint_3.md` — **CLOSED** (archive, read-only; IDs `000026`–`000071`)

> **LOGGING SUSPENDED — PROJECT DELIVERED (2026-06-29).** Sprint 3 is concluded and the project
> has been delivered; there is no open sprint. The prompt-logging protocol is therefore
> **suspended**: do NOT append new entries to any sprint file. The Sprint 1/2/3 logs are all closed
> archives — never renumber or remove existing entries. This protocol resumes only if a new sprint
> (Sprint 4) is explicitly opened, at which point a `Report/Prompt_Sprint_4.md` is created and IDs
> continue from `000072`.

**Rules:**
- **ID:** 6-digit, **sequential and continuous across sprints** (Sprint 1: `000001`–`000011`; Sprint 2: `000012`–`000025`; Sprint 3: `000026`–`000071`). All sprint logs are now closed; new IDs would resume only in a newly opened sprint (from `000072`).
- **Prompt text MUST be verbatim** — copy the full prompt unchanged inside a fenced code block. Never paraphrase it.
- Keep each file's top **index table** updated with the new entry.
- Separate consecutive entries with a horizontal rule (`---`).

**Per-sprint file header (once, at top of file):**
```
# Prompt Log — Sprint N

> Registro dei prompt di sessione (protocollo §9 di `wiki/DIRECTIVES.md`).
> Il testo dei prompt è riportato integrale e invariato; struttura e formattazione sono normalizzate per leggibilità.

## Indice

| ID | Data | Versione | Componente | Titolo |
|---|---|---|---|---|
| ... | ... | ... | ... | ... |
```

**Entry format:**
```
## [ID] — [summary title]

**Data:** [dd/mm/yyyy hh:mm] · **Programmatore:** [name] · **Componente:** [App Mobile / WebDashboard / Server / ...]
**Versione:** [x.x.x.x-stage.n or —] · **CI:** [flutter analyze / test / build outcome or —]   (· **APK:** [filename] if produced)
[· **Backend:** non implementato → AG-CI/AG-SEC N/A  — only if relevant]

**File**
- [grouped file paths]

**Funzioni:** [functions added/modified/deleted]

**Prompt**
​```
[FULL verbatim prompt text]
​```

**Risultato** — [optional one-line scope note, e.g. "additivo, nessun MVC, architettura invariata"]
[numbered list or bullets describing result and elements involved]

---
```

**Programmers (ask identity ONCE per coding session / per day):**
`Jar/Jarno` · `Vic/Victor` · `Ste/Stefano` · `Man/Manuel`

---

## 10. SPRINT PLANNING

### Sprint 1 — ✅ COMPLETED
- **Deadline:** 24/05/2026
- **Prompt log:** `Report/Prompt_Sprint_1.md` (closed, IDs `000001`–`000011`)
- **Objectives:**
  - Mobile app user interface development
  - OP and PA web dashboard interface development

### Sprint 2 — ✅ COMPLETED
- **Start:** 30/05/2026 · **End:** 07/06/2026
- **Prompt log:** `Report/Prompt_Sprint_2.md` (closed, IDs `000012`–`000025`)
- **Objectives:**
  - WebDashboard (OP/PA) interface consolidation
  - Prompt log continuity and ID renumbering

### Sprint 3 — ✅ COMPLETED
- **Start:** 10/06/2026 · **End:** 28/06/2026 · **Project delivered:** 29/06/2026
- **Prompt log:** `Report/Prompt_Sprint_3.md` (closed, IDs `000026`–`000071`)
- **Objectives (all met):**
  - Commit of Phase 0 (web Maps key security + repository hygiene) — done
  - Deterministic widget tests on core screens of both clients (TD-04 remediation) — done
  - Technical debt report update (SQALE debt ratio) — **rating B ~7,8%** reached
  - **Server implemented end-to-end** (three tier + `runtime/` + `console_operativa/` + client-facing `/api/v1`), Cloud Firestore persistence (server-mediated), AES-256-GCM at rest, security gates AG-SEC-01..04 green
  - **Clients wired to the real backend** via `/api/v1` (mobile `1.0.0-alpha.31`, web `1.0.0-alpha.22`); live device/Cloudflare integration testing (§12.5)
- **Final gates:** server `ruff`/`ruff format`/`mypy --strict` 0 · `pytest` ~211 (runtime ~91–92% cov) · mobile `flutter analyze` 0 / `flutter test` 75 · web `flutter analyze` 0 / `flutter test` 90

---

## 11. SELF-LEARNING PROTOCOL (on script failure)

1. Read the error logs.
2. Fix the Python script in `server/` or the Dart code in `client/`.
3. Update this directive file (`wiki/DIRECTIVES.md`) — document the error so it is never repeated.

---

## 12. AUTOMATED CI/CD SESSION PROTOCOL

### 12.1 Lifecycle Rules
1. **Execute ONCE** at session start, before parsing any user request.
2. **Notify user** with exact message: `"Initializing automated CI/CD validation and architecture alignment check..."`
3. **Run all controls** in the Controls Reference Matrix (parallel or sequential).
4. **Self-correction loop:** max **3 iterations**. If failure persists after 3 iterations → HALT feature development → prompt user for architectural guidance.
5. **Write report** to `Report/session_cicd_report.md` (create `Report/` if it does not exist).
6. **Output condensed report** to chat immediately after writing file.

### 12.2 Controls Reference Matrix

| ID | Control | Scope | Command | Target | Severity |
|---|---|---|---|---|---|
| AG-CI-01 | Backend Linting | Server (FastAPI) | `ruff check .` | 0 warnings / 0 errors | Critical |
| AG-CI-02 | Backend Formatting | Server (FastAPI) | `ruff format check` | 100% compliance | Critical |
| AG-CI-03 | Static Types | Server / Business Logic | `mypy --strict` | 0 type errors | Critical |
| AG-CI-04 | Backend Tests | Integration & Business | `pytest --cov=app tests/` | 100% pass / ≥80% coverage | Critical |
| AG-CI-05 | Frontend Analysis | Client (Flutter) | `flutter analyze` | 0 issues | Critical |
| AG-CI-06 | Frontend Tests | Presentation & Business | `flutter test` | 100% success | Critical |
| AG-CI-07 | Tier Isolation | Global Architecture | Cross-layer import inspection | No leaky abstractions | Critical |
| AG-CI-08 | Technical Debt Ratio | Global Codebase | SQALE ratio vs `Report/technical_debt_report.md` | < 20% (rating ≤ C) | Major |
| AG-CI-09 | Mock-in-UI Scan | Client (Flutter) | Scan widgets for hardcoded `static const` datasets | Data resides in dedicated `data/`/repository layer | Major |
| AG-SEC-01 | KYC Format Validation | Business (gestore_profili_ekyc) | `pytest tests/security/test_kyc_format.py` | Reject non PDF/JPG/PNG | Critical |
| AG-SEC-02 | AES-256 Encryption at Rest | Integration (data_access_manager) | `pytest tests/security/test_encryption.py` | Sensitive fields & KYC docs encrypted | Critical |
| AG-SEC-03 | MFA Enforcement (OP/PA) | Presentation (api_gateway_sicurezza) | `pytest tests/security/test_mfa.py` | OP/PA login impossible without valid OTP | Critical |
| AG-SEC-04 | PA Data Anonymization | Business (motore_analitica) | `pytest tests/security/test_anonymization.py` | PA dashboard data not re-identifiable | Critical |

### 12.3 Security Traceability (IIN → CI Control)

| IIN | Description | Enforced By |
|---|---|---|
| IIN-6 | KYC upload restricted to PDF/JPG/PNG | AG-SEC-01 |
| IIN-4 | Sensitive data & GPS logs encrypted at rest (AES-256) | AG-SEC-02 |
| IIN-9 | Mandatory MFA (OTP) for OP/PA | AG-SEC-03 |
| IIN-15 | PA dashboard data aggregated and anonymized | AG-SEC-04 |

### 12.4 CI/CD Report Template

Write to `Report/session_cicd_report.md` using exactly this structure:

```
# ANTIGRAVITY AUTOMATED CI/CD SESSION REPORT
## [TIMESTAMP] | SESSION ID: <id>

### 1. EXECUTION SUMMARY
**Date:** [day/month/year hours:minutes]
**Overall Status:** [PASSED WITH SELF-CORRECTION / PASSED / FAILED]
**Duration:** Z.ZZ seconds
**Git Context:** Branch name | Commit SHA

### 2. DETAILED METRICS BY ARCHITECTURAL TIER

#### A. BACKEND TIER (FastAPI)
- **Linter (Ruff):** Clean / Issues Corrected
- **Type Checker (Mypy):** Passed / Failures Detailed
- **Unit Tests (Pytest):** X passed, Y failed, W% Coverage

#### B. FRONTEND TIER (Flutter)
- **Static Analyzer:** Clean / Violations Fixed
- **Unit & Widget Tests:** N passed, M failed

### 3. SELF-CORRECTION LOG (IF APPLICABLE)
- **File:** `path/to/file`
- **Initial Error:** [error description]
- **Action Taken:** [what was rewritten]
- **Resolution Status:** [Verified Passed on Round N]

### 4. ARCHITECTURAL BOUNDARY CHECK
- **Presentation–Business Separation:** VALID / INVALID
- **Business–Integration Separation:** VALID / INVALID

*Report automatically compiled by Antigravity Core AI Agent.*
```

**Report metadata MUST include:** timestamp, Git branch, latest commit SHA, session ID, initialization type (Automatic/Manual), Python version, Dart/Flutter SDK version, active environment profile.

### 12.5 Real-Device / Live Integration Testing (MANDATORY)

Green automated controls (§12.2) are **NECESSARY but NOT SUFFICIENT**. Passing unit, widget and lint gates does **NOT** prove that a client↔server feature works: connectivity, packaging and deployment defects are invisible to them (e.g. a missing `INTERNET` permission in the release manifest, a loopback-only server bind, a locked account, a missing/mis-named Firestore index). Before any client–server flow (login, vehicle search, booking, ride start/stop, support ticket, password reset, notifications, invoices) is declared **"done"**, it MUST be verified end-to-end against a **running server**, observing **BOTH sides**:

1. **Real device (or emulator) over USB debug.** Install and exercise the app on a **physical Android device** connected via USB (`flutter run` / `adb`), perform the actual user flow, and observe app-side behaviour and Dart logs. The **release APK** — not only the `flutter run` debug build — MUST be validated, because the debug/profile manifests mask defects (the `INTERNET` permission is auto-added only there).
2. **Structured server logs.** Inspect `server/dati/server_app.log` (structured logging: `Timestamp | Module | Level | PID/TID | client IP | request-id | Message`) for the corresponding request: method, path, status, client IP, latency and any traceback. A feature is verified **only when the real request from the device is observed reaching the server with the expected status** — never inferred from a green unit test alone.
3. **Both transport paths.** When the backend is reachable both on the LAN (`LEAF_HOST=0.0.0.0`) and via the Cloudflare tunnel (`api.leafmobility.org`), connectivity-sensitive changes MUST be validated at least once on the path actually used in production (Cloudflare).

Findings from live testing that contradict green CI **take precedence**: HALT and fix the real defect. Record each such defect per §11 (self-learning) so it is never repeated.

---

## 13. EXTERNAL SYSTEMS (BLACK-BOXES — DO NOT BUILD FROM SCRATCH)

Interface with these via API calls, SDKs, or standard drivers through the Integration Tier only:

| System | Component | Notes |
|---|---|---|
| **Cloud Firestore** (NoSQL document DB, Firebase) + **Cloud Storage** (KYC vault) | `DataAccessManager` (server-side `firebase-admin`) | Structured data in Firestore collections; KYC docs (PDF/JPG/PNG) in Cloud Storage referenced by URL. Firestore encrypts at rest by default; sensitive fields AES-256 app-encrypted before write (IIN-4). Accessed only server-side — clients via `/api/v1` |
| **Banking System / SistemaBancario** (e.g., Stripe) | `GatewayPagamenti` | Secure transactions, credit card validation |
| **Map Service / ServizioMappa** (e.g., Google Maps / Mapbox) | `MapInterface` (client UI) + `GatewayRouting` (server routing & heatmaps) | — |
| **Physical Vehicle / MezzoFisico** (IoT hardware) | `GatewayIoT` | Bidirectional: lock/unlock commands + real-time telemetry & GPS |
| **User Localization / LocalizzazioneUtente** (native OS GPS) | `AppMobileUtente` | Query native iOS/Android GPS interface |

---

## 14. FUNCTIONAL REQUIREMENTS — USER STORIES

> ⚠️ **DO NOT TRANSLATE.** Text below is in Italian. Implement exactly as described.

### 14.1 Utenti (UT)

- **UT.01** — COME utente, VOGLIO visualizzare sulla mappa i mezzi disponibili, COSI DA poter individuare quello più vicino per iniziare una corsa.
- **UT.02** — COME utente, VOGLIO prenotare un mezzo, COSI DA garantire la disponibilità esclusiva del veicolo.
- **UT.03** — COME utente, VOGLIO inserire la mia destinazione per ottenere una stima preventiva del costo, COSI DA conoscere la spesa prima di confermare l'utilizzo del mezzo.
- **UT.04** — COME utente, VOGLIO ricevere un riepilogo al termine della corsa, COSI DA verificare l'importo totale addebitato.
- **UT.05** — COME utente, VOGLIO poter filtrare per tipologia (e-bike, e-scooter, automobili elettriche) i mezzi disponibili nei dintorni della mia posizione attuale o di un indirizzo da me inserito e vederne le caratteristiche, COSI DA scegliere il veicolo adatto alle mie necessità di spostamento.
- **UT.06** — COME utente, VOGLIO visualizzare il tempo di attesa stimato per la disponibilità di un mezzo, COSI DA decidere se attendere il rilascio o cercare alternative.
- **UT.07** — COME utente, VOGLIO ricevere diverse opzioni di percorso verso la destinazione inserita, che includano anche l'eventuale integrazione con i mezzi pubblici, ordinate per tempo di percorrenza stimato e con l'evidenza di eventuali interruzioni stradali, COSI DA poter valutare le alternative e scegliere il tragitto.
- **UT.08** — COME utente, VOGLIO visualizzare i suggerimenti sui mezzi consigliati in base al livello di traffico del percorso selezionato, COSI DA evitare ritardi dovuti alla congestione stradale.
- **UT.09** — COME utente, VOGLIO poter contattare un servizio di supporto, COSI DA ottenere assistenza dagli operatori.
- **UT.10** — COME utente, VOGLIO sbloccare il veicolo tramite un comando dall'applicazione, COSI DA avviare l'erogazione del servizio e la corsa.
- **UT.11** — COME utente, VOGLIO registrare un metodo di pagamento verificato nel mio profilo, COSI DA consentire l'addebito automatico a fine noleggio.
- **UT.12** — COME utente, VOGLIO poter attivare una modalità di "pausa corsa", COSI DA mantenere il mezzo bloccato e a mia disposizione senza terminare il noleggio.
- **UT.13** — COME utente, VOGLIO poter noleggiare più mezzi simultaneamente dal mio account, COSI DA estendere il servizio ai miei accompagnatori.
- **UT.14** — COME utente, VOGLIO visualizzare sulla mappa l'ubicazione delle stazioni di ricarica, COSI DA individuare i punti autorizzati per collegare il mezzo.
- **UT.15** — COME utente, VOGLIO ricevere un avviso a schermo un minuto prima della scadenza della mia prenotazione, COSI DA avere il tempo di scegliere se prolungarla o farla decadere.
- **UT.16** — COME utente, VOGLIO inserire una valutazione a stelle al termine della corsa, COSI DA fornire un feedback sulla qualità del noleggio appena concluso.
- **UT.17** — COME utente, VOGLIO consultare una sezione archivio contenente lo storico delle mie corse passate, COSI DA monitorare i dettagli dei tragitti e le relative spese.
- **UT.18** — COME utente, VOGLIO poter aderire a opzioni commerciali specifiche, COSI DA ottimizzare i costi di noleggio dei veicoli.
- **UT.19** — COME utente, VOGLIO visualizzare un avviso in caso di interruzione del servizio, COSI DA poter pianificare opzioni di viaggio alternative.
- **UT.20** — COME utente, VOGLIO attivare una segnalazione di emergenza tramite un tasto SOS nell'app, COSÌ DA comunicare la mia posizione ai soccorsi in caso di pericolo.
- **UT.21** — COME utente, VOGLIO poter accedere ad una sezione dedicata al mio profilo, COSI DA poter visualizzare e gestire le mie informazioni personali, i metodi di pagamento, gli abbonamenti attivi e lo storico delle corse.
- **UT.22.1** — COME utente, VOGLIO poter creare un account con email, username, password e data di nascita, COSI DA poter usufruire del servizio di smart mobility.
- **UT.22.2** — COME utente, VOGLIO caricare una copia digitale dei miei documenti ufficiali, COSI DA certificare la mia identità e idoneità alla guida.
- **UT.23** — COME utente, VOGLIO poter accedere al mio account inserendo email/username e password, COSI DA poter gestire il mio profilo, visualizzare la mappa e avviare noleggi.
- **UT.24** — COME utente, VOGLIO poter richiedere il reset della password tramite la mia email registrata, COSI DA riottenere l'accesso al mio account in caso di smarrimento delle credenziali.
- **UT.25** — COME utente, VOGLIO poter ricevere la fattura della corsa, COSI DA possedere una copia digitale stampabile.

### 14.2 Amministrazione Pubblica (AP)

- **AP.01** — COME Amministrazione Pubblica, VOGLIO estrarre un report periodico sui noleggi raggruppati per tipologia di mezzo, COSI DA quantificare l'effettivo volume di utilizzo di ciascuna categoria.
- **AP.02** — COME Amministrazione Pubblica, VOGLIO visualizzare dashboard con i dati aggregati dei flussi di mobilità (orari e quartieri più attivi), COSI DA estrapolare statistiche misurabili per la pianificazione della viabilità.
- **AP.03** — COME Amministrazione Pubblica, VOGLIO visualizzare le percentuali dei mezzi attualmente operativi rispetto a quelli in manutenzione, COSI DA verificare il rispetto delle soglie minime di servizio concordate con l'operatore.
- **AP.04** — COME Amministrazione Pubblica, VOGLIO inserire sulla mappa del sistema le aree interessate da cantieri o lavori stradali temporanei, COSI DA inibirne temporaneamente il transito o il parcheggio per gli utenti.
- **AP.05** — COME Amministrazione Pubblica, VOGLIO visualizzare una mappa di calore (heatmap) dei percorsi più frequentati dai mezzi, COSI DA individuare i tratti stradali maggiormente soggetti a usura per programmarne i rifacimenti.
- **AP.06** — COME Amministrazione Pubblica, VOGLIO tracciare sulla mappa dei perimetri di interdizione totale, COSI DA bloccare automaticamente l'accesso e la sosta dei mezzi in aree pedonali o protette.
- **AP.07** — COME Amministrazione Pubblica, VOGLIO visualizzare un report indicante la stima delle emissioni di CO₂ risparmiate in base ai chilometri percorsi dalla flotta elettrica, COSI DA quantificare l'impatto ecologico positivo generato dal servizio.
- **AP.08** — COME Amministrazione Pubblica, VOGLIO tracciare specifiche aree sulla mappa imponendo un limite di velocità ridotto (slow-zone), COSI DA forzare il rallentamento automatico del veicolo per tutelare le aree ad alta densità pedonale.
- **AP.09** — COME Amministrazione Pubblica, VOGLIO inserire a sistema le date e le coordinate geografiche dei grandi eventi cittadini, COSI DA notificare gli operatori sulle aree che richiederanno un potenziamento preventivo della flotta.
- **AP.10** — COME Amministrazione Pubblica, VOGLIO visualizzare su mappa la concentrazione in tempo reale dei mezzi disponibili, COSI DA individuare eventuali zone della città prive di copertura.
- **AP.11** — COME Amministrazione Pubblica, VOGLIO poter accedere al mio account con email/username e password, COSI DA poter accedere alle dashboard e visualizzare le analitiche sulla mobilità urbana.
- **AP.12** — COME Amministrazione Pubblica, VOGLIO poter resettare la mia password tramite l'indirizzo email istituzionale fornito in fase di creazione account, COSI DA ripristinare l'accesso alle dashboard analitiche senza dover contattare ogni volta l'assistenza tecnica.

### 14.3 Operatore del Servizio (OP)

- **OP.01** — COME Operatore, VOGLIO visualizzare sulla mappa la posizione in tempo reale di tutti i mezzi della flotta, COSI DA individuare le aree geografiche con eccesso o carenza di disponibilità.
- **OP.02** — COME Operatore, VOGLIO impostare una soglia minima numerica di mezzi per una data area e ricevere un alert quando il numero scende sotto tale valore, COSI DA programmare le operazioni fisiche di ricollocamento della flotta.
- **OP.03** — COME Operatore, VOGLIO visualizzare in una dashboard dedicata la lista dei mezzi contrassegnati dallo stato "Guasto", COSI DA programmarne il ritiro per la manutenzione.
- **OP.04** — COME Operatore, VOGLIO definire a sistema un perimetro geografico che inibisca la procedura di fine noleggio al di fuori di esso, COSI DA vincolare il rilascio dei mezzi esclusivamente all'interno dell'area operativa.
- **OP.05** — COME Operatore, VOGLIO registrare a database le coordinate GPS esatte trasmesse dal mezzo al momento della chiusura della corsa, COSI DA aggiornarne in automatico la posizione sulla mappa visibile agli utenti.
- **OP.06** — COME Operatore, VOGLIO visualizzare un elenco filtrabile dei mezzi che richiedono assistenza tecnica, COSI DA assegnare gli interventi riparativi al personale incaricato.
- **OP.07** — COME Operatore, VOGLIO visualizzare il tracciato GPS in tempo reale e la telemetria di un mezzo attualmente in uso, COSI DA raccogliere dati oggettivi utili in caso di istruttoria per sinistri o anomalie.
- **OP.08** — COME Operatore, VOGLIO accedere a una coda centralizzata delle richieste di assistenza in entrata, COSI DA prendere in carico e rispondere ai messaggi degli utenti.
- **OP.09** — COME Operatore, VOGLIO configurare l'erogazione automatica di un credito bonus per i rilasci effettuati all'interno di specifiche aree di parcheggio designate, COSI DA incentivare la sosta dei mezzi nelle zone predisposte.
- **OP.10** — COME Operatore, VOGLIO poter modificare manualmente lo stato dell'account di un utente in "Sospeso", COSI DA inibirne l'accesso ai servizi di prenotazione e noleggio in seguito a violazioni contrattuali.
- **OP.11** — COME Operatore, VOGLIO inviare un comando di blocco motore da remoto a un mezzo attualmente privo di noleggi attivi, COSI DA inibirne lo spostamento fisico qualora i sensori lo rilevino in un'area non autorizzata.
- **OP.12** — COME Operatore, VOGLIO poter forzare l'annullamento di una prenotazione attiva tramite pannello di controllo, COSI DA rimettere a disposizione della community un mezzo trattenuto in modo anomalo senza l'avvio della corsa.
- **OP.13** — COME Operatore, VOGLIO scaricare un report riepilogativo giornaliero contenente il conteggio totale dei mezzi suddiviso per stati operativi (attivi, in manutenzione, con batteria scarica), COSI DA pianificare i turni delle squadre di recupero per la giornata.
- **OP.14** — COME Operatore, VOGLIO consultare il registro di sistema (log) degli eventi telemetrici (sblocchi, variazioni anomale, urti) associato al codice univoco di ciascun mezzo, COSI DA estrarre i dati storici necessari per analizzare eventuali dinamiche di danno.
- **OP.15** — COME Operatore, VOGLIO configurare uno sconto percentuale programmato per i noleggi avviati all'interno di specifici perimetri geografici configurabili, COSI DA incentivare la domanda nelle zone statisticamente meno redditizie.
- **OP.16** — COME Operatore, VOGLIO compilare e assegnare a sistema un ticket di intervento a un tecnico registrato, COSI DA autorizzare l'attività di riparazione su un mezzo specifico.
- **OP.17** — COME Operatore, VOGLIO poter creare e configurare gli account per gli Amministratori Pubblici, COSI DA fornire loro un accesso sicuro e controllato al sistema, evitando registrazioni pubbliche non autorizzate.
- **OP.18** — COME Operatore, VOGLIO poter sbloccare manualmente un account utente che è stato sospeso per motivi di sicurezza, COSI DA assistere gli utenti che non riescono a completare la procedura automatica.
- **OP.19** — COME Operatore, VOGLIO creare, assegnare e tracciare ticket di manutenzione per i veicoli guasti, COSI DA coordinare il lavoro dei tecnici sul campo e garantire che i mezzi tornino disponibili il prima possibile.
- **OP.20** — COME Operatore, VOGLIO visualizzare in tempo reale lo stato di ogni mezzo (disponibile, in uso, in manutenzione, scarico), COSI DA avere una visione completa della distribuzione della flotta e delle necessità di ricarica/riparazione.
- **OP.21** — COME Operatore, VOGLIO che il sistema generi automaticamente un log operativo completo ogni giorno alle ore 20:00, COSI DA analizzare le performance giornaliere e pianificare le attività per il giorno successivo.
- **OP.22** — COME Operatore, VOGLIO impostare soglie di allerta per la batteria dei mezzi, COSI DA pianificare tempestivamente gli interventi di ricarica.

---

## 15. NON-FUNCTIONAL REQUIREMENTS (IIN)

> ⚠️ **DO NOT TRANSLATE.** Text below is in Italian. Implement exactly as described.

**IIN-1 Accesso al Sistema**
I dati richiesti dal Sistema per l'accesso sono: Email · Password. In caso di credenziali dimenticate, deve essere possibile richiedere l'invio di una mail per il recupero/reset delle credenziali.

**IIN-2 Usabilità**
L'interfaccia utente (UI) deve risultare intuitiva, con un'architettura dell'informazione ottimizzata per l'uso "on-the-go" (pulsanti di facile interazione, alto contrasto visivo). Le funzioni centrali (ricerca, sblocco e termine corsa) devono poter essere apprese da un nuovo utente in meno di 5 minuti.

**IIN-3 Compatibilità e Accessibilità**
L'App mobile deve essere compatibile con iOS e Android aggiornati alle ultime due major release. Le dashboard web devono essere responsive e compatibili con Chrome, Firefox, Safari, Edge.

**IIN-4 Sicurezza e Protezione dei Dati**
I dati personali e i log GPS devono essere archiviati in stretta conformità GDPR. Tutti i dati sensibili devono essere protetti nel database tramite AES-256.

**IIN-5 Autenticazione e Autorizzazione**
Implementare RBAC per ogni tipologia di utente. Password minima: 8 caratteri con almeno una maiuscola, un numero e un carattere speciale.

**IIN-6 Gestione Documentale e Sincronizzazione**
KYC accetta solo PDF, JPG, PNG (blocco server-side di tutte le altre estensioni). Feedback visivo caricamento ≤ 3 secondi. Sincronizzazione in tempo reale degli stati del noleggio; gestione locale in caso di caduta connessione con ripristino alla riconnessione.

**IIN-7 Internazionalizzazione**
Tutte le interfacce (app mobile + web dashboard) devono supportare nativamente almeno Italiano e Inglese.

**IIN-8 Analitiche e Dashboard in Tempo Reale**
Il sistema deve elaborare metriche strategiche condivise tra OP e PA (heatmap distribuzione, zone sovraffollate, stima impatto ecologico).

**IIN-9 Multi-Factor Authentication (MFA)**
Accesso per AP e OP: MFA obbligatorio (OTP via email/app). Per UT: MFA opzionale.

**IIN-10 Account Lockout**
Prevenzione brute-force: blocco account UT per 30 minuti dopo 5 tentativi falliti consecutivi. Blocco AP/OP dopo soli 3 tentativi falliti.

**IIN-11 Recupero Credenziali**
Link di reset password: validità massima 15 minuti, monouso.

**IIN-12 Primo Accesso Istituzionale**
Al primo login, AP e OP devono essere obbligati a modificare la password temporanea fornita in fase di provisioning.

**IIN-13 Audit Logging**
Ogni tentativo di accesso (riuscito o fallito) e ogni azione di sistema compiuta da AP e OP deve essere registrata in un log non modificabile con timestamp e indirizzo IP.

**IIN-14 Limite Dispositivi**
Impedire l'accesso simultaneo di un singolo account UT su più di 3 dispositivi contemporaneamente.

**IIN-15 Anonimizzazione Dati AP**
I dati di mobilità visualizzati nelle dashboard AP devono essere preventivamente aggregati e completamente anonimi — impossibile risalire all'identità o ai tragitti del singolo cittadino.

**IIN-16 Conformità GDPR**
Rispetto del GDPR (Regolamento UE 2016/679): consenso esplicito per raccolta geolocalizzazione e procedure di disattivazione.

**IIN-17 Data Retention**
Dati personali e cronologie degli utenti inattivi: pseudonimizzazione o cancellazione definitiva dopo 24 mesi consecutivi di inattività dell'account.

**IIN-18 Prestazioni SOS**
Inoltro coordinate GPS ai soccorsi entro massimo 5 secondi dalla pressione del tasto SOS.

**IIN-19 Tempestività Notifiche**
Notifiche push critiche (es. fine prenotazione imminente): latenza massima 10 secondi dal verificarsi dell'evento scatenante.

**IIN-20 Real-Time Dashboard**
Dashboard di OP e PA: refresh rate massimo 5 secondi per metriche logistiche e heatmap della flotta.

**IIN-21 Propagazione Configurazione Mappa**
Modifiche dinamiche ai parametri della mappa (nuove aree geofencing, soglie allerta batteria) devono essere propagate e attive su tutti i veicoli interessati entro 30 secondi dal salvataggio.

**IIN-22 Curva di Apprendimento**
Le funzionalità core (registrazione, ricerca veicolo sulla mappa e sblocco) devono essere apprendibili e completabili da un nuovo utente in meno di 5 minuti.

**IIN-23 Aggiornamento Chilometraggio Disponibile**
Il sistema deve aggiornare il saldo dei chilometri residui entro 30 secondi dal termine della corsa.

**IIN-24 Precisione Rintracciamento**
Il calcolo della distanza percorsa per il decurtamento del credito deve avere una precisione del 99% basata sui dati GPS registrati.

---

## 16. ACRONYMS & DEFINITIONS

| Term | Definition |
|---|---|
| AES-256 | Advanced encryption standard for sensitive/personal data in the database |
| Anonymization | Process applied to mobility data shared with PA to prevent identification of individual citizens |
| AP / PA | Public Administration — monitors mobility, reduces traffic/pollution, plans traffic management |
| Audit Logging | Unalterable log of every access attempt and action by PA and Operators (timestamp + IP) |
| Brute-force | Cyberattack via repeated login attempts; prevented by Account Lockout |
| Cloud | Remote-server system ensuring real-time rental status sync |
| Core (Functionality) | Central app functions: registration, vehicle search, unlocking |
| Dashboard | Control panel for Operators and PA showing aggregated data, analytics, real-time fleet status |
| Data Retention | Auto-deletion/pseudonymization of user data after 24 months of inactivity |
| GDPR | EU Regulation 2016/679 — governs storage and management of personal data and GPS logs |
| Geofencing | Virtual map areas limiting speed or prohibiting traffic in specific zones |
| GPS | Global Positioning System — vehicle tracking, end-of-trip coordinate recording, SOS location |
| Heatmap | Graphical representation of most-traveled routes or fleet distribution |
| IIN | Identifier for Non-Functional Infrastructure/Interface Requirements |
| JPG / PNG / PDF | Supported formats for invoice export and document upload |
| KYC | Know Your Customer — document validation system for user identity |
| Log | System log recording operational events, telemetry (unlocking, impacts), or GPS tracking |
| Major release | Most recent significant OS versions (iOS, Android) supported by the app |
| MFA | Multi-Factor Authentication — mandatory for AP and OP, optional for UT |
| Multimodal Routes | Routes combining sharing services and Local Public Transportation |
| On-the-go | Usage mode for which the mobile UI must be optimized |
| OP | Service Operator — manages fleet, maintenance, and logistics |
| OTP | One-Time Password — used for two-factor authentication |
| Provisioning | Process of creating and configuring accounts for AP and OP |
| Pseudonymization | Masking user identity in databases after 24 months of inactivity |
| Push Notifications | Server-to-device alerts (e.g., upcoming reservation expiration) |
| RBAC | Role-Based Access Control (User, Operator, AP) |
| Refresh rate | Frequency at which dashboard data is updated in real time |
| Responsive | UI adapts optimally to different screen sizes and devices |
| Sharing | Mobility model based on shared vehicles (bike sharing, car sharing, e-scooter sharing) |
| sistemaTPL / TPL / LMT | Local Public Transportation (buses, trams) — integrated for informational route planning |
| Slow-zone | Map area with enforced reduced speed limit, forcing automatic vehicle deceleration |
| Smart Mobility | Main project focus — smart and sustainable urban mobility system |
| SOS | In-app emergency button sending GPS coordinates to emergency services |
| Telemetry | Real-time operational/diagnostic data from the vehicle during use |
| Ticket | Formal system request assigned to a technician to authorize repair/maintenance |
| Timestamp | Exact date and time automatically recorded in system logs |
| UI | User Interface — must be intuitive and easy to use |
| UT | User — end customer who books and rents vehicles |

---

## 17. TECHNICAL DEBT GOVERNANCE

**Dedicated report:** `Report/technical_debt_report.md` — maintained with the **SQALE method**, updated at the end of every sprint and on every architectural change.

- **Debt ratio** = remediation cost / development cost of existing code.
- **Rating scale:** A ≤5% · B 6–10% · C 11–20% · D 21–50% · E >50%.
- **ALARM THRESHOLD:** debt ratio **> 20%** → HALT new feature development until remediation brings it back ≤ 20% (same halt discipline as §12.1).
- Each entry MUST record: ID · item · severity · type (Security / Architecture / Reliability / Maintainability / Documentation / Process) · key file(s) · remediation estimate (hours) · status.
- **Prototype exception:** UI mock data not yet wired to the backend is logged as **integration backlog**, NOT debt, until the corresponding endpoint exists.
- Enforced by two automated controls in §12.2: **AG-CI-08** (debt ratio) and **AG-CI-09** (mock-in-UI scan). The executable client CI gate lives in `.github/workflows/ci.yml`.

---

## 18. VERSION CONTROL SESSION PROTOCOL

### 18.1 Session start (synchronization)

At the start of EVERY new session, before any development activity, the agent MUST:

1. **Check for changes** in the repository with `git status` (pending uncommitted local changes).
2. **Synchronize with the remote** by running `git pull origin main`.
3. **List to the developer** the detected changes: pending local files and commits/files received with the pull (or report that the repository is already up to date).

### 18.2 Session end (commit)

At the end of EVERY coding session (when the development work requested for the session is complete), the agent MUST:

1. **Propose a Git commit** — list every modified/added/deleted file and a proposed commit message (Italian, scope-first summary line).
2. **WAIT for explicit developer approval** before running `git commit` and `git push origin main`. NEVER commit or push without approval (same discipline as §3: list all proposed changes and wait).
3. **Update `CHANGELOG.md`** (repository root) within the same commit: add or extend the entry for the current version/date (Keep a Changelog categories: Added / Changed / Fixed / Removed). Sprint-level detail stays in the `Report/` files (§9); the changelog records only the high-level summary per commit.
4. **SVN (TortoiseSVN):** the repository is currently versioned with Git only (no `.svn` working copy, no command-line SVN client installed). IF an SVN working copy becomes available, after the approved Git commit the agent MUST open the TortoiseSVN commit dialog with:
   `& "C:\Program Files\TortoiseSVN\bin\TortoiseProc.exe" /command:commit /path:"C:\Leaf_Mobility"`
   so the developer reviews and approves the SVN commit directly in the GUI. The agent never finalizes an SVN commit autonomously.

> Pure review/Q&A sessions with no file changes are exempt — there is nothing to commit.

---

## 19. LLM WIKI PROTOCOL — "SECOND BRAIN"

> Persistent personal knowledge base maintained by the agent in `wiki/`.
> **ADDITIVE and SEPARATE** layer with respect to the software project: it does NOT alter the
> three-tier structure (§4), the clients (§4.2), or any development protocol. The agent is the
> disciplined maintainer of the wiki; the developer curates sources, explores, and asks questions.

### 19.1 Three-layer architecture

| Layer | Path | Ownership |
|---|---|---|
| **Raw sources** | `wiki/raw/` | **IMMUTABLE.** The agent reads them, NEVER modifies them. Source of truth, curated by the developer (directive snapshots included). |
| **Wiki** | `wiki/` (all other folders) | Written and maintained **exclusively by the agent**. The developer browses it (Obsidian). |
| **Schema** | this §19 | Conventions and workflows. Co-evolved with the developer over time. |

### 19.2 Folder structure

```
wiki/
├── DIRECTIVES.md     # THIS FILE — single authoritative canon (project directives + wiki schema §19)
├── CLAUDE.md         # thin shim → DIRECTIVES.md (entrypoint for Claude Code)
├── GeminiV1.md       # thin shim → DIRECTIVES.md (entrypoint for Google Antigravity)
├── index.md          # catalog of ALL pages (updated on every ingest)
├── log.md            # chronological append-only operations log
├── raw/              # immutable raw sources (articles, papers, notes, transcripts)
│   └── assets/       # locally downloaded images and attachments (incl. UML diagrams)
├── fonti/            # one summary page per ingested source
├── entita/           # entity pages: people, systems, organizations, tools
├── concetti/         # concept pages: themes, ideas, recurring patterns
└── sintesi/          # cross-cutting syntheses, comparisons, archived query answers
```

### 19.3 Page conventions

- **File names:** kebab-case, lowercase, no accents or spaces (e.g. `analisi-mobilita.md`). Raw sources are date-prefixed: `YYYY-MM-DD-titolo.md`.
- **Language of wiki CONTENT: Italian** (consistent with §3 documentation rule).
- **Mandatory YAML frontmatter** on every wiki page:
  ```yaml
  ---
  tipo: fonte | entita | concetto | sintesi
  creato: YYYY-MM-DD
  aggiornato: YYYY-MM-DD
  tag: [tag1, tag2]
  fonti: [raw/linked-source.md]   # only where applicable
  ---
  ```
- **Internal links:** Obsidian wikilinks `[[page-name]]`. Link liberally — links are as valuable as content. A wikilink to a page that does not exist yet is allowed: it marks a page worth creating.
- **Citations:** every significant claim points to its source (`[[source-page]]` or a path in `raw/`).
- **Contradictions:** never silently resolved — flagged explicitly in a `⚠ Contraddizioni` section of the affected page, citing both sources.

### 19.4 Operations

**INGEST** (the developer drops a source into `wiki/raw/`, pastes it in chat, or provides a URL):
1. Save the source **verbatim** into `wiki/raw/` with date prefix `YYYY-MM-DD-titolo.md` (if not already there).
2. Read it in full and discuss the key takeaways with the developer.
3. Write the summary page in `wiki/fonti/`.
4. Update/create the `entita/` and `concetti/` pages touched by the source (a single source may touch 10–15 pages).
5. Flag contradictions with existing knowledge.
6. Update `index.md` and append an entry to `log.md`.

**QUERY** (the developer asks a question):
1. Read `index.md` to locate the relevant pages, then drill into them.
2. Answer with citations to pages/sources.
3. If the answer has lasting value (a comparison, an analysis, a discovered connection), **archive it** in `wiki/sintesi/` and record it in index and log. Explorations compound just like ingested sources.

**LINT** (on periodic request):
- Look for: contradictions between pages, claims superseded by newer sources, orphan pages with no inbound links, concepts mentioned but lacking their own page, missing cross-references, fillable knowledge gaps.
- Produce a report in chat, apply the approved fixes, record the pass in `log.md`.

### 19.5 index.md and log.md

- **`index.md`** is **content-oriented**: a catalog of every page with link, one-line summary and metadata, organized by category (Fonti / Entità / Concetti / Sintesi). Updated on **every** ingest and every archived synthesis. It is the entry point for every query.
- **`log.md`** is **chronological and append-only**: existing entries are never modified. Every entry starts with the parseable prefix:
  ```
  ## [YYYY-MM-DD] ingest | Source title
  ## [YYYY-MM-DD] query | Short question
  ## [YYYY-MM-DD] lint  | Short outcome
  ## [YYYY-MM-DD] setup | Short structural change
  ```
  (so `grep "^## \[" wiki/log.md | tail -5` returns the last 5 operations).

### 19.6 Separation from the software project (NON-NEGOTIABLE)

- `wiki/` is **excluded** from: CI/CD controls AG-CI/AG-SEC (§12), SQALE technical debt (§17), prompt-logging protocol (§9), Doxygen standards (§7).
- Wiki operations **never touch** `client/`, `server/`, or `Report/`. The directive files (`wiki/DIRECTIVES.md` and its shims `wiki/CLAUDE.md`, `wiki/GeminiV1.md`) live inside the wiki folder but are NOT wiki content: they are modified only on explicit developer request.
- The version control protocol §18 also applies to the wiki: commits are proposed and approved by the developer.
- The software directory structure (§5) is NEVER altered by wiki activities.
