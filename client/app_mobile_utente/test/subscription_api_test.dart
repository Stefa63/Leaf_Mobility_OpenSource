// Test del cablaggio abbonamento al backend (UT.18) — Task 3.
//
// La pressione di "Seleziona Piano" invia al backend l'id reale del piano
// (POST /profilo/abbonamenti) tramite ProfiloApi iniettato.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile_utente/api/profilo_repository.dart';
import 'package:app_mobile_utente/screens/buy_subscription_screen.dart';

/// Repository profilo fittizio che cattura l'id del piano sottoscritto.
class _SpyProfilo implements ProfiloApi {
  String? sottoscritto;

  @override
  Future<Map<String, dynamic>> sottoscriviAbbonamento(String idPiano) async {
    sottoscritto = idPiano;
    return {'id_abbonamento': 'ab1', 'id_piano': idPiano, 'data_fine': '2026-07-26'};
  }

  @override
  Future<Map<String, dynamic>> profilo() async => const {};
  @override
  Future<Map<String, dynamic>> aggiorna(Map<String, dynamic> modifiche) async =>
      const {};
  @override
  Future<Map<String, dynamic>> registraPagamento({
    required String numero,
    required int mese,
    required int anno,
    required String titolare,
    required String cvv,
    required String indirizzoFatturazione,
  }) async => const {};
  @override
  Future<Map<String, dynamic>> caricaKyc({
    required String tipo,
    required String nomeFile,
  }) async => const {};

  @override
  Future<List<Map<String, dynamic>>> abbonamenti() async => const [];
}

void main() {
  testWidgets('I piani mostrati usano gli id reali del seed (UT.18)', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: BuySubscriptionScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('LEAF Base'), findsOneWidget);
    expect(find.text('LEAF Plus'), findsOneWidget);
    expect(find.text('LEAF Annuale'), findsOneWidget);
    expect(kPianiAbbonamento.map((p) => p.idPiano), [
      'piano-base',
      'piano-plus',
      'piano-annuale',
    ]);
  });

  testWidgets('Seleziona Piano sottoscrive l\'id corretto al backend (UT.18)', (
    tester,
  ) async {
    final spy = _SpyProfilo();
    await tester.pumpWidget(
      MaterialApp(
        // Una rotta iniziale così il pop di successo non lascia schermo vuoto.
        home: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute(
            builder: (_) => BuySubscriptionScreen(profilo: spy),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Il primo piano del catalogo è 'piano-base'.
    await tester.tap(find.text('Seleziona Piano').first);
    await tester.pumpAndSettle();

    expect(spy.sottoscritto, 'piano-base');
  });
}
