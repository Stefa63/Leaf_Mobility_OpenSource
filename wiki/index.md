---
tipo: indice
aggiornato: 2026-06-29
---

# Indice della Wiki

> Catalogo di tutte le pagine (§19.5 di `wiki/DIRECTIVES.md`). Aggiornato a ogni ingest.
> Punto di ingresso per ogni query: leggere prima questo file, poi approfondire le pagine rilevanti.

**Statistiche:** 17 fonti ingerite · 1 entità · 18 concetti · 0 sintesi

## Fonti

| Pagina | Sintesi | Ingerita |
|---|---|---|
| [[llm-wiki-pattern]] | Il pattern fondativo: wiki persistente mantenuta dall'LLM al posto del RAG; tre livelli, tre operazioni, index+log | 2026-06-12 |
| [[direttive-leaf-mobility]] | Snapshot del file direttivo unico del progetto: DOE, vincoli architetturali, 59 user story, 24 IIN, CI/CD, SQALE, protocolli di sessione | 2026-06-12 |
| [[caso-studio-leaf-mobility]] | Deliverable ufficiale UNIBA (Sprint Report N. 2, 127 pp.): Product Backlog, 18 casi d'uso, architettura a componenti, classi, sequenze, prompt Sprint 1/2 | 2026-06-13 |
| [[itps-concetti-generali]] | Corso ITPS — Introduzione all'IS: ciclo di vita, qualità ISO 25000, tipi di prodotto software, processi piani vs agili | 2026-06-19 |
| [[itps-principi-ingegneria-software]] | Corso ITPS — i 7 principi dell'IS e il loro adattamento allo Stream Coding (AI-coding) | 2026-06-19 |
| [[itps-analisi-requisiti]] | Corso ITPS — ingegneria dei requisiti: funzionali/non funzionali, user story, processo, 14 criteri di qualità | 2026-06-19 |
| [[itps-caso-di-studio-smart-mobility]] | Corso ITPS — la traccia ufficiale Smart Mobility (Zootropolis, UT/OP/AP) da cui nasce il progetto | 2026-06-19 |
| [[itps-uml-overview]] | Corso ITPS — modelli di sistema e UML: costituenti, 13 diagrammi, sketch/blueprint, viste 4+1 di Kruchten | 2026-06-19 |
| [[itps-uml-classi-oggetti]] | Corso ITPS — classi/oggetti, qualità classe di analisi, anti-pattern, relazioni e molteplicità con codice Java | 2026-06-19 |
| [[itps-uml-sequenza]] | Corso ITPS — diagrammi di sequenza: lifeline, messaggi, scenari, frammenti combinati opt/alt/loop/break | 2026-06-19 |
| [[itps-uml-componenti]] | Corso ITPS — componenti white/black/grey-box, interfacce fornite/richieste, mapping classi↔componenti | 2026-06-19 |
| [[itps-progettazione-architetturale]] | Corso ITPS — progettazione architetturale: stili layered/three-tier, client-server, MVC; fondamento del three-tier LEAF | 2026-06-19 |
| [[itps-processi-agili-scrum]] | Corso ITPS — Agile e SCRUM (ruoli, cerimonie, burndown) + integrazione Stream Coding (Velocity Mirage, 40/20/20, Clarity Gate, Strategic Blueprints) | 2026-06-29 |
| [[itps-progettazione]] | Corso ITPS — progettazione software generale: modularità, USES/fan-in-out, information hiding, processo, black/white/grey box, UI, V&V | 2026-06-29 |
| [[prompt-engineering-llm]] | Seminario ITPS (Pretorino) — fondamenti LLM (token, context window), limiti, 5 principi e tecniche di prompt engineering, caso eSpeechT | 2026-06-29 |
| [[non-economic-kpis-complex-projects]] | Parametri non economici, EVM avanzato, modelli predittivi e architetture ESG per la gestione di progetti complessi | 2026-08-10 |
| [[parametri-ai-grafici-progetto]] | Integrazione dell'IA nel Project Management: Machine Learning per l'EVM, Monte Carlo, RAG, Agentic AI e Data Visualization | 2026-08-10 |
## Entità

