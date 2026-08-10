import 'package:flutter/material.dart';
import 'package:web_dashboard/theme.dart';

/// Tipologia di veicolo condivisa (allineata ai filtri di AppMobileUtente).
enum VehicleType { scooter, bike, car, emoto }

/// Stato operativo del mezzo visibile nelle dashboard OP. OP.20.
enum VehicleStatus { available, inUse, maintenance, lowBattery }

/// @brief Veicolo della flotta condivisa LEAF Mobility.
///
/// Le coordinate replicano 1:1 quelle mostrate sulla mappa di
/// [AppMobileUtente] (map_tab.dart): la vista di OP/AP coincide cosi' con la
/// vista utente, come richiesto. UT.01 / OP.01 / AP.10.
@immutable
class Vehicle {
  final String id;
  final VehicleType type;
  final double lat;
  final double lng;
  final int battery;
  final VehicleStatus status;

  const Vehicle(
    this.id,
    this.type,
    this.lat,
    this.lng,
    this.battery,
    this.status,
  );

  /// @brief Costruisce un [Vehicle] da un documento `mezzi` della API (OP.01/OP.20).
  ///
  /// Mappa i campi snake_case del server (`codice_identificativo`, `tipo_mezzo`,
  /// `posizione{lat,lon}`, `livello_batteria_pct`, `stato_operativo`) sul modello
  /// di vista. Ritorna null se il mezzo non ha una posizione valida.
  ///
  /// @param d Documento mezzo grezzo da `/api/v1/flotta`.
  /// @return Il [Vehicle] corrispondente, o null se senza coordinate.
  static Vehicle? daApi(Map<String, dynamic> d) {
    final pos = d['posizione'];
    if (pos is! Map || pos['lat'] == null || pos['lon'] == null) return null;
    return Vehicle(
      '${d['codice_identificativo'] ?? d['_id'] ?? ''}',
      _tipoDaApi('${d['tipo_mezzo'] ?? ''}'),
      (pos['lat'] as num).toDouble(),
      (pos['lon'] as num).toDouble(),
      (d['livello_batteria_pct'] ?? 0) as int,
      _statoDaApi('${d['stato_operativo'] ?? ''}'),
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

  /// Mappa `stato_operativo` del server sullo stato operativo di vista.
  static VehicleStatus _statoDaApi(String stato) {
    switch (stato) {
      case 'in_uso':
        return VehicleStatus.inUse;
      case 'manutenzione':
      case 'guasto':
        return VehicleStatus.maintenance;
      case 'scarico':
      case 'batteria_scarica':
        return VehicleStatus.lowBattery;
      default:
        return VehicleStatus.available;
    }
  }
}

/// @brief Stazione di ricarica condivisa. UT.14 / OP.22.
@immutable
class ChargingStation {
  final String id;
  final double lat;
  final double lng;
  final int slots;
  final String area;

  const ChargingStation(this.id, this.lat, this.lng, this.slots, this.area);
}

/// @brief Fermata del sistema TPL (trasporto pubblico locale).
///
/// Integrata nativamente nei dati mappa (vincolo architetturale: sistemaTPL
/// non e' un modulo separato).
@immutable
class TplStop {
  final String id;
  final double lat;
  final double lng;
  final String name;

  const TplStop(this.id, this.lat, this.lng, this.name);
}

/// @brief Riquadro geografico per la proiezione lat/lng → coordinate schermo.
///
/// Bounds centrati su Bari, scelti per contenere l'intera flotta mostrata in
/// [AppMobileUtente]. La proiezione e' equirettangolare (sufficiente alla
/// scala cittadina) con il nord in alto.
class MapBounds {
  static const double minLat = 41.080;
  static const double maxLat = 41.142;
  static const double minLng = 16.745;
  static const double maxLng = 16.885;

  /// @brief Proietta una coordinata geografica in frazioni [0,1] dell'area.
  /// @param lat Latitudine.
  /// @param lng Longitudine.
  /// @return Offset con dx/dy in [0,1] (origine in alto a sinistra).
  static Offset project(double lat, double lng) {
    final fx = ((lng - minLng) / (maxLng - minLng)).clamp(0.0, 1.0);
    final fy = ((maxLat - lat) / (maxLat - minLat)).clamp(0.0, 1.0);
    return Offset(fx, fy);
  }
}

/// @brief Sorgente dati condivisa della flotta (mock pre-backend).
///
/// Finche' il Business Tier (`gestore_flotta`) non sara' disponibile, queste
/// strutture statiche alimentano sia la mappa che le metriche. Le posizioni
/// coincidono con quelle di [AppMobileUtente]; gli stati operativi sono
/// aggiunti per le viste OP. OP.01 / OP.03 / OP.20 / AP.03 / AP.10.
class FleetData {
  FleetData._();

  /// Veicoli — posizioni identiche a map_tab.dart di AppMobileUtente.
  static const List<Vehicle> vehicles = [
    // Scooter
    Vehicle('SC-001', VehicleType.scooter, 41.1171, 16.8715, 78,
        VehicleStatus.inUse),
    Vehicle('SC-009', VehicleType.scooter, 41.1188, 16.8742, 52,
        VehicleStatus.available),
    Vehicle('SC-012', VehicleType.scooter, 41.1258, 16.8702, 90,
        VehicleStatus.available),
    Vehicle('SC-014', VehicleType.scooter, 41.1205, 16.8655, 67,
        VehicleStatus.available),
    Vehicle('SC-017', VehicleType.scooter, 41.1232, 16.8688, 83,
        VehicleStatus.inUse),
    Vehicle('SC-021', VehicleType.scooter, 41.1148, 16.8665, 41,
        VehicleStatus.maintenance),
    Vehicle('SC-024', VehicleType.scooter, 41.1108, 16.8702, 95,
        VehicleStatus.available),
    Vehicle('SC-028', VehicleType.scooter, 41.1300, 16.8682, 58,
        VehicleStatus.available),
    Vehicle('SC-031', VehicleType.scooter, 41.1045, 16.8628, 73,
        VehicleStatus.available),
    Vehicle('SC-034', VehicleType.scooter, 41.1170, 16.8600, 64,
        VehicleStatus.available),
    Vehicle('SC-037', VehicleType.scooter, 41.1085, 16.8585, 9,
        VehicleStatus.lowBattery),
    // Bici
    Vehicle('BK-003', VehicleType.bike, 41.1278, 16.8665, 91,
        VehicleStatus.inUse),
    Vehicle('BK-007', VehicleType.bike, 41.1060, 16.8560, 74,
        VehicleStatus.available),
    Vehicle('BK-011', VehicleType.bike, 41.1242, 16.8718, 88,
        VehicleStatus.inUse),
    Vehicle('BK-015', VehicleType.bike, 41.0840, 16.8612, 55,
        VehicleStatus.available),
    Vehicle('BK-018', VehicleType.bike, 41.1162, 16.8718, 67,
        VehicleStatus.available),
    Vehicle('BK-022', VehicleType.bike, 41.1318, 16.8612, 80,
        VehicleStatus.available),
    Vehicle('BK-026', VehicleType.bike, 41.1185, 16.8730, 12,
        VehicleStatus.lowBattery),
    Vehicle('BK-029', VehicleType.bike, 41.1098, 16.8665, 77,
        VehicleStatus.available),
    Vehicle('BK-033', VehicleType.bike, 41.1212, 16.8625, 60,
        VehicleStatus.available),
    // Auto
    Vehicle('CA-007', VehicleType.car, 41.1157, 16.8705, 65,
        VehicleStatus.inUse),
    Vehicle('CA-011', VehicleType.car, 41.1005, 16.8742, 82,
        VehicleStatus.available),
    Vehicle('CA-015', VehicleType.car, 41.0838, 16.8688, 48,
        VehicleStatus.maintenance),
    Vehicle('CA-019', VehicleType.car, 41.1278, 16.8568, 91,
        VehicleStatus.available),
    Vehicle('CA-023', VehicleType.car, 41.1068, 16.8712, 70,
        VehicleStatus.available),
    Vehicle('CA-027', VehicleType.car, 41.1135, 16.8638, 55,
        VehicleStatus.available),
    Vehicle('CA-031', VehicleType.car, 41.1225, 16.8662, 88,
        VehicleStatus.available),
    // E-Moto
    Vehicle('EM-002', VehicleType.emoto, 41.1052, 16.8702, 85,
        VehicleStatus.inUse),
    Vehicle('EM-005', VehicleType.emoto, 41.0855, 16.8628, 60,
        VehicleStatus.available),
    Vehicle('EM-008', VehicleType.emoto, 41.1378, 16.7720, 72,
        VehicleStatus.available),
    Vehicle('EM-012', VehicleType.emoto, 41.1190, 16.8640, 88,
        VehicleStatus.available),
    Vehicle('EM-015', VehicleType.emoto, 41.1238, 16.8695, 8,
        VehicleStatus.lowBattery),
    Vehicle('EM-018', VehicleType.emoto, 41.1118, 16.8602, 79,
        VehicleStatus.available),
  ];

  /// Stazioni di ricarica — posizioni identiche a map_tab.dart.
  static const List<ChargingStation> charging = [
    ChargingStation('CHG-01', 41.1262, 16.8698, 4, 'Piazza Ferrarese'),
    ChargingStation('CHG-02', 41.1072, 16.8608, 2, 'Via Amendola'),
    ChargingStation('CHG-03', 41.0958, 16.8718, 6, 'Japigia'),
    ChargingStation('CHG-04', 41.1275, 16.8718, 3, 'Lungomare'),
    ChargingStation('CHG-05', 41.1200, 16.8678, 5, 'Piazza Umberto'),
    ChargingStation('CHG-06', 41.1142, 16.8728, 4, 'Murat'),
    ChargingStation('CHG-07', 41.0892, 16.8742, 2, 'Japigia Sud'),
    ChargingStation('CHG-08', 41.1325, 16.8530, 3, 'San Cataldo'),
    ChargingStation('CHG-09', 41.1162, 16.8632, 4, 'Quartiere Libertà'),
    ChargingStation('CHG-10', 41.1085, 16.8628, 3, 'Carrassi'),
    ChargingStation('CHG-11', 41.1248, 16.8648, 5, 'Corso Cavour'),
    ChargingStation('CHG-12', 41.1300, 16.8505, 6, 'Fiera del Levante'),
    ChargingStation('CHG-13', 41.1042, 16.8552, 2, 'Poggiofranco'),
    ChargingStation('CHG-14', 41.0845, 16.8662, 3, 'Carbonara'),
  ];

  /// Fermate TPL — posizioni identiche a map_tab.dart (sistemaTPL integrato).
  static const List<TplStop> tplStops = [
    TplStop('TPL-FS', 41.1157, 16.8711, 'Stazione FS Bari Centrale'),
    TplStop('TPL-FIERA', 41.1000, 16.8500, 'Fiera del Levante – Bus Hub'),
    TplStop('TPL-PETRUZZELLI', 41.1236, 16.8719, 'Teatro Petruzzelli'),
    TplStop('TPL-POLICLINICO', 41.1095, 16.8780, 'Policlinico – Bus'),
    TplStop('TPL-AEROPORTO', 41.1389, 16.7606, 'Aeroporto K. Wojtyła'),
  ];

  // ── Aggregati per le metriche dashboard ──────────────────────────────────
  static int get total => vehicles.length;

  static int countByStatus(VehicleStatus s) =>
      vehicles.where((v) => v.status == s).length;

  static int countByType(VehicleType t) =>
      vehicles.where((v) => v.type == t).length;

  /// Mezzi operativi (disponibili o in uso) = "Attivi" delle dashboard. AP.03.
  static int get activeCount =>
      countByStatus(VehicleStatus.available) +
      countByStatus(VehicleStatus.inUse);

  /// Percentuale di mezzi attivi sul totale, arrotondata.
  static int get activePct => (activeCount * 100 / total).round();

  static int get lowBatteryPct =>
      (countByStatus(VehicleStatus.lowBattery) * 100 / total).round();

  static int get maintenancePct =>
      (countByStatus(VehicleStatus.maintenance) * 100 / total).round();
}

// ── Helper di presentazione (colori, icone, etichette) ──────────────────────

/// @brief Colore associato alla tipologia di mezzo (coerente con i marker).
Color vehicleTypeColor(VehicleType t) {
  switch (t) {
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

/// @brief Icona Material associata alla tipologia di mezzo.
IconData vehicleTypeIcon(VehicleType t) {
  switch (t) {
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

/// @brief Etichetta (chiave i18n) della tipologia di mezzo.
String vehicleTypeLabel(VehicleType t) {
  switch (t) {
    case VehicleType.scooter:
      return 'Scooter';
    case VehicleType.bike:
      return 'Bici';
    case VehicleType.car:
      return 'Auto';
    case VehicleType.emoto:
      return 'E-Moto';
  }
}

/// @brief Colore associato allo stato operativo del mezzo.
Color vehicleStatusColor(VehicleStatus s) {
  switch (s) {
    case VehicleStatus.available:
      return AppTheme.statusAvailable;
    case VehicleStatus.inUse:
      return AppTheme.statusInUse;
    case VehicleStatus.maintenance:
      return AppTheme.statusMaintenance;
    case VehicleStatus.lowBattery:
      return AppTheme.statusLowBattery;
  }
}

/// @brief Etichetta (chiave i18n) dello stato operativo del mezzo.
String vehicleStatusLabel(VehicleStatus s) {
  switch (s) {
    case VehicleStatus.available:
      return 'Disponibile';
    case VehicleStatus.inUse:
      return 'In uso';
    case VehicleStatus.maintenance:
      return 'In manutenzione';
    case VehicleStatus.lowBattery:
      return 'Batteria scarica';
  }
}

/// @brief Mappa il discriminante `tipo_mezzo` del server sull'enum di vista.
/// @param tipo Valore `tipo_mezzo` del documento mezzo (es. "ebike").
/// @return Il [VehicleType] corrispondente (scooter per valori ignoti).
VehicleType vehicleTypeFromApi(String tipo) {
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

/// @brief Mappa `stato_operativo` del server sullo stato operativo di vista.
/// @param stato Valore `stato_operativo` del documento mezzo (es. "manutenzione").
/// @return Il [VehicleStatus] corrispondente (disponibile per valori ignoti).
VehicleStatus vehicleStatusFromApi(String stato) {
  switch (stato) {
    case 'in_uso':
      return VehicleStatus.inUse;
    case 'manutenzione':
    case 'guasto':
      return VehicleStatus.maintenance;
    case 'scarico':
    case 'batteria_scarica':
      return VehicleStatus.lowBattery;
    default:
      return VehicleStatus.available;
  }
}
