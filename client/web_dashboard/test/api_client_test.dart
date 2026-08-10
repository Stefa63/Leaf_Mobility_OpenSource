// Test dell'inviluppo e della normalizzazione errori del client API web (FASE 2.C).

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:web_dashboard/api/api_client.dart';

void main() {
  Response<dynamic> rispostaCon(dynamic corpo, {int codice = 200}) => Response(
    requestOptions: RequestOptions(path: '/x'),
    statusCode: codice,
    data: corpo,
  );

  test('payload estrae i dati quando disponibile', () {
    final dati = ApiClient.payload(
      rispostaCon({
        'disponibile': true,
        'messaggio': 'ok',
        'dati': {'a': 1},
      }),
    );
    expect(dati['a'], 1);
  });

  test('payload solleva col messaggio quando non disponibile', () {
    expect(
      () => ApiClient.payload(
        rispostaCon({
          'disponibile': false,
          'messaggio': 'in sviluppo',
          'dati': null,
        }),
      ),
      throwsA(
        isA<LeafApiException>().having((e) => e.messaggio, 'msg', 'in sviluppo'),
      ),
    );
  });

  test('erroreDa usa il campo dettaglio del backend', () {
    final errore = DioException(
      requestOptions: RequestOptions(path: '/x'),
      response: rispostaCon({'dettaglio': 'non consentito'}, codice: 403),
    );
    final ex = ApiClient.erroreDa(errore);
    expect(ex.messaggio, 'non consentito');
    expect(ex.codice, 403);
  });
}
