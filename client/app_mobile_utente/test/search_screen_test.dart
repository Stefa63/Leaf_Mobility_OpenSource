// Widget test della schermata di ricerca percorso (UT.05, UT.07) — Cascata B.
//
// La ricerca è cablata al backend: suggerimenti da `/geocoding` e opzioni di
// percorso da `/percorsi`. I repository sono iniettati con fake deterministici
// (nessuna rete): si verificano cronologia iniziale, autocompletamento,
// "nessun risultato" e la comparsa dei percorsi reali (incluso il TPL).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/api/routing_repository.dart';
import 'package:app_mobile_utente/api/veicoli_repository.dart';
import 'package:app_mobile_utente/screens/search_screen.dart';

/// Routing fittizio: gazetteer ridotto in memoria, nessuna rete.
class _FakeRouting implements RoutingApi {
  @override
  Future<List<LuogoSuggerito>> suggerisci(String query) async {
    const tutti = [
      LuogoSuggerito(nome: 'Lungomare di Bari', lat: 41.1258, lon: 16.8760),
      LuogoSuggerito(nome: 'Stazione Bari Centrale', lat: 41.1171, lon: 16.8719),
      LuogoSuggerito(nome: 'Fiera del Levante', lat: 41.1330, lon: 16.8480),
      LuogoSuggerito(
        nome: 'Aeroporto Karol Wojtyla – Bari',
        lat: 41.1389,
        lon: 16.7606,
      ),
    ];
    final q = query.toLowerCase();
    return tutti.where((l) => l.nome.toLowerCase().contains(q)).toList();
  }

  @override
  Future<Map<String, dynamic>> percorsi({
    String? da,
    String? a,
    double? daLat,
    double? daLon,
    double? aLat,
    double? aLon,
  }) async {
    return {
      'origine': {'lat': 41.1171, 'lon': 16.8719},
      'destinazione': {'lat': 41.1330, 'lon': 16.8480},
      'percorsi': [
        {
          'modalita': 'sharing',
          'nome': 'Percorso diretto',
          'descrizione': 'Percorso più diretto con un mezzo in sharing',
          'ha_tpl': false,
          'tipo_consigliato': 'ebike',
          'distanza_m': 2800.0,
          'durata_min': 9.3,
          'distanza_km': 2.8,
        },
        {
          'modalita': 'tpl',
          'nome': 'Con TPL integrato',
          'descrizione': 'Mezzo in sharing + trasporto pubblico locale',
          'ha_tpl': true,
          'tipo_consigliato': 'ebike',
          'distanza_m': 2800.0,
          'durata_min': 7.0,
          'distanza_km': 2.8,
        },
      ],
      'totale': 2,
    };
  }
}

/// Veicoli fittizi: nessun mezzo disponibile (i mezzi consigliati restano vuoti).
class _FakeVeicoli implements VeicoliApi {
  @override
  Future<List<Map<String, dynamic>>> disponibili({double? lat, double? lon}) async => const [];

  @override
  Future<List<Map<String, dynamic>>> stazioni() async => const [];
}

/// @brief Monta la [SearchScreen] con repository fittizi.
/// @return il widget radice da passare a `pumpWidget`.
Widget buildSearchApp() {
  return MaterialApp(
    home: SearchScreen(routing: _FakeRouting(), veicoli: _FakeVeicoli()),
  );
}

/// @brief Compila partenza (via suggerimento) e arrivo (digitato).
/// @param tester il driver del widget test.
Future<void> fillBothFields(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).first, 'Stazione');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Stazione Bari Centrale').last);
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextField).at(1), 'Fiera del Levante');
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    // Lingua deterministica per i finder testuali (IIN-7).
    appLanguage.value = 'it';
  });

  testWidgets('All\'apertura mostra le ricerche recenti', (tester) async {
    await tester.pumpWidget(buildSearchApp());
    await tester.pump();

    expect(find.text('RICERCHE RECENTI'), findsOneWidget);
    expect(find.text('Stazione Bari Centrale'), findsOneWidget);
    expect(find.text('Lungomare di Bari'), findsOneWidget);
  });

  testWidgets('La digitazione interroga i suggerimenti (UT.07)', (tester) async {
    await tester.pumpWidget(buildSearchApp());

    await tester.enterText(find.byType(TextField).first, 'lungo');
    await tester.pumpAndSettle();

    expect(find.text('SUGGERIMENTI'), findsOneWidget);
    expect(find.text('Lungomare di Bari'), findsOneWidget);
    expect(find.text('Aeroporto Karol Wojtyla – Bari'), findsNothing);
  });

  testWidgets('Query senza corrispondenze mostra "Nessun risultato."', (
    tester,
  ) async {
    await tester.pumpWidget(buildSearchApp());

    await tester.enterText(find.byType(TextField).first, 'xyzabc');
    await tester.pumpAndSettle();

    expect(find.text('Nessun risultato.'), findsOneWidget);
  });

  testWidgets('Partenza+arrivo compilati mostrano i percorsi reali con TPL (UT.07)', (
    tester,
  ) async {
    await tester.pumpWidget(buildSearchApp());
    await fillBothFields(tester);

    expect(find.text('Percorso diretto'), findsOneWidget);
    expect(find.text('Con TPL integrato'), findsOneWidget);
    // Il percorso multimodale espone il badge TPL (sistemaTPL integrato).
    expect(find.text('TPL'), findsOneWidget);
  });

  testWidgets('Il pulsante di swap inverte partenza e arrivo', (tester) async {
    await tester.pumpWidget(buildSearchApp());
    await fillBothFields(tester);

    await tester.tap(find.byIcon(Icons.swap_vert));
    await tester.pumpAndSettle();

    final dep = tester.widget<TextField>(find.byType(TextField).first);
    final arr = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(dep.controller!.text, 'Fiera del Levante');
    expect(arr.controller!.text, 'Stazione Bari Centrale');
  });

  testWidgets('Cancella svuota entrambi i campi e torna alla cronologia', (
    tester,
  ) async {
    await tester.pumpWidget(buildSearchApp());
    await fillBothFields(tester);

    await tester.tap(find.text('Cancella'));
    await tester.pumpAndSettle();

    expect(find.text('RICERCHE RECENTI'), findsOneWidget);
    expect(find.text('Percorso diretto'), findsNothing);
  });
}
