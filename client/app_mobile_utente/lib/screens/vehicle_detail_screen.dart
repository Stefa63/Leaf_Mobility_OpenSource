import 'package:flutter/material.dart';
import 'package:app_mobile_utente/active_trip_store.dart';
import 'package:app_mobile_utente/api/api_client.dart';
import 'package:app_mobile_utente/api/corse_repository.dart';
import 'package:app_mobile_utente/profile_store.dart';
import 'package:app_mobile_utente/theme.dart';
import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/screens/booking_screen.dart';

/// Vehicle type constants — shared across detail and search screens.
enum VehicleType { scooter, bike, car, emoto }

/// @brief Indica se il tipo di mezzo richiede la patente (auto/moto, punto 6, UT.22.2).
bool richiedePatente(VehicleType type) =>
    type == VehicleType.car || type == VehicleType.emoto;

/// @brief True se l'utente non ha la patente caricata ma il mezzo la richiede (punto 6).
bool patenteMancante(VehicleType type) =>
    richiedePatente(type) && (ProfileStore.licensePath.value ?? '').isEmpty;

/// @brief Mappa il discriminante `tipo_mezzo` del server sull'enum [VehicleType].
/// @param tipo Discriminante grezzo (ebike/ecar/emotorbike/monopattino).
/// @return Il [VehicleType] corrispondente (scooter come default).
VehicleType vehicleTypeDaApi(String tipo) {
  switch (tipo) {
    case 'ebike':
      return VehicleType.bike;
    case 'ecar':
      return VehicleType.car;
    case 'emotorbike':
      return VehicleType.emoto;
    default:
      return VehicleType.scooter;
  }
}

/// Mezzi disponibili nei dintorni (mock condiviso fino al `gestore_flotta`).
///
/// Esposto come elenco pubblico cosi' da poter essere riusato sia dalla home
/// che dalla tab "Prenota" senza duplicare i dati di mock. UT.01, UT.05.
const List<VehicleData> kAvailableVehicles = [
  VehicleData(
    id: 'SC-001',
    type: VehicleType.scooter,
    batteryPercent: 78,
    rangeKm: 42,
    distanceMeters: 120,
  ),
  VehicleData(
    id: 'BK-003',
    type: VehicleType.bike,
    batteryPercent: 91,
    rangeKm: 55,
    distanceMeters: 230,
  ),
  VehicleData(
    id: 'EM-002',
    type: VehicleType.emoto,
    batteryPercent: 85,
    rangeKm: 68,
    distanceMeters: 710,
  ),
  VehicleData(
    id: 'CA-007',
    type: VehicleType.car,
    batteryPercent: 65,
    rangeKm: 195,
    distanceMeters: 450,
  ),
];

/// Vehicle data model used by SearchScreen and VehicleDetailScreen.
class VehicleData {
  final String id;
  final VehicleType type;
  final int batteryPercent; // 0–100
  final int rangeKm; // estimated range in km
  final int distanceMeters; // distance from user/departure point
  final String status; // 'Disponibile' | 'In uso' | 'In manutenzione'

  /// Id del documento mezzo lato server (Firestore), per prenotazione/avvio
  /// corsa (UT.02/UT.10). Null per i dati di riserva mock (path locale offline).
  final String? docId;

  const VehicleData({
    required this.id,
    required this.type,
    required this.batteryPercent,
    required this.rangeKm,
    required this.distanceMeters,
    this.status = 'Disponibile',
    this.docId,
  });

  /// @brief Costruisce un [VehicleData] da un documento mezzo della API (UT.01/UT.05).
  /// @param doc Documento `mezzi` grezzo (`_id`, `codice_identificativo`, `tipo_mezzo`…).
  /// @param distanceMeters Distanza stimata dall'utente in metri (default 0).
  /// @return Il modello di vista con `docId` valorizzato per la prenotazione.
  factory VehicleData.daApi(Map<String, dynamic> doc, {int distanceMeters = 0}) {
    return VehicleData(
      id: '${doc['codice_identificativo'] ?? doc['_id'] ?? ''}',
      type: _tipoDaApi('${doc['tipo_mezzo'] ?? ''}'),
      batteryPercent: (doc['livello_batteria_pct'] ?? 0) as int,
      rangeKm: ((doc['autonomia_km'] ?? 0) as num).round(),
      distanceMeters: distanceMeters,
      docId: doc['_id']?.toString(),
    );
  }

