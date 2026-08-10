// Widget test della schermata di dettaglio veicolo (UT.05, UT.06, UT.10).
//
// Verifica l'esposizione delle caratteristiche del mezzo (batteria,
// autonomia, distanza, attesa stimata, tariffa), il comando di sblocco
// (UT.10, stub pre-backend) e l'accesso alla prenotazione (UT.02).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/screens/booking_screen.dart';
import 'package:app_mobile_utente/screens/vehicle_detail_screen.dart';

/// Veicolo campione: scooter vicino all'utente, batteria carica.
const VehicleData kTestVehicle = VehicleData(
  id: 'SC-001',
  type: VehicleType.scooter,
  batteryPercent: 78,
  rangeKm: 42,
  distanceMeters: 120,
);

/// @brief Monta la [VehicleDetailScreen] del veicolo campione in test.
/// @return il widget radice da passare a `pumpWidget`.
Widget buildDetailApp() {
  return const MaterialApp(home: VehicleDetailScreen(vehicle: kTestVehicle));
}

void main() {
  setUp(() {
    // Lingua deterministica per i finder testuali (IIN-7).
    appLanguage.value = 'it';
  });

  testWidgets('Il dettaglio mostra le caratteristiche del mezzo (UT.05)', (
    tester,
  ) async {
    await tester.pumpWidget(buildDetailApp());

    expect(find.text('SC-001'), findsOneWidget);
    expect(find.text('Disponibile'), findsOneWidget);
    expect(find.text('78%'), findsOneWidget);
    expect(find.text('~42 km'), findsOneWidget);
    expect(find.text('120 m'), findsOneWidget);
    // UT.06 — attesa stimata: distanza < 300 m → "< 2 min".
    expect(find.text('< 2 min'), findsOneWidget);
    // UT.03 — tariffa dello scooter.
    expect(find.text('0.25 €/min'), findsOneWidget);
  });

  testWidgets('Sblocca con QR mostra il feedback di sblocco (UT.10)', (
    tester,
  ) async {
    await tester.pumpWidget(buildDetailApp());

    await tester.ensureVisible(find.text('Sblocca con QR'));
    await tester.tap(find.text('Sblocca con QR'));
    await tester.pump();

    expect(
      find.text('Sblocco mezzo… (funzione in sviluppo)'),
      findsOneWidget,
    );
  });

  testWidgets('Prenota mezzo apre la BookingScreen (UT.02)', (tester) async {
    await tester.pumpWidget(buildDetailApp());

    await tester.ensureVisible(find.text('Prenota mezzo'));
    await tester.tap(find.text('Prenota mezzo'));
    await tester.pumpAndSettle();

    expect(find.byType(BookingScreen), findsOneWidget);
  });
}
