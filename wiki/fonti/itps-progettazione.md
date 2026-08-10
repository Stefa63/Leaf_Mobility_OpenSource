---
tipo: fonte
creato: 2026-06-29
aggiornato: 2026-06-29
tag: [itps, progettazione, modularita, information-hiding, architettura, corso]
fonti: [raw/07.1_ITPS_Progettazione_2026.pptx.pdf]
---

# ITPS — La Progettazione Software

Slide del corso **ITPS A.A. 2025/2026** (Barletta · Caivano · Piccinno), **44 slide**. Riferimento: Ghezzi · Jazayeri · Mandrioli, *Ingegneria del Software — Fondamenti e Principi* (cap. 5). È la teoria **generale** della progettazione, complementare alla [[itps-progettazione-architetturale|progettazione architetturale]] (07.2) che ne è la specializzazione sugli stili. Pagine concetto: → [[modularita]], → [[information-hiding]].

## Contenuti chiave

- **Progetto software (IEEE):** la *progettazione* (processo di definizione di architettura, componenti, interfacce) e il *progetto dell'applicazione* (il prodotto). Ruolo: produrre modelli alternativi, valutarli, scegliere il miglior compromesso requisiti↔qualità, pianificare codifica e test.
- **Pratiche di progettazione** (linee guida dei principi): Decomposizione e **Modularità** (coesione alta, accoppiamento basso); **Generalizzazione** (risolvere il problema più generale → riuso, via parametrizzazione); **Incapsulamento/Information Hiding** (sintesi di Separazione degli Interessi + Astrazione); **Anticipazione dei cambiamenti** (plug-in, linee di prodotto); **Sufficienza, completezza e ricerca di primitive**.

### Modularità → [[modularita]]
- Sistema = insieme di moduli fornitori di **servizi**. Relazioni binarie tra moduli.
- **USES** (A usa B = A client, B server; statica, indipendente dall'esecuzione): preferibile **gerarchica (DAG aciclico)** → comprensione bottom-up, riuso, validazione, manutenibilità. Un ciclo → «niente funziona finché tutto non funziona».
- **Fan-in alto** (molto riuso) e **fan-out basso** (poche dipendenze) = buona struttura.
- L'**interfaccia** è un *contratto* tra modulo e client e l'astrazione delle capacità del server; la chiara distinzione interfaccia↔implementazione è principio chiave (Separazione degli Interessi).
- **Is-Component-Of / Comprises:** gerarchia di composizione (un modulo di alto livello è composto da moduli di livello più basso).

### Information Hiding → [[information-hiding]]
- Obiettivo: cambiare il comportamento di una componente senza conoscere né modificare le altre. Strategia: nascondere ogni decisione in un modulo, isolare i dettagli instabili, interfacce stabili.
- Tre tipi: **HW/SW hiding** (accesso dati/DBMS, I/O, comunicazione), **Behavior hiding** (interfaccia uomo-macchina, regole di produzione dati), **Decision hiding** (politiche di implementazione, parametri di sistema).

### Processo, Architettura, Dettaglio
- **Manufatti:** Architettura (decomposizione/organizzazione in componenti) + Progetto Dettagliato (comportamento e collaborazione). **Strategie:** funzionale, OO, centrata sui dati, **basata sulle componenti** (riuso; componenti di qualità non dipendono da componenti di qualità inferiore).
- **Stili architetturali:** Layers, pipes&filters, blackboard; **client-server, three-tier**, broker; MVC, PAC. **Pattern · Framework · Linee di prodotto.**
- **Problemi del dominio dei sistemi:** concorrenza, eventi/call-back, deployment, errori/eccezioni, dati comuni, **persistenza** (ciclo di vita dei dati).
- **Tipi di componenti:** **black box** (terze parti, impl. nascosta — es. Google Maps), **white box** (tutto noto), **grey/glass box** (codice disponibile non necessariamente modificabile — es. open source).

### Interfacce Uomo-Macchina + V&V
- **Principi UI:** apprendibilità, familiarità, consistenza, recuperabilità, guida all'utente, diversità degli utenti. Stili d'interazione (quesiti-risposte, manipolazione diretta, menu, moduli, comandi, linguaggio naturale). Uso accorto dei **colori** (pochi, consistenti, accessibilità daltonici).
- **V&V:** Verifica (conformità/correttezza del modello, ispezione) · Validazione (statica = ispezione; dinamica = prototipi, test di integrazione e di sistema).

## Collegamenti al progetto

- Il **three-tier** §4 di [[leaf-mobility]] applica `USES` gerarchico: nessun import tra tier non adiacenti = grafo aciclico, fan-out controllato → vedi [[architettura-three-tier]].
- I **black-box** §13 (Firestore, Stripe, Google Maps, IoT) sono esattamente i «componenti black box» di queste slide → [[diagramma-dei-componenti]].
- **Information Hiding** ↔ `DataAccessManager` che nasconde la persistenza (HW/SW hiding) dietro un'interfaccia stabile; i gateway che nascondono i sistemi esterni.
- I **principi UI** ↔ requisiti IIN-2 (usabilità on-the-go), IIN-3 (accessibilità), e l'uso minimalista del colore richiesto dalle direttive.

## Pagine collegate

- [[modularita]] · [[information-hiding]] · [[progettazione-architetturale]] · [[architettura-three-tier]]
- [[diagramma-dei-componenti]] · [[principi-ingegneria-software]] · [[leaf-mobility]]
