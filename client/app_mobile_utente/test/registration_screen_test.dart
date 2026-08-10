// Widget test della schermata di Registrazione cablata al backend (UT.22.1).
//
// Inietta un AuthApi fittizio per verificare offline: presenza dei campi richiesti,
// oscuramento password, invio della registrazione e ritorno al login al successo,
// gestione dell'errore di dominio (es. email già in uso / password debole).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/api/api_client.dart';
import 'package:app_mobile_utente/api/auth_repository.dart';
import 'package:app_mobile_utente/screens/registration_screen.dart';

/// @brief AuthApi fittizio: registra() può completare o sollevare un errore.
class _FakeAuth implements AuthApi {
  _FakeAuth({this.errore});

  /// Messaggio d'errore da sollevare in [registra], o null per successo.
  final String? errore;

  bool registraChiamato = false;

  /// Data di nascita ISO ricevuta da [registra] (verifica forward UT.22.1).
  String? dataNascitaRicevuta;

  @override
  Future<void> registra(
    String email,
    String username,
    String password, {
    String? dataNascita,
    String? nome,
    String? cognome,
    String? residenza,
  }) async {
    registraChiamato = true;
    dataNascitaRicevuta = dataNascita;
    if (errore != null) throw LeafApiException(errore!, codice: 409);
  }

  @override
  Future<EsitoAccesso> accedi(
    String identita,
    String password, {
    String? dispositivo,
  }) async =>
      EsitoAccesso(StatoAccesso.ok);

  @override
  Future<EsitoAccesso> verificaMfa(
    String idAccount,
    String otp, {
    String? dispositivo,
  }) async =>
      EsitoAccesso(StatoAccesso.ok);

  @override
  Future<void> richiediReset(String identita) async {}

  @override
  Future<EsitoAccesso> confermaReset(
    String identita,
    String codice,
    String nuovaPassword,
  ) async =>
      EsitoAccesso(StatoAccesso.ok);


  @override
  Future<void> esci() async {}
}

/// @brief Monta la [RegistrationScreen] su uno stack con un login stub sottostante.
///
/// Lo stack `['/', '/reg']` consente di verificare il `pop` di ritorno al login
/// dopo una registrazione riuscita (UT.22 → UT.23).
Widget buildRegistrationApp(AuthApi auth) {
  return MaterialApp(
    initialRoute: '/reg',
    routes: {
      '/': (_) => const Scaffold(body: Text('LOGIN_STUB')),
      '/reg': (_) => RegistrationScreen(auth: auth),
    },
  );
}

Future<void> _compila(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextField, 'Email'),
    'nuovo.utente@example.com',
  );
  await tester.enterText(find.widgetWithText(TextField, 'Username'), 'nuovo');
  await tester.enterText(find.widgetWithText(TextField, 'Nome'), 'Mario');
  await tester.enterText(find.widgetWithText(TextField, 'Cognome'), 'Rossi');
  await tester.enterText(
    find.widgetWithText(TextField, 'Residenza (via di fatturazione)'),
    'Via Roma 1, Bari',
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Password'),
    'Password1!',
  );
  // Seleziona la data di nascita dal date picker (obbligatoria, UT.22.1).
  final dataField = find.widgetWithText(TextField, 'Data di nascita');
  await tester.ensureVisible(dataField);
  await tester.tap(dataField);
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    appLanguage.value = 'it';
  });

  testWidgets('La registrazione mostra i campi richiesti (UT.22.1)', (
    tester,
  ) async {
    await tester.pumpWidget(buildRegistrationApp(_FakeAuth()));

    expect(find.text('Completa il tuo profilo'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Username'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Data di nascita'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Registrati'), findsOneWidget);
  });

  testWidgets('Il campo Password della registrazione e\' oscurato', (
    tester,
  ) async {
    await tester.pumpWidget(buildRegistrationApp(_FakeAuth()));

    final passwordField = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Password'),
    );
    expect(passwordField.obscureText, isTrue);
  });

  testWidgets('Registrati invia la registrazione e mostra conferma (UT.22.1)', (
    tester,
  ) async {
    final auth = _FakeAuth();
    await tester.pumpWidget(buildRegistrationApp(auth));

    await _compila(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Registrati'));
    await tester.pumpAndSettle();

    expect(auth.registraChiamato, isTrue);
    // La data di nascita selezionata viene inoltrata in ISO al backend (UT.22.1).
    expect(auth.dataNascitaRicevuta, isNotNull);
    expect(auth.dataNascitaRicevuta, matches(r'^\d{4}-\d{2}-\d{2}$'));
    // Al successo si torna al login (UT.22 → UT.23).
    expect(find.text('LOGIN_STUB'), findsOneWidget);
    expect(find.byType(RegistrationScreen), findsNothing);
  });

  testWidgets('Un errore di dominio resta in schermata col banner (409)', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildRegistrationApp(_FakeAuth(errore: 'Email già registrata')),
    );

    await _compila(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Registrati'));
    await tester.pumpAndSettle();

    expect(find.text('Email già registrata'), findsOneWidget);
    expect(find.byType(RegistrationScreen), findsOneWidget);
  });
}
