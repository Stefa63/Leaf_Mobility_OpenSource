---
tipo: concetto
creato: 2026-06-12
aggiornato: 2026-06-25
tag: [architettura, leaf-mobility, three-tier]
fonti: [raw/2026-06-12-direttive-leaf-mobility.md]
---

# Architettura three-tier (server LEAF)

Vincolo architetturale **esclusivo e non negoziabile** del server di [[leaf-mobility]] (§4.1 delle [[direttive-leaf-mobility]]): tre livelli con dipendenze solo tra tier adiacenti, **MVC severamente vietato** su server e client.

```
Presentation  →  api_gateway_sicurezza, gestore_attivita
Business      →  gestore_corse, gestore_profili_ekyc, gestore_geofencing,
                 motore_analitica, gestore_assistenza_ticket, gestore_flotta
Integration   →  gateway_pagamenti, data_access_manager, gateway_iot,
                 gateway_routing (sistemaTPL INTEGRATO qui, mai modulo a sé)
```

## Regole di isolamento

- Nessun import tra tier **non adiacenti** (no leaky abstractions): il Presentation non chiama mai endpoint dell'Integration direttamente.
- Il Business Tier resta isolato dai framework di piattaforma (testabile puro).
- Verificato automaticamente dal controllo CI **AG-CI-07** (ispezione degli import cross-layer).
- I sistemi esterni (pagamenti, mappe, IoT, DB) si toccano **solo** attraverso l'Integration Tier.

## Punti d'attenzione

- Il `sistemaTPL` (trasporto pubblico locale) è la trappola classica: sembra un modulo autonomo, ma le direttive impongono che resti **dentro** `gateway_routing`.
- A giugno 2026 il server non è ancora implementato: l'albero `server/` esiste come struttura vuota richiesta dal §5.

## Fondamento teorico

L'architettura a tre tier è applicazione diretta dei [[principi-ingegneria-software|principi]] di **Separazione degli Interessi** e **Modularità** (alta coesione, basso accoppiamento via information hiding): i tre tier sono le «parti» (interfaccia / regole di dominio / dati persistenti) del principio di separazione per parti. Il vincolo «no import tra tier non adiacenti» è basso accoppiamento; `gateway_routing` che incapsula `sistemaTPL` è information hiding.

Più precisamente, è l'istanza dello stile **Layered → Three-tier** insegnato nel corso ([[progettazione-architetturale]], Sommerville cap. 6). La corrispondenza è 1-a-1 con le responsabilità canoniche:

| Tier (corso) | Responsabilità | Componenti LEAF (§4.1) |
|---|---|---|
| Presentation | interazione utenti, sessione, controllo accessi | `api_gateway_sicurezza`, `gestore_attivita` |
| Business | logica di dominio, **realizza i casi d'uso** | `gestore_corse`, `…ekyc`, `…geofencing`, `motore_analitica`, `…ticket`, `gestore_flotta` |
| Integration | comunicazione verso l'esterno e persistenza | `gateway_pagamenti`, `data_access_manager`, `gateway_iot`, `gateway_routing` |

I **sistemi esterni** (§13) sono i componenti **black-box** dietro l'Integration Tier ([[diagramma-dei-componenti]]); il **DB (Cloud Firestore, NoSQL document store)** è il "Resource Tier" del modello a strati — accesso **server-mediato** via `data_access_manager` (`firebase-admin`), mai dai client. *(Il PostgreSQL+PostGIS originario è stato superato il 22/06/2026: NON usare SQL/SQLAlchemy — vedi `wiki/DIRECTIVES.md` §6.)*

> **⚠ Nota MVC (da difendere all'orale):** il corso insegna anche **MVC** come stile valido, ma le direttive lo **vietano** (§3/§4). LEAF usa three-tier (server) + store osservabile `ValueNotifier` (client), non MVC. Argomentazione completa in [[progettazione-architetturale]] (sezione *Tensione teoria ↔ direttive*).

## Pagine collegate

- [[leaf-mobility]] — il progetto
- [[progettazione-architetturale]] — lo stile layered/three-tier e gli altri stili del corso
- [[diagramma-dei-componenti]] — la vista UML che modella i tre tier; sistemi esterni §13 = black-box
- [[principi-ingegneria-software]] — separazione degli interessi e modularità
- [[stream-coding]] — il framework DOE che governa la realizzazione
- [[direttive-leaf-mobility]] — la fonte normativa (§4, §5, §12)
