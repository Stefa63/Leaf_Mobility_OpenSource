part of 'map_tab.dart';

// ── Dati mock di mappa (pre-backend) ──────────────────────────────────────────
// Estratti da `map_tab.dart` per separare il dato dalla UI (TD-08). Restano
// `part of` la stessa libreria: gli identificatori privati (`_`) e i siti d'uso
// non cambiano. Le coordinate stanno tutte sul lato entroterra della costa
// adriatica (nessun marker in mare) e gli ID/livelli batteria sono allineati a
// `search_screen` e `home_tab` (SC-001/009/012, BK-003/007/011, CA-007, EM-002).
// La sorgente reale arrivera' col GatewayIoT/GatewayRouting (integration backlog
// §17, TD-02/TD-03).

/// Colore identificativo di ciascun filtro mezzo nelle chip (UT.05).
const Map<_VehicleFilter, Color> _filterColor = {
  _VehicleFilter.all: AppTheme.accentBrown,
  _VehicleFilter.scooter: Color(0xFF388E3C),
  _VehicleFilter.bike: Color(0xFF0097A7),
  _VehicleFilter.car: Color(0xFFE65100),
  _VehicleFilter.emoto: Color(0xFF1565C0),
  _VehicleFilter.charge: Color(0xFFF57F17),
};

/// Mezzi disponibili sulla mappa: `(id, filtro, posizione, etichetta)` (UT.01/UT.05).
const _vehicleData = [
  // Scooters — Murat / Libertà / Carrassi / San Nicola
  (
    'sc_001',
    _VehicleFilter.scooter,
    LatLng(41.1171, 16.8715), // Stazione Centrale
    'Scooter SC-001 · 78%',
  ),
  (
    'sc_009',
    _VehicleFilter.scooter,
    LatLng(41.1188, 16.8742), // Madonnella
    'Scooter SC-009 · 52%',
  ),
  (
    'sc_012',
    _VehicleFilter.scooter,
    LatLng(41.1258, 16.8702), // Teatro Petruzzelli
    'Scooter SC-012 · 90%',
  ),
  (
    'sc_014',
    _VehicleFilter.scooter,
    LatLng(41.1205, 16.8655), // Libertà
    'Scooter SC-014 · 67%',
  ),
  (
    'sc_017',
    _VehicleFilter.scooter,
    LatLng(41.1232, 16.8688), // Murat
    'Scooter SC-017 · 83%',
  ),
  (
    'sc_021',
    _VehicleFilter.scooter,
    LatLng(41.1148, 16.8665), // San Pasquale
    'Scooter SC-021 · 41%',
  ),
  (
    'sc_024',
    _VehicleFilter.scooter,
    LatLng(41.1108, 16.8702), // Carrassi
    'Scooter SC-024 · 95%',
  ),
  (
    'sc_028',
    _VehicleFilter.scooter,
    LatLng(41.1300, 16.8682), // Basilica San Nicola
    'Scooter SC-028 · 58%',
  ),
  (
    'sc_031',
    _VehicleFilter.scooter,
    LatLng(41.1045, 16.8628), // Parco 2 Giugno
    'Scooter SC-031 · 73%',
  ),
  (
    'sc_034',
    _VehicleFilter.scooter,
    LatLng(41.1170, 16.8600), // Libertà ovest
    'Scooter SC-034 · 64%',
  ),
  (
    'sc_037',
    _VehicleFilter.scooter,
    LatLng(41.1085, 16.8585), // Picone
    'Scooter SC-037 · 49%',
  ),
  // Bikes — center / Carrassi / Carbonara
  (
    'bk_003',
    _VehicleFilter.bike,
    LatLng(41.1278, 16.8665), // Cattedrale San Sabino
    'E-Bike BK-003 · 91%',
  ),
  (
    'bk_007',
    _VehicleFilter.bike,
    LatLng(41.1060, 16.8560), // Poggiofranco
    'E-Bike BK-007 · 74%',
  ),
  (
    'bk_011',
    _VehicleFilter.bike,
    LatLng(41.1242, 16.8718), // Corso Vittorio Emanuele
    'E-Bike BK-011 · 88%',
  ),
  (
    'bk_015',
    _VehicleFilter.bike,
    LatLng(41.0840, 16.8612), // Carbonara
    'E-Bike BK-015 · 55%',
  ),
  (
    'bk_018',
    _VehicleFilter.bike,
    LatLng(41.1162, 16.8718), // Madonnella
    'E-Bike BK-018 · 67%',
  ),
  (
    'bk_022',
    _VehicleFilter.bike,
    LatLng(41.1318, 16.8612), // San Girolamo / Marconi
    'E-Bike BK-022 · 80%',
  ),
  (
    'bk_026',
    _VehicleFilter.bike,
    LatLng(41.1185, 16.8730), // Madonnella (entroterra)
    'E-Bike BK-026 · 49%',
  ),
  (
    'bk_029',
    _VehicleFilter.bike,
    LatLng(41.1098, 16.8665), // Carrassi
    'E-Bike BK-029 · 77%',
  ),
  (
    'bk_033',
    _VehicleFilter.bike,
    LatLng(41.1212, 16.8625), // Libertà
    'E-Bike BK-033 · 60%',
  ),
  // Cars
  (
    'ca_007',
    _VehicleFilter.car,
    LatLng(41.1157, 16.8705), // Stazione Centrale
    'Auto CA-007 · 65%',
  ),
  (
    'ca_011',
    _VehicleFilter.car,
    LatLng(41.1005, 16.8742), // Japigia (entroterra)
    'Auto CA-011 · 82%',
  ),
  (
    'ca_015',
    _VehicleFilter.car,
    LatLng(41.0838, 16.8688), // Carbonara
    'Auto CA-015 · 48%',
  ),
  (
    'ca_019',
    _VehicleFilter.car,
    LatLng(41.1278, 16.8568), // Marconi
    'Auto CA-019 · 91%',
  ),
  (
    'ca_023',
    _VehicleFilter.car,
    LatLng(41.1068, 16.8712), // Policlinico
    'Auto CA-023 · 70%',
  ),
  (
    'ca_027',
    _VehicleFilter.car,
    LatLng(41.1135, 16.8638), // Libertà sud
    'Auto CA-027 · 55%',
  ),
  (
    'ca_031',
    _VehicleFilter.car,
    LatLng(41.1225, 16.8662), // Murat ovest
    'Auto CA-031 · 88%',
  ),
  // E-Moto
  (
    'em_002',
    _VehicleFilter.emoto,
    LatLng(41.1052, 16.8702), // Carrassi
    'E-Moto EM-002 · 85%',
  ),
  (
    'em_005',
    _VehicleFilter.emoto,
    LatLng(41.0855, 16.8628), // Carbonara
    'E-Moto EM-005 · 60%',
  ),
  (
    'em_008',
    _VehicleFilter.emoto,
    LatLng(41.1378, 16.7720), // Palese / Aeroporto
    'E-Moto EM-008 · 72%',
  ),
  (
    'em_012',
    _VehicleFilter.emoto,
    LatLng(41.1190, 16.8640), // Libertà
    'E-Moto EM-012 · 88%',
  ),
  (
    'em_015',
    _VehicleFilter.emoto,
    LatLng(41.1238, 16.8695), // Murat
    'E-Moto EM-015 · 54%',
  ),
  (
    'em_018',
    _VehicleFilter.emoto,
    LatLng(41.1118, 16.8602), // Picone / Carrassi
    'E-Moto EM-018 · 79%',
  ),
];

