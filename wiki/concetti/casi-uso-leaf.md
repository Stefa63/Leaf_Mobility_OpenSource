---
tipo: concetto
creato: 2026-06-13
aggiornato: 2026-06-13
tag: [leaf-mobility, casi-uso, requisiti, sprint-2]
fonti: [raw/2026-06-13-caso-studio-leaf-mobility.pdf]
---

# Casi d'uso LEAF Mobility (UC01–UC18)

I 18 casi d'uso del sistema [[leaf-mobility]], definiti nello [[caso-studio-leaf-mobility|Sprint Report N. 2]] (§2.2). Ogni UC ha scenario base + alternativi e un diagramma di sequenza; sono tracciabili 1-a-1 con le user story (UT/OP/AP) delle [[direttive-leaf-mobility]].

## Per attore

### Utente (UT)
| UC | Titolo | Note chiave |
|---|---|---|
| UC01 | Gestione Account e KYC | registrazione → account "non verificato" → upload documento → verifica provider KYC esterno → "verificato" |
| UC02 | Gestione profilo, pagamenti e abbonamenti | anagrafica, metodi di pagamento, abbonamenti |
| UC03 | Ricerca mezzi, mappa e percorsi | mappa, filtri per tipo, fermate TPL integrate |
| UC04 | Stime tempi, costi e percorsi | preventivo costo, opzioni multimodali |
| UC05 | Inizio/Pausa/Fine corsa e fatturazione | ciclo di vita noleggio + addebito |
| UC06 | Richiesta assistenza e segnalazione SOS | chat supporto + tasto SOS con coordinate |
| UC07 | Gestione Noleggi e annullamenti | prenotazioni multiple, annullo |

### Operatore (OP)
| UC | Titolo |
|---|---|
| UC08 | Estrazione eventi, LOG e report |
| UC09 | Monitoraggio mappa, flotta e telemetria |
| UC10 | Gestione manutenzione e ticket |
| UC11 | Configurazione regole e incentivi |
| UC12 | Controllo remoto e allarmi |
| UC13 | Gestione utenti, AP e assistenza |

### Pubblica Amministrazione (AP)
| UC | Titolo |
|---|---|
| UC14 | Accesso e gestione account AP |
| UC15 | Consultazione heatmap e dashboard |
| UC16 | Estrazione report (AP) |
| UC17 | Definizione aree limitate |
| UC18 | Gestione variabilità (cantieri, eventi, ecc.) |

## Diagramma dei casi d'uso

Il diagramma è incluso nel PDF (§2.2.1). I diagrammi UML di supporto (componenti, casi d'uso, classi, sequenze) sono anche in `wiki/raw/assets/`.
L'attore principale interagisce quasi sempre in via primaria, ma gli scenari prevedono attori secondari (ad esempio i gateway di pagamento esterni) che partecipano silenziosamente per autorizzare un addebito (UC05). Le interazioni tra attori (es. OP e UT) passano sempre per l'astrazione del sistema centrale, mantenendo forte disaccoppiamento visibile nei diagrammi UML.

## Pagine collegate

- [[caso-studio-leaf-mobility]] — la fonte (Sprint Report N. 2)
- [[diagramma-di-sequenza]] — i 16 diagrammi di sequenza realizzano gli scenari di questi UC
- [[uml]] — i casi d'uso sono la vista «+1» di Kruchten da cui derivano le altre
- [[leaf-mobility]] · [[direttive-leaf-mobility]] · [[architettura-three-tier]]
