// Test del cablaggio sblocco/avvio corsa al backend (UT.10) — FASE 2.B.
//
// Con un docId reale, "Sblocca con QR" invia corse.avvia(docId).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile_utente/api/corse_repository.dart';
import 'package:app_mobile_utente/screens/vehicle_detail_screen.dart';

/// Repository corse fittizio che registra l'avvio.
class _SpyCorse implements CorseApi {
  String? avviato;

  @override
  Future<Map<String, dynamic>> avvia(
    String idMezzo, {
    String? idPrenotazione,
  }) async {
    avviato = idMezzo;
    return {'id_corsa': 'c1', 'sbloccato': true};
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
  Future<List<Map<String, dynamic>>> storico() async => const [];
  @override
  Future<List<Map<String, dynamic>>> fatture() async => const [];
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
  Future<Map<String, dynamic>> pausa(String idCorsa) async => const {};
  @override
  Future<Map<String, dynamic>> riprendi(String idCorsa) async => const {};
  @override
  Future<Map<String, dynamic>> valuta(String idCorsa, int stelle) async =>
      const {};
}

void main() {
  testWidgets('Sblocca con QR avvia la corsa col docId (UT.10)', (
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
      MaterialApp(home: VehicleDetailScreen(vehicle: veicolo, corse: spy)),
    );
    final pulsante = find.text('Sblocca con QR');
    await tester.ensureVisible(pulsante);
    await tester.pumpAndSettle();
    await tester.tap(pulsante);
    await tester.pumpAndSettle();

    expect(spy.avviato, 'mezzo_doc_1');
  });
}
