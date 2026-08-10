import 'package:dio/dio.dart';

import 'package:web_dashboard/api/api_client.dart';

/// @brief Contratto delle prenotazioni lato operatore (OP.12), iniettabile nei test.
abstract class PrenotazioniOpApi {
  /// @brief Elenca tutte le prenotazioni attive della flotta (OP.12).
  /// @return Lista delle prenotazioni attive (con etichetta utente risolta lato server).
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> attive();

  /// @brief Forza l'annullamento di una prenotazione attiva (OP.12).
  /// @param idPrenotazione Id della prenotazione da annullare.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<void> annulla(String idPrenotazione);
}

/// @brief Implementazione di [PrenotazioniOpApi] su `/api/v1` via Dio (Bearer OP).
class PrenotazioniOpRepository implements PrenotazioniOpApi {
  /// @brief Crea il repository; il client API è iniettabile nei test.
  PrenotazioniOpRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<List<Map<String, dynamic>>> attive() async {
    try {
      final risposta = await _client.dio.get<dynamic>('/prenotazioni/attive');
      final dati = ApiClient.payload(risposta);
      final pren = (dati['prenotazioni'] as List?) ?? const [];
      return pren
          .map((p) => Map<String, dynamic>.from(p as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<void> annulla(String idPrenotazione) async {
    try {
      await _client.dio.post<dynamic>('/prenotazioni/$idPrenotazione/annulla-op');
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

/// @brief Repository prenotazioni OP condiviso (default reale; sovrascrivibile nei test).
final PrenotazioniOpRepository prenotazioniOpRepository =
    PrenotazioniOpRepository();
