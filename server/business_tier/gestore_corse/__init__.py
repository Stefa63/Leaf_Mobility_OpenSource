"""! @package server.business_tier.gestore_corse
@brief Ciclo di vita delle corse: prenotazione, sblocco, pausa, termine, costi.
"""

from __future__ import annotations

from datetime import UTC, datetime
from typing import TYPE_CHECKING, Any

from server.business_tier.gestore_geofencing import GestoreGeofencing
from server.integration_tier.data_access_manager import ErrorePersistenza, ottieni_dao_opzionale
from server.integration_tier.gateway_email import GatewayEmail
from server.integration_tier.gateway_iot import GatewayIot
from server.integration_tier.gateway_pagamenti import GatewayPagamenti
from server.integration_tier.gateway_routing import GatewayRouting

if TYPE_CHECKING:
    from server.integration_tier.data_access_manager import DataAccessManager

#! Tariffa locale deterministica per tipo di mezzo: (sblocco_cent, al_minuto_cent).
#! Simulazione documentata (nessun gateway tariffario esterno cablato, §3): valori
#! fissi e riproducibili, sufficienti a UT.03 (stima) e UT.04 (importo finale).
TARIFFE_CENT: dict[str, tuple[int, int]] = {
    "ebike": (50, 15),
    "monopattino": (50, 20),
    "ecar": (100, 35),
    "emotorbike": (80, 28),
}
#! Durata stimata di default (minuti) per la stima preventiva quando non indicata.
DURATA_STIMATA_DEFAULT_MIN = 15
#! Tipi di mezzo a motore che richiedono la patente caricata prima di
#! prenotare/avviare una corsa (UT.22.2): auto e moto elettriche (punto 6).
TIPI_RICHIEDE_PATENTE: frozenset[str] = frozenset({"ecar", "emotorbike"})
#! Aliquota IVA ordinaria applicata alle fatture (22%).
ALIQUOTA_IVA = 0.22
#! Tipi di promozione ammessi (schema promozioni.tipo, §10): sconto percentuale, credito
#! bonus per rilascio in parcheggio incentivato (OP.09), sconto geografico (OP.15), tariffa evento.
TIPI_PROMOZIONE_AMMESSI: frozenset[str] = frozenset(
    {"sconto_percentuale", "credito_bonus_parcheggio", "sconto_geografico", "tariffa_evento"}
)


