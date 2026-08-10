---
tipo: concetto
creato: 2026-06-19
aggiornato: 2026-06-19
tag: [requisiti, qualita, tracciabilita, valutazione, corso]
fonti: [raw/04_ITPS_Analisi_Requisiti_2026.pptx.pdf]
---

# La qualità dei requisiti (14 criteri)

Criteri che ogni requisito (e la SRS nel complesso) deve soddisfare. Fonte: [[itps-analisi-requisiti]] (slide 45–61). Sono una **griglia di autovalutazione** diretta per i requisiti di [[leaf-mobility]] e un terreno tipico di domande all'orale.

## I criteri

1. **Non Ambiguo** — un solo modo di interpretarlo; evitare acronimi non esplicitati, cattivo uso dei termini, eccessiva sintesi.
2. **Provabile / Verificabile** — devono esistere casi di test che lo confermano/rigettano; vietati aggettivi/avverbi vaghi (robusto, efficiente, velocemente…), parole generiche (gestire, manipolare), pronomi indefiniti, voci passive.
3. **Chiaro** — conciso, semplice, preciso, senza verbosità.
4. **Corretto** — i fatti contenuti devono essere veri.
5. **Comprensibile** — grammaticalmente corretto, stile consistente; usare «deve» non «vuole/può».
6. **Fattibile** — realizzabile entro i vincoli di tempo, denaro, risorse.
7. **Indipendente / Auto-consistente** — comprensibile senza conoscere altri requisiti (no «essi», «questi» riferiti ad altri requisiti).
8. **Atomico** — un solo elemento tracciabile; espressioni con «e»/«ma» vanno spezzate.
9. **Necessario** — qualche stakeholder ne ha bisogno; la sua cancellazione avrebbe conseguenze.
10. **Astratto** — indipendente dall'implementazione (salvo vincolo esplicito dell'utente).
11. **Consistente** — stessi termini per stessi concetti, nessun conflitto diretto/indiretto.
12. **Non Ridondante** — espresso una sola volta, senza sovrapposizioni.
13. **Completo** — specificato per tutte le condizioni che possono verificarsi.
14. **Derivati: Manutenibile e Tracciabile** — un requisito atomico, non ridondante e con **identificatore univoco** è manutenibile e tracciabile.

## Applicazione ai requisiti LEAF Mobility

I requisiti del progetto ([[direttive-leaf-mobility]] §14/§15) sono **identificati univocamente** (UT.xx, AP.xx, OP.xx, IIN-x) → criterio *Tracciabile* soddisfatto e tracciato nei commenti del codice. Tre osservazioni concrete (utili anche all'orale):

- **⚠ Consistenza — formato data (slide 56).** Il corso porta come esempio di **conflitto diretto** proprio `mm/dd/yyyy` vs `gg/mm/aaaa`. Negli artefatti del progetto i formati data risultano misti (US vs ISO), annotazione già presente nel technical debt report come incongruenza da sanare. Teoria e progetto coincidono: è un conflitto da risolvere con una convenzione unica.
- **Atomicità (criterio 8).** Alcune user story sono **compound** (es. UT.21: «visualizzare e gestire informazioni personali, metodi di pagamento, abbonamenti **e** storico»; UT.07 molto articolata). Per il criterio *atomico* andrebbero idealmente scomposte in requisiti tracciabili singoli — spunto di miglioramento, non errore bloccante.
- **Verificabilità.** Gli IIN quantificati (es. SOS ≤5s, refresh ≤5s, reset link 15 min) sono *provabili*; quelli più qualitativi (usabilità «intuitiva») seguono la raccomandazione del corso solo se ancorati a metriche (IIN-2/IIN-22 lo fanno: «apprendibile in <5 minuti»).

## Pagine collegate

- [[ingegneria-dei-requisiti]] — il processo che produce i requisiti
- [[casi-uso-leaf]] · [[itps-analisi-requisiti]] · [[direttive-leaf-mobility]]
