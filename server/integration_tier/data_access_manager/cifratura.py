"""! @file cifratura.py
@brief Cifratura applicativa AES-256 dei campi sensibili 🔒 prima della scrittura (IIN-4).

Firestore cifra at-rest di default; per i campi 🔒 (PII, log GPS, token, documenti)
il canone richiede una **cifratura applicativa AES-256** prima della scrittura
(IIN-4 / AG-SEC-02 / §10.4). Questo modulo isola tale responsabilità dietro
un'interfaccia (@ref CifrarioCampi) con due implementazioni:

- @ref CifrarioNullo — passthrough (nessuna cifratura): default in sviluppo/test e
  contro l'emulatore, dove la cifratura non è l'oggetto del test.
- @ref CifrarioAes256Gcm — AES-256-GCM (riservatezza + autenticità) basato sulla
  libreria `cryptography`.

@warning La dipendenza `cryptography` è **in attesa di approvazione** (§3): NON è in
         server/requirements.txt. @ref CifrarioAes256Gcm la importa in modo pigro e,
         se assente, solleva un errore esplicito. Finché non è approvata e installata
         il @ref DataAccessManager usa @ref CifrarioNullo.
"""

from __future__ import annotations

import base64
import importlib
import importlib.util
import os
from typing import Any, Protocol, runtime_checkable


@runtime_checkable
class CifrarioCampi(Protocol):
    """! @brief Interfaccia di cifratura/decifratura simmetrica dei campi sensibili.

    Implementata dalle strategie concrete usate dal @ref DataAccessManager per
    proteggere i campi 🔒 (§10.4). Opera su stringhe: i valori non testuali vanno
    serializzati a monte (es. JSON) dal chiamante.
    """

    #! True se la strategia cifra realmente (per audit/diagnostica).
    attivo: bool

    def cifra(self, testo: str) -> str:
        """! @brief Cifra un valore testuale.
        @param testo Valore in chiaro.
        @return Token cifrato (testo, trasportabile in un documento Firestore).
        """
        ...

    def decifra(self, token: str) -> str:
        """! @brief Decifra un valore prodotto da @ref cifra.
        @param token Token cifrato.
        @return Valore in chiaro originale.
        """
        ...


class CifrarioNullo:
    """! @brief Strategia passthrough: non cifra (default in sviluppo/test).

    Mantiene il contratto di @ref CifrarioCampi restituendo il valore invariato.
    Usata finché la dipendenza `cryptography` non è approvata (§3) o contro
    l'emulatore Firestore, dove la cifratura non è in prova.
    """

    #! Indica che la strategia NON cifra realmente.
    attivo: bool = False

    def cifra(self, testo: str) -> str:
        """! @brief Restituisce il testo invariato (nessuna cifratura).
        @param testo Valore in chiaro.
        @return Lo stesso valore, non cifrato.
        """
        return testo

    def decifra(self, token: str) -> str:
        """! @brief Restituisce il token invariato (nessuna decifratura).
        @param token Valore memorizzato.
        @return Lo stesso valore, non decifrato.
        """
        return token


class CifrarioAes256Gcm:
    """! @brief Cifratura AES-256-GCM dei campi 🔒 (IIN-4) basata su `cryptography`.

    Ogni valore è cifrato con un nonce casuale a 96 bit; l'output è
    base64(nonce ‖ ciphertext ‖ tag). GCM fornisce riservatezza e autenticità
    (rilevamento di manomissioni). La chiave è a 256 bit (32 byte).

    @param chiave Chiave AES-256 (esattamente 32 byte).
    @throws ValueError Se la chiave non è di 32 byte.
    @warning Richiede la dipendenza `cryptography` (in attesa di approvazione, §3):
             importata in modo pigro in @ref cifra/@ref decifra.
    """

    #! Indica che la strategia cifra realmente.
    attivo: bool = True

    def __init__(self, chiave: bytes) -> None:
        """! @brief Inizializza il cifrario con la chiave AES-256.
        @param chiave Chiave simmetrica di 32 byte (256 bit).
        @throws ValueError Se la chiave non è lunga 32 byte.
        """
        if len(chiave) != 32:
            raise ValueError("La chiave AES-256 deve essere di 32 byte")
        self._chiave = chiave

    @staticmethod
    def da_base64(chiave_b64: str) -> CifrarioAes256Gcm:
        """! @brief Costruisce il cifrario da una chiave codificata base64.
        @param chiave_b64 Chiave AES-256 in base64 (es. dalla variabile d'ambiente).
        @return Istanza di @ref CifrarioAes256Gcm.
        @throws ValueError Se la chiave decodificata non è di 32 byte.
        """
        return CifrarioAes256Gcm(base64.b64decode(chiave_b64))

    def _aesgcm(self) -> Any:
        """! @brief Importa pigramente `cryptography` e crea l'oggetto AESGCM.
        @return Istanza di AESGCM legata alla chiave.
        @throws RuntimeError Se la dipendenza `cryptography` non è installata (§3).
        """
        try:
            # Import pigro via importlib: `cryptography` e' in attesa di approvazione (§3)
            # e non installata; importlib la tratta come Any senza errori di type checking.
            aead = importlib.import_module("cryptography.hazmat.primitives.ciphers.aead")
        except ImportError as exc:  # pragma: no cover - dipende dall'ambiente
            raise RuntimeError(
                "Cifratura AES-256 non disponibile: la dipendenza 'cryptography' "
                "è in attesa di approvazione (§3) e non è installata."
            ) from exc
        return aead.AESGCM(self._chiave)

    def cifra(self, testo: str) -> str:
        """! @brief Cifra un valore con AES-256-GCM e nonce casuale.
        @param testo Valore in chiaro.
        @return base64(nonce ‖ ciphertext ‖ tag).
        @throws RuntimeError Se `cryptography` non è installata.
        """
        aesgcm = self._aesgcm()
        nonce = os.urandom(12)
        cifrato: bytes = aesgcm.encrypt(nonce, testo.encode("utf-8"), None)
        return base64.b64encode(nonce + cifrato).decode("ascii")

    def decifra(self, token: str) -> str:
        """! @brief Decifra un token prodotto da @ref cifra.
        @param token base64(nonce ‖ ciphertext ‖ tag).
        @return Valore in chiaro originale.
        @throws RuntimeError Se `cryptography` non è installata.
        """
        aesgcm = self._aesgcm()
        grezzo = base64.b64decode(token)
        nonce, cifrato = grezzo[:12], grezzo[12:]
        chiaro: bytes = aesgcm.decrypt(nonce, cifrato, None)
        return chiaro.decode("utf-8")


