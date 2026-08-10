"""! @package server.business_tier.gestore_flotta
@brief Stato e logistica della flotta veicoli.
"""

from __future__ import annotations

import json
from datetime import UTC, datetime
from typing import TYPE_CHECKING, Any

from server.integration_tier.data_access_manager import ottieni_dao_opzionale
from server.integration_tier.gateway_iot import GatewayIot

if TYPE_CHECKING:
    from server.integration_tier.data_access_manager import DataAccessManager

#! Soglia di batteria (%) sotto la quale un mezzo è considerato scarico nei report (OP.13).
BATTERIA_SCARICA_PCT = 20
#! Tipi di evento telemetrico ammessi (valore della @ref TipoTelemetria, OP.07/OP.14).
TIPI_TELEMETRIA: frozenset[str] = frozenset(
    {"sblocco", "blocco", "urto", "anomalia", "gps", "batteria"}
)


class GestoreFlotta:
    """! @brief Gestisce stato, distribuzione e soglie della flotta (OP.01/02/03/20/22).

    Responsabilita': stato in tempo reale di ogni mezzo (disponibile, in uso, in
    manutenzione, scarico), soglie minime per area con alert, liste mezzi guasti,
    report giornalieri per stato operativo, ricerca dei mezzi disponibili per gli
    utenti (UT.01/UT.05). La persistenza e' delegata al @ref DataAccessManager
    (Integration Tier, tier adiacente §4); la telemetria proviene dal GatewayIoT.

    @param dao DataAccessManager opzionale; se None risolto dall'ambiente
               (@ref ottieni_dao_opzionale).
    """

    def __init__(self, dao: DataAccessManager | None = None) -> None:
        """! @brief Costruisce il gestore, opzionalmente con un DAO iniettato (test).
        @param dao DataAccessManager da usare; se None risolto dall'ambiente.
        """
        self._dao = dao
        self._iot = GatewayIot()

    def conteggio_per_stato(self) -> dict[str, int]:
        """! @brief Conta i mezzi raggruppati per stato operativo (OP.13/20).
        @return Mappa stato -> numero di mezzi.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao or ottieni_dao_opzionale()
        if dao is None:
            raise NotImplementedError("DataAccessManager/DB in sviluppo")
        conteggi: dict[str, int] = {}
        from server.integration_tier.data_access_manager import collezioni as col

        for mezzo in dao.elenca(col.MEZZI):
            stato = str(mezzo.get("stato_operativo", "sconosciuto"))
            conteggi[stato] = conteggi.get(stato, 0) + 1
        return conteggi

    def elenco(self, stato: str | None = None, limite: int | None = None) -> list[dict[str, Any]]:
        """! @brief Elenca i mezzi della flotta per la dashboard OP (AP.03/OP.03/OP.20).

        Vista operativa completa dello stato dei mezzi (disponibile, in uso, in
        manutenzione, scarico). A differenza di @ref mezzi_disponibili (vista utente
        ristretta ai disponibili nei pressi), questa è la vista gestionale dell'operatore.

        @param stato Filtro opzionale su `stato_operativo` (es. "guasto" per OP.03).
        @param limite Numero massimo di mezzi restituiti (None = tutti).
        @return Lista di mezzi (con stato operativo) per la dashboard.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao or ottieni_dao_opzionale()
        if dao is None:
            raise NotImplementedError("DataAccessManager/DB in sviluppo")
        from server.integration_tier.data_access_manager import collezioni as col

        filtri = [("stato_operativo", "==", stato)] if stato else None
        return dao.elenca(col.MEZZI, filtri=filtri, limite=limite)

    def mezzi_disponibili(
        self,
        lat: float | None = None,
        lon: float | None = None,
        raggio_m: float = 2000.0,
        tipo: str | None = None,
    ) -> list[dict[str, Any]]:
        """! @brief Elenca i mezzi disponibili nei pressi di una posizione (UT.01/UT.05).
        @param lat Latitudine del centro di ricerca (opzionale).
        @param lon Longitudine del centro di ricerca (opzionale).
        @param raggio_m Raggio di ricerca in metri (default 2000).
        @param tipo Filtro opzionale per tipo di mezzo.
        @return Lista di mezzi disponibili (ordinati per distanza se lat/lon presenti).
        @throws NotImplementedError Se la persistenza non e' configurata (slice "in sviluppo", §9).
        """
        dao = self._dao or ottieni_dao_opzionale()
        if dao is None:
            raise NotImplementedError("DataAccessManager/DB in sviluppo")
        return dao.mezzi_disponibili(lat, lon, raggio_m, tipo)

    def _dao_o_errore(self) -> DataAccessManager:
        """! @brief Restituisce il DAO disponibile o segnala la persistenza in sviluppo.
        @return DataAccessManager pronto.
        @throws NotImplementedError Se la persistenza non e' configurata (slice "in sviluppo", §9).
        """
        dao = self._dao or ottieni_dao_opzionale()
        if dao is None:
            raise NotImplementedError("DataAccessManager/DB in sviluppo")
        return dao

    def mezzi_guasti(self) -> list[dict[str, Any]]:
        """! @brief Elenca i mezzi in stato "Guasto" da ritirare per manutenzione (OP.03).
        @return Lista dei mezzi con `stato_operativo == "guasto"`.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        return self.elenco(stato="guasto")

    def stazioni_ricarica(self) -> list[dict[str, Any]]:
        """! @brief Elenca le stazioni di ricarica attive sulla mappa (UT.14).
        @return Lista delle stazioni con `stato == "attiva"` (posizione + colonnine).
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        return dao.elenca(col.STAZIONI_RICARICA, filtri=[("stato", "==", "attiva")])

    # ── Soglie di allerta (OP.02/OP.22) ───────────────────────────────────────
    def imposta_soglia_area(self, id_area: str, minimo: int, id_operatore: str) -> str:
        """! @brief Imposta la soglia minima di mezzi per un'area (OP.02).

        Registra una soglia che, al di sotto del numero minimo di mezzi presenti
        nell'area, genera un'allerta (@ref verifica_soglie) per programmare il
        ricollocamento della flotta.

        @param id_area Id dell'area di geofencing monitorata.
        @param minimo Numero minimo di mezzi richiesto nell'area.
        @param id_operatore Id dell'operatore che configura la soglia (FK → account).
        @return Id della soglia creata.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        return dao.crea(
            col.SOGLIE,
            {
                "tipo": "mezzi_area",
                "id_area": id_area,
                "valore": int(minimo),
                "creata_da": id_operatore,
            },
        )

    def imposta_soglia_batteria(
        self, percentuale: int, id_operatore: str, tipo_mezzo: str | None = None
    ) -> str:
        """! @brief Imposta la soglia di allerta batteria (OP.22).
        @param percentuale Percentuale di batteria sotto la quale scatta l'allerta.
        @param id_operatore Id dell'operatore che configura la soglia (FK → account).
        @param tipo_mezzo Limita la soglia a una tipologia di mezzo (opzionale).
        @return Id della soglia creata.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        documento: dict[str, Any] = {
            "tipo": "batteria",
            "valore": int(percentuale),
            "creata_da": id_operatore,
        }
        if tipo_mezzo:
            documento["tipo_mezzo"] = tipo_mezzo
        return dao.crea(col.SOGLIE, documento)

    def verifica_soglie(self) -> list[dict[str, Any]]:
        """! @brief Valuta le soglie configurate e produce le allerte attive (OP.02/OP.22).

        Per le soglie `mezzi_area` conta i mezzi nel poligono dell'area (delega geo al
        @ref DataAccessManager) e segnala se sotto il minimo; per le soglie `batteria`
        segnala i mezzi sotto la percentuale, eventualmente filtrati per tipologia.

        @return Elenco di allerte (area sotto soglia o mezzi con batteria insufficiente).
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        allerte: list[dict[str, Any]] = []
        mezzi = dao.elenca(col.MEZZI)
        for soglia in dao.elenca(col.SOGLIE):
            valore = int(soglia.get("valore") or 0)
            if soglia.get("tipo") == "mezzi_area" and soglia.get("id_area"):
                area = dao.leggi(col.AREE_LIMITATE, str(soglia["id_area"]))
                if area is None:
                    continue
                presenti = dao.conta_mezzi_in_area(area)
                if presenti < valore:
                    allerte.append(
                        {
                            "tipo": "mezzi_area",
                            "area": area.get("nome") or soglia["id_area"],
                            "presenti": presenti,
                            "minimo": valore,
                        }
                    )
            elif soglia.get("tipo") == "batteria":
                tipo_filtro = soglia.get("tipo_mezzo")
                for mezzo in mezzi:
                    if tipo_filtro and mezzo.get("tipo_mezzo") != tipo_filtro:
                        continue
                    batteria = int(mezzo.get("livello_batteria_pct") or 0)
                    if batteria < valore:
                        allerte.append(
                            {
                                "tipo": "batteria",
                                "mezzo": mezzo.get("codice_identificativo") or mezzo.get("_id"),
                                "batteria": batteria,
                                "soglia": valore,
                            }
                        )
        return allerte

    def report_giornaliero(self) -> dict[str, Any]:
        """! @brief Report giornaliero del conteggio mezzi per stato e batteria scarica (OP.13).

        Fornisce alla squadra di recupero il quadro della giornata: conteggi per stato
        operativo, numero di mezzi a batteria scarica (< @ref BATTERIA_SCARICA_PCT) e totale.

        @return `{per_stato, batteria_scarica, totale}`.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        mezzi = dao.elenca(col.MEZZI)
        scarica = sum(
            1 for m in mezzi if int(m.get("livello_batteria_pct") or 0) < BATTERIA_SCARICA_PCT
        )
        return {
            "per_stato": self.conteggio_per_stato(),
            "batteria_scarica": scarica,
            "totale": len(mezzi),
        }

    # ── Telemetria e comandi remoti (OP.07/OP.11/OP.14) ───────────────────────
    def _mezzo_o_errore(self, codice_mezzo: str) -> dict[str, Any]:
        """! @brief Recupera un mezzo per codice o segnala l'inesistenza.
        @param codice_mezzo Codice identificativo del mezzo (id documento).
        @return Documento del mezzo.
        @throws ValueError Se il mezzo non esiste.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        from server.integration_tier.data_access_manager import collezioni as col

        mezzo = self._dao_o_errore().leggi(col.MEZZI, codice_mezzo)
        if mezzo is None:
            raise ValueError(f"Mezzo '{codice_mezzo}' inesistente")
        return mezzo

    def registra_evento_telemetria(
        self,
        codice_mezzo: str,
        tipo: str,
        *,
        lat: float | None = None,
        lon: float | None = None,
        velocita: float | None = None,
        batteria: int | None = None,
        dettagli: str | None = None,
    ) -> str:
        """! @brief Registra un evento telemetrico nel log del mezzo (OP.07/OP.14).

        Scrive nella subcollezione `eventi_telemetria` del mezzo (sblocco, urto,
        anomalia, GPS, …). La posizione è serializzata JSON e cifrata at-rest dal
        @ref DataAccessManager (campo 🔒 `posizione`, IIN-4).

        @param codice_mezzo Codice del mezzo (id documento padre).
        @param tipo Tipo di evento (@ref TIPI_TELEMETRIA).
        @param lat Latitudine rilevata (opzionale).
        @param lon Longitudine rilevata (opzionale).
        @param velocita Velocità rilevata (opzionale).
        @param batteria Livello batteria rilevato (opzionale).
        @param dettagli Note aggiuntive (opzionale).
        @return Id dell'evento telemetrico creato.
        @throws ValueError Se il tipo non è ammesso o il mezzo non esiste.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        if tipo not in TIPI_TELEMETRIA:
            raise ValueError(f"Tipo telemetria non valido: {tipo}")
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        self._mezzo_o_errore(codice_mezzo)
        documento: dict[str, Any] = {
            "tipo": tipo,
            "timestamp": datetime.now(UTC).isoformat(),
        }
        if lat is not None and lon is not None:
            documento["posizione"] = json.dumps({"lat": lat, "lon": lon}, separators=(",", ":"))
        if velocita is not None:
            documento["velocita"] = velocita
        if batteria is not None:
            documento["batteria"] = batteria
        if dettagli:
            documento["dettagli"] = dettagli
        return dao.crea_in_sub(col.MEZZI, codice_mezzo, col.SUB_EVENTI_TELEMETRIA, documento)

    def log_telemetrico(self, codice_mezzo: str) -> list[dict[str, Any]]:
        """! @brief Registro degli eventi telemetrici di un mezzo (OP.14).
        @param codice_mezzo Codice del mezzo.
        @return Elenco degli eventi telemetrici del mezzo (posizione decifrata).
        @throws ValueError Se il mezzo non esiste.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        self._mezzo_o_errore(codice_mezzo)
        return dao.elenca_sub(col.MEZZI, codice_mezzo, col.SUB_EVENTI_TELEMETRIA)

    def blocca_motore_remoto(self, codice_mezzo: str) -> bool:
        """! @brief Invia il blocco motore remoto a un mezzo e ne traccia l'evento (OP.11).

        Immobilizza un mezzo privo di noleggi attivi (anti-spostamento in area non
        autorizzata) via @ref GatewayIot e registra un evento telemetrico "blocco"
        (OP.14) per la tracciabilità dell'azione.

        @param codice_mezzo Codice del mezzo da immobilizzare.
        @return True se il comando è stato accettato dal gateway IoT.
        @throws ValueError Se il mezzo non esiste.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        self._mezzo_o_errore(codice_mezzo)
        esito = self._iot.invia_comando_blocco_motore(codice_mezzo)
        if esito:
            self.registra_evento_telemetria(
                codice_mezzo, "blocco", dettagli="Blocco motore remoto (OP.11)"
            )
        return esito

    def sblocca_motore_remoto(self, codice_mezzo: str) -> bool:
        """! @brief Revoca il blocco motore remoto di un mezzo e ne traccia l'evento (OP.11).

        Operazione inversa di @ref blocca_motore_remoto: riabilita la movimentazione
        di un mezzo precedentemente immobilizzato via @ref GatewayIot e registra un
        evento telemetrico "sblocco" (OP.14) per la tracciabilità dell'azione.

        @param codice_mezzo Codice del mezzo da riabilitare.
        @return True se il comando è stato accettato dal gateway IoT.
        @throws ValueError Se il mezzo non esiste.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        self._mezzo_o_errore(codice_mezzo)
        esito = self._iot.invia_comando_sblocco_motore(codice_mezzo)
        if esito:
            self.registra_evento_telemetria(
                codice_mezzo, "sblocco", dettagli="Sblocco motore remoto (OP.11)"
            )
        return esito
