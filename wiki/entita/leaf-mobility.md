---
tipo: entita
creato: 2026-06-12
aggiornato: 2026-06-29
tag: [leaf-mobility, progetto, smart-mobility, firestore]
fonti: [raw/2026-06-12-direttive-leaf-mobility.md, raw/2026-06-13-caso-studio-leaf-mobility.pdf]
---

# LEAF Mobility (Open Source Edition)

Piattaforma di **smart mobility urbana** per la città di Zootropolis — progetto d'esame di Ingegneria del Software (UNIBA, a.a. 2025-2026), ora in versione **Open Source**. Noleggio condiviso di e-bike, e-scooter e auto elettriche con modello pay-per-use, abbonamenti, incentivi al parcheggio e sconti geografici. Fonte primaria: [[caso-studio-leaf-mobility]] (Sprint Report N. 2); contratto operativo derivato: [[direttive-leaf-mobility]].

> [!NOTE] Open Source Edition
> Questa è l'edizione open-source di Leaf Mobility. Contiene adattamenti architetturali per evitare lock-in su provider proprietari chiusi laddove possibile e utilizza framework aperti come Dash (Plotly) per la dashboard KPI (`dashboard_kpi_opensource.py`), oltre a simulare i gateway hardware IoT.

## Componenti

> **Stato finale (Sprint 3 concluso il 28/06/2026, progetto consegnato il 29/06/2026):** sistema client–server reale e funzionante; debito tecnico SQALE rating **B (~7,8%)**; gate CI/CD e sicurezza (AG-SEC-01..04) verdi.

| Componente | Tecnologia | Stato finale (06/2026) |
|---|---|---|
| `AppMobileUtente` | Flutter — design minimalista, focus su navigazione e sblocco mezzi; cablata al backend via `/api/v1` (`dio`) | `1.0.0-alpha.31` |
| `WebDashboard` (OP/PA) | Flutter Web — accesso protetto da MFA reale, Google Maps reali + report fl_chart; cablata al backend via `/api/v1` | `1.0.0-alpha.22` |
| Server | Python 3.11+ / FastAPI / **Cloud Firestore** (NoSQL document store, `firebase-admin`, accesso **server-mediato**) + AES-256-GCM sui campi sensibili, [[architettura-three-tier]] | **implementato end-to-end**: tre tier + `runtime/` + `console_operativa/` + API `/api/v1` + dominio cablato |

> **⚠️ PERSISTENZA = CLOUD FIRESTORE (NoSQL), NON SQL.** Il target originario PostgreSQL+PostGIS/SQLAlchemy è stato **superato** (decisione team 22/06/2026, vedi `wiki/DIRECTIVES.md` §6, nota di deviazione). NON usare SQL/SQLAlchemy/ORM relazionale: l'unico accesso ai dati è il `DataAccessManager` (Integration Tier) via `firebase-admin` con metodi CRUD/query a documenti; i client passano solo da `/api/v1`. Il modello E-R relazionale resta **solo concettuale**; il modello fisico è il design a collezioni Firestore.

## Persone e ruoli

- **Sviluppatori (team UNIBA):** Lamanna Manuel Antonio (832222) · Convertino Stefano (827602) · Galesi Jarno (829867) · Galesi Victor (829396). Coincidono con i programmatori di §9 (Jarno · Victor · Stefano · Manuel).
- **Ruoli applicativi (RBAC):** UT (utente) · OP (operatore del servizio) · AP/PA (amministrazione pubblica).

## Requisiti in numeri

59 user story (25 UT, 12 AP, 22 OP) + 24 requisiti non funzionali IIN — testo integrale nello snapshot [[direttive-leaf-mobility]]. Formalizzati in **18 casi d'uso UC01–UC18** ([[casi-uso-leaf]]). Sistemi esterni black-box: banca/Stripe, servizio mappe, IoT dei mezzi, GPS nativo, DBMS.

## Fondamenti teorici (corso ITPS)

Il progetto è il caso di studio ufficiale del corso ([[itps-caso-di-studio-smart-mobility]]). Le scelte di progetto si ancorano alla teoria ITPS:
- metodologia: [[stream-coding]] — il framework DOE delle direttive ne è un'istanza applicata;
- progettazione: [[principi-ingegneria-software|7 principi]] → [[architettura-three-tier]];
- requisiti: [[ingegneria-dei-requisiti]] e [[qualita-dei-requisiti|14 criteri di qualità]];
- qualità: [[qualita-del-software|ISO 25000]].

## Pagine collegate

- [[caso-studio-leaf-mobility]] — fonte primaria (Sprint Report N. 2)
- [[itps-caso-di-studio-smart-mobility]] — la traccia del corso da cui nasce il progetto
- [[direttive-leaf-mobility]] — il contratto operativo completo
- [[casi-uso-leaf]] — i 18 casi d'uso
- [[architettura-three-tier]] — vincolo architetturale del server
