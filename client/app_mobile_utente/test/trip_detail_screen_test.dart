// Widget test della schermata di dettaglio corsa (UT.17, UT.09, UT.25).
//
// Verifica l'esposizione dei dati della corsa passata (percorso, statistiche,
// importo), l'apertura della fattura digitale (UT.25) e il flusso di segnalazione
// corsa con validazione del messaggio (UT.09). Nessuna dipendenza di piattaforma.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/screens/history_screen.dart';
import 'package:app_mobile_utente/screens/trip_detail_screen.dart';

/// Corsa campione: scooter, durata e distanza non nulle (velocità media > 0).
const TripEntry kTestTrip = TripEntry(
  id: '#0042',
  date: '12/06/2026',
  time: '09:15',
  from: 'Piazza Moro',
  to: 'Lungomare',
  vehicleType: 'Scooter',
  cost: 4.5,
  durationMinutes: 12,
  distanceKm: 3.0,
);

/// @brief Monta la [TripDetailScreen] della corsa campione in test.
/// @return il widget radice da passare a `pumpWidget`.
Widget buildTripApp() {
  return const MaterialApp(home: TripDetailScreen(trip: kTestTrip));
}

void main() {
  setUp(() {
    // Lingua deterministica per i finder testuali (IIN-7).
    appLanguage.value = 'it';
  });

  testWidgets('Il dettaglio mostra percorso, statistiche e importo (UT.17)', (
    tester,
  ) async {
    await tester.pumpWidget(buildTripApp());

    expect(find.text('Scooter'), findsOneWidget);
    expect(find.text('12/06/2026 · 09:15'), findsOneWidget);
    expect(find.text('Piazza Moro'), findsOneWidget);
    expect(find.text('Lungomare'), findsOneWidget);
    // Statistiche calcolate: durata, distanza, velocità media, CO₂.
    expect(find.text('12 min'), findsOneWidget);
    expect(find.text('3.0 km'), findsOneWidget);
    expect(find.text('15 km/h'), findsOneWidget); // 3.0 / 12 * 60
    expect(find.text('0.36 kg'), findsOneWidget); // 3.0 * 0.12
    // Importo addebitato.
    expect(find.text('4.50 €'), findsOneWidget);
  });

  testWidgets('Esporta fattura apre la fattura digitale (UT.25)', (tester) async {
    await tester.pumpWidget(buildTripApp());

    await tester.ensureVisible(find.text('Esporta fattura'));
    await tester.tap(find.text('Esporta fattura'));
    await tester.pumpAndSettle();

    // La schermata fattura mostra il numero derivato dalla corsa e il totale,
    // con scorporo IVA 22% (4,50 = 3,69 imponibile + 0,81 IVA).
    expect(find.text('FT-#0042'), findsOneWidget);
    expect(find.text('3.69 €'), findsOneWidget); // imponibile
    expect(find.text('0.81 €'), findsOneWidget); // IVA
    expect(find.text('4.50 €'), findsOneWidget); // totale
  });

  testWidgets('Segnala corsa: invio senza messaggio è bloccato (UT.09)', (
    tester,
  ) async {
    await tester.pumpWidget(buildTripApp());

    await tester.ensureVisible(find.text('Segnala corsa'));
    await tester.tap(find.text('Segnala corsa'));
    await tester.pumpAndSettle();

    // Il dialogo di segnalazione è aperto.
    expect(find.text('Segnala corsa #0042'), findsOneWidget);

    // Invio senza messaggio → errore di validazione, dialogo ancora aperto.
    await tester.tap(find.text('Invia'));
    await tester.pump();
    expect(find.text('Inserisci un messaggio prima di inviare.'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('Segnala corsa: invio valido confermato e dialogo chiuso (UT.09)', (
    tester,
  ) async {
    await tester.pumpWidget(buildTripApp());

    await tester.ensureVisible(find.text('Segnala corsa'));
    await tester.tap(find.text('Segnala corsa'));
    await tester.pumpAndSettle();

    // Inserimento messaggio e invio → conferma e chiusura dialogo.
    await tester.enterText(find.byType(TextField), 'Sella danneggiata');
    await tester.tap(find.text('Invia'));
    await tester.pumpAndSettle();

    expect(find.text('Grazie! La tua segnalazione è stata inviata.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing); // dialogo chiuso
  });
}
