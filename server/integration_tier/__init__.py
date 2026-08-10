"""! @package server.integration_tier
@brief Integration Tier — accesso dati e sistemi esterni black-box (§4.1 / §13).

Gateway: pagamenti, accesso dati, IoT, routing (con sistemaTPL INTEGRATO).
E' l'unico tier che parla con i sistemi esterni; non viene importato
direttamente dalla Presentation (no leaky abstractions, §4.1).
"""
