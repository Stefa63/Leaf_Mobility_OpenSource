"""! @package server.business_tier
@brief Business Tier — logica di dominio isolata dai framework (§4.1).

Gestori: corse, profili/eKYC, geofencing, motore analitica, assistenza/ticket,
flotta. Rimane indipendente da dettagli di piattaforma; dialoga con
l'Integration Tier solo tramite interfacce.
"""
