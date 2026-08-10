// Widget test della schermata Impostazioni della console.
//
// Verifica l'header, la sezione lingua e i controlli di preferenza
// (le azioni con backend sono stub pre-backend).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/theme.dart';
import 'package:web_dashboard/screens/settings_screen.dart';

/// @brief Monta la [SettingsScreen] in un telaio di test desktop.
/// @param tester il driver del widget test.
Future<void> pumpSettings(WidgetTester tester) async {
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
      home: const Scaffold(body: SettingsScreen(accent: AppTheme.opAccent)),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    appLanguage.value = 'it';
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Impostazioni mostra header e sezione lingua', (tester) async {
    await pumpSettings(tester);
    await tester.pump();

    expect(find.text('Impostazioni'), findsOneWidget);
    expect(find.text('Lingua'), findsOneWidget);
    expect(find.text('Italiano'), findsWidgets);
  });

  testWidgets('Un toggle modificato viene persistito e ricaricato', (
    tester,
  ) async {
    // Carica le preferenze (initState) e attende la prima resa.
    await pumpSettings(tester);
    await tester.pumpAndSettle();

    // "Testo ingrandito" parte spento: lo accendo. Risalgo al Row più interno
    // del tile (`.first` = ancestor più vicino) per isolarne lo Switch.
    final switchTrovato = find.descendant(
      of: find
          .ancestor(
            of: find.text('Testo ingrandito'),
            matching: find.byType(Row),
          )
          .first,
      matching: find.byType(Switch),
    );
    expect(switchTrovato, findsOneWidget);
    expect(tester.widget<Switch>(switchTrovato).value, isFalse);
    await tester.tap(switchTrovato);
    await tester.pumpAndSettle();

    // Il valore è ora persistito nell'archivio mock.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('impostazioni.testo_ingrandito'), isTrue);

    // Rimonto la schermata: il valore persistito viene ricaricato all'avvio.
    await pumpSettings(tester);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(switchTrovato).value, isTrue);
  });
}
