import 'package:dio/dio.dart';

import 'package:web_dashboard/api/api_client.dart';

/// @brief Contratto dei ticket di manutenzione veicoli (OP.16/OP.19).
abstract class ManutenzioneApi {
  /// @brief Elenca i ticket di manutenzione, opzionalmente filtrati per stato.
  /// @param stato Filtro opzionale (aperto/assegnato/chiuso).
  /// @return Lista di ticket di manutenzione.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> elenco({String? stato});

  /// @brief Elenca i tecnici manutentori assegnabili (OP.16).
  /// @return Lista di tecnici.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> elencoTecnici();

  /// @brief Crea un ticket di manutenzione per un mezzo guasto (OP.16/OP.19).
  /// @param idMezzo Id del mezzo guasto.
  /// @param descrizione Descrizione del guasto/intervento.
  /// @param priorita Priorità: bassa | media | alta.
  /// @return Id del ticket creato.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<String> crea({
    required String idMezzo,
    required String descrizione,
    String priorita = 'media',
  });

  /// @brief Assegna un ticket a un tecnico registrato (OP.16).
  /// @param idTicket Id del ticket.
  /// @param idTecnico Id del tecnico assegnatario.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<void> assegna(String idTicket, String idTecnico);

  /// @brief Chiude un ticket a intervento concluso (OP.19).
  /// @param idTicket Id del ticket.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<void> chiudi(String idTicket);
}

/// @brief Implementazione di [ManutenzioneApi] su `/api/v1` via Dio (Bearer OP).
class MaintenanceRepository implements ManutenzioneApi {
  /// @brief Crea il repository; il client API è iniettabile nei test.
  MaintenanceRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<List<Map<String, dynamic>>> elenco({String? stato}) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/manutenzione',
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
  Future<List<Map<String, dynamic>>> elencoTecnici() async {
    try {
      final risposta = await _client.dio.get<dynamic>('/tecnici');
      final dati = ApiClient.payload(risposta);
      final tecnici = (dati['tecnici'] as List?) ?? const [];
      return tecnici
          .map((t) => Map<String, dynamic>.from(t as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<String> crea({
    required String idMezzo,
    required String descrizione,
    String priorita = 'media',
  }) async {
    try {
      final risposta = await _client.dio.post<dynamic>(
        '/manutenzione',
        data: {
          'id_mezzo': idMezzo,
          'descrizione': descrizione,
          'priorita': priorita,
        },
      );
      return ApiClient.payload(risposta)['id_ticket'].toString();
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<void> assegna(String idTicket, String idTecnico) async {
    try {
      await _client.dio.put<dynamic>(
        '/manutenzione/$idTicket/assegna',
        data: {'id_tecnico': idTecnico},
      );
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<void> chiudi(String idTicket) async {
    try {
      await _client.dio.put<dynamic>('/manutenzione/$idTicket/chiudi');
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

/// @brief Repository manutenzione condiviso (default reale; sovrascrivibile nei test).
final MaintenanceRepository maintenanceRepository = MaintenanceRepository();
