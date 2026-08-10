import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:web_dashboard/api/api_config.dart';

/// @brief Eccezione applicativa di rete: porta il messaggio di dominio e il codice HTTP.
///
/// Normalizza gli errori del backend (campo `dettaglio`) e di trasporto, così che
/// la UI possa mostrare un messaggio leggibile senza conoscere i dettagli di Dio.
class LeafApiException implements Exception {
  /// @brief Crea l'eccezione con messaggio e codice opzionale.
  LeafApiException(this.messaggio, {this.codice});

  /// @brief Messaggio leggibile per l'utente.
  final String messaggio;

  /// @brief Codice HTTP associato (se disponibile).
  final int? codice;

  @override
  String toString() => messaggio;
}

/// @brief Custodia cifrata del token JWT (Keychain/Keystore/Web storage) — IIN-4.
///
/// Il token di sessione OP/PA non è mai salvato in chiaro: si appoggia
/// all'archivio sicuro di piattaforma fornito da `flutter_secure_storage`.
class TokenStore {
  /// @brief Crea la custodia; consente di iniettare uno storage fittizio nei test.
  TokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const String _chiave = 'leaf_jwt_web';

  /// @brief Salva il token JWT in modo cifrato.
  /// @param token Token di accesso da custodire.
  Future<void> salva(String token) =>
      _storage.write(key: _chiave, value: token);

  /// @brief Legge il token JWT custodito.
  /// @return Il token, o null se assente.
  Future<String?> leggi() => _storage.read(key: _chiave);

  /// @brief Cancella il token (logout).
  Future<void> cancella() => _storage.delete(key: _chiave);
}

/// @brief Client HTTP verso il backend LEAF: inietta il Bearer token e normalizza gli errori.
///
/// Espone l'istanza Dio (riusabile dai repository) e la custodia del token. Un
/// interceptor aggiunge automaticamente l'header `Authorization: Bearer <jwt>`
/// quando un token è presente.
class ApiClient {
  /// @brief Crea il client; Dio e TokenStore sono iniettabili (test).
  /// @param dio Istanza Dio personalizzata (opzionale).
  /// @param tokenStore Custodia del token personalizzata (opzionale).
  ApiClient({Dio? dio, TokenStore? tokenStore})
    : tokenStore = tokenStore ?? TokenStore(),
      dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: kLeafApiBase,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            ),
          ) {
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await this.tokenStore.leggi();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  /// @brief Istanza Dio condivisa coi repository.
  final Dio dio;

  /// @brief Custodia cifrata del token di sessione.
  final TokenStore tokenStore;

  /// @brief Converte un errore Dio nell'eccezione applicativa con messaggio di dominio.
  /// @param errore Errore sollevato da Dio.
  /// @return Eccezione applicativa leggibile.
  static LeafApiException erroreDa(DioException errore) {
    final dati = errore.response?.data;
    final dettaglio = (dati is Map)
        ? (dati['detail'] ?? dati['dettaglio'] ?? dati['messaggio'])?.toString()
        : null;
    return LeafApiException(
      dettaglio ?? 'Impossibile contattare il servizio. Riprova.',
      codice: errore.response?.statusCode,
    );
  }

  /// @brief Estrae il payload `dati` dall'inviluppo uniforme della API dati.
  ///
  /// Gli endpoint dati rispondono con `{disponibile, messaggio, dati}`: quando il
  /// servizio è ancora "in sviluppo" (`disponibile == false`) o non porta dati, si
  /// solleva un'eccezione col messaggio di dominio, così la UI mostra lo stato d'errore.
  ///
  /// @param risposta Risposta Dio con corpo a inviluppo.
  /// @return Mappa del payload `dati`.
  /// @throws LeafApiException Se il servizio non è disponibile o non ha prodotto dati.
  static Map<String, dynamic> payload(Response<dynamic> risposta) {
    final corpo = risposta.data;
    if (corpo is Map && corpo['disponibile'] == true && corpo['dati'] is Map) {
      return Map<String, dynamic>.from(corpo['dati'] as Map);
    }
    final messaggio = (corpo is Map && corpo['messaggio'] != null)
        ? corpo['messaggio'].toString()
        : 'Servizio non disponibile';
    throw LeafApiException(messaggio, codice: risposta.statusCode);
  }
}

/// @brief Istanza condivisa del client API (singleton applicativo).
final ApiClient apiClient = ApiClient();
