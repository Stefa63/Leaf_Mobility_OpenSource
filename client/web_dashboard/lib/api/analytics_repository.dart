import 'package:dio/dio.dart';

import 'package:web_dashboard/api/api_client.dart';

/// @brief Contratto di accesso alle analitiche aggregate e anonime (AP.01/02/07, IIN-15).
abstract class AnalyticsApi {
  /// @brief Aggregati di mobilità per tipo di mezzo, opzionalmente in un intervallo.
  /// @param dallaData Inizio intervallo ISO-8601 (opzionale).
  /// @param allaData Fine intervallo ISO-8601 (opzionale).
  /// @return Lista di aggregati per tipo (documenti grezzi della API).
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> perTipo({
    String? dallaData,
    String? allaData,
  });

  /// @brief Conteggio noleggi per tipologia di mezzo, anonimo (AP.01, IIN-15).
  /// @param dallaData Inizio intervallo ISO-8601 (opzionale).
  /// @param allaData Fine intervallo ISO-8601 (opzionale).
  /// @return Mappa `{noleggi: {tipo: conteggio}}` dal backend.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<Map<String, dynamic>> noleggiPerTipo({
    String? dallaData,
    String? allaData,
  });

  /// @brief Distribuzione dei noleggi per fascia oraria, anonima (AP.02, IIN-15).
  /// @param dallaData Inizio intervallo ISO-8601 (opzionale).
  /// @param allaData Fine intervallo ISO-8601 (opzionale).
  /// @return Mappa `{flussi: {ora: conteggio}}` dal backend.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<Map<String, dynamic>> flussiOrari({
    String? dallaData,
    String? allaData,
  });

  /// @brief Percentuale mezzi operativi vs manutenzione vs scarico (AP.03).
  /// @return Mappa `{operativi, manutenzione, scarico}` dal backend.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<Map<String, dynamic>> percentualiOperativi();

  /// @brief Stima della CO₂ risparmiata dalla flotta elettrica, anonima (AP.07, IIN-15).
  /// @param dallaData Inizio intervallo ISO-8601 (opzionale).
  /// @param allaData Fine intervallo ISO-8601 (opzionale).
  /// @return Mappa `{km_totali, co2_risparmiata_kg, km_per_tipo}` dal backend.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<Map<String, dynamic>> co2Risparmiata({
    String? dallaData,
    String? allaData,
  });
}

/// @brief Implementazione di [AnalyticsApi] su `/api/v1/analitiche` via Dio (Bearer PA/OP).
class AnalyticsRepository implements AnalyticsApi {
  /// @brief Crea il repository; il client API è iniettabile nei test.
  AnalyticsRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<List<Map<String, dynamic>>> perTipo({
    String? dallaData,
    String? allaData,
  }) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/analitiche',
        queryParameters: {'dalla_data': ?dallaData, 'alla_data': ?allaData},
      );
      final dati = ApiClient.payload(risposta);
      final aggregati = (dati['per_tipo'] as List?) ?? const [];
      return aggregati
          .map((a) => Map<String, dynamic>.from(a as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<Map<String, dynamic>> noleggiPerTipo({
    String? dallaData,
    String? allaData,
  }) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/analitiche/noleggi',
        queryParameters: {'dalla_data': ?dallaData, 'alla_data': ?allaData},
      );
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<Map<String, dynamic>> flussiOrari({
    String? dallaData,
    String? allaData,
  }) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/analitiche/flussi',
        queryParameters: {'dalla_data': ?dallaData, 'alla_data': ?allaData},
      );
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<Map<String, dynamic>> percentualiOperativi() async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/analitiche/operativi',
      );
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<Map<String, dynamic>> co2Risparmiata({
    String? dallaData,
    String? allaData,
  }) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/analitiche/co2',
        queryParameters: {'dalla_data': ?dallaData, 'alla_data': ?allaData},
      );
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

/// @brief Repository analitiche condiviso (default reale; sovrascrivibile nei test).
final AnalyticsRepository analyticsRepository = AnalyticsRepository();
