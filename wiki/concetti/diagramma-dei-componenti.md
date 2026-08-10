---
tipo: concetto
creato: 2026-06-19
aggiornato: 2026-06-25
tag: [uml, componenti, black-box, interfacce, architettura, corso]
fonti: [raw/10_ITPS_UML_Componenti_2024.pptx.pdf]
---

# Diagramma dei Componenti

Vista di **implementazione** (4+1 di Kruchten): mostra i **componenti** del sistema e le loro dipendenze, senza istanze. Fonte: [[itps-uml-componenti]]. Un **componente** è una parte sostituibile e modulare che incapsula l'implementazione ed espone servizi via interfacce ben definite.

## Tipi di componente

| Tipo | Funzionamento | Implementazione | Esempi |
|---|---|---|---|
| **white-box** | noto | nota e modificabile | insieme di classi del sistema |
| **black-box** | noto | non nota né modificabile | librerie/framework proprietari, web service |
| **grey-box** | noto | modificabile, non necessaria da conoscere | librerie/framework open-source |

## Interfacce

- **Servizi forniti** — l'**API** del componente: i metodi chiamabili da altri.
- **Servizi richiesti** — ciò che altri componenti devono fornire perché il componente funzioni; non definiscono *come*, quindi non ne compromettono l'indipendenza.

## Mapping classi ↔ componenti

- Nel **diagramma dei componenti**: mostrare le classi contenute (per i white-box).
- Nel **diagramma delle classi**: indicare il componente di appartenenza di ciascuna classe.

→ È il legame di consistenza tra [[diagramma-delle-classi]] e questo diagramma.

## Mappatura su LEAF Mobility

- Il `Diagramma_Componenti.png` del team modella i tre tier ([[architettura-three-tier]]): Client (`AppMobileUtente`, `WebDashboard`), Server (Presentation/Business/Integration), Sistemi Esterni.
- **Dettaglio dei Tier e Interfacce**:
  - **Presentation Tier**: `api_gateway_sicurezza` gestisce l'ingresso delle chiamate client ed espone le interfacce REST; `gestore_attivita` orchestra il flusso verso la business logic.
  - **Business Tier**: I vari `Gestore*` (es. `gestore_corse`, `gestore_flotta`) incapsulano le regole di dominio. Devono offrire interfacce stabili affinché il presentation tier sia disaccoppiato dalle logiche interne.
  - **Integration Tier**: `data_access_manager`, `gateway_pagamenti`, `gateway_iot`, `gateway_routing` nascondono la complessità dei sistemi di terze parti e del DB, fungendo da strato anticorruzione.
- **I sistemi esterni delle direttive (§13) sono componenti black-box** — l'UML del team nomina PostgreSQL/PostGIS, Stripe, Google Maps, IoT, GPS, accessibili **solo** via Integration Tier. È un aggancio teoria↔progetto forte per l'orale. **⚠️ Riconciliazione:** il DB effettivo NON è più PostgreSQL/PostGIS ma **Cloud Firestore** (NoSQL document store, `firebase-admin`, server-mediato) — decisione team 22/06/2026; il *ruolo* black-box dietro l'Integration Tier è invariato, ma il codice usa CRUD a documenti, **non SQL/SQLAlchemy** (vedi `wiki/DIRECTIVES.md` §6).
- I componenti server (`Gestore*`, `api_gateway_sicurezza`, gateway) sono **white-box** (le loro classi vanno mostrate nel class diagram); le interfacce tra tier (Access/Collection/Map/GPS/Bank/Mezzi) sono le interfacce «servizi forniti/richiesti».
- Coerenza piena già rilevata nel technical debt report (component diagram ↔ direttive §4): tre tier, nomi, `sistemaTPL` in `gateway_routing`.

## Pagine collegate

- [[architettura-three-tier]] — i tre tier modellati
- [[diagramma-delle-classi]] — mapping classi↔componenti
- [[uml]] · [[itps-uml-componenti]] · [[direttive-leaf-mobility]] · [[leaf-mobility]]
