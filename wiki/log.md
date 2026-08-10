# Registro della Wiki

> Registro cronologico append-only (§19.5 di `wiki/DIRECTIVES.md`). Mai modificare voci esistenti.
> Ultime 5 operazioni: `grep "^## \[" wiki/log.md | tail -5`

## [2026-06-12] setup | Creazione della wiki

Istituito il sistema Wiki LLM "secondo cervello": schema codificato nel §19 di `directives/CLAUDE.md`, struttura cartelle `raw/ fonti/ entita/ concetti/ sintesi/`, creati `index.md` e `log.md`.

## [2026-06-12] ingest | LLM Wiki — il pattern fondativo

Prima ingestione: il documento-idea che definisce il pattern stesso.
- Fonte grezza: `raw/2026-06-12-llm-wiki-pattern.md` (verbatim)
- Pagine create: `fonti/llm-wiki-pattern.md`, `concetti/wiki-vs-rag.md`, `concetti/memex.md`
- Indice aggiornato. Nessuna contraddizione (prima fonte).

## [2026-06-12] setup | Migrazione in vault dedicato (annullata)

Wiki spostata temporaneamente in `C:\Wiki\` come vault autonomo; operazione annullata su decisione dello sviluppatore prima di qualsiasi commit.

## [2026-06-12] setup | Rientro nel repository LEAF

Wiki ripristinata in `C:\Leaf_Mobility\wiki\`. Schema confermato nel §19 di `directives/CLAUDE.md` (tradotto in inglese, coerente col resto delle direttive; il contenuto delle pagine wiki resta in italiano); albero §5 aggiornato con la struttura wiki. Decisione: le direttive di progetto entrano in `raw/` come fonte da ingerire. Rimossi dalla radice del repo i file di scarto `_ctx.txt` e `_i18n_scan.txt`.

## [2026-06-12] ingest | Direttive LEAF Mobility (snapshot)

Seconda ingestione: snapshot verbatim di `directives/CLAUDE.md` (19 sezioni, inclusi 59 user story e 24 IIN).
- Fonte grezza: `raw/2026-06-12-direttive-leaf-mobility.md`
- Pagine create: `fonti/direttive-leaf-mobility.md`, `entita/leaf-mobility.md`, `concetti/architettura-three-tier.md`
- Diagrammi UML non duplicati in `raw/assets/`: restano referenziati in `directives/`.
- Indice aggiornato. Nessuna contraddizione con [[llm-wiki-pattern]] (domini disgiunti). Nota: a ogni revisione significativa delle direttive va ingerito un nuovo snapshot datato.

## [2026-06-12] setup | Eliminazione cartella directives: tutto il contesto in wiki/

La cartella `directives/` non esiste più: i file direttivi vivi (`CLAUDE.md`, `GeminiV1.md`) ora risiedono alla radice di `wiki/`; i diagrammi UML (componenti, casi d'uso, classi, 16 diagrammi di sequenza) sono in `raw/assets/`. Aggiornati gli alberi §5 e i riferimenti interni di entrambi i file direttivi, gli header dei Prompt_Sprint, il CHANGELOG e il technical debt report (TD-11). I file direttivi vivono nella wiki ma NON sono contenuto wiki: si modificano solo su richiesta esplicita (§19.6).

## [2026-06-12] setup | Consolidamento direttive: canone unico DIRECTIVES.md + shim

Eliminata la duplicazione tra i due file direttivi (erano identici al ~98%). Creato `wiki/DIRECTIVES.md` come **canone unico autoritativo** per tutti gli agenti AI; `CLAUDE.md` e `GeminiV1.md` ridotti a shim sottili che puntano al canone e indicano solo il ruolo per-modello (DOE §2). Il §2 del canone ora ha una tabella «ruolo per modello» (Claude Code → backend/opus 4.8; Antigravity → frontend/gemini 3.1 Pro). Aggiornati tutti i puntatori vivi (`wiki/CLAUDE.md` → `wiki/DIRECTIVES.md`) in CHANGELOG, Prompt_Sprint_1/2/3, index/log/fonti della wiki e nel report di lavoro sul Desktop. Antigravity referenzia il file manualmente, quindi nessun vincolo di nome. Beneficio: ogni futura modifica alle direttive si fa in un solo posto, niente più drift.

## [2026-06-13] ingest | Caso di studio LEAF Mobility — Sprint Report N. 2

Terza ingestione: deliverable ufficiale UNIBA (PDF, 127 pagine) fornito dallo sviluppatore.
- Fonte grezza: `raw/2026-06-13-caso-studio-leaf-mobility.pdf` (testo estratto con pypdf per l'analisi; il PDF resta la fonte immutabile)
- Pagine create: `fonti/caso-studio-leaf-mobility.md`, `concetti/casi-uso-leaf.md`
- Pagine aggiornate: `entita/leaf-mobility.md` (fonte primaria, team con matricole, link ai 18 UC)
- **⚠ Contraddizione segnalata** in `fonti/caso-studio-leaf-mobility.md`: formati KYC — UC01 dichiara «JPEG/PNG max 5 MB», in conflitto con la specifica del componente GestoreProfiliEKYC dello stesso documento e con le direttive (§7.3/IIN-6: PDF, JPG, PNG).
- Nota: §2.5.1/2.5.2 (modello dati DB) risultano placeholder nel deliverable. Indice aggiornato.

## [2026-06-13] lint | Allineamento contraddizione KYC + chiarimento DB

Su indicazione dello sviluppatore:
- **KYC allineato:** la formattazione autoritativa è **PDF/JPG/PNG** (direttive §7.3/IIN-6 + specifica componente GestoreProfiliEKYC). Il «JPEG/PNG max 5 MB» di UC01 è una svista di redazione da correggere alla prossima revisione del deliverable. Aggiornata la sezione contraddizioni di [[caso-studio-leaf-mobility]] da ⚠ aperta a ✅ allineata.
- **Modello dati DB (§2.5):** i placeholder non sono una lacuna ma riflettono che **il database deve ancora essere progettato** (sprint successivo); annotazione chiarita nella stessa pagina.

## [2026-06-19] ingest | Blocco teoria di riferimento corso ITPS (4 fonti)

Quarta ingestione: primo blocco di teoria di riferimento (slide del corso ITPS A.A. 2025/2026, Barletta · Caivano · Piccinno) fornito dallo sviluppatore per ampliare il contesto e preparare l'orale.
- Fonti grezze (immutabili): `raw/02_ITPS_Concetti_Generali_2026.pptx.pdf` (41 slide), `raw/03_ITPS_Principi_Ingegneria_Software_2026.pptx.pdf` (52), `raw/04_ITPS_Analisi_Requisiti_2026.pptx.pdf` (63), `raw/06_ITPS_Caso_di_Studio_2026.pptx.pdf` (10). Testo estratto con pypdf per l'analisi.
- Pagine fonte create: `fonti/itps-concetti-generali.md`, `fonti/itps-principi-ingegneria-software.md`, `fonti/itps-analisi-requisiti.md`, `fonti/itps-caso-di-studio-smart-mobility.md`.
- Pagine concetto create: `concetti/stream-coding.md`, `concetti/principi-ingegneria-software.md`, `concetti/ingegneria-dei-requisiti.md`, `concetti/qualita-dei-requisiti.md`, `concetti/qualita-del-software.md`.
- Pagine aggiornate: `entita/leaf-mobility.md` (sezione "Fondamenti teorici"), `concetti/architettura-three-tier.md` (fondamento teorico: separazione/modularità), `index.md` (7 fonti · 9 concetti).
- **Connessione chiave:** lo **Stream Coding** (slide 44–52 di Principi) è la metodologia di cui il framework **DOE** delle direttive (§2) è un'istanza applicata; il "Debito di Divergenza" della metodologia coincide con il **TD-11** del progetto (class diagram ↔ codice).
- **⚠ Coerenza requisiti:** i 14 criteri di qualità (fonte 04) confermano due punti già noti del progetto — conflitto **formato data US/ISO** (slide 56, "conflitto diretto") e **atomicità** di alcune user story compound; annotati in `concetti/qualita-dei-requisiti.md`.
- Note: PDF lasciati con i nomi originali del corso (numerazione 02/03/04/06) anziché date-prefissati, per preservare l'ordinamento didattico; `[[ciclo-di-vita-del-software]]` resta wikilink-stub da creare. Blocco 2 atteso (analisi/progettazione, UML, gestione progetto/Scrum).

## [2026-06-19] ingest | Blocco UML corso ITPS (4 fonti)

Quinta ingestione: blocco UML (slide del corso ITPS A.A. 2025/2026), particolarmente rilevante perché i diagrammi sono il punto più scrutinato all'esame.
- Fonti grezze (immutabili): `raw/08.0_ITPS_UML_Overview_2026.pptx.pdf` (35 slide), `raw/08.3_ITPS_UML_Classi_e_Oggetti_2026.pptx.pdf` (78), `raw/08.4_ITPS_UML_Sequenza_2026.pptx.pdf` (28), `raw/10_ITPS_UML_Componenti_2024.pptx.pdf` (18). Testo estratto con pypdf.
- Pagine fonte create: `fonti/itps-uml-overview.md`, `fonti/itps-uml-classi-oggetti.md`, `fonti/itps-uml-sequenza.md`, `fonti/itps-uml-componenti.md`.
- Pagine concetto create: `concetti/uml.md` (hub), `concetti/diagramma-delle-classi.md`, `concetti/diagramma-di-sequenza.md`, `concetti/diagramma-dei-componenti.md`.
- Pagine aggiornate: `concetti/casi-uso-leaf.md` (link a sequenza/uml), `concetti/architettura-three-tier.md` (link al diagramma componenti), `index.md` (11 fonti · 13 concetti).
- **Connessioni chiave:** (1) i sistemi esterni delle direttive §13 sono esattamente componenti **black-box** UML; (2) le **viste 4+1 di Kruchten** mappano i 4 artefatti del team (componenti/casi d'uso/classi/16 sequenze); manca la vista di deployment (server non implementato); (3) catena di coerenza **caso d'uso → sequenza → classi** da presidiare, collegata a **TD-11**; (4) l'anti-pattern «classe onnipotente con nome sistema/controllore» è uno spunto d'orale per i `Gestore*`.
- Nessuna modifica agli artefatti UML del team (solo conoscenza wiki, su richiesta dello sviluppatore i diagrammi restano a sua cura).

## [2026-06-19] ingest | Progettazione architetturale corso ITPS (1 fonte)

Sesta ingestione: `raw/07.2_ITPS_Progettazione_Architetturale_2026.pptx.pdf` (38 slide), il fondamento teorico diretto dell'architettura del progetto.
- Pagina fonte: `fonti/itps-progettazione-architetturale.md`.
- Pagina concetto: `concetti/progettazione-architetturale.md` (stili layered/three-tier, client-server, MVC).
- Pagine aggiornate: `concetti/architettura-three-tier.md` (corrispondenza 1-a-1 tier↔componenti §4.1, nota MVC), `index.md` (12 fonti · 14 concetti).
- **Connessione chiave:** il three-tier del progetto (§4.1: Presentation/Business/Integration) è **esattamente** lo stile layered/three-tier insegnato (Sommerville cap. 6), con le stesse responsabilità canoniche; «il Business Tier realizza i casi d'uso».
- **⚠ Contraddizione segnalata** (`concetti/progettazione-architetturale.md`): il corso insegna **MVC** come stile valido, ma le direttive lo **vietano** (§3/§4). Documentata come scelta deliberata da difendere all'orale (three-tier + `ValueNotifier` osservabile vs pattern MVC), con l'osservazione onesta che i `ValueNotifier` realizzano comunque un legame Model↔View di tipo Observer.

## [2026-06-25] lint  | Enforcement Firestore: rimosse le residue framing PostgreSQL/SQLAlchemy
- Su richiesta di Stefano: garantire che tutti i file che lo richiedono dichiarino **Cloud Firestore** come persistenza, per evitare la ricaduta automatica nello stile SQL/SQLAlchemy da parte di un nuovo agente.
- Audit codice `server/`: nessuna implementazione SQL/SQLAlchemy attiva — i soli match (`esegui_query`, console `query`, `tipi.py`) sono già **guardie anti-SQL** corrette ("Firestore è un document store: usare CRUD, non SQL"; "niente SQLAlchemy").
- Corretti i file wiki che descrivevano ancora PostgreSQL/PostGIS/SQLAlchemy come stack attivo: `entita/leaf-mobility.md` (tabella stack + banner), `concetti/architettura-three-tier.md` (Resource Tier), `concetti/diagramma-dei-componenti.md` (riconciliazione UML→Firestore), `fonti/direttive-leaf-mobility.md`, `fonti/itps-concetti-generali.md`, `fonti/itps-uml-componenti.md` (note di riconciliazione, sorgenti non riscritte).
- Aggiunto banner ⚠️ anti-SQL inequivocabile in `DIRECTIVES.md` §6 e una riga di promemoria nei due shim d'ingresso `CLAUDE.md`/`GeminiV1.md`; aggiornato `server/README.md` (Firestore + stato reale del backend).
- Esito: nessun residuo non-storico di PostgreSQL/PostGIS/SQLAlchemy fuori da `raw/` e dai log storici.

## [2026-06-29] ingest | 3 nuovi PDF di teoria del corso (SCRUM, Progettazione, Prompt Engineering)
- Stefano ha inserito 3 nuovi PDF in `raw/` (creati il 29/06): `05_ITPS_Processi_Agili_SCRUM_2026.pptx.pdf` (79 slide), `07.1_ITPS_Progettazione_2026.pptx.pdf` (44 slide), `09_Prompt Engineering Ingegneria 2026.pdf` (53 slide, seminario Pretorino).
- Pagine **fonti** create: `fonti/itps-processi-agili-scrum.md`, `fonti/itps-progettazione.md`, `fonti/prompt-engineering-llm.md`.
- Pagine **concetti** create: `concetti/scrum.md`, `concetti/modularita.md`, `concetti/information-hiding.md`, `concetti/prompt-engineering.md`.
- Pagina **aggiornata**: `concetti/stream-coding.md` — il deck SCRUM (slide 58–79) integra lo Stream Coding (Velocity Mirage/METR 2025, Telaio+Motore, modello 40/20/20, Clarity Gate 13 punti, Strategic Blueprints 7 domande); aggiunta la fonte `raw/05_...SCRUM...` e i collegamenti a [[scrum]]/[[prompt-engineering]].
- **Collegamenti chiave al progetto:** SCRUM ↔ sprint Redmine (Sprint 0 = skeleton); modularità/USES gerarchico ↔ three-tier + AG-CI-07; information hiding ↔ DataAccessManager (deviazione Firestore indolore) e gateway; 5 principi di prompt engineering ↔ Direttive/DOE; Lost-in-the-Middle/Context Rot ↔ motivazione della wiki LLM.
- **Nessuna contraddizione nuova** (il deck SCRUM è coerente col DOE; conferma anzi la tensione PO/Scrum-Master compressi nel team d'esame, annotata come adattamento di scala).
- Indice aggiornato: 12→**15 fonti**, 14→**18 concetti**.

## [2026-06-29] setup | Sprint 3 concluso — aggiornamento stato in tutti i documenti
- Marcato **Sprint 3 CONCLUSO** (progetto consegnato 29/06/2026) nei documenti di progetto su richiesta di Stefano.
- `wiki/DIRECTIVES.md`: §9 logging prompt **sospeso** (Sprint 3 chiuso, ID 000026–000071); §10 Sprint 3 → ✅ COMPLETED (fine 28/06, consegna 29/06, obiettivi e gate finali); nota stack §6 allineata (API `/api/v1` ora live).
- `Report/Prompt_Sprint_3.md`: header → ✅ CONCLUSO.
- `Report/technical_debt_report.md`: riga di chiusura Sprint 3 (rating B ~7,8%), gate finali AG-CI-04/06 aggiornati (server 211 pytest, client 75+90), storico revisioni esteso.
- `wiki/entita/leaf-mobility.md` + `wiki/index.md`: versioni finali (mobile alpha.31, web alpha.22), server implementato, nota di conclusione.
- Documento esterno aggiornato (fuori repo): `Manuale di spiegazione artefatti LEAF Mobility.md` (OneDrive) — refresh completo allo stato finale.
- Operazione di sola documentazione: nessun impatto su codice, test o debito (§19.6).

## [2026-08-10] ingest | 2 nuovi PDF su KPI Non Economici e Intelligenza Artificiale
- Ingeriti due nuovi documenti dal contenuto avanzato sul Project Management moderno.
- Fonti grezze: `raw/Non-Economic KPIs for Complex Projects.pdf`, `raw/Parametri AI e Grafici Progetto.pdf`.
- Pagine **fonti** create: `fonti/non-economic-kpis-complex-projects.md`, `fonti/parametri-ai-grafici-progetto.md`.
- Argomenti: evoluzione dell'EVM tramite ML (XGBoost, RI, SP), simulazioni Monte Carlo, RAG per archivi di progetto, e framework Agentic AI (CrewAI, LangGraph).
- Indice aggiornato: 15→**17 fonti**.

## [2026-08-10] setup | Sincronizzazione e Adattamento Wiki per Open Source
- Sincronizzata la wiki dal repository originario.
- Effettuato adattamento di `entita/leaf-mobility.md` per marcare esplicitamente le divergenze Open Source (Dash/Plotly, mock IoT).
- La memoria wikiLLM è ora allineata e biforcata correttamente tra le due edizioni.
