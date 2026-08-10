"""! @package server.console_operativa
@brief Console operativa da terminale per gestire il runtime server (stile Claude Code).

Interfaccia a riga di comando con tema verde, comandi colorati, help per-comando,
barre di avanzamento e mascotte a foglia. E' un CLIENT dell'endpoint di controllo
loopback del runtime: piu' istanze (terminali diversi) possono operare in
concorrenza sullo stesso server.

Avvio:  python -m server.console_operativa
"""
