---
tipo: fonte
creato: 2026-06-19
aggiornato: 2026-06-19
tag: [itps, uml, modelli, viste-4+1, corso]
fonti: [raw/08.0_ITPS_UML_Overview_2026.pptx.pdf]
---

# ITPS — UML Overview (Modelli di sistema)

Slide del corso **ITPS A.A. 2025/2026** (Caivano · Piccinno · Barletta), 35 slide. Riferimenti: Sommerville cap. 5; Fowler *UML Distilled* cap. 1. Introduce la modellazione di sistema e la struttura dell'UML. Pagina concetto: → [[uml]].

## Contenuti chiave

- **Perché modellare:** non si comprende un sistema nella totalità; un modello è un'**astrazione** (non un'alternativa) che tralascia deliberatamente dettagli. Quattro prospettive: esterna (contesto), interazioni, strutturale, comportamentale.
- **UML** (Booch, Jacobson, Rumbaugh; standard OMG, ISO/IEC 19505): linguaggio grafico per specificare, visualizzare, costruire, documentare; indipendente da linguaggio e processo.
- **Due aspetti complementari:** struttura statica (tipi di oggetto e correlazioni) + comportamento dinamico (ciclo di vita e collaborazioni).
- **Tre modi di usare UML:** come **sketch** (informale, esplorativo), come **blueprint/progetto** (dettagliato; reverse engineering da codice, forward engineering verso codice), come **linguaggio di programmazione** (generazione automatica).
- **Costituenti:** entità (strutturali: classe, interfaccia, caso d'uso, componente, nodo; comportamentali; di raggruppamento: package; informative: note); **relazioni** (dipendenza, associazione, aggregazione, composizione, contenimento, generalizzazione, realizzazione); diagrammi; specifiche (il «substrato semantico»); ornamenti; meccanismi di estendibilità (vincoli, stereotipi, valori etichettati).
- **«Il diagramma NON è il modello»**: i diagrammi sono viste sul modello.
- **13 tipi di diagramma** (attività, classi, comunicazione, componenti, struttura composita, deployment, interazione generale, oggetti, package, sequenza, macchina a stati, temporizzazione, casi d'uso).
- **Architettura — le "4+1 Viste" di Kruchten:** vista logica (class/object diagram), dei processi (sequence/activity), di implementazione (component diagram), di deployment (deployment diagram), **+1 dei casi d'uso** (da cui derivano tutte le altre).

## Collegamenti al progetto

- Gli artefatti UML del team (componenti, casi d'uso, classi, 16 sequenze in `raw/assets/`) coprono le viste 4+1 di Kruchten.
- L'UML come **blueprint per forward engineering** è il ponte verso lo [[stream-coding]] (specifica → codice).

## Pagine collegate

- [[uml]] · [[diagramma-delle-classi]] · [[diagramma-di-sequenza]] · [[diagramma-dei-componenti]]
- [[principi-ingegneria-software]] · [[leaf-mobility]]
