// Test del repository stazioni di ricarica (UT.14) — Task 3.
//
// Verifica che VeicoliRepository.stazioni() interroghi /stazioni e spacchetti la
// lista `stazioni` dall'inviluppo uniforme, in modo deterministico e offline
// (HttpClientAdapter fittizio: nessuna rete, nessun canale plugin reale).

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile_utente/api/api_client.dart';
import 'package:app_mobile_utente/api/veicoli_repository.dart';

/// Adapter Dio che risponde sempre con lo stesso corpo JSON (200).
class _AdapterFisso implements HttpClientAdapter {
  _AdapterFisso(this.corpo);

  final Map<String, dynamic> corpo;
  String? percorsoRichiesto;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    percorsoRichiesto = options.path;
    return ResponseBody.fromString(
      jsonEncode(corpo),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Il canale del secure storage non esiste nei test: l'interceptor Bearer
    // legge il token con questo handler fittizio (nessun token → nessun header).
    const canale = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canale, (call) async => null);
  });

  test('stazioni() interroga /stazioni e spacchetta la lista (UT.14)', () async {
    final adapter = _AdapterFisso({
      'disponibile': true,
      'messaggio': 'ok',
      'dati': {
        'stazioni': [
          {
            '_id': 'CHG-01',
            'nome': 'Piazza Ferrarese',
            'lat': 41.1262,
            'lon': 16.8698,
            'num_colonnine': 4,
            'stato': 'attiva',
          },
          {
            '_id': 'CHG-02',
            'nome': 'Via Amendola',
            'lat': 41.1072,
            'lon': 16.8608,
            'num_colonnine': 2,
            'stato': 'attiva',
          },
        ],
        'totale': 2,
      },
    });
    final dio = Dio()..httpClientAdapter = adapter;
    final repo = VeicoliRepository(client: ApiClient(dio: dio));

    final stazioni = await repo.stazioni();

    expect(adapter.percorsoRichiesto, '/stazioni');
    expect(stazioni.length, 2);
    expect(stazioni.first['_id'], 'CHG-01');
    expect(stazioni.first['num_colonnine'], 4);
  });

  test('stazioni() solleva LeafApiException se non disponibile (IIN-6)', () async {
    final adapter = _AdapterFisso({
      'disponibile': false,
      'messaggio': 'DataAccessManager/DB in sviluppo',
      'dati': null,
    });
    final dio = Dio()..httpClientAdapter = adapter;
    final repo = VeicoliRepository(client: ApiClient(dio: dio));

    await expectLater(repo.stazioni(), throwsA(isA<LeafApiException>()));
  });
}
