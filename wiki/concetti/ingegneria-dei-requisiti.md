---
tipo: concetto
creato: 2026-06-19
aggiornato: 2026-06-19
tag: [requisiti, user-story, elicitazione, tracciabilita, corso]
fonti: [raw/04_ITPS_Analisi_Requisiti_2026.pptx.pdf]
---

# Ingegneria dei Requisiti

Processo di ricerca, analisi, documentazione e verifica dei servizi che il sistema deve fornire e dei suoi vincoli operativi. Fonte: [[itps-analisi-requisiti]] (Sommerville, cap. 4). I requisiti fanno comunicare gli stakeholder e servono a definire portata, costi, schedulazione, casi di test e documentazione.

## Livelli e tipi

- **Requisiti utente** (astratti, alto livello) vs **requisiti di sistema** (descrizione dettagliata). Un requisito utente si espande in più requisiti di sistema.
- **Funzionali** — servizi/comportamenti che il sistema deve fornire.
- **Non Funzionali (vincoli)** — sul sistema nel complesso: requisiti di **prodotto** (es. disponibilità, tempi di risposta), **organizzativi** (politiche interne), **esterni** (norme, privacy). Vanno **quantificati** per essere verificabili.

## User Story

`COME <ruolo> VOGLIO <obiettivo> COSÌ CHE <valore di business>` — tecnica tipica dei processi agili. È la forma usata da [[leaf-mobility]] per UT/OP/AP.

## Il processo (4 attività)

1. **Elicitazione.** *Sorgenti:* obiettivi di business, conoscenza del dominio, stakeholder, regolamenti/leggi, ambiente operativo e organizzativo. *Tecniche:* interviste, scenari, prototipazione, osservazione, storie utente, studi di mappatura.
2. **Analisi e Negoziazione.** Rilevare conflitti/inconsistenze e requisiti mancanti; definire priorità, varianti/invarianti, volatilità; **negoziare** per azzerare le dissonanze concettuali.
3. **Specifica.** Trasformare i requisiti in un **modello concettuale** verificabile, validabile e trasformabile in architettura → **SRS** (Software Requirements Specification), almeno rigorosa.
4. **Verifica & Validazione.** *Verifica:* conformità/correttezza del modello (ispezione). *Validazione:* corrispondenza alle richieste — statica (ispezione) e dinamica (prototipi, test di accettazione).

## Bisogni vs Requisiti

- I **Bisogni** esprimono il «cosa» risolve il problema; cambiano col **dominio dei problemi** (lentamente).
- I **Requisiti** esprimono il modello concettuale del funzionamento; cambiano col **dominio delle soluzioni**.
- Una buona **mappatura/tracciabilità** Bisogni↔Requisiti accelera la soddisfazione dell'utente e gestisce lo *scorrimento dei requisiti*. La traduzione Bisogni→Requisiti è compito dell'**analista** (l'utente parla solo il linguaggio del dominio dei problemi).

## Ruoli adeguati nell'elicitazione

L'utente esperto del dominio dei problemi non deve essere costretto al «tecnichese»: una traduzione inadeguata inietta difetti nei concetti di funzionamento, che si amplificano nelle fasi successive.

## Collegamenti al progetto

- LEAF elicita dal [[itps-caso-di-studio-smart-mobility|caso di studio]] e formalizza in user story con ID + 24 IIN non funzionali → [[direttive-leaf-mobility]] §14/§15, poi in [[casi-uso-leaf|18 casi d'uso]].
- La **tracciabilità** requisiti↔artefatti è uno dei criteri di valutazione del corso; vedi [[qualita-dei-requisiti]].

## Pagine collegate

- [[qualita-dei-requisiti]] — i 14 criteri di qualità
- [[casi-uso-leaf]] · [[itps-analisi-requisiti]] · [[direttive-leaf-mobility]] · [[leaf-mobility]]
