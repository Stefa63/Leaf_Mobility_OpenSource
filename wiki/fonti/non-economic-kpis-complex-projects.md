---
tipo: fonte
creato: 2026-08-10
aggiornato: 2026-08-10
tag: [KPI, project-management, ESG, EVM, sostenibilita]
fonti: ["raw/Non-Economic KPIs for Complex Projects.pdf"]
---

# L'Integrazione dei Parametri Non Economici nella Gestione dei Progetti Complessi

## Sintesi
Il documento analizza il superamento del tradizionale "Triangolo di Ferro" (costo, tempo, perimetro) nel Project Management, a favore dell'integrazione di parametri non economici e predittivi. L'affidamento esclusivo a metriche finanziarie (lagging indicators) risulta insufficiente per prevedere fallimenti sistemici. L'adozione di KPI non finanziari (leading indicators) permette di anticipare i problemi e attivare azioni correttive prima che le inefficienze si trasformino in perdite monetarie definitive.

## Concetti Chiave

### 1. Evoluzione dell'Earned Value Management (EVM)
Sebbene l'EVM si esprima in valori monetari, traduce il progresso fisico e l'efficienza in metriche analitiche:
- **Planned Value (PV)**, **Earned Value (EV)**, **Actual Cost (AC)**.
- **Cost Performance Index (CPI)** e **Schedule Performance Index (SPI)**: L'SPI agisce come trigger decisionale. Valori sotto 0.90 o 0.80 indicano inefficienze croniche che richiedono interventi operativi drastici.

### 2. Modelli Predittivi: EAC e TCPI
- **Estimate At Completion (EAC)**: Previsione del costo finale basata su cause qualitative (varianza atipica, varianza tipica o scenari di disastro).
- **To-Complete Performance Index (TCPI)**: Indica l'efficienza necessaria per rientrare nel budget. Valori superiori a 1.20 segnalano una sfida operativa quasi proibitiva.

### 3. Machine Learning e Misurazione Topologica
I calcoli puramente lineari falliscono nei progetti complessi. I modelli di AI (come XGBoost, LightGBM) superano questi limiti introducendo parametri non economici strutturali:
- **Project Regularity (RI)**: Quantifica la costanza e la fluidità dell'esecuzione.
- **Project Seriality (SP)**: Mappa la topologia dei task (in serie o in parallelo), fondamentale per comprendere la propagazione dei ritardi.

### 4. Sfera Operativa e Dinamiche Umane
- **Defect Density** e **First-Pass Rate**: Misurano l'integrità e la qualità per evitare che l'efficienza sacrifichi l'output.
- **Resource Capacity Utilization**: Previene il burnout; un'utilizzazione del 100% è patologica perché non lascia margine per imprevisti.
- **Team Velocity** ed **Employee Engagement Score**: Metriche essenziali per valutare la produttività reale e la salute culturale del team (preallarme per cali di produttività).

### 5. Resilienza Esterna e Criteri ESG
- **CSAT**, **NPS** e **CLV**: Indicatori per misurare la fidelizzazione del cliente e la resilienza del mercato.
- I criteri **ESG (Ambiente, Sociale, Governance)** sono divenuti un pilastro della *Long-term Viability*. Richiedono indicatori quantitativi assoluti e di intensità per garantire *benchmarkability*.
- **Data Governance e KPI Hub**: Sistemi architetturali (Data Lineage, Data Ownership) essenziali per prevenire il *greenwashing* e garantire audit rigorosi sulle metriche non finanziarie.

## ⚠ Contraddizioni / Note
- Le stime tradizionali (solo budget/tempo) sono esplicitamente in contrasto con le reali esigenze dei megaprogetti, spingendo verso logiche algoritmiche (Machine Learning) che tengano conto di RI (Regularity) e SP (Seriality).
