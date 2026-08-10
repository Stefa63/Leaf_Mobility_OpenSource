---
tipo: fonte
creato: 2026-06-19
aggiornato: 2026-06-25
tag: [itps, ingegneria-software, qualita, ciclo-di-vita, corso]
fonti: [raw/02_ITPS_Concetti_Generali_2026.pptx.pdf]
---

# ITPS — Concetti Generali (Introduzione all'Ingegneria del Software)

Slide del corso **ITPS A.A. 2025/2026** (Barletta · Caivano · Piccinno, UNIBA), 41 slide. Introduce natura del software, ciclo di vita, qualità e tipi di prodotto. Riferimento: Ghezzi, Jazayeri, Mandrioli, *Ingegneria del Software — Fondamenti e Principi*, capp. 1–2.

## Contenuti chiave

- **Programmare in piccolo vs in grande:** l'ingegnere del software non solo programma (dati, algoritmi, linguaggi) ma sviluppa modelli, lavora in gruppo, gestisce progetti e coordina (programmazione *in grande*).
- **Ciclo di vita (Modello a Cascata):** Analisi e specifica requisiti → Progettazione e specifica → Codifica e test di modulo → Integrazione e test di sistema → Consegna e manutenzione. Ogni fase produce artefatti trasferiti alla successiva.
- **La qualità come valore centrale.** Convergenza qualità di *processo* e di *prodotto*. → [[qualita-del-software]].
- **Le tre prospettive della qualità (ISO 25000):** qualità *in uso* (percepita), *interna* (attributi statici del codice), *esterna* (comportamento dinamico). Si influenzano a vicenda.
- **Caratteristiche di qualità:** correttezza, affidabilità, robustezza, usabilità, manutenibilità (riparabilità + evolvibilità), riusabilità, prestazioni, verificabilità, portabilità, interoperabilità, ecc. → [[qualita-del-software]].
- **Tipi di prodotto software:** Programma → Applicazione → **Sistema Software** (alta qualità + documentazione completa: requisiti, progettazione, manuali). LEAF Mobility punta a essere un *sistema software*.
- **Applicazioni d'impresa:** dati persistenti e voluminosi, accesso concorrente, molte schermate, integrazione tra domini — profilo che descrive bene LEAF.
- **Inadeguatezza dei processi sequenziali (Waterfall)** di fronte a requisiti volatili → tecniche basate su **architettura** (information hiding, modularità) o su **refactoring** → processi guidati da piani (RUP, Spirale, Waterfall) vs **processi Agili** (SCRUM, XP, FDD…). → [[ciclo-di-vita-del-software]].

## Collegamenti al progetto

- LEAF è un **sistema software** software-intensivo con applicazioni d'impresa (dashboard a molte schermate, dati persistenti). *(La fonte citava PostGIS; il progetto usa ora **Cloud Firestore** NoSQL — vedi `wiki/DIRECTIVES.md` §6, NON SQL/SQLAlchemy.)*
- La qualità ISO 25000 è già citata nelle direttive (§7.2): correttezza, manutenibilità, prestazioni (refresh ≤5s), affidabilità (sync offline).
- Approccio Agile/Scrum → gli sprint del progetto ([[leaf-mobility]]).

## Pagine collegate

- [[qualita-del-software]] · [[principi-ingegneria-software]] · [[ciclo-di-vita-del-software]]
- [[leaf-mobility]] · [[direttive-leaf-mobility]]
