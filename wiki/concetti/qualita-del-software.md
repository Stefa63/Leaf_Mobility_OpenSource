---
tipo: concetto
creato: 2026-06-19
aggiornato: 2026-06-19
tag: [qualita, iso-25000, manutenibilita, prestazioni, corso]
fonti: [raw/02_ITPS_Concetti_Generali_2026.pptx.pdf]
---

# La qualità del software (ISO 25000)

La qualità è **il valore centrale** dell'Ingegneria del Software: una caratteristica di qualità è una proprietà desiderabile che il prodotto/processo deve possedere per soddisfare requisiti impliciti o espliciti. Fonte: [[itps-concetti-generali]]. Negli ultimi decenni convergenza tra **qualità di processo** e **qualità di prodotto**.

## Le tre prospettive (famiglia ISO 25000)

- **Qualità in uso (percepita)** — efficacia/efficienza con cui il software serve l'utente; percezione diretta.
- **Qualità interna** — attributi statici del codice, indipendenti dall'ambiente d'uso.
- **Qualità esterna** — comportamento dinamico nell'ambito d'uso.

Si influenzano a vicenda: non c'è qualità percepita senza buona qualità interna del codice e buone prestazioni.

## Caratteristiche principali

- **Correttezza** — soddisfa i requisiti funzionali (rispetto alle specifiche).
- **Affidabilità** — probabilità di comportarsi secondo le attese in un intervallo di tempo.
- **Robustezza** — comportamento accettabile anche in circostanze non previste.
- **Usabilità** — facilità d'uso per gli utilizzatori.
- **Manutenibilità** — riparabilità (trovare ed eliminare la causa di un malfunzionamento) + evolvibilità (aggiungere/modificare funzioni).
- **Riusabilità** — riuso di componenti a varie granularità (favorito dall'OO).
- **Prestazioni** — tempo di risposta, reattività, latenza, throughput, carico, efficienza, capacità, scalabilità.
- **Verificabilità, Portabilità, Comprensibilità, Interoperabilità**; del processo: **Produttività, Tempestività, Visibilità**.

## Mappatura su LEAF Mobility

Le direttive (§7.2) adottano esplicitamente **ISO 25000**:

| Caratteristica | Requisito/pratica nel progetto |
|---|---|
| Manutenibilità | Codice lintato (Ruff/`flutter analyze`), no MVC, Doxygen (§7.1), governo **SQALE** del debito (§17) |
| Prestazioni | Refresh dashboard ≤5s (IIN-20), SOS ≤5s (IIN-18), propagazione config ≤30s (IIN-21) |
| Affidabilità | Sync offline degli stati noleggio con ripristino alla riconnessione (IIN-6) |
| Usabilità | UI minimalista «on-the-go», core apprendibile in <5 min (IIN-2/IIN-22) |
| Verificabilità | Gate CI/CD (§12), coverage ≥80% (TD-04), test deterministici |
| Portabilità | iOS/Android ultime due major; dashboard web responsive multi-browser (IIN-3) |

> La **qualità interna** (codice) e la **verificabilità** sono presidiate dal technical debt report (SQALE) e dalla suite di test; la **qualità in uso** dai requisiti non funzionali quantificati (IIN).

## Pagine collegate

- [[principi-ingegneria-software]] — i principi che abilitano la qualità
- [[qualita-dei-requisiti]] · [[itps-concetti-generali]] · [[direttive-leaf-mobility]]
