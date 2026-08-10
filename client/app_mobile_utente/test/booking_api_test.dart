// Test del cablaggio prenotazione al backend (UT.02) — FASE 2.B.
//
// Quando il mezzo porta un docId reale, la conferma invia prima la prenotazione
// al backend (CorseApi.prenota) e poi registra la prenotazione locale.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile_utente/api/corse_repository.dart';
import 'package:app_mobile_utente/booking_store.dart';
import 'package:app_mobile_utente/screens/booking_screen.dart';
import 'package:app_mobile_utente/screens/vehicle_detail_screen.dart';

/// Repository corse fittizio che registra prenotazione e stima costo (UT.02/UT.03).
class _SpyCorse implements CorseApi {
  String? prenotato;
  String? stimato;

  @override
  Future<Map<String, dynamic>> prenota(String idMezzo, {int? durataMin}) async {
    prenotato = idMezzo;
    return {'id_prenotazione': 'p1'};
  }

  @override
  Future<List<Map<String, dynamic>>> prenotazioni() async => const [];
  @override
  Future<Map<String, dynamic>?> corsaAttiva() async => null;
  @override
  Future<Map<String, dynamic>> annullaPrenotazione(
    String idPrenotazione,
  ) async => const {};

  @override
  Future<Map<String, dynamic>> stima(String idMezzo, {int? durataMin}) async {
    stimato = idMezzo;
    // Scomposizione come dal backend (punto 8): sblocco + corsa = totale.
    return {
      'sblocco_cent': 50,
      'corsa_cent': 200,
      'totale_cent': 250,
      'costo_stimato_cent': 250,
      'ha_abbonamento': false,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> storico() async => const [];
  @override
  Future<List<Map<String, dynamic>>> fatture() async => const [];
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
  Future<Map<String, dynamic>> pausa(String idCorsa) async => const {};
  @override
  Future<Map<String, dynamic>> riprendi(String idCorsa) async => const {};
  @override
  Future<Map<String, dynamic>> valuta(String idCorsa, int stelle) async =>
      const {};
}

void main() {
  setUp(() => bookingStore.value = <Booking>[]);

  testWidgets('Conferma invia la prenotazione al backend col docId (UT.02)', (
    tester,
  ) async {
    final spy = _SpyCorse();
    const veicolo = VehicleData(
      id: 'SC-001',
      type: VehicleType.scooter,
      batteryPercent: 80,
      rangeKm: 40,
      distanceMeters: 100,
      docId: 'mezzo_doc_1',
    );

    await tester.pumpWidget(
      MaterialApp(home: BookingScreen(vehicle: veicolo, corse: spy)),
    );
    await tester.pumpAndSettle();

    // La stima reale del backend (250c = 2,50 €) è richiesta e mostrata (UT.03).
    expect(spy.stimato, 'mezzo_doc_1');
    expect(find.text('2.50 €'), findsOneWidget);

    await tester.ensureVisible(find.text('Conferma prenotazione'));
    await tester.tap(find.text('Conferma prenotazione'));
    await tester.pumpAndSettle();

    // La prenotazione è inviata al backend con la durata scelta (UT.02/UT.15) e
    // si apre l'elenco "Mie Prenotazioni" (il backend è la fonte di verità).
    expect(spy.prenotato, 'mezzo_doc_1');
    expect(find.text('Mie Prenotazioni'), findsOneWidget);
  });
}
