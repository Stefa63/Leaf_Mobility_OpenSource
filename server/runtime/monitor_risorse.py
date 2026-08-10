"""! @file monitor_risorse.py
@brief Monitor dello sforzo hardware (CPU, RAM, I/O disco e rete) via psutil.
"""

from __future__ import annotations

import os

import psutil

#! Fattore di conversione byte -> mebibyte.
_MB = 1024 * 1024


class MonitorRisorse:
    """! @brief Campiona l'uso hardware del processo server e del sistema.

    Si appoggia a psutil per CPU, memoria e contatori di I/O. Le misure di CPU
    sono relative all'intervallo trascorso tra due chiamate a @ref istantanea
    (la prima lettura, di innesco, vale 0).

    @param pid PID del processo da monitorare; default = processo corrente.
    """

    def __init__(self, pid: int | None = None) -> None:
        """! @brief Inizializza il monitor e innesca le misure di CPU.
        @param pid PID da monitorare; se None usa il processo corrente.
        """
        self._proc = psutil.Process(pid if pid is not None else os.getpid())
        self._n_cpu = psutil.cpu_count(logical=True) or 1
        # Innesco: la prima misura percentuale di psutil e' sempre 0.
        self._proc.cpu_percent(None)
        psutil.cpu_percent(None)

    def istantanea(self) -> dict[str, object]:
        """! @brief Restituisce una fotografia dello sforzo hardware corrente.
        @return Dizionario con percentuali CPU, memoria (MB e %), I/O disco e rete.
        """
        mem_sistema = psutil.virtual_memory()
        try:
            with self._proc.oneshot():
                cpu_proc = self._proc.cpu_percent(None) / self._n_cpu
                rss = self._proc.memory_info().rss
                thread = self._proc.num_threads()
        except psutil.Error:
            cpu_proc, rss, thread = 0.0, 0, 0

        disco_letti = disco_scritti = 0
        try:
            io = self._proc.io_counters()
            disco_letti, disco_scritti = io.read_bytes, io.write_bytes
        except (psutil.Error, AttributeError):
            pass

        rete_inviati = rete_ricevuti = 0
        try:
            rete = psutil.net_io_counters()
            rete_inviati, rete_ricevuti = rete.bytes_sent, rete.bytes_recv
        except Exception:  # noqa: BLE001 — contatori rete opzionali per piattaforma
            pass

        return {
            "cpu_processo_pct": round(cpu_proc, 1),
            "cpu_sistema_pct": round(psutil.cpu_percent(None), 1),
            "ram_processo_mb": round(rss / _MB, 1),
            "ram_sistema_pct": round(mem_sistema.percent, 1),
            "ram_totale_mb": round(mem_sistema.total / _MB, 1),
            "disco_letti_mb": round(disco_letti / _MB, 1),
            "disco_scritti_mb": round(disco_scritti / _MB, 1),
            "rete_inviati_mb": round(rete_inviati / _MB, 1),
            "rete_ricevuti_mb": round(rete_ricevuti / _MB, 1),
            "thread": thread,
            "pid": self._proc.pid,
        }
