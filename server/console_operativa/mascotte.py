"""! @file mascotte.py
@brief Mascotte a foglia, schermata di benvenuto e barre di avanzamento.
"""

from __future__ import annotations

import time

from rich import box
from rich.console import Console, Group, RenderableType
from rich.panel import Panel
from rich.progress import BarColumn, Progress, SpinnerColumn, TaskProgressColumn, TextColumn
from rich.table import Table
from rich.text import Text

#! Griglia pixel della mascotte per la TUI a schermo intero (design handoff):
#! foglia allungata con punta in alto, nervatura centrale, due occhi e picciolo
#! lungo. 0=vuoto, 1=corpo, 2=luce, 3=nervatura, 4=picciolo, 5=occhio.
MASCOTTE_GRID = [
    [0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 1, 3, 1, 0, 0, 0, 0],
    [0, 0, 0, 1, 1, 3, 1, 1, 0, 0, 0],
    [0, 0, 1, 1, 1, 3, 1, 1, 1, 0, 0],
    [0, 1, 1, 1, 1, 3, 1, 1, 1, 1, 0],
    [0, 1, 1, 5, 1, 3, 1, 5, 1, 1, 0],
    [1, 1, 1, 5, 1, 3, 1, 5, 1, 1, 1],
    [1, 1, 1, 1, 1, 3, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 3, 1, 1, 1, 1, 1],
    [0, 1, 1, 1, 1, 3, 1, 1, 1, 1, 0],
    [0, 1, 1, 1, 1, 3, 1, 1, 1, 1, 0],
    [0, 0, 1, 1, 1, 3, 1, 1, 1, 0, 0],
    [0, 0, 0, 1, 1, 3, 1, 1, 0, 0, 0],
    [0, 0, 0, 0, 1, 3, 1, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0],
]
#! Numero di righe della mascotte (usato dalla TUI per dimensionare la finestra).
ALTEZZA_MASCOTTE = len(MASCOTTE_GRID)
#! Classe di stile prompt_toolkit per ciascun codice della griglia.
_CLASSI_FOGLIA = {1: "leaf", 2: "leaf.h", 3: "leaf.v", 4: "leaf.s", 5: "leaf.e"}
#! Due caratteri blocco per cella: i "pixel" risultano quasi quadrati.
_BLOCCO = "██"


def foglia_formattata() -> list[tuple[str, str]]:
    """! @brief Rende la mascotte come testo formattato prompt_toolkit.

    Ogni cella della @ref MASCOTTE_GRID diventa due caratteri blocco colorati
    secondo il proprio codice; le celle vuote sono spazi. Usata dalla TUI come
    logo del brand (la foglia accanto al prompt resta invece l'emoji 🍃).

    @return Lista di frammenti (classe_stile, testo) con ritorni a capo.
    """
    frammenti: list[tuple[str, str]] = []
    for riga in MASCOTTE_GRID:
        for cella in riga:
            if cella == 0:
                frammenti.append(("", "  "))
            else:
                frammenti.append((f"class:{_CLASSI_FOGLIA[cella]}", _BLOCCO))
        frammenti.append(("", "\n"))
    return frammenti[:-1]


#! Mascotte a foglia in pixel-art (richiama il logo LEAF Mobility): due meta'
#! piene separate da una nervatura centrale, punta in alto e picciolo in basso.
FOGLIA = "\n".join(
    [
        "       ▟▙",
        "      ▟▌▐▙",
        "     ▟█▌▐█▙",
        "    ▟██▌▐██▙",
        "   ▟███▌▐███▙",
        "   ▜███▌▐███▛",
        "    ▜██▌▐██▛",
        "     ▜█▌▐█▛",
        "      ▜▌▐▛",
        "       ▐▌",
        "       ▐▌",
    ]
)


