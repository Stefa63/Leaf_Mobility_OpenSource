"""! @file cliente_falso.py
@brief Client Firestore in-memory per i test offline (nessuna credenziale, nessun emulatore).

Replica la porzione dell'API di `firebase-admin` (`google-cloud-firestore`) usata dal
@ref DataAccessManager: `collection`/`document`/`get`/`set`/`update`/`delete`,
subcollezioni, query `where`/`order_by`/`limit`/`stream` e transazioni
(`transaction()` + `ref.get(transaction=...)` + `transaction.set/update/delete`).
Consente di eseguire i test del layer di persistenza **completamente offline**
(testabilità §12.2 / nessun progetto Google richiesto), con lo stesso codice del
percorso reale. NON è destinato alla produzione.

@note Il client espone l'attributo @c _e_falso = True per consentire al
      @ref DataAccessManager di scegliere il percorso transazionale corretto
      (lock locale per il fake, `firestore.transactional` per il client reale).
"""

from __future__ import annotations

import copy
import secrets
import threading
from collections.abc import Iterator
from typing import Any


class SnapshotFalso:
    """! @brief Istantanea di un documento (equivalente di DocumentSnapshot).
    @param id_doc Identificativo del documento.
    @param dati Contenuto del documento, o None se inesistente.
    """

    def __init__(self, id_doc: str, dati: dict[str, Any] | None) -> None:
        """! @brief Costruisce l'istantanea.
        @param id_doc Identificativo del documento.
        @param dati Contenuto (copia) o None se il documento non esiste.
        """
        self.id = id_doc
        self._dati = dati

    @property
    def exists(self) -> bool:
        """! @brief Indica se il documento esiste.
        @return True se il documento è presente.
        """
        return self._dati is not None

    def to_dict(self) -> dict[str, Any] | None:
        """! @brief Restituisce il contenuto del documento.
        @return Copia del contenuto, o None se inesistente.
        """
        return copy.deepcopy(self._dati) if self._dati is not None else None


class _Documento:
    """! @brief Nodo di archiviazione: dati del documento + subcollezioni."""

    def __init__(self) -> None:
        """! @brief Inizializza un nodo vuoto (nessun dato, nessuna subcollezione)."""
        self.dati: dict[str, Any] | None = None
        self.sub: dict[str, CollezioneFalsa] = {}


class CollezioneFalsa:
    """! @brief Collezione in-memory (equivalente di CollectionReference)."""

    def __init__(self) -> None:
        """! @brief Inizializza una collezione vuota."""
        self._documenti: dict[str, _Documento] = {}

    def document(self, id_doc: str | None = None) -> DocumentRefFalso:
        """! @brief Riferimento a un documento (creandone l'id se assente).
        @param id_doc Identificativo; se None viene generato un id casuale.
        @return Riferimento al documento.
        """
        if id_doc is None:
            id_doc = secrets.token_hex(10)
        return DocumentRefFalso(self, id_doc)

    def _nodo(self, id_doc: str, crea: bool = False) -> _Documento | None:
        """! @brief Recupera (o crea) il nodo di archiviazione di un documento.
        @param id_doc Identificativo del documento.
        @param crea Se True crea il nodo qualora assente.
        @return Nodo del documento o None.
        """
        nodo = self._documenti.get(id_doc)
        if nodo is None and crea:
            nodo = _Documento()
            self._documenti[id_doc] = nodo
        return nodo

    def where(  # noqa: ANN401, A002
        self,
        campo: str | None = None,
        operatore: str | None = None,
        valore: Any = None,
        *,
        filter: Any = None,
    ) -> QueryFalsa:
        """! @brief Inizia una query filtrando per campo (API `filter=FieldFilter`).
        @param campo Nome del campo (forma posizionale legacy).
        @param operatore Operatore di confronto (==, >=, <=, >, <, in, array_contains).
        @param valore Valore di confronto.
        @param filter Filtro `FieldFilter` (API non deprecata di firebase-admin).
        @return Query filtrata.
        """
        return QueryFalsa(self).where(campo, operatore, valore, filter=filter)

    def order_by(self, campo: str, direction: str = "ASCENDING") -> QueryFalsa:
        """! @brief Inizia una query ordinando per campo.
        @param campo Campo di ordinamento.
        @param direction "ASCENDING" o "DESCENDING".
        @return Query ordinata.
        """
        return QueryFalsa(self).order_by(campo, direction)

    def limit(self, numero: int) -> QueryFalsa:
        """! @brief Inizia una query limitando il numero di risultati.
        @param numero Numero massimo di documenti.
        @return Query limitata.
        """
        return QueryFalsa(self).limit(numero)

    def stream(self) -> Iterator[SnapshotFalso]:
        """! @brief Itera su tutti i documenti della collezione.
        @return Iteratore di istantanee dei documenti esistenti.
        """
        return QueryFalsa(self).stream()


