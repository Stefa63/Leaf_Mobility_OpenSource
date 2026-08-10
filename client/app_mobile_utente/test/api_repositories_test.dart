// Unit test del layer repository dati (FASE 2.B): spacchettamento dell'inviluppo
// uniforme `{disponibile, messaggio, dati}` e normalizzazione degli errori.
//
// Verifica la logica condivisa `ApiClient.payload`/`erroreDa` su cui poggiano tutti
// i repository dati (veicoli, corse, profilo, assistenza), in modo deterministico
// e offline (Response costruite a mano, nessuna rete).

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile_utente/api/api_client.dart';

Response<dynamic> _risposta(dynamic corpo, {int statusCode = 200}) {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: '/x'),
    statusCode: statusCode,
    data: corpo,
  );
}

void main() {
  group('ApiClient.payload', () {
    test('estrae il payload dati quando disponibile', () {
      final dati = ApiClient.payload(
        _risposta({
          'disponibile': true,
          'messaggio': 'ok',
          'dati': {
            'mezzi': [
              {'id': 'BK-1'},
            ],
            'totale': 1,
          },
        }),
      );
      expect(dati['totale'], 1);
      expect((dati['mezzi'] as List).length, 1);
    });

    test('solleva con il messaggio di dominio quando non disponibile', () {
      expect(
        () => ApiClient.payload(
          _risposta({
            'disponibile': false,
            'messaggio': 'DataAccessManager/DB in sviluppo',
            'dati': null,
          }),
        ),
        throwsA(
          isA<LeafApiException>().having(
            (e) => e.messaggio,
            'messaggio',
            contains('sviluppo'),
          ),
        ),
      );
    });

    test('solleva su corpo inatteso', () {
      expect(
        () => ApiClient.payload(_risposta('non-json')),
        throwsA(isA<LeafApiException>()),
      );
    });
  });

  group('ApiClient.erroreDa', () {
    test('usa il campo dettaglio del backend come messaggio', () {
      final errore = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: _risposta({
          'dettaglio': 'Credenziali non valide',
        }, statusCode: 401),
      );
      final eccezione = ApiClient.erroreDa(errore);
      expect(eccezione.messaggio, 'Credenziali non valide');
      expect(eccezione.codice, 401);
    });

    test('messaggio di fallback senza dettaglio', () {
      final errore = DioException(requestOptions: RequestOptions(path: '/x'));
      expect(ApiClient.erroreDa(errore).messaggio, contains('servizio'));
    });
  });
}
