import 'package:dio/dio.dart';

import 'package:app_mobile_utente/api/api_client.dart';

/// @brief Contratto della richiesta di assistenza utente (UT.09), iniettabile nei test.
abstract class AssistenzaApi {
  /// @brief Apre una richiesta di assistenza in coda per l'utente autenticato.
  /// @param oggetto Oggetto sintetico della richiesta.
  /// @param messaggio Testo della richiesta di supporto.
  /// @param idCorsa Corsa correlata (opzionale).
  /// @return Payload con `id_ticket`.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<Map<String, dynamic>> apri(
    String oggetto,
    String messaggio, {
    String? idCorsa,
  });
}

/// @brief Implementazione di [AssistenzaApi] su `/api/v1/assistenza` via Dio (Bearer automatico).
class AssistenzaRepository implements AssistenzaApi {
  /// @brief Crea il repository; il client API è iniettabile nei test.
  AssistenzaRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<Map<String, dynamic>> apri(
    String oggetto,
    String messaggio, {
    String? idCorsa,
  }) async {
    try {
      final risposta = await _client.dio.post<dynamic>(
        '/assistenza',
        data: {
          'oggetto': oggetto,
          'messaggio': messaggio,
          'id_corsa': ?idCorsa,
        },
      );
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

/// @brief Repository assistenza condiviso (default reale; sovrascrivibile nei test).
final AssistenzaRepository assistenzaRepository = AssistenzaRepository();
