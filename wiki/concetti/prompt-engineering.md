---
tipo: concetto
creato: 2026-06-29
aggiornato: 2026-06-29
tag: [prompt-engineering, llm, ai, tecniche, sicurezza]
fonti: ["raw/09_Prompt Engineering Ingegneria 2026.pdf"]
---

# Prompt Engineering

Processo di **progettazione e ottimizzazione dei prompt** per guidare efficacemente un LLM, massimizzandone l'utilità e mitigando allucinazioni e bias. Fonte: [[prompt-engineering-llm]]. È la disciplina operativa con cui è stato condotto lo sviluppo AI-assistito di [[leaf-mobility]].

## I 5 principi

1. **Dare indicazioni** — stile/persona desiderati in dettaglio.
2. **Specificare il formato** — regole e struttura della risposta.
3. **Fornire esempi** — casi di prova diversificati.
4. **Valutare la qualità** — individuare errori, testare cosa influenza le prestazioni.
5. **Dividere il lavoro** — scomporre in passi concatenati.

## Tecniche principali

- **Step by step** · **Role-Based** · **Zero/One/Few-Shot** · **Chain-of-Thought** · **Generated Knowledge**.
- **Base:** delimitatori (`"""…"""`), impostazioni (Temperatura, Top-k/Top-p), trial-and-error.

## Limiti da governare

- **Allucinazioni**, **bias**, conoscenza **obsoleta**.
- Finestra di contesto: **«Lost in the Middle»**, **«Context Rot»**, costo/latenza.
- **Prompt injection:** mitigata dai **delimitatori** che trattano l'input utente come dato, non come comando.

## Realizzazione in LEAF Mobility

| Principio/tecnica | Nel progetto |
|---|---|
| Dare indicazioni / Role-Based | Ruoli per-modello del **DOE** (Claude backend, Antigravity UI); persona "ingegnere del software" |
| Specificare il formato | Template rigidi §9 (prompt log) e §12.4 (report CI/CD); inviluppo `{disponibile,messaggio,dati}` |
| Fornire esempi / valutare | Gate **CI/CD AG-CI/AG-SEC** §12 come "valutazione della qualità" automatica |
| Dividere il lavoro | Sviluppo a **sprint / cascate / blocchi**; «esegui poco alla volta» |
| Mitigare Context Rot | La **[[llm-wiki-pattern|wiki LLM]]** come memoria compilata fuori dalla finestra di contesto |
| Prompt injection / delimitatori | Separazione istruzioni-di-sistema ↔ input utente; controlli di sicurezza al confine `/api/v1` |

## Pagine collegate

- [[prompt-engineering-llm]] · [[llm-wiki-pattern]] · [[wiki-vs-rag]] · [[stream-coding]]
- [[direttive-leaf-mobility]] · [[leaf-mobility]]
