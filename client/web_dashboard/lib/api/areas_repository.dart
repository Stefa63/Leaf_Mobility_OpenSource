import 'package:dio/dio.dart';

import 'package:web_dashboard/api/api_client.dart';

/// @brief Contratto di accesso alle aree di geofencing (AP.04/06/08).
abstract class AreeApi {
  /// @brief Elenca le aree limitate configurate.
  /// @param soloAttive Se true, restituisce solo le aree attive.
  /// @return Lista di aree (documenti grezzi della API).
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> elenco({bool soloAttive = false});

  /// @brief Crea una nuova area limitata.
  /// @param dati Definizione area (tipo, nome, poligono, limite_velocita_kmh).
  /// @return Id dell'area creata.
  /// @throws LeafApiException Su errore di rete o validazione.
  Future<String> crea(Map<String, dynamic> dati);

  /// @brief Elimina un'area limitata (riapertura al transito, AP.04).
  /// @param idArea Id dell'area da eliminare.
  /// @throws LeafApiException Su errore di rete.
  Future<void> elimina(String idArea);
}

/// @brief Implementazione di [AreeApi] su `/api/v1/aree` via Dio (Bearer PA/OP).
class AreasRepository implements AreeApi {
  /// @brief Crea il repository; il client API è iniettabile nei test.
  AreasRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<List<Map<String, dynamic>>> elenco({bool soloAttive = false}) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/aree',
        queryParameters: {'solo_attive': soloAttive},
      );
      final dati = ApiClient.payload(risposta);
      final aree = (dati['aree'] as List?) ?? const [];
      return aree
          .map((a) => Map<String, dynamic>.from(a as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<String> crea(Map<String, dynamic> dati) async {
    try {
      final risposta = await _client.dio.post<dynamic>('/aree', data: dati);
      final payload = ApiClient.payload(risposta);
      return '${payload['id_area'] ?? ''}';
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<void> elimina(String idArea) async {
    try {
      await _client.dio.delete<dynamic>('/aree/$idArea');
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

/// @brief Repository aree condiviso (default reale; sovrascrivibile nei test).
final AreasRepository areasRepository = AreasRepository();
