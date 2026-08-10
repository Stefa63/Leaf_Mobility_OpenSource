// Test della gestione abbonamenti cablata a GET /profilo/abbonamenti (UT.18/UT.21).
//
// La card di stato mostra l'abbonamento attivo reale (piano, stato, residuo) o
// lo stato vuoto quando non ce ne sono.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile_utente/api/profilo_repository.dart';
import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/screens/subscription_manager_screen.dart';

/// Repository profilo fittizio con un elenco abbonamenti configurabile.
class _FakeProfilo implements ProfiloApi {
  _FakeProfilo(this._abbonamenti);
  final List<Map<String, dynamic>> _abbonamenti;

  @override
  Future<List<Map<String, dynamic>>> abbonamenti() async => _abbonamenti;

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
  Future<Map<String, dynamic>> sottoscriviAbbonamento(String idPiano) async =>
      const {};
  @override
  Future<Map<String, dynamic>> caricaKyc({
    required String tipo,
    required String nomeFile,
  }) async => const {};
}

void main() {
  setUp(() => appLanguage.value = 'it');

  testWidgets('Mostra l\'abbonamento attivo reale (UT.18/UT.21)', (
    tester,
  ) async {
    final ora = DateTime.now();
    final fake = _FakeProfilo([
      {
        'id_piano': 'piano-plus',
        'stato': 'attivo',
        'data_inizio': ora.subtract(const Duration(days: 10)).toIso8601String(),
        'data_fine': ora.add(const Duration(days: 20)).toIso8601String(),
        'prezzo_cent': 1999,
      },
    ]);

    await tester.pumpWidget(
      MaterialApp(home: SubscriptionManagerScreen(profilo: fake)),
    );
    await tester.pumpAndSettle();

    expect(find.text('LEAF Plus'), findsOneWidget);
    expect(find.text('Abbonamento attivo'), findsOneWidget);
    expect(find.text('Rimanente'), findsOneWidget);
  });

  testWidgets('Senza abbonamenti mostra lo stato vuoto (UT.18)', (tester) async {
    final fake = _FakeProfilo(const []);

    await tester.pumpWidget(
      MaterialApp(home: SubscriptionManagerScreen(profilo: fake)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nessun abbonamento attivo.'), findsOneWidget);
  });
}
