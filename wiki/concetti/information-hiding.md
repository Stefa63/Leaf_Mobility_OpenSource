---
tipo: concetto
creato: 2026-06-29
aggiornato: 2026-06-29
tag: [information-hiding, incapsulamento, astrazione, progettazione]
fonti: [raw/07.1_ITPS_Progettazione_2026.pptx.pdf]
---

# Information Hiding

Pratica di progettazione (Parnas) che **nasconde le decisioni e i dettagli instabili** dentro singoli moduli, dietro interfacce stabili, così da poter cambiare il comportamento di una componente **senza conoscere né modificare** le altre. Sintetizza i principi di **Separazione degli Interessi** e **Astrazione**. Fonte: [[itps-progettazione]].

## Strategia

- Ogni decisione di progetto è nascosta singolarmente in un modulo.
- I **dettagli instabili** sono isolati in componenti specifiche; i dettagli indipendenti in componenti separate.
- Le **interfacce restano stabili** anche quando cambiano le implementazioni.
- La valutazione della **stabilità** è a carico del progettista (conoscenza del dominio e delle piattaforme HW/SW).

## Tre tipi (linee guida)

| Tipo | Cosa nasconde | Cambia quando |
|---|---|---|
| **HW/SW hiding** | accesso dati/DBMS, I/O, comunicazione/rete | cambia la macchina virtuale |
| **Behavior hiding** | interfaccia uomo-macchina, regole di produzione dei dati, algoritmi | cambiano le specifiche |
| **Decision hiding** | politiche di implementazione, parametri di sistema, configurazione | cambiano le decisioni tecniche |

## Realizzazione in LEAF Mobility

- **HW/SW hiding** ↔ il **`DataAccessManager`** (Integration Tier) nasconce **Cloud Firestore** dietro metodi CRUD a documenti: il Business Tier non sa se sotto c'è Firestore, l'emulatore o il client fake in-memory. La **deviazione di persistenza** PostgreSQL→Firestore (2026-06-22) è stata indolore per il Business **proprio grazie** a questo hiding.
- **Behavior hiding** ↔ i **gateway** (`GatewayPagamenti`, `GatewayIot`, `GatewayRouting`, `GatewayEmail`) nascondono i sistemi esterni §13 dietro interfacce stabili; le simulazioni locali deterministiche sono intercambiabili con i provider reali senza toccare il dominio.
- **Decision hiding** ↔ `Impostazioni`/`config.json` e le variabili `.env` (`LEAF_*`) isolano i parametri di configurazione del runtime.
- L'**interfaccia stabile** `/api/v1` permette di evolvere il backend senza rompere i client.

## Pagine collegate

- [[modularita]] · [[itps-progettazione]] · [[diagramma-dei-componenti]] · [[architettura-three-tier]]
- [[principi-ingegneria-software]] · [[leaf-mobility]]
