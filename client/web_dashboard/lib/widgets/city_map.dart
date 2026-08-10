import 'package:flutter/material.dart';
import 'package:web_dashboard/data/fleet_data.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/theme.dart';

/// @brief Mappa schematica interattiva della citta' (Bari).
///
/// Resa con [CustomPaint] (terra/mare/quartieri + eventuale heatmap) e marker
/// posizionati come widget sovrapposti: non richiede chiavi API esterne e si
/// visualizza in qualunque browser. Le coordinate dei mezzi, delle ricariche e
/// delle fermate TPL coincidono con quelle di [AppMobileUtente].
/// OP.01 (flotta live), AP.05/AP.10 (heatmap/concentrazione), UT.14 (ricariche).
class CityMap extends StatelessWidget {
  /// Tipologia di mezzo da mostrare; null = tutte.
  final VehicleType? typeFilter;

  /// Stati operativi da mostrare; null = tutti.
  final Set<VehicleStatus>? statusFilter;

  final bool showVehicles;
  final bool showCharging;
  final bool showTpl;

  /// Mostra l'overlay heatmap di utilizzo/concentrazione (vista AP).
  final bool showHeatmap;

  /// Mostra la legenda in basso a sinistra.
  final bool showLegend;

  const CityMap({
    super.key,
    this.typeFilter,
    this.statusFilter,
    this.showVehicles = true,
    this.showCharging = true,
    this.showTpl = true,
    this.showHeatmap = false,
    this.showLegend = true,
  });

  bool _vehiclePasses(Vehicle v) {
    if (typeFilter != null && v.type != typeFilter) return false;
    if (statusFilter != null && !statusFilter!.contains(v.status)) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final vehicles = showVehicles
                ? FleetData.vehicles.where(_vehiclePasses).toList()
                : const <Vehicle>[];

            return Stack(
              children: [
                // Sfondo cartografico + heatmap.
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CityPainter(
                      heatmap: showHeatmap,
                      heatPoints: showHeatmap
                          ? FleetData.vehicles
                              .map((v) => MapBounds.project(v.lat, v.lng))
                              .toList()
                          : const [],
                    ),
                  ),
                ),
                // Fermate TPL (sistemaTPL integrato nella mappa).
                if (showTpl)
                  for (final s in FleetData.tplStops)
                    _marker(
                      w,
                      h,
                      s.lat,
                      s.lng,
                      tooltip: '${s.name}\n${tr('Trasporto Pubblico (TPL)')}',
                      color: const Color(0xFF0288D1),
                      icon: Icons.directions_bus,
                      size: 22,
                    ),
                // Stazioni di ricarica.
                if (showCharging)
                  for (final c in FleetData.charging)
                    _marker(
                      w,
                      h,
                      c.lat,
                      c.lng,
                      tooltip:
                          '${tr('Ricarica')} – ${c.area}\n${c.slots} ${tr('posti')}',
                      color: AppTheme.statusLowBattery,
                      icon: Icons.bolt,
                      size: 22,
                    ),
                // Veicoli.
                if (showVehicles)
                  for (final v in vehicles)
                    _marker(
                      w,
                      h,
                      v.lat,
                      v.lng,
                      tooltip:
                          '${v.id} · ${tr(vehicleTypeLabel(v.type))}\n'
                          '${tr('Batteria')}: ${v.battery}%\n'
                          '${tr('Stato')}: ${tr(vehicleStatusLabel(v.status))}',
                      color: vehicleStatusColor(v.status),
                      icon: vehicleTypeIcon(v.type),
                      size: 24,
                    ),
                if (showLegend)
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: _legend(),
                  ),
                if (showVehicles)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: _counter(vehicles.length),
                  ),
              ],
            );
          },
        ),
      );
    });
  }

  Widget _marker(
    double w,
    double h,
    double lat,
    double lng, {
    required String tooltip,
    required Color color,
    required IconData icon,
    required double size,
  }) {
    final p = MapBounds.project(lat, lng);
    return Positioned(
      left: p.dx * w - size / 2,
      top: p.dy * h - size / 2,
      child: Tooltip(
        message: tooltip,
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
        decoration: BoxDecoration(
          color: AppTheme.textDark.withAlpha(235),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(icon, size: size * 0.55, color: color),
        ),
      ),
    );
  }

  Widget _counter(int n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(235),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 6),
        ],
      ),
      child: Text(
        '$n ${tr('mezzi visualizzati')}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textDark,
        ),
      ),
    );
  }

  Widget _legend() {
    Widget row(Color c, String label) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: c, width: 2.5),
                ),
              ),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 11)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(235),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tr('Legenda'),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textGrey,
            ),
          ),
          const SizedBox(height: 4),
          row(AppTheme.statusAvailable, tr('Disponibile')),
          row(AppTheme.statusInUse, tr('In uso')),
          row(AppTheme.statusMaintenance, tr('In manutenzione')),
          row(AppTheme.statusLowBattery, tr('Ricarica')),
          row(const Color(0xFF0288D1), tr('Trasporto Pubblico (TPL)')),
        ],
      ),
    );
  }
}

/// @brief Painter dello sfondo cartografico schematico + heatmap.
class _CityPainter extends CustomPainter {
  final bool heatmap;
  final List<Offset> heatPoints;

  _CityPainter({required this.heatmap, required this.heatPoints});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Terra.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppTheme.mapLand,
    );

    // Mare nell'angolo nord-est (la costa di Bari corre verso NE).
    final sea = Path()
      ..moveTo(w * 0.62, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.46)
      ..quadraticBezierTo(w * 0.82, h * 0.20, w * 0.62, 0)
      ..close();
    canvas.drawPath(sea, Paint()..color = AppTheme.mapSea);

    // Quartieri (blocchi tenui per dare profondita').
    final district = Paint()..color = AppTheme.mapDistrict;
    final blocks = <Rect>[
      Rect.fromLTWH(w * 0.10, h * 0.30, w * 0.22, h * 0.26),
      Rect.fromLTWH(w * 0.36, h * 0.50, w * 0.24, h * 0.30),
      Rect.fromLTWH(w * 0.55, h * 0.55, w * 0.20, h * 0.24),
      Rect.fromLTWH(w * 0.30, h * 0.18, w * 0.18, h * 0.18),
    ];
    for (final b in blocks) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(b, const Radius.circular(10)),
        district,
      );
    }

    // Assi viari principali (linee bianche).
    final road = Paint()
      ..color = AppTheme.mapRoad
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, h * 0.62), Offset(w * 0.78, h * 0.30), road);
    canvas.drawLine(Offset(w * 0.20, h), Offset(w * 0.52, 0), road);
    canvas.drawLine(Offset(0, h * 0.42), Offset(w, h * 0.78), road);

    // Heatmap: aloni radiali tradotti dalla concentrazione dei mezzi. AP.05.
    if (heatmap) {
      for (final p in heatPoints) {
        final center = Offset(p.dx * w, p.dy * h);
        const radius = 46.0;
        final paint = Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFE53935).withAlpha(90),
              const Color(0xFFFB8C00).withAlpha(40),
              const Color(0x00FB8C00),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: radius));
        canvas.drawCircle(center, radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CityPainter old) =>
      old.heatmap != heatmap || old.heatPoints != heatPoints;
}
