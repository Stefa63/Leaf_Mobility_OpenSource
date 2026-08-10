// Widget test della login OP/PA cablata su /api/v1/auth con MFA reale a due passi
// (IIN-9, IIN-5, RBAC). L'AuthApi è iniettato (fittizio): primo passo credenziali
// → secondo passo OTP → token e instradamento secondo il ruolo del backend.
//
// La route `/home` è una stub: la HomeRouter reale monta le dashboard con mappa,
// coperte dai test dedicati.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:web_dashboard/api/auth_repository.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/screens/login_screen.dart';
import 'package:web_dashboard/session.dart';

/// @brief AuthApi fittizio: richiede sempre MFA e poi concede il ruolo impostato.
class _FakeAuth implements AuthApi {
  _FakeAuth({this.ruolo = 'OP'});

  /// Ruolo restituito a verifica OTP riuscita ("OP"/"PA").
  String ruolo;

  @override
  Future<EsitoAccesso> accedi(String identita, String password) async =>
      EsitoAccesso(StatoAccesso.mfaRichiesta, idAccount: 'acc1');

  @override
  Future<EsitoAccesso> verificaMfa(String idAccount, String otp) async =>
      EsitoAccesso(StatoAccesso.ok, ruolo: ruolo);

  @override
  Future<void> richiediReset(String identita) async {}

  @override
  Future<EsitoAccesso> confermaReset(String identita, String codice, [String? nuovaPassword]) async => EsitoAccesso(StatoAccesso.ok);

  @override
  Future<void> cambiaPasswordPrimoAccesso(String nuovaPassword) async {}

  @override
  Future<void> esci() async {}
}

/// @brief Monta la [LoginScreen] con AuthApi iniettato e route `/home` fittizia.
Widget buildLoginApp(AuthApi auth) {
  return MaterialApp(
    home: LoginScreen(auth: auth),
    routes: {
      '/home': (context) => const Scaffold(body: Text('CONSOLE_STUB')),
    },
  );
}

/// @brief Compila email/password e preme Accedi (primo passo).
Future<void> inviaCredenziali(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextField, 'Email'),
    'operatore@leafmobility.it',
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Password'),
    'Password1!',
  );
  await tester.tap(find.widgetWithText(ElevatedButton, 'Accedi'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    appLanguage.value = 'it';
    Session.role = DashboardRole.operator;
    Session.email = '';
  });

  testWidgets('Senza OTP valido l\'accesso è negato (IIN-9)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildLoginApp(_FakeAuth()));
    await tester.pumpAndSettle();

    await inviaCredenziali(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Codice OTP'), '123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Verifica'));
    await tester.pumpAndSettle();

    expect(find.text('Inserisci un codice OTP a 6 cifre.'), findsOneWidget);
    expect(find.text('CONSOLE_STUB'), findsNothing);
    expect(Session.email, isEmpty);
  });

  testWidgets('OTP a 6 cifre + ruolo OP: Session aggiornata e accesso (IIN-9)', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildLoginApp(_FakeAuth(ruolo: 'OP')));
    await tester.pumpAndSettle();

    await inviaCredenziali(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Codice OTP'),
      '123456',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Verifica'));
    await tester.pumpAndSettle();

    expect(find.text('CONSOLE_STUB'), findsOneWidget);
    expect(Session.role, DashboardRole.operator);
    expect(Session.isPublicAdmin, isFalse);
    expect(Session.email, 'operatore@leafmobility.it');
  });

  testWidgets('Il ruolo PA dal backend instrada come publicAdmin (RBAC)', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildLoginApp(_FakeAuth(ruolo: 'PA')));
    await tester.pumpAndSettle();

    await inviaCredenziali(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Codice OTP'),
      '654321',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Verifica'));
    await tester.pumpAndSettle();

    expect(find.text('CONSOLE_STUB'), findsOneWidget);
    expect(Session.role, DashboardRole.publicAdmin);
    expect(Session.isPublicAdmin, isTrue);
  });

  testWidgets('Il campo OTP accetta solo cifre', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildLoginApp(_FakeAuth()));
    await tester.pumpAndSettle();

    await inviaCredenziali(tester); // porta al passo OTP
    await tester.enterText(
      find.widgetWithText(TextField, 'Codice OTP'),
      'ab12cd34',
    );
    await tester.pump();

    final otpField = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Codice OTP'),
    );
    expect(otpField.controller!.text, '1234');
  });
}
