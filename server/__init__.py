"""! @package server
@brief Pacchetto radice del server LEAF Mobility.

Architettura a tre tier (§4.1 / §5 di wiki/DIRECTIVES.md):
  - @ref server.presentation_tier  "Presentation Tier"  — API gateway, attivita'.
  - @ref server.business_tier       "Business Tier"      — logica di dominio.
  - @ref server.integration_tier    "Integration Tier"   — accesso dati e sistemi esterni.

Layer operativi AGGIUNTI (tooling, NON un quarto tier):
  - @ref server.runtime            — bootstrap FastAPI, strumentazione, metriche, backup.
  - @ref server.console_operativa  — TUI di gestione stile Claude Code.

Stato: i tier di dominio sono scheletri (classi + Doxygen) non ancora cablati al
database (in sviluppo). Il runtime e la console sono invece funzionanti.
"""
