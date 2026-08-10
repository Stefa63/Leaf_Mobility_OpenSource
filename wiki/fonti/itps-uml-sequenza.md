---
tipo: fonte
creato: 2026-06-19
aggiornato: 2026-06-19
tag: [itps, uml, sequenza, casi-uso, interazione, corso]
fonti: [raw/08.4_ITPS_UML_Sequenza_2026.pptx.pdf]
---

# ITPS — UML: Diagrammi di Sequenza

Slide del corso **ITPS A.A. 2025/2026** (Barletta · Caivano · Piccinno), 28 slide. Riferimenti: Sommerville cap. 7 (7.1.4); Fowler cap. 4. Pagina concetto: → [[diagramma-di-sequenza]].

## Contenuti chiave

- **Realizzazione dei casi d'uso:** il diagramma di sequenza mostra come le istanze delle **classi di analisi** interagiscono per realizzare un caso d'uso. Il classificatore di contesto è il caso d'uso; le **linee di vita** (lifeline) sono le istanze che si scambiano messaggi.
- **Linea di vita:** nome (opz.) + tipo (classificatore) + selettore (opz.).
- **Messaggi:** chiamata di operazione (stessa segnatura), creazione/distruzione di istanza, segnale; **auto-delega** (messaggio a sé stessi); valore restituito. La linea di vita che esegue ha il **focus di attivazione**.
- **Uno scenario per diagramma:** lo scenario base è un singolo diagramma; gli scenari alternativi in un diagramma a sé o dentro quello base.
- **Invarianti di stato:** un messaggio può cambiare lo stato di un'istanza (mostrabile sulla lifeline).
- **Frammenti combinati** (operatore + operandi + guardie): `opt` (if), `alt` (select/case, con `else`), `loop min,max [cond]`, `break`. Tabella dei tipi di ciclo (while/for/repeat/forEach) → espressioni `loop`.

## Collegamenti al progetto

- Il team ha **16 diagrammi di sequenza** in `raw/assets/Diagrammi di Sequenza/`: realizzano gli scenari dei [[casi-uso-leaf|18 casi d'uso UC01–UC18]].
- Catena di coerenza da presidiare (e da difendere all'orale): **caso d'uso → diagramma di sequenza → classi di analisi**. Le lifeline dei sequence diagram devono essere istanze di classi presenti nel [[diagramma-delle-classi|class diagram]] — punto su cui i diagrammi vanno tenuti allineati tra loro e con il codice (vedi TD-11).

## Pagine collegate

- [[diagramma-di-sequenza]] · [[diagramma-delle-classi]] · [[casi-uso-leaf]]
- [[uml]] · [[leaf-mobility]]
