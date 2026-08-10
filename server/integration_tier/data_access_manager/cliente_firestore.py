"""! @file cliente_firestore.py
@brief Inizializzazione del client Cloud Firestore (firebase-admin, solo lato server).

Predispone l'unico punto di connessione a Firestore usato dal @ref DataAccessManager
(Integration Tier). La libreria `firebase-admin` è importata in modo **pigro** così che
il pacchetto resti importabile anche dove la dipendenza non è installata (CI runtime,
test offline col fake): l'inizializzazione reale avviene solo quando esiste un bersaglio
configurato.

Selezione del bersaglio (deliverable §2):
- @c FIRESTORE_EMULATOR_HOST valorizzato → **emulatore** Firestore, SENZA credenziali reali
  (sviluppo/test).
- altrimenti @c LEAF_FIREBASE_CRED → chiave service account (`credentials.Certificate`)
  verso il **progetto Cloud reale**.
- nessuno dei due → @c None (la persistenza resta "in sviluppo", §9 dello slice).

@warning Accesso a Firestore SOLO lato server (§4/§6/§13): i client non usano mai l'SDK.
@note La chiave service account NON è versionata (è in server/.gitignore).
"""

from __future__ import annotations

import importlib
import os
from pathlib import Path
from typing import TYPE_CHECKING, Any, Protocol

if TYPE_CHECKING:
    from collections.abc import Callable

#! Radice del pacchetto server/ (per risolvere percorsi relativi della chiave).
_RADICE_SERVER = Path(__file__).resolve().parents[2]
#! Project id fittizio usato con l'emulatore (nessuna risorsa Cloud reale toccata).
_PROGETTO_EMULATORE = "leaf-mobility-emulatore"


class ClienteFirestore(Protocol):
    """! @brief Superficie minima del client Firestore usata dal DataAccessManager.

    Soddisfatta sia dal client reale di `firebase-admin` sia dal
    @ref ClienteFalsoFirestore dei test (duck typing).
    """

    def collection(self, nome: str) -> Any:  # noqa: ANN401
        """! @brief Riferimento a una collezione top-level.
        @param nome Nome della collezione.
        @return Riferimento alla collezione.
        """
        ...

    def transaction(self) -> Any:  # noqa: ANN401
        """! @brief Crea una nuova transazione.
        @return Oggetto transazione.
        """
        ...


def _percorso_chiave(cred_path: str | None) -> Path | None:
    """! @brief Risolve il percorso della chiave service account (assoluto o relativo a server/).
    @param cred_path Valore di LEAF_FIREBASE_CRED (o None).
    @return Percorso esistente della chiave, o None se non configurata/assente.
    """
    if not cred_path:
        return None
    percorso = Path(cred_path)
    if not percorso.is_absolute():
        percorso = (_RADICE_SERVER / percorso).resolve()
    return percorso if percorso.is_file() else None


def _credenziale_emulatore() -> Any:  # noqa: ANN401
    """! @brief Credenziale anonima per l'emulatore (nessuna ADC/chiave reale richiesta).

    Con @c FIRESTORE_EMULATOR_HOST impostato, `firebase-admin` non deve contattare il
    cloud: senza una credenziale esplicita ricadrebbe però sulle Application Default
    Credentials (che in sviluppo/test non esistono → errore). Si fornisce quindi una
    credenziale anonima (`google.auth.AnonymousCredentials`), coerente con l'uso
    dell'emulatore "SENZA credenziali reali" dichiarato in testa al file.

    @return Istanza di credenziale `firebase-admin` che non richiede ADC.
    """
    credentials = importlib.import_module("firebase_admin.credentials")
    google_auth = importlib.import_module("google.auth.credentials")

    class _CredenzialeAnonima(credentials.Base):  # type: ignore[misc, name-defined]
        """! @brief Credenziale firebase-admin che restituisce token anonimi (solo emulatore)."""

        def get_credential(self) -> Any:  # noqa: ANN401
            """! @brief Restituisce la credenziale anonima di google-auth.
            @return Istanza di `AnonymousCredentials`.
            """
            return google_auth.AnonymousCredentials()

    return _CredenzialeAnonima()


