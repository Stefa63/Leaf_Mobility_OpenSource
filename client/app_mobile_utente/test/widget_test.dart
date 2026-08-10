// Smoke test della schermata Cronologia (UT.17).
//
// Verifica che la lista delle corse e i controlli di ordinamento vengano
// costruiti correttamente a partire dai dati del repository corse iniettato
// (FASE 2.B: cablaggio reale via /api/v1/corse). La HistoryScreen non usa timer
// o animazioni continue, quindi il test termina senza timer pendenti.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile_utente/api/corse_repository.dart';
import 'package:app_mobile_utente/screens/history_screen.dart';

/// Repository corse fittizio: ritorna due corse deterministiche per il test.
class _FakeCorse implements CorseApi {
  @override
  Future<List<Map<String, dynamic>>> storico() async => [
    {
      'codice_identificativo_mezzo': 'SC-001',
      'tipo_mezzo': 'monopattino',
      'data_ora_inizio': '2026-05-27T14:30:00',
      'durata_min': 7,
      'km_percorsi': 1.8,
      'costo_finale_cent': 175,
    },
    {
      'codice_identificativo_mezzo': 'BK-003',
      'tipo_mezzo': 'ebike',
      'data_ora_inizio': '2026-05-26T09:05:00',
      'durata_min': 8,
      'km_percorsi': 2.1,
      'costo_finale_cent': 120,
    },
  ];

  @override
  Future<List<Map<String, dynamic>>> fatture() async => const [];

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
  Future<Map<String, dynamic>> pausa(String idCorsa) async => const {};

  @override
  Future<Map<String, dynamic>> riprendi(String idCorsa) async => const {};

  @override
  Future<Map<String, dynamic>> valuta(String idCorsa, int stelle) async =>
      const {};
}

void main() {
  testWidgets('La cronologia mostra corse e criteri di ordinamento', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: HistoryScreen(corse: _FakeCorse())),
    );
    // Risolve il Future del caricamento (FutureBuilder → dati).
    await tester.pumpAndSettle();

    expect(find.text('Data'), findsOneWidget);
    expect(find.text('Durata'), findsOneWidget);
    expect(find.text('Distanza'), findsOneWidget);
    expect(find.text('Costo'), findsOneWidget);

    expect(find.byType(ListTile), findsWidgets);
  });
}
