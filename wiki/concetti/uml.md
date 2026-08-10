---
tipo: concetto
creato: 2026-06-19
aggiornato: 2026-06-19
tag: [uml, modelli, viste-4+1, diagrammi, corso]
fonti: [raw/08.0_ITPS_UML_Overview_2026.pptx.pdf]
---

# UML (Unified Modeling Language)

Linguaggio grafico standard (OMG, ISO/IEC 19505) per **specificare, visualizzare, costruire e documentare** gli artefatti di un sistema software, indipendentemente da linguaggio e processo. Fonte: [[itps-uml-overview]]. Pagina-hub del blocco UML; è l'attuazione del principio di [[principi-ingegneria-software|Astrazione]]: un modello è un'astrazione del sistema, non un'alternativa.

## Due aspetti complementari

- **Struttura statica** — i tipi di oggetto e come si correlano → [[diagramma-delle-classi]], diagramma dei componenti.
- **Comportamento dinamico** — ciclo di vita e collaborazioni → [[diagramma-di-sequenza]], stati, attività.

## Costituenti fondamentali

- **Entità:** strutturali (classe, interfaccia, caso d'uso, componente, nodo), comportamentali (interazioni, attività, stati), di raggruppamento (package), informative (note).
- **Relazioni:** dipendenza, associazione, aggregazione, composizione, contenimento, generalizzazione, realizzazione.
- **Specifiche:** il «substrato semantico» testuale che dà significato al modello — *il diagramma NON è il modello*, è una vista su di esso.
- **Estendibilità:** vincoli, **stereotipi** (`<<...>>`), valori etichettati.

## Tre modi di usare UML

- **Sketch** — informale, esplorativo.
- **Blueprint / progetto** — dettagliato; *reverse engineering* (da codice a diagramma) e *forward engineering* (da diagramma a codice).
- **Linguaggio di programmazione** — generazione automatica del codice.

> Lo [[stream-coding]] del progetto è UML/specifica usata come **blueprint per forward engineering**: la specifica genera il codice.

## Le "4+1 Viste" (Kruchten)

| Vista | Diagrammi | Nel progetto |
|---|---|---|
| Logica | classi, oggetti | `Leaf_Mobility_Classi.jpg` → [[diagramma-delle-classi]] |
| Processi | sequenza, attività | 16 diagrammi di sequenza → [[diagramma-di-sequenza]] |
| Implementazione | componenti | `Diagramma_Componenti.png` → [[diagramma-dei-componenti]] |
| Deployment | deployment | (non ancora prodotto) |
| **+1 Casi d'uso** | casi d'uso | `Diagramma_CasiDuso.png` → [[casi-uso-leaf]] (da cui derivano le altre viste) |

Gli artefatti UML del team coprono 4 delle 5 viste; la vista di deployment manca (coerente col server non ancora implementato).

## Pagine collegate

- [[diagramma-delle-classi]] · [[diagramma-di-sequenza]] · [[diagramma-dei-componenti]] · [[casi-uso-leaf]]
- [[principi-ingegneria-software]] · [[stream-coding]] · [[itps-uml-overview]] · [[leaf-mobility]]
