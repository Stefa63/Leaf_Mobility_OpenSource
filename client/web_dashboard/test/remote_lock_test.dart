// Test del dialog di blocco/sblocco motore remoto cablato agli endpoint reali
// /api/v1/mezzi/{codice}/blocco-motore e /sblocco-motore (OP.11).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/fleet_repository.dart';
import 'package:web_dashboard/data/fleet_data.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/screens/op_dashboard.dart';

/// FlottaApi fittizia: registra blocco/sblocco richiesti (o simula errore di rete).
class _FakeFlotta implements FlottaApi {
  _FakeFlotta({this.errore = false});
  final bool errore;
  String? codiceBloccato;
  String? codiceSbloccato;

  @override
  Future<Map<String, dynamic>> bloccoMotore(String codice) async {
    codiceBloccato = codice;
    if (errore) throw LeafApiException('rete giù');
    return {'esito': 'comando_inviato', 'codice': codice};
  }

  @override
  Future<Map<String, dynamic>> sbloccoMotore(String codice) async {
    codiceSbloccato = codice;
    if (errore) throw LeafApiException('rete giù');
    return {'esito': 'comando_inviato', 'codice': codice};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} non usato nei test');
}

/// Monta un pulsante che apre il dialog con il repository fittizio iniettato.
Future<void> _pump(WidgetTester tester, _FakeFlotta fake) async {
  appLanguage.value = 'it';
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showRemoteLockDialog(context, repo: fake),
            child: const Text('apri'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Il blocco motore invia il comando reale e conferma (OP.11)', (
    tester,
  ) async {
    final fake = _FakeFlotta();
    await _pump(tester, fake);

    await tester.tap(find.text('apri'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Blocca'));
    await tester.pumpAndSettle();

    expect(fake.codiceBloccato, FleetData.vehicles.first.id);
    expect(find.textContaining('Comando di blocco inviato'), findsOneWidget);
  });

  testWidgets('In errore di rete il blocco mostra il fallimento (IIN-6)', (
    tester,
  ) async {
    final fake = _FakeFlotta(errore: true);
    await _pump(tester, fake);

    await tester.tap(find.text('apri'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Blocca'));
    await tester.pumpAndSettle();

    expect(fake.codiceBloccato, FleetData.vehicles.first.id);
    expect(find.textContaining('Invio comando non riuscito'), findsOneWidget);
  });

  testWidgets('Lo sblocco motore invia il comando reale e conferma (OP.11)', (
    tester,
  ) async {
    final fake = _FakeFlotta();
    await _pump(tester, fake);

    await tester.tap(find.text('apri'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sblocca'));
    await tester.pumpAndSettle();

    expect(fake.codiceSbloccato, FleetData.vehicles.first.id);
    expect(fake.codiceBloccato, isNull);
    expect(find.textContaining('Comando di sblocco inviato'), findsOneWidget);
  });
}
