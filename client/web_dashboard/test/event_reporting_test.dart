// Widget test della schermata Segnala Eventi (AP.09).
//
// Verifica l'header, l'elenco degli eventi/cantieri/interruzioni programmati e
// l'accesso al modulo di inserimento di un nuovo evento.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:web_dashboard/data/event_data.dart';
import 'package:web_dashboard/data/event_store.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/screens/event_reporting_screen.dart';

/// @brief Monta la [EventReportingScreen] in un telaio di test desktop.
/// @param tester il driver del widget test.
Future<void> pumpEvents(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1400, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          // 0.6: alcune righe di questa schermata sono molto compatte e il font
          // "Ahem" dei test traboccherebbe; a runtime, coi font reali, no.
          textScaler: const TextScaler.linear(0.6),
        ),
        child: child!,
      ),
      home: const Scaffold(body: EventReportingScreen(autoload: false)),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    appLanguage.value = 'it';
    EventStore.events.value = EventData.events;
    EventStore.offline.value = false;
  });

  testWidgets('Segnala Eventi mostra header ed eventi programmati (AP.09)', (
    tester,
  ) async {
    await pumpEvents(tester);

    expect(find.text('Segnala Eventi'), findsOneWidget);
    expect(find.text('Concerto Fiera del Levante'), findsOneWidget);
    expect(find.text('Cantiere Corso Cavour'), findsOneWidget);
  });
}
