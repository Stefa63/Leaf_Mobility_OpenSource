"""! @file servizi.py
@brief Contenitore dei servizi condivisi del runtime (stato applicativo).
"""

from __future__ import annotations

from server.runtime.audit_log import AuditLog
from server.runtime.gestore_backup import GestoreBackup
from server.runtime.impostazioni import Impostazioni
from server.runtime.monitor_risorse import MonitorRisorse
from server.runtime.provisioning_op import ProvisioningOP
from server.runtime.registro_metriche import RegistroMetriche


def _as_int(valore: object) -> int:
    """! @brief Converte un valore di configurazione (object) in int.
    @param valore Valore grezzo (proveniente da un payload JSON).
    @return Intero convertito (0 se non convertibile).
    """
    if isinstance(valore, bool):
        return int(valore)
    if isinstance(valore, (int, float, str)):
        try:
            return int(valore)
        except ValueError:
            return 0
    return 0


def _as_float(valore: object) -> float:
    """! @brief Converte un valore di configurazione (object) in float.
    @param valore Valore grezzo (proveniente da un payload JSON).
    @return Float convertito (0.0 se non convertibile).
    """
    if isinstance(valore, bool):
        return float(valore)
    if isinstance(valore, (int, float, str)):
        try:
            return float(valore)
        except ValueError:
            return 0.0
    return 0.0


class ServiziRuntime:
    """! @brief Aggrega i servizi condivisi tra le richieste concorrenti.

    Istanziato una sola volta per processo server e riferito da app.state, e'
    l'unico stato condiviso dalle console connesse: i suoi componenti sono
    thread-safe, cosi' piu' interfacce possono operare in concorrenza.

    @param impostazioni Configurazione del runtime.
    """

    def __init__(self, impostazioni: Impostazioni) -> None:
        """! @brief Costruisce e collega i servizi condivisi.
        @param impostazioni Configurazione del runtime.
        """
        self.impostazioni = impostazioni
        self.metriche = RegistroMetriche()
        self.monitor = MonitorRisorse()
        self.audit = AuditLog(impostazioni.file_audit)
        self.provisioning = ProvisioningOP(impostazioni.file_store_op, self.metriche)
        self.backup = GestoreBackup(
            impostazioni.dati_dir, impostazioni.backup_dir, impostazioni.backup_retention
        )
        #! Impostazioni personalizzabili a caldo (sovrascrivono i default immutabili,
        #! restano coerenti col file config.json persistito da Impostazioni.salva_config).
        self.backup_auto_attivo = impostazioni.backup_auto
        self.backup_intervallo_s = impostazioni.backup_intervallo_s
        self.soglia_cpu = impostazioni.soglia_cpu
        self.soglia_ram = impostazioni.soglia_ram

    @property
    def backup_retention(self) -> int:
        """! @brief Retention corrente del backup (numero di archivi conservati).
        @return Numero massimo di archivi conservati.
        """
        return self.backup.retention

    def aggiorna_config(self, modifiche: dict[str, object]) -> dict[str, object]:
        """! @brief Applica a caldo le impostazioni personalizzate e le persiste.

        Aggiorna lo stato runtime (soglie, backup auto/intervallo/retention) e
        scrive config.json cosi' che la scelta sopravviva al riavvio del runtime.

        @param modifiche Mappa parziale chiave -> nuovo valore (chiavi configurabili).
        @return Configurazione personalizzata completa dopo l'aggiornamento.
        """
        if "backup_auto" in modifiche:
            self.backup_auto_attivo = bool(modifiche["backup_auto"])
        if "backup_intervallo_s" in modifiche:
            self.backup_intervallo_s = max(5, _as_int(modifiche["backup_intervallo_s"]))
        if "backup_retention" in modifiche:
            self.backup.retention = max(1, _as_int(modifiche["backup_retention"]))
        if "soglia_cpu" in modifiche:
            self.soglia_cpu = _as_float(modifiche["soglia_cpu"])
        if "soglia_ram" in modifiche:
            self.soglia_ram = _as_float(modifiche["soglia_ram"])
        return self.impostazioni.salva_config(self.configurazione())

    def configurazione(self) -> dict[str, object]:
        """! @brief Istantanea delle impostazioni personalizzabili correnti.
        @return Mappa chiave -> valore corrente (stato runtime, non i default immutabili).
        """
        return {
            "backup_auto": self.backup_auto_attivo,
            "backup_intervallo_s": self.backup_intervallo_s,
            "backup_retention": self.backup.retention,
            "soglia_cpu": self.soglia_cpu,
            "soglia_ram": self.soglia_ram,
        }
