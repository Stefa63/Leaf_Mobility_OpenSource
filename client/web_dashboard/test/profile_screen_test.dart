// Widget test della Gestione Profilo (console OP/AP).
//
// Verifica l'header e l'adattamento dei contenuti al ruolo di sessione
// (Operatore vs Amministrazione Pubblica).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:web_dashboard/api/profilo_repository.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/theme.dart';
import 'package:web_dashboard/session.dart';
import 'package:web_dashboard/screens/profile_screen.dart';

/// @brief ProfiloApi fittizia: dati anagrafici deterministici, nessuna rete.
class _FakeProfilo implements ProfiloApi {
  @override
  Future<Map<String, dynamic>> profilo() async => {
    'nome': 'Mario',
    'cognome': 'Rossi',
    'email': 'operatore@leaf.it',
    'telefono': '+39 080 000 0000',
  };

  @override
  Future<Map<String, dynamic>> aggiorna(Map<String, dynamic> modifiche) async =>
      modifiche;
}

/// @brief Monta la [ProfileScreen] in un telaio di test desktop.
/// @param accent il colore d'accento coerente col ruolo.
/// @param tester il driver del widget test.
Future<void> pumpProfile(WidgetTester tester, Color accent) async {
  await tester.binding.setSurfaceSize(const Size(1400, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(0.8),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: ProfileScreen(accent: accent, profilo: _FakeProfilo()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    appLanguage.value = 'it';
  });

  testWidgets('Gestione Profilo (Operatore) mostra header e dati operatore', (
    tester,
  ) async {
    Session.role = DashboardRole.operator;
    await pumpProfile(tester, AppTheme.opAccent);

    expect(find.text('Gestione Profilo'), findsOneWidget);
    expect(find.text('Centro Operativo LEAF'), findsOneWidget);
  });

  testWidgets('Gestione Profilo (AP) adatta i contenuti al ruolo pubblico', (
    tester,
  ) async {
    Session.role = DashboardRole.publicAdmin;
    await pumpProfile(tester, AppTheme.apAccent);

    expect(find.text('Gestione Profilo'), findsOneWidget);
    expect(find.text('Assessorato alla Mobilità'), findsOneWidget);
  });
}
