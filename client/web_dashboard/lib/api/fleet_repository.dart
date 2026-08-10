import 'package:dio/dio.dart';

import 'package:web_dashboard/api/api_client.dart';

/// @brief Contratto di accesso allo stato della flotta (OP.01/03/20, AP.03/10).
abstract class FlottaApi {
  /// @brief Elenca i mezzi della flotta, opzionalmente filtrati per stato.
  /// @param stato Filtro opzionale su stato operativo (es. "guasto" per OP.03).
  /// @return Lista di mezzi (documenti grezzi della API).
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> elenco({String? stato});

  /// @brief Elenca i mezzi in stato "Guasto" da ritirare (OP.03).
  /// @return Lista di mezzi guasti.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> mezziGuasti();

  /// @brief Report giornaliero dei mezzi per stato e batteria scarica (OP.13).
  /// @return Mappa `{per_stato, batteria_scarica, totale}`.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<Map<String, dynamic>> reportGiornaliero();

  /// @brief Valuta le soglie configurate e restituisce le allerte attive (OP.02/OP.22).
  /// @return Lista di allerte attive.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> soglieAllerte();

  /// @brief Imposta la soglia minima di mezzi per un'area (OP.02).
  /// @param idArea Id dell'area.
  /// @param minimo Numero minimo di mezzi richiesti.
  /// @return Id della soglia creata.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<String> impostaSogliaArea({
    required String idArea,
    required int minimo,
  });

  /// @brief Imposta la soglia di allerta batteria (OP.22).
  /// @param percentuale Percentuale di allerta.
  /// @param tipoMezzo Tipologia di mezzo (opzionale).
  /// @return Id della soglia creata.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<String> impostaSogliaBatteria({
    required int percentuale,
    String? tipoMezzo,
  });

  /// @brief Registro telemetrico di un mezzo (sblocchi, urti, anomalie, GPS) (OP.07/14).
  /// @param codice Codice identificativo del mezzo.
  /// @return Lista di eventi telemetrici.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> telemetria(String codice);

  /// @brief Invia il blocco motore remoto anti-spostamento a un mezzo (OP.11).
  /// @param codice Codice identificativo del mezzo da immobilizzare.
  /// @return Mappa con l'esito del comando.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<Map<String, dynamic>> bloccoMotore(String codice);

  /// @brief Revoca il blocco motore remoto e riabilita un mezzo (OP.11).
  /// @param codice Codice identificativo del mezzo da riabilitare.
  /// @return Mappa con l'esito del comando.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<Map<String, dynamic>> sbloccoMotore(String codice);
}

/// @brief Implementazione di [FlottaApi] su `/api/v1/flotta` via Dio (Bearer OP/PA).
class FleetRepository implements FlottaApi {
  /// @brief Crea il repository; il client API è iniettabile nei test.
  FleetRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<List<Map<String, dynamic>>> elenco({String? stato}) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/flotta',
        queryParameters: {'stato': ?stato},
      );
      final dati = ApiClient.payload(risposta);
      final mezzi = (dati['mezzi'] as List?) ?? const [];
      return mezzi
          .map((m) => Map<String, dynamic>.from(m as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> mezziGuasti() async {
    try {
      final risposta = await _client.dio.get<dynamic>('/mezzi-guasti');
      final dati = ApiClient.payload(risposta);
      final mezzi = (dati['mezzi'] as List?) ?? const [];
      return mezzi
          .map((m) => Map<String, dynamic>.from(m as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<Map<String, dynamic>> reportGiornaliero() async {
    try {
      final risposta = await _client.dio.get<dynamic>('/flotta/report');
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> soglieAllerte() async {
    try {
      final risposta = await _client.dio.get<dynamic>('/soglie/allerte');
      final dati = ApiClient.payload(risposta);
      final allerte = (dati['allerte'] as List?) ?? const [];
      return allerte
          .map((a) => Map<String, dynamic>.from(a as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<String> impostaSogliaArea({
    required String idArea,
    required int minimo,
  }) async {
    try {
      final risposta = await _client.dio.post<dynamic>(
        '/soglie/area',
        data: {'id_area': idArea, 'minimo': minimo},
      );
      return ApiClient.payload(risposta)['id_soglia']?.toString() ?? '';
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<String> impostaSogliaBatteria({
    required int percentuale,
    String? tipoMezzo,
  }) async {
    try {
      final risposta = await _client.dio.post<dynamic>(
        '/soglie/batteria',
        data: {'percentuale': percentuale, 'tipo_mezzo': tipoMezzo},
      );
      return ApiClient.payload(risposta)['id_soglia']?.toString() ?? '';
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> telemetria(String codice) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/mezzi/$codice/telemetria',
      );
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
  Future<Map<String, dynamic>> bloccoMotore(String codice) async {
    try {
      final risposta = await _client.dio.post<dynamic>(
        '/mezzi/$codice/blocco-motore',
      );
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<Map<String, dynamic>> sbloccoMotore(String codice) async {
    try {
      final risposta = await _client.dio.post<dynamic>(
        '/mezzi/$codice/sblocco-motore',
      );
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

/// @brief Repository flotta condiviso (default reale; sovrascrivibile nei test).
final FleetRepository fleetRepository = FleetRepository();
