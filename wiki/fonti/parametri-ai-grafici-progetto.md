---
tipo: fonte
creato: 2026-08-10
aggiornato: 2026-08-10
tag: [AI, project-management, EVM, RAG, simulazione-monte-carlo, dashboard]
fonti: ["raw/Parametri AI e Grafici Progetto.pdf"]
---

# L'Integrazione dell'Intelligenza Artificiale nel Project Management Complesso

## Sintesi
Il documento approfondisce come l'Intelligenza Artificiale (IA) e i modelli predittivi stiano trasformando il Project Management. Sfruttando i dati derivanti dall'Earned Value Management (EVM) come input per reti neurali (ANN, XGBoost), l'IA offre previsioni dinamiche su costi e tempi. Vengono inoltre esaminati l'impiego delle simulazioni Monte Carlo per la gestione dell'incertezza, l'architettura RAG per l'interrogazione dei documenti storici e l'Agentic AI per l'automazione dei processi decisionali.

## Concetti Chiave

### 1. IA Predittiva ed EVM
- I parametri EVM (PV, EV, AC, CPI, SPI) fungono da base (feature) per l'addestramento dei modelli di Machine Learning.
- L'IA calcola in tempo reale **EAC** (Estimate At Completion) e **TCPI**, identificando deviazioni statisticamente irrealistiche (es. balzi di produttività impossibili) per raccomandare tempestivamente azioni contenitive (riduzione di scope, rinegoziazione budget).
- I modelli lineari tradizionali (EVM ortodosso) vengono superati da architetture ad albero (Random Forest, XGBoost) e reti neurali, le quali integrano fattori come *Project Regularity* e *Seriality* per una precisione maggiore e, soprattutto, offrono *Explainability* (rilevanza delle features).

### 2. Simulazione Monte Carlo
- Utilizzata per mitigare la *planning fallacy*, modella l'incertezza su migliaia di iterazioni campionando distribuzioni statistiche (Beta-PERT, Triangolare, Normale, Uniforme).
- Sostituisce stime puntuali con distribuzioni di probabilità, restituendo curve S e istogrammi. Questo consente ai decisori di valutare percentili di confidenza (es. P80) per fissare buffer di contingenza.

### 3. Visualizzazione Dati e Framework Python
La "intelligenza visiva azionabile" è essenziale:
- **Grafici Fondamentali**: Curve a S, Burndown/Burnup chart, Istogrammi/Ribbon di convergenza (Monte Carlo), Treemap e Diagrammi di Rete (Critical Path dinamico).
- **Framework per Dashboard**:
  - **Streamlit**: Ottimo per prototipazione rapida, ma limitato dal paradigma "Full Script Rerun" che lo rende inadatto ad analisi pesanti (es. riaddestramento XGBoost).
  - **Dash (Plotly)**: Adatto per soluzioni Enterprise. Si basa su callback asincroni, aggiornando solo i componenti interessati e gestendo calcoli intensivi senza bloccare l'interfaccia.

### 4. RAG e Intelligenza Agentica (Agentic AI)
- **RAG (Retrieval-Augmented Generation)**: Architettura essenziale per interrogare archivi storici e log di progetto senza incappare in allucinazioni. Suddivide il testo in chunk semantici (Semantic Chunking) ed effettua ricerche ibride per poi fornire una sintesi "grounded" (Sintesi Generativa).
- **Agentic AI**: Sistemi multi-agente (es. LangGraph, CrewAI) in cui agenti software con ruoli specifici collaborano tra loro (es. Agente Analista Costi, Agente Ricercatore Requisiti). Possono compiere *Tool Calling* per recuperare dati ERP, eseguire script e persino gestire cicli interattivi *Human-in-the-loop*.

### 5. Data Governance e Sicurezza dell'IA
- Introdurre l'IA nel project management espone l'azienda a rischi se non regolamentata (*Shadow AI*, fuga di dati sensibili).
- Necessita di stringenti controlli di governance: *Purpose-Bound Access* (ruoli vettoriali segmentati), filtraggio PII e *Data Lineage* per audit inoppugnabili.

## ⚠ Contraddizioni / Note
- Le dashboard reattive con *Streamlit* pur essendo semplici e veloci non sono in grado di scalare in ambienti *Enterprise*, motivo per cui Dash è considerato mandatorio per l'orchestrazione avanzata AI.