def _blocco_sinistro(base_url: str, stato: str, versione: str) -> RenderableType:
    """! @brief Costruisce il blocco sinistro del benvenuto (titolo, mascotte, meta).
    @param base_url URL loopback del runtime.
    @param stato Stato corrente del runtime (es. "attivo").
    @param versione Versione del server.
    @return Renderable rich allineato al centro.
    """
    g = Table.grid(padding=0)
    g.add_column(justify="center")
    g.add_row(Text(f"LEAF Mobility · Console Operativa v{versione}", style="leaf"))
    g.add_row(Text(""))
    g.add_row(Text("Bentornato!", style="leaf"))
    g.add_row(Text(FOGLIA, style="verde"))
    g.add_row(Text(""))
    g.add_row(Text("server · runtime locale", style="dim"))
    g.add_row(Text(base_url, style="dim"))
    g.add_row(Text(f"stato: {stato}", style="val"))
    return g


def _pannello_comandi() -> RenderableType:
    """! @brief Pannello "Comandi principali" (analogo a "Recent activity").
    @return Pannello rich con i comandi piu' usati.
    """
    t = Table.grid(padding=(0, 1))
    t.add_column(style="cmd", no_wrap=True)
    t.add_column(style="val")
    t.add_row("start / stop", "avvia o arresta il runtime")
    t.add_row("monitor", "carico in tempo reale")
    t.add_row("hw", "sforzo hardware (CPU/RAM/IO)")
    t.add_row("op create <u>", "nuovo OP con password temporanea")
    t.add_row("backup", "backup manuale / automatico")
    return Panel(t, title="[head]Comandi principali", border_style="verde", box=box.ROUNDED)


def _pannello_novita() -> RenderableType:
    """! @brief Pannello "Suggerimenti" (analogo a "What's new").
    @return Pannello rich con suggerimenti d'uso.
    """
    t = Table.grid(padding=(0, 1))
    t.add_column(style="cmd", no_wrap=True)
    t.add_column(style="val")
    t.add_row("help <comando>", "aiuto sul singolo comando")
    t.add_row("selftest", "genera carico sintetico di prova")
    t.add_row("query <sql>", "interrogazione admin (DB in sviluppo)")
    t.add_row("più terminali", "comandi diversi in concorrenza")
    return Panel(t, title="[head]Suggerimenti", border_style="verde", box=box.ROUNDED)


def mostra_benvenuto(console: Console, *, base_url: str, stato: str, versione: str) -> None:
    """! @brief Stampa la schermata di benvenuto in stile Claude Code (tema verde).
    @param console Console rich su cui scrivere.
    @param base_url URL loopback del runtime.
    @param stato Stato corrente del runtime.
    @param versione Versione del server.
    @return Nessuno.
    """
    griglia = Table.grid(padding=(0, 3))
    griglia.add_column(justify="center")
    griglia.add_column()
    griglia.add_row(
        _blocco_sinistro(base_url, stato, versione),
        Group(_pannello_comandi(), _pannello_novita()),
    )
    console.print(Panel(griglia, border_style="verde", box=box.DOUBLE, padding=(1, 2)))
    console.print("Digita [cmd]help[/] per l'elenco completo dei comandi.\n")


def barra_avvio(console: Console, descrizione: str, passi: list[str]) -> None:
    """! @brief Mostra una barra di avanzamento percentuale per una sequenza di passi.
    @param console Console rich su cui rendere la barra.
    @param descrizione Etichetta generale dell'operazione.
    @param passi Elenco di sotto-passi; ogni completamento avanza la percentuale.
    @return Nessuno.
    """
    with Progress(
        SpinnerColumn(style="verde"),
        TextColumn("[leaf]{task.description}"),
        BarColumn(complete_style="verde", finished_style="verde"),
        TaskProgressColumn(),
        console=console,
        transient=True,
    ) as progress:
        task = progress.add_task(descrizione, total=len(passi))
        for passo in passi:
            progress.update(task, description=passo)
            time.sleep(0.12)
            progress.advance(task)
