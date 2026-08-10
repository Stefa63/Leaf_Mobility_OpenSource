// Test del cablaggio assistenza al backend (UT.09) — chiusura debito repository orfano.
//
// All'invio, SupportScreen chiama AssistenzaApi.apri (POST /api/v1/assistenza)
// con stati loading/errore; il repository è iniettabile per i test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile_utente/api/api_client.dart';
import 'package:app_mobile_utente/api/assistenza_repository.dart';
import 'package:app_mobile_utente/screens/support_screen.dart';

/// Repository assistenza fittizio che registra la chiamata di apertura.
class _SpyAssistenza implements AssistenzaApi {
  String? oggetto;
  String? messaggio;

  @override
  Future<Map<String, dynamic>> apri(
    String oggetto,
    String messaggio, {
    String? idCorsa,
  }) async {
    this.oggetto = oggetto;
    this.messaggio = messaggio;
    return {'id_ticket': 't1'};
  }
}

/// Repository assistenza fittizio che fallisce con errore di dominio.
class _FailAssistenza implements AssistenzaApi {
  @override
  Future<Map<String, dynamic>> apri(
    String oggetto,
    String messaggio, {
    String? idCorsa,
  }) async {
    throw LeafApiException('Servizio non disponibile', codice: 503);
  }
}

void main() {
  testWidgets('Invio segnalazione chiama il backend e conferma (UT.09)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final spy = _SpyAssistenza();
    await tester.pumpWidget(
      MaterialApp(home: SupportScreen(assistenza: spy)),
    );

    await tester.enterText(find.byType(TextField), 'Serve aiuto col mezzo');
    final invia = find.widgetWithText(ElevatedButton, 'Invia');
    await tester.tap(invia);
    await tester.pumpAndSettle();

    expect(spy.oggetto, 'Feedback');
    expect(spy.messaggio, 'Serve aiuto col mezzo');
    expect(find.text('Grazie! La tua segnalazione è stata inviata.'), findsOneWidget);
    // Il campo è ripulito dopo l'invio riuscito.
    expect(find.text('Serve aiuto col mezzo'), findsNothing);
  });

  testWidgets('Errore del backend mostra il messaggio di dominio (UT.09)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: SupportScreen(assistenza: _FailAssistenza())),
    );

    await tester.enterText(find.byType(TextField), 'Messaggio di prova');
    final invia = find.widgetWithText(ElevatedButton, 'Invia');
    await tester.tap(invia);
    await tester.pumpAndSettle();

    expect(find.text('Servizio non disponibile'), findsOneWidget);
    // Il messaggio resta nel campo per consentire un nuovo tentativo.
    expect(find.text('Messaggio di prova'), findsOneWidget);
  });
}
