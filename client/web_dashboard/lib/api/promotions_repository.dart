import 'package:dio/dio.dart';

import 'package:web_dashboard/api/api_client.dart';

/// @brief Contratto delle promozioni e incentivi geografici (OP.09/OP.15).
abstract class PromozioniApi {
  /// @brief Elenca le promozioni configurate, opzionalmente solo le attive.
  /// @param soloAttive Se true, restituisce solo le promozioni attive.
  /// @return Lista di promozioni.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> elenco({bool soloAttive = false});

  /// @brief Configura una promozione/incentivo geografico (OP.09/OP.15).
  /// @param tipo Tipo (sconto_percentuale/credito_bonus_parcheggio/sconto_geografico/tariffa_evento).
  /// @param descrizione Descrizione leggibile della promozione.
  /// @param valore Valore numerico opzionale (es. percentuale di sconto).
  /// @param idArea Id dell'area che circoscrive l'ambito geografico (opzionale).
  /// @return Id della promozione creata.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<String> crea({
    required String tipo,
    required String descrizione,
    num? valore,
    String? idArea,
  });

  /// @brief Disattiva una promozione configurata (OP.15).
  /// @param idPromozione Id della promozione da disattivare.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<void> disattiva(String idPromozione);
}

/// @brief Implementazione di [PromozioniApi] su `/api/v1` via Dio (Bearer OP).
class PromotionsRepository implements PromozioniApi {
  /// @brief Crea il repository; il client API è iniettabile nei test.
  PromotionsRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<List<Map<String, dynamic>>> elenco({bool soloAttive = false}) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/promozioni',
        queryParameters: {'solo_attive': soloAttive},
      );
      final dati = ApiClient.payload(risposta);
      final promozioni = (dati['promozioni'] as List?) ?? const [];
      return promozioni
          .map((p) => Map<String, dynamic>.from(p as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<String> crea({
    required String tipo,
    required String descrizione,
    num? valore,
    String? idArea,
  }) async {
    try {
      final risposta = await _client.dio.post<dynamic>(
        '/promozioni',
        data: {
          'tipo': tipo,
          'descrizione': descrizione,
          'valore': ?valore,
          'id_area': ?idArea,
        },
      );
      return ApiClient.payload(risposta)['id_promozione'].toString();
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<void> disattiva(String idPromozione) async {
    try {
      await _client.dio.delete<dynamic>('/promozioni/$idPromozione');
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

/// @brief Repository promozioni condiviso (default reale; sovrascrivibile nei test).
final PromotionsRepository promotionsRepository = PromotionsRepository();
