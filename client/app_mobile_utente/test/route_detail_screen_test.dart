// Widget test della schermata di dettaglio percorso (UT.07, UT.08, UT.03).
//
// Verifica il riepilogo del percorso (durata, distanza, stima costo), il badge
// di integrazione TPL (UT.07), la modalità di trasporto e l'elenco dei mezzi
// consigliati con accesso alla scheda mezzo (UT.08). Nessuna piattaforma reale.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/screens/route_detail_screen.dart';
import 'package:app_mobile_utente/screens/vehicle_detail_screen.dart';

/// Mezzo consigliato campione per il percorso.
const VehicleData kRouteVehicle = VehicleData(
  id: 'SC-007',
  type: VehicleType.scooter,
  batteryPercent: 64,
  rangeKm: 33,
  distanceMeters: 150,
);

/// Percorso campione con integrazione TPL e un mezzo consigliato (UT.07/UT.08).
const RouteData kTestRoute = RouteData(
  name: 'Percorso veloce',
  description: 'Scooter fino alla fermata, poi bus.',
  durationMinutes: 15,
  distanceKm: 3.2,
  transportSummary: 'Scooter + TPL Bus',
  recommended: [kRouteVehicle],
  hasTpl: true,
);

/// @brief Monta la [RouteDetailScreen] del percorso campione in test.
/// @return il widget radice da passare a `pumpWidget`.
Widget buildRouteApp() {
  return const MaterialApp(
    home: RouteDetailScreen(
      route: kTestRoute,
      departure: 'Piazza Moro',
      arrival: 'Stazione Centrale',
    ),
  );
}

void main() {
  setUp(() {
    // Lingua deterministica per i finder testuali (IIN-7).
    appLanguage.value = 'it';
  });

  testWidgets('Il dettaglio mostra riepilogo, stima costo e badge TPL (UT.07/UT.03)', (
    tester,
  ) async {
    await tester.pumpWidget(buildRouteApp());

    expect(find.text('Piazza Moro'), findsOneWidget);
    expect(find.text('Stazione Centrale'), findsOneWidget);
    expect(find.text('15 min'), findsOneWidget);
    expect(find.text('3.2 km'), findsOneWidget);
    expect(find.text('~2.56 €'), findsOneWidget); // 3.2 * 0.8
    // Integrazione TPL disponibile (hasTpl == true).
    expect(find.text('Integrazione TPL disponibile'), findsOneWidget);
    expect(find.text('Scooter + TPL Bus'), findsOneWidget);
  });

  testWidgets('Il mezzo consigliato è elencato e apre la scheda (UT.08)', (
    tester,
  ) async {
    await tester.pumpWidget(buildRouteApp());

    // Tile del mezzo consigliato: tipo + id e caratteristiche.
    expect(find.textContaining('SC-007'), findsOneWidget);

    // Il pulsante info apre la VehicleDetailScreen.
    await tester.ensureVisible(find.byTooltip('Scheda mezzo'));
    await tester.tap(find.byTooltip('Scheda mezzo'));
    await tester.pumpAndSettle();

    expect(find.byType(VehicleDetailScreen), findsOneWidget);
  });
}
