"""! @package server.business_tier.motore_analitica
@brief Analitiche aggregate e anonimizzate per dashboard OP/AP.
"""

from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING, Any

from server.integration_tier.data_access_manager import ottieni_dao_opzionale

if TYPE_CHECKING:
    from server.integration_tier.data_access_manager import DataAccessManager

#! CO2 risparmiata per km percorso in micro-mobilità elettrica vs auto termica (kg/km).
#! Costante documentata (fattore medio urbano): usata per AP.07 (stima CO2 evitata).
CO2_KG_PER_KM = 0.12
#! Campi mai presenti nell'output analitico (anonimato totale, IIN-15 / AG-SEC-04).
_CAMPI_VIETATI: frozenset[str] = frozenset({"id_utente", "_id", "id_mezzo"})


class MotoreAnalitica:
    """! @brief Calcola metriche di mobilita' aggregate e anonime (AP.01/02/05/07, IIN-15).

    Responsabilita': report periodici aggregati per tipo di mezzo, stima CO2 risparmiata.
    Tutti i dati AP sono **aggregati e completamente anonimi** (nessun riferimento al
    singolo cittadino, IIN-15 / AG-SEC-04): l'output non contiene mai id utente/mezzo.
    Opera sui dati del @ref DataAccessManager (Integration Tier, tier adiacente §4).

    @param dao DataAccessManager opzionale; se None risolto dall'ambiente
               (@ref ottieni_dao_opzionale).
    """

    def __init__(self, dao: DataAccessManager | None = None) -> None:
        """! @brief Costruisce il motore, opzionalmente con un DAO iniettato (test).
        @param dao DataAccessManager da usare; se None risolto dall'ambiente.
        """
        self._dao = dao

    def _dao_o_errore(self) -> DataAccessManager:
        """! @brief Restituisce il DAO disponibile o segnala la persistenza in sviluppo.
        @return DataAccessManager pronto.
        @throws NotImplementedError Se la persistenza non e' configurata (slice "in sviluppo", §9).
        """
        dao = self._dao or ottieni_dao_opzionale()
        if dao is None:
            raise NotImplementedError("DataAccessManager/DB in sviluppo")
        return dao

    def aggrega_uso(
        self, dalla_data: str | None = None, alla_data: str | None = None
    ) -> list[dict[str, Any]]:
        """! @brief Aggrega le corse concluse per tipo di mezzo, in forma anonima (AP.02/AP.07).

        Per ogni `tipo_mezzo` calcola numero corse, km totali, durata media e CO2
        risparmiata stimata, senza alcun riferimento al singolo utente o mezzo (IIN-15).
        Il filtro temporale è opzionale e si applica su `data_ora_inizio` (ISO-8601).

        @param dalla_data Inizio intervallo incluso (ISO-8601), o None per nessun limite.
        @param alla_data Fine intervallo incluso (ISO-8601), o None per nessun limite.
        @return Lista di aggregati anonimi, uno per tipo di mezzo.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        accumulo: dict[str, dict[str, float]] = {}
        for corsa in dao.elenca(col.CORSE, filtri=[("stato", "==", "conclusa")]):
            inizio = corsa.get("data_ora_inizio")
            if dalla_data is not None and isinstance(inizio, str) and inizio < dalla_data:
                continue
            if alla_data is not None and isinstance(inizio, str) and inizio > alla_data:
                continue
            tipo = str(corsa.get("tipo_mezzo", "sconosciuto"))
            agg = accumulo.setdefault(tipo, {"num_corse": 0, "km_totali": 0.0, "durata_tot": 0.0})
            agg["num_corse"] += 1
            agg["km_totali"] += float(corsa.get("km_percorsi") or 0.0)
            agg["durata_tot"] += float(corsa.get("durata_min") or 0.0)

        risultato: list[dict[str, Any]] = []
        for tipo, agg in sorted(accumulo.items()):
            num = int(agg["num_corse"])
            risultato.append(
                {
                    "tipo_mezzo": tipo,
                    "num_corse": num,
                    "km_totali": round(agg["km_totali"], 2),
                    "durata_media_min": round(agg["durata_tot"] / num, 1) if num else 0.0,
                    "co2_risparmiata_kg": round(agg["km_totali"] * CO2_KG_PER_KM, 2),
                }
            )
        assert all(_CAMPI_VIETATI.isdisjoint(r) for r in risultato)  # garanzia anonimato IIN-15
        return risultato

    def _corse_concluse_periodo(
        self, dalla_data: str | None, alla_data: str | None
    ) -> list[dict[str, Any]]:
        """! @brief Corse concluse nell'intervallo, base anonima dei report PA (IIN-15).

        Filtra le corse con `stato == "conclusa"` su `data_ora_inizio` (ISO-8601). Helper
        condiviso dai report granulari (noleggi/flussi/CO2) senza toccare @ref aggrega_uso.

        @param dalla_data Inizio intervallo incluso (ISO-8601), o None per nessun limite.
        @param alla_data Fine intervallo incluso (ISO-8601), o None per nessun limite.
        @return Documenti delle corse concluse nell'intervallo.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        corse: list[dict[str, Any]] = []
        for corsa in dao.elenca(col.CORSE, filtri=[("stato", "==", "conclusa")]):
            inizio = corsa.get("data_ora_inizio")
            if dalla_data is not None and isinstance(inizio, str) and inizio < dalla_data:
                continue
            if alla_data is not None and isinstance(inizio, str) and inizio > alla_data:
                continue
            corse.append(corsa)
        return corse

    def report_noleggi_per_tipo(
        self, dalla_data: str | None = None, alla_data: str | None = None
    ) -> dict[str, int]:
        """! @brief Conteggio dei noleggi (corse concluse) per tipologia di mezzo (AP.01).

        Quantifica il volume di utilizzo di ciascuna categoria di mezzo, in forma
        aggregata e anonima (nessun id utente/mezzo, IIN-15).

        @param dalla_data Inizio intervallo (ISO-8601) opzionale.
        @param alla_data Fine intervallo (ISO-8601) opzionale.
        @return Mappa `tipo_mezzo -> numero di corse concluse`.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        conteggio: dict[str, int] = {}
        for corsa in self._corse_concluse_periodo(dalla_data, alla_data):
            tipo = str(corsa.get("tipo_mezzo", "sconosciuto"))
            conteggio[tipo] = conteggio.get(tipo, 0) + 1
        return dict(sorted(conteggio.items()))

    def flussi_per_ora(
        self, dalla_data: str | None = None, alla_data: str | None = None
    ) -> dict[int, int]:
        """! @brief Distribuzione dei noleggi per fascia oraria 0-23 (AP.02).

        Individua le ore più attive per la pianificazione della viabilità, in forma
        aggregata e anonima (IIN-15). L'ora è ricavata da `data_ora_inizio` (ISO-8601).

        @param dalla_data Inizio intervallo (ISO-8601) opzionale.
        @param alla_data Fine intervallo (ISO-8601) opzionale.
        @return Mappa `ora (0-23) -> numero di corse avviate`.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        flussi: dict[int, int] = dict.fromkeys(range(24), 0)
        for corsa in self._corse_concluse_periodo(dalla_data, alla_data):
            inizio = corsa.get("data_ora_inizio")
            if not isinstance(inizio, str):
                continue
            try:
                flussi[datetime.fromisoformat(inizio).hour] += 1
            except ValueError:
                continue
        return flussi

    def percentuale_operativi(self) -> dict[str, float]:
        """! @brief Percentuale di mezzi operativi vs manutenzione vs scarico (AP.03).

        Verifica il rispetto delle soglie minime di servizio. Legge lo `stato_operativo`
        dei mezzi (valore della @ref StatoMezzo): operativi = disponibile/in uso/prenotato.

        @return Mappa con percentuali `operativi`, `manutenzione`, `scarico`.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        mezzi = dao.elenca(col.MEZZI)
        totale = len(mezzi) or 1
        operativi = manutenzione = scarico = 0
        for m in mezzi:
            stato = str(m.get("stato_operativo") or m.get("stato") or "")
            if stato in ("disponibile", "in_uso", "prenotato"):
                operativi += 1
            elif stato in ("manutenzione", "guasto"):
                manutenzione += 1
            elif stato == "scarico":
                scarico += 1
        return {
            "operativi": round(operativi / totale * 100, 1),
            "manutenzione": round(manutenzione / totale * 100, 1),
            "scarico": round(scarico / totale * 100, 1),
        }

    def co2_risparmiata(
        self, dalla_data: str | None = None, alla_data: str | None = None
    ) -> dict[str, Any]:
        """! @brief Stima la CO2 risparmiata dai km della flotta elettrica (AP.07).

        Quantifica l'impatto ecologico positivo confrontando i km percorsi a zero
        emissioni con un'auto termica equivalente (@ref CO2_KG_PER_KM). Aggregato e
        anonimo (IIN-15), con dettaglio per tipologia di mezzo.

        @param dalla_data Inizio intervallo (ISO-8601) opzionale.
        @param alla_data Fine intervallo (ISO-8601) opzionale.
        @return `{km_totali, co2_risparmiata_kg, km_per_tipo}`.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        km_per_tipo: dict[str, float] = {}
        for corsa in self._corse_concluse_periodo(dalla_data, alla_data):
            tipo = str(corsa.get("tipo_mezzo", "sconosciuto"))
            km_per_tipo[tipo] = km_per_tipo.get(tipo, 0.0) + float(corsa.get("km_percorsi") or 0.0)
        km_totali = sum(km_per_tipo.values())
        return {
            "km_totali": round(km_totali, 2),
            "co2_risparmiata_kg": round(km_totali * CO2_KG_PER_KM, 2),
            "km_per_tipo": {tipo: round(km, 2) for tipo, km in sorted(km_per_tipo.items())},
        }
