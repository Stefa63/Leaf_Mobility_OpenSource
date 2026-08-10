import 'package:dio/dio.dart';

import 'package:app_mobile_utente/api/api_client.dart';

/// @brief Contratto delle notifiche utente (UT.15/UT.19, IIN-19), iniettabile nei test.
abstract class NotificheApi {
  /// @brief Elenca le notifiche dell'utente autenticato e i broadcast.
  /// @param soloNonLette Se true restituisce solo le notifiche non lette.
  /// @return Lista di notifiche (documenti grezzi della API), dalla più recente.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> elenco({bool soloNonLette = false});

  /// @brief Marca una notifica come letta.
  /// @param idNotifica Id della notifica.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<void> segnaLetta(String idNotifica);
}

/// @brief Implementazione di [NotificheApi] su `/api/v1/notifiche` via Dio (Bearer automatico).
class NotificheRepository implements NotificheApi {
  /// @brief Crea il repository; il client API è iniettabile nei test.
  NotificheRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<List<Map<String, dynamic>>> elenco({bool soloNonLette = false}) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/notifiche',
        queryParameters: {'solo_non_lette': soloNonLette},
      );
      final dati = ApiClient.payload(risposta);
      final notifiche = (dati['notifiche'] as List?) ?? const [];
      return notifiche
          .map((n) => Map<String, dynamic>.from(n as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<void> segnaLetta(String idNotifica) async {
    try {
      await _client.dio.post<dynamic>('/notifiche/$idNotifica/letta');
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

/// @brief Repository notifiche condiviso (default reale; sovrascrivibile nei test).
final NotificheRepository notificheRepository = NotificheRepository();
