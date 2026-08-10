// Test dello store flotta alimentato da /api/v1/flotta (FASE 2.C, A2).

import 'package:flutter_test/flutter_test.dart';

import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/fleet_repository.dart';
import 'package:web_dashboard/data/fleet_data.dart';
import 'package:web_dashboard/data/fleet_store.dart';

/// FlottaApi fittizia: ritorna un mezzo deterministico (o errore).
class _FakeFlotta implements FlottaApi {
  _FakeFlotta({this.errore = false});
  final bool errore;

  @override
  Future<List<Map<String, dynamic>>> elenco({String? stato}) async {
    if (errore) throw LeafApiException('rete giù');
    return [
      {
        '_id': 'm1',
        'codice_identificativo': 'SC-900',
        'tipo_mezzo': 'monopattino',
        'stato_operativo': 'in_uso',
        'livello_batteria_pct': 77,
        'posizione': {'lat': 41.12, 'lon': 16.87},
      },
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} non usato nei test');
}

void main() {
  setUp(() {
    FleetStore.vehicles.value = FleetData.vehicles;
    FleetStore.offline.value = false;
  });

  test('Vehicle.daApi mappa i campi del documento mezzo', () {
    final v = Vehicle.daApi({
      '_id': 'm1',
      'codice_identificativo': 'BK-100',
      'tipo_mezzo': 'ebike',
      'stato_operativo': 'manutenzione',
      'livello_batteria_pct': 33,
      'posizione': {'lat': 41.1, 'lon': 16.8},
    });
    expect(v, isNotNull);
    expect(v!.id, 'BK-100');
    expect(v.type, VehicleType.bike);
    expect(v.status, VehicleStatus.maintenance);
    expect(v.battery, 33);
  });

  test('Vehicle.daApi ritorna null senza posizione', () {
    expect(Vehicle.daApi({'codice_identificativo': 'X', 'tipo_mezzo': 'ecar'}),
        isNull);
  });

  test('FleetStore.carica popola lo store dai dati reali', () async {
    await FleetStore.carica(repo: _FakeFlotta());
    expect(FleetStore.vehicles.value.length, 1);
    expect(FleetStore.vehicles.value.first.id, 'SC-900');
    expect(FleetStore.offline.value, isFalse);
  });

  test('FleetStore.carica segnala offline e tiene i dati di riserva', () async {
    await FleetStore.carica(repo: _FakeFlotta(errore: true));
    expect(FleetStore.offline.value, isTrue);
    expect(FleetStore.vehicles.value, FleetData.vehicles);
  });
}
