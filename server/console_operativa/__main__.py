"""! @file __main__.py
@brief Punto di ingresso della console operativa: python -m server.console_operativa
"""

from __future__ import annotations

import contextlib
import sys

from server.console_operativa.console import ConsoleOperativa


def main() -> None:
    """! @brief Avvia la console operativa interattiva.
    @return Nessuno.
    """
    # Forza l'output UTF-8: tema verde, mascotte a foglia ed emoji richiedono
    # caratteri non presenti nel codepage legacy (cp1252) di alcune console Windows.
    for flusso in (sys.stdout, sys.stderr):
        with contextlib.suppress(AttributeError, ValueError):
            flusso.reconfigure(encoding="utf-8")  # type: ignore[union-attr]
    ConsoleOperativa().esegui()


if __name__ == "__main__":
    main()
