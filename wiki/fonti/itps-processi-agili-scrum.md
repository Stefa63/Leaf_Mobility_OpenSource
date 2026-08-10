---
tipo: fonte
creato: 2026-06-29
aggiornato: 2026-06-29
tag: [itps, agile, scrum, sprint, stream-coding, processo, corso]
fonti: [raw/05_ITPS_Processi_Agili_SCRUM_2026.pptx.pdf]
---

# ITPS — Processi Agili e SCRUM (+ Stream Coding)

Slide del corso **ITPS A.A. 2025/2026** (Barletta · Caivano · Piccinno), **79 slide**. Riferimento: Sommerville cap. 3 (Sviluppo Agile). Fonte doppia: la **prima metà** è la teoria Agile/SCRUM canonica, la **seconda metà** (slide 58–79) integra lo **[[stream-coding|Stream Coding]]** dentro SCRUM. È il fondamento teorico diretto della gestione a sprint di [[leaf-mobility]]. Pagine concetto: → [[scrum]], → [[stream-coding]].

## Parte 1 — Agile e SCRUM

- **Agile (Manifesto 2001):** non una metodologia ma un set di valori/principi; sviluppo incrementale con release ogni 2–3 settimane, cliente coinvolto, documentazione minima. Declinazioni: XP, Scrum, FDD, ASD.
- **4 valori:** individui e interazioni > processi/strumenti; software funzionante > documentazione esaustiva; collaborazione col cliente > negoziazione contratto; rispondere al cambiamento > seguire un piano.
- **12 principi:** software di valore continuo, accoglienza del cambiamento, consegna frequente, collaborazione quotidiana, individui motivati, comunicazione faccia a faccia, software funzionante come metro, ritmo sostenibile, eccellenza tecnica, semplicità, team auto-organizzati, riflessione periodica.
- **SCRUM = framework** (non processo/tecnica) per problemi complessi adattivi. **3 pilastri:** Trasparenza · Ispezione · Adattamento. **6 principi guida:** Empirical Process Control, Self-Organization, Collaboration, Value-Based Prioritization, Time-boxing, Iterative Development.
- **Sprint:** iterazioni di 2–4 settimane a durata costante; nessun cambiamento durante lo sprint. **Sprint n.0** = definizione dello "skeleton" (macro-architettura), unico che non rilascia software funzionante.
- **3 ruoli:** Product Owner (il *valore*, gestisce il backlog, voce del cliente, ROI) · Scrum Master (il *processo*, servant leader, rimuove impedimenti) · Developer/Team (l'*esecuzione*, 5–9 persone, auto-organizzato, cross-funzionale).
- **Cerimonie:** Sprint Planning (obiettivo + sprint backlog stimato) · Daily Scrum (15 min, in piedi: cosa ho fatto/farò/impedimenti) · Sprint Review (demo al PO, focus prodotto) · Sprint Retrospective (focus processo/persone: start/stop/continue) · Product Backlog Refinement.
- **Strumenti:** Product Backlog (lista priorizzata di user story stimate) · Sprint Backlog (task scelti, non assegnati) · **Burndown Chart** (lavoro rimanente nel tempo) · **Scrum Board** (New/In Progress/Feedback/Resolved/Closed).
- **User Story:** «COME ‹ruolo› VOGLIO ‹fare qualcosa› COSÌ CHE ‹valore per il business›».

## Parte 2 — SCRUM + Stream Coding (slide 58–79)

- **Velocity Mirage:** l'AI generativa **non** riduce i tempi del PDLC. Studio **METR 2025**: sviluppatori senior **19% più lenti** con l'AI pur percependo un +20%. Causa = **Vibe Coding** (esplorativo, non strutturato → codice rapido ma senza coerenza architettonica; amplifica le ambiguità).
- **Telaio + Motore:** non abbandonare Agile, potenziarlo. **SCRUM = il Telaio** (direzione strategica, priorità, ruoli → *cosa e perché*); **Stream Coding = il Motore** (velocità di esecuzione via documentazione "AI-ready" → *come eseguire senza errori*).
- **Modello 40/20/20 (gestione del tempo):** Pianificazione/Architettura **40%**, Implementazione **15%** (automatica/task-level), Integrazione & Test ~restante; Debugging/Refactoring **quasi nullo** (vs «elevatissimo» del Vibe Coding).
- **Strategic Blueprints — le 7 domande** (reject vago / require specifico): quale problema risolvi · metriche di successo · perché vincerai · decisione architettonica (umano decide dopo trade-off) · rationale del tech stack · feature MVP (3–5 essenziali) · cosa NON stai costruendo (esclusioni esplicite).
- **Clarity Gate — checklist 13 punti** (controllo qualità pre-Sprint Planning): *Foundation* (Actionability, Currency, Single Source of Truth, Decision-not-Wishes, Prompt-Ready, No Future State, No Fluff) + *Document Architecture* (Document Type, Anti-patterns Placement, Test Cases Placement, Error Handling Placement, Deep Links, No Duplication).
- **La regola della Divergenza** nello Sprint Execution; **esecuzione Single-Agent** con specifiche dense (no coordinamento complesso → niente latenza/instabilità). L'AI eleva l'astrazione: l'ingegnere si focalizza sulla **progettazione del sistema**.

## Collegamenti al progetto

- La gestione a **sprint su Redmine** (Sprint 0/1/2/3, 17 task, burndown) di [[leaf-mobility]] è applicazione diretta di SCRUM; lo **Sprint 0** del progetto = lo "skeleton" qui descritto.
- Il **modello 40/20/20**, il **Clarity Gate** e gli **Strategic Blueprints** sono la teoria dietro il framework **DOE** e le **Direttive Inviolabili** ([[direttive-leaf-mobility]]): vedi la mappatura in [[stream-coding]].
- «Cosa NON stai costruendo» ↔ la disciplina del progetto di marcare i confini (integration backlog §17, esclusioni esplicite).

## ⚠ Contraddizioni / tensioni

- Il deck prescrive **Product Owner / Scrum Master** distinti; nel progetto d'esame i ruoli sono compressi nel team studentesco (lo sviluppatore funge anche da PO). Non è un errore di metodo ma un adattamento di scala.

## Pagine collegate

- [[scrum]] · [[stream-coding]] · [[ingegneria-dei-requisiti]] · [[qualita-dei-requisiti]]
- [[principi-ingegneria-software]] · [[direttive-leaf-mobility]] · [[leaf-mobility]] · [[itps-caso-di-studio-smart-mobility]]
