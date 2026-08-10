// Test del cablaggio pausa/riprendi della corsa attiva (UT.12) — Task 3.
//
// La card della corsa attiva in MyBookingsScreen invia pausa/riprendi al
// backend (CorseApi) e aggiorna lo stato osservabile activeTripStore.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile_utente/active_trip_store.dart';
import 'package:app_mobile_utente/api/corse_repository.dart';
import 'package:app_mobile_utente/booking_store.dart';
import 'package:app_mobile_utente/screens/my_bookings_screen.dart';
import 'package:app_mobile_utente/screens/vehicle_detail_screen.dart';

/// Repository corse fittizio che conta le chiamate pausa/riprendi.
class _SpyCorse implements CorseApi {
  int pausaCount = 0;
  int riprendiCount = 0;

  @override
  Future<Map<String, dynamic>> pausa(String idCorsa) async {
    pausaCount++;
    return {'id_corsa': idCorsa, 'stato': 'in_pausa'};
  }

  @override
  Future<Map<String, dynamic>> riprendi(String idCorsa) async {
    riprendiCount++;
    return {'id_corsa': idCorsa, 'stato': 'in_corso'};
  }

  @override
  Future<Map<String, dynamic>> prenota(String idMezzo, {int? durataMin}) async =>
      const {};
  @override
  Future<List<Map<String, dynamic>>> prenotazioni() async => const [];
  @override
  Future<Map<String, dynamic>?> corsaAttiva() async => null;
  @override
  Future<Map<String, dynamic>> annullaPrenotazione(
    String idPrenotazione,
  ) async => const {};
  @override
  Future<Map<String, dynamic>> avvia(
    String idMezzo, {
    String? idPrenotazione,
  }) async => const {};
  @override
  Future<Map<String, dynamic>> termina(
    String idCorsa, {
    double km = 0.0,
    double? lat,
    double? lon,
  }) async => const {};
  @override
  Future<Map<String, dynamic>> stima(String idMezzo, {int? durataMin}) async =>
      const {};
  @override
  Future<Map<String, dynamic>> valuta(String idCorsa, int stelle) async =>
      const {};
  @override
  Future<List<Map<String, dynamic>>> storico() async => const [];
  @override
  Future<List<Map<String, dynamic>>> fatture() async => const [];
}

void main() {
  setUp(() {
    bookingStore.value = <Booking>[];
    activeTripStore.value = null;
  });

  tearDown(() => activeTripStore.value = null);

  testWidgets('Pausa poi Riprendi commutano stato e backend (UT.12)', (
    tester,
  ) async {
    final spy = _SpyCorse();
    activeTripStore.value = ActiveTrip(
      idCorsa: 'corsa_1',
      vehicleId: 'SC-001',
      vehicleType: VehicleType.scooter,
      startedAt: DateTime(2026, 6, 26, 10),
    );

    await tester.pumpWidget(
      MaterialApp(home: MyBookingsScreen(corse: spy)),
    );
    await tester.pumpAndSettle();

    // Stato iniziale: in corso, pulsante "Pausa corsa".
    expect(find.text('Pausa corsa'), findsOneWidget);

    // Pausa → backend chiamato, stato in pausa, pulsante "Riprendi corsa".
    await tester.tap(find.text('Pausa corsa'));
    await tester.pumpAndSettle();
    expect(spy.pausaCount, 1);
    expect(activeTripStore.value!.isPaused, isTrue);
    expect(find.text('Riprendi corsa'), findsOneWidget);

    // Riprendi → backend chiamato, stato in corso.
    await tester.tap(find.text('Riprendi corsa'));
    await tester.pumpAndSettle();
    expect(spy.riprendiCount, 1);
    expect(activeTripStore.value!.isPaused, isFalse);
    expect(find.text('Pausa corsa'), findsOneWidget);
  });

  testWidgets('Senza corsa attiva la card non è mostrata (UT.12)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: MyBookingsScreen(corse: _SpyCorse())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pausa corsa'), findsNothing);
    expect(find.text('Nessuna prenotazione attiva'), findsOneWidget);
  });
}
