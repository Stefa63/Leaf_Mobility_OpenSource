// Test della fattura digitale della corsa (UT.25) — Task 3.
//
// La schermata rende una copia digitale con lo scorporo IVA (22%) a partire dai
// dati reali della corsa: imponibile + IVA = totale.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile_utente/screens/history_screen.dart';
import 'package:app_mobile_utente/screens/invoice_screen.dart';

void main() {
  const trip = TripEntry(
    id: 'corsa_42',
    date: '12/06/2026',
    time: '09:30',
    from: 'Stazione Bari Centrale',
    to: 'Teatro Petruzzelli',
    vehicleType: 'E-Bike',
    cost: 12.20,
    durationMinutes: 18,
    distanceKm: 3.4,
  );

  testWidgets('La fattura mostra lo scorporo IVA e il totale (UT.25)', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: InvoiceScreen(trip: trip)));
    await tester.pumpAndSettle();

    // Numero e dettaglio corsa.
    expect(find.text('FT-corsa_42'), findsOneWidget);
    expect(find.text('E-Bike'), findsOneWidget);
    expect(
      find.text('Stazione Bari Centrale → Teatro Petruzzelli'),
      findsOneWidget,
    );

    // Scorporo IVA al 22%: 12,20 = 10,00 imponibile + 2,20 IVA.
    expect(find.text('10.00 €'), findsOneWidget); // imponibile
    expect(find.text('2.20 €'), findsOneWidget); // IVA
    expect(find.text('12.20 €'), findsOneWidget); // totale
  });
}
