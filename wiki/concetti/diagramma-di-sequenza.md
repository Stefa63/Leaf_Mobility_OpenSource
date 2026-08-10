---
tipo: concetto
creato: 2026-06-19
aggiornato: 2026-06-19
tag: [uml, sequenza, casi-uso, interazione, corso]
fonti: [raw/08.4_ITPS_UML_Sequenza_2026.pptx.pdf]
---

# Diagramma di Sequenza

Vista **comportamentale**: rappresentazione grafica di uno **scenario** di un caso d'uso come sequenza temporale di messaggi tra oggetti. Fonte: [[itps-uml-sequenza]]. Insieme al class diagram, è l'artefatto più scrutinato all'esame ITPS.

## Realizza i casi d'uso

Mostra come le istanze delle **classi di analisi** interagiscono per realizzare un [[casi-uso-leaf|caso d'uso]]. Il classificatore di contesto è il caso d'uso; le **linee di vita** (lifeline) sono le istanze che si scambiano messaggi.

- **Linea di vita:** nome (opz.) + tipo (classificatore) + selettore (opz.).
- **Messaggi:** chiamata di operazione (stessa segnatura del metodo), creazione/distruzione di istanza, segnale, **auto-delega** (a sé stessi), valore restituito. Chi esegue ha il **focus di attivazione**.
- **Scenari:** lo scenario *base* è un singolo diagramma; gli *alternativi* in un diagramma a sé o annidati in quello base.
- **Invarianti di stato:** un messaggio può cambiare lo stato dell'istanza (mostrabile sulla lifeline).

## Frammenti combinati

Aree con **operatore + operandi + guardie**:

| Operatore | Significato |
|---|---|
| `opt` | esegue l'operando se la guardia è vera (if…then) |
| `alt` | sceglie l'operando con guardia vera (select/case, con `else`) |
| `loop min,max [cond]` | esegue `min` volte, poi finché `cond` è vera fino a `max` |
| `break` | se la guardia è vera esegue l'operando e interrompe il loop |

Tipi di ciclo mappati su `loop`: `while`, `for n,m`, `repeat`, `forEach`.

## Mappatura su LEAF Mobility

- Il team ha **16 diagrammi di sequenza** in `raw/assets/Diagrammi di Sequenza/`, uno per scenario degli [[casi-uso-leaf|UC01–UC18]].
- **Catena di coerenza da difendere all'orale:** caso d'uso → diagramma di sequenza → classi. Ogni lifeline deve essere istanza di una classe presente nel [[diagramma-delle-classi|class diagram]], e ogni messaggio deve corrispondere a un'operazione di quella classe. È il controllo di consistenza inter-diagramma che i professori verificano.
- Flussi con scelte/cicli (es. login con OTP, pausa/fine corsa, prenotazione con scadenza) vanno modellati con `alt`/`opt`/`loop`.
- **Esempio di interazione (Sblocco Veicolo - UC10)**:
  - Il client (AppMobileUtente) invia un comando di sblocco ad `api_gateway_sicurezza`.
  - Il gateway autentica la chiamata e inoltra al `GestoreCorse`.
  - Il `GestoreCorse` verifica il saldo utente e la disponibilità del `Mezzo`, quindi comunica con il `GatewayIoT` (frammento `alt` se il mezzo risponde o meno).
  - Il `GatewayIoT` (black-box) invia il comando effettivo al veicolo fisico. In caso di successo, si crea una nuova istanza di `Corsa` e si aggiorna il database tramite `DataAccessManager`.

## Pagine collegate

- [[diagramma-delle-classi]] — fornisce le classi/operazioni usate come lifeline e messaggi
- [[casi-uso-leaf]] — gli scenari realizzati
- [[uml]] · [[itps-uml-sequenza]] · [[leaf-mobility]]
