import 'package:flutter/material.dart';
import 'package:app_mobile_utente/theme.dart';
import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/screens/main_layout.dart';
import 'package:app_mobile_utente/screens/vehicle_detail_screen.dart';

/// A single route option. UT.07 (route options with TPL integration).
class RouteData {
  final String name;
  final String description;
  final int durationMinutes;
  final double distanceKm;
  final String transportSummary; // e.g. "Scooter + TPL Bus"
  final List<VehicleData> recommended;
  final bool hasTpl;

  /// Tipo di mezzo consigliato per il percorso (UT.08). Permette di mostrare
  /// l'icona della modalità anche quando [recommended] è vuota (nessun mezzo
  /// reale disponibile nelle vicinanze / offline). Null per i percorsi mock.
  final VehicleType? recommendedType;

  const RouteData({
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.distanceKm,
    required this.transportSummary,
    required this.recommended,
    this.hasTpl = false,
    this.recommendedType,
  });
}

/// Route detail screen — UT.07, UT.08, UT.03.
/// Shows route summary, recommended vehicles and lets user view vehicle info.
class RouteDetailScreen extends StatelessWidget {
  final RouteData route;
  final String departure;
  final String arrival;

  const RouteDetailScreen({
    required this.route,
    required this.departure,
    required this.arrival,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(route.name)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Route header card ─────────────────────────────────────
            Card(
              elevation: 0,
              color: AppTheme.surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RoutePoint(
                      icon: Icons.trip_origin,
                      color: AppTheme.primaryGreen,
                      label: departure,
                    ),
                    const _RouteLine(),
                    _RoutePoint(
                      icon: Icons.location_on,
                      color: Colors.red,
                      label: arrival,
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatBadge(
                          icon: Icons.schedule_outlined,
                          value: '${route.durationMinutes} ${tr('min')}',
                          label: tr('Durata'),
                        ),
                        _StatBadge(
                          icon: Icons.straighten_outlined,
                          value: '${route.distanceKm.toStringAsFixed(1)} km',
                          label: tr('Distanza'),
                        ),
                        _StatBadge(
                          icon: Icons.euro_outlined,
                          // UT.03 cost estimate
                          value:
                              '~${(route.distanceKm * 0.8).toStringAsFixed(2)} €',
                          label: tr('Stima costo'),
                        ),
                      ],
                    ),
                    if (route.hasTpl) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withAlpha(60)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.directions_bus_outlined,
                              size: 14,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tr('Integrazione TPL disponibile'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Transport summary ─────────────────────────────────────
            _SectionLabel(tr('Modalità di trasporto')),
            const SizedBox(height: 8),
            Text(
              tr(route.transportSummary),
              style: const TextStyle(fontSize: 14, color: AppTheme.textDark),
            ),
            const SizedBox(height: 24),

            // ── Recommended vehicles — UT.08 ─────────────────────────
            _SectionLabel(tr('Mezzi consigliati vicino alla partenza')),
            const SizedBox(height: 12),
            if (route.recommended.isEmpty)
              Text(
                tr('Nessun mezzo disponibile nelle vicinanze.'),
                style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
              ),
            ...route.recommended.map(
              (v) => _RecommendedVehicleTile(vehicle: v),
            ),

            const SizedBox(height: 24),

            // ── View on map ───────────────────────────────────────────
            OutlinedButton.icon(
              onPressed: () {
                // #4: torna alla home E apre la tab Mappa (index 2), non solo pop.
                richiestaTabHome.value = 2;
                Navigator.popUntil(context, ModalRoute.withName('/home'));
              },
              icon: const Icon(Icons.map_outlined, color: AppTheme.accentBrown),
              label: Text(
                tr('Vedi su mappa'),
                style: const TextStyle(color: AppTheme.accentBrown),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.accentBrown),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AppTheme.textGrey,
      letterSpacing: 0.7,
    ),
  );
}

class _RoutePoint extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _RoutePoint({
    required this.icon,
    required this.color,
    required this.label,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    ],
  );
}

class _RouteLine extends StatelessWidget {
  const _RouteLine();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
    child: Container(width: 2, height: 16, color: Colors.black12),
  );
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatBadge({
    required this.icon,
    required this.value,
    required this.label,
  });
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, size: 18, color: AppTheme.accentBrown),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: AppTheme.textDark,
        ),
      ),
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppTheme.textGrey),
      ),
    ],
  );
}

class _RecommendedVehicleTile extends StatelessWidget {
  final VehicleData vehicle;
  const _RecommendedVehicleTile({required this.vehicle});
  @override
  Widget build(BuildContext context) {
    final color = vehicle.typeColor;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: color.withAlpha(14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(vehicle.typeIcon, color: color, size: 28),
        title: Text(
          '${tr(vehicle.typeLabel)}  ·  ${vehicle.id}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Text(
          '${vehicle.batteryPercent}% ${tr('batteria')}  ·  ~${vehicle.rangeKm} km ${tr('autonomia')}',
          style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
        ),
        trailing: IconButton(
          icon: Icon(Icons.info_outline, color: color, size: 20),
          tooltip: tr('Scheda mezzo'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VehicleDetailScreen(vehicle: vehicle),
            ),
          ),
        ),
      ),
    );
  }
}
