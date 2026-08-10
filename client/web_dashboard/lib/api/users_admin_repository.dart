import 'package:dio/dio.dart';

import 'package:web_dashboard/api/api_client.dart';

/// @brief Contratto di gestione account per l'operatore (OP.10/OP.17/OP.18).
abstract class GestioneUtentiApi {
  /// @brief Elenca gli account, opzionalmente filtrati per ruolo RBAC.
  /// @param ruolo Filtro opzionale (UT/OP/PA); null = tutti.
  /// @return Lista di account (campi riservati già redatti lato server).
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> elencoAccount({String? ruolo});

  /// @brief Sospende o riattiva un account utente (OP.10 sospendi / OP.18 sblocca).
  /// @param idAccount Id dell'account su cui agire.
  /// @param stato Nuovo stato: "attivo" oppure "sospeso".
  /// @return Vista account aggiornata.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<Map<String, dynamic>> impostaStato(String idAccount, String stato);

  /// @brief Provisiona un account Amministrazione Pubblica (OP.17, IIN-12).
  /// @param email Email di accesso univoca.
  /// @param username Username univoco.
  /// @param ente Nome dell'ente.
  /// @param emailIstituzionale Email istituzionale per il reset (AP.12).
  /// @return {id_account, password_temporanea} — la temporanea va mostrata una volta.
  /// @throws LeafApiException Su errore di rete o conflitto (email/username in uso).
  Future<Map<String, dynamic>> provisionaPa({
    required String email,
    required String username,
    required String ente,
    required String emailIstituzionale,
  });
}

/// @brief Implementazione di [GestioneUtentiApi] su `/api/v1` via Dio (Bearer OP).
class UsersAdminRepository implements GestioneUtentiApi {
  /// @brief Crea il repository; il client API è iniettabile nei test.
  UsersAdminRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<List<Map<String, dynamic>>> elencoAccount({String? ruolo}) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/utenti',
        queryParameters: {'ruolo': ?ruolo},
      );
      final dati = ApiClient.payload(risposta);
      final account = (dati['account'] as List?) ?? const [];
      return account
          .map((a) => Map<String, dynamic>.from(a as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<Map<String, dynamic>> impostaStato(
    String idAccount,
    String stato,
  ) async {
    try {
      final risposta = await _client.dio.put<dynamic>(
        '/utenti/$idAccount/stato',
        data: {'stato': stato},
      );
      final dati = ApiClient.payload(risposta);
      return Map<String, dynamic>.from(dati['account'] as Map);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<Map<String, dynamic>> provisionaPa({
    required String email,
    required String username,
    required String ente,
    required String emailIstituzionale,
  }) async {
    try {
      final risposta = await _client.dio.post<dynamic>(
        '/amministrazioni',
        data: {
          'email': email,
          'username': username,
          'ente': ente,
          'email_istituzionale': emailIstituzionale,
        },
      );
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

/// @brief Repository gestione utenti condiviso (default reale; sovrascrivibile nei test).
final UsersAdminRepository usersAdminRepository = UsersAdminRepository();
