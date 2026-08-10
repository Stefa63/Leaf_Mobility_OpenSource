// Test del flusso di prenotazione (UT.02, UT.03, UT.12, UT.13).
//
// Copre la tab "Prenota" (elenco mezzi disponibili), la BookingScreen
// (selezione durata e costo stimato) e lo store osservabile [bookingStore],
// che viene azzerato tra i test per evitare contaminazione di stato.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile_utente/api/corse_repository.dart';
import 'package:app_mobile_utente/booking_store.dart';
import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/screens/booking_screen.dart';
import 'package:app_mobile_utente/screens/booking_tab.dart';
import 'package:app_mobile_utente/screens/my_bookings_screen.dart';
import 'package:app_mobile_utente/screens/vehicle_detail_screen.dart';

/// Repository corse fittizio: nessuna prenotazione lato server, così la schermata
/// "Mie Prenotazioni" mostra solo quelle locali offline senza chiamate di rete reali.
class _FakeCorse implements CorseApi {
  @override
  Future<List<Map<String, dynamic>>> prenotazioni() async => const [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// @brief Costruisce una [Booking] campione per i test unitari dello store.
/// @param vehicleId codice del veicolo prenotato.
/// @return prenotazione attiva di 15 minuti creata "adesso".
Booking makeBooking(String vehicleId) {
  return Booking(
    vehicleId: vehicleId,
    vehicleTypeLabel: 'Scooter Elettrico',
    vehicleType: VehicleType.scooter,
    createdAt: DateTime.now(),
    durationMinutes: 15,
    estimatedCost: 3.75,
  );
}

void main() {
  setUp(() {
    // Lingua deterministica (IIN-7) e store azzerato tra i test.
    appLanguage.value = 'it';
    bookingStore.value = <Booking>[];
  });

  group('bookingStore (unit)', () {
    test('addBooking inserisce in testa e notifica gli ascoltatori', () {
      var notifications = 0;
      bookingStore.addListener(() => notifications++);

      addBooking(makeBooking('SC-001'));
      addBooking(makeBooking('BK-003'));

      expect(bookingStore.value.length, 2);
      expect(bookingStore.value.first.vehicleId, 'BK-003');
      expect(notifications, 2);
    });

    test('cancelBooking marca la prenotazione annullata e notifica (UT.12)', () {
      final booking = makeBooking('SC-001');
      addBooking(booking);
      var notified = false;
      bookingStore.addListener(() => notified = true);

      cancelBooking(booking);

      expect(bookingStore.value.single.status, BookingStatus.annullata);
      expect(notified, isTrue);
    });

    test('expiresAt e\' createdAt + durata della riserva', () {
      final booking = makeBooking('SC-001');
      expect(
        booking.expiresAt,
        booking.createdAt.add(const Duration(minutes: 15)),
      );
    });
  });

  group('BookingTab', () {
    testWidgets('Elenca i mezzi disponibili nei dintorni (UT.02)', (
      tester,
    ) async {
      // Superficie alta a sufficienza per costruire tutte le righe della
      // ListView (i tile mostrano "Tipo · ID" in un unico Text).
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: BookingTab())),
      );

      expect(find.text('Mezzi Disponibili Vicino a Te'), findsOneWidget);
      for (final vehicle in kAvailableVehicles) {
        expect(find.textContaining(vehicle.id), findsOneWidget);
      }
    });
  });

  group('BookingScreen', () {
    testWidgets('La durata selezionata aggiorna il costo stimato (UT.03)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: BookingScreen(vehicle: kAvailableVehicles.first)),
      );

      // Default: scooter 0.25 €/min × 15 min.
      expect(find.text('3.75 €'), findsOneWidget);

      await tester.tap(find.text('30 min'));
      await tester.pump();

      expect(find.text('7.50 €'), findsOneWidget);
      expect(find.text('3.75 €'), findsNothing);
    });

    testWidgets(
      'Conferma registra la prenotazione nello store e apre Mie Prenotazioni '
      '(UT.02)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: BookingScreen(
              vehicle: kAvailableVehicles.first,
              corse: _FakeCorse(),
            ),
          ),
        );

        await tester.tap(find.text('30 min'));
        await tester.pump();
        await tester.ensureVisible(find.text('Conferma prenotazione'));
        await tester.tap(find.text('Conferma prenotazione'));
        await tester.pumpAndSettle();

        expect(bookingStore.value.length, 1);
        final booking = bookingStore.value.single;
        expect(booking.vehicleId, 'SC-001');
        expect(booking.durationMinutes, 30);
        expect(booking.estimatedCost, closeTo(7.50, 0.001));
        expect(booking.status, BookingStatus.attiva);

        expect(find.byType(MyBookingsScreen), findsOneWidget);
        // La card mostra "Tipo · ID" in un unico Text.
        expect(find.textContaining('SC-001'), findsOneWidget);
      },
    );
  });
}
