"""! @file __main__.py
@brief Avvio manuale diretto del runtime: `python -m server.runtime`.

Entrypoint **foreground** del runtime operativo, alternativo alla console
(`python -m server.console_operativa` → `start`, che lo lancia come processo
indipendente). Utile per avviarlo a mano in un terminale dedicato vedendone i
log strutturati in tempo reale (ctrl-C per arrestarlo). Host/porta/worker sono
quelli di @ref Impostazioni (env/.env: `LEAF_HOST`, `LEAF_PORT`, `LEAF_WORKERS`).
"""

from __future__ import annotations

import uvicorn

from server.runtime.impostazioni import Impostazioni

#! Target d'import dell'app del runtime (uguale a quello usato dalla console).
_TARGET = "server.runtime.app_factory:app"


def main() -> None:
    """! @brief Carica le impostazioni e avvia uvicorn in foreground.
    @return Nessuno (blocca finché il server non viene arrestato).
    """
    imp = Impostazioni.carica()
    print(f"LEAF Mobility — runtime su {imp.base_url}  (ctrl-C per arrestare)")
    uvicorn.run(
        _TARGET,
        host=imp.host,
        port=imp.porta,
        workers=imp.workers if imp.workers > 1 else None,
        log_level=imp.log_level.lower(),
    )


if __name__ == "__main__":
    main()
