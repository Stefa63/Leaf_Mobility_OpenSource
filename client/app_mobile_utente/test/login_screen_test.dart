// Widget test della schermata di Login cablata al backend (UT.23, UT.24, IIN-1, IIN-9).
//
// Inietta un AuthApi fittizio per verificare, in modo deterministico e offline:
// presenza dei campi, accesso UT diretto, passo MFA (IIN-9), feedback di reset,
// gestione dell'errore di credenziali e navigazione verso la registrazione.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/api/api_client.dart';
import 'package:app_mobile_utente/api/auth_repository.dart';
import 'package:app_mobile_utente/screens/login_screen.dart';
import 'package:app_mobile_utente/screens/registration_screen.dart';
import 'package:app_mobile_utente/screens/reset_password_screen.dart';

/// @brief AuthApi fittizio a esiti programmabili (nessuna rete).
class _FakeAuth implements AuthApi {
  _FakeAuth({
    this.esitoAccedi,
    this.erroreAccesso = false,
    this.erroreLimiteDispositivi = false,
  });

  /// Esito restituito da [accedi] (default: ok UT).
  final EsitoAccesso? esitoAccedi;

  /// Se true, [accedi] solleva un errore di credenziali (401).
  final bool erroreAccesso;

  /// Se true, [accedi] solleva il 403 di limite dispositivi superato (IIN-14).
  final bool erroreLimiteDispositivi;

  bool resetChiamato = false;

  @override
  Future<EsitoAccesso> accedi(
    String identita,
    String password, {
    String? dispositivo,
  }) async {
    if (erroreLimiteDispositivi) {
      throw LeafApiException('limite_dispositivi_superato', codice: 403);
    }
    if (erroreAccesso) {
      throw LeafApiException('Credenziali non valide', codice: 401);
    }
    return esitoAccedi ??
        EsitoAccesso(StatoAccesso.ok, idAccount: 'u1', ruolo: 'UT');
  }

  @override
  Future<EsitoAccesso> confermaReset(
    String identita,
    String codice,
    String nuovaPassword,
  ) async {
    return EsitoAccesso(StatoAccesso.ok, idAccount: 'u1', ruolo: 'UT');
  }

  @override
  Future<EsitoAccesso> verificaMfa(
    String idAccount,
    String otp, {
    String? dispositivo,
  }) async {
    return EsitoAccesso(StatoAccesso.ok, idAccount: idAccount, ruolo: 'OP');
  }

  @override
  Future<void> registra(
    String email,
    String username,
    String password, {
    String? dataNascita,
    String? nome,
    String? cognome,
    String? residenza,
  }) async {}

  @override
  Future<void> richiediReset(String identita) async {
    resetChiamato = true;
  }

  @override
  Future<void> esci() async {}
}

/// @brief Monta la [LoginScreen] con l'auth iniettato in una MaterialApp di test.
Widget buildLoginApp(AuthApi auth) {
  return MaterialApp(
    home: LoginScreen(auth: auth),
    routes: {
      '/home': (context) => const Scaffold(body: Text('HOME_STUB')),
    },
  );
}

Future<void> _compilaCredenziali(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextField, 'Email'),
    'utente@example.com',
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Password'),
    'Password1!',
  );
}

void main() {
  setUp(() {
    appLanguage.value = 'it';
  });

  testWidgets('La login mostra i campi credenziali e le azioni (IIN-1)', (
    tester,
  ) async {
    await tester.pumpWidget(buildLoginApp(_FakeAuth()));

    expect(find.text('Benvenuto in Leaf Mobility'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Accedi'), findsOneWidget);
    expect(find.text('Password dimenticata?'), findsOneWidget);
    expect(find.text('Nuovo utente? Registrati'), findsOneWidget);
  });

  testWidgets('Il campo Password e\' oscurato', (tester) async {
    await tester.pumpWidget(buildLoginApp(_FakeAuth()));

    final passwordField = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Password'),
    );
    expect(passwordField.obscureText, isTrue);
  });

  testWidgets('Accedi UT valido naviga alla home (UT.23/IIN-1)', (tester) async {
    await tester.pumpWidget(buildLoginApp(_FakeAuth()));

    await _compilaCredenziali(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Accedi'));
    await tester.pumpAndSettle();

    expect(find.text('HOME_STUB'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('Login OP mostra il passo OTP (MFA, IIN-9)', (tester) async {
    final auth = _FakeAuth(
      esitoAccedi: EsitoAccesso(
        StatoAccesso.mfaRichiesta,
        idAccount: 'op1',
        otpSimulato: '123456',
      ),
    );
    await tester.pumpWidget(buildLoginApp(auth));

    await _compilaCredenziali(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Accedi'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Codice OTP'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Verifica codice'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Codice OTP'), '123456');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Verifica codice'));
    await tester.pumpAndSettle();

    expect(find.text('HOME_STUB'), findsOneWidget);
  });

  testWidgets('Credenziali errate mostrano il banner d\'errore (IIN-1)', (
    tester,
  ) async {
    await tester.pumpWidget(buildLoginApp(_FakeAuth(erroreAccesso: true)));

    await _compilaCredenziali(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Accedi'));
    await tester.pumpAndSettle();

    expect(
      find.text('Credenziali non valide. Controlla email e password.'),
      findsOneWidget,
    );
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Limite dispositivi (403) mostra il messaggio dedicato (IIN-14)', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildLoginApp(_FakeAuth(erroreLimiteDispositivi: true)),
    );

    await _compilaCredenziali(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Accedi'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Limite dispositivi raggiunto. '
        'Disconnetti un altro dispositivo per continuare.',
      ),
      findsOneWidget,
    );
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('HOME_STUB'), findsNothing);
  });

  testWidgets('Password dimenticata apre la ResetPasswordScreen (UT.24)', (
    tester,
  ) async {
    final auth = _FakeAuth();
    await tester.pumpWidget(buildLoginApp(auth));

    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'utente@example.com',
    );
    await tester.tap(find.text('Password dimenticata?'));
    await tester.pumpAndSettle();

    expect(find.byType(ResetPasswordScreen), findsOneWidget);
  });

  testWidgets('Nuovo utente? Registrati apre la RegistrationScreen', (
    tester,
  ) async {
    await tester.pumpWidget(buildLoginApp(_FakeAuth()));

    await tester.tap(find.text('Nuovo utente? Registrati'));
    await tester.pumpAndSettle();

    expect(find.byType(RegistrationScreen), findsOneWidget);
  });
}
