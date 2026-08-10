import 'package:dio/dio.dart';

import 'package:web_dashboard/api/api_client.dart';

/// @brief Contratto di accesso alle notifiche (UT.15/UT.19, IIN-19).
abstract class NotificheApi {
  /// @brief Elenca le notifiche dell'account autenticato e broadcast.
  /// @param soloNonLette Se true, restituisce solo le notifiche non lette.
  /// @return Lista di notifiche (documenti grezzi della API).
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> elenco({bool soloNonLette = false});

  /// @brief Marca una notifica come letta (UT.15/UT.19).
  /// @param idNotifica Id della notifica.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<void> segnaLetta(String idNotifica);

  /// @brief Pubblica una notifica broadcast di servizio (UT.19, OP/PA).
  /// @param titolo Titolo della notifica.
  /// @param messaggio Corpo della notifica.
  /// @param tipo Tipo della notifica (default "servizio").
  /// @return Id della notifica creata.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<String> crea({
    required String titolo,
    required String messaggio,
    String tipo = 'servizio',
  });
}

/// @brief Implementazione di [NotificheApi] su `/api/v1/notifiche` via Dio (Bearer).
class NotificationsRepository implements NotificheApi {
  /// @brief Crea il repository; il client API è iniettabile nei test.
  NotificationsRepository({ApiClient? client}) : _client = client ?? apiClient;

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

  @override
  Future<String> crea({
    required String titolo,
    required String messaggio,
    String tipo = 'servizio',
  }) async {
    try {
      final risposta = await _client.dio.post<dynamic>(
        '/notifiche',
        data: {'titolo': titolo, 'messaggio': messaggio, 'tipo': tipo},
      );
      return ApiClient.payload(risposta)['id_notifica']?.toString() ?? '';
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

/// @brief Repository notifiche condiviso (default reale; sovrascrivibile nei test).
final NotificationsRepository notificationsRepository =
    NotificationsRepository();
