---
tipo: fonte
creato: 2026-06-12
aggiornato: 2026-06-12
tag: [meta, metodologia, knowledge-management]
fonti: [raw/2026-06-12-llm-wiki-pattern.md]
---

# LLM Wiki — il pattern fondativo

> Fonte: [raw/2026-06-12-llm-wiki-pattern.md](../raw/2026-06-12-llm-wiki-pattern.md) · documento-idea, autore non specificato · ingerito il 12/06/2026.
> È la fonte fondativa di questa wiki: descrive il pattern su cui la wiki stessa è costruita.

## In una frase

Invece di recuperare frammenti dalle fonti grezze a ogni domanda (RAG), l'LLM **compila e mantiene una wiki persistente e interconnessa** che si arricchisce a ogni fonte ingerita e a ogni domanda posta — vedi [[wiki-vs-rag]].

## Punti chiave

1. **Conoscenza compilata una volta, non riderivata a ogni query.** La wiki è un artefatto persistente e cumulativo: i riferimenti incrociati esistono già, le contraddizioni sono già segnalate, la sintesi riflette già tutto il letto.
2. **Divisione del lavoro:** l'umano cura le fonti, esplora e pone le domande giuste; l'LLM fa tutta la manutenzione (riassunti, cross-reference, archiviazione, bookkeeping). «Obsidian è l'IDE; l'LLM è il programmatore; la wiki è il codebase.»
3. **Tre livelli:** fonti grezze (immutabili) → wiki (scritta solo dall'LLM) → schema (CLAUDE.md, le convenzioni). Lo schema è ciò che rende l'LLM un manutentore disciplinato anziché un chatbot generico.
4. **Tre operazioni:** *ingest* (una fonte tocca 10–15 pagine), *query* (le risposte di valore vengono riarchiviate in wiki: le esplorazioni si accumulano), *lint* (controllo periodico di salute: contraddizioni, pagine orfane, claim superati).
5. **Due file di navigazione:** `index.md` (catalogo per contenuti, letto prima di ogni query — basta fino a ~100 fonti, niente RAG embedding) e `log.md` (cronologico, append-only, prefisso parsabile `## [data] operazione | titolo`).
6. **Perché funziona:** gli umani abbandonano le wiki perché il costo di manutenzione cresce più in fretta del valore; per l'LLM quel costo è quasi zero. Radice storica: il [[memex]] di Vannevar Bush (1945).

## Decisioni di implementazione locali (questa wiki)

- Schema codificato nel **§19 di `wiki/DIRECTIVES.md`** (in inglese, come il resto delle direttive; il contenuto della wiki resta in italiano); strato additivo dentro il repo LEAF Mobility, separato dal software. Dal 12/06/2026 `wiki/` ospita anche i file direttivi (canone unico `DIRECTIVES.md` + shim `CLAUDE.md`/`GeminiV1.md`) e i diagrammi UML (`raw/assets/`).
- Cartelle: `raw/` · `fonti/` · `entita/` · `concetti/` · `sintesi/`; lingua italiana; frontmatter YAML; wikilink Obsidian.
- Strumenti opzionali rimandati: motore di ricerca (qmd), Marp, Dataview — da valutare quando la scala lo richiederà.

## Pagine collegate

- [[wiki-vs-rag]] — il confronto concettuale al cuore del pattern
- [[memex]] — l'antenato storico dell'idea
