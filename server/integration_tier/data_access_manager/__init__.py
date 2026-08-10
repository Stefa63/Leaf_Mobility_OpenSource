"""! @package server.integration_tier.data_access_manager
@brief Accesso dati verso Cloud Firestore (server-mediato), con cifratura applicativa (§13).

Unico componente che tocca Firestore (§4): il Business Tier lo usa, la Presentation
espone /api/v1; i client non accedono mai direttamente al database. Implementa il
**modello fisico Firestore** allineato a `Report/schema_logico_db.md` (collezioni e
subcollezioni in snake_case §6.2, generalizzazione Account a **chiave condivisa**
§6.1, registri di unicità in transazione §4/IIN-1, denormalizzazioni §6.6, reference
id_X per le N:1 con integrità referenziale applicativa §6.3, geo via geohash §6.7) e
la cifratura AES-256 dei campi 🔒 (IIN-4) tramite un @ref cifratura.CifrarioCampi.

Il client Firestore è iniettabile: reale (firebase-admin) in produzione/emulatore,
@ref cliente_falso.ClienteFalsoFirestore nei test offline. Una piccola funzione di
selezione (@ref ottieni_dao_opzionale) fornisce al Business Tier l'istanza corretta
senza che la Presentation tocchi l'Integration Tier (vincolo a tre tier §4).
"""

from __future__ import annotations

import contextlib
import json
from datetime import UTC, datetime, timedelta
from typing import TYPE_CHECKING, Any

from google.cloud.firestore_v1 import FieldFilter
from passlib.context import CryptContext

from server.integration_tier.data_access_manager import collezioni as col
from server.integration_tier.data_access_manager.cifratura import (
    CifrarioCampi,
    CifrarioNullo,
    cifra_campi,
    cifrario_da_ambiente,
    decifra_campi,
)
from server.integration_tier.data_access_manager.cliente_firestore import (
    esegui_transazionale,
    inizializza_firestore,
)
from server.integration_tier.data_access_manager.geo import geohash, punto_in_poligono, riquadro

if TYPE_CHECKING:
    from server.integration_tier.data_access_manager.cliente_firestore import ClienteFirestore

#! Contesto di verifica password (Passlib, schema pbkdf2_sha256: §6, puro Python).
_CTX_PASSWORD = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")
#! Collezioni con posizione + geohash (schema §6.2: mezzi, stazioni_ricarica).
_COLLEZIONI_GEO: frozenset[str] = frozenset({col.MEZZI, col.STAZIONI_RICARICA})
#! Limite di dispositivi attivi per utente (IIN-14 / schema §6.1 #8).
_MAX_DISPOSITIVI_ATTIVI = 3
#! Tentativi di accesso falliti consecutivi prima del blocco temporaneo (UT, IIN-10).
_MAX_TENTATIVI_UT = 5
#! Tentativi di accesso falliti consecutivi prima del blocco (OP/PA, IIN-10).
_MAX_TENTATIVI_ISTITUZIONALI = 3
#! Durata del blocco account UT dopo troppi tentativi falliti, in minuti (IIN-10).
_BLOCCO_MINUTI_UT = 30


class ErrorePersistenza(RuntimeError):  # noqa: N818 - convenzione di dominio in italiano
    """! @brief Errore generico del layer di persistenza Firestore."""


class ErroreIntegrita(ErrorePersistenza):
    """! @brief Violazione dell'integrità referenziale applicativa (reference inesistente)."""


class ViolazioneUnicita(ErrorePersistenza):
    """! @brief Violazione di una chiave univoca logica (email/username/codice, §6.4 / IIN-1)."""


class LimiteDispositivi(ErrorePersistenza):
    """! @brief Superato il limite di 3 dispositivi attivi per utente (IIN-14 / §6.1 #8)."""


class MezzoNonDisponibile(ErrorePersistenza):
    """! @brief Mezzo già prenotato/non disponibile: blocco esclusivo (UT.02 / §6.1 #24)."""


class ViolazioneXor(ErrorePersistenza):
    """! @brief Pagamento con XOR violato su id_corsa/id_abbonamento."""


def _adesso() -> str:
    """! @brief Timestamp corrente in ISO 8601 UTC (ordinabile lessicograficamente).
    @return Stringa ISO 8601 con offset UTC.
    """
    return datetime.now(UTC).isoformat()


