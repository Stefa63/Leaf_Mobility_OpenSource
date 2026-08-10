"""! @package server.presentation_tier.gestore_attivita
@brief Orchestrazione delle attivita' applicative esposte ai client.
"""

from __future__ import annotations

from server.business_tier.gestore_assistenza_ticket import GestoreAssistenzaTicket
from server.business_tier.gestore_corse import GestoreCorse
from server.business_tier.gestore_flotta import GestoreFlotta
from server.business_tier.gestore_geofencing import GestoreGeofencing
from server.business_tier.gestore_profili_ekyc import GestoreProfiliEkyc
from server.business_tier.motore_analitica import MotoreAnalitica


def _come_float(valore: object) -> float | None:
    """! @brief Converte un valore di payload in float (None se assente/non numerico).
    @param valore Valore grezzo dal payload (lat/lon).
    @return Float convertito o None.
    """
    if isinstance(valore, (int, float)):
        return float(valore)
    if isinstance(valore, str):
        try:
            return float(valore)
        except ValueError:
            return None
    return None


def _coppia_coord(payload: dict[str, object], prefisso: str) -> tuple[float, float] | None:
    """! @brief Estrae una coppia di coordinate (lat, lon) dal payload, se entrambe presenti.
    @param payload Parametri dell'azione (con chiavi tipo "da_lat"/"da_lon").
    @param prefisso Prefisso delle chiavi (es. "da" per "da_lat"/"da_lon").
    @return Tupla (lat, lon) se entrambe valide, altrimenti None.
    """
    lat = _come_float(payload.get(f"{prefisso}_lat"))
    lon = _come_float(payload.get(f"{prefisso}_lon"))
    if lat is None or lon is None:
        return None
    return (lat, lon)