class DocumentRefFalso:
    """! @brief Riferimento a un documento (equivalente di DocumentReference)."""

    def __init__(self, collezione: CollezioneFalsa, id_doc: str) -> None:
        """! @brief Costruisce il riferimento.
        @param collezione Collezione contenitore.
        @param id_doc Identificativo del documento.
        """
        self._collezione = collezione
        self.id = id_doc

    def get(self, transaction: Any = None) -> SnapshotFalso:  # noqa: ANN401, ARG002
        """! @brief Legge l'istantanea del documento.
        @param transaction Ignorato dal fake (compatibilità con il percorso reale).
        @return Istantanea del documento.
        """
        nodo = self._collezione._nodo(self.id)
        dati = copy.deepcopy(nodo.dati) if nodo is not None else None
        return SnapshotFalso(self.id, dati)

    def set(self, dati: dict[str, Any], merge: bool = False) -> None:
        """! @brief Scrive (o fonde) il contenuto del documento.
        @param dati Contenuto da scrivere.
        @param merge Se True fonde con il contenuto esistente, altrimenti lo sostituisce.
        @return Nessuno.
        """
        nodo = self._collezione._nodo(self.id, crea=True)
        assert nodo is not None
        if merge and nodo.dati is not None:
            nodo.dati.update(copy.deepcopy(dati))
        else:
            nodo.dati = copy.deepcopy(dati)

    def update(self, dati: dict[str, Any]) -> None:
        """! @brief Aggiorna campi del documento (chiavi puntate = percorsi annidati).
        @param dati Mappa campo→valore; le chiavi con punto indicano percorsi annidati.
        @return Nessuno.
        @throws KeyError Se il documento non esiste.
        """
        nodo = self._collezione._nodo(self.id)
        if nodo is None or nodo.dati is None:
            raise KeyError(f"Documento '{self.id}' inesistente: update non possibile")
        for chiave, valore in dati.items():
            corrente = nodo.dati
            parti = chiave.split(".")
            for parte in parti[:-1]:
                prossimo = corrente.get(parte)
                if not isinstance(prossimo, dict):
                    prossimo = {}
                    corrente[parte] = prossimo
                corrente = prossimo
            corrente[parti[-1]] = copy.deepcopy(valore)

    def delete(self) -> None:
        """! @brief Elimina il documento (e le sue subcollezioni).
        @return Nessuno.
        """
        self._collezione._documenti.pop(self.id, None)

    def collection(self, nome: str) -> CollezioneFalsa:
        """! @brief Riferimento a una subcollezione del documento.
        @param nome Nome della subcollezione.
        @return Subcollezione (creata al volo se assente).
        """
        nodo = self._collezione._nodo(self.id, crea=True)
        assert nodo is not None
        if nome not in nodo.sub:
            nodo.sub[nome] = CollezioneFalsa()
        return nodo.sub[nome]


def _valore_campo(dati: dict[str, Any], campo: str) -> Any:  # noqa: ANN401
    """! @brief Legge un valore da un documento risolvendo la notazione puntata.
    @param dati Contenuto del documento.
    @param campo Nome del campo (eventualmente annidato con punti).
    @return Valore del campo o None se assente.
    """
    corrente: Any = dati
    for parte in campo.split("."):
        if not isinstance(corrente, dict):
            return None
        corrente = corrente.get(parte)
    return corrente


def _confronta(valore: Any, operatore: str, atteso: Any) -> bool:  # noqa: ANN401
    """! @brief Applica un operatore di confronto Firestore tra due valori.
    @param valore Valore del documento.
    @param operatore Operatore (==, !=, >=, <=, >, <, in, array_contains).
    @param atteso Valore di confronto della query.
    @return Esito del confronto.
    """
    if valore is None:
        return False
    if operatore == "==":
        return bool(valore == atteso)
    if operatore == "!=":
        return bool(valore != atteso)
    if operatore == ">=":
        return bool(valore >= atteso)
    if operatore == "<=":
        return bool(valore <= atteso)
    if operatore == ">":
        return bool(valore > atteso)
    if operatore == "<":
        return bool(valore < atteso)
    if operatore == "in":
        return valore in atteso
    if operatore == "array_contains":
        return isinstance(valore, list) and atteso in valore
    raise ValueError(f"Operatore di query non supportato: {operatore}")


