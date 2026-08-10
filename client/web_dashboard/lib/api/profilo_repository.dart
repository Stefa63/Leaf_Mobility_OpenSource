import 'package:dio/dio.dart';

import 'package:web_dashboard/api/api_client.dart';

/// @brief Contratto di accesso al profilo dell'account OP/PA autenticato (UT.21 lato dashboard).
abstract class ProfiloApi {
  /// @brief Recupera i dati del profilo dell'account autenticato.
  /// @return Vista profilo (mai contenente la password hash).
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<Map<String, dynamic>> profilo();

  /// @brief Aggiorna i dati anagrafici del profilo (whitelist server-side).
  /// @param modifiche Coppie campo→valore da aggiornare (nome, cognome, telefono).
  /// @return Vista profilo aggiornata.
  /// @throws LeafApiException Su errore di rete o conflitto.
  Future<Map<String, dynamic>> aggiorna(Map<String, dynamic> modifiche);
}

/// @brief Implementazione di [ProfiloApi] su `/api/v1/profilo` via Dio (Bearer).
class ProfiloRepository implements ProfiloApi {
  /// @brief Crea il repository; il client API è iniettabile nei test.
  ProfiloRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<Map<String, dynamic>> profilo() async {
    try {
      final risposta = await _client.dio.get<dynamic>('/profilo');
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<Map<String, dynamic>> aggiorna(Map<String, dynamic> modifiche) async {
    try {
      final risposta = await _client.dio.put<dynamic>(
        '/profilo',
        data: modifiche,
      );
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

/// @brief Repository profilo condiviso (default reale; sovrascrivibile nei test).
final ProfiloRepository profiloRepository = ProfiloRepository();
