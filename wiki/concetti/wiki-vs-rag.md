---
tipo: concetto
creato: 2026-06-12
aggiornato: 2026-06-12
tag: [metodologia, knowledge-management, llm]
fonti: [raw/2026-06-12-llm-wiki-pattern.md]
---

# Wiki persistente vs RAG

Due modi opposti di far lavorare un LLM su una collezione di documenti.

| | **RAG** (NotebookLM, file upload, ecc.) | **Wiki LLM** (questo sistema) |
|---|---|---|
| Quando avviene la sintesi | A ogni query, da zero | Una volta, all'ingestione; poi mantenuta |
| Accumulo di conoscenza | Nessuno — ogni domanda riparte da capo | Cumulativo — ogni fonte e ogni query arricchiscono l'artefatto |
| Cross-reference | Ricostruiti al volo, se va bene | Già presenti come wikilink espliciti |
| Contraddizioni tra fonti | Invisibili o scoperte per caso | Già segnalate nelle pagine (`⚠ Contraddizioni`) |
| Infrastruttura | Embedding, vector store, chunking | File markdown + `index.md` (basta fino a ~100 fonti) |
| Ruolo dell'umano | Pone domande | Cura le fonti, dirige l'analisi, pone domande |

**L'intuizione centrale:** in RAG la conoscenza viene *riderivata* a ogni domanda; nella wiki viene *compilata* una volta e tenuta aggiornata. Il valore sta nell'artefatto persistente, non nella singola risposta. Le risposte di valore vengono a loro volta archiviate in `sintesi/`, quindi anche le esplorazioni compongono interesse.

Il collo di bottiglia che storicamente uccideva le wiki personali — il costo di manutenzione (bookkeeping, coerenza, riferimenti) — è proprio ciò che l'LLM azzera. È la stessa lacuna che il [[memex]] di Bush non riuscì a risolvere nel 1945.

## Pagine collegate

- [[llm-wiki-pattern]] — la fonte che definisce il pattern
- [[memex]] — precedente storico
