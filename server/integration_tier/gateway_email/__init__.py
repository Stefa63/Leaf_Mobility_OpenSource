"""! @package server.integration_tier.gateway_email
@brief Adattatore SMTP per l'invio di email transazionali (UT.09, §13).
"""

from __future__ import annotations

import logging
import os
import smtplib
import ssl
import threading
from email.message import EmailMessage

#! Logger del modulo (compare come "Modulo" nel log strutturato del runtime).
_log = logging.getLogger("gateway_email")


class GatewayEmail:
    """! @brief Invio di email transazionali via SMTP (Gmail), Integration Tier (§13).

    Black-box esterno: i client non accedono mai all'email, che è mediata
    server-side dall'Integration Tier (vincolo tre tier §4). La configurazione è
    letta dall'ambiente (`server/.env`): se mittente o app password mancano, il
    gateway è **DISATTIVATO** e @ref invia è un no-op che ritorna False. Così lo
    sviluppo/test resta offline e nessun invio reale avviene finché non si fornisce
    la app password Gmail (segreto non versionato, come la chiave service account).

    @note Usa la sola libreria standard (`smtplib`/`email`): nessuna nuova dipendenza.
    """

    def __init__(
        self,
        host: str | None = None,
        porta: int | None = None,
        mittente: str | None = None,
        password: str | None = None,
    ) -> None:
        """! @brief Costruisce il gateway leggendo la configurazione dall'ambiente.
        @param host Host SMTP (default da @c LEAF_SMTP_HOST o "smtp.gmail.com").
        @param porta Porta SMTP STARTTLS (default da @c LEAF_SMTP_PORT o 587).
        @param mittente Indirizzo mittente / casella supporto (default @c LEAF_EMAIL_MITTENTE).
        @param password App password SMTP (default da @c LEAF_EMAIL_APP_PASSWORD).
        """
        self._host = host or os.environ.get("LEAF_SMTP_HOST", "smtp.gmail.com")
        self._porta = porta if porta is not None else int(os.environ.get("LEAF_SMTP_PORT", "587"))
        self._mittente = (
            mittente if mittente is not None else os.environ.get("LEAF_EMAIL_MITTENTE", "")
        )
        self._password = (
            password if password is not None else os.environ.get("LEAF_EMAIL_APP_PASSWORD", "")
        )

    @property
    def mittente(self) -> str:
        """! @brief Indirizzo mittente configurato (anche casella di supporto in entrata).
        @return Indirizzo email del mittente (stringa vuota se non configurato).
        """
        return self._mittente

    @property
    def configurato(self) -> bool:
        """! @brief Indica se l'invio reale è abilitato (mittente e credenziale presenti).
        @return True se mittente e app password sono valorizzati, False altrimenti.
        """
        return bool(self._mittente and self._password)

    def invia(self, destinatario: str, oggetto: str, corpo: str) -> bool:
        """! @brief Invia un'email di testo via SMTP STARTTLS (best-effort, UT.09).

        Se il gateway non è configurato (mittente/app password assenti) o il
        destinatario è vuoto non invia nulla e ritorna False (no-op sicuro). Gli
        errori SMTP/rete sono assorbiti (ritorna False) per non interrompere il
        flusso applicativo chiamante: l'invio email è accessorio rispetto
        all'operazione di dominio (es. apertura ticket).

        @param destinatario Indirizzo email del destinatario.
        @param oggetto Oggetto del messaggio.
        @param corpo Corpo testuale del messaggio.
        @return True se l'email è stata inviata, False se saltata o fallita.
        """
        if not self.configurato:
            _log.debug("Invio email saltato: gateway non configurato (mittente/app password).")
            return False
        if not destinatario:
            _log.debug("Invio email saltato: destinatario vuoto.")
            return False
        messaggio = EmailMessage()
        messaggio["From"] = self._mittente
        messaggio["To"] = destinatario
        messaggio["Subject"] = oggetto
        messaggio.set_content(corpo)
        try:
            contesto = ssl.create_default_context()
            with smtplib.SMTP(self._host, self._porta, timeout=10) as server:
                server.starttls(context=contesto)
                server.login(self._mittente, self._password)
                server.send_message(messaggio)
        except (smtplib.SMTPException, OSError) as exc:
            # L'invio è accessorio (best-effort) ma il fallimento NON deve restare
            # invisibile: lo si registra con la causa per la diagnosi (#3 connettività).
            _log.warning(
                "Invio email a %s fallito (%s:%d): %s",
                destinatario,
                self._host,
                self._porta,
                exc,
            )
            return False
        _log.info("Email inviata a %s (oggetto: %s)", destinatario, oggetto)
        return True

    def invia_in_background(self, destinatario: str, oggetto: str, corpo: str) -> None:
        """! @brief Recapita un'email best-effort senza bloccare il chiamante (invio asincrono).

        L'invio SMTP reale (connessione + STARTTLS + login + send) costa ~1-3s e, se
        eseguito in linea dentro un handler `async` (es. `/auth/login`), blocca l'event
        loop e rallenta l'accesso. Per le email puramente accessorie (OTP, avvisi) si
        delega l'invio a un thread daemon: la risposta torna subito e l'email parte in
        parallelo. Gli errori sono già assorbiti da @ref invia (best-effort).

        @note Thread daemon: non trattiene mai l'arresto del processo (riavvio pulito).
            Se il gateway non è configurato @ref invia è un no-op immediato (nessun thread utile),
            ma si delega comunque per uniformità del percorso.

        @param destinatario Indirizzo email del destinatario.
        @param oggetto Oggetto del messaggio.
        @param corpo Corpo testuale del messaggio.
        @return Nessuno (l'esito dell'invio è tracciato nei log del gateway).
        """
        threading.Thread(
            target=self.invia,
            args=(destinatario, oggetto, corpo),
            name="invio-email",
            daemon=True,
        ).start()