class GestoreAttivita:
    """! @brief Coordina i casi d'uso applicativi tra Presentation e Business Tier.

    Responsabilita': ricezione delle azioni utente gia' autenticate
    (ricerca mezzi UT.01/UT.05, prenotazione UT.02, avvio/termine corsa
    UT.10/UT.04, dashboard OP/AP) e loro inoltro ai gestori di dominio del
    Business Tier (@ref GestoreFlotta), restituendo risposte gia' formattate.
    """

    def __init__(self) -> None:
        """! @brief Costruisce il coordinatore collegandolo ai gestori del Business Tier."""
        self._flotta = GestoreFlotta()
        self._corse = GestoreCorse()
        self._geofencing = GestoreGeofencing()
        self._profili = GestoreProfiliEkyc()
        self._analitica = MotoreAnalitica()
        self._assistenza = GestoreAssistenzaTicket()

    def instrada(self, azione: str, payload: dict[str, object]) -> dict[str, object]:
        """! @brief Instrada un'azione applicativa al gestore di dominio competente.
        @param azione Identificativo del caso d'uso (es. "ricerca_mezzi", "avvia_corsa").
        @param payload Parametri dell'azione gia' validati e autorizzati.
        @return Risposta del Business Tier serializzabile per il client.
        @throws NotImplementedError Per le azioni non cablate o con persistenza in sviluppo.
        """
        if azione == "ricerca_mezzi":
            tipo = payload.get("tipo")
            mezzi = self._flotta.mezzi_disponibili(
                lat=_come_float(payload.get("lat")),
                lon=_come_float(payload.get("lon")),
                tipo=tipo if isinstance(tipo, str) else None,
            )
            return {"mezzi": mezzi, "totale": len(mezzi)}
        if azione == "prenota_mezzo":
            scadenza = payload.get("scadenza")
            return {
                "id_prenotazione": self._corse.prenota(
                    str(payload.get("id_utente")),
                    str(payload.get("id_mezzo")),
                    scadenza=str(scadenza) if scadenza else None,
                )
            }
        if azione == "elenca_prenotazioni":
            prenotazioni = self._corse.prenotazioni(str(payload.get("id_utente")))
            return {"prenotazioni": prenotazioni, "totale": len(prenotazioni)}
        if azione == "annulla_prenotazione":
            return self._corse.annulla_prenotazione(
                str(payload.get("id_prenotazione")), str(payload.get("id_utente"))
            )
        if azione == "prenotazioni_attive_op":
            prenotazioni = self._corse.prenotazioni_attive_tutte()
            return {"prenotazioni": prenotazioni, "totale": len(prenotazioni)}
        if azione == "annulla_prenotazione_op":
            return self._corse.annulla_prenotazione_op(str(payload.get("id_prenotazione")))
        if azione == "avvia_corsa":
            id_pren = payload.get("id_prenotazione")
            return self._corse.avvia(
                str(payload.get("id_utente")),
                str(payload.get("id_mezzo")),
                id_prenotazione=str(id_pren) if id_pren else None,
            )
        if azione == "termina_corsa":
            return self._corse.termina(
                str(payload.get("id_corsa")),
                km_percorsi=_come_float(payload.get("km")) or 0.0,
                lat=_come_float(payload.get("lat")),
                lon=_come_float(payload.get("lon")),
            )
        if azione == "stima_corsa":
            durata = payload.get("durata_min")
            id_mezzo = str(payload.get("id_mezzo"))
            id_utente = str(payload.get("id_utente"))
            return (
                self._corse.stima_dettaglio(id_mezzo, id_utente, int(str(durata)))
                if durata is not None
                else self._corse.stima_dettaglio(id_mezzo, id_utente)
            )
        if azione == "corsa_attiva":
            return {"corsa": self._corse.corsa_attiva(str(payload.get("id_utente")))}
        if azione == "pausa_corsa":
            return self._corse.pausa(str(payload.get("id_corsa")))
        if azione == "riprendi_corsa":
            return self._corse.riprendi(str(payload.get("id_corsa")))
        if azione == "valuta_corsa":
            return self._corse.valuta(
                str(payload.get("id_corsa")), int(str(payload.get("stelle") or 0))
            )
        if azione == "suggerisci_luoghi":
            luoghi = self._corse.suggerisci_luoghi(str(payload.get("query") or ""))
            return {"luoghi": luoghi, "totale": len(luoghi)}
        if azione == "cerca_percorsi":
            da = payload.get("da")
            a = payload.get("a")
            return self._corse.pianifica_percorsi(
                da=str(da) if da else None,
                a=str(a) if a else None,
                origine=_coppia_coord(payload, "da"),
                destinazione=_coppia_coord(payload, "a"),
            )
        if azione == "stato_geofencing":
            lat, lon = _come_float(payload.get("lat")), _come_float(payload.get("lon"))
            if lat is None or lon is None:
                raise ValueError("stato_geofencing richiede lat/lon")
            return {
                "vietata": self._geofencing.punto_in_area_vietata(lat, lon),
                "limite_velocita_kmh": self._geofencing.limite_velocita(lat, lon),
            }
        # ── Profilo e onboarding (UT.21/UT.22/UT.24) ──────────────────────────
        if azione == "registra_utente":
            nascita = payload.get("data_nascita")
            nome = payload.get("nome")
            cognome = payload.get("cognome")
            residenza = payload.get("residenza")
            return {
                "id_account": self._profili.registra(
                    str(payload.get("email")),
                    str(payload.get("username")),
                    str(payload.get("password")),
                    data_nascita=str(nascita) if nascita else None,
                    nome=str(nome) if nome else None,
                    cognome=str(cognome) if cognome else None,
                    residenza=str(residenza) if residenza else None,
                )
            }
        if azione == "richiedi_reset":
            return self._profili.richiedi_reset(str(payload.get("identita")))
        if azione == "conferma_reset":
            return self._profili.conferma_reset(
                str(payload.get("identita")),
                str(payload.get("codice")),
                str(payload.get("nuova_password")),
            )
        if azione == "cambia_password":
            return self._profili.cambia_password(
                str(payload.get("id_account")), str(payload.get("nuova_password"))
            )
        if azione == "profilo":
            return self._profili.profilo(str(payload.get("id_account")))
        if azione == "aggiorna_profilo":
            modifiche = payload.get("modifiche")
            return self._profili.aggiorna_profilo(
                str(payload.get("id_account")),
                modifiche if isinstance(modifiche, dict) else {},
            )
        if azione == "registra_metodo_pagamento":
            cvv = payload.get("cvv")
            indirizzo = payload.get("indirizzo_fatturazione")
            return self._profili.registra_metodo_pagamento(
                str(payload.get("id_account")),
                str(payload.get("numero")),
                int(str(payload.get("mese") or 0)),
                int(str(payload.get("anno") or 0)),
                str(payload.get("titolare")),
                cvv=str(cvv) if cvv is not None else None,
                indirizzo_fatturazione=str(indirizzo) if indirizzo is not None else None,
            )
        if azione == "sottoscrivi_abbonamento":
            return self._profili.sottoscrivi_abbonamento(
                str(payload.get("id_account")), str(payload.get("id_piano"))
            )
        if azione == "abbonamenti_utente":
            abbonamenti = self._profili.abbonamenti(str(payload.get("id_account")))
            return {"abbonamenti": abbonamenti, "totale": len(abbonamenti)}
        if azione == "registra_consenso":
            return self._profili.registra_consenso(
                str(payload.get("id_account")),
                str(payload.get("tipo")),
                bool(payload.get("concesso")),
                str(payload.get("versione_privacy")),
            )
        if azione == "carica_kyc":
            return self._profili.carica_documento_kyc(
                str(payload.get("id_account")),
                str(payload.get("tipo")),
                str(payload.get("nome_file")),
            )
        if azione == "elenca_notifiche":
            notifiche = self._profili.notifiche(
                str(payload.get("id_account")), bool(payload.get("solo_non_lette"))
            )
            return {"notifiche": notifiche, "totale": len(notifiche)}
        if azione == "segna_notifica_letta":
            return self._profili.segna_notifica_letta(str(payload.get("id_notifica")))
        if azione == "crea_notifica":
            id_dest = payload.get("id_destinatario")
            return {
                "id_notifica": self._profili.crea_notifica(
                    str(id_dest) if id_dest else None,
                    str(payload.get("tipo") or "servizio"),
                    str(payload.get("titolo")),
                    str(payload.get("messaggio")),
                )
            }
        # ── Storico e fatture utente (UT.17/UT.25) ────────────────────────────
        if azione == "storico_corse":
            corse = self._corse.storico(str(payload.get("id_utente")))
            return {"corse": corse, "totale": len(corse)}
        if azione == "fatture_utente":
            fatture = self._corse.fatture(str(payload.get("id_utente")))
            return {"fatture": fatture, "totale": len(fatture)}
        # ── Dashboard OP: flotta e coda assistenza (AP.03/OP.03/OP.08/OP.20) ──
        if azione == "elenco_flotta":
            stato = payload.get("stato")
            mezzi = self._flotta.elenco(stato=stato if isinstance(stato, str) else None)
            return {"mezzi": mezzi, "totale": len(mezzi)}
        if azione == "stazioni_ricarica":
            stazioni = self._flotta.stazioni_ricarica()
            return {"stazioni": stazioni, "totale": len(stazioni)}
        if azione == "segnala_sos":
            id_corsa = payload.get("id_corsa")
            return self._assistenza.segnala_sos(
                str(payload.get("id_utente")),
                _come_float(payload.get("lat")) or 0.0,
                _come_float(payload.get("lon")) or 0.0,
                id_corsa=str(id_corsa) if id_corsa else None,
            )
        if azione == "elenca_sos":
            stato = payload.get("stato")
            sos = self._assistenza.elenca_sos(stato=stato if isinstance(stato, str) else None)
            return {"sos": sos, "totale": len(sos)}
        if azione == "aggiorna_stato_sos":
            id_operatore = payload.get("id_operatore")
            return self._assistenza.aggiorna_stato_sos(
                str(payload.get("id_segnalazione")),
                str(payload.get("stato")),
                id_operatore=str(id_operatore) if id_operatore else None,
            )
        if azione == "mezzi_guasti":
            mezzi = self._flotta.mezzi_guasti()
            return {"mezzi": mezzi, "totale": len(mezzi)}
        if azione == "report_flotta":
            return self._flotta.report_giornaliero()
        if azione == "imposta_soglia_area":
            return {
                "id_soglia": self._flotta.imposta_soglia_area(
                    str(payload.get("id_area")),
                    int(str(payload.get("minimo") or 0)),
                    str(payload.get("id_operatore")),
                )
            }
        if azione == "imposta_soglia_batteria":
            tipo_mezzo = payload.get("tipo_mezzo")
            return {
                "id_soglia": self._flotta.imposta_soglia_batteria(
                    int(str(payload.get("percentuale") or 0)),
                    str(payload.get("id_operatore")),
                    str(tipo_mezzo) if tipo_mezzo else None,
                )
            }
        if azione == "verifica_soglie":
            allerte = self._flotta.verifica_soglie()
            return {"allerte": allerte, "totale": len(allerte)}
        if azione == "log_telemetria":
            eventi = self._flotta.log_telemetrico(str(payload.get("codice_mezzo")))
            return {"eventi": eventi, "totale": len(eventi)}
        if azione == "blocca_motore":
            esito = self._flotta.blocca_motore_remoto(str(payload.get("codice_mezzo")))
            return {"codice_mezzo": str(payload.get("codice_mezzo")), "bloccato": esito}
        if azione == "sblocca_motore":
            esito = self._flotta.sblocca_motore_remoto(str(payload.get("codice_mezzo")))
            return {"codice_mezzo": str(payload.get("codice_mezzo")), "sbloccato": esito}
        if azione == "elenca_assistenza":
            stato = payload.get("stato")
            ticket = self._assistenza.elenca_assistenza(
                stato=stato if isinstance(stato, str) else None
            )
            return {"ticket": ticket, "totale": len(ticket)}
        if azione == "apri_assistenza":
            id_corsa = payload.get("id_corsa")
            return {
                "id_ticket": self._assistenza.apri_assistenza(
                    str(payload.get("id_utente")),
                    str(payload.get("oggetto")),
                    str(payload.get("messaggio")),
                    id_corsa=str(id_corsa) if id_corsa else None,
                )
            }
        if azione == "rispondi_assistenza":
            self._assistenza.rispondi_assistenza(
                str(payload.get("id_ticket")),
                str(payload.get("id_operatore")),
                str(payload.get("risposta")),
                stato=str(payload.get("stato") or "in_lavorazione"),
            )
            return {"id_ticket": str(payload.get("id_ticket")), "aggiornato": True}
        # ── Dashboard PA: analitiche e geofencing (AP.01/02/04/06/07/08) ──────
        if azione == "analitiche":
            dalla = payload.get("dalla_data")
            alla = payload.get("alla_data")
            aggregati = self._analitica.aggrega_uso(
                dalla_data=str(dalla) if dalla else None,
                alla_data=str(alla) if alla else None,
            )
            return {"per_tipo": aggregati}
        if azione == "report_noleggi":
            dalla = payload.get("dalla_data")
            alla = payload.get("alla_data")
            return {
                "noleggi": self._analitica.report_noleggi_per_tipo(
                    str(dalla) if dalla else None, str(alla) if alla else None
                )
            }
        if azione == "flussi_orari":
            dalla = payload.get("dalla_data")
            alla = payload.get("alla_data")
            return {
                "flussi": self._analitica.flussi_per_ora(
                    str(dalla) if dalla else None, str(alla) if alla else None
                )
            }
        if azione == "mezzi_operativi":
            return {"operativi": self._analitica.percentuale_operativi()}
        if azione == "co2":
            dalla = payload.get("dalla_data")
            alla = payload.get("alla_data")
            return self._analitica.co2_risparmiata(
                str(dalla) if dalla else None, str(alla) if alla else None
            )
        if azione == "elenca_aree":
            aree = self._geofencing.elenca_aree(solo_attive=bool(payload.get("solo_attive")))
            return {"aree": aree, "totale": len(aree)}
        if azione == "crea_area":
            dati = payload.get("dati")
            return {
                "id_area": self._geofencing.crea_area(
                    dati if isinstance(dati, dict) else {},
                    str(payload.get("creata_da")),
                )
            }
        if azione == "elimina_area":
            self._geofencing.elimina_area(str(payload.get("id_area")))
            return {"id_area": str(payload.get("id_area")), "eliminata": True}
        # ── Gestione utenti/AP: sospensione, sblocco, provisioning PA (OP.10/17/18) ──
        if azione == "elenca_account":
            ruolo = payload.get("ruolo")
            account = self._profili.elenca_account(ruolo=ruolo if isinstance(ruolo, str) else None)
            return {"account": account, "totale": len(account)}
        if azione == "imposta_stato_account":
            return {
                "account": self._profili.imposta_stato_account(
                    str(payload.get("id_account")), str(payload.get("stato"))
                )
            }
        if azione == "provisiona_op":
            return self._profili.provisiona_operatore(
                str(payload.get("email")),
                str(payload.get("username")),
                str(payload.get("nome")),
            )
        if azione == "provisiona_pa":
            return self._profili.provisiona_amministrazione(
                str(payload.get("email")),
                str(payload.get("username")),
                str(payload.get("ente")),
                str(payload.get("email_istituzionale")),
            )
        # ── Ticket di manutenzione veicoli (OP.16/OP.19) ──────────────────────
        if azione == "elenca_manutenzione":
            stato = payload.get("stato")
            ticket = self._assistenza.elenca_manutenzione(
                stato=stato if isinstance(stato, str) else None
            )
            return {"ticket": ticket, "totale": len(ticket)}
        if azione == "crea_manutenzione":
            return {
                "id_ticket": self._assistenza.crea_ticket(
                    str(payload.get("id_mezzo")),
                    str(payload.get("id_operatore")),
                    str(payload.get("descrizione")),
                    priorita=str(payload.get("priorita") or "media"),
                )
            }
        if azione == "assegna_manutenzione":
            self._assistenza.assegna_tecnico(
                str(payload.get("id_ticket")), str(payload.get("id_tecnico"))
            )
            return {"id_ticket": str(payload.get("id_ticket")), "assegnato": True}
        if azione == "chiudi_manutenzione":
            self._assistenza.chiudi_manutenzione(str(payload.get("id_ticket")))
            return {"id_ticket": str(payload.get("id_ticket")), "chiuso": True}
        if azione == "elenca_tecnici":
            tecnici = self._assistenza.elenca_tecnici()
            return {"tecnici": tecnici, "totale": len(tecnici)}
        # ── Promozioni e incentivi geografici (OP.09/OP.15) ───────────────────
        if azione == "crea_promozione":
            dati = payload.get("dati")
            return {
                "id_promozione": self._corse.crea_promozione(
                    dati if isinstance(dati, dict) else {}, str(payload.get("creata_da"))
                )
            }
        if azione == "elenca_promozioni":
            promozioni = self._corse.elenca_promozioni(solo_attive=bool(payload.get("solo_attive")))
            return {"promozioni": promozioni, "totale": len(promozioni)}
        if azione == "disattiva_promozione":
            self._corse.disattiva_promozione(str(payload.get("id_promozione")))
            return {"id_promozione": str(payload.get("id_promozione")), "disattivata": True}
        # ── Grandi eventi cittadini (AP.09) ───────────────────────────────────
        if azione == "crea_evento":
            dati = payload.get("dati")
            return {
                "id_evento": self._geofencing.crea_evento(
                    dati if isinstance(dati, dict) else {}, str(payload.get("creata_da"))
                )
            }
        if azione == "elenca_eventi":
            eventi = self._geofencing.elenca_eventi()
            return {"eventi": eventi, "totale": len(eventi)}
        if azione == "elimina_evento":
            self._geofencing.elimina_evento(str(payload.get("id_evento")))
            return {"id_evento": str(payload.get("id_evento")), "eliminato": True}
        raise NotImplementedError("Business Tier in sviluppo")
