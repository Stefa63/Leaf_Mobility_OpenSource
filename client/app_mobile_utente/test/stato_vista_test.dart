// Test del widget riusabile di stato (caricamento/errore/vuoto) — FASE 2.B.
//
// Verifica gli stati che le schermate dati riutilizzano: il caricatore mostra
// l'indicatore mentre il Future è pendente, l'errore con "Riprova" su eccezione,
// lo stato vuoto sul predicato, e il riconoscimento dell'offline (IIN-6).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile_utente/api/api_client.dart';
import 'package:app_mobile_utente/widgets/stato_vista.dart';

void main() {
  testWidgets('CaricatoreVista mostra caricamento poi dati', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CaricatoreVista<int>(
            carica: () async => 42,
            costruisci: (context, dati) => Text('valore $dati'),
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('valore 42'), findsOneWidget);
  });

  testWidgets('CaricatoreVista mostra errore con Riprova su eccezione', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CaricatoreVista<int>(
            carica: () async => throw LeafApiException('Boom', codice: 500),
            costruisci: (context, dati) => Text('$dati'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Boom'), findsOneWidget);
    expect(find.text('Riprova'), findsOneWidget);
  });

  testWidgets('CaricatoreVista mostra lo stato vuoto sul predicato', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CaricatoreVista<List<int>>(
            carica: () async => const <int>[],
            vuotoSe: (dati) => dati.isEmpty,
            vistaVuota: const VistaVuota(titolo: 'Niente qui'),
            costruisci: (context, dati) => Text('${dati.length}'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Niente qui'), findsOneWidget);
  });

  testWidgets('VistaErrore.da riconosce l\'assenza di connessione (IIN-6)', (
    tester,
  ) async {
    // Eccezione senza codice HTTP → trattata come offline.
    final vista = VistaErrore.da(LeafApiException('rete giù'));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: vista)));
    expect(vista.offline, isTrue);
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
  });
}