class GestoreCorse:
    """! @brief Gestisce prenotazioni e corse (UT.02, UT.03, UT.04, UT.10, UT.12).

    Responsabilita': disponibilita' esclusiva del mezzo (blocco in transazione),
    stima preventiva del costo (tariffa locale deterministica), avvio/pausa/termine
    corsa e calcolo dell'importo finale. La persistenza e i vincoli sono delegati al
    @ref DataAccessManager (Integration Tier, tier adiacente §4).

    @param dao DataAccessManager opzionale; se None risolto dall'ambiente
               (@ref ottieni_dao_opzionale).
    """

    def __init__(
        self,
        dao: DataAccessManager | None = None,
        iot: GatewayIot | None = None,
        pagamenti: GatewayPagamenti | None = None,
        routing: GatewayRouting | None = None,
        email: GatewayEmail | None = None,
        geofencing: GestoreGeofencing | None = None,
    ) -> None:
        """! @brief Costruisce il gestore con DAO e gateway esterni (simulazioni locali).
        @param dao DataAccessManager da usare; se None risolto dall'ambiente.
        @param iot Gateway IoT (comandi sblocco/blocco); default simulazione locale.
        @param pagamenti Gateway pagamenti (addebito); default simulazione locale.
        @param routing Gateway routing (percorsi/ETA); default simulazione locale.
        @param email Gateway email per le notifiche transazionali; default @ref GatewayEmail
                     (disattivato finché non configurato via ambiente).
        @param geofencing Gestore geofencing per il perimetro operativo di fine-noleggio
                     (OP.04, composizione intra-tier); default su stesso DAO.
        """
        self._dao = dao
        self._iot = iot or GatewayIot()
        self._pagamenti = pagamenti or GatewayPagamenti()
        self._routing = routing or GatewayRouting()
        self._email = email or GatewayEmail()
        self._geofencing = geofencing or GestoreGeofencing(dao)

    def _notifica_utente(
        self, dao: DataAccessManager, id_utente: str, oggetto: str, corpo: str
    ) -> None:
        """! @brief Email transazionale best-effort all'utente di una corsa/prenotazione.

        Risolve l'email registrata dell'utente dal @ref DataAccessManager e invia il
        messaggio. È un effetto accessorio (come per i ticket di assistenza): se il gateway
        è disattivato (app password assente) o l'invio fallisce, non altera l'esito
        dell'operazione di dominio (nessuna eccezione propagata).

        @param dao DataAccessManager connesso (per risolvere l'email dell'utente).
        @param id_utente Id dell'utente destinatario (FK → account).
        @param oggetto Oggetto del messaggio.
        @param corpo Corpo testuale del messaggio.
        @return Nessuno.
        """
        if not self._email.configurato:
            return
        from server.integration_tier.data_access_manager import collezioni as col

        account = dao.leggi(col.ACCOUNT, id_utente)
        email_utente = str(account.get("email", "")) if account else ""
        if email_utente:
            self._email.invia(email_utente, oggetto, corpo)

    def _dao_o_errore(self) -> DataAccessManager:
        """! @brief Restituisce il DAO disponibile o segnala la persistenza in sviluppo.
        @return DataAccessManager pronto.
        @throws NotImplementedError Se la persistenza non e' configurata (slice "in sviluppo", §9).
        """
        dao = self._dao or ottieni_dao_opzionale()
        if dao is None:
            raise NotImplementedError("DataAccessManager/DB in sviluppo")
        return dao

    @staticmethod
    def costo_cent(tipo_mezzo: str, durata_min: int) -> int:
        """! @brief Calcola il costo di una corsa in centesimi (tariffa locale, UT.03/UT.04).
        @param tipo_mezzo Tipo del mezzo (ebike/monopattino/ecar/emotorbike).
        @param durata_min Durata in minuti (>= 0).
        @return Costo in centesimi: sblocco + al_minuto * durata.
        """
        sblocco, al_minuto = TARIFFE_CENT.get(tipo_mezzo, (50, 20))
        return sblocco + al_minuto * max(0, durata_min)

    @staticmethod
    def dettaglio_costo(tipo_mezzo: str, durata_min: int) -> dict[str, int]:
        """! @brief Scompone il costo in sblocco + corsa + totale (UT.03/UT.04, punto 8).

        Restituisce le tre voci separate richieste dalla UI per gli utenti **senza
        abbonamento** (sblocco + corsa mostrati distintamente, poi la somma). Per gli
        abbonati a pagamento lo sblocco è gratuito e la corsa è coperta dai token: il
        chiamante (@ref stima_dettaglio / @ref termina) azzera le voci di conseguenza.

        @param tipo_mezzo Tipo del mezzo (ebike/monopattino/ecar/emotorbike).
        @param durata_min Durata in minuti (>= 0).
        @return {sblocco_cent, corsa_cent, totale_cent}.
        """
        sblocco, al_minuto = TARIFFE_CENT.get(tipo_mezzo, (50, 20))
        corsa = al_minuto * max(0, durata_min)
        return {"sblocco_cent": sblocco, "corsa_cent": corsa, "totale_cent": sblocco + corsa}

    @staticmethod
    def _ha_patente_caricata(dao: DataAccessManager, id_utente: str) -> bool:
        """! @brief Indica se l'utente ha caricato almeno un documento patente (UT.22.2, punto 6).

        Verifica l'esistenza di un documento `patente` in `documenti_ufficiali` (qualsiasi
        stato di verifica): è il prerequisito per noleggiare auto/moto elettriche. Tollerante
        ai problemi di persistenza (in caso di errore ritorna False, lato sicuro: senza prova
        della patente il noleggio del mezzo a motore è inibito).

        @param dao DataAccessManager connesso.
        @param id_utente Id dell'utente.
        @return True se esiste un documento patente caricato dall'utente.
        """
        from server.integration_tier.data_access_manager import collezioni as col

        try:
            documenti = dao.elenca(
                col.DOCUMENTI_UFFICIALI,
                filtri=[("id_utente", "==", id_utente), ("tipo_documento", "==", "patente")],
            )
            return len(documenti) > 0
        except (ErrorePersistenza, ValueError, TypeError, KeyError):
            return False

    def _verifica_patente_se_richiesta(
        self, dao: DataAccessManager, id_utente: str, tipo_mezzo: str
    ) -> None:
        """! @brief Inibisce prenotazione/avvio di auto e moto elettriche senza patente (punto 6).
        @param dao DataAccessManager connesso.
        @param id_utente Id dell'utente.
        @param tipo_mezzo Tipo del mezzo richiesto.
        @return Nessuno.
        @throws ValueError Se il mezzo richiede la patente e l'utente non l'ha caricata.
        """
        if tipo_mezzo in TIPI_RICHIEDE_PATENTE and not self._ha_patente_caricata(dao, id_utente):
            raise ValueError(
                "Per noleggiare auto o moto elettriche devi prima caricare la patente "
                "nei documenti del profilo (UT.22.2)."
            )

    def stima_costo(self, id_mezzo: str, durata_min: int = DURATA_STIMATA_DEFAULT_MIN) -> int:
        """! @brief Stima preventiva del costo di una corsa su un mezzo (UT.03).
        @param id_mezzo Identificativo del mezzo selezionato.
        @param durata_min Durata stimata in minuti (default 15).
        @return Costo stimato in centesimi.
        @throws NotImplementedError Se la persistenza non e' configurata.
        @throws ValueError Se il mezzo non esiste.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        mezzo = dao.leggi(col.MEZZI, id_mezzo)
        if mezzo is None:
            raise ValueError(f"Mezzo '{id_mezzo}' inesistente")
        return self.costo_cent(str(mezzo.get("tipo_mezzo")), durata_min)

    def stima_dettaglio(
        self, id_mezzo: str, id_utente: str, durata_min: int = DURATA_STIMATA_DEFAULT_MIN
    ) -> dict[str, Any]:
        """! @brief Stima con voci separate e stato abbonamento (UT.03, punto 8).

        Per gli utenti **senza abbonamento** restituisce sblocco + corsa + totale distinti
        (mostrati separatamente in app). Per gli **abbonati a pagamento** lo sblocco è
        gratuito e la corsa è coperta dai token: il totale è azzerato e si riportano token
        inclusi/residui e la percentuale già utilizzata (la UI mostra % + token).

        @param id_mezzo Identificativo del mezzo selezionato.
        @param id_utente Id dell'utente (per risolvere l'abbonamento attivo).
        @param durata_min Durata stimata in minuti (default 15).
        @return {sblocco_cent, corsa_cent, totale_cent, costo_stimato_cent, ha_abbonamento,
                 [token_inclusi, token_residui, percentuale_usata]}.
        @throws NotImplementedError Se la persistenza non e' configurata.
        @throws ValueError Se il mezzo non esiste.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        mezzo = dao.leggi(col.MEZZI, id_mezzo)
        if mezzo is None:
            raise ValueError(f"Mezzo '{id_mezzo}' inesistente")
        dettaglio = self.dettaglio_costo(str(mezzo.get("tipo_mezzo")), durata_min)
        abbonamento = self._abbonamento_con_token(dao, id_utente)
        if abbonamento is not None:
            inclusi = int(abbonamento.get("token_inclusi") or 0)
            residui = int(abbonamento.get("token_residui") or 0)
            usati = max(0, inclusi - residui)
            dettaglio.update(
                {
                    "ha_abbonamento": True,
                    "sblocco_cent": 0,  # sblocco gratis per gli abbonati a pagamento
                    "totale_cent": 0,  # corsa coperta dai token dell'abbonamento
                    "token_inclusi": inclusi,
                    "token_residui": residui,
                    "percentuale_usata": round(usati / inclusi * 100) if inclusi else 0,
                }
            )
        else:
            dettaglio["ha_abbonamento"] = False
        dettaglio["costo_stimato_cent"] = dettaglio["totale_cent"]  # compat UT.03
        return dettaglio

    def corsa_attiva(self, id_utente: str) -> dict[str, Any] | None:
        """! @brief Corsa in corso o in pausa dell'utente, o None (UT.10/UT.12, punto 2).

        Permette al client di **recuperare** la corsa in svolgimento dopo un riavvio
        dell'app (lo stato locale è volatile): si interroga lo storico dell'utente e si
        seleziona la prima corsa con stato `in_corso` o `in_pausa`. Riusa l'indice
        composito id_utente+data_ora_inizio già definito per lo storico (UT.17).

        @param id_utente Id dell'utente.
        @return Documento corsa attiva (con id_mezzo, tipo_mezzo, stato…), o None.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        corse = dao.elenca(
            col.CORSE,
            filtri=[("id_utente", "==", id_utente)],
            ordina=("data_ora_inizio", "DESCENDING"),
            limite=20,
        )
        for corsa in corse:
            if corsa.get("stato") in ("in_corso", "in_pausa"):
                return corsa
        return None

    def prenota(self, id_utente: str, id_mezzo: str, scadenza: str | None = None) -> str:
        """! @brief Prenota un mezzo con blocco esclusivo (UT.02).
        @param id_utente Id dell'utente.
        @param id_mezzo Id del mezzo.
        @param scadenza Scadenza ISO 8601 della prenotazione (opzionale, UT.15).
        @return Id della prenotazione creata.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        mezzo = dao.leggi(col.MEZZI, id_mezzo)
        self._verifica_patente_se_richiesta(
            dao, id_utente, str(mezzo.get("tipo_mezzo")) if mezzo else ""
        )
        id_prenotazione = dao.prenota_mezzo(id_utente, id_mezzo, scadenza)
        self._notifica_utente(
            dao,
            id_utente,
            "LEAF Mobility - Prenotazione confermata",
            f"Ciao,\n\nhai prenotato il mezzo {id_mezzo}.\n"
            f"Codice prenotazione: {id_prenotazione}.\n"
            + (f"Valida fino a: {scadenza}.\n" if scadenza else "")
            + "\nIl team LEAF Mobility\n",
        )
        return id_prenotazione

    def prenotazioni(self, id_utente: str, limite: int = 50) -> list[dict[str, Any]]:
        """! @brief Prenotazioni attive di un utente, dalla più recente (UT.02/UT.21).
        @param id_utente Id dell'utente.
        @param limite Numero massimo di prenotazioni restituite (default 50).
        @return Lista delle prenotazioni con stato "attiva".
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        return self._dao_o_errore().elenca_prenotazioni_attive(id_utente, limite)

    def annulla_prenotazione(self, id_prenotazione: str, id_utente: str) -> dict[str, Any]:
        """! @brief Annulla una prenotazione attiva dell'utente e libera il mezzo (UT.12).
        @param id_prenotazione Id della prenotazione da annullare.
        @param id_utente Id dell'utente richiedente (controllo di proprietà).
        @return Esito {id_prenotazione, id_mezzo, annullata}.
        @throws NotImplementedError Se la persistenza non e' configurata.
        @throws ErroreIntegrita Se la prenotazione non esiste o non appartiene all'utente.
        @throws MezzoNonDisponibile Se la prenotazione non è più attiva.
        """
        dao = self._dao_o_errore()
        esito = dao.annulla_prenotazione(id_prenotazione, id_utente)
        self._notifica_utente(
            dao,
            id_utente,
            "LEAF Mobility - Prenotazione annullata",
            f"Ciao,\n\nla tua prenotazione {id_prenotazione} "
            f"(mezzo {esito.get('id_mezzo')}) è stata annullata e il mezzo è di nuovo "
            "disponibile.\n\nIl team LEAF Mobility\n",
        )
        return esito

    def prenotazioni_attive_tutte(self, limite: int = 100) -> list[dict[str, Any]]:
        """! @brief Tutte le prenotazioni attive per la console operatore (OP.12).

        Vista gestionale (≠ @ref prenotazioni, per-utente): elenca le prenotazioni con
        stato "attiva" sull'intera flotta, dalla più recente, arricchite con l'etichetta
        leggibile dell'utente (username/nominativo) per identificare chi trattiene il mezzo.

        @param limite Numero massimo di prenotazioni restituite (default 100).
        @return Lista delle prenotazioni attive con etichetta utente.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        attive = [p for p in dao.elenca(col.PRENOTAZIONI) if p.get("stato") == "attiva"]
        for p in attive:
            p.update(self._etichetta_utente(dao, str(p.get("id_utente") or "")))
        attive.sort(key=lambda p: str(p.get("data_ora_inizio") or ""), reverse=True)
        return attive[:limite]

    def annulla_prenotazione_op(self, id_prenotazione: str) -> dict[str, Any]:
        """! @brief Forza l'annullamento di una prenotazione attiva da parte dell'operatore (OP.12).

        A differenza di @ref annulla_prenotazione (UT, con controllo di proprietà), salta la
        verifica del titolare — è un'azione autorizzata dell'operatore per rimettere a
        disposizione un mezzo trattenuto in modo anomalo — e libera il mezzo. Notifica
        comunque l'utente titolare dell'annullamento operatore.

        @param id_prenotazione Id della prenotazione da annullare.
        @return Esito {id_prenotazione, id_mezzo, annullata}.
        @throws NotImplementedError Se la persistenza non e' configurata.
        @throws ErroreIntegrita Se la prenotazione non esiste.
        @throws MezzoNonDisponibile Se la prenotazione non è più attiva.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        prenotazione = dao.leggi(col.PRENOTAZIONI, id_prenotazione) or {}
        esito = dao.annulla_prenotazione(id_prenotazione, None)  # None = operatore (OP.12)
        id_utente = str(prenotazione.get("id_utente") or "")
        if id_utente:
            self._notifica_utente(
                dao,
                id_utente,
                "LEAF Mobility - Prenotazione annullata dall'operatore",
                f"Ciao,\n\nla tua prenotazione {id_prenotazione} "
                f"(mezzo {esito.get('id_mezzo')}) è stata annullata dall'operatore e il mezzo "
                "è di nuovo disponibile per la community.\n\nIl team LEAF Mobility\n",
            )
        return esito

    @staticmethod
    def _etichetta_utente(dao: DataAccessManager, id_utente: str) -> dict[str, str]:
        """! @brief Etichetta leggibile dell'utente di una prenotazione (username + nominativo).
        @param dao DataAccessManager connesso.
        @param id_utente Id dell'account titolare.
        @return {username, nominativo} (vuoti/ripiego se l'account non e' risolvibile).
        """
        from server.integration_tier.data_access_manager import collezioni as col

        if not id_utente:
            return {"username": "", "nominativo": ""}
        account = dao.leggi(col.ACCOUNT, id_utente) or {}
        profilo = (dao.leggi_profilo(account) if account else None) or {}
        nominativo = " ".join(str(profilo[c]) for c in ("nome", "cognome") if profilo.get(c))
        username = str(account.get("username") or "")
        return {
            "username": username,
            "nominativo": nominativo or username or str(account.get("email") or id_utente),
        }

    def avvia(
        self,
        id_utente: str,
        id_mezzo: str,
        id_prenotazione: str | None = None,
        durata_stimata_min: int = DURATA_STIMATA_DEFAULT_MIN,
    ) -> dict[str, Any]:
        """! @brief Sblocca il mezzo e avvia la corsa (UT.10).
        @param id_utente Id dell'utente.
        @param id_mezzo Id del mezzo da sbloccare.
        @param id_prenotazione Id della prenotazione da convertire (opzionale).
        @param durata_stimata_min Durata stimata per la stima preventiva del costo.
        @return Esito {id_corsa, costo_stimato_cent, sbloccato}.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        mezzo = dao.leggi(col.MEZZI, id_mezzo)
        tipo = str(mezzo.get("tipo_mezzo")) if mezzo else ""
        self._verifica_patente_se_richiesta(dao, id_utente, tipo)  # punto 6
        stima = self.costo_cent(tipo, durata_stimata_min)
        id_corsa = dao.avvia_corsa(id_utente, id_mezzo, id_prenotazione, costo_stimato_cent=stima)
        sbloccato = self._iot.invia_comando_sblocco(id_mezzo)  # comando IoT (sim. locale)
        self._notifica_utente(
            dao,
            id_utente,
            "LEAF Mobility - Noleggio iniziato",
            f"Ciao,\n\nil tuo noleggio è iniziato.\nMezzo: {id_mezzo}\n"
            f"Codice corsa: {id_corsa}\nCosto stimato: {stima / 100:.2f} €\n\n"
            "Il team LEAF Mobility\n",
        )
        return {"id_corsa": id_corsa, "costo_stimato_cent": stima, "sbloccato": sbloccato}

    def percorsi(
        self, origine: tuple[float, float], destinazione: tuple[float, float]
    ) -> list[dict[str, Any]]:
        """! @brief Opzioni di percorso multimodali sharing+TPL (UT.07), via gateway routing.
        @param origine Coordinate (lat, lon) di partenza.
        @param destinazione Coordinate (lat, lon) di arrivo.
        @return Percorsi ordinati per tempo (simulazione locale deterministica).
        """
        return self._routing.percorsi_multimodali(origine, destinazione)

    def suggerisci_luoghi(self, query: str, limite: int = 8) -> list[dict[str, Any]]:
        """! @brief Suggerimenti di luogo per l'autocompletamento della ricerca (UT.07).
        @param query Testo parziale digitato dall'utente.
        @param limite Numero massimo di suggerimenti restituiti (default 8).
        @return Elenco di {nome, lat, lon} dal gazetteer del @ref GatewayRouting.
        """
        return self._routing.suggerisci(query, limite=limite)

    @staticmethod
    def _arricchisci_percorso(percorso: dict[str, Any]) -> dict[str, Any]:
        """! @brief Arricchisce un'opzione di percorso grezza con nome/descrizione/mezzo (UT.08).
        @param percorso Opzione grezza del routing ({modalita, distanza_m, durata_min}).
        @return Opzione con nome/descrizione/ha_tpl/tipo_consigliato/distanza_km aggiunti.
        """
        modalita = str(percorso.get("modalita"))
        km = float(percorso.get("distanza_m", 0.0)) / 1000.0
        if modalita == "tpl":
            arricchimento = {
                "nome": "Con TPL integrato",
                "descrizione": "Mezzo in sharing + trasporto pubblico locale",
                "ha_tpl": True,
                "tipo_consigliato": "ebike",
            }
        else:
            tipo = "monopattino" if km <= 1.5 else "ebike" if km <= 4.0 else "ecar"
            arricchimento = {
                "nome": "Percorso diretto",
                "descrizione": "Percorso più diretto con un mezzo in sharing",
                "ha_tpl": False,
                "tipo_consigliato": tipo,
            }
        return {**percorso, **arricchimento, "distanza_km": round(km, 2)}

    def pianifica_percorsi(
        self,
        da: str | None = None,
        a: str | None = None,
        origine: tuple[float, float] | None = None,
        destinazione: tuple[float, float] | None = None,
    ) -> dict[str, Any]:
        """! @brief Pianifica i percorsi tra due luoghi, per nome o coordinate (UT.07/UT.08).

        Le coordinate esplicite (es. posizione corrente) prevalgono; altrimenti il nome
        è geocodificato sul gazetteer locale. Calcola le opzioni multimodali via gateway
        routing e le arricchisce con nome/descrizione/mezzo consigliato.

        @param da Nome del luogo di partenza (geocodificato se @p origine è assente).
        @param a Nome del luogo di arrivo (geocodificato se @p destinazione è assente).
        @param origine Coordinate (lat, lon) di partenza che prevalgono sul nome.
        @param destinazione Coordinate (lat, lon) di arrivo che prevalgono sul nome.
        @return {origine, destinazione, percorsi, totale} con opzioni ordinate per tempo.
        @throws ValueError Se un luogo indicato per nome non è nel gazetteer.
        """
        org = origine or (self._routing.geocodifica(da) if da else None)
        dst = destinazione or (self._routing.geocodifica(a) if a else None)
        if org is None:
            raise ValueError(f"Luogo di partenza non riconosciuto: {da!r}")
        if dst is None:
            raise ValueError(f"Luogo di arrivo non riconosciuto: {a!r}")
        grezzi = self._routing.percorsi_multimodali(org, dst)
        percorsi = [self._arricchisci_percorso(p) for p in grezzi]
        return {
            "origine": {"lat": org[0], "lon": org[1]},
            "destinazione": {"lat": dst[0], "lon": dst[1]},
            "percorsi": percorsi,
            "totale": len(percorsi),
        }

    def storico(self, id_utente: str, limite: int = 50) -> list[dict[str, Any]]:
        """! @brief Storico delle corse di un utente, dalla più recente (UT.17).
        @param id_utente Id dell'utente.
        @param limite Numero massimo di corse restituite (default 50).
        @return Lista di corse dell'utente ordinate per inizio decrescente.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        return dao.elenca(
            col.CORSE,
            filtri=[("id_utente", "==", id_utente)],
            ordina=("data_ora_inizio", "DESCENDING"),
            limite=limite,
        )

    def fatture(self, id_utente: str, limite: int = 50) -> list[dict[str, Any]]:
        """! @brief Elenco delle fatture di un utente, per copia digitale (UT.25).

        Le Fatture non referenziano l'utente direttamente (FK → pagamenti, §6.9): si
        risolvono i pagamenti dell'utente e si selezionano le fatture collegate.

        @param id_utente Id dell'utente.
        @param limite Numero massimo di fatture restituite (default 50).
        @return Lista di fatture dell'utente.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        pagamenti = dao.elenca(col.PAGAMENTI, filtri=[("id_utente", "==", id_utente)])
        id_pagamenti = {str(p.get("_id")) for p in pagamenti}
        if not id_pagamenti:
            return []
        fatture = [f for f in dao.elenca(col.FATTURE) if str(f.get("id_pagamento")) in id_pagamenti]
        return fatture[:limite]

    def pausa(self, id_corsa: str) -> dict[str, Any]:
        """! @brief Mette in pausa una corsa in corso (UT.12).
        @param id_corsa Id della corsa.
        @return Esito {id_corsa, stato}.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        self._dao_o_errore().aggiorna_stato_corsa(id_corsa, "in_pausa")
        return {"id_corsa": id_corsa, "stato": "in_pausa"}

    def riprendi(self, id_corsa: str) -> dict[str, Any]:
        """! @brief Riprende una corsa precedentemente messa in pausa (UT.12).
        @param id_corsa Id della corsa.
        @return Esito {id_corsa, stato}.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        self._dao_o_errore().aggiorna_stato_corsa(id_corsa, "in_corso")
        return {"id_corsa": id_corsa, "stato": "in_corso"}

    def valuta(self, id_corsa: str, stelle: int) -> dict[str, Any]:
        """! @brief Registra la valutazione a stelle di una corsa conclusa (UT.16).

        Salva sul documento corsa il feedback dell'utente (1-5 stelle) sulla qualità
        del noleggio appena concluso.

        @param id_corsa Id della corsa da valutare.
        @param stelle Valutazione da 1 a 5.
        @return Esito {id_corsa, valutazione}.
        @throws ValueError Se le stelle sono fuori dall'intervallo 1-5 o la corsa non esiste.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        if not 1 <= stelle <= 5:
            raise ValueError("La valutazione deve essere compresa tra 1 e 5 stelle")
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        if dao.leggi(col.CORSE, id_corsa) is None:
            raise ValueError(f"Corsa '{id_corsa}' inesistente")
        dao.aggiorna(col.CORSE, id_corsa, {"valutazione": stelle})
        return {"id_corsa": id_corsa, "valutazione": stelle}

    @staticmethod
    def _abbonamento_con_token(dao: DataAccessManager, id_utente: str) -> dict[str, Any] | None:
        """! @brief Abbonamento attivo (non scaduto) con token residui da scalare, o None (punto 7).

        Tollerante a errori/assenza dati: in caso di problemi ritorna None, cosi' il termine
        corsa ripiega sempre sull'addebito monetario standard (UT.04) senza mai fallire.

        @param dao DataAccessManager connesso.
        @param id_utente Id dell'utente della corsa.
        @return L'abbonamento da scalare, oppure None se non applicabile.
        """
        from server.integration_tier.data_access_manager import collezioni as col

        try:
            ora = datetime.now(UTC)
            attivi = dao.elenca(
                col.ABBONAMENTI,
                filtri=[("id_utente", "==", id_utente), ("stato", "==", "attivo")],
            )
            for abb in attivi:
                if int(abb.get("token_residui", 0)) < 1:
                    continue
                fine = abb.get("data_fine")
                if not fine:
                    return abb
                try:
                    if datetime.fromisoformat(str(fine)) > ora:
                        return abb
                except ValueError:
                    return abb
        except (ErrorePersistenza, ValueError, TypeError, KeyError):
            return None
        return None

    def termina(
        self,
        id_corsa: str,
        km_percorsi: float = 0.0,
        *,
        lat: float | None = None,
        lon: float | None = None,
    ) -> dict[str, Any]:
        """! @brief Conclude la corsa, blocca il mezzo, addebita e fattura (UT.04/UT.25).

        Sequenza: conclude la corsa (durata + mezzo liberato), calcola l'importo finale
        (tariffa locale), blocca il mezzo (gateway IoT), addebita l'utente (gateway
        pagamenti, sim. locale), registra il Pagamento (XOR su id_corsa) ed emette la
        Fattura con scorporo IVA. Il PDF della fattura va su Cloud Storage (stub
        `storage_path_pdf`, §4 schema): qui non generato.

        OP.05/OP.04: se sono fornite le coordinate di chiusura le registra (cifrate
        at-rest, IIN-4) e valuta il perimetro operativo in **modalità soft** — segnala
        `fuori_area_operativa` senza inibire il rilascio (enforcement hard separato).

        @param id_corsa Id della corsa.
        @param km_percorsi Chilometri percorsi (IIN-24).
        @param lat Latitudine GPS di chiusura (opzionale, OP.05).
        @param lon Longitudine GPS di chiusura (opzionale, OP.05).
        @return Esito {id_corsa, durata_min, costo_finale_cent, id_pagamento, id_fattura,
            fuori_area_operativa}.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        # Prima conclusione per ottenere la durata effettiva, poi calcolo del costo finale.
        conclusa = dao.termina_corsa(id_corsa, km_percorsi=km_percorsi)
        tipo = str(conclusa.get("tipo_mezzo"))
        durata = int(conclusa.get("durata_min", 0))
        dettaglio = self.dettaglio_costo(tipo, durata)  # sblocco/corsa/totale (punto 8)
        costo = dettaglio["totale_cent"]

        id_mezzo = conclusa.get("id_mezzo")
        if id_mezzo:
            self._iot.invia_comando_blocco(str(id_mezzo))  # blocco motore (sim. locale)

        id_utente = str(conclusa.get("id_utente"))

        # OP.05/OP.04: registra le coordinate GPS di chiusura (cifrate at-rest) e valuta il
        # perimetro operativo in modalità soft (segnala "fuori area" senza bloccare).
        fuori_area = False
        if lat is not None and lon is not None:
            try:
                fuori_area = not self._geofencing.dentro_area_operativa(lat, lon)
            except NotImplementedError:
                fuori_area = False
            dao.aggiorna(
                col.CORSE,
                id_corsa,
                {"posizione_arrivo": {"lat": lat, "lon": lon}, "fuori_area_operativa": fuori_area},
            )

        # Punto 7: con un abbonamento attivo a token, la corsa è coperta dall'abbonamento —
        # si scala 1 token e NON si addebita denaro (nessun importo sul gateway pagamenti).
        abbonamento = self._abbonamento_con_token(dao, id_utente)
        if abbonamento is not None:
            residui = int(abbonamento.get("token_residui", 0)) - 1
            inclusi = int(abbonamento.get("token_inclusi", 0))
            percentuale_usata = round((inclusi - residui) / inclusi * 100) if inclusi else 0
            dao.aggiorna(col.ABBONAMENTI, str(abbonamento["_id"]), {"token_residui": residui})
            # Sblocco gratuito + corsa coperta dai token: costo addebitato 0 ma si
            # registra comunque la scomposizione informativa (sblocco/corsa) sul DB (punto 8).
            dao.aggiorna(
                col.CORSE,
                id_corsa,
                {
                    "costo_finale_cent": 0,
                    "sblocco_cent": 0,
                    "corsa_cent": dettaglio["corsa_cent"],
                    "coperto_da_abbonamento": str(abbonamento["_id"]),
                },
            )
            id_pagamento = dao.registra_pagamento(
                {
                    "tipo": "corsa",
                    "id_utente": id_utente,
                    "id_corsa": id_corsa,
                    "importo_cent": 0,
                    "sblocco_cent": 0,
                    "corsa_cent": dettaglio["corsa_cent"],
                    "valuta": "EUR",
                    "stato": "completato",
                    "coperto_da_abbonamento": str(abbonamento["_id"]),
                }
            )
            id_fattura = self._emetti_fattura(dao, id_pagamento, 0)
            self._notifica_utente(
                dao,
                id_utente,
                "LEAF Mobility - Noleggio terminato",
                f"Ciao,\n\nil tuo noleggio {id_corsa} è terminato.\n"
                f"Durata: {durata} min\nImporto: 0,00 € (coperto da abbonamento; sblocco gratis)\n"
                f"Token residui: {residui} ({percentuale_usata}% utilizzato)\n"
                f"Fattura: {id_fattura}\n\nIl team LEAF Mobility\n",
            )
            return {
                "id_corsa": id_corsa,
                "durata_min": durata,
                "costo_finale_cent": 0,
                "sblocco_cent": 0,
                "corsa_cent": dettaglio["corsa_cent"],
                "coperto_da_abbonamento": True,
                "token_residui": residui,
                "token_inclusi": inclusi,
                "percentuale_usata": percentuale_usata,
                "id_pagamento": id_pagamento,
                "id_fattura": id_fattura,
                "fuori_area_operativa": fuori_area,
            }

        # Senza abbonamento: sblocco + corsa addebitati sul metodo di pagamento (punto 8).
        dao.aggiorna(
            col.CORSE,
            id_corsa,
            {
                "costo_finale_cent": costo,
                "sblocco_cent": dettaglio["sblocco_cent"],
                "corsa_cent": dettaglio["corsa_cent"],
            },
        )
        id_transazione = self._pagamenti.addebita(id_utente, costo, riferimento=id_corsa)
        id_pagamento = dao.registra_pagamento(
            {
                "tipo": "corsa",
                "id_utente": id_utente,
                "id_corsa": id_corsa,
                "importo_cent": costo,
                "sblocco_cent": dettaglio["sblocco_cent"],
                "corsa_cent": dettaglio["corsa_cent"],
                "valuta": "EUR",
                "stato": "completato",
                "id_transazione_esterna": id_transazione,
            }
        )
        id_fattura = self._emetti_fattura(dao, id_pagamento, costo)
        self._notifica_utente(
            dao,
            id_utente,
            "LEAF Mobility - Noleggio terminato",
            f"Ciao,\n\nil tuo noleggio {id_corsa} è terminato.\n"
            f"Durata: {durata} min\nImporto: {costo / 100:.2f} €\nFattura: {id_fattura}\n\n"
            "Il team LEAF Mobility\n",
        )
        return {
            "id_corsa": id_corsa,
            "durata_min": durata,
            "costo_finale_cent": costo,
            "sblocco_cent": dettaglio["sblocco_cent"],
            "corsa_cent": dettaglio["corsa_cent"],
            "coperto_da_abbonamento": False,
            "id_pagamento": id_pagamento,
            "id_fattura": id_fattura,
            "fuori_area_operativa": fuori_area,
        }

    # ── Promozioni e incentivi geografici (OP.09/OP.15) ───────────────────────
    def crea_promozione(self, dati: dict[str, Any], creata_da: str) -> str:
        """! @brief Configura una promozione/incentivo geografico o di parcheggio (OP.09/OP.15).

        OP.09: credito bonus per i rilasci in aree di parcheggio designate. OP.15: sconto
        percentuale per i noleggi avviati entro perimetri configurabili. La promozione può
        legarsi a un'area (`id_area` → aree_limitate) per circoscriverne l'ambito geografico.

        @param dati Campi della promozione (tipo, descrizione, valore, id_area opz., date opz.).
        @param creata_da Id dell'operatore che configura la promozione (FK → operatori, §6.9).
        @return Id della promozione creata.
        @throws ValueError Se il tipo di promozione non e' ammesso.
        @throws NotImplementedError Se la persistenza non e' configurata.
        @throws ErroreIntegrita Se `creata_da`/`id_area` non esistono (integrità referenziale).
        """
        tipo = str(dati.get("tipo"))
        if tipo not in TIPI_PROMOZIONE_AMMESSI:
            raise ValueError(f"Tipo promozione non ammesso: {tipo}")
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        documento = {
            "stato": "attiva",
            **dati,
            "creata_da": creata_da,
            "data_creazione": datetime.now(UTC).isoformat(),
        }
        return dao.crea(col.PROMOZIONI, documento)

    def elenca_promozioni(self, solo_attive: bool = False) -> list[dict[str, Any]]:
        """! @brief Elenca le promozioni configurate per la dashboard operatore (OP.09/OP.15).
        @param solo_attive Se True, restituisce solo le promozioni con `stato` == "attiva".
        @return Lista delle promozioni (sconti, incentivi parcheggio, tariffe evento).
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        filtri = [("stato", "==", "attiva")] if solo_attive else None
        return dao.elenca(col.PROMOZIONI, filtri=filtri)

    def disattiva_promozione(self, id_promozione: str) -> None:
        """! @brief Disattiva una promozione (la rende non più applicabile, OP.15).
        @param id_promozione Id della promozione da disattivare.
        @return Nessuno.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        dao.aggiorna(col.PROMOZIONI, id_promozione, {"stato": "sospesa"})

    @staticmethod
    def _emetti_fattura(dao: DataAccessManager, id_pagamento: str, totale_cent: int) -> str:
        """! @brief Emette una Fattura per un pagamento, con scorporo IVA (UT.25).
        @param dao DataAccessManager connesso.
        @param id_pagamento Id del pagamento fatturato (FK → pagamenti).
        @param totale_cent Totale lordo in centesimi.
        @return Id della fattura creata.
        """
        from server.integration_tier.data_access_manager import collezioni as col

        imponibile = round(totale_cent / (1 + ALIQUOTA_IVA))
        return dao.crea(
            col.FATTURE,
            {
                "numero_progressivo": f"FT-{id_pagamento}",
                "id_pagamento": id_pagamento,
                "imponibile_cent": imponibile,
                "iva_cent": totale_cent - imponibile,
                "totale_cent": totale_cent,
                "storage_path_pdf": None,  # binario su Cloud Storage (stub §4)
            },
        )
