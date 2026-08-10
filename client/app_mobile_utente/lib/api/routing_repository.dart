import 'package:dio/dio.dart';

import 'package:app_mobile_utente/api/api_client.dart';

/// @brief Suggerimento di luogo (autocompletamento) dal gazetteer del server (UT.07).
class LuogoSuggerito {
  /// @brief Crea il suggerimento di luogo.
  /// @param nome Nome canonico del luogo.
  /// @param lat Latitudine del luogo (gradi decimali).
  /// @param lon Longitudine del luogo (gradi decimali).
  const LuogoSuggerito({
    required this.nome,
    required this.lat,
    required this.lon,
  });

  /// Nome canonico del luogo mostrato nei suggerimenti.
  final String nome;

  /// Latitudine del luogo (gradi decimali, WGS84).
  final double lat;

  /// Longitudine del luogo (gradi decimali, WGS84).
  final double lon;

  /// @brief Costruisce il suggerimento da un elemento `luoghi` della API.
  /// @param mappa Elemento grezzo `{nome, lat, lon}` del payload `/geocoding`.
  /// @return Il modello di vista del suggerimento.
  factory LuogoSuggerito.daApi(Map<String, dynamic> mappa) => LuogoSuggerito(
    nome: '${mappa['nome'] ?? ''}',
    lat: ((mappa['lat'] ?? 0) as num).toDouble(),
    lon: ((mappa['lon'] ?? 0) as num).toDouble(),
  );
}

/// @brief Contratto di ricerca percorsi e geocoding (UT.07/UT.08), iniettabile nei test.
abstract class RoutingApi {
  /// @brief Suggerimenti di luogo per l'autocompletamento (gazetteer server).
  /// @param query Testo parziale digitato dall'utente.
  /// @return Elenco di luoghi suggeriti (vuoto se la query è vuota).
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<LuogoSuggerito>> suggerisci(String query);

  /// @brief Opzioni di percorso multimodali tra due luoghi (per nome o coordinate).
  /// @param da Nome del luogo di partenza (geocodificato dal server).
  /// @param a Nome del luogo di arrivo (geocodificato dal server).
  /// @param daLat Latitudine di partenza, che prevale su [da] (es. posizione corrente).
  /// @param daLon Longitudine di partenza, che prevale su [da].
  /// @param aLat Latitudine di arrivo, che prevale su [a].
  /// @param aLon Longitudine di arrivo, che prevale su [a].
  /// @return Payload `{origine, destinazione, percorsi, totale}`.
  /// @throws LeafApiException Se un luogo non è riconosciuto o su errore di rete.
  Future<Map<String, dynamic>> percorsi({
    String? da,
    String? a,
    double? daLat,
    double? daLon,
    double? aLat,
    double? aLon,
  });
}

/// @brief Implementazione di [RoutingApi] su `/api/v1/geocoding` e `/api/v1/percorsi` via Dio.
class RoutingRepository implements RoutingApi {
  /// @brief Crea il repository; il client API è iniettabile nei test.
  RoutingRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<List<LuogoSuggerito>> suggerisci(String query) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/geocoding',
        queryParameters: {'q': query},
      );
      final dati = ApiClient.payload(risposta);
      final luoghi = (dati['luoghi'] as List?) ?? const [];
      return luoghi
          .map((e) => LuogoSuggerito.daApi(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<Map<String, dynamic>> percorsi({
    String? da,
    String? a,
    double? daLat,
    double? daLon,
    double? aLat,
    double? aLon,
  }) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/percorsi',
        queryParameters: {
          'da': ?da,
          'a': ?a,
          'da_lat': ?daLat,
          'da_lon': ?daLon,
          'a_lat': ?aLat,
          'a_lon': ?aLon,
        },
      );
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

/// @brief Repository di routing condiviso (default reale; sovrascrivibile nei test).
final RoutingRepository routingRepository = RoutingRepository();
