---
tipo: concetto
creato: 2026-06-19
aggiornato: 2026-06-19
tag: [uml, classi, relazioni, molteplicita, valutazione, corso]
fonti: [raw/08.3_ITPS_UML_Classi_e_Oggetti_2026.pptx.pdf]
---

# Diagramma delle Classi

Vista **strutturale** del sistema in termini di classi, attributi, operazioni e relazioni (nessuna informazione temporale). Fonte: [[itps-uml-classi-oggetti]]. È l'artefatto UML più scrutinato all'esame ITPS — questa pagina è anche una **lente di valutazione** per il class diagram di [[leaf-mobility]].

## Anatomia della classe

Tre scomparti: **nome / attributi / operazioni**. Segnatura: `visibilità nome(par:tipo,…):tipoRestituito`. Visibilità: `+` public · `-` private · `#` protected · `~` package. Corrispondenza diretta UML ↔ codice OO (attributi → campi, operazioni → metodi).

## Qualità di una classe di analisi (criteri d'esame)

- Nome che ne rispecchia l'intento; astrazione ben definita del dominio del problema.
- **3–5 responsabilità** per classe; massima coesione, minima interdipendenza.
- **Anti-pattern da evitare:** classi isolate; proliferazione di classi semplici; poche classi troppo complesse; classi-funzione procedurali; **classi onnipotenti** (occhio ai nomi «sistema»/«controllore»); alberi di ereditarietà profondi.
- Rimedi: **fusione** (accorpare responsabilità coese), **separazione** (estrarre responsabilità in classi coese), combinazione.

## Individuazione delle classi

Analisi testuale di problemi/bisogni/[[casi-uso-leaf|casi d'uso]]/glossario: **nomi e predicati nominali → classi/attributi**; **verbi e frasi verbali → responsabilità**.

## Relazioni tra classi

| Relazione | Significato | Note |
|---|---|---|
| **Associazione** | legame tra istanze | nome/ruoli/**molteplicità**/navigabilità; bidirezionale |
| **Aggregazione** | "parte-di" (whole-part) | la parte può sopravvivere al tutto |
| **Composizione** | parte senza vita propria | il tutto crea/distrugge le parti; molteplicità lato tutto ≤ 1 |
| **Classe associativa** | proprietà della relazione | tipica di molti-a-molti |
| **Generalizzazione** | ereditarietà, sostituibilità | massima interdipendenza |
| **Dipendenza** | «usa» | A usa B come parametro/ritorno/variabile locale |

**Molteplicità:** `1`, `0..1`, `0..*`, `1..*`, `1..6`, … (limiti inferiore..superiore).

## Mappatura su LEAF Mobility (e TD-11)

- Il class diagram del team (`raw/assets/Leaf_Mobility_Classi.jpg`) modella PRESENTATION/BUSINESS/INTEGRATION + ENUM + ENTITÀ + CLIENT. **TD-11**: disallineamento bidirezionale con il codice (il server modellato non è implementato; gli store/screen Flutter implementati non sono modellati). Vedi [[stream-coding]] — è il «Debito di Divergenza».
- **Struttura delle Entità e dei Controllori**: Nel dominio LEAF, si distinguono le classi **Entità** (es. `Utente`, `Corsa`, `Mezzo`) che mantengono lo stato puro e sono fortemente legate al DataAccessManager, dalle classi **Controllore** (es. logica applicativa nei `Gestore*`) che mediano i flussi operativi.
- **Spunto d'orale (god-class):** i componenti `Gestore*`/`api_gateway_sicurezza` sono *componenti di tier*, non classi onnipotenti; nel class diagram la loro logica va decomposta in classi con 3–5 responsabilità (ad esempio separando il gestore validazione KYC dal gestore anagrafica pura). Poterlo dichiarare anticipa l'obiezione del criterio anti-pattern.
- **Mapping classi↔componenti** ([[diagramma-dei-componenti]]): ogni classe del class diagram dovrebbe indicare il componente di appartenenza, coerente con `Diagramma_Componenti.png`.
- **Relazioni chiave in LEAF**: Un tipico esempio è l'aggregazione/composizione tra la classe `Utente` e i suoi `MetodiDiPagamento`, oppure l'associazione tracciabile tra una `Corsa` in stato *attiva* e uno specifico `Mezzo` allocato.

## Pagine collegate

- [[diagramma-di-sequenza]] — le classi qui definite sono le lifeline lì usate
- [[diagramma-dei-componenti]] · [[uml]] · [[casi-uso-leaf]]
- [[principi-ingegneria-software]] · [[stream-coding]] · [[itps-uml-classi-oggetti]]
