// Test unitari della sorgente dati di flotta condivisa (OP.20, AP.03, AP.10).
//
// FleetData e' lo store statico (mock pre-backend) che alimenta mappe e
// metriche delle console OP/AP: i dati sono costanti, quindi non serve un
// reset tra i test. Si verificano la coerenza degli aggregati e la copertura
// completa degli helper di presentazione su ogni valore enum.

import 'package:flutter_test/flutter_test.dart';

import 'package:web_dashboard/data/fleet_data.dart';

void main() {
  test('I conteggi per stato sommano al totale della flotta (OP.20)', () {
    final sum = VehicleStatus.values
        .map(FleetData.countByStatus)
        .reduce((a, b) => a + b);
    expect(sum, FleetData.total);
  });

  test('I conteggi per tipologia sommano al totale della flotta', () {
    final sum = VehicleType.values
        .map(FleetData.countByType)
        .reduce((a, b) => a + b);
    expect(sum, FleetData.total);
  });

  test('activeCount = disponibili + in uso e activePct coerente (AP.03)', () {
    final expected = FleetData.countByStatus(VehicleStatus.available) +
        FleetData.countByStatus(VehicleStatus.inUse);
    expect(FleetData.activeCount, expected);
    expect(
      FleetData.activePct,
      (expected * 100 / FleetData.total).round(),
    );
  });

  test('Gli ID dei veicoli sono univoci', () {
    final ids = FleetData.vehicles.map((v) => v.id).toSet();
    expect(ids.length, FleetData.vehicles.length);
  });

  test('La proiezione MapBounds resta nel quadrato unitario', () {
    for (final v in FleetData.vehicles) {
      final p = MapBounds.project(v.lat, v.lng);
      expect(p.dx, inInclusiveRange(0.0, 1.0));
      expect(p.dy, inInclusiveRange(0.0, 1.0));
    }
  });

  test('Helper di presentazione definiti per ogni tipologia e stato', () {
    for (final t in VehicleType.values) {
      expect(vehicleTypeLabel(t), isNotEmpty);
      expect(vehicleTypeColor(t), isNotNull);
      expect(vehicleTypeIcon(t), isNotNull);
    }
    for (final s in VehicleStatus.values) {
      expect(vehicleStatusLabel(s), isNotEmpty);
      expect(vehicleStatusColor(s), isNotNull);
    }
  });
}
