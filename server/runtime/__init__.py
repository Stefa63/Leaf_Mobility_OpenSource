"""! @package server.runtime
@brief Ossatura operativa del server: bootstrap FastAPI, strumentazione e servizi.

NON e' un quarto tier: e' tooling di runtime trasversale che ospita l'app dei tre
tier e l'endpoint di controllo loopback usato dalla @ref server.console_operativa.

Componenti:
  - @ref server.runtime.impostazioni        — configurazione (env/.env).
  - @ref server.runtime.registro_metriche   — contatori thread-safe (byte, richieste, tempi).
  - @ref server.runtime.metriche_middleware — middleware ASGI di strumentazione.
  - @ref server.runtime.monitor_risorse     — monitor hardware (psutil).
  - @ref server.runtime.audit_log           — log append-only delle azioni (IIN-13).
  - @ref server.runtime.provisioning_op     — creazione OP con credenziali temporanee.
  - @ref server.runtime.gestore_backup      — backup manuale e automatico.
  - @ref server.runtime.controllo_router    — endpoint di controllo (loopback).
  - @ref server.runtime.app_factory         — costruzione dell'app FastAPI.
"""