  /// Mappa il discriminante `tipo_mezzo` del server sull'enum di vista.
  static VehicleType _tipoDaApi(String tipo) {
    switch (tipo) {
      case 'ebike':
        return VehicleType.bike;
      case 'ecar':
        return VehicleType.car;
      case 'emotorbike':
        return VehicleType.emoto;
      default:
        return VehicleType.scooter;
    }
  }

  String get typeLabel {
    switch (type) {
      case VehicleType.scooter:
        return 'Scooter Elettrico';
      case VehicleType.bike:
        return 'E-Bike';
      case VehicleType.car:
        return 'Auto Elettrica';
      case VehicleType.emoto:
        return 'E-Moto';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case VehicleType.scooter:
        return Icons.electric_scooter;
      case VehicleType.bike:
        return Icons.pedal_bike;
      case VehicleType.car:
        return Icons.directions_car;
      case VehicleType.emoto:
        return Icons.electric_moped;
    }
  }

  Color get typeColor {
    switch (type) {
      case VehicleType.scooter:
        return const Color(0xFF388E3C);
      case VehicleType.bike:
        return const Color(0xFF0097A7);
      case VehicleType.car:
        return const Color(0xFFE65100);
      case VehicleType.emoto:
        return const Color(0xFF1565C0);
    }
  }
}

/// Vehicle detail screen — shows all user-visible characteristics.
/// UT.05 (filter/view characteristics), UT.06 (wait time estimate),
/// UT.10 (unlock stub), UT.02 (booking stub).
class VehicleDetailScreen extends StatelessWidget {
  final VehicleData vehicle;

  /// Repository corse iniettabile per l'avvio corsa (default reale; test).
  final CorseApi? corse;