/// Stazioni di ricarica autorizzate: `(id, posizione, etichetta)` (UT.14).
///
/// Posizioni reali su Bari fornite dal team (coordinate da DMS a gradi decimali),
/// allineate al seed server `bootstrap_seed.py` (CHG-01..CHG-10): questa è la vista
/// di riserva offline quando `/api/v1/stazioni` non è raggiungibile (IIN-6).
const _chargingData = [
  (
    'chg_01',
    LatLng(41.118083, 16.868694),
    'Ricarica – Stazione Bari Centrale · 6 posti',
  ),
  (
    'chg_02',
    LatLng(41.125167, 16.873694),
    'Ricarica – Lungomare Crollalanza · 4 posti',
  ),
  (
    'chg_03',
    LatLng(41.126028, 16.868278),
    'Ricarica – Corso Vittorio Emanuele · 4 posti',
  ),
  ('chg_04', LatLng(41.119250, 16.882639), 'Ricarica – Corso Sydney · 4 posti'),
  ('chg_05', LatLng(41.111889, 16.863278), 'Ricarica – Policlinico · 5 posti'),
  (
    'chg_06',
    LatLng(41.105778, 16.874889),
    'Ricarica – Parco Due Giugno · 3 posti',
  ),
  (
    'chg_07',
    LatLng(41.134611, 16.835722),
    'Ricarica – Fiera del Levante · 6 posti',
  ),
  (
    'chg_08',
    LatLng(41.137056, 16.827222),
    'Ricarica – Lungomare San Girolamo · 4 posti',
  ),
  (
    'chg_09',
    LatLng(41.102556, 16.867361),
    'Ricarica – Poggiofranco / Via Petroni · 3 posti',
  ),
  (
    'chg_10',
    LatLng(41.097944, 16.854083),
    'Ricarica – Poggiofranco / Via Caccuri · 3 posti',
  ),
];