def inizializza_firestore(
    cred_path: str | None = None, emulator_host: str | None = None
) -> ClienteFirestore | None:
    """! @brief Inizializza e restituisce il client Firestore reale (o None se non configurato).

    Legge i parametri dagli argomenti o, se assenti, dalle variabili d'ambiente
    @c LEAF_FIREBASE_CRED e @c FIRESTORE_EMULATOR_HOST. Riusa l'app `firebase-admin`
    già inizializzata se presente (idempotente).

    @param cred_path Percorso della chiave service account; default da LEAF_FIREBASE_CRED.
    @param emulator_host Host:porta dell'emulatore; default da FIRESTORE_EMULATOR_HOST.
    @return Client Firestore pronto all'uso, oppure None se non c'è un bersaglio
            configurato o se `firebase-admin` non è installato.
    """
    cred_path = cred_path if cred_path is not None else os.environ.get("LEAF_FIREBASE_CRED")
    emulator_host = (
        emulator_host if emulator_host is not None else os.environ.get("FIRESTORE_EMULATOR_HOST")
    )
    # Una FIRESTORE_EMULATOR_HOST vuota (tipica da .env) verrebbe interpretata dalla
    # libreria google come "usa emulatore" su host vuoto (canale 'dns:///' non valido):
    # va rimossa dall'ambiente per usare davvero il cloud con la chiave service account.
    if not emulator_host:
        os.environ.pop("FIRESTORE_EMULATOR_HOST", None)
    chiave = _percorso_chiave(cred_path)
    if not emulator_host and chiave is None:
        return None

    try:
        # Import pigro via importlib: firebase-admin e' una dipendenza runtime opzionale
        # (assente nei test/CI offline). importlib evita che il type checker tenti di
        # risolvere il modulo (lo tratta come Any), indipendentemente dall'installazione.
        firebase_admin = importlib.import_module("firebase_admin")
        credentials = importlib.import_module("firebase_admin.credentials")
        firestore = importlib.import_module("firebase_admin.firestore")
    except ImportError:  # pragma: no cover - dipende dall'ambiente (CI senza firebase-admin)
        return None

    try:
        app = firebase_admin.get_app()
    except ValueError:
        if emulator_host:
            os.environ["FIRESTORE_EMULATOR_HOST"] = emulator_host
            app = firebase_admin.initialize_app(
                _credenziale_emulatore(), {"projectId": _PROGETTO_EMULATORE}
            )
        else:
            assert chiave is not None
            app = firebase_admin.initialize_app(credentials.Certificate(str(chiave)))
    cliente: ClienteFirestore = firestore.client(app)
    return cliente


def esegui_transazionale(
    cliente: ClienteFirestore,
    corpo: Callable[..., Any],
    *args: Any,  # noqa: ANN401
) -> Any:  # noqa: ANN401
    """! @brief Esegue una funzione in transazione, sul client reale o sul fake.

    Sul fake (@c _e_falso = True) serializza con il lock locale (atomicità nei test);
    sul client reale usa `firestore.transactional` (con retry gestiti dalla libreria).
    In entrambi i casi @p corpo riceve come primo argomento l'oggetto transazione e
    deve usarlo per letture/scritture (compare-and-set su documento singolo, §10.4).

    @param cliente Client Firestore (reale o fake).
    @param corpo Funzione transazionale @c corpo(transaction, *args).
    @param args Argomenti aggiuntivi passati a @p corpo dopo la transazione.
    @return Valore restituito da @p corpo.
    """
    transazione = cliente.transaction()
    if getattr(cliente, "_e_falso", False):
        lock = cliente._lock  # type: ignore[attr-defined]
        with lock:
            return corpo(transazione, *args)
    firestore = importlib.import_module("firebase_admin.firestore")
    avvolto = firestore.transactional(corpo)
    return avvolto(transazione, *args)
