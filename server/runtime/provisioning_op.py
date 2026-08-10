"""! @file provisioning_op.py
@brief Provisioning di account Operatore (OP) con credenziali temporanee.
"""

from __future__ import annotations

import json
import secrets
import string
import threading
from datetime import UTC, datetime
from pathlib import Path
from typing import TYPE_CHECKING

from passlib.context import CryptContext

if TYPE_CHECKING:
    from server.runtime.registro_metriche import RegistroMetriche

#! Contesto di hashing password (Passlib §6). Schema pbkdf2_sha256: puro Python,
#! robusto e privo di dipendenze native (evita l'incompatibilita' bcrypt 5.x +
#! passlib su Python 3.14). Niente password in chiaro a riposo (§7.3).
_CTX = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")

#! Insiemi di caratteri per una password temporanea conforme a IIN-5.
_MAIUSC = string.ascii_uppercase
_MINUSC = string.ascii_lowercase
_CIFRE = string.digits
_SPECIALI = "!@#$%?*-_"


class ProvisioningOP:
    """! @brief Crea e cataloga account OP con password temporanea (OP.17, IIN-12).

    Genera una password temporanea robusta (conforme a IIN-5), ne salva solo
    l'hash in uno store JSON locale e marca l'account per cambio obbligatorio al
    primo accesso (IIN-12). E' uno store PROVVISORIO che sostituisce il
    DataAccessManager finche' il database e' in sviluppo: catalogato come
    integration backlog (§17), non come debito tecnico.

    @param percorso_store File JSON di persistenza degli account provvisori.
    @param registro Registro metriche opzionale per contabilizzare l'I/O su store.
    """

    def __init__(self, percorso_store: Path, registro: RegistroMetriche | None = None) -> None:
        """! @brief Inizializza lo store creando la cartella contenitore.
        @param percorso_store Percorso del file JSON degli OP provvisori.
        @param registro Registro metriche opzionale (per @ref registra_io).
        """
        self._percorso = percorso_store
        self._registro = registro
        self._lock = threading.Lock()
        self._percorso.parent.mkdir(parents=True, exist_ok=True)

    @staticmethod
    def genera_password_temporanea(lunghezza: int = 14) -> str:
        """! @brief Genera una password temporanea casuale conforme a IIN-5.
        @param lunghezza Lunghezza totale (>= 8); garantisce maiuscola, cifra e speciale.
        @return Password in chiaro (mostrata una sola volta all'operatore).
        """
        lunghezza = max(8, lunghezza)
        obbligatori = [
            secrets.choice(_MAIUSC),
            secrets.choice(_MINUSC),
            secrets.choice(_CIFRE),
            secrets.choice(_SPECIALI),
        ]
        alfabeto = _MAIUSC + _MINUSC + _CIFRE + _SPECIALI
        resto = [secrets.choice(alfabeto) for _ in range(lunghezza - len(obbligatori))]
        caratteri = obbligatori + resto
        secrets.SystemRandom().shuffle(caratteri)
        return "".join(caratteri)

    def _carica(self) -> dict[str, dict[str, object]]:
        """! @brief Carica lo store dal file JSON.
        @return Mappa username -> record account (vuota se il file non esiste).
        """
        if not self._percorso.is_file():
            return {}
        grezzo = self._percorso.read_text(encoding="utf-8")
        if self._registro is not None:
            self._registro.registra_io(len(grezzo.encode("utf-8")), 0)
        return json.loads(grezzo) if grezzo.strip() else {}

    def _salva(self, dati: dict[str, dict[str, object]]) -> None:
        """! @brief Persiste lo store sul file JSON.
        @param dati Mappa completa degli account da scrivere.
        @return Nessuno.
        """
        grezzo = json.dumps(dati, ensure_ascii=False, indent=2)
        self._percorso.write_text(grezzo, encoding="utf-8")
        if self._registro is not None:
            self._registro.registra_io(0, len(grezzo.encode("utf-8")))

    def esiste(self, username: str) -> bool:
        """! @brief Verifica l'esistenza di un account OP.
        @param username Username da cercare.
        @return True se l'account esiste gia'.
        """
        with self._lock:
            return username in self._carica()

    def crea_op(self, username: str) -> str:
        """! @brief Crea un account OP con password temporanea.
        @param username Username dell'operatore da creare (univoco).
        @return Password temporanea in chiaro, da consegnare e mostrare una volta sola.
        @throws ValueError Se l'username e' vuoto o gia' esistente.
        """
        username = username.strip()
        if not username:
            raise ValueError("Username vuoto")
        with self._lock:
            store = self._carica()
            if username in store:
                raise ValueError(f"Account OP '{username}' gia' esistente")
            temporanea = self.genera_password_temporanea()
            store[username] = {
                "ruolo": "OP",
                "hash_password": _CTX.hash(temporanea),
                "creato_il": datetime.now(UTC).isoformat(timespec="seconds"),
                "password_temporanea": True,
                "deve_cambiare_password": True,  # IIN-12: cambio obbligatorio al 1o accesso
            }
            self._salva(store)
        return temporanea

    def elenco(self) -> list[dict[str, object]]:
        """! @brief Elenca gli account OP provvisori (senza dati segreti).
        @return Lista di record con username, stato e data di creazione (no hash).
        """
        with self._lock:
            store = self._carica()
        return [
            {
                "username": u,
                "ruolo": rec.get("ruolo", "OP"),
                "creato_il": rec.get("creato_il"),
                "deve_cambiare_password": rec.get("deve_cambiare_password", True),
            }
            for u, rec in sorted(store.items())
        ]
