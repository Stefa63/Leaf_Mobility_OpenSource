import 'package:dio/dio.dart';

import 'package:web_dashboard/api/api_client.dart';

/// @brief Contratto dei grandi eventi cittadini su mappa (AP.09).
abstract class EventiApi {
  /// @brief Elenca i grandi eventi cittadini configurati.
  /// @return Lista di eventi (aree limitate di tipo "evento", con date e perimetro).
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> elenco();

  /// @brief Inserisce un evento cittadino tipizzato su mappa (AP.09/AP.04).
  /// @param nome Nome dell'evento.
  /// @param categoria Categoria (grande_evento / cantiere / interruzione).
  /// @param dataInizio Data di inizio (ISO-8601).
  /// @param dataFine Data di fine (ISO-8601).
  /// @param poligono Perimetro geografico come lista di coppie [lat, lon].
  /// @param area Area/quartiere interessato (opzionale).
  /// @return Id dell'evento creato.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<String> crea({
    required String nome,
    required String categoria,
    required String dataInizio,
    required String dataFine,
    required List<List<double>> poligono,
    String? area,
  });

  /// @brief Elimina un evento cittadino dalla mappa (AP.09).
  /// @param idEvento Id dell'evento (area di tipo "evento") da rimuovere.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<void> elimina(String idEvento);
}

/// @brief Implementazione di [EventiApi] su `/api/v1` via Dio (Bearer PA).
class EventsRepository implements EventiApi {
  /// @brief Crea il repository; il client API è iniettabile nei test.
  EventsRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<List<Map<String, dynamic>>> elenco() async {
    try {
      final risposta = await _client.dio.get<dynamic>('/eventi');
      final dati = ApiClient.payload(risposta);
      final eventi = (dati['eventi'] as List?) ?? const [];
      return eventi
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<String> crea({
    required String nome,
    required String categoria,
    required String dataInizio,
    required String dataFine,
    required List<List<double>> poligono,
    String? area,
  }) async {
    try {
      final risposta = await _client.dio.post<dynamic>(
        '/eventi',
        data: {
          'nome': nome,
          'categoria': categoria,
          'data_inizio': dataInizio,
          'data_fine': dataFine,
          'poligono': poligono,
          if (area != null && area.isNotEmpty) 'area': area,
        },
      );
      return ApiClient.payload(risposta)['id_evento'].toString();
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<void> elimina(String idEvento) async {
    try {
      await _client.dio.delete<dynamic>('/eventi/$idEvento');
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

/// @brief Repository eventi condiviso (default reale; sovrascrivibile nei test).
final EventsRepository eventsRepository = EventsRepository();
