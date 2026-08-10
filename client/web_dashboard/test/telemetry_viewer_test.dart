// Widget test del Visualizzatore Telemetria: registro eventi per mezzo (OP.07/OP.14).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/fleet_repository.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/screens/telemetry_viewer.dart';

/// FlottaApi fittizia: registro telemetrico deterministico (o errore di rete).
class _FakeFlotta implements FlottaApi {
  _FakeFlotta({this.errore = false});
  final bool errore;

  @override
  Future<List<Map<String, dynamic>>> telemetria(String codice) async {
    if (errore) throw LeafApiException('rete giù');
    return [
      {
        'tipo': 'sblocco',
        'timestamp': '2026-06-25T14:30:00+00:00',
        'posizione': '{"lat":41.1234,"lon":16.8765}',
      },
      {
        'tipo': 'urto',
        'timestamp': '2026-06-25T14:45:10+00:00',
        'velocita': 12.5,
        'dettagli': 'Decelerazione brusca',
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
      home: Scaffold(
        body: TelemetryViewer(repo: repo, codiceIniziale: 'BK-1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Carica e mostra gli eventi telemetrici del mezzo (OP.07/OP.14)', (
    tester,
  ) async {
    await _pump(tester, _FakeFlotta());

    expect(find.text('Telemetria'), findsOneWidget);

    await tester.tap(find.text('Carica'));
    await tester.pumpAndSettle();

    expect(find.text('Sblocco'), findsOneWidget);
    expect(find.text('Urto rilevato'), findsOneWidget);
    expect(find.textContaining('41.1234, 16.8765'), findsOneWidget);
  });

  testWidgets('In errore di rete mostra il banner offline (IIN-6)', (
    tester,
  ) async {
    await _pump(tester, _FakeFlotta(errore: true));

    await tester.tap(find.text('Carica'));
    await tester.pumpAndSettle();

    expect(find.text('Telemetria non disponibile (offline)'), findsOneWidget);
  });
}
