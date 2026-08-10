// Test dello store allerte di soglia alimentato da /api/v1/soglie/allerte (OP.02/OP.22).

import 'package:flutter_test/flutter_test.dart';

import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/fleet_repository.dart';
import 'package:web_dashboard/data/alerts_store.dart';

/// FlottaApi fittizia: ritorna allerte deterministiche (o errore) per `soglieAllerte`.
class _FakeFlotta implements FlottaApi {
  _FakeFlotta({this.errore = false});
  final bool errore;

  @override
  Future<List<Map<String, dynamic>>> soglieAllerte() async {
    if (errore) throw LeafApiException('rete giù');
    return [
      {'tipo': 'mezzi_area', 'area': 'Zona Est', 'presenti': 2, 'minimo': 5},
      {'tipo': 'batteria', 'mezzo': 'SC-021', 'batteria': 8, 'soglia': 15},
      {'tipo': 'sconosciuto', 'x': 1}, // scartata da daApi
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} non usato nei test');
}

void main() {
  setUp(() {
    AlertsStore.allerte.value = const [];
    AlertsStore.offline.value = false;
  });

  test('FleetAlert.daApi mappa una soglia mezzi_area', () {
    final a = FleetAlert.daApi(
      {'tipo': 'mezzi_area', 'area': 'Centro', 'presenti': 1, 'minimo': 4},
    );
    expect(a, isNotNull);
    expect(a!.tipo, 'mezzi_area');
    expect(a.area, 'Centro');
    expect(a.presenti, 1);
    expect(a.minimo, 4);
  });

  test('FleetAlert.daApi mappa una soglia batteria', () {
    final a = FleetAlert.daApi(
      {'tipo': 'batteria', 'mezzo': 'BK-100', 'batteria': 9, 'soglia': 20},
    );
    expect(a!.tipo, 'batteria');
    expect(a.mezzo, 'BK-100');
    expect(a.batteria, 9);
    expect(a.soglia, 20);
  });

  test('FleetAlert.daApi scarta i tipi non riconosciuti', () {
    expect(FleetAlert.daApi({'tipo': 'altro'}), isNull);
  });

  test('AlertsStore.carica popola le allerte reali (scartando le ignote)', () async {
    await AlertsStore.carica(repo: _FakeFlotta());
    expect(AlertsStore.allerte.value.length, 2);
    expect(AlertsStore.allerte.value.first.area, 'Zona Est');
    expect(AlertsStore.offline.value, isFalse);
  });

  test('AlertsStore.carica segnala offline e svuota le allerte reali', () async {
    await AlertsStore.carica(repo: _FakeFlotta(errore: true));
    expect(AlertsStore.offline.value, isTrue);
    expect(AlertsStore.allerte.value, isEmpty);
  });
}
