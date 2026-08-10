"""! @package server.integration_tier.gateway_iot
@brief Adattatore verso i mezzi fisici IoT: comandi + telemetria (§13).
"""

from __future__ import annotations


class GatewayIot:
    """! @brief Interfaccia bidirezionale coi veicoli fisici (UT.10, OP.07/11).

    Responsabilita': invio comandi di sblocco/blocco motore, ricezione di
    telemetria e tracciato GPS in tempo reale. L'hardware e' un black-box (§13).

    @note **Simulazione locale deterministica** (§3): non essendo collegato hardware
          reale, i comandi sono simulati in modo deterministico (esito sempre positivo
          per un id mezzo valido); nessuna chiamata di rete. In produzione qui si
          dialogherebbe col provider IoT (MQTT/HTTP). La firma resta invariata per il
          cablaggio reale.
    """

    def invia_comando_sblocco(self, id_mezzo: str) -> bool:
        """! @brief Invia il comando di sblocco a un mezzo (UT.10).
        @param id_mezzo Identificativo del mezzo da sbloccare.
        @return True (lo sblocco è sempre confermato nella simulazione locale).
        """
        return bool(id_mezzo)

    def invia_comando_blocco(self, id_mezzo: str) -> bool:
        """! @brief Invia il comando di blocco a un mezzo a fine corsa (UT.04).
        @param id_mezzo Identificativo del mezzo da bloccare.
        @return True (il blocco è sempre confermato nella simulazione locale).
        """
        return bool(id_mezzo)

    def invia_comando_blocco_motore(self, id_mezzo: str) -> bool:
        """! @brief Invia il blocco motore remoto anti-spostamento a un mezzo (OP.11).

        Distinto dal blocco di fine corsa (@ref invia_comando_blocco): immobilizza un
        mezzo privo di noleggi attivi rilevato in un'area non autorizzata. Simulazione
        locale deterministica (§13): in produzione qui andrebbe il comando IoT reale.

        @param id_mezzo Identificativo del mezzo da immobilizzare.
        @return True (il blocco motore è sempre confermato nella simulazione locale).
        """
        return bool(id_mezzo)

    def invia_comando_sblocco_motore(self, id_mezzo: str) -> bool:
        """! @brief Revoca il blocco motore remoto e riabilita il mezzo (OP.11).

        Operazione inversa di @ref invia_comando_blocco_motore: ripristina la
        movimentazione di un mezzo precedentemente immobilizzato. Simulazione locale
        deterministica (§13): in produzione qui andrebbe il comando IoT reale.

        @param id_mezzo Identificativo del mezzo da riabilitare.
        @return True (lo sblocco è sempre confermato nella simulazione locale).
        """
        return bool(id_mezzo)
