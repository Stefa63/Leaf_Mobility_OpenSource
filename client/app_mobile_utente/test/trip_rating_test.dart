// Test della valutazione a stelle di una corsa conclusa (UT.16).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile_utente/api/corse_repository.dart';
import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/screens/history_screen.dart';
import 'package:app_mobile_utente/screens/trip_detail_screen.dart';

/// CorseApi fittizia: registra la valutazione inviata.
class _SpyCorse implements CorseApi {
  String? valutata;
  int? stelle;

  @override
  Future<Map<String, dynamic>> valuta(String idCorsa, int s) async {
    valutata = idCorsa;
    stelle = s;
    return {'id_corsa': idCorsa, 'valutazione': s};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} non usato nel test');
}

const _trip = TripEntry(
  id: '#0001',
  date: '01/06/2026',
  time: '10:00',
  from: 'Partenza',
  to: 'Arrivo',
  vehicleType: 'E-Bike',
  cost: 3.5,
  durationMinutes: 20,
  distanceKm: 4,
);

void main() {
  testWidgets('Valuta corsa invia le stelle scelte al backend (UT.16)', (
    tester,
  ) async {
    appLanguage.value = 'it';
    await tester.binding.setSurfaceSize(const Size(1000, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final spy = _SpyCorse();
    await tester.pumpWidget(
      MaterialApp(home: TripDetailScreen(trip: _trip, corse: spy)),
    );
    await tester.pumpAndSettle();

    // Apre il dialogo di valutazione (il pulsante è in fondo allo scroll).
    await tester.ensureVisible(find.text('Valuta corsa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valuta corsa'));
    await tester.pumpAndSettle();

    // Seleziona 4 stelle e invia.
    await tester.tap(find.byIcon(Icons.star_border).at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Invia'));
    await tester.pumpAndSettle();

    expect(spy.valutata, '#0001');
    expect(spy.stelle, 4);
  });
}
