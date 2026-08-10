import 'package:dio/dio.dart';

import 'package:app_mobile_utente/api/api_client.dart';

/// @brief Contratto di accesso ai veicoli/mappa (UT.01/UT.05), iniettabile nei test.
abstract class VeicoliApi {
  /// @brief Elenca i mezzi disponibili, opzionalmente nei pressi di un punto.
  /// @param lat Latitudine del centro di ricerca (opzionale).
  /// @param lon Longitudine del centro di ricerca (opzionale).
  /// @return Lista dei mezzi disponibili (documenti grezzi della API).
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> disponibili({double? lat, double? lon});

  /// @brief Elenca le stazioni di ricarica attive sulla mappa (UT.14).
  /// @return Lista delle stazioni (`_id`, `nome`, `lat`, `lon`, `num_colonnine`…).
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> stazioni();
}

/// @brief Implementazione di [VeicoliApi] su `/api/v1/veicoli` via Dio.
class VeicoliRepository implements VeicoliApi {
  /// @brief Crea il repository; il client API è iniettabile nei test.
  VeicoliRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<List<Map<String, dynamic>>> disponibili({
    double? lat,
    double? lon,
  }) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/veicoli',
        queryParameters: {'lat': ?lat, 'lon': ?lon},
      );
      final dati = ApiClient.payload(risposta);
      final mezzi = (dati['mezzi'] as List?) ?? const [];
      return mezzi
          .map((m) => Map<String, dynamic>.from(m as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> stazioni() async {
    try {
      final risposta = await _client.dio.get<dynamic>('/stazioni');
      final dati = ApiClient.payload(risposta);
      final elenco = (dati['stazioni'] as List?) ?? const [];
      return elenco
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

/// @brief Repository veicoli condiviso (default reale; sovrascrivibile nei test).
final VeicoliRepository veicoliRepository = VeicoliRepository();
