// Unit test del mapping del layer routing (Cascata B): parsing del suggerimento
// di luogo dal payload `/geocoding`, deterministico e offline.

import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile_utente/api/routing_repository.dart';

void main() {
  group('LuogoSuggerito.daApi', () {
    test('mappa nome e coordinate dal payload', () {
      final luogo = LuogoSuggerito.daApi({
        'nome': 'Teatro Petruzzelli – Bari',
        'lat': 41.1255,
        'lon': 16.8694,
      });
      expect(luogo.nome, 'Teatro Petruzzelli – Bari');
      expect(luogo.lat, closeTo(41.1255, 1e-6));
      expect(luogo.lon, closeTo(16.8694, 1e-6));
    });

    test('coerce gli interi a double e tollera i campi assenti', () {
      final luogo = LuogoSuggerito.daApi({'lat': 41, 'lon': 16});
      expect(luogo.nome, ''); // nome assente → stringa vuota
      expect(luogo.lat, 41.0);
      expect(luogo.lon, 16.0);
    });
  });
}
