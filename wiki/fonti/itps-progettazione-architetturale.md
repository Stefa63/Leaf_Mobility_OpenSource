---
tipo: fonte
creato: 2026-06-19
aggiornato: 2026-06-19
tag: [itps, architettura, layered, three-tier, mvc, client-server, corso]
fonti: [raw/07.2_ITPS_Progettazione_Architetturale_2026.pptx.pdf]
---

# ITPS — Progettazione Architetturale

Slide del corso **ITPS A.A. 2025/2026** (Barletta · Caivano · Piccinno), 38 slide. Riferimento: Sommerville cap. 6. È il **fondamento teorico diretto** dell'architettura di [[leaf-mobility]]. Pagina concetto: → [[progettazione-architetturale]].

## Contenuti chiave

- **Cos'è:** primo stadio della progettazione; collegamento critico tra ingegneria dei requisiti e progettazione; identifica i componenti strutturali principali e le relazioni. Influenza predominante sulle caratteristiche **non funzionali**.
- **Vantaggi della documentazione esplicita:** comunicazione tra stakeholder, analisi del sistema (conformità a prestazioni/affidabilità/manutenibilità), riuso su vasta scala.
- **Viste architetturali:** logica, dei processi, dello sviluppo, fisica.
- **Schemi/stili architetturali:** descrizioni stilizzate di buone pratiche provate; individuano parti con responsabilità omogenee e le relazioni. Esempi: **Layers, Client/Server, MVC**.

### Architettura a strati (Layers) → Three-tier
- Separazione e indipendenza per **localizzare le modifiche**; ogni strato usa i servizi di quello sottostante. Punti di forza: riuso, separazione interessi, manutenibilità, portabilità; debolezze: meno flessibilità, possibile minore efficienza.
- Forma specifica più comune: **Three-tier** — (1) gestione interazione utenti, (2) logica di dominio, (3) interfaccia verso servizi esterni:
  - **Presentation Tier:** intercetta le richieste client, single sign-on, gestione sessione, controllo accessi ai servizi di business, costruisce risposte. *Cambiamenti frequenti, flessibile.*
  - **Business Tier:** incapsula logica e dati di business; **realizza i casi d'uso**; interfaccia stabile.
  - **Integration Tier:** comunicazione verso l'esterno (data store, sistemi esterni/legacy), dati persistenti. *Cambiamenti poco frequenti, ottimizza l'accesso a risorse esterne.*

### MVC (Model-View-Controller)
- Divide un'applicazione interattiva in Model (dati+logica), View (presentazione), Controller (input). Observer per la propagazione dei cambiamenti. Si usa con UI flessibili / viste multiple. ⚠ Le **direttive del progetto vietano MVC** (§3/§4): tensione discussa in [[progettazione-architetturale]].

### Client/Server
- Stile per sistemi distribuiti: server espone servizi via interfaccia, più client concorrenti; connettori = formato+protocollo. Varianti stateless/stateful. Modello a 3 strati logici: Web Server · Application Server · DB Server.

## Collegamenti al progetto

- L'architettura §4.1 delle direttive (Presentation/Business/Integration) è **esattamente il three-tier di questa slide**: il progetto è textbook-correct. Vedi [[architettura-three-tier]].
- «Il Business Tier realizza i casi d'uso» ↔ [[casi-uso-leaf]].
- Il progetto è insieme **client/server** (client Flutter + server FastAPI) e **layered** (server a tre tier).

## Pagine collegate

- [[progettazione-architetturale]] · [[architettura-three-tier]]
- [[principi-ingegneria-software]] · [[diagramma-dei-componenti]] · [[leaf-mobility]] · [[direttive-leaf-mobility]]
