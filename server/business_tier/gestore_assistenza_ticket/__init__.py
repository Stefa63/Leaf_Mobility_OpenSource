"""! @package server.business_tier.gestore_assistenza_ticket
@brief Coda di assistenza utenti e ticket di manutenzione veicoli.
"""

from __future__ import annotations

from datetime import UTC, datetime
from typing import TYPE_CHECKING, Any

from server.integration_tier.data_access_manager import ottieni_dao_opzionale
from server.integration_tier.gateway_email import GatewayEmail

if TYPE_CHECKING:
    from server.integration_tier.data_access_manager import DataAccessManager

#! PrioritÃ  ammesse per i ticket di manutenzione (schema ticket_manutenzione).
PRIORITA_AMMESSE: frozenset[str] = frozenset({"bassa", "media", "alta"})
#! Stati ammessi di una segnalazione SOS lungo la presa in carico operatore (UT.20/OP.08).
STATI_SOS: frozenset[str] = frozenset({"inoltrata", "presa_in_carico", "chiusa"})


class GestoreAssistenzaTicket:
    """! @brief Gestisce supporto utenti e ticket di intervento (UT.09, OP.08/16/19).

    Responsabilita': coda centralizzata delle richieste in entrata, creazione e
    assegnazione ticket ai tecnici, tracciamento dello stato fino a chiusura. La
    persistenza Ã¨ delegata al @ref DataAccessManager (Integration Tier, tier
    adiacente Â§4); il `codice_identificativo_mezzo` Ã¨ denormalizzato alla create (Â§6.6).

    @param dao DataAccessManager opzionale; se None risolto dall'ambiente
               (@ref ottieni_dao_opzionale).
    """

    def __init__(
        self, dao: DataAccessManager | None = None, email: GatewayEmail | None = None
    ) -> None:
        """! @brief Costruisce il gestore, opzionalmente con un DAO/gateway iniettati (test).
        @param dao DataAccessManager da usare; se None risolto dall'ambiente.
        @param email Gateway email per le notifiche di assistenza; default @ref GatewayEmail
                     (disattivato finchÃ© non configurato via ambiente).
        """
        self._dao = dao
        self._email = email or GatewayEmail()

    def _dao_o_errore(self) -> DataAccessManager:
        """! @brief Restituisce il DAO disponibile o segnala la persistenza in sviluppo.
        @return DataAccessManager pronto.
        @throws NotImplementedError Se la persistenza non e' configurata (slice "in sviluppo", Â§9).
        """
        dao = self._dao or ottieni_dao_opzionale()
        if dao is None:
            raise NotImplementedError("DataAccessManager/DB in sviluppo")
        return dao

    def apri_assistenza(
        self, id_utente: str, oggetto: str, messaggio: str, id_corsa: str | None = None
    ) -> str:
        """! @brief Apre una richiesta di assistenza in coda per un utente (UT.09).
        @param id_utente Id dell'utente richiedente (FK â†’ utenti, Â§6.9).
        @param oggetto Oggetto sintetico della richiesta.
        @param messaggio Testo della richiesta di supporto.
        @param id_corsa Id della corsa correlata (opzionale, FK â†’ corse).
        @return Identificativo del ticket di assistenza creato.
        @throws NotImplementedError Se la persistenza non e' configurata.
        @throws ErroreIntegrita Se l'utente non esiste (integritÃ  referenziale).
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        id_ticket = dao.crea(
            col.TICKET_ASSISTENZA,
            {
                "id_utente": id_utente,
                "id_operatore": None,
                "id_corsa": id_corsa,
                "oggetto": oggetto,
                "messaggio": messaggio,
                "stato": "aperto",
                "risposta": None,
                "data_apertura": datetime.now(UTC).isoformat(),
                "data_chiusura": None,
            },
        )
        self._notifica_apertura(dao, id_utente, id_ticket, oggetto, messaggio)
        return id_ticket

    def _notifica_apertura(
        self,
        dao: DataAccessManager,
        id_utente: str,
        id_ticket: str,
        oggetto: str,
        messaggio: str,
    ) -> None:
        """! @brief Invio email best-effort all'apertura di un ticket di assistenza (UT.09).

        Avvisa la casella di supporto (`support@leafmobility.example.com`) della nuova richiesta e
        conferma la ricezione all'utente sul suo indirizzo registrato. Ãˆ un effetto
        accessorio: se il gateway Ã¨ disattivato o l'invio fallisce, non altera l'esito
        dell'apertura del ticket (nessuna eccezione propagata).

        @param dao DataAccessManager connesso (per risolvere l'email dell'utente).
        @param id_utente Id dell'utente richiedente.
        @param id_ticket Id del ticket appena creato.
        @param oggetto Oggetto della richiesta.
        @param messaggio Testo della richiesta.
        @return Nessuno.
        """
        if not self._email.configurato:
            return
        from server.integration_tier.data_access_manager import collezioni as col

        self._email.invia(
            self._email.mittente,
            f"[LEAF Assistenza] {oggetto} (ticket {id_ticket})",
            f"Nuova richiesta di assistenza.\n\n"
            f"Utente: {id_utente}\nTicket: {id_ticket}\n\n{messaggio}\n",
        )
        account = dao.leggi(col.ACCOUNT, id_utente)
        email_utente = str(account.get("email", "")) if account else ""
        if email_utente:
            self._email.invia(
                email_utente,
                "Abbiamo ricevuto la tua richiesta di assistenza",
                f'Ciao,\n\nabbiamo ricevuto la tua richiesta "{oggetto}" '
                f"(ticket {id_ticket}). Ti risponderemo al piÃ¹ presto.\n\n"
                f"Il team LEAF Mobility\n",
            )

    def elenca_assistenza(self, stato: str | None = None) -> list[dict[str, Any]]:
        """! @brief Coda centralizzata delle richieste di assistenza in entrata (OP.08).
        @param stato Filtro opzionale su `stato` (es. "aperto" per le sole pendenti).
        @return Lista dei ticket di assistenza per la dashboard operatore.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        filtri = [("stato", "==", stato)] if stato else None
        return dao.elenca(col.TICKET_ASSISTENZA, filtri=filtri)

    def rispondi_assistenza(
        self, id_ticket: str, id_operatore: str, risposta: str, stato: str = "in_lavorazione"
    ) -> None:
        """! @brief Prende in carico e risponde a una richiesta di assistenza (OP.08).
        @param id_ticket Id del ticket di assistenza.
        @param id_operatore Id dell'operatore che risponde (FK â†’ operatori).
        @param risposta Testo della risposta all'utente.
        @param stato Nuovo stato del ticket (default "in_lavorazione"; "chiuso" per concludere).
        @return Nessuno.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        modifiche: dict[str, Any] = {
            "id_operatore": id_operatore,
            "risposta": risposta,
            "stato": stato,
        }
        if stato == "chiuso":
            modifiche["data_chiusura"] = datetime.now(UTC).isoformat()
        dao.aggiorna(col.TICKET_ASSISTENZA, id_ticket, modifiche)

    def crea_ticket(
        self,
        id_mezzo: str,
        id_operatore_creatore: str,
        descrizione: str,
        priorita: str = "media",
    ) -> str:
        """! @brief Crea un ticket di manutenzione per un veicolo (OP.16/19).
        @param id_mezzo Id del mezzo guasto (FK obbligatoria â†’ mezzi, Â§6.3).
        @param id_operatore_creatore Id dell'operatore che apre il ticket (FK â†’ operatori).
        @param descrizione Descrizione del guasto/intervento richiesto.
        @param priorita PrioritÃ : bassa | media | alta.
        @return Identificativo del ticket creato.
        @throws ValueError Se la prioritÃ  non e' ammessa.
        @throws NotImplementedError Se la persistenza non e' configurata.
        @throws ErroreIntegrita Se mezzo/operatore non esistono (integritÃ  referenziale).
        """
        if priorita not in PRIORITA_AMMESSE:
            raise ValueError(f"PrioritÃ  non ammessa: {priorita}")
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        return dao.crea(
            col.TICKET_MANUTENZIONE,
            {
                "id_mezzo": id_mezzo,
                "id_operatore_creatore": id_operatore_creatore,
                "id_tecnico": None,
                "descrizione_guasto": descrizione,
                "priorita": priorita,
                "stato": "aperto",
                "data_apertura": datetime.now(UTC).isoformat(),
                "data_assegnazione": None,
                "data_chiusura": None,
            },
        )

    def assegna_tecnico(self, id_ticket: str, id_tecnico: str) -> None:
        """! @brief Assegna un ticket di manutenzione a un tecnico (OP.16).
        @param id_ticket Id del ticket di manutenzione.
        @param id_tecnico Id del tecnico assegnatario.
        @return Nessuno.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        from server.integration_tier.data_access_manager import collezioni as col

        self._dao_o_errore().aggiorna(
            col.TICKET_MANUTENZIONE,
            id_ticket,
            {
                "id_tecnico": id_tecnico,
                "stato": "assegnato",
                "data_assegnazione": datetime.now(UTC).isoformat(),
            },
        )

    def elenca_manutenzione(self, stato: str | None = None) -> list[dict[str, Any]]:
        """! @brief Elenca i ticket di manutenzione per la dashboard operatore (OP.19).
        @param stato Filtro opzionale su `stato` (es. "aperto"/"assegnato"/"chiuso").
        @return Lista dei ticket di manutenzione (con codice_identificativo_mezzo denormalizzato).
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        filtri = [("stato", "==", stato)] if stato else None
        return dao.elenca(col.TICKET_MANUTENZIONE, filtri=filtri)

    def elenca_tecnici(self) -> list[dict[str, Any]]:
        """! @brief Elenca i tecnici manutentori assegnabili ai ticket (OP.16).
        @return Lista dei tecnici (id, nome, specializzazione, stato).
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        return dao.elenca(col.TECNICI)

    def chiudi_manutenzione(self, id_ticket: str) -> None:
        """! @brief Chiude un ticket di manutenzione a intervento concluso (OP.19).

        Segna il ticket come `chiuso` con timestamp; il rientro in servizio del mezzo Ã¨
        gestito separatamente dal @ref GestoreFlotta (aggiornamento `stato_operativo`).

        @param id_ticket Id del ticket di manutenzione.
        @return Nessuno.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        dao.aggiorna(
            col.TICKET_MANUTENZIONE,
            id_ticket,
            {"stato": "chiuso", "data_chiusura": datetime.now(UTC).isoformat()},
        )

    def segnala_sos(
        self, id_utente: str, lat: float, lon: float, id_corsa: str | None = None
    ) -> dict[str, Any]:
        """! @brief Registra una segnalazione di emergenza SOS con la posizione (UT.20, IIN-18).

        Inoltra ai soccorsi le coordinate dell'utente in pericolo: la segnalazione Ã¨
        persistita in `segnalazioni_emergenza` con timestamp e stato iniziale "inoltrata"
        (il recapito reale ai soccorsi Ã¨ esterno, Â§13). La posizione Ã¨ normalizzata/cifrata
        at-rest dal @ref DataAccessManager (IIN-4).

        @param id_utente Id dell'utente che attiva l'SOS.
        @param lat Latitudine corrente dell'utente.
        @param lon Longitudine corrente dell'utente.
        @param id_corsa Id della corsa in atto (opzionale).
        @return {id_segnalazione, stato}.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        documento: dict[str, Any] = {
            "id_utente": id_utente,
            "lat": lat,
            "lon": lon,
            "stato": "inoltrata",
            "timestamp": datetime.now(UTC).isoformat(),
        }
        if id_corsa:
            documento["id_corsa"] = id_corsa
        id_segnalazione = dao.crea(col.SEGNALAZIONI_EMERGENZA, documento)
        return {"id_segnalazione": id_segnalazione, "stato": "inoltrata"}

    def elenca_sos(self, stato: str | None = None) -> list[dict[str, Any]]:
        """! @brief Coda live delle segnalazioni di emergenza per l'operatore (UT.20/OP.08).

        Alimenta la coda SOS della console operatore (in precedenza hardcoded): elenca le
        segnalazioni persistite da @ref segnala_sos, dalla piÃ¹ recente, arricchendole con
        l'etichetta leggibile dell'utente (username/nominativo) cosÃ¬ l'operatore identifica
        chi ha chiesto aiuto senza esporre l'id grezzo.

        @param stato Filtro opzionale su `stato` (inoltrata/presa_in_carico/chiusa).
        @return Lista delle segnalazioni SOS, ordinate per timestamp decrescente.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        filtri = [("stato", "==", stato)] if stato else None
        elenco = dao.elenca(col.SEGNALAZIONI_EMERGENZA, filtri=filtri)
        for s in elenco:
            s.update(self._etichetta_utente(dao, str(s.get("id_utente") or "")))
        elenco.sort(key=lambda s: str(s.get("timestamp", "")), reverse=True)
        return elenco

    def aggiorna_stato_sos(
        self, id_segnalazione: str, stato: str, id_operatore: str | None = None
    ) -> dict[str, Any]:
        """! @brief Aggiorna lo stato di una segnalazione SOS (presa in carico/chiusura, OP.08).
        @param id_segnalazione Id della segnalazione su cui agire.
        @param stato Nuovo stato (@ref STATI_SOS).
        @param id_operatore Id dell'operatore che prende in carico (opzionale).
        @return {id_segnalazione, stato}.
        @throws ValueError Se lo stato non e' ammesso.
        @throws NotImplementedError Se la persistenza non e' configurata.
        """
        if stato not in STATI_SOS:
            raise ValueError(f"Stato SOS non ammesso: {stato}")
        dao = self._dao_o_errore()
        from server.integration_tier.data_access_manager import collezioni as col

        modifiche: dict[str, Any] = {"stato": stato}
        if id_operatore:
            modifiche["id_operatore"] = id_operatore
        dao.aggiorna(col.SEGNALAZIONI_EMERGENZA, id_segnalazione, modifiche)
        return {"id_segnalazione": id_segnalazione, "stato": stato}

    @staticmethod
    def _etichetta_utente(dao: DataAccessManager, id_utente: str) -> dict[str, str]:
        """! @brief Etichetta leggibile dell'utente di una SOS (username + nominativo).
        @param dao DataAccessManager connesso.
        @param id_utente Id dell'account che ha attivato l'SOS.
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
