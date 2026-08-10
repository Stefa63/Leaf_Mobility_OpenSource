// Test del cablaggio profilo al backend (UT.21) — FASE 2.B.
//
// All'apertura, AccountScreen carica il profilo dal repository e popola i campi.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile_utente/api/profilo_repository.dart';
import 'package:app_mobile_utente/screens/account_screen.dart';

/// Repository profilo fittizio con dati deterministici.
class _FakeProfilo implements ProfiloApi {
  @override
  Future<Map<String, dynamic>> profilo() async => {
    'nome': 'Giulia',
    'cognome': 'Bianchi',
    'email': 'giulia.bianchi@example.com',
    'telefono': '+39 320 0000000',
  };

  @override
  Future<Map<String, dynamic>> aggiorna(Map<String, dynamic> modifiche) async =>
      modifiche;

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

  @override
  Future<List<Map<String, dynamic>>> abbonamenti() async => const [];
}

void main() {
  testWidgets('AccountScreen popola i campi dal profilo del backend (UT.21)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: AccountScreen(profilo: _FakeProfilo())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Giulia'), findsOneWidget);
    expect(find.text('Bianchi'), findsOneWidget);
    expect(find.text('giulia.bianchi@example.com'), findsOneWidget);
  });
}
