---
tipo: fonte
creato: 2026-06-19
aggiornato: 2026-06-19
tag: [itps, requisiti, user-story, tracciabilita, corso]
fonti: [raw/04_ITPS_Analisi_Requisiti_2026.pptx.pdf]
---

# ITPS — Analisi dei Requisiti

Slide del corso **ITPS A.A. 2025/2026** (Barletta · Caivano · Piccinno), 63 slide. Riferimento: Sommerville, *Ingegneria del Software*, 10ª ed., cap. 4. Copre definizione, tipi, processo e **qualità** dei requisiti.

## Contenuti chiave

- **Requisiti utente** (alto livello, astratti) vs **requisiti di sistema** (descrizione dettagliata). Un requisito utente si espande in più requisiti di sistema.
- **Funzionali** (servizi che il sistema deve fornire) vs **Non Funzionali** (vincoli sul sistema nel complesso: prodotto, organizzativi, esterni). I non funzionali andrebbero **quantificati** per essere verificabili oggettivamente.
- **User Story:** `COME <ruolo> VOGLIO <obiettivo> COSÌ CHE <valore di business>` — tipica dei processi agili.
- **Processo dei requisiti (4 attività):** 1) Elicitazione (sorgenti: obiettivi business, dominio, stakeholder, leggi, ambiente; tecniche: interviste, scenari, prototipazione, osservazione, storie utente…); 2) Analisi e Negoziazione (conflitti, priorità, varianti/invarianti, volatilità); 3) Specifica (modello concettuale verificabile/validabile → SRS); 4) Verifica & Validazione (ispezione statica, prototipi, test di accettazione). → [[ingegneria-dei-requisiti]].
- **Bisogni vs Requisiti:** i Bisogni esprimono il «cosa» risolve il problema (cambiano col dominio dei problemi, lentamente); i Requisiti esprimono il modello concettuale del funzionamento (cambiano col dominio delle soluzioni). Una buona **mappatura/tracciabilità** Bisogni↔Requisiti accelera la soddisfazione dell'utente.
- **I 14 criteri di qualità dei requisiti** (slide 45–61): non ambiguo, verificabile, chiaro, corretto, comprensibile, fattibile, indipendente/auto-consistente, atomico, necessario, astratto, consistente, non ridondante, completo + derivati **manutenibile** e **tracciabile**. → [[qualita-dei-requisiti]].

## Collegamenti al progetto

- LEAF formalizza i requisiti **come user story** (UT/OP/AP) + IIN non funzionali, con **ID univoci** → soddisfa il criterio *tracciabile*. → [[casi-uso-leaf]].
- I 14 criteri sono una **griglia di autovalutazione** dei requisiti del progetto; in [[qualita-dei-requisiti]] sono mappati su punti concreti (atomicità di user story compound, conflitto formato data US/ISO).

## Pagine collegate

- [[ingegneria-dei-requisiti]] · [[qualita-dei-requisiti]]
- [[casi-uso-leaf]] · [[direttive-leaf-mobility]] · [[leaf-mobility]]
