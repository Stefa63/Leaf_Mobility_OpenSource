// Widget test della Diagnostica Flotta: report giornaliero (OP.13) + mezzi guasti (OP.03).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/fleet_repository.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/screens/fleet_diagnostics.dart';

/// FlottaApi fittizia: report e mezzi guasti deterministici (o errore di rete).
class _FakeFlotta implements FlottaApi {
  _FakeFlotta({this.errore = false});
  final bool errore;

  @override
  Future<Map<String, dynamic>> reportGiornaliero() async {
    if (errore) throw LeafApiException('rete giù');
    return {
      'per_stato': {'disponibile': 7, 'in_uso': 3, 'guasto': 2},
      'batteria_scarica': 4,
      'totale': 12,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> mezziGuasti() async {
    if (errore) throw LeafApiException('rete giù');
    return [
      {
        'codice_identificativo': 'SC-021',
        'tipo_mezzo': 'monopattino',
        'livello_batteria_pct': 8,
      },
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} non usato nei test');
}

Future<void> _pump(WidgetTester tester, FlottaApi repo) async {
  appLanguage.value = 'it';
  await tester.binding.setSurfaceSize(const Size(1200, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: FleetDiagnostics(repo: repo)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Mostra il report giornaliero e i mezzi guasti reali (OP.03/OP.13)', (
    tester,
  ) async {
    await _pump(tester, _FakeFlotta());

    expect(find.text('Diagnostica Flotta'), findsOneWidget);
    expect(find.text('12'), findsOneWidget); // totale mezzi
    expect(find.text('4'), findsOneWidget); // batteria scarica
    expect(find.textContaining('SC-021'), findsOneWidget); // mezzo guasto
  });

  testWidgets('In errore di rete mostra il banner offline (IIN-6)', (
    tester,
  ) async {
    await _pump(tester, _FakeFlotta(errore: true));

    expect(find.text('Dati non aggiornati (offline)'), findsOneWidget);
  });
}
