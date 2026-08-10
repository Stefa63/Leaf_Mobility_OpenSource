// Widget test della schermata di cambio password obbligatorio al primo accesso
// OP/PA (IIN-12). Inietta un AuthApi fittizio per verificare offline: validazione
// dei requisiti IIN-5, controllo di coincidenza, chiamata all'endpoint e chiusura
// con esito positivo.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:web_dashboard/api/auth_repository.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/screens/change_password_screen.dart';

/// @brief AuthApi fittizio: registra la password inviata al cambio (IIN-12).
class _FakeAuth implements AuthApi {
  /// Ultima password ricevuta dal cambio (null se mai chiamato).
  String? passwordRicevuta;

  @override
  Future<EsitoAccesso> accedi(String identita, String password) async =>
      EsitoAccesso(StatoAccesso.ok);

  @override
  Future<EsitoAccesso> verificaMfa(String idAccount, String otp) async =>
      EsitoAccesso(StatoAccesso.ok);

  @override
  Future<void> richiediReset(String identita) async {}

  @override
  Future<EsitoAccesso> confermaReset(String identita, String codice, [String? nuovaPassword]) async => EsitoAccesso(StatoAccesso.ok);

  @override
  Future<void> cambiaPasswordPrimoAccesso(String nuovaPassword) async {
    passwordRicevuta = nuovaPassword;
  }

  @override
  Future<void> esci() async {}
}

/// @brief Monta la [ChangePasswordScreen] dietro un pulsante che ne raccoglie l'esito.
Widget _buildApp(AuthApi auth, {void Function(bool?)? onEsito}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final esito = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangePasswordScreen(auth: auth),
                ),
              );
              onEsito?.call(esito);
            },
            child: const Text('APRI'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _apri(WidgetTester tester) async {
  await tester.tap(find.text('APRI'));
  await tester.pumpAndSettle();
}

Future<void> _compila(WidgetTester tester, String nuova, String conferma) async {
  await tester.enterText(
    find.widgetWithText(TextField, 'Nuova password'),
    nuova,
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Conferma password'),
    conferma,
  );
}

void main() {
  setUp(() {
    appLanguage.value = 'it';
  });

  testWidgets('Password debole è respinta (IIN-5)', (tester) async {
    final auth = _FakeAuth();
    await tester.pumpWidget(_buildApp(auth));
    await _apri(tester);

    await _compila(tester, 'debole', 'debole');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Imposta password'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('almeno 8 caratteri'),
      findsOneWidget,
    );
    expect(auth.passwordRicevuta, isNull);
    expect(find.byType(ChangePasswordScreen), findsOneWidget);
  });

  testWidgets('Password non coincidenti sono respinte', (tester) async {
    final auth = _FakeAuth();
    await tester.pumpWidget(_buildApp(auth));
    await _apri(tester);

    await _compila(tester, 'Password1!', 'Password2!');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Imposta password'));
    await tester.pumpAndSettle();

    expect(find.text('Le due password non coincidono.'), findsOneWidget);
    expect(auth.passwordRicevuta, isNull);
  });

  testWidgets('Password valida invia il cambio e chiude con true (IIN-12)', (
    tester,
  ) async {
    final auth = _FakeAuth();
    bool? esito;
    await tester.pumpWidget(_buildApp(auth, onEsito: (e) => esito = e));
    await _apri(tester);

    await _compila(tester, 'NuovaForte1!', 'NuovaForte1!');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Imposta password'));
    await tester.pumpAndSettle();

    expect(auth.passwordRicevuta, 'NuovaForte1!');
    expect(esito, isTrue);
    expect(find.byType(ChangePasswordScreen), findsNothing);
  });
}
