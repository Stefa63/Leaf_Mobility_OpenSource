// Test del generatore PDF della fattura (UT.25) — stampa/PDF reale.
//
// buildInvoicePdf è puro Dart (nessun canale di piattaforma): genera i byte di
// un PDF valido a partire dai dati della corsa. Il dialogo di stampa nativo
// (Printing.layoutPdf) non è testabile in flutter test (canale di sistema).

import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile_utente/screens/history_screen.dart';
import 'package:app_mobile_utente/screens/invoice_pdf.dart';

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

  test('buildInvoicePdf produce un PDF valido (UT.25)', () async {
    final bytes = await buildInvoicePdf(trip: trip, cliente: 'Mario Rossi');

    // Un PDF non vuoto, che inizia con la firma "%PDF".
    expect(bytes.length, greaterThan(500));
    expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
  });
}
