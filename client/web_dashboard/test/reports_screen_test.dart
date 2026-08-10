// Widget test della Reportistica (report periodici aggregati sulla mobilità).
//
// Monta la ReportsScreen su superficie desktop e verifica l'header, i grafici
// aggregati (fl_chart) e i comandi di esportazione PDF/CSV (stub pre-backend).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:web_dashboard/api/analytics_repository.dart';
import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/screens/reports_screen.dart';

/// @brief AnalyticsApi fittizia: aggregati deterministici, nessuna rete.
class _FakeAnalytics implements AnalyticsApi {
  @override
  Future<List<Map<String, dynamic>>> perTipo({
    String? dallaData,
    String? allaData,
  }) async => [
    {
      'tipo_mezzo': 'monopattino',
      'num_corse': 120,
      'km_totali': 240.0,
      'durata_media_min': 9.0,
      'co2_risparmiata_kg': 40.0,
    },
  ];

  // Sezioni flussi (AP.02) e percentuali operative (AP.03) non esposte da questo
  // fake: restano sui dati di riserva mock (IIN-6), come asserito dai test.
  @override
  Future<Map<String, dynamic>> flussiOrari({
    String? dallaData,
    String? allaData,
  }) async => throw LeafApiException('non disponibile nei test');

  @override
  Future<Map<String, dynamic>> percentualiOperativi() async =>
      throw LeafApiException('non disponibile nei test');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} non usato nei test');
}

/// @brief Monta la [ReportsScreen] in un telaio di test desktop.
///
/// `textScaler` 0.8 compensa il font "Ahem" dei widget test (glifi a larghezza
/// piena) evitando overflow di pochi pixel su etichette compatte; a runtime,
/// con i font reali, l'overflow non esiste.
/// @param tester il driver del widget test.
Future<void> pumpReports(WidgetTester tester) async {
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
      home: Scaffold(body: ReportsScreen(analytics: _FakeAnalytics())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    appLanguage.value = 'it'; // lingua deterministica per i finder (IIN-7)
  });

  testWidgets('La reportistica mostra header e comandi di export', (
    tester,
  ) async {
    await pumpReports(tester);

    expect(find.text('Reportistica'), findsOneWidget);
    expect(find.text('Esporta PDF'), findsOneWidget);
    expect(find.text('Esporta CSV'), findsOneWidget);
  });

  testWidgets('Esporta PDF mostra il feedback stub (pre-backend)', (
    tester,
  ) async {
    await pumpReports(tester);

    await tester.ensureVisible(find.text('Esporta PDF'));
    await tester.tap(find.text('Esporta PDF'));
    await tester.pump();

    expect(find.textContaining('in preparazione'), findsOneWidget);
  });

  testWidgets('I KPI usano i dati reali delle analitiche (AP.01/07)', (
    tester,
  ) async {
    await pumpReports(tester);

    // num_corse reale (120) come totale noleggi; CO₂ reale (40 kg).
    expect(find.text('120'), findsOneWidget);
    expect(find.text('40 kg'), findsOneWidget);
  });

  testWidgets('Solo le card mock portano il badge "dato stimato"', (
    tester,
  ) async {
    await pumpReports(tester);

    // Flussi orari e trend CO₂ a 6 mesi sono mock → due badge.
    // Noleggi per tipo e flotta sono reali/derivati da dati reali → nessun badge.
    expect(find.text('dato stimato'), findsNWidgets(2));
  });
}
