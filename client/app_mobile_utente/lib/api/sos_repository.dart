import 'package:dio/dio.dart';

import 'package:app_mobile_utente/api/api_client.dart';

/// @brief Contratto della segnalazione di emergenza SOS (UT.20, IIN-18), iniettabile nei test.
abstract class SosApi {
  /// @brief Inoltra una segnalazione SOS con la posizione GPS corrente.
  /// @param lat Latitudine rilevata.
  /// @param lon Longitudine rilevata.
  /// @param idCorsa Corsa in atto correlata (opzionale).
  /// @return Payload con `id_segnalazione`/`stato`.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<Map<String, dynamic>> segnala({
    required double lat,
    required double lon,
    String? idCorsa,
  });
}

/// @brief Implementazione di [SosApi] su `/api/v1/sos` via Dio (Bearer automatico).
class SosRepository implements SosApi {
  /// @brief Crea il repository; il client API è iniettabile nei test.
  SosRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<Map<String, dynamic>> segnala({
    required double lat,
    required double lon,
    String? idCorsa,
  }) async {
    try {
      final risposta = await _client.dio.post<dynamic>(
        '/sos',
        data: {'lat': lat, 'lon': lon, 'id_corsa': ?idCorsa},
      );
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

/// @brief Repository SOS condiviso (default reale; sovrascrivibile nei test).
final SosRepository sosRepository = SosRepository();
