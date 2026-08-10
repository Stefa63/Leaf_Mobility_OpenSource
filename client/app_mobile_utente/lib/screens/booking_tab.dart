import 'package:flutter/material.dart';
import 'package:app_mobile_utente/theme.dart';
import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/screens/vehicle_detail_screen.dart';
import 'package:app_mobile_utente/screens/booking_screen.dart';
import 'package:app_mobile_utente/screens/my_bookings_screen.dart';

/// @brief Tab "Prenota": punto d'accesso alla prenotazione dei mezzi. UT.02.
///
/// Sostituisce il vecchio segnaposto "Servizio non disponibile": elenca i mezzi
/// disponibili nei dintorni e, al tap, apre la [BookingScreen] del veicolo
/// scelto. In testa offre una scorciatoia a "Mie Prenotazioni". Si ridisegna al
/// cambio lingua tramite [Translated]. IIN-7.
class BookingTab extends StatelessWidget {
  const BookingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Text(
            tr('Prenota un mezzo'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGreen,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tr('Seleziona un veicolo disponibile per riservarlo.'),
            style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
          ),
          const SizedBox(height: 16),

          // ── Shortcut: Mie Prenotazioni ─────────────────────────────────
          _BookingsShortcut(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            tr('Mezzi Disponibili Vicino a Te'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGreen,
            ),
          ),
          const SizedBox(height: 12),

          // ── Available vehicles ─────────────────────────────────────────
          ...kAvailableVehicles.map(
            (v) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BookableVehicleTile(
                vehicle: v,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BookingScreen(vehicle: v)),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

/// Scorciatoia in evidenza verso l'elenco delle prenotazioni attive.
class _BookingsShortcut extends StatelessWidget {
  final VoidCallback onTap;
  const _BookingsShortcut({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primaryGreen.withAlpha(20),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppTheme.primaryGreen,
                child: Icon(Icons.event_available, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  tr('Mie Prenotazioni'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textGrey),
            ],
          ),
        ),
      ),
    );
  }
}

/// Riga di un veicolo prenotabile: icona, tipo, batteria/autonomia e azione.
class _BookableVehicleTile extends StatelessWidget {
  final VehicleData vehicle;
  final VoidCallback onTap;
  const _BookableVehicleTile({required this.vehicle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = vehicle.typeColor;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black.withAlpha(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withAlpha(28),
                child: Icon(vehicle.typeIcon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tr(vehicle.typeLabel)} · ${vehicle.id}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${vehicle.batteryPercent}% ${tr('batteria')} · ~${vehicle.rangeKm} km ${tr('autonomia')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
