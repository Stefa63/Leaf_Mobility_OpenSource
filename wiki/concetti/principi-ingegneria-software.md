---
tipo: concetto
creato: 2026-06-19
aggiornato: 2026-06-19
tag: [principi, modularita, separazione-interessi, astrazione, corso]
fonti: [raw/03_ITPS_Principi_Ingegneria_Software_2026.pptx.pdf]
---

# I 7 principi dell'Ingegneria del Software

I principi descrivono **proprietà desiderabili** di prodotti e processi in termini generali e astratti, indipendenti da contesto, tipo di sistema e ambiente. Si trasformano in pratica attraverso metodi → tecniche → metodologie → strumenti. Fonte: [[itps-principi-ingegneria-software]] (Ghezzi-Jazayeri-Mandrioli, cap. 3). La **modularità è la pietra angolare** della progettazione.

## I principi

1. **Rigore e Formalità.** Il rigore è coerenza con pre-condizioni, scopo, metodo e tecniche. La formalità (uso di formalismi matematici) è il grado massimo: consente generazione/verifica automatica. *Vantaggio:* documentazione tracciabile e manutenibile. *Svantaggio:* difficile mantenere rigore costante; il formalismo costa.
2. **Separazione degli Interessi.** Separare le decisioni su aspetti diversi dello stesso problema: per **tempo** (analisi vs progettazione), **caratteristiche**, **prospettive** (stakeholder), **parti** (interfaccia / regole di dominio / dati persistenti). *Svantaggio:* aspetti con caratteristiche comuni non vanno separati (rischio di perdere ottimizzazioni).
3. **Modularità.** Moduli ad **alta coesione interna** e **basso accoppiamento**, garantiti dall'**information hiding**. Top-Down (scomposizione) o Bottom-Up (composizione). *Svantaggio:* eccessiva frammentazione riduce la comprensibilità.
4. **Anticipazione del Cambiamento.** Accogliere i cambiamenti con poco impegno, tempo e rischio: minore accoppiamento dove maggiore è la volatilità; serve Gestione della Configurazione Software. È ciò che distingue il software dagli altri beni.
5. **Astrazione.** Estrarre gli aspetti significativi trascurando i dettagli irrilevanti per lo scopo; produce modelli a livelli diversi per destinatari diversi.
6. **Generalità.** Riformulare il problema come istanza di uno più generale, riusabile altrove; abilita prodotti off-the-shelf. *Svantaggio:* maggiori costi di sviluppo della soluzione generale.
7. **Incrementalità.** Sviluppo per incrementi successivi a qualsiasi livello di astrazione; più validazioni, minore rischio di non rispondere ai requisiti. *Svantaggi:* rischi di integrazione e costi di test crescenti.

## Coesione vs Accoppiamento (lo "scudo contro l'obsolescenza")

La combinazione **alta coesione + basso accoppiamento + information hiding** (modularità) con l'**anticipazione del cambiamento** è ciò che rende un sistema resistente all'obsolescenza.

## Mappatura su LEAF Mobility

| Principio | Dove si manifesta nel progetto |
|---|---|
| Separazione degli Interessi / Modularità | [[architettura-three-tier]]: Presentation/Business/Integration; Business isolato dai framework; `sistemaTPL` incapsulato in `gateway_routing`. Le "parti" (interfaccia/dominio/dati) sono i tre tier. |
| Rigore e Formalità | Direttive come specifica rigorosa; gate CI/CD (§12); Doxygen (§7.1); SQALE (§17). |
| Anticipazione del Cambiamento | Basso accoppiamento tra tier (no import non adiacenti); sistemi esterni come black-box dietro l'Integration Tier. |
| Astrazione | Diagrammi UML (componenti, classi, sequenze) come modelli a livelli; requisiti astratti indipendenti dall'implementazione. |
| Incrementalità | Sviluppo a **sprint** (Sprint 1→3) con versionamento alpha. |
| → estensione AI | I principi applicati all'AI-coding diventano [[stream-coding]] (il framework DOE). |

## Pagine collegate

- [[stream-coding]] — i principi applicati allo sviluppo assistito da AI
- [[architettura-three-tier]] · [[qualita-del-software]]
- [[itps-principi-ingegneria-software]] · [[direttive-leaf-mobility]]
