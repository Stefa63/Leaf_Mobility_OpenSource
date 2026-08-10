"""! @file registro_metriche.py
@brief Registro thread-safe delle metriche di carico del runtime.
"""

from __future__ import annotations

import threading
import time
from collections import deque


class RegistroMetriche:
    """! @brief Raccoglie in modo thread-safe le metriche di carico del server.

    Traccia byte in/uscita, numero di richieste totali e concorrenti, dati
    letti/scritti, errori e tempi di risposta (media e p95). E' condiviso tra
    tutte le richieste concorrenti e tra le console connesse (lettura via
    @ref snapshot).

    @param max_campioni Numero massimo di tempi di risposta conservati per il p95.
    """

    def __init__(self, max_campioni: int = 1024, finestra_dispositivi_s: float = 30.0) -> None:
        """! @brief Inizializza il registro a zero.
        @param max_campioni Dimensione della finestra scorrevole dei tempi di risposta.
        @param finestra_dispositivi_s Secondi entro cui un client e' considerato "collegato".
        """
        self._lock = threading.Lock()
        self._avvio_wall = time.time()
        self._avvio_mono = time.monotonic()
        self._byte_in = 0
        self._byte_out = 0
        self._dati_letti = 0
        self._dati_scritti = 0
        self._richieste_totali = 0
        self._richieste_errore = 0
        self._richieste_attive = 0
        self._picco_concorrenza = 0
        self._somma_tempi = 0.0
        self._tempi: deque[float] = deque(maxlen=max_campioni)
        #! Ultimo istante (monotonic) in cui ciascun dispositivo client si e' fatto vivo.
        self._dispositivi: dict[str, float] = {}
        self._finestra_dispositivi = finestra_dispositivi_s
        #! Picco di dispositivi collegati simultaneamente osservato.
        self._picco_dispositivi = 0

    def inizio_richiesta(self) -> None:
        """! @brief Registra l'avvio di una richiesta (aggiorna concorrenza e totale).
        @return Nessuno.
        """
        with self._lock:
            self._richieste_totali += 1
            self._richieste_attive += 1
            self._picco_concorrenza = max(self._picco_concorrenza, self._richieste_attive)

    def fine_richiesta(self, byte_in: int, byte_out: int, durata_s: float, errore: bool) -> None:
        """! @brief Registra il completamento di una richiesta.
        @param byte_in Byte ricevuti (corpo della richiesta).
        @param byte_out Byte inviati (corpo della risposta).
        @param durata_s Tempo di risposta in secondi.
        @param errore True se la risposta e' un errore (status >= 400).
        @return Nessuno.
        """
        with self._lock:
            self._richieste_attive = max(0, self._richieste_attive - 1)
            self._byte_in += byte_in
            self._byte_out += byte_out
            self._somma_tempi += durata_s
            self._tempi.append(durata_s)
            if errore:
                self._richieste_errore += 1

    def segna_dispositivo(self, identificativo: str) -> None:
        """! @brief Registra l'attivita' di un dispositivo client collegato.

        Aggiorna l'istante di ultimo contatto del dispositivo (tipicamente l'host
        del client) per il monitoraggio in tempo reale dei dispositivi collegati.

        @param identificativo Chiave del dispositivo (es. host del client).
        @return Nessuno.
        """
        if not identificativo:
            return
        with self._lock:
            self._dispositivi[identificativo] = time.monotonic()

    def _dispositivi_collegati(self, ora: float) -> int:
        """! @brief Conta i dispositivi attivi entro la finestra ed elimina gli scaduti.
        @param ora Istante monotonic corrente.
        @return Numero di dispositivi collegati di recente.
        @note Da invocare con il lock gia' acquisito.
        """
        scaduti = [k for k, t in self._dispositivi.items() if ora - t > self._finestra_dispositivi]
        for k in scaduti:
            del self._dispositivi[k]
        collegati = len(self._dispositivi)
        self._picco_dispositivi = max(self._picco_dispositivi, collegati)
        return collegati

    def registra_io(self, letti: int, scritti: int) -> None:
        """! @brief Contabilizza dati applicativi letti/scritti (es. backup, store OP).
        @param letti Byte letti da disco/store.
        @param scritti Byte scritti su disco/store.
        @return Nessuno.
        """
        with self._lock:
            self._dati_letti += letti
            self._dati_scritti += scritti

    def snapshot(self) -> dict[str, object]:
        """! @brief Fotografia coerente delle metriche correnti.
        @return Dizionario serializzabile con tutte le metriche di carico.
        """
        with self._lock:
            uptime = time.monotonic() - self._avvio_mono
            n = len(self._tempi)
            media = (self._somma_tempi / self._richieste_totali) if self._richieste_totali else 0.0
            p95 = 0.0
            if n:
                ordinati = sorted(self._tempi)
                idx = min(n - 1, int(round(0.95 * (n - 1))))
                p95 = ordinati[idx]
            req_s = self._richieste_totali / uptime if uptime > 0 else 0.0
            dispositivi = self._dispositivi_collegati(time.monotonic())
            return {
                "uptime_s": round(uptime, 1),
                "dispositivi_collegati": dispositivi,
                "picco_dispositivi": self._picco_dispositivi,
                "byte_in": self._byte_in,
                "byte_out": self._byte_out,
                "dati_letti": self._dati_letti,
                "dati_scritti": self._dati_scritti,
                "richieste_totali": self._richieste_totali,
                "richieste_attive": self._richieste_attive,
                "richieste_errore": self._richieste_errore,
                "picco_concorrenza": self._picco_concorrenza,
                "richieste_al_secondo": round(req_s, 2),
                "tempo_risposta_medio_ms": round(media * 1000, 2),
                "tempo_risposta_p95_ms": round(p95 * 1000, 2),
            }
