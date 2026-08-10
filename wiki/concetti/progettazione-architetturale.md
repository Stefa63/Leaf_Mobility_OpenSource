---
tipo: concetto
creato: 2026-06-19
aggiornato: 2026-06-19
tag: [architettura, layered, three-tier, mvc, client-server, stili, corso]
fonti: [raw/07.2_ITPS_Progettazione_Architetturale_2026.pptx.pdf]
---

# Progettazione Architetturale

Primo stadio della progettazione: organizza il sistema e ne definisce la struttura complessiva. È il **collegamento critico tra requisiti e progettazione** e ha l'influenza predominante sulle caratteristiche **non funzionali** (prestazioni, affidabilità, manutenibilità). Fonte: [[itps-progettazione-architetturale]] (Sommerville cap. 6).

## Stili (schemi) architetturali

Uno stile è una soluzione provata e riusabile a un problema ricorrente di organizzazione. I principali trattati nel corso:

### Layered → Three-tier
Strati sovrapposti, ciascuno usa i servizi di quello sottostante, organizzati per livello di astrazione. Localizza le modifiche, massimizza intercambiabilità e coesione delle responsabilità. La forma più comune è il **three-tier**:

| Tier | Responsabilità | Volatilità |
|---|---|---|
| **Presentation** | interazione utenti: intercetta richieste, SSO, sessione, controllo accessi, risposte | cambia spesso, flessibile |
| **Business** | logica e dati di dominio; **realizza i casi d'uso**; interfaccia stabile | stabile |
| **Integration** | comunicazione verso l'esterno: data store, sistemi esterni/legacy, persistenza | cambia raramente, ottimizzata |

→ È esattamente l'architettura di [[architettura-three-tier|LEAF Mobility]].

### Client/Server
Sistemi distribuiti: un server espone servizi via interfaccia ben definita, più client concorrenti; connettori = formato+protocollo. Varianti stateless/stateful. Modello a 3 strati logici: Web · Application · DB Server.

### MVC (Model-View-Controller)
Applicazione interattiva divisa in Model (dati+logica), View (presentazione), Controller (input), con propagazione Observer. Adatto quando ci sono viste multiple o requisiti di interazione non noti.

## ⚠ Tensione teoria ↔ direttive: MVC

Il corso presenta **MVC** come uno stile valido e diffuso per applicazioni interattive; le **direttive del progetto lo vietano esplicitamente** (§3: «NEVER use MVC pattern — strictly prohibited on server AND client»; §4.2: «No MVC pattern»). Non è un errore del progetto ma una **scelta di progettazione deliberata da saper difendere all'orale**:

- LEAF struttura il **server** con lo stile **layered/three-tier** (separazione per *tier* tecnologici, non per Model/View/Controller) e il **client** con uno store osservabile (`ValueNotifier`) + widget, senza Controller espliciti.
- **Motivazione del team (rationale di progetto):** MVC è stato escluso per
  1. **Semplicità** — un solo asse di separazione (i tier) anziché due (tier + Model/View/Controller), che ridurrebbe la complessità senza un beneficio richiesto dalla consegna;
  2. **Facile individuazione della posizione degli elementi** — con i tier ogni elemento ha una collocazione netta e prevedibile, quindi è immediato sapere *dove* vive una responsabilità;
  3. **Locus unico del calcolo** — tutta la logica di recupero delle informazioni ed esecuzione delle operazioni risiede da una sola parte (il Business/Integration Tier lato server), mantenendo il client sottile (sola presentazione). MVC, distribuendo logica tra Model e Controller, frammenterebbe questo locus.

  Questo rationale è coerente con il modello di corso: nel three-tier «la maggior parte delle elaborazioni di business è concentrata nel Business Tier», ed è in linea con il framework [[stream-coding|DOE]] (logica deterministica spinta nel codice server, [E] Execution).
- Argomento difensivo aggiuntivo: three-tier e MVC risolvono problemi diversi (separazione orizzontale per livelli di servizio vs separazione dell'app interattiva); MVC introdurrebbe un secondo asse di separazione non richiesto.
- Punto onesto: poiché i `ValueNotifier` realizzano di fatto un legame Model↔View di tipo Observer, all'orale conviene spiegare la differenza tra «non adottare il *pattern* MVC come organizzazione» e «usare il meccanismo di notifica osservabile».

## Decisioni e viste

Domande guida (slide 7): stile/schema da usare, distribuzione tra processori, strategia di controllo, scomposizione in sottocomponenti, organizzazione migliore per i requisiti non funzionali, come documentare. Viste: logica, processi, sviluppo, fisica (cfr. le [[uml|4+1 di Kruchten]]).

## Pagine collegate

- [[architettura-three-tier]] — l'istanza nel progetto
- [[principi-ingegneria-software]] — separazione/modularità/anticipazione del cambiamento
- [[diagramma-dei-componenti]] · [[casi-uso-leaf]] · [[itps-progettazione-architetturale]] · [[direttive-leaf-mobility]]
