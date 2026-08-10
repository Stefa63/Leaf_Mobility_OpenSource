// Test del mapping documento area → GeoArea (FASE 2.C, A4).

import 'package:flutter_test/flutter_test.dart';

import 'package:web_dashboard/screens/geofencing_screen.dart';

void main() {
  test('GeoArea.daApi mappa il poligono e il tipo slow-zone', () {
    final a = GeoArea.daApi({
      '_id': 'GF-10',
      'nome': 'Slow Lungomare',
      'tipo': 'slow_zone',
      'limite_velocita_kmh': 15,
      'poligono': [
        [41.12, 16.86],
        [41.13, 16.87],
        [41.11, 16.88],
      ],
    });
    expect(a, isNotNull);
    expect(a!.id, 'GF-10');
    expect(a.type, GeoAreaType.slowZone);
    expect(a.speedLimit, 15);
    expect(a.points.length, 3);
  });

  test('GeoArea.daApi accetta anche il formato geometria {lat,lon}', () {
    final a = GeoArea.daApi({
      '_id': 'GF-11',
      'nome': 'Interdetta',
      'tipo': 'interdizione',
      'geometria': [
        {'lat': 41.1, 'lon': 16.8},
        {'lat': 41.2, 'lon': 16.9},
        {'lat': 41.0, 'lon': 16.7},
      ],
    });
    expect(a, isNotNull);
    expect(a!.type, GeoAreaType.interdetta);
    expect(a.points.length, 3);
  });

  test('GeoArea.daApi ritorna null con meno di 3 vertici', () {
    expect(
      GeoArea.daApi({
        '_id': 'X',
        'tipo': 'area_operativa',
        'poligono': [
          [41.1, 16.8],
        ],
      }),
      isNull,
    );
  });

  test('tipoAreaApi e tipoAreaDaApi sono coerenti', () {
    for (final t in GeoAreaType.values) {
      expect(tipoAreaDaApi(tipoAreaApi(t)), t);
    }
  });
}
