"""! @file client_controllo.py
@brief Client HTTP standard (loopback) verso l'endpoint di controllo del runtime.
"""

from __future__ import annotations

from typing import cast

import httpx

from server.runtime.controllo_router import PREFISSO


class ErroreControllo(RuntimeError):  # noqa: N818 — nomenclatura italiana di progetto (§3)
    """! @brief Errore di comunicazione o applicativo verso l'endpoint di controllo."""


class ClientControllo:
    """! @brief Client sincrono verso gli endpoint di controllo loopback.

    Usa httpx (strumento standard, HTTP/JSON) per dialogare col runtime. Essendo
    un semplice client, piu' console possono interrogare lo stesso server in
    concorrenza.

    @param base_url URL base del runtime (es. http://127.0.0.1:8770).
    @param admin_token Token admin opzionale per le interrogazioni riservate.
    @param timeout Timeout delle richieste in secondi.
    """

    def __init__(self, base_url: str, admin_token: str = "", timeout: float = 5.0) -> None:
        """! @brief Inizializza il client.
        @param base_url URL base del runtime.
        @param admin_token Token admin opzionale (header X-Admin-Token).
        @param timeout Timeout richieste in secondi.
        """
        self._base = base_url.rstrip("/") + PREFISSO
        self._headers = {"X-Admin-Token": admin_token} if admin_token else {}
        self._timeout = timeout

    def _get(self, percorso: str, **params: str | int | float | bool | None) -> dict[str, object]:
        """! @brief Esegue una GET sull'endpoint di controllo.
        @param percorso Sotto-percorso (es. "/metriche").
        @param params Parametri di query opzionali.
        @return Corpo JSON della risposta.
        @throws ErroreControllo In caso di errore di rete o status non 2xx.
        """
        return self._invia("GET", percorso, params=params)

    def _post(self, percorso: str, corpo: dict[str, object] | None = None) -> dict[str, object]:
        """! @brief Esegue una POST sull'endpoint di controllo.
        @param percorso Sotto-percorso (es. "/op").
        @param corpo Corpo JSON della richiesta.
        @return Corpo JSON della risposta.
        @throws ErroreControllo In caso di errore di rete o status non 2xx.
        """
        return self._invia("POST", percorso, corpo=corpo)

    def _invia(
        self,
        metodo: str,
        percorso: str,
        params: dict[str, str | int | float | bool | None] | None = None,
        corpo: dict[str, object] | None = None,
    ) -> dict[str, object]:
        """! @brief Inoltra una richiesta HTTP e normalizza gli errori.
        @param metodo Metodo HTTP.
        @param percorso Sotto-percorso dell'endpoint.
        @param params Parametri di query opzionali (GET).
        @param corpo Corpo JSON opzionale (POST).
        @return Corpo JSON della risposta.
        @throws ErroreControllo Su errori di trasporto o status >= 400.
        """
        try:
            resp = httpx.request(
                metodo,
                self._base + percorso,
                headers=self._headers,
                timeout=self._timeout,
                params=params,
                json=corpo,
            )
        except httpx.HTTPError as exc:
            raise ErroreControllo(f"server non raggiungibile: {exc}") from exc
        if resp.status_code >= 400:
            dettaglio = resp.json().get("detail", resp.text) if resp.content else resp.text
            raise ErroreControllo(str(dettaglio))
        return cast("dict[str, object]", resp.json())

    def raggiungibile(self) -> bool:
        """! @brief Verifica se il runtime risponde all'health check.
        @return True se l'endpoint /salute risponde correttamente.
        """
        try:
            return self._get("/salute").get("stato") == "ok"
        except ErroreControllo:
            return False

    def metriche(self) -> dict[str, object]:
        """! @brief Recupera le metriche di carico.
        @return Snapshot delle metriche.
        """
        return self._get("/metriche")

    def hardware(self) -> dict[str, object]:
        """! @brief Recupera lo sforzo hardware corrente.
        @return Snapshot hardware con soglie.
        """
        return self._get("/hardware")

    def elenco_op(self) -> list[dict[str, object]]:
        """! @brief Elenca gli account OP provvisori.
        @return Lista degli OP.
        """
        return cast("list[dict[str, object]]", self._get("/op").get("op", []))

    def crea_op(self, username: str) -> dict[str, object]:
        """! @brief Crea un OP con password temporanea.
        @param username Username da creare.
        @return Esito con username e password temporanea.
        """
        return self._post(
            "/op",
            {
                "username": username,
                "nome": f"Operatore {username}",
                "email": f"{username}@leaf.local",
            },
        )

    def query(self, sql: str) -> dict[str, object]:
        """! @brief Esegue un'interrogazione amministrativa (solo admin).
        @param sql Istruzione SQL.
        @return Esito dell'interrogazione.
        """
        return self._post("/query", {"sql": sql})

    def backup_manuale(self) -> dict[str, object]:
        """! @brief Avvia un backup manuale.
        @return Metadati dell'archivio creato.
        """
        return self._post("/backup", None)

    def elenco_backup(self) -> dict[str, object]:
        """! @brief Elenca gli archivi di backup.
        @return Archivi e stato del backup automatico.
        """
        return self._get("/backup")

    def backup_auto(self, attivo: bool) -> dict[str, object]:
        """! @brief Attiva/disattiva il backup automatico.
        @param attivo Stato desiderato.
        @return Stato aggiornato del backup automatico.
        """
        return self._post("/backup/auto", {"attivo": attivo})

    def backup_restore(self, nome: str) -> dict[str, object]:
        """! @brief Ripristina i dati da un archivio.
        @param nome Nome dell'archivio.
        @return Metadati del ripristino.
        """
        return self._post("/backup/restore", {"nome": nome})

    def audit(self, n: int = 20) -> list[dict[str, object]]:
        """! @brief Recupera le ultime voci di audit.
        @param n Numero di voci.
        @return Lista delle voci di audit.
        """
        return cast("list[dict[str, object]]", self._get("/audit", n=n).get("voci", []))

    def config(self) -> dict[str, object]:
        """! @brief Recupera le impostazioni personalizzabili correnti.
        @return Mappa delle impostazioni configurabili a caldo.
        """
        return self._get("/config")

    def aggiorna_config(self, modifiche: dict[str, object]) -> dict[str, object]:
        """! @brief Aggiorna a caldo una o piu' impostazioni personalizzabili.
        @param modifiche Mappa parziale chiave -> nuovo valore.
        @return Configurazione aggiornata.
        """
        return self._post("/config", modifiche)
