// Widget test della Gestione Geofencing (OP.04).
//
// La schermata monta GoogleCityMap: il ServizioMappa è sostituito dal fake di
// piattaforma (test/helpers/fake_maps_platform.dart). Verifica l'header e
// l'elenco delle aree (operativa, interdizione, slow-zone).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:web_dashboard/api/areas_repository.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/screens/geofencing_screen.dart';

import 'helpers/fake_maps_platform.dart';

/// @brief AreeApi fittizia: ritorna due aree deterministiche, nessuna rete.
class _FakeAree implements AreeApi {
  @override
  Future<List<Map<String, dynamic>>> elenco({bool soloAttive = false}) async => [
    {
      '_id': 'GF-01',
      'nome': 'Area Operativa Centro',
      'tipo': 'area_operativa',
      'poligono': [
        [41.1255, 16.8650],
        [41.1265, 16.8740],
        [41.1190, 16.8760],
      ],
    },
    {
      '_id': 'GF-02',
      'nome': 'Zona Pedonale San Nicola',
      'tipo': 'interdizione',
      'poligono': [
        [41.1300, 16.8665],
        [41.1312, 16.8700],
        [41.1288, 16.8712],
      ],
    },
  ];

  @override
  Future<String> crea(Map<String, dynamic> dati) async => 'GF-99';

  @override
  Future<void> elimina(String idArea) async {}
}

/// @brief Monta la [GeofencingScreen] in un telaio di test desktop con mappa fake.
/// @param tester il driver del widget test.
Future<void> pumpGeofencing(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1400, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(0.8),
        ),
        child: child!,
      ),
      home: Scaffold(body: GeofencingScreen(aree: _FakeAree())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    appLanguage.value = 'it';
    installFakeGoogleMapsPlatform();
  });

  testWidgets('Gestione Geofencing mostra header e aree definite (OP.04)', (
    tester,
  ) async {
    await pumpGeofencing(tester);

    expect(find.text('Gestione Geofencing'), findsOneWidget);
    expect(find.text('Area Operativa Centro'), findsOneWidget);
    expect(find.text('Zona Pedonale San Nicola'), findsOneWidget);
  });
}
