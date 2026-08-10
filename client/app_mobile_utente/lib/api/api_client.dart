import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:app_mobile_utente/api/api_config.dart';

/// @brief Eccezione applicativa di rete: porta il messaggio di dominio e il codice HTTP.
///
/// Normalizza gli errori del backend (campo `dettaglio`) e di trasporto, cosi' che
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

/// @brief Custodia cifrata del token JWT on-device (Keychain/Keystore) — TD-10 / IIN-4.
///
/// I dati sensibili (token di sessione) non sono mai salvati in chiaro: si appoggiano
/// all'archivio sicuro di piattaforma fornito da `flutter_secure_storage`.
class TokenStore {
  /// @brief Crea la custodia; consente di iniettare uno storage fittizio nei test.
  TokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const String _chiave = 'leaf_jwt';

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

/// @brief Custodia dell'identificativo stabile del dispositivo (IIN-14).
///
/// Il backend limita a 3 i dispositivi attivi per utente: il client invia al login un
/// `device_id` stabile, generato una sola volta al primo avvio (UUID v4) e conservato
/// nell'archivio sicuro di piattaforma (`flutter_secure_storage`, nessuna dipendenza nuova).
class DeviceIdStore {
  /// @brief Crea la custodia; consente di iniettare uno storage fittizio nei test.
  DeviceIdStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const String _chiave = 'leaf_device_id';

  /// @brief Restituisce il device_id stabile, generandolo e salvandolo al primo accesso.
  /// @return Identificativo univoco e persistente del dispositivo (UUID v4).
  Future<String> ottieni() async {
    final esistente = await _storage.read(key: _chiave);
    if (esistente != null && esistente.isNotEmpty) return esistente;
    final nuovo = _generaUuidV4();
    await _storage.write(key: _chiave, value: nuovo);
    return nuovo;
  }

  /// @brief Genera un UUID v4 con sorgente casuale crittografica (RFC 4122).
  /// @return Stringa UUID v4 (8-4-4-4-12 cifre esadecimali).
  static String _generaUuidV4() {
    final rnd = Random.secure();
    final byte = List<int>.generate(16, (_) => rnd.nextInt(256));
    byte[6] = (byte[6] & 0x0f) | 0x40; // versione 4
    byte[8] = (byte[8] & 0x3f) | 0x80; // variante RFC 4122
    final hex = byte.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}'
        '-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

/// @brief Client HTTP verso il backend LEAF: inietta il Bearer token e normalizza gli errori.
///
/// Espone l'istanza Dio (riusabile dai repository) e la custodia del token. Un interceptor
/// aggiunge automaticamente l'header `Authorization: Bearer <jwt>` quando un token e' presente.
class ApiClient {
  /// @brief Crea il client; Dio, TokenStore e DeviceIdStore sono iniettabili (test).
  /// @param dio Istanza Dio personalizzata (opzionale).
  /// @param tokenStore Custodia del token personalizzata (opzionale).
  /// @param deviceIdStore Custodia del device_id personalizzata (opzionale, IIN-14).
  ApiClient({Dio? dio, TokenStore? tokenStore, DeviceIdStore? deviceIdStore})
    : tokenStore = tokenStore ?? TokenStore(),
      deviceIdStore = deviceIdStore ?? DeviceIdStore(),
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

  /// @brief Custodia dell'identificativo stabile del dispositivo (IIN-14).
  final DeviceIdStore deviceIdStore;

  /// @brief Interceptor di log verboso (modalita' sviluppatore), se attivo.
  ///
  /// Tenuto come riferimento per poterlo rimuovere quando la modalita' viene
  /// disattivata, evitando di accumulare interceptor duplicati.
  Interceptor? _logInterceptor;

  /// @brief Ripunta il client a un nuovo URL base (es. server LAN in debug).
  ///
  /// Usato dalla Modalita' sviluppatore per cambiare endpoint a runtime senza
  /// ricompilare. Se [base] e' vuoto non modifica nulla.
  /// @param base Nuovo URL base completo (`http://host:porta/api/v1`).
  void applicaBaseUrl(String base) {
    if (base.trim().isEmpty) return;
    dio.options.baseUrl = base.trim();
  }

  /// @brief Attiva/disattiva il log verboso delle richieste (debug USB).
  ///
  /// Con `flutter run` collegato via USB, il [LogInterceptor] stampa richieste e
  /// risposte sulla console, utile per diagnosticare i problemi di connettivita'.
  /// @param attivo True per abilitare il log, False per rimuoverlo.
  void abilitaLogVerboso(bool attivo) {
    if (attivo && _logInterceptor == null) {
      _logInterceptor = LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        logPrint: (Object o) => debugPrint('[LEAF-API] $o'),
      );
      dio.interceptors.add(_logInterceptor!);
    } else if (!attivo && _logInterceptor != null) {
      dio.interceptors.remove(_logInterceptor);
      _logInterceptor = null;
    }
  }

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
