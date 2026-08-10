---
tipo: concetto
creato: 2026-06-29
aggiornato: 2026-06-29
tag: [modularita, uses, coesione, accoppiamento, progettazione]
fonti: [raw/07.1_ITPS_Progettazione_2026.pptx.pdf]
---

# Modularità

Decomposizione di un sistema in **moduli** (fornitori di servizi) con **coesione interna alta** e **accoppiamento basso**. È una delle pratiche fondamentali della [[itps-progettazione|progettazione software]] e sostiene i [[principi-ingegneria-software|principi]] di modularità, separazione degli interessi e astrazione.

## Concetti

- **Coesione** = forza che giustifica la coesistenza degli elementi interni a un modulo; deve essere **alta**.
- **Accoppiamento** = densità/tipo di interdipendenza tra moduli; deve essere **basso**.
- **Relazione USES:** `A USES B` ⇒ A (client) dipende da B (server) per i suoi servizi; è **statica** (indipendente dall'esecuzione). Preferibilmente **gerarchica (DAG aciclico)**: comprensione bottom-up, riuso, validazione, manutenibilità. Un **ciclo** → «niente funziona finché tutto non funziona».
- **Fan-in / Fan-out:** archi entranti/uscenti nel grafo USES. Buona struttura = **fan-in alto** (riuso) + **fan-out basso** (poche dipendenze, minore esposizione alle modifiche).
- **Is-Component-Of / Comprises:** gerarchia di composizione (modulo di alto livello costituito da moduli di livello più basso).
- **Interfaccia** = contratto tra modulo e client + astrazione delle capacità; separata nettamente dall'implementazione (nascosta).

## Realizzazione in LEAF Mobility

- L'architettura **three-tier** §4 è un grafo `USES` **gerarchico e aciclico**: nessun import tra tier non adiacenti, la Presentation usa il Business che usa l'Integration — mai il contrario, mai salti. Il controllo **AG-CI-07** (tier isolation) verifica esattamente l'assenza di cicli/leaky abstraction → [[architettura-three-tier]].
- **Fan-out basso** ↔ ogni gestore del Business Tier dipende solo dal `DataAccessManager`/gateway adiacenti; **fan-in alto** ↔ il `DataAccessManager` è usato da tutti i gestori (riuso massimo).
- L'**interfaccia stabile** ↔ `/api/v1` come contratto verso i client, e i metodi CRUD del DAO come contratto verso il Business.

## Pagine collegate

- [[information-hiding]] · [[itps-progettazione]] · [[progettazione-architetturale]] · [[architettura-three-tier]]
- [[diagramma-dei-componenti]] · [[principi-ingegneria-software]] · [[leaf-mobility]]