| Pagina | Sintesi | Aggiornata |
|---|---|---|
| [[leaf-mobility]] | Il progetto d'esame: piattaforma smart mobility per Zootropolis; **Sprint 3 concluso/consegnato 29/06/2026** — client Flutter (mobile alpha.31, web alpha.22) cablati al server tre tier su Cloud Firestore, rating B ~7,8% | 2026-06-29 |

## Concetti

| Pagina | Sintesi | Aggiornata |
|---|---|---|
| [[wiki-vs-rag]] | Confronto tra recupero a ogni query (RAG) e conoscenza compilata e mantenuta (wiki); l'intuizione centrale del sistema | 2026-06-12 |
| [[memex]] | Il dispositivo di Vannevar Bush (1945): antenato concettuale della wiki personale; il problema irrisolto della manutenzione | 2026-06-12 |
| [[architettura-three-tier]] | Il vincolo esclusivo del server LEAF: tre tier isolati, no MVC, sistemaTPL integrato in gateway_routing, controllo AG-CI-07 | 2026-06-12 |
| [[casi-uso-leaf]] | I 18 casi d'uso UC01–UC18 per attore (UT/OP/AP), tracciabili con le user story | 2026-06-13 |
| [[stream-coding]] | Metodologia AI-coding del corso: specifica come source of truth, golden rule, debito di divergenza; il DOE del progetto ne è un'istanza | 2026-06-19 |
| [[principi-ingegneria-software]] | I 7 principi (rigore, separazione, modularità, anticipazione, astrazione, generalità, incrementalità) mappati sul progetto | 2026-06-19 |
| [[ingegneria-dei-requisiti]] | Processo dei requisiti: livelli, tipi, user story, elicitazione→analisi→specifica→V&V, bisogni vs requisiti | 2026-06-19 |
| [[qualita-dei-requisiti]] | I 14 criteri di qualità dei requisiti come griglia di autovalutazione (atomicità, tracciabilità, conflitto formato data) | 2026-06-19 |
| [[qualita-del-software]] | ISO 25000: tre prospettive (in uso/interna/esterna) e caratteristiche, mappate sui requisiti e le pratiche LEAF | 2026-06-19 |
| [[uml]] | Hub UML: due aspetti, costituenti, sketch/blueprint/forward engineering, viste 4+1 mappate sugli artefatti del team | 2026-06-19 |
| [[diagramma-delle-classi]] | Vista strutturale: anatomia classe, qualità/anti-pattern (god-class), relazioni, molteplicità; lente per il class diagram e TD-11 | 2026-06-19 |
| [[diagramma-di-sequenza]] | Realizzazione casi d'uso: lifeline, messaggi, frammenti combinati; catena coerenza UC→sequenza→classi (16 diagrammi del team) | 2026-06-19 |
| [[diagramma-dei-componenti]] | Componenti white/black/grey-box, interfacce, mapping classi↔componenti; sistemi esterni §13 = black-box | 2026-06-19 |
| [[progettazione-architetturale]] | Stili architetturali (layered/three-tier, client-server, MVC); fondamento del three-tier LEAF + ⚠ tensione MVC da difendere all'orale | 2026-06-19 |
| [[scrum]] | Framework agile (3 pilastri, ruoli, cerimonie, burndown); processo del progetto (Sprint 0/1/2/3 su Redmine) + innesto Stream Coding | 2026-06-29 |
| [[modularita]] | Coesione/accoppiamento, relazione USES (DAG aciclico), fan-in/fan-out, Is-Component-Of; il three-tier come grafo USES gerarchico | 2026-06-29 |
| [[information-hiding]] | Nascondere decisioni/dettagli instabili dietro interfacce stabili; HW-SW/behavior/decision hiding; DataAccessManager e gateway come applicazione | 2026-06-29 |
| [[prompt-engineering]] | I 5 principi e le tecniche (role/few-shot/CoT), limiti LLM e prompt injection; disciplina operativa dello sviluppo AI-assistito del progetto | 2026-06-29 |

## Sintesi

*(nessuna pagina ancora)*
