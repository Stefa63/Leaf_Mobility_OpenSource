"""! @file test_gateway_email.py
@brief Test del GatewayEmail (Integration Tier): no-op se non configurato, invio
best-effort con assorbimento degli errori. Nessuna rete reale (SMTP mockato).
"""

from __future__ import annotations

import smtplib
from typing import Any, Literal

import pytest

from server.integration_tier.gateway_email import GatewayEmail


def test_email_disattivata_senza_configurazione() -> None:
    """! @brief Senza mittente/password il gateway è disattivato e invia è no-op."""
    gateway = GatewayEmail(mittente="", password="")
    assert gateway.configurato is False
    assert gateway.invia("dest@example.it", "oggetto", "corpo") is False


def test_email_destinatario_vuoto_non_invia() -> None:
    """! @brief Anche se configurato, un destinatario vuoto non produce invii."""
    gateway = GatewayEmail(mittente="leaf@example.it", password="segreto")
    assert gateway.configurato is True
    assert gateway.invia("", "oggetto", "corpo") is False


def test_email_assorbe_errori_smtp(monkeypatch: pytest.MonkeyPatch) -> None:
    """! @brief Gli errori SMTP/rete sono assorbiti: invia ritorna False, niente eccezioni."""

    def _esplodi(*_args: Any, **_kwargs: Any) -> None:  # noqa: ANN401
        raise OSError("rete non disponibile")

    monkeypatch.setattr(smtplib, "SMTP", _esplodi)
    gateway = GatewayEmail(mittente="leaf@example.it", password="segreto")
    assert gateway.invia("dest@example.it", "oggetto", "corpo") is False


def test_email_invio_riuscito(monkeypatch: pytest.MonkeyPatch) -> None:
    """! @brief Percorso d'invio: con SMTP mockato il messaggio è consegnato (True)."""
    inviate: list[Any] = []

    class _FakeSMTP:
        def __init__(self, *_args: Any, **_kwargs: Any) -> None:  # noqa: ANN401
            pass

        def __enter__(self) -> _FakeSMTP:
            return self

        def __exit__(self, *_args: Any) -> Literal[False]:  # noqa: ANN401
            return False

        def starttls(self, context: Any = None) -> None:  # noqa: ANN401
            pass

        def login(self, _utente: str, _password: str) -> None:
            pass

        def send_message(self, messaggio: Any) -> None:  # noqa: ANN401
            inviate.append(messaggio)

    monkeypatch.setattr(smtplib, "SMTP", _FakeSMTP)
    gateway = GatewayEmail(mittente="leaf@example.it", password="segreto")
    assert gateway.invia("dest@example.it", "Oggetto", "Corpo") is True
    assert len(inviate) == 1
    assert inviate[0]["To"] == "dest@example.it"
    assert inviate[0]["From"] == "leaf@example.it"
