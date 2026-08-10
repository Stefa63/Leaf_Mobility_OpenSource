"""! @file tema.py
@brief Tema cromatico della console (palette del design handoff) per Rich e prompt_toolkit.
"""

from __future__ import annotations

from prompt_toolkit.styles import Style
from rich.console import Console
from rich.theme import Theme

#! ---- Token cromatici del design handoff (design_handoff_leaf_console) ----
BG = "#000000"  #! sfondo schermo
PANEL = "#050806"  #! sfondo pannello interno
BORDER = "#1c4a2c"  #! bordo verde principale / celle vuote dei gauge
BORDER_SOFT = "#133a20"  #! bordo interno / separatori tenui
VERDE = "#34e06a"  #! verde brillante primario (comandi, gauge, brand)
VERDE_CHIARO = "#6cf39a"  #! verde chiaro: intestazioni e valori in evidenza
VERDE_PROFONDO = "#16a34a"  #! verde profondo: nervatura, argomenti, freccia su
VERDE_TENUE = "#2a7a45"  #! verde tenue: picciolo / verde sottile
TESTO = "#9fb6a6"  #! testo corpo
TESTO_DEBOLE = "#5d7568"  #! etichette, testo attenuato
GIALLO = "#e0b341"  #! avvisi
ROSSO = "#e06a6a"  #! errori
OCCHIO = "#061009"  #! occhio della mascotte (quasi nero)

#! Tema rich: verde "foglia" come colore base, coerente col design handoff.
#! Riusato per catturare in ANSI l'output dei comandi e mostrarlo nella chat.
TEMA = Theme(
    {
        "leaf": f"bold {VERDE}",
        "ok": f"bold {VERDE}",
        "warn": f"{GIALLO}",
        "err": f"bold {ROSSO}",
        "info": f"{VERDE_PROFONDO}",
        "dim": f"{TESTO_DEBOLE}",
        "cmd": f"bold {VERDE}",
        "val": f"{TESTO}",
        "head": f"bold {VERDE_CHIARO}",
        "verde": VERDE,
    }
)


def crea_console() -> Console:
    """! @brief Crea una console rich con il tema LEAF applicato.
    @return Istanza Console pronta all'uso.
    """
    return Console(theme=TEMA, highlight=False)


def stile_tui() -> Style:
    """! @brief Costruisce lo stile prompt_toolkit della TUI a schermo intero.

    Mappa le classi di stile usate dalla vista (barra telemetria, mascotte,
    wordmark, server card, box comandi, chat) ai token cromatici del design.

    @return Stile prompt_toolkit pronto per l'@ref Application.
    """
    return Style.from_dict(
        {
            # contenitori
            "base": f"bg:{PANEL} {TESTO}",
            "frame.border": BORDER,
            "frame.label": f"bold {VERDE_CHIARO}",
            "sep": BORDER_SOFT,
            # barra telemetria
            "monitor": f"bg:{PANEL}",
            "lbl": TESTO_DEBOLE,
            "val": VERDE_CHIARO,
            "val.dim": TESTO,
            "gauge.f": VERDE,
            "gauge.e": BORDER,
            "arrow.d": VERDE,
            "arrow.u": VERDE_PROFONDO,
            "spark": VERDE,
            "devices": f"bold {VERDE_CHIARO}",
            "pulse.on": VERDE,
            "pulse.off": TESTO_DEBOLE,
            "run.on": f"bold {VERDE_CHIARO}",
            "run.off": TESTO_DEBOLE,
            # mascotte (griglia pixel)
            "leaf": VERDE,
            "leaf.h": VERDE_CHIARO,
            "leaf.v": VERDE_PROFONDO,
            "leaf.s": VERDE_TENUE,
            "leaf.e": OCCHIO,
            # brand
            "wordmark.leaf": f"bold {VERDE}",
            "wordmark.mob": TESTO,
            "sub": TESTO_DEBOLE,
            "sub.v": VERDE_PROFONDO,
            # colonna sinistra
            "hi": f"bold {VERDE_CHIARO}",
            "card.k": TESTO_DEBOLE,
            "card.v": TESTO,
            "card.link": VERDE,
            # box comandi
            "cmd": f"bold {VERDE}",
            "arg": VERDE_PROFONDO,
            "desc": TESTO,
            # chat / log
            "log": TESTO,
            "log.ok": VERDE,
            "log.warn": GIALLO,
            "log.err": ROSSO,
            "log.head": f"bold {VERDE_CHIARO}",
            "log.muted": TESTO_DEBOLE,
            "log.b": f"bold {VERDE}",
            "hint": TESTO,
            "hint.b": f"bold {VERDE}",
            # prompt
            "prompt.leaf": VERDE,
            "prompt.name": f"bold {VERDE}",
            "prompt.gt": TESTO_DEBOLE,
        }
    )


def colore_soglia(valore: float, soglia: float) -> str:
    """! @brief Sceglie lo stile in base al superamento di una soglia.
    @param valore Valore corrente (es. % CPU).
    @param soglia Soglia di allerta.
    @return Nome dello stile: "ok" sotto 75% della soglia, "warn" sotto soglia, "err" oltre.
    """
    if valore >= soglia:
        return "err"
    if valore >= 0.75 * soglia:
        return "warn"
    return "ok"
