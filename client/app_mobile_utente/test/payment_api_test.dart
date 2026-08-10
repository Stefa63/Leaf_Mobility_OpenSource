// Test del cablaggio metodo di pagamento al backend (UT.11) — Task 3.
//
// La conferma del form invia la carta al backend (POST /profilo/pagamenti) con
// mese/anno derivati dalla scadenza MM/AA, e localmente persiste solo il numero
// mascherato: il PAN in chiaro non deve mai essere salvato sul client.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_mobile_utente/api/profilo_repository.dart';
import 'package:app_mobile_utente/profile_store.dart';
import 'package:app_mobile_utente/screens/sensitive_data_screen.dart';

/// Repository profilo fittizio che cattura i dati della carta inviati.
class _SpyProfilo implements ProfiloApi {
  String? numero;
  int? mese;
  int? anno;
  String? titolare;

  @override
  Future<Map<String, dynamic>> registraPagamento({
    required String numero,
    required int mese,
    required int anno,
    required String titolare,
    required String cvv,
    required String indirizzoFatturazione,
  }) async {
    this.numero = numero;
    this.mese = mese;
    this.anno = anno;
    this.titolare = titolare;
    return {'id_metodo': 'm1', 'pan_mascherato': '•••• •••• •••• 1111'};
  }

  @override
  Future<Map<String, dynamic>> profilo() async => const {};
  @override
  Future<Map<String, dynamic>> aggiorna(Map<String, dynamic> modifiche) async =>
      const {};
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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ProfileStore.cardHolder.value = '';
    ProfileStore.cardNumber.value = '';
    ProfileStore.cardExpiry.value = '';
  });

  testWidgets('Registra la carta al backend senza persistere il PAN (UT.11)', (
    tester,
  ) async {
    final spy = _SpyProfilo();
    await tester.pumpWidget(
      MaterialApp(home: SensitiveDataScreen(profilo: spy)),
    );
    await tester.pumpAndSettle();

    // Entra in modifica del metodo di pagamento.
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    // Compila i campi nell'ordine del form: intestatario, numero, scadenza,
    // CVV e indirizzo di fatturazione (validazione stretta, punto 4).
    final campi = find.byType(TextField);
    await tester.enterText(campi.at(0), 'Mario Rossi');
    await tester.enterText(campi.at(1), '4111111111111111');
    await tester.enterText(campi.at(2), '08/27');
    await tester.enterText(campi.at(3), '123');
    await tester.enterText(campi.at(4), 'Via Roma 1, Bari');
    await tester.pumpAndSettle();

    // Conferma (icona di spunta).
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    // Il backend ha ricevuto i dati corretti, con mese/anno derivati da MM/AA.
    expect(spy.numero, '4111111111111111');
    expect(spy.mese, 8);
    expect(spy.anno, 2027);
    expect(spy.titolare, 'Mario Rossi');

    // Il PAN in chiaro non è stato persistito localmente: solo il mascherato.
    expect(ProfileStore.cardNumber.value, '•••• •••• •••• 1111');
    expect(ProfileStore.cardNumber.value.contains('4111'), isFalse);
  });
}
