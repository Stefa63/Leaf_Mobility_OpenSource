// Test unitari di ProfileStore (UT.21, UT.11, UT.22.2).
//
// Verifica che i salvataggi aggiornino i ValueNotifier osservati dalle viste
// e la persistenza locale (SharedPreferences, qui in modalita' mock con gli
// strumenti integrati del plugin: nessuna dipendenza aggiuntiva). Lo stato
// dello store, essendo statico, viene riportato ai valori di default tra un
// test e l'altro per evitare contaminazione.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_mobile_utente/profile_store.dart';

/// @brief Riporta tutti i campi di [ProfileStore] ai valori di fabbrica.
///
/// Necessario perche' lo store e' statico e condiviso fra i test.
void resetProfileStore() {
  ProfileStore.firstName.value = 'Mario';
  ProfileStore.lastName.value = 'Rossi';
  ProfileStore.email.value = 'mario.rossi@example.com';
  ProfileStore.address.value = 'Via Roma 1, 00100 Roma (RM)';
  ProfileStore.phone.value = '+39 333 1234567';
  ProfileStore.photoPath.value = null;
  ProfileStore.idCardPath.value = null;
  ProfileStore.licensePath.value = null;
  ProfileStore.cardHolder.value = '';
  ProfileStore.cardNumber.value = '';
  ProfileStore.cardExpiry.value = '';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    resetProfileStore();
  });

  test('savePersonalData aggiorna i notifier e persiste (UT.21)', () async {
    await ProfileStore.savePersonalData(
      firstNameValue: 'Anna',
      lastNameValue: 'Bianchi',
      emailValue: 'anna.bianchi@example.com',
      addressValue: 'Via Napoli 5, 70121 Bari (BA)',
      phoneValue: '+39 320 7654321',
    );

    expect(ProfileStore.firstName.value, 'Anna');
    expect(ProfileStore.lastName.value, 'Bianchi');
    expect(ProfileStore.email.value, 'anna.bianchi@example.com');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('profile.firstName'), 'Anna');
    expect(prefs.getString('profile.email'), 'anna.bianchi@example.com');
  });

  test('savePaymentMethod aggiorna i notifier e persiste (UT.11)', () async {
    await ProfileStore.savePaymentMethod(
      holder: 'Anna Bianchi',
      number: '4111111111111111',
      expiry: '12/27',
    );

    expect(ProfileStore.cardHolder.value, 'Anna Bianchi');
    expect(ProfileStore.cardExpiry.value, '12/27');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('profile.cardNumber'), '4111111111111111');
  });

  test('setIdCardPath persiste e azzera il documento (UT.22.2)', () async {
    await ProfileStore.setIdCardPath('/sandbox/id_card.png');
    expect(ProfileStore.idCardPath.value, '/sandbox/id_card.png');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('profile.idCardPath'), '/sandbox/id_card.png');

    await ProfileStore.setIdCardPath(null);
    expect(ProfileStore.idCardPath.value, isNull);
    expect(prefs.getString('profile.idCardPath'), isNull);
  });

  test('load ripristina i valori persistiti localmente', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'profile.firstName': 'Luca',
      'profile.lastName': 'Verdi',
      'profile.cardHolder': 'Luca Verdi',
    });

    await ProfileStore.load();

    expect(ProfileStore.firstName.value, 'Luca');
    expect(ProfileStore.lastName.value, 'Verdi');
    expect(ProfileStore.cardHolder.value, 'Luca Verdi');
    // Chiave assente → resta il default corrente.
    expect(ProfileStore.email.value, 'mario.rossi@example.com');
  });

  test('i notifier notificano gli ascoltatori al salvataggio', () async {
    var notified = 0;
    ProfileStore.firstName.addListener(() => notified++);

    await ProfileStore.savePersonalData(
      firstNameValue: 'Paola',
      lastNameValue: 'Rossi',
      emailValue: 'paola@example.com',
      addressValue: 'Via Bari 2',
      phoneValue: '+39 333 0000000',
    );

    expect(notified, 1);
  });
}