class QueryFalsa:
    """! @brief Query componibile su una collezione (where/order_by/limit/stream)."""

    def __init__(self, collezione: CollezioneFalsa) -> None:
        """! @brief Costruisce una query vuota sulla collezione.
        @param collezione Collezione interrogata.
        """
        self._collezione = collezione
        self._filtri: list[tuple[str, str, Any]] = []
        self._ordina: tuple[str, bool] | None = None
        self._limite: int | None = None

    def where(  # noqa: ANN401, A002
        self,
        campo: str | None = None,
        operatore: str | None = None,
        valore: Any = None,
        *,
        filter: Any = None,
    ) -> QueryFalsa:
        """! @brief Aggiunge un filtro alla query (API `filter=FieldFilter` o posizionale).
        @param campo Campo filtrato (forma posizionale legacy).
        @param operatore Operatore di confronto.
        @param valore Valore di confronto.
        @param filter Filtro `FieldFilter`: se presente, ne estrae campo/operatore/valore.
        @return La query stessa (componibile).
        """
        if filter is not None:
            campo, operatore, valore = filter.field_path, filter.op_string, filter.value
        assert campo is not None and operatore is not None  # noqa: S101
        self._filtri.append((campo, operatore, valore))
        return self

    def order_by(self, campo: str, direction: str = "ASCENDING") -> QueryFalsa:
        """! @brief Imposta l'ordinamento della query.
        @param campo Campo di ordinamento.
        @param direction "ASCENDING" o "DESCENDING".
        @return La query stessa (componibile).
        """
        self._ordina = (campo, direction.upper() == "DESCENDING")
        return self

    def limit(self, numero: int) -> QueryFalsa:
        """! @brief Limita il numero di risultati.
        @param numero Numero massimo di documenti restituiti.
        @return La query stessa (componibile).
        """
        self._limite = numero
        return self

    def stream(self) -> Iterator[SnapshotFalso]:
        """! @brief Esegue la query e itera i risultati.
        @return Iteratore di istantanee filtrate, ordinate e limitate.
        """
        coppie = [
            (id_doc, nodo.dati)
            for id_doc, nodo in self._collezione._documenti.items()
            if nodo.dati is not None
        ]
        for campo, operatore, atteso in self._filtri:
            coppie = [
                (i, d)
                for (i, d) in coppie
                if _confronta(_valore_campo(d, campo), operatore, atteso)
            ]
        if self._ordina is not None:
            campo, discendente = self._ordina
            coppie.sort(key=lambda c: _ordinabile(_valore_campo(c[1], campo)), reverse=discendente)
        if self._limite is not None:
            coppie = coppie[: self._limite]
        for id_doc, dati in coppie:
            yield SnapshotFalso(id_doc, copy.deepcopy(dati))


def _ordinabile(valore: Any) -> tuple[int, Any]:  # noqa: ANN401
    """! @brief Chiave di ordinamento robusta ai valori None (None ordina per primo).
    @param valore Valore del campo di ordinamento.
    @return Tupla (priorità, valore) confrontabile.
    """
    return (1, valore) if valore is not None else (0, "")


class TransazioneFalsa:
    """! @brief Transazione in-memory (equivalente minimale di Transaction).

    Le scritture sono applicate immediatamente; la serializzazione tra transazioni
    concorrenti è garantita dal lock del @ref ClienteFalsoFirestore acquisito dal
    @ref DataAccessManager attorno all'intera operazione transazionale.
    """

    def set(self, ref: DocumentRefFalso, dati: dict[str, Any], merge: bool = False) -> None:
        """! @brief Scrive un documento nel contesto della transazione.
        @param ref Riferimento al documento.
        @param dati Contenuto da scrivere.
        @param merge Se True fonde con l'esistente.
        @return Nessuno.
        """
        ref.set(dati, merge=merge)

    def update(self, ref: DocumentRefFalso, dati: dict[str, Any]) -> None:
        """! @brief Aggiorna un documento nel contesto della transazione.
        @param ref Riferimento al documento.
        @param dati Campi da aggiornare.
        @return Nessuno.
        """
        ref.update(dati)

    def delete(self, ref: DocumentRefFalso) -> None:
        """! @brief Elimina un documento nel contesto della transazione.
        @param ref Riferimento al documento.
        @return Nessuno.
        """
        ref.delete()


class ClienteFalsoFirestore:
    """! @brief Client Firestore in-memory per i test (equivalente di firestore.Client).

    @note Espone @c _e_falso = True e @c _lock per il percorso transazionale del
          @ref DataAccessManager.
    """

    #! Marca il client come fake (selezione del percorso transazionale).
    _e_falso: bool = True

    def __init__(self) -> None:
        """! @brief Inizializza un archivio vuoto e il lock delle transazioni."""
        self._collezioni: dict[str, CollezioneFalsa] = {}
        self._lock = threading.RLock()

    def collection(self, nome: str) -> CollezioneFalsa:
        """! @brief Riferimento a una collezione top-level.
        @param nome Nome della collezione.
        @return Collezione (creata al volo se assente).
        """
        if nome not in self._collezioni:
            self._collezioni[nome] = CollezioneFalsa()
        return self._collezioni[nome]

    def transaction(self) -> TransazioneFalsa:
        """! @brief Crea una nuova transazione fittizia.
        @return Istanza di @ref TransazioneFalsa.
        """
        return TransazioneFalsa()
