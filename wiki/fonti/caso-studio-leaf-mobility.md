---
tipo: fonte
creato: 2026-06-13
aggiornato: 2026-06-13
tag: [leaf-mobility, sprint-2, deliverable, casi-uso, architettura, unibara]
fonti: [raw/2026-06-13-caso-studio-leaf-mobility.pdf]
---

# Caso di studio LEAF Mobility — Sprint Report N. 2 (deliverable UNIBA)

> Fonte: [raw/2026-06-13-caso-studio-leaf-mobility.pdf](../raw/2026-06-13-caso-studio-leaf-mobility.pdf) — documento ufficiale del corso di Ingegneria del Software a.a. 2025-2026, 127 pagine, intestato **SPRINT REPORT N. 2**. Autori: Lamanna Manuel Antonio (832222), Convertino Stefano (827602), Galesi Jarno (829867), Galesi Victor (829396). È la **fonte primaria** da cui derivano le [[direttive-leaf-mobility]]: in caso di dubbio sui requisiti, è il riferimento autoritativo.

## In una frase

Il documento di progetto completo di [[leaf-mobility]] fino allo Sprint 2: dal Product Backlog (item funzionali/non funzionali) allo Sprint Report (18 casi d'uso, architettura a componenti, diagramma delle classi, diagrammi di sequenza, modello dati) fino ai prompt usati nello sviluppo di Sprint 1 e 2.

## Struttura del documento

| Sezione | Contenuto |
|---|---|
| **1. Product Backlog** | Introduzione, contesto di business (Comune di Zootropolis), stakeholder (Utenti, Operatori, PA), Item Funzionali (IF) e Non Funzionali — Informativi (IIN), di Interfaccia (IUI), Qualitativi (IQ), Altri |
| **2. Sprint Report N. 2** | Sprint Backlog; Product Requirement Specification (**18 casi d'uso UC01–UC18** con scenari base/alternativi); System Architecture (componenti + interfacce); Detailed Product Design (diagramma + specifiche delle classi, diagrammi di sequenza); Data Modeling (modello logico/fisico DB) |
| **3–4. Prompt** | Qualità dei requisiti, definizioni, sviluppo interfacce; log dei prompt di **Sprint 1** e **Sprint 2** |

## I 18 casi d'uso (UC01–UC18)

- **Utente:** UC01 Gestione Account e KYC · UC02 Profilo/pagamenti/abbonamenti · UC03 Ricerca mezzi/mappa/percorsi · UC04 Stime tempi/costi/percorsi · UC05 Inizio/Pausa/Fine corsa e fatturazione · UC06 Assistenza e SOS · UC07 Gestione noleggi e annullamenti
- **Operatore:** UC08 Estrazione eventi/LOG/report · UC09 Monitoraggio mappa/flotta/telemetria · UC10 Manutenzione e ticket · UC11 Configurazione regole e incentivi · UC12 Controllo remoto e allarmi · UC13 Gestione utenti/AP e assistenza
- **Pubblica Amministrazione:** UC14 Accesso e gestione account AP · UC15 Heatmap e dashboard · UC16 Estrazione report · UC17 Definizione aree limitate · UC18 Gestione variabilità (cantieri, eventi)

I casi d'uso sono tracciabili 1-a-1 con le user story del Product Backlog (UT/OP/AP, vedi [[direttive-leaf-mobility]]) e ciascuno ha un diagramma di sequenza associato.

## Architettura a componenti (conferma la [[architettura-three-tier]])

I nomi del documento mappano esattamente sui moduli delle direttive:

- **Client:** AppMobileUtente · WebDashboard (MFA obbligatoria)
- **Presentation:** APIGatewayESicurezza (unico punto d'accesso, MFA+RBAC) · GestoreAttività (orchestratore/instradamento)
- **Business:** GestoreCorse · GestoreProfiliEKYC · GestoreGeofencing · MotoreDiAnalitica (anonimizzazione PA, heatmap, CO₂) · GestoreAssistenzaETicket (SOS) · GestoreFlotta (telemetria)
- **Integration:** GatewayPagamenti · DataAccessManager (persistenza + cifratura) · GatewayIoT · GatewayRouting (mappe + TPL multimodale)
- **Sistemi esterni black-box:** DBMS SQL · SistemaBancario (Stripe) · ServizioMappa (Google Maps) · MezzoFisico · LocalizzazioneUtente (GPS nativo) — combaciano con §13 delle direttive.

## ⚠ Contraddizioni — stato

1. **Formati KYC — ✅ allineato (13/06/2026).** UC01 (Requisiti) dichiarava «documento d'identità in formato **JPEG/PNG**, max **5 MB**». La versione **autoritativa** è quella della specifica del componente *GestoreProfiliEKYC* e delle [[direttive-leaf-mobility]] (§7.3 e IIN-6): **PDF, JPG, PNG**. Il testo di UC01 nel deliverable è una svista di redazione (omette il PDF, introduce un cap di 5 MB non previsto altrove) da correggere alla prossima revisione del documento. Per l'implementazione fa fede **PDF/JPG/PNG**.

## Note di tracciabilità

- Le sezioni **2.5.1 / 2.5.2 (modello logico/fisico del DB)** sono volutamente **placeholder**: il database **deve ancora essere progettato** — coerente con lo stato del progetto (server e DB non ancora implementati, vedi [[leaf-mobility]] e [[architettura-three-tier]]). Non è una lacuna documentale ma un'attività pianificata per uno sprint successivo.
- Il team coincide con i programmatori elencati in §9 delle direttive (Jarno · Victor · Stefano · Manuel).

## Pagine collegate

- [[leaf-mobility]] — la scheda del progetto
- [[direttive-leaf-mobility]] — le direttive operative derivate da questa fonte
- [[architettura-three-tier]] — il vincolo architetturale confermato dalla §2.3
- [[casi-uso-leaf]] — i 18 UC in dettaglio