  const VehicleDetailScreen({required this.vehicle, super.key, this.corse});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(vehicle.typeLabel)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero vehicle card ────────────────────────────────────────
            Card(
              elevation: 0,
              color: vehicle.typeColor.withAlpha(18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(vehicle.typeIcon, size: 72, color: vehicle.typeColor),
                    const SizedBox(height: 12),
                    Text(
                      vehicle.id,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _StatusBadge(vehicle.status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Battery ──────────────────────────────────────────────────
            _SectionTitle(tr('Batteria')),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  vehicle.batteryPercent > 30
                      ? Icons.battery_charging_full
                      : Icons.battery_alert,
                  color: vehicle.batteryPercent > 30
                      ? AppTheme.primaryGreen
                      : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: vehicle.batteryPercent / 100,
                      minHeight: 12,
                      backgroundColor: Colors.black12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        vehicle.batteryPercent > 30
                            ? AppTheme.primaryGreen
                            : Colors.orange,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${vehicle.batteryPercent}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Stats grid ───────────────────────────────────────────────
            _SectionTitle(tr('Caratteristiche')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.route,
                    label: tr('Autonomia'),
                    value: '~${vehicle.rangeKm} km',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.near_me_outlined,
                    label: tr('Distanza da te'),
                    value: vehicle.distanceMeters < 1000
                        ? '${vehicle.distanceMeters} m'
                        : '${(vehicle.distanceMeters / 1000).toStringAsFixed(1)} km',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.timer_outlined,
                    // UT.06 — estimated wait time
                    label: tr('Attesa stimata'),
                    value: vehicle.distanceMeters < 300
                        ? '< 2 ${tr('min')}'
                        : '~${(vehicle.distanceMeters / 80).ceil()} ${tr('min')}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.euro_outlined,
                    // UT.03 — cost estimation (stub)
                    label: tr('Tariffa'),
                    value: _tariffLabel(vehicle.type),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Actions ──────────────────────────────────────────────────
            // Avviso patente per auto/moto elettriche senza patente (punto 6).
            if (patenteMancante(vehicle.type)) ...[
              _AvvisoPatente(),
              const SizedBox(height: 12),
            ],
            // UT.02 — booking
            ElevatedButton.icon(
              onPressed: () {
                if (patenteMancante(vehicle.type)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        tr('Carica la patente per noleggiare auto o moto elettriche.'),
                      ),
                      backgroundColor: const Color(0xFFC62828),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingScreen(vehicle: vehicle),
                  ),
                );
              },
              icon: const Icon(Icons.event_available_outlined),
              label: Text(tr('Prenota mezzo')),
              style: ElevatedButton.styleFrom(
                backgroundColor: vehicle.typeColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            // UT.10 — sblocco mezzo / avvio corsa
            _UnlockButton(vehicle: vehicle, corse: corse ?? corseRepository),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (r) => false,
              ),
              icon: const Icon(Icons.map_outlined, color: AppTheme.accentBrown),
              label: Text(
                tr('Vedi su mappa'),
                style: const TextStyle(color: AppTheme.accentBrown),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _tariffLabel(VehicleType t) {
    switch (t) {
      case VehicleType.scooter:
        return '0.25 €/min';
      case VehicleType.bike:
        return '0.15 €/min';
      case VehicleType.car:
        return '0.45 €/min';
      case VehicleType.emoto:
        return '0.30 €/min';
    }
  }
}

/// @brief Pulsante "Sblocca con QR" che avvia la corsa sul backend (UT.10).
///
/// Con un `docId` reale invia `corse.avvia(docId)` mostrando lo stato di
/// caricamento ed eventuali errori di dominio; senza `docId` (dati di riserva
/// mock) mantiene il comportamento dimostrativo "in sviluppo".
class _UnlockButton extends StatefulWidget {
  const _UnlockButton({required this.vehicle, required this.corse});

  /// Veicolo da sbloccare.
  final VehicleData vehicle;

  /// Repository corse usato per l'avvio.
  final CorseApi corse;

  @override
  State<_UnlockButton> createState() => _UnlockButtonState();
}

class _UnlockButtonState extends State<_UnlockButton> {
  /// Avvio corsa in corso (disabilita il pulsante e mostra lo spinner).
  bool _avvio = false;

  /// Avvia la corsa sul backend, o mostra il messaggio dimostrativo sui mock.
  Future<void> _sblocca() async {
    if (_avvio) return;
    // Punto 6: auto e moto elettriche non avviabili senza patente caricata.
    if (patenteMancante(widget.vehicle.type)) {
      _mostra(
        tr('Carica la patente per noleggiare auto o moto elettriche.'),
        const Color(0xFFC62828),
      );
      return;
    }
    final docId = widget.vehicle.docId;
    if (docId == null || docId.isEmpty) {
      _mostra(tr('Sblocco mezzo… (funzione in sviluppo)'), AppTheme.accentBrown);
      return;
    }
    setState(() => _avvio = true);
    try {
      final dati = await widget.corse.avvia(docId);
      // Registra la corsa attiva per abilitare pausa/riprendi (UT.12).
      final idCorsa = dati['id_corsa']?.toString();
      if (idCorsa != null && idCorsa.isNotEmpty) {
        startActiveTrip(
          idCorsa: idCorsa,
          vehicleId: widget.vehicle.id,
          vehicleType: widget.vehicle.type,
        );
      }
      if (!mounted) return;
      _mostra(tr('Mezzo sbloccato — corsa avviata'), AppTheme.primaryGreen);
    } on LeafApiException catch (e) {
      if (!mounted) return;
      _mostra(e.messaggio, const Color(0xFFC62828));
    } finally {
      if (mounted) setState(() => _avvio = false);
    }
  }

  /// Mostra un riscontro all'utente tramite SnackBar.
  void _mostra(String messaggio, Color colore) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(messaggio),
        backgroundColor: colore,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _avvio ? null : _sblocca,
      icon: _avvio
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: widget.vehicle.typeColor,
              ),
            )
          : const Icon(Icons.qr_code_scanner),
      label: Text(tr('Sblocca con QR')),
      style: OutlinedButton.styleFrom(
        foregroundColor: widget.vehicle.typeColor,
        side: BorderSide(color: widget.vehicle.typeColor),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

/// Banner che avvisa l'utente che il mezzo richiede la patente (punto 6, UT.22.2).
class _AvvisoPatente extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE57373)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFC62828)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tr('Per questo mezzo serve la patente: caricala nei dati sensibili.'),
              style: const TextStyle(color: Color(0xFFC62828), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppTheme.textGrey,
      letterSpacing: 0.6,
    ),
  );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.accentBrown),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textGrey),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);
  @override
  Widget build(BuildContext context) {
    final color = status == 'Disponibile'
        ? AppTheme.primaryGreen
        : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        tr(status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
