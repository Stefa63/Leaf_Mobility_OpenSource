// Widget test del logout reale della console OP/PA.
//
// Selezionando "Logout" dalla tendina del profilo, lo shell chiama
// AuthApi.esci() (POST /auth/logout + cancellazione token) e naviga a /login.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:web_dashboard/api/auth_repository.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/theme.dart';
import 'package:web_dashboard/widgets/dashboard_shell.dart';

/// @brief AuthApi fittizia che registra la chiamata di logout.
class _SpyAuth implements AuthApi {
  bool uscito = false;

  @override
  Future<void> esci() async => uscito = true;

  @override
  Future<EsitoAccesso> accedi(String identita, String password) async =>
      throw UnimplementedError();

  @override
  Future<EsitoAccesso> verificaMfa(String idAccount, String otp) async =>
      throw UnimplementedError();

  @override
  Future<void> richiediReset(String identita) async {}

  @override
  Future<EsitoAccesso> confermaReset(String identita, String codice, [String? nuovaPassword]) async => throw UnimplementedError();

  @override
  Future<void> cambiaPasswordPrimoAccesso(String nuovaPassword) async {}
}

Future<void> pumpShell(WidgetTester tester, AuthApi auth) async {
  await tester.binding.setSurfaceSize(const Size(1400, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      // textScaler 0.8 compensa il font "Ahem" dei widget test (glifi a
      // larghezza piena), evitando overflow nella tendina del profilo.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(0.8),
        ),
        child: child!,
      ),
      routes: {
        '/login': (_) => const Scaffold(body: Text('PAGINA LOGIN')),
      },
      home: DashboardShell(
        accent: AppTheme.opAccent,
        profileLabel: 'Operatore',
        sections: [
          DashboardSection(
            icon: Icons.home,
            label: 'Home',
            builder: (_) => const Text('Contenuto Home'),
          ),
        ],
        profileBuilder: (_) => const Text('Profilo'),
        notificationsBuilder: (_) => const Text('Notifiche'),
        settingsBuilder: (_) => const Text('Impostazioni'),
        auth: auth,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    appLanguage.value = 'it';
  });

  testWidgets('Logout chiama esci() e naviga a /login', (tester) async {
    final spy = _SpyAuth();
    await pumpShell(tester, spy);

    // Apre la tendina del profilo e seleziona "Logout".
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout').last);
    await tester.pumpAndSettle();

    expect(spy.uscito, isTrue);
    expect(find.text('PAGINA LOGIN'), findsOneWidget);
  });
}
