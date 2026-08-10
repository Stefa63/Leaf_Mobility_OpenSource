---
tipo: concetto
creato: 2026-06-19
aggiornato: 2026-06-19
tag: [stream-coding, ai, metodologia, doe, principi, scrum]
fonti: [raw/03_ITPS_Principi_Ingegneria_Software_2026.pptx.pdf, raw/05_ITPS_Processi_Agili_SCRUM_2026.pptx.pdf, raw/2026-06-12-direttive-leaf-mobility.md]
---

# Stream Coding

Metodologia di **sviluppo software assistito da AI** presentata nel corso ITPS ([[itps-principi-ingegneria-software|Principi dell'IS]], slide 44–52, e ampiamente nel deck [[itps-processi-agili-scrum|Processi Agili e SCRUM]], slide 58–79) come applicazione dei [[principi-ingegneria-software|7 principi]] all'era della generazione di codice tramite LLM. Si contrappone al **Vibe Coding** (approccio conversazionale e caotico che, inseguendo la velocità, sacrifica Rigore e Formalità). Riferimento: `github.com/frmoretto/stream-coding`.

## Tesi centrale

> «La velocità non è l'obiettivo, è un **sintomo**. La **chiarezza** è la causa.»

Il valore non è far generare codice in fretta, ma mantenere una **specifica chiara** da cui il codice discende in modo deterministico e rigenerabile.

## I tre cardini

1. **La Specifica come "Source of Truth".** La documentazione/intento è la fonte autoritativa; il codice è un artefatto derivato.
2. **The Golden Rule.** Se trovi un bug, **correggi la specifica e rigenera** il modulo — non modificare il codice generato a mano.
3. **Il Debito di Divergenza.** Una modifica manuale al codice crea divergenza tra Specifica e Implementazione, rompe il flusso (*stream*) e degrada la sincronia. È debito tecnico per costruzione.

## Mappatura sui 7 principi (slide 51)

| Principio | Realizzazione nello Stream Coding |
|---|---|
| Rigore e Formalità | Prompt strutturati e **gate di chiarezza** pre-esecuzione |
| Astrazione + Separazione degli Interessi | Netta divisione tra **Intento** (documentazione) e **Implementazione** (generazione AI) |
| Anticipazione del Cambiamento | Aggiornare le specifiche e **rigenerare interi moduli** a costo temporale ~zero |

## Perché è il concetto-chiave per LEAF Mobility

Il framework **DOE** delle [[direttive-leaf-mobility|direttive]] (§2: Directive · Orchestration · Execution) è **un'istanza applicata dello Stream Coding**:

| Stream Coding | LEAF Mobility (`DIRECTIVES.md`) |
|---|---|
| Specifica = Source of Truth | **[D] Directive:** tutte le regole/SOP vivono in `DIRECTIVES.md`, letto prima di agire |
| Intento (doc) vs Implementazione (AI) | **[O] Orchestration:** l'agente struttura la logica e la spinge in codice deterministico — mai logica funzionale lasciata alla stocasticità dell'LLM |
| Codice come artefatto derivato deterministico | **[E] Execution:** logica deterministica in `server/` (Python) e `client/` (Dart) |
| Gate di chiarezza pre-esecuzione | I gate **CI/CD AG-CI/AG-SEC** (§12) e la disciplina §3 (ASK PERMISSION, NEVER refactor) |
| **Debito di Divergenza** | È **letteralmente** il **TD-11** del progetto: divergenza class diagram ↔ codice (vedi [[architettura-three-tier]] e il technical debt report) |

### Spunto per l'orale

Poter affermare *«il nostro DOE è un'istanza dello Stream Coding»* e giustificare ogni scelta di processo (specifica autoritativa, no-refactor manuale, rigenerazione, gate CI) con il principio teorico corrispondente. Il **TD-11** non è una svista: è il «Debito di Divergenza» che la metodologia stessa prevede e che il progetto traccia e governa esplicitamente (§17).

## Integrazione in SCRUM (deck Processi Agili, slide 58–79)

Il deck [[itps-processi-agili-scrum]] colloca lo Stream Coding **dentro** SCRUM con metafora **Telaio + Motore**: lo [[scrum|SCRUM]] è il *Telaio* (direzione strategica, priorità, ruoli → *cosa e perché*); lo Stream Coding è il *Motore* (esecuzione AI-accelerata → *come, senza errori*).

- **Velocity Mirage:** l'AI **non** accorcia il PDLC. Studio **METR 2025**: senior **−19%** di velocità reale pur percependo **+20%**. Il Vibe Coding amplifica le ambiguità.
- **Modello 40/20/20:** Pianificazione/Architettura **40%**, Implementazione **15%** (automatica), restante a Integrazione & Test; Debugging/Refactoring **quasi nullo**. → giustifica il peso che il progetto dà a direttive/progettazione rispetto al coding.
- **Strategic Blueprints (7 domande):** problema · metriche · vantaggio · decisione architettonica (umano dopo trade-off) · rationale stack · MVP 3–5 feature · **cosa NON costruire**. ↔ le esclusioni esplicite e l'integration backlog §17.
- **Clarity Gate (checklist 13 punti):** controllo di qualità documentale **prima** dello Sprint Planning (Actionability, Single Source of Truth, Decision-not-Wishes, Prompt-Ready, No Future State, No Fluff, …). ↔ la disciplina §3 e i gate §12 del progetto.

## Pagine collegate

- [[principi-ingegneria-software]] — i 7 principi da cui deriva
- [[scrum]] · [[itps-processi-agili-scrum]] — il Telaio in cui si innesta
- [[prompt-engineering]] — la tecnica operativa che lo abilita
- [[direttive-leaf-mobility]] — il framework DOE (§2)
- [[architettura-three-tier]] · [[leaf-mobility]]
