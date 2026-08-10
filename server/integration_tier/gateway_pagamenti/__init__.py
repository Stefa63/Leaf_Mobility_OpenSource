"""! @package server.integration_tier.gateway_pagamenti
@brief Adattatore verso il Sistema Bancario esterno (es. Stripe) — §13.
"""

from __future__ import annotations

from datetime import UTC, datetime


class GatewayPagamenti:
    """! @brief Interfaccia il sistema di pagamento esterno (UT.04/UT.11).

    Responsabilita': validazione carta, autorizzazione e addebito a fine
    noleggio. Il provider e' un black-box (§13): si dialoga solo via SDK/API standard.

    @note **Simulazione locale deterministica** (§3): senza credenziali del provider,
          l'autorizzazione è sempre concessa per un importo positivo e l'id transazione
          è derivato in modo deterministico dal riferimento (idempotenza per corsa);
          nessuna chiamata di rete. In produzione qui si chiamerebbe l'API del PSP.
    """

    def addebita(self, id_utente: str, importo_cent: int, riferimento: str) -> str:
        """! @brief Addebita un importo all'utente a fine noleggio (UT.04).
        @param id_utente Identificativo dell'utente con metodo di pagamento verificato.
        @param importo_cent Importo in centesimi da addebitare (> 0).
        @param riferimento Riferimento idempotente dell'addebito (es. id_corsa).
        @return Identificativo deterministico della transazione simulata.
        @throws ValueError Se l'importo non e' positivo (autorizzazione negata).
        """
        if importo_cent <= 0:
            raise ValueError("Importo da addebitare non valido (deve essere > 0)")
        return f"SIMPAY-{riferimento}"

    @staticmethod
    def _luhn_valido(cifre: str) -> bool:
        """! @brief Verifica il checksum di Luhn di un numero di carta (PAN).
        @param cifre Numero della carta come sole cifre.
        @return True se il checksum di Luhn e' valido.
        """
        somma = 0
        pari = False
        for car in reversed(cifre):
            valore = ord(car) - ord("0")
            if pari:
                valore *= 2
                if valore > 9:
                    valore -= 9
            somma += valore
            pari = not pari
        return somma % 10 == 0

    def valida_carta(self, numero: str, mese: int, anno: int) -> None:
        """! @brief Valida la carta lato server: lunghezza, checksum Luhn e scadenza (UT.11).

        Controllo deterministico locale (§3, nessuna chiamata al PSP): blocca PAN non
        plausibili (Luhn) e carte gia' scadute, prima della tokenizzazione del metodo.

        @param numero Numero della carta (le cifre vengono estratte).
        @param mese Mese di scadenza (1-12).
        @param anno Anno di scadenza (4 cifre).
        @throws ValueError Se numero, mese o scadenza non sono validi.
        """
        cifre = "".join(c for c in numero if c.isdigit())
        if not 12 <= len(cifre) <= 19 or not self._luhn_valido(cifre):
            raise ValueError("Numero carta non valido")
        if not 1 <= mese <= 12:
            raise ValueError("Mese di scadenza non valido")
        oggi = datetime.now(UTC)
        if (anno, mese) < (oggi.year, oggi.month):
            raise ValueError("Carta scaduta")
