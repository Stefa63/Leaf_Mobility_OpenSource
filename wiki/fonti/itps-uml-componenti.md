---
tipo: fonte
creato: 2026-06-19
aggiornato: 2026-06-25
tag: [itps, uml, componenti, black-box, interfacce, corso]
fonti: [raw/10_ITPS_UML_Componenti_2024.pptx.pdf]
---

# ITPS — UML: Componenti (e Deployment)

Slide del corso **ITPS** (Caivano · Barletta · Piccinno), 18 slide. Riferimenti: Sommerville cap. 16; Fowler cap. 14. Pagina concetto: → [[diagramma-dei-componenti]].

## Contenuti chiave

- **Componente:** parte del sistema **sostituibile, modulare**, che incapsula l'implementazione ed espone servizi via interfacce ben definite (es. .exe, DLL, EJB, o anche un sottoinsieme di classi). I dettagli implementativi sono nascosti; modificabili senza impattare il resto.
- **Tipi di componente:**
  - **white-box** — funzionamento + implementazione noti e modificabili (es. insieme di classi del sistema);
  - **black-box** — funzionamento noto, implementazione **non** nota né modificabile (es. librerie/framework proprietari, web service);
  - **grey-box** — funzionamento noto, implementazione modificabile ma non necessaria da conoscere (es. open-source).
- **Interfacce:** dei **servizi forniti** (l'API del componente) e dei **servizi richiesti** (ciò che altri componenti devono fornire perché funzioni). I servizi richiesti non definiscono *come* sono forniti → non compromettono l'indipendenza.
- **Diagramma dei componenti:** mostra componenti e dipendenze (non le istanze). Può mostrare il contenuto (classi) di un componente white-box.
- **Mapping classi ↔ componenti:** nel diagramma dei componenti si mostrano le classi contenute (white-box); nel diagramma delle classi si indica il componente di appartenenza di ciascuna classe.

## Collegamenti al progetto

- I sistemi esterni delle direttive (§13: ~~PostgreSQL/PostGIS~~ → **Cloud Firestore**, Stripe, Google Maps, IoT, GPS) sono **esattamente componenti black-box** — l'UML conferma il termine usato dal progetto, accessibili solo via [[architettura-three-tier|Integration Tier]]. *(Il DB nell'UML era PostgreSQL/PostGIS; superato il 22/06/2026 da **Cloud Firestore** NoSQL server-mediato — NON SQL/SQLAlchemy, `wiki/DIRECTIVES.md` §6.)*
- Il `Diagramma_Componenti.png` del team modella i tre tier; le interfacce «servizi forniti/richiesti» corrispondono alle interfacce tra tier (Access/Collection/Map/GPS/Bank/Mezzi).
- Il **mapping classi↔componenti** è il legame da presidiare tra `Diagramma_Componenti.png` e `Leaf_Mobility_Classi.jpg`.

## Pagine collegate

- [[diagramma-dei-componenti]] · [[architettura-three-tier]] · [[diagramma-delle-classi]]
- [[uml]] · [[leaf-mobility]] · [[direttive-leaf-mobility]]
