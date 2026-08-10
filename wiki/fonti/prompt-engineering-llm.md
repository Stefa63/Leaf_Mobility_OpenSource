---
tipo: fonte
creato: 2026-06-29
aggiornato: 2026-06-29
tag: [prompt-engineering, llm, ai, tecniche, corso, seminario]
fonti: ["raw/09_Prompt Engineering Ingegneria 2026.pdf"]
---

# Prompt Engineering — progettare il dialogo con gli LLM

Seminario **ITPS A.A. 2025/2026** di **Alfonso Pio Pretorino** (dottorando, Università di Bari), **53 slide**. Tratta i fondamenti degli LLM, i loro limiti, e le tecniche di prompt engineering. È la teoria diretta del modo in cui [[leaf-mobility]] è stato sviluppato (agente AI guidato da prompt strutturati). Pagina concetto: → [[prompt-engineering]].

## Fondamenti LLM

- **Cos'è un LLM:** non un cervello biologico; **predice il token più probabile** dato il contesto («Roma è la capitale ___»). Richiede enorme capacità di calcolo per l'addestramento; non "pensa".
- **Token e tokenizer:** il prompt è diviso in **token** (parola/sillaba/lettera); ogni token = intero del **vocabolario**; il tokenizer converte testo↔token.
- **Context window:** numero massimo di token per richiesta. Limiti: **«Lost in the Middle»** (primacy/recency bias, −30% accuratezza al centro), **«Context Rot»** (declino al riempirsi della finestra), **costo e latenza** (crescita ~esponenziale).

## Problemi comuni

- **Allucinazioni:** informazioni false ma plausibili → minano la fiducia, vanno verificate.
- **Aggiornamento:** modelli con conoscenza obsoleta; riaddestrare è costoso.
- **Bias:** risultati distorti dai dati di training (caso reale: il recruiting AI di Amazon penalizzava le candidate donne → progetto abbandonato).

## Prompt Engineering — definizione e principi

- **Definizione:** «processo di progettazione e ottimizzazione dei prompt di input per guidare efficacemente le risposte di un LLM». Obiettivi: massimizzare l'utilità, superare allucinazioni e bias, migliorare l'accuratezza.
- **Equilibrio del contesto:** troppo contesto → output rigido; troppo poco → output non controllato; struttura confusa → degrado.
- **I 5 principi:** 1) **Dare indicazioni** (stile/persona) · 2) **Specificare il formato** (regole, struttura) · 3) **Fornire esempi** (casi di prova) · 4) **Valutare la qualità** (errori, testing) · 5) **Dividere il lavoro** (scomporre in passi concatenati).

## Tecniche

- **Step by step** («Let's think step by step»).
- **Role-Based Prompting** (assegnare un ruolo/persona: competenze specifiche, stile, prospettive diverse, coinvolgimento).
- **Zero- / One- / Few-Shot** (nessun / uno / più esempi nel prompt).
- **Chain-of-Thought** (il modello "pensa ad alta voce", utile per ragionamenti complessi).
- **Generated Knowledge** (processo a due step: genera conoscenza → risponde con quel contesto).
- **Metodi di base:** **delimitatori** (`"""…"""` separano dati da istruzioni → anti **prompt injection**), **impostazioni LLM** (Temperatura 0.1–0.3 deterministico / 0.7–1.0 creativo; Top-k/Top-p), **trial-and-error** (generare più risposte e selezionare la migliore).
- **Sicurezza:** i delimitatori prevengono la *prompt injection* trattando l'input utente come dato, non come comando.

## Caso di studio — eSpeechT

Web-app a supporto del **logopedista** (esercizi, appuntamenti, monitoraggio; attori logopedista/caregiver/paziente). Una **pipeline di prompt** progettata e testata genera esercizi (es. oggetto "Spoon" con hint e rationale) confrontati con quelli del logopedista → gli LLM possono supportare la creazione di esercizi.

## Collegamenti al progetto

- I **5 principi** sono esattamente la disciplina con cui sono scritte le **Direttive Inviolabili** e i prompt di sprint di [[leaf-mobility]]: dare indicazioni (DOE [D]), specificare il formato (template §9/§12.4), fornire esempi, valutare (gate CI/CD §12), **dividere il lavoro** (cascate/blocchi/sprint).
- **Lost in the Middle / Context Rot** ↔ motivano la [[llm-wiki-pattern|wiki LLM]] come memoria compilata esterna alla finestra di contesto (vedi [[wiki-vs-rag]]).
- **Prompt injection / delimitatori** ↔ la separazione tra istruzioni di sistema e input utente, e i controlli di sicurezza al confine `/api/v1`.
- **Role-Based Prompting** ↔ i ruoli per-modello del DOE (Claude = backend/architettura, Antigravity = UI).

## Pagine collegate

- [[prompt-engineering]] · [[llm-wiki-pattern]] · [[wiki-vs-rag]] · [[stream-coding]]
- [[direttive-leaf-mobility]] · [[leaf-mobility]]
