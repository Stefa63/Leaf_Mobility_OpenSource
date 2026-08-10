# Console Operativa — LEAF Mobility

TUI **a schermo intero** (prompt_toolkit) di gestione del runtime server, fedele al
design handoff `design_handoff_leaf_console` (tema verde su nero, mascotte a foglia,
**help per-comando**). È un **client** dell'endpoint di controllo loopback del runtime:
più istanze possono operare in concorrenza.

Layout: barra telemetria **sempre visibile** in alto (RUNTIME · CPU · RAM · IO · NET ·
**DISPOSITIVI** · THREAD · UPTIME, aggiornata ogni secondo via `psutil` + endpoint runtime),
brand con mascotte a foglia **allungata** e **stato sotto la mascotte**, box dei comandi a
destra, **chat scrollabile** (storico e caricamenti persistenti) a sinistra col prompt
`🍃 leaf >` e cursore in basso. La voce **DISPOSITIVI** mostra in tempo reale i client
collegati; l'UPTIME è quello del runtime e si azzera a ogni `restart`. Scorrimento storico
con `PagSu`/`PagGiù`, `Maiusc+Frecce` o `Inizio`/`Fine`.

All'avvio la console **ripristina le ultime operazioni** da disco (resilienza a chiusure
impreviste). I comandi `set` (impostazioni a caldo, es. intervallo backup) e `cronologia`
(ultime operazioni) sono nuovi; `exit` **arresta il runtime** prima di chiudere
(`exit --keep` per lasciarlo attivo).

```bash
python -m server.console_operativa
```

Elenco comandi, configurazione e dettagli d'uso: vedi [`../README.md`](../README.md).
Progettazione: [`../../Report/architettura_server.md`](../../Report/architettura_server.md).

All'avvio digita `help` per l'elenco dei comandi, oppure `help <comando>` per il dettaglio.
