import 'package:dio/dio.dart';

import 'package:web_dashboard/api/api_client.dart';

/// @brief Contratto della coda SOS lato operatore (OP.08, UT.20/IIN-18), iniettabile nei test.
abstract class SosApi {
  /// @brief Elenca le segnalazioni SOS in coda, opzionalmente filtrate per stato.
  /// @param stato Filtro opzionale (inoltrata/presa_in_carico/chiusa); null = tutte.
  /// @return Lista delle segnalazioni (con etichetta utente già risolta lato server).
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> coda({String? stato});

  /// @brief Aggiorna lo stato di una segnalazione SOS (presa in carico/chiusura, OP.08).
  /// @param idSegnalazione Id della segnalazione.
  /// @param stato Nuovo stato: inoltrata | presa_in_carico | chiusa.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<void> aggiornaStato(String idSegnalazione, String stato);
}

/// @brief Implementazione di [SosApi] su `/api/v1` via Dio (Bearer OP).
class SosRepository implements SosApi {
  /// @brief Crea il repository; il client API è iniettabile nei test.
  SosRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<List<Map<String, dynamic>>> coda({String? stato}) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/sos',
        queryParameters: {'stato': ?stato},
      );
      final dati = ApiClient.payload(risposta);
      final sos = (dati['sos'] as List?) ?? const [];
      return sos
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<void> aggiornaStato(String idSegnalazione, String stato) async {
    try {
      await _client.dio.put<dynamic>(
        '/sos/$idSegnalazione/stato',
        data: {'stato': stato},
      );
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

/// @brief Repository SOS condiviso (default reale; sovrascrivibile nei test).
final SosRepository sosRepository = SosRepository();