def _naviga(documento: dict[str, object], percorso: str) -> tuple[dict[str, object], str] | None:
    """! @brief Risolve un percorso puntato fino al dizionario contenitore e alla chiave.
    @param documento Documento (dizionario annidato) su cui navigare.
    @param percorso Percorso in notazione puntata (es. "datiUtente.nome").
    @return Coppia (contenitore, chiave_finale) se il percorso esiste, altrimenti None.
    """
    parti = percorso.split(".")
    corrente: dict[str, object] = documento
    for chiave in parti[:-1]:
        prossimo = corrente.get(chiave)
        if not isinstance(prossimo, dict):
            return None
        corrente = prossimo
    return (corrente, parti[-1]) if parti[-1] in corrente else None


def cifra_campi(
    documento: dict[str, object], percorsi: tuple[str, ...], cifrario: CifrarioCampi
) -> dict[str, object]:
    """! @brief Cifra in-place i campi 🔒 indicati dai percorsi puntati.

    I valori non stringa vengono convertiti a stringa prima della cifratura (i tipi
    sensibili del modello — testi, date ISO, liste GPS serializzate — sono testuali
    o serializzabili dal chiamante). I percorsi assenti sono ignorati.

    @param documento Documento da cifrare (modificato in-place e restituito).
    @param percorsi Percorsi puntati dei campi sensibili (vedi @ref collezioni.CAMPI_SENSIBILI).
    @param cifrario Strategia di cifratura.
    @return Lo stesso documento con i campi sensibili cifrati.
    """
    if not cifrario.attivo:
        return documento
    for percorso in percorsi:
        risolto = _naviga(documento, percorso)
        if risolto is None:
            continue
        contenitore, chiave = risolto
        valore = contenitore[chiave]
        if valore is None:
            continue
        contenitore[chiave] = cifrario.cifra(valore if isinstance(valore, str) else str(valore))
    return documento


def decifra_campi(
    documento: dict[str, object], percorsi: tuple[str, ...], cifrario: CifrarioCampi
) -> dict[str, object]:
    """! @brief Decifra in-place i campi 🔒 indicati dai percorsi puntati.
    @param documento Documento da decifrare (modificato in-place e restituito).
    @param percorsi Percorsi puntati dei campi sensibili.
    @param cifrario Strategia di cifratura usata in scrittura.
    @return Lo stesso documento con i campi sensibili in chiaro.
    """
    if not cifrario.attivo:
        return documento
    for percorso in percorsi:
        risolto = _naviga(documento, percorso)
        if risolto is None:
            continue
        contenitore, chiave = risolto
        valore = contenitore[chiave]
        if isinstance(valore, str):
            contenitore[chiave] = cifrario.decifra(valore)
    return documento


def cifrario_da_ambiente() -> CifrarioCampi:
    """! @brief Costruisce la strategia di cifratura in base all'ambiente (IIN-4).

    Attiva l'AES-256-GCM **solo** se è configurata la chiave @c LEAF_AES_KEY (base64 di
    32 byte) **e** la libreria `cryptography` è installata; altrimenti ricade sul cifrario
    passthrough (@ref CifrarioNullo), così sviluppo/test e l'emulatore restano operativi
    senza chiave. La chiave NON è mai hard-coded: in produzione va fornita via ambiente.

    @return @ref CifrarioAes256Gcm se chiave e libreria presenti, altrimenti @ref CifrarioNullo.
    """
    chiave = os.environ.get("LEAF_AES_KEY")
    if chiave and importlib.util.find_spec("cryptography") is not None:
        return CifrarioAes256Gcm.da_base64(chiave)
    return CifrarioNullo()