class DataAccessManager:
    """! @brief Unico punto di accesso alla base dati Cloud Firestore (§6/§13).

    Responsabilita': persistenza di tutte le entita' dello schema logico, cifratura
    AES-256 dei campi sensibili e dei log GPS (IIN-4 / AG-SEC-02), generalizzazione
    Account a chiave condivisa, registri di unicità in transazione, integrita'
    referenziale applicativa, vincoli (IIN-14, blocco esclusivo, XOR) e query
    geospaziali (geohash + bounding-box). Nessun altro componente accede al DB.

    @param cliente Client Firestore (reale firebase-admin o fake nei test); None lascia
                   il manager non connesso (compatibilita' con lo scheletro storico).
    @param cifrario Strategia di cifratura dei campi 🔒; default @ref CifrarioNullo
                    (passthrough) finche' la chiave AES non e' configurata (IIN-4).
    """

    def __init__(
        self, cliente: ClienteFirestore | None = None, cifrario: CifrarioCampi | None = None
    ) -> None:
        """! @brief Costruisce il manager legandolo a un client e a una strategia di cifratura.
        @param cliente Client Firestore (reale o fake), o None.
        @param cifrario Strategia di cifratura dei campi sensibili (default passthrough).
        """
        self._client = cliente
        self._cifrario: CifrarioCampi = cifrario or CifrarioNullo()

    # ── Compatibilita' con lo scheletro storico (metodi NON rinominati, §3) ────
    def connesso(self) -> bool:
        """! @brief Indica se la connessione al DB e' attiva.
        @return True se un client Firestore e' stato iniettato.
        """
        return self._client is not None

    def esegui_query(self, sql: str, parametri: dict[str, object] | None = None) -> object:
        """! @brief Non supportato su Firestore (document store schemaless, niente SQL).
        @param sql Istruzione SQL (ignorata).
        @param parametri Parametri di bind (ignorati).
        @return Mai: solleva sempre.
        @throws NotImplementedError Firestore non usa SQL; usare i metodi CRUD/query.
        """
        raise NotImplementedError("Firestore e' un document store: usare i metodi CRUD, non SQL")

    # ── Infrastruttura interna ────────────────────────────────────────────────
    def _coll(self, nome: str) -> Any:  # noqa: ANN401
        """! @brief Riferimento a una collezione top-level (con guardia di connessione).
        @param nome Nome della collezione.
        @return Riferimento di collezione Firestore.
        @throws ErrorePersistenza Se il client non e' connesso.
        """
        if self._client is None:
            raise ErrorePersistenza("DataAccessManager non connesso a Firestore")
        return self._client.collection(nome)

    def _client_o_errore(self) -> ClienteFirestore:
        """! @brief Restituisce il client connesso o solleva.
        @return Client Firestore iniettato.
        @throws ErrorePersistenza Se il client non e' connesso.
        """
        if self._client is None:
            raise ErrorePersistenza("DataAccessManager non connesso a Firestore")
        return self._client

    def _prepara_geo(self, collezione: str, dati: dict[str, Any]) -> None:
        """! @brief Normalizza la posizione: lat/lon → `posizione` {lat,lon} + `geohash` (§6.7).

        Accetta in ingresso lat/lon (o una `posizione` {lat,lon}); calcola il `geohash`
        (in chiaro, grana di cella, campo di range-query per la prossimità) e materializza
        `posizione`. Per le collezioni dove `posizione` è 🔒 (mezzi, §6.5) la serializza a
        stringa JSON, così la cifratura AES-256 successiva la protegge come leaf testuale
        (round-trip pulito); altrove resta una map leggibile.

        @param collezione Collezione di destinazione.
        @param dati Documento (modificato in-place): consuma lat/lon, imposta posizione/geohash.
        @return Nessuno.
        """
        if collezione not in _COLLEZIONI_GEO:
            return
        lat = dati.pop("lat", None)
        lon = dati.pop("lon", None)
        pos = dati.get("posizione")
        if (lat is None or lon is None) and isinstance(pos, dict):
            lat, lon = pos.get("lat"), pos.get("lon")
        if lat is None or lon is None:
            return
        lat_f, lon_f = float(lat), float(lon)
        dati["geohash"] = geohash(lat_f, lon_f)
        posizione = {"lat": lat_f, "lon": lon_f}
        if "posizione" in col.CAMPI_SENSIBILI.get(collezione, ()):
            dati["posizione"] = json.dumps(posizione, separators=(",", ":"))
        else:
            dati["posizione"] = posizione

    @staticmethod
    def _parse_geo(collezione: str, dati: dict[str, Any]) -> dict[str, Any]:
        """! @brief Ricostruisce `posizione` da stringa JSON a map dopo la decifratura.
        @param collezione Collezione del documento letto.
        @param dati Documento (modificato in-place).
        @return Lo stesso documento con `posizione` come map {lat,lon}.
        """
        if collezione in _COLLEZIONI_GEO:
            pos = dati.get("posizione")
            if isinstance(pos, str):
                with contextlib.suppress(ValueError):  # posizione malformata: lascia invariato
                    dati["posizione"] = json.loads(pos)
        return dati

    def _denormalizza_mezzo(self, collezione_o_sub: str, dati: dict[str, Any]) -> None:
        """! @brief Popola i campi 📎 copiati dal mezzo alla create (§6.6).

        Per le collezioni che denormalizzano i dati del mezzo legge il mezzo referenziato
        (`id_mezzo`) e copia `codice_identificativo` (e `tipo_mezzo` dove previsto).

        @param collezione_o_sub Collezione o subcollezione ospite.
        @param dati Documento (modificato in-place) con eventuale `id_mezzo`.
        @return Nessuno.
        """
        if collezione_o_sub not in col.DENORM_MEZZO_COMPLETO | col.DENORM_MEZZO_CODICE:
            return
        id_mezzo = dati.get("id_mezzo")
        if not id_mezzo or dati.get("codice_identificativo_mezzo"):
            return
        mezzo = self.leggi(col.MEZZI, str(id_mezzo))
        if mezzo is None:
            return
        dati["codice_identificativo_mezzo"] = mezzo.get("codice_identificativo")
        if collezione_o_sub in col.DENORM_MEZZO_COMPLETO:
            dati[col.DISCR_TIPO_MEZZO] = mezzo.get(col.DISCR_TIPO_MEZZO)

    def _verifica_riferimenti(self, collezione: str, dati: dict[str, Any]) -> None:
        """! @brief Verifica che i reference id_X puntino a documenti esistenti (no FK del DBMS).
        @param collezione Collezione del documento da scrivere.
        @param dati Documento con eventuali campi reference.
        @return Nessuno.
        @throws ErroreIntegrita Se un reference valorizzato non esiste.
        """
        for campo, bersaglio in col.RIFERIMENTI.get(collezione, {}).items():
            valore = dati.get(campo)
            if valore and self.leggi(bersaglio, str(valore)) is None:
                raise ErroreIntegrita(f"{collezione}.{campo}='{valore}' non esiste in {bersaglio}")

    @staticmethod
    def _con_id(snapshot: Any) -> dict[str, Any]:  # noqa: ANN401
        """! @brief Converte un'istantanea in dizionario includendo l'id documento (_id).
        @param snapshot Istantanea Firestore (DocumentSnapshot o fake).
        @return Dizionario del documento con la chiave aggiuntiva "_id".
        """
        dati: dict[str, Any] = snapshot.to_dict() or {}
        dati["_id"] = snapshot.id
        return dati

    # ── CRUD generico sulle collezioni top-level (§6.2) ───────────────────────
    def crea(self, collezione: str, dati: dict[str, Any], id_doc: str | None = None) -> str:
        """! @brief Crea un documento in una collezione top-level.
        @param collezione Nome della collezione (deve essere prevista dallo schema §6.2).
        @param dati Contenuto del documento (non modificato dall'esterno: ne usa una copia).
        @param id_doc Id desiderato; se None Firestore ne genera uno.
        @return Id del documento creato.
        @throws ValueError Se la collezione non e' prevista dallo schema.
        @throws ErroreIntegrita Se un reference valorizzato non esiste.
        """
        if collezione not in col.COLLEZIONI_TOP_LEVEL:
            raise ValueError(f"Collezione non prevista dallo schema §6.2: {collezione}")
        documento = dict(dati)
        self._denormalizza_mezzo(collezione, documento)
        self._verifica_riferimenti(collezione, documento)
        self._prepara_geo(collezione, documento)
        cifra_campi(documento, col.CAMPI_SENSIBILI.get(collezione, ()), self._cifrario)
        ref = self._coll(collezione).document(id_doc)
        ref.set(documento)
        return str(ref.id)

    def leggi(self, collezione: str, id_doc: str) -> dict[str, Any] | None:
        """! @brief Legge un documento per id, decifrando i campi 🔒.
        @param collezione Nome della collezione.
        @param id_doc Id del documento.
        @return Documento (con "_id") o None se inesistente.
        """
        snap = self._coll(collezione).document(id_doc).get()
        if not snap.exists:
            return None
        dati = self._con_id(snap)
        decifra_campi(dati, col.CAMPI_SENSIBILI.get(collezione, ()), self._cifrario)
        return self._parse_geo(collezione, dati)

    def aggiorna(self, collezione: str, id_doc: str, modifiche: dict[str, Any]) -> None:
        """! @brief Aggiorna campi di un documento (ricalcola il geohash se cambia lat/lon).
        @param collezione Nome della collezione.
        @param id_doc Id del documento.
        @param modifiche Mappa campo→nuovo valore.
        @return Nessuno.
        """
        aggiornamenti = dict(modifiche)
        if collezione in _COLLEZIONI_GEO and "lat" in aggiornamenti and "lon" in aggiornamenti:
            self._prepara_geo(collezione, aggiornamenti)
        cifra_campi(aggiornamenti, col.CAMPI_SENSIBILI.get(collezione, ()), self._cifrario)
        self._coll(collezione).document(id_doc).update(aggiornamenti)

    def elimina(self, collezione: str, id_doc: str) -> None:
        """! @brief Elimina un documento per id.
        @param collezione Nome della collezione.
        @param id_doc Id del documento.
        @return Nessuno.
        """
        self._coll(collezione).document(id_doc).delete()

    def elenca(
        self,
        collezione: str,
        filtri: list[tuple[str, str, Any]] | None = None,
        ordina: tuple[str, str] | None = None,
        limite: int | None = None,
    ) -> list[dict[str, Any]]:
        """! @brief Interroga una collezione con filtri/ordinamento/limite.
        @param collezione Nome della collezione.
        @param filtri Lista di (campo, operatore, valore) (es. [("stato_operativo","==","x")]).
        @param ordina Coppia (campo, direzione) con direzione "ASCENDING"/"DESCENDING".
        @param limite Numero massimo di documenti.
        @return Lista di documenti (ciascuno con "_id"), con i campi 🔒 decifrati.
        """
        query: Any = self._coll(collezione)
        for campo, operatore, valore in filtri or []:
            query = query.where(filter=FieldFilter(campo, operatore, valore))
        if ordina is not None:
            query = query.order_by(ordina[0], direction=ordina[1])
        if limite is not None:
            query = query.limit(limite)
        sensibili = col.CAMPI_SENSIBILI.get(collezione, ())
        risultati: list[dict[str, Any]] = []
        for snap in query.stream():
            dati = self._con_id(snap)
            decifra_campi(dati, sensibili, self._cifrario)
            risultati.append(self._parse_geo(collezione, dati))
        return risultati

    # ── CRUD su subcollezioni (composizione/sottocoll., §6.2) ─────────────────
    def _ref_sub(self, collezione: str, id_padre: str, sub: str) -> Any:  # noqa: ANN401
        """! @brief Riferimento a una subcollezione di un documento padre.
        @param collezione Collezione del padre.
        @param id_padre Id del documento padre.
        @param sub Nome della subcollezione.
        @return Riferimento di subcollezione Firestore.
        @throws ValueError Se la subcollezione non e' ammessa per il padre.
        """
        if sub not in col.SUBCOLLEZIONI.get(collezione, ()):  # integrità dei percorsi §6.2
            raise ValueError(f"Subcollezione '{sub}' non ammessa per '{collezione}'")
        return self._coll(collezione).document(id_padre).collection(sub)

    def crea_in_sub(
        self,
        collezione: str,
        id_padre: str,
        sub: str,
        dati: dict[str, Any],
        id_doc: str | None = None,
    ) -> str:
        """! @brief Crea un documento in una subcollezione (es. utenti/{id}/metodi_pagamento).
        @param collezione Collezione del padre (es. utenti).
        @param id_padre Id del documento padre.
        @param sub Nome della subcollezione (es. metodi_pagamento).
        @param dati Contenuto del documento.
        @param id_doc Id desiderato; se None ne viene generato uno.
        @return Id del documento creato.
        """
        documento = dict(dati)
        self._denormalizza_mezzo(sub, documento)
        cifra_campi(documento, col.CAMPI_SENSIBILI_SUB.get(sub, ()), self._cifrario)
        ref = self._ref_sub(collezione, id_padre, sub).document(id_doc)
        ref.set(documento)
        return str(ref.id)

    def leggi_sub(
        self, collezione: str, id_padre: str, sub: str, id_doc: str
    ) -> dict[str, Any] | None:
        """! @brief Legge un documento di una subcollezione, decifrando i campi 🔒.
        @param collezione Collezione del padre.
        @param id_padre Id del padre.
        @param sub Nome della subcollezione.
        @param id_doc Id del documento.
        @return Documento (con "_id") o None se inesistente.
        """
        snap = self._ref_sub(collezione, id_padre, sub).document(id_doc).get()
        if not snap.exists:
            return None
        return decifra_campi(
            self._con_id(snap), col.CAMPI_SENSIBILI_SUB.get(sub, ()), self._cifrario
        )

    def elenca_sub(
        self,
        collezione: str,
        id_padre: str,
        sub: str,
        filtri: list[tuple[str, str, Any]] | None = None,
    ) -> list[dict[str, Any]]:
        """! @brief Elenca i documenti di una subcollezione, decifrando i campi 🔒.
        @param collezione Collezione del padre.
        @param id_padre Id del padre.
        @param sub Nome della subcollezione.
        @param filtri Lista di (campo, operatore, valore).
        @return Lista di documenti (ciascuno con "_id").
        """
        query: Any = self._ref_sub(collezione, id_padre, sub)
        for campo, operatore, valore in filtri or []:
            query = query.where(filter=FieldFilter(campo, operatore, valore))
        sensibili = col.CAMPI_SENSIBILI_SUB.get(sub, ())
        return [decifra_campi(self._con_id(s), sensibili, self._cifrario) for s in query.stream()]

    # ── Generalizzazione Account a chiave condivisa + registri unicità (§6.1) ──
    def crea_account(
        self,
        ruolo: str,
        email: str,
        password_hash: str,
        profilo: dict[str, Any] | None = None,
        *,
        username: str | None = None,
        extra: dict[str, Any] | None = None,
        id_doc: str | None = None,
    ) -> str:
        """! @brief Crea un Account (UT/OP/PA) e il profilo a chiave condivisa, in transazione.

        Scrive in un'unica transazione (IIN-1): i registri di unicità `email_index`
        (e `username_index` se `username` è dato), il documento `account` con i campi di
        credenziali/lifecycle e il documento di profilo (`utenti`/`operatori`/
        `amministrazioni_pubbliche`) con **document ID = id_account** (§6.1). I campi 🔒
        del profilo (utenti: nome/cognome/…) sono cifrati prima della scrittura.

        @param ruolo Ruolo RBAC: UT, OP o PA (discriminante §6.1).
        @param email Email di accesso (univoca, §6.4 / IIN-1).
        @param password_hash Hash Passlib della password (mai in chiaro).
        @param profilo Campi della collezione di profilo (nome, cognome, ente, …).
        @param username Username univoco opzionale (registro `username_index`).
        @param extra Campi aggiuntivi di account (es. mfa_abilitato, lingua_preferita).
        @param id_doc Id desiderato dell'account; se None ne viene generato uno.
        @return Id dell'account creato (= id del profilo).
        @throws ValueError Se il ruolo non e' ammesso.
        @throws ViolazioneUnicita Se email o username sono gia' registrati.
        """
        if ruolo not in col.RUOLI_AMMESSI:
            raise ValueError(f"Ruolo non ammesso: {ruolo}")
        collezione_profilo = col.MAP_RUOLO_COLLEZIONE[ruolo]
        documento_account: dict[str, Any] = {
            col.DISCR_RUOLO: ruolo,
            "email": email,
            "username": username,
            "password_hash": password_hash,
            "stato_account": "attivo",
            "mfa_abilitato": ruolo in ("OP", "PA"),  # obbligatorio OP/PA (IIN-9)
            "tentativi_falliti": 0,  # lockout IIN-10
            "bloccato_fino": None,
            "password_temporanea": False,  # 1° accesso OP/PA (IIN-12)
            "data_creazione": _adesso(),
            "ultimo_accesso": None,  # retention IIN-17
            "lingua_preferita": "it",
            **(extra or {}),
        }
        documento_profilo = dict(profilo or {})
        if ruolo == "UT":
            documento_profilo.setdefault("dispositivi_attivi", 0)  # contatore IIN-14
        cifra_campi(
            documento_profilo, col.CAMPI_SENSIBILI.get(collezione_profilo, ()), self._cifrario
        )
        cliente = self._client_o_errore()

        def _corpo(transaction: Any) -> str:  # noqa: ANN401
            ref_email = self._coll(col.EMAIL_INDEX).document(email)
            if ref_email.get(transaction=transaction).exists:
                raise ViolazioneUnicita(f"Email gia' registrata: {email}")
            ref_username = None
            if username:
                ref_username = self._coll(col.USERNAME_INDEX).document(username)
                if ref_username.get(transaction=transaction).exists:
                    raise ViolazioneUnicita(f"Username gia' registrato: {username}")
            ref_account = self._coll(col.ACCOUNT).document(id_doc)
            id_account = ref_account.id
            transaction.set(ref_account, documento_account)
            transaction.set(self._coll(collezione_profilo).document(id_account), documento_profilo)
            transaction.set(ref_email, {"id_account": id_account})
            if ref_username is not None:
                transaction.set(ref_username, {"id_account": id_account})
            return str(id_account)

        return str(esegui_transazionale(cliente, _corpo))

    def crea_mezzo(
        self,
        tipo_mezzo: str,
        dati: dict[str, Any],
        attributi: dict[str, Any] | None = None,
        id_doc: str | None = None,
    ) -> str:
        """! @brief Crea un Mezzo (ebike/monopattino/ecar/emotorbike) e il registro codice.

        Scrive in transazione (IIN-1) il mezzo (discriminante `tipo_mezzo` + map
        `attributi_specifici`) e il registro di unicità `mezzo_index/{codice}` →
        id_mezzo (§6.4). L'id documento è interno/auto (non enumerabile, ≠ codice §6.2)
        se `id_doc` è None. Geo e cifratura della posizione/targa come da §6.5/§6.7.

        @param tipo_mezzo Discriminante del tipo di mezzo (§3).
        @param dati Campi comuni del mezzo (codice_identificativo, stato_operativo, lat/lon, …).
        @param attributi Map dei campi specifici del sottotipo (targa, num_posti, …).
        @param id_doc Id documento desiderato; se None ne viene generato uno (auto-ID interno).
        @return Id del mezzo creato.
        @throws ValueError Se il tipo di mezzo non e' ammesso.
        @throws ViolazioneUnicita Se il codice_identificativo e' gia' usato.
        @throws ErroreIntegrita Se un reference valorizzato non esiste.
        """
        if tipo_mezzo not in col.TIPI_MEZZO_AMMESSI:
            raise ValueError(f"Tipo di mezzo non ammesso: {tipo_mezzo}")
        documento: dict[str, Any] = {col.DISCR_TIPO_MEZZO: tipo_mezzo, **dati}
        documento[col.MAP_ATTRIBUTI_MEZZO] = dict(attributi or {})
        codice = documento.get("codice_identificativo")
        self._verifica_riferimenti(col.MEZZI, documento)
        self._prepara_geo(col.MEZZI, documento)
        cifra_campi(documento, col.CAMPI_SENSIBILI.get(col.MEZZI, ()), self._cifrario)
        cliente = self._client_o_errore()

        def _corpo(transaction: Any) -> str:  # noqa: ANN401
            ref_indice = self._coll(col.MEZZO_INDEX).document(str(codice)) if codice else None
            if ref_indice is not None and ref_indice.get(transaction=transaction).exists:
                raise ViolazioneUnicita(f"codice_identificativo gia' usato: {codice}")
            ref_mezzo = self._coll(col.MEZZI).document(id_doc)
            id_mezzo = ref_mezzo.id
            transaction.set(ref_mezzo, documento)
            if ref_indice is not None:
                transaction.set(ref_indice, {"id_mezzo": id_mezzo})
            return str(id_mezzo)

        return str(esegui_transazionale(cliente, _corpo))

    # ── Helper di dominio (login + veicoli + lookup per chiave naturale) ──────
    def leggi_account_per_email(self, email: str) -> dict[str, Any] | None:
        """! @brief Recupera un Account dalla sua email via registro di unicità (§6.4).
        @param email Email di accesso.
        @return Account (con "_id") o None se inesistente.
        """
        snap = self._coll(col.EMAIL_INDEX).document(email).get()
        if not snap.exists:
            return None
        id_account = str((snap.to_dict() or {}).get("id_account"))
        return self.leggi(col.ACCOUNT, id_account)

    def leggi_account_per_username(self, username: str) -> dict[str, Any] | None:
        """! @brief Recupera un Account dal suo username via registro di unicità (§6.4).
        @param username Username di accesso.
        @return Account (con "_id") o None se inesistente.
        """
        snap = self._coll(col.USERNAME_INDEX).document(username).get()
        if not snap.exists:
            return None
        id_account = str((snap.to_dict() or {}).get("id_account"))
        return self.leggi(col.ACCOUNT, id_account)

    def leggi_profilo(self, account: dict[str, Any]) -> dict[str, Any] | None:
        """! @brief Recupera il profilo a chiave condivisa di un account (§6.1).
        @param account Documento account (con "ruolo" e "_id").
        @return Documento di profilo (utenti/operatori/amministrazioni_pubbliche) o None.
        """
        ruolo = account.get("ruolo")
        if ruolo not in col.MAP_RUOLO_COLLEZIONE:
            return None
        return self.leggi(col.MAP_RUOLO_COLLEZIONE[str(ruolo)], str(account.get("_id")))

    def leggi_mezzo_per_codice(self, codice: str) -> dict[str, Any] | None:
        """! @brief Recupera un Mezzo dal suo codice_identificativo via registro (§6.4).
        @param codice Codice identificativo del mezzo (OP.14).
        @return Mezzo (con "_id") o None se inesistente.
        """
        snap = self._coll(col.MEZZO_INDEX).document(codice).get()
        if not snap.exists:
            return None
        id_mezzo = str((snap.to_dict() or {}).get("id_mezzo"))
        return self.leggi(col.MEZZI, id_mezzo)

    def verifica_credenziali(self, account: dict[str, Any], password: str) -> bool:
        """! @brief Verifica una password contro l'hash Passlib dell'account.
        @param account Documento account (deve contenere "password_hash").
        @param password Password in chiaro fornita dal client.
        @return True se la password e' corretta e l'account e' attivo.
        """
        hash_pw = account.get("password_hash")
        if not isinstance(hash_pw, str):
            return False
        if account.get("stato_account") not in (None, "attivo"):
            return False
        return _CTX_PASSWORD.verify(password, hash_pw)

    def account_bloccato(self, account: dict[str, Any]) -> bool:
        """! @brief Indica se l'account e' attualmente bloccato per lockout (IIN-10).
        @param account Documento account (con "bloccato_fino").
        @return True se `bloccato_fino` e' un istante futuro.
        """
        fino = account.get("bloccato_fino")
        if not isinstance(fino, str):
            return False
        try:
            return datetime.fromisoformat(fino) > datetime.now(UTC)
        except ValueError:  # pragma: no cover - timestamp malformato
            return False

    def registra_accesso_riuscito(self, id_account: str) -> None:
        """! @brief Azzera il contatore di lockout e registra l'ultimo accesso (IIN-10/IIN-17).
        @param id_account Id dell'account.
        @return Nessuno.
        """
        self.aggiorna(
            col.ACCOUNT,
            id_account,
            {"tentativi_falliti": 0, "bloccato_fino": None, "ultimo_accesso": _adesso()},
        )

    def registra_tentativo_fallito(self, account: dict[str, Any]) -> dict[str, Any]:
        """! @brief Incrementa i tentativi falliti e blocca l'account oltre la soglia (IIN-10).
        @param account Documento account (con "_id" e "tentativi_falliti").
        @return Esito {tentativi_falliti, bloccato} dopo l'aggiornamento.
        """
        ruolo = str(account.get("ruolo", "UT"))
        soglia = _MAX_TENTATIVI_ISTITUZIONALI if ruolo in ("OP", "PA") else _MAX_TENTATIVI_UT

        tentativi = int(account.get("tentativi_falliti", 0)) + 1
        modifiche: dict[str, Any] = {"tentativi_falliti": tentativi}
        bloccato = tentativi >= soglia
        if bloccato:
            # UT: blocco temporaneo (30 min). OP/PA: blocco permanente (richiede sblocco manuale).
            minuti = _BLOCCO_MINUTI_UT if ruolo == "UT" else 999999
            scadenza = datetime.now(UTC) + timedelta(minutes=minuti)
            modifiche["bloccato_fino"] = scadenza.isoformat()
        self.aggiorna(col.ACCOUNT, str(account.get("_id")), modifiche)
        return {"tentativi_falliti": tentativi, "bloccato": bloccato}

    # ── Token di reset password (IIN-11, store effimero monouso) ──────────────
    def memorizza_token_reset(self, id_account: str, codice_hash: str, scadenza_iso: str) -> None:
        """! @brief Memorizza (o sostituisce) il token di reset password monouso (IIN-11).

        Document ID = id_account: una nuova richiesta sovrascrive la precedente, così resta
        valido solo l'ultimo codice emesso. Il codice arriva gia' hashato dal Business Tier
        (mai in chiaro a riposo, IIN-4).

        @param id_account Id dell'account proprietario del token.
        @param codice_hash Hash Passlib del codice monouso.
        @param scadenza_iso Istante di scadenza in ISO 8601 UTC (TTL di reset, IIN-11).
        @return Nessuno.
        """
        self._coll(col.RESET_TOKEN).document(id_account).set(
            {
                "id_account": id_account,
                "codice_hash": codice_hash,
                "scadenza": scadenza_iso,
                "creato": _adesso(),
            }
        )

    def leggi_token_reset(self, id_account: str) -> dict[str, Any] | None:
        """! @brief Legge il token di reset password di un account (IIN-11).
        @param id_account Id dell'account.
        @return Documento token {codice_hash, scadenza, ...} o None se assente.
        """
        snap = self._coll(col.RESET_TOKEN).document(id_account).get()
        return dict(snap.to_dict() or {}) if snap.exists else None

    def elimina_token_reset(self, id_account: str) -> None:
        """! @brief Elimina il token di reset (consumo monouso o invalidazione, IIN-11).
        @param id_account Id dell'account.
        @return Nessuno.
        """
        self._coll(col.RESET_TOKEN).document(id_account).delete()

    def mezzi_disponibili(
        self,
        lat: float | None = None,
        lon: float | None = None,
        raggio_m: float = 2000.0,
        tipo: str | None = None,
    ) -> list[dict[str, Any]]:
        """! @brief Elenca i mezzi disponibili, opzionalmente nei pressi di un punto (UT.01/UT.05).

        Legge da `mezzi` con filtro su `stato_operativo` (e tipo); se sono dati lat/lon
        usa il `geohash` in chiaro per restringere i candidati (range-query di prossimità,
        §6.7), poi raffina con la distanza esatta sulla `posizione` decifrata del solo set
        ristretto e ordina per distanza crescente. La coordinata fine resta cifrata a riposo.

        @param lat Latitudine del centro di ricerca (opzionale).
        @param lon Longitudine del centro di ricerca (opzionale).
        @param raggio_m Raggio di ricerca in metri (default 2000).
        @param tipo Filtro opzionale per tipo di mezzo.
        @return Lista di mezzi disponibili (ordinati per distanza se lat/lon presenti).
        """
        filtri: list[tuple[str, str, Any]] = [("stato_operativo", "==", "disponibile")]
        if tipo is not None:
            filtri.append((col.DISCR_TIPO_MEZZO, "==", tipo))
        mezzi = self.elenca(col.MEZZI, filtri=filtri)
        if lat is None or lon is None:
            return mezzi
        from server.integration_tier.data_access_manager.geo import distanza_m

        lat_min, lat_max, lon_min, lon_max = riquadro(lat, lon, raggio_m)
        vicini: list[dict[str, Any]] = []
        for m in mezzi:
            pos = m.get("posizione")
            if not isinstance(pos, dict) or pos.get("lat") is None or pos.get("lon") is None:
                continue
            mlat, mlon = float(pos["lat"]), float(pos["lon"])
            if lat_min <= mlat <= lat_max and lon_min <= mlon <= lon_max:
                vicini.append(m)
        vicini.sort(
            key=lambda m: distanza_m(
                lat, lon, float(m["posizione"]["lat"]), float(m["posizione"]["lon"])
            )
        )
        return vicini

    def aree_contenenti(self, lat: float, lon: float) -> list[dict[str, Any]]:
        """! @brief Aree di geofencing attive che contengono un punto (point-in-polygon, §6.7).
        @param lat Latitudine del punto.
        @param lon Longitudine del punto.
        @return Aree attive il cui poligono contiene il punto (AP.06/AP.08/OP.04).
        """
        contenitrici: list[dict[str, Any]] = []
        for area in self.elenca(col.AREE_LIMITATE, filtri=[("stato", "==", "attiva")]):
            geometria = area.get("geometria")
            if isinstance(geometria, list):
                vertici = [(float(p["lat"]), float(p["lon"])) for p in geometria]
                if punto_in_poligono(lat, lon, vertici):
                    contenitrici.append(area)
        return contenitrici

    def conta_mezzi_in_area(self, area: dict[str, Any]) -> int:
        """! @brief Conta i mezzi la cui posizione cade nel poligono di un'area (OP.02).

        Usato dalla verifica delle soglie minime di mezzi per area: itera i mezzi,
        decifra la `posizione` (§6.5/§6.7) e applica il point-in-polygon sulla
        `geometria` dell'area. La posizione dei mezzi è già decifrata da @ref elenca.

        @param area Documento area con `geometria` [{lat,lon}].
        @return Numero di mezzi contenuti nell'area (0 se l'area non ha geometria).
        """
        geometria = area.get("geometria")
        if not isinstance(geometria, list) or not geometria:
            return 0
        vertici = [(float(p["lat"]), float(p["lon"])) for p in geometria]
        presenti = 0
        for mezzo in self.elenca(col.MEZZI):
            pos = mezzo.get("posizione")
            if not isinstance(pos, dict) or pos.get("lat") is None or pos.get("lon") is None:
                continue
            if punto_in_poligono(float(pos["lat"]), float(pos["lon"]), vertici):
                presenti += 1
        return presenti

    # ── Vincoli via transazioni (compare-and-set su documento singolo) ────────
    def registra_dispositivo(
        self,
        id_utente: str,
        device_id: str,
        ip: str | None = None,
        nome_dispositivo: str | None = None,
    ) -> str:
        """! @brief Registra un dispositivo attivo applicando il limite di 3 (IIN-14 / §6.1 #8).

        Transazione di compare-and-set sul contatore `dispositivi_attivi` del profilo utente:
        se gia' a 3 rifiuta; altrimenti crea utenti/{id}/dispositivi/{device_id} e incrementa.

        @param id_utente Id dell'utente (= id_account).
        @param device_id Identificativo del dispositivo (usato come id documento).
        @param ip Indirizzo IP del dispositivo (opzionale).
        @param nome_dispositivo Nome leggibile del dispositivo (opzionale).
        @return Id del documento dispositivo creato.
        @throws ErroreIntegrita Se l'utente non esiste.
        @throws LimiteDispositivi Se l'utente ha gia' 3 dispositivi attivi.
        """
        cliente = self._client_o_errore()

        def _corpo(transaction: Any) -> str:  # noqa: ANN401
            ref_utente = self._coll(col.UTENTI).document(id_utente)
            snap = ref_utente.get(transaction=transaction)
            if not snap.exists:
                raise ErroreIntegrita(f"Utente '{id_utente}' inesistente")
            ref_disp = ref_utente.collection(col.SUB_DISPOSITIVI).document(device_id)
            snap_disp = ref_disp.get(transaction=transaction)  # lettura prima delle scritture
            gia_attivo = snap_disp.exists and bool((snap_disp.to_dict() or {}).get("attiva"))
            attivi = int((snap.to_dict() or {}).get("dispositivi_attivi", 0))
            if gia_attivo:
                # Re-login dallo STESSO dispositivo: aggiorna solo l'ultimo accesso, NON
                # consuma un nuovo slot né rivaluta il limite (IIN-14). Senza questo controllo
                # ogni login (dopo riavvio app/server, con sessioni in-memory perse) gonfiava
                # `dispositivi_attivi` portando a falsi "limite dispositivi superato".
                transaction.update(ref_disp, {"ip": ip, "ultimo_accesso": _adesso()})
                return str(ref_disp.id)
            if attivi >= _MAX_DISPOSITIVI_ATTIVI:
                raise LimiteDispositivi("Massimo 3 dispositivi attivi per utente (IIN-14)")
            transaction.set(
                ref_disp,
                {
                    "device_id": device_id,
                    "nome_dispositivo": nome_dispositivo,
                    "ip": ip,
                    "attiva": True,
                    "ultimo_accesso": _adesso(),
                },
            )
            transaction.update(ref_utente, {"dispositivi_attivi": attivi + 1})
            return str(ref_disp.id)

        return str(esegui_transazionale(cliente, _corpo))

    def rimuovi_dispositivo(self, id_utente: str, device_id: str) -> bool:
        """! @brief Disattiva un dispositivo liberando uno slot del limite di 3 (IIN-14 / §6.1 #8).

        Operazione inversa di @ref registra_dispositivo, invocata al logout: in transazione
        marca il documento utenti/{id}/dispositivi/{device_id} come non attivo e decrementa il
        contatore `dispositivi_attivi` del profilo (mai sotto zero). Idempotente: se il
        dispositivo è assente o già inattivo non modifica nulla e restituisce False.

        @param id_utente Id dell'utente (= id_account).
        @param device_id Identificativo del dispositivo da disattivare.
        @return True se uno slot è stato liberato, False se non c'era nulla da liberare.
        @throws ErroreIntegrita Se l'utente non esiste.
        """
        cliente = self._client_o_errore()

        def _corpo(transaction: Any) -> bool:  # noqa: ANN401
            ref_utente = self._coll(col.UTENTI).document(id_utente)
            snap = ref_utente.get(transaction=transaction)
            if not snap.exists:
                raise ErroreIntegrita(f"Utente '{id_utente}' inesistente")
            ref_disp = ref_utente.collection(col.SUB_DISPOSITIVI).document(device_id)
            snap_disp = ref_disp.get(transaction=transaction)  # lettura prima delle scritture
            if not snap_disp.exists or not (snap_disp.to_dict() or {}).get("attiva"):
                return False  # nessuno slot da liberare (idempotente)
            attivi = int((snap.to_dict() or {}).get("dispositivi_attivi", 0))
            transaction.update(ref_disp, {"attiva": False, "ultimo_accesso": _adesso()})
            transaction.update(ref_utente, {"dispositivi_attivi": max(0, attivi - 1)})
            return True

        return bool(esegui_transazionale(cliente, _corpo))

    def prenota_mezzo(self, id_utente: str, id_mezzo: str, scadenza: str | None = None) -> str:
        """! @brief Prenota un mezzo con blocco esclusivo in transazione (UT.02 / §6.1 #24).

        Transazione: legge mezzi/{id}; se non `disponibile` rifiuta; altrimenti porta
        `stato_operativo` a "prenotato" (il flag di stato è il lock: Firestore non blocca
        range di query) e crea la prenotazione con i campi 📎 denormalizzati dal mezzo (§6.6).

        @param id_utente Id dell'utente che prenota.
        @param id_mezzo Id del mezzo da prenotare.
        @param scadenza Scadenza della prenotazione in ISO 8601 (opzionale, UT.15).
        @return Id della prenotazione creata.
        @throws ErroreIntegrita Se il mezzo non esiste.
        @throws MezzoNonDisponibile Se il mezzo non e' disponibile.
        """
        cliente = self._client_o_errore()

        def _corpo(transaction: Any) -> str:  # noqa: ANN401
            ref_mezzo = self._coll(col.MEZZI).document(id_mezzo)
            snap = ref_mezzo.get(transaction=transaction)
            if not snap.exists:
                raise ErroreIntegrita(f"Mezzo '{id_mezzo}' inesistente")
            dati = snap.to_dict() or {}
            if dati.get("stato_operativo") != "disponibile":
                raise MezzoNonDisponibile(f"Mezzo '{id_mezzo}' non disponibile alla prenotazione")
            ref_pren = self._coll(col.PRENOTAZIONI).document()
            transaction.set(
                ref_pren,
                {
                    "id_utente": id_utente,
                    "id_mezzo": id_mezzo,
                    "codice_identificativo_mezzo": dati.get("codice_identificativo"),  # 📎
                    col.DISCR_TIPO_MEZZO: dati.get(col.DISCR_TIPO_MEZZO),  # 📎
                    "stato": "attiva",
                    "data_ora_inizio": _adesso(),
                    "data_ora_scadenza": scadenza,
                },
            )
            transaction.update(ref_mezzo, {"stato_operativo": "prenotato"})
            return str(ref_pren.id)

        return str(esegui_transazionale(cliente, _corpo))

    def elenca_prenotazioni_attive(self, id_utente: str, limite: int = 50) -> list[dict[str, Any]]:
        """! @brief Prenotazioni attive di un utente, dalla più recente (UT.02/UT.21).

        Filtra le prenotazioni dell'utente con `stato` == "attiva" (esclude quelle
        convertite in corsa o annullate) e le ordina per inizio decrescente. Il filtro di
        stato e l'ordinamento sono applicati lato applicazione per non richiedere indici
        compositi Firestore aggiuntivi.

        @param id_utente Id dell'utente.
        @param limite Numero massimo di prenotazioni restituite (default 50).
        @return Lista delle prenotazioni attive (con campi 📎 denormalizzati dal mezzo).
        """
        prenotazioni = self.elenca(col.PRENOTAZIONI, filtri=[("id_utente", "==", id_utente)])
        attive = [p for p in prenotazioni if p.get("stato") == "attiva"]
        attive.sort(key=lambda p: str(p.get("data_ora_inizio") or ""), reverse=True)
        return attive[:limite]

    def annulla_prenotazione(
        self, id_prenotazione: str, id_utente: str | None = None
    ) -> dict[str, Any]:
        """! @brief Annulla una prenotazione attiva e libera il mezzo (UT.12/OP.12).

        Transazione: legge la prenotazione e il mezzo (tutte le letture prima delle
        scritture, vincolo Firestore); se la prenotazione non è "attiva" rifiuta; se
        `id_utente` è dato verifica la proprietà (un UT annulla solo le proprie); porta la
        prenotazione a "annullata" e riporta il mezzo a "disponibile" se ancora "prenotato".

        @param id_prenotazione Id della prenotazione da annullare.
        @param id_utente Id dell'utente richiedente per il controllo di proprietà
                         (None = operatore OP.12, controllo saltato).
        @return {id_prenotazione, id_mezzo, annullata: True}.
        @throws ErroreIntegrita Se la prenotazione non esiste o non appartiene all'utente.
        @throws MezzoNonDisponibile Se la prenotazione non è più attiva.
        """
        cliente = self._client_o_errore()

        def _corpo(transaction: Any) -> dict[str, Any]:  # noqa: ANN401
            ref_pren = self._coll(col.PRENOTAZIONI).document(id_prenotazione)
            snap = ref_pren.get(transaction=transaction)
            if not snap.exists:
                raise ErroreIntegrita(f"Prenotazione '{id_prenotazione}' inesistente")
            dati = snap.to_dict() or {}
            if id_utente is not None and dati.get("id_utente") != id_utente:
                raise ErroreIntegrita("La prenotazione non appartiene all'utente")
            if dati.get("stato") != "attiva":
                raise MezzoNonDisponibile(f"Prenotazione '{id_prenotazione}' non più attiva")
            id_mezzo = dati.get("id_mezzo")
            # Lettura del mezzo prima di qualunque scrittura (vincolo transazioni Firestore).
            ref_mezzo = self._coll(col.MEZZI).document(str(id_mezzo)) if id_mezzo else None
            mezzo_da_liberare = False
            if ref_mezzo is not None:
                snap_mezzo = ref_mezzo.get(transaction=transaction)
                mezzo_da_liberare = (
                    snap_mezzo.exists
                    and (snap_mezzo.to_dict() or {}).get("stato_operativo") == "prenotato"
                )
            transaction.update(ref_pren, {"stato": "annullata"})
            if mezzo_da_liberare and ref_mezzo is not None:
                transaction.update(ref_mezzo, {"stato_operativo": "disponibile"})
            return {"id_prenotazione": id_prenotazione, "id_mezzo": id_mezzo, "annullata": True}

        return dict(esegui_transazionale(cliente, _corpo))

    def avvia_corsa(
        self,
        id_utente: str,
        id_mezzo: str,
        id_prenotazione: str | None = None,
        costo_stimato_cent: int | None = None,
    ) -> str:
        """! @brief Avvia una corsa sbloccando il mezzo in transazione (UT.10 / §6.1 #25).

        Transazione: legge mezzi/{id}; ammette lo sblocco solo da `disponibile` o
        `prenotato`; porta `stato_operativo` a "in_uso" e crea la corsa `in_corso` con i
        campi 📎 denormalizzati dal mezzo. Se la corsa nasce da una prenotazione, questa
        è marcata `convertita_in_corsa` (§6.1 #29). L'esistenza dell'utente è verificata
        prima della transazione (integrità referenziale applicativa, §6.3).

        @param id_utente Id dell'utente (= id_account) che avvia la corsa.
        @param id_mezzo Id del mezzo da sbloccare.
        @param id_prenotazione Id della prenotazione da convertire (opzionale).
        @param costo_stimato_cent Stima preventiva del costo in centesimi (opzionale, UT.03).
        @return Id della corsa creata.
        @throws ErroreIntegrita Se l'utente o il mezzo non esistono.
        @throws MezzoNonDisponibile Se il mezzo non e' sbloccabile.
        """
        if self.leggi(col.UTENTI, id_utente) is None:
            raise ErroreIntegrita(f"Utente '{id_utente}' inesistente")
        cliente = self._client_o_errore()

        def _corpo(transaction: Any) -> str:  # noqa: ANN401
            ref_mezzo = self._coll(col.MEZZI).document(id_mezzo)
            snap = ref_mezzo.get(transaction=transaction)
            if not snap.exists:
                raise ErroreIntegrita(f"Mezzo '{id_mezzo}' inesistente")
            dati = snap.to_dict() or {}
            if dati.get("stato_operativo") not in ("disponibile", "prenotato"):
                raise MezzoNonDisponibile(f"Mezzo '{id_mezzo}' non sbloccabile (UT.10)")
            ref_corsa = self._coll(col.CORSE).document()
            transaction.set(
                ref_corsa,
                {
                    "id_utente": id_utente,
                    "id_mezzo": id_mezzo,
                    "codice_identificativo_mezzo": dati.get("codice_identificativo"),  # 📎
                    col.DISCR_TIPO_MEZZO: dati.get(col.DISCR_TIPO_MEZZO),  # 📎
                    "id_prenotazione": id_prenotazione,
                    "stato": "in_corso",
                    "data_ora_inizio": _adesso(),
                    "data_ora_fine": None,
                    "km_percorsi": 0.0,
                    "durata_min": 0,
                    "costo_stimato_cent": costo_stimato_cent,
                    "costo_finale_cent": None,
                },
            )
            transaction.update(ref_mezzo, {"stato_operativo": "in_uso"})
            if id_prenotazione:
                transaction.update(
                    self._coll(col.PRENOTAZIONI).document(id_prenotazione),
                    {"stato": "convertita_in_corsa"},
                )
            return str(ref_corsa.id)

        return str(esegui_transazionale(cliente, _corpo))

    def aggiorna_stato_corsa(self, id_corsa: str, stato: str) -> None:
        """! @brief Aggiorna lo stato di una corsa (es. pausa/ripresa, UT.12).
        @param id_corsa Id della corsa.
        @param stato Nuovo stato (in_corso | in_pausa | conclusa | interrotta).
        @return Nessuno.
        """
        self.aggiorna(col.CORSE, id_corsa, {"stato": stato})

    def termina_corsa(
        self, id_corsa: str, km_percorsi: float = 0.0, costo_finale_cent: int | None = None
    ) -> dict[str, Any]:
        """! @brief Conclude una corsa e libera il mezzo (UT.04 / OP.05).

        Calcola la durata dall'inizio, registra km/costo finale, porta la corsa a
        "conclusa" e riporta il mezzo a "disponibile". Compare-and-set su documenti
        singoli (la corsa e il mezzo sono indipendenti: nessun blocco di range).

        @param id_corsa Id della corsa da concludere.
        @param km_percorsi Chilometri percorsi (IIN-24).
        @param costo_finale_cent Importo finale in centesimi (se gia' calcolato a monte).
        @return Documento della corsa conclusa (con durata e stato aggiornati).
        @throws ErroreIntegrita Se la corsa non esiste.
        """
        corsa = self.leggi(col.CORSE, id_corsa)
        if corsa is None:
            raise ErroreIntegrita(f"Corsa '{id_corsa}' inesistente")
        inizio = corsa.get("data_ora_inizio")
        durata_min = 0
        if isinstance(inizio, str):
            delta = datetime.now(UTC) - datetime.fromisoformat(inizio)
            durata_min = max(0, int(delta.total_seconds() // 60))
        modifiche: dict[str, Any] = {
            "stato": "conclusa",
            "data_ora_fine": _adesso(),
            "durata_min": durata_min,
            "km_percorsi": km_percorsi,
            "costo_finale_cent": costo_finale_cent,
        }
        self.aggiorna(col.CORSE, id_corsa, modifiche)
        id_mezzo = corsa.get("id_mezzo")
        if id_mezzo:
            self.aggiorna(col.MEZZI, str(id_mezzo), {"stato_operativo": "disponibile"})
        return {**corsa, **modifiche}

    def registra_pagamento(self, dati: dict[str, Any]) -> str:
        """! @brief Registra un Pagamento applicando il vincolo XOR su corsa/abbonamento.

        Per le causali "corsa"/"abbonamento" esattamente uno tra id_corsa e id_abbonamento
        deve essere valorizzato (non entrambi, non nessuno).

        @param dati Documento pagamento (tipo, importo_cent, id_utente, id_metodo, id_corsa?/…).
        @return Id del pagamento creato.
        @throws ViolazioneXor Se il vincolo XOR e' violato per le causali corsa/abbonamento.
        """
        if dati.get("tipo") in ("corsa", "abbonamento"):
            ha_corsa = bool(dati.get("id_corsa"))
            ha_abb = bool(dati.get("id_abbonamento"))
            if ha_corsa == ha_abb:
                raise ViolazioneXor(
                    "Pagamento corsa/abbonamento: valorizzare esattamente uno tra "
                    "id_corsa e id_abbonamento"
                )
        documento = {**dati, "data_ora": dati.get("data_ora", _adesso())}
        return self.crea(col.PAGAMENTI, documento)


# ── Iniezione/selezione del DAO per il Business Tier (senza toccare la Presentation) ──
#! DAO iniettato esplicitamente (test): ha la precedenza assoluta.
_dao_iniettato: DataAccessManager | None = None
#! DAO reale costruito pigramente dall'ambiente (.env), memorizzato per riuso.
_dao_reale: DataAccessManager | None = None


def imposta_dao(dao: DataAccessManager | None) -> None:
    """! @brief Inietta un DataAccessManager (usato dai test per fornire il client fake).
    @param dao Istanza da usare, o None per non iniettare nulla.
    @return Nessuno.
    """
    global _dao_iniettato
    _dao_iniettato = dao


def azzera_dao() -> None:
    """! @brief Azzera il DAO iniettato e la cache reale (ripristino tra i test).
    @return Nessuno.
    """
    global _dao_iniettato, _dao_reale
    _dao_iniettato = None
    _dao_reale = None


def ottieni_dao_opzionale() -> DataAccessManager | None:
    """! @brief Restituisce il DAO disponibile, costruendolo dall'ambiente se configurato.

    Precedenza: DAO iniettato (test) → DAO reale gia' costruito → costruzione dal client
    Firestore reale/emulatore (se @c LEAF_FIREBASE_CRED o @c FIRESTORE_EMULATOR_HOST sono
    valorizzati e firebase-admin e' installato). Restituisce None se la persistenza non e'
    configurata: in tal caso lo slice resta sull'inviluppo "in sviluppo" (§9).

    @return DataAccessManager pronto, oppure None se la persistenza non e' configurata.
    """
    if _dao_iniettato is not None:
        return _dao_iniettato
    global _dao_reale
    if _dao_reale is None:
        cliente = inizializza_firestore()
        if cliente is not None:
            _dao_reale = DataAccessManager(cliente, cifrario_da_ambiente())
    return _dao_reale
