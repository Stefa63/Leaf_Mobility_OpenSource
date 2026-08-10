import 'package:dio/dio.dart';

import 'package:web_dashboard/api/api_client.dart';

/// @brief Contratto di accesso alla coda di assistenza lato operatore (OP.08).
abstract class AssistenzaApi {
  /// @brief Coda centralizzata delle richieste di assistenza.
  /// @param stato Filtro opzionale su stato (aperto/in_lavorazione/chiuso).
  /// @return Lista di ticket (documenti grezzi della API).
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> coda({String? stato});

  /// @brief Prende in carico e/o risponde a un ticket (OP.08).
  /// @param idTicket Id del ticket di assistenza.
  /// @param risposta Testo della risposta all'utente.
  /// @param stato Nuovo stato (aperto/in_lavorazione/chiuso).
  /// @throws LeafApiException Su errore di rete.
  Future<void> rispondi(
    String idTicket,
    String risposta, {
    String stato = 'in_lavorazione',
  });
}

/// @brief Implementazione di [AssistenzaApi] su `/api/v1/assistenza` via Dio (Bearer OP).
class AssistenzaRepository implements AssistenzaApi {
  /// @brief Crea il repository; il client API è iniettabile nei test.
  AssistenzaRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<List<Map<String, dynamic>>> coda({String? stato}) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/assistenza',
        queryParameters: {'stato': ?stato},
      );
      final dati = ApiClient.payload(risposta);
      final ticket = (dati['ticket'] as List?) ?? const [];
      return ticket
          .map((t) => Map<String, dynamic>.from(t as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<void> rispondi(
    String idTicket,
    String risposta, {
    String stato = 'in_lavorazione',
  }) async {
    try {
      await _client.dio.put<dynamic>(
        '/assistenza/$idTicket/risposta',
        data: {'risposta': risposta, 'stato': stato},
      );
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

/// @brief Repository assistenza condiviso (default reale; sovrascrivibile nei test).
final AssistenzaRepository assistenzaRepository = AssistenzaRepository();
