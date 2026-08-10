"""! @package server.integration_tier.data_access_manager.tipi
@brief Enumerazioni di dominio (RBAC, stati, tipi) condivise dai tier.

Contratto pubblico degli enum di dominio: il Business Tier li ri-esporta e il
Presentation Tier (gateway, router `/api/v1`) li usa. I `value` sono **allineati
alle stringhe persistite su Firestore** (vedi @ref collezioni e
`Report/schema_logico_db.md`), così la conversione enum↔documento è l'identità su
`.value` e non rompe DAM/seed/test esistenti. Nessuna dipendenza dalla persistenza
(niente SQLAlchemy): la cifratura AES-256 dei campi 🔒 vive nel @ref cifratura del DAM.
"""

from __future__ import annotations

import enum


class Ruolo(enum.Enum):
    """! @brief Ruoli RBAC del sistema (IIN-5). `value` = codice persistito su Firestore."""

    UT = "UT"
    OP = "OP"
    AP = "PA"  # amministrazione pubblica: lo schema Firestore usa il codice "PA"


class StatoAccount(enum.Enum):
    """! @brief Stato di un account (OP.10/OP.18, IIN-17)."""

    ATTIVO = "attivo"
    SOSPESO = "sospeso"
    DISATTIVATO = "disattivato"


class TipoMezzo(enum.Enum):
    """! @brief Tipologie di mezzo condiviso (UT.05). `value` = discriminante Firestore."""

    EBIKE = "ebike"
    ESCOOTER = "monopattino"
    ECAR = "ecar"
    EMOTORBIKE = "emotorbike"


class StatoMezzo(enum.Enum):
    """! @brief Stato operativo di un mezzo (OP.20). `value` = `stato_operativo` Firestore."""

    DISPONIBILE = "disponibile"
    PRENOTATO = "prenotato"
    IN_USO = "in_uso"
    MANUTENZIONE = "manutenzione"
    SCARICO = "scarico"
    GUASTO = "guasto"


class StatoPrenotazione(enum.Enum):
    """! @brief Ciclo di vita di una prenotazione (UT.02/UT.15, OP.12)."""

    ATTIVA = "attiva"
    SCADUTA = "scaduta"
    ANNULLATA = "annullata"
    CONVERTITA = "convertita_in_corsa"  # allineato al DAM (avvia_corsa)


class StatoCorsa(enum.Enum):
    """! @brief Ciclo di vita di una corsa (UT.10/UT.12/UT.04). `value` = `stato` Firestore."""

    IN_CORSO = "in_corso"
    IN_PAUSA = "in_pausa"
    TERMINATA = "conclusa"  # il DAM/motore_analitica usano "conclusa"


class StatoTransazione(enum.Enum):
    """! @brief Esito di una transazione di pagamento (UT.04/UT.11)."""

    AUTORIZZATA = "autorizzata"
    RIUSCITA = "riuscita"
    FALLITA = "fallita"
    RIMBORSATA = "rimborsata"


class StatoAbbonamento(enum.Enum):
    """! @brief Stato di una sottoscrizione di abbonamento (UT.18/UT.21)."""

    ATTIVO = "attivo"
    SCADUTO = "scaduto"
    ANNULLATO = "annullato"


class TipoArea(enum.Enum):
    """! @brief Tipologia di area di geofencing (AP.04/06/08, OP.04/09/15)."""

    INTERDIZIONE = "interdizione"
    SLOW_ZONE = "slow_zone"
    PARCHEGGIO_INCENTIVATO = "parcheggio_incentivato"
    OPERATIVA = "operativa"
    SCONTO = "sconto"
    CANTIERE = "cantiere"


class StatoTicket(enum.Enum):
    """! @brief Stato di un ticket di manutenzione (OP.03/06/16/19)."""

    APERTO = "aperto"
    ASSEGNATO = "assegnato"
    IN_CORSO = "in_corso"
    CHIUSO = "chiuso"


class StatoAssistenza(enum.Enum):
    """! @brief Stato di una richiesta di assistenza utente (UT.09, OP.08)."""

    APERTA = "aperta"
    IN_CARICO = "in_carico"
    CHIUSA = "chiusa"


class TipoConsenso(enum.Enum):
    """! @brief Tipologia di consenso GDPR (IIN-16)."""

    GEOLOCALIZZAZIONE = "geolocalizzazione"
    MARKETING = "marketing"
    TRATTAMENTO_DATI = "trattamento_dati"


class TipoDocumento(enum.Enum):
    """! @brief Tipo di documento ufficiale per il KYC (UT.22.2)."""

    PATENTE = "patente"
    CARTA_IDENTITA = "carta_identita"


class StatoVerificaKyc(enum.Enum):
    """! @brief Stato della verifica documentale KYC (UT.22.2)."""

    IN_ATTESA = "in_attesa"
    APPROVATO = "approvato"
    RIFIUTATO = "rifiutato"


class TipoTelemetria(enum.Enum):
    """! @brief Tipo di evento telemetrico di un mezzo (OP.07/OP.14)."""

    SBLOCCO = "sblocco"
    BLOCCO = "blocco"
    URTO = "urto"
    ANOMALIA = "anomalia"
    GPS = "gps"
    BATTERIA = "batteria"


class TipoSoglia(enum.Enum):
    """! @brief Tipo di soglia di allerta configurabile (OP.02/OP.22)."""

    MEZZI_AREA = "mezzi_area"
    BATTERIA = "batteria"


class ScopoOtp(enum.Enum):
    """! @brief Scopo di un codice OTP (IIN-9)."""

    MFA = "mfa"
    LOGIN = "login"


class StatoSos(enum.Enum):
    """! @brief Stato di una segnalazione di emergenza (UT.20, IIN-18)."""

    APERTA = "aperta"
    INOLTRATA = "inoltrata"
    GESTITA = "gestita"


class StatoManutenzione(enum.Enum):
    """! @brief Stato di un intervento di manutenzione (OP.19)."""

    PROGRAMMATA = "programmata"
    IN_CORSO = "in_corso"
    COMPLETATA = "completata"


class TipoNotifica(enum.Enum):
    """! @brief Categoria di notifica push (IIN-19, UT.15/UT.19)."""

    PRENOTAZIONE = "prenotazione"
    SERVIZIO = "servizio"
    PROMOZIONE = "promozione"
    SISTEMA = "sistema"
    SOS = "sos"
