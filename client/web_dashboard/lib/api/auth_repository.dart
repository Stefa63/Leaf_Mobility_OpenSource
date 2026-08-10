import 'package:dio/dio.dart';

import 'package:web_dashboard/api/api_client.dart';

/// @brief Esito di un passo di accesso OP/PA (IIN-1/9/12).
enum StatoAccesso {
  /// Accesso completato: token emesso e custodito.
  ok,

  /// Richiesto il secondo fattore OTP (OP/PA, IIN-9 — sempre per la dashboard).
  mfaRichiesta,

  /// Richiesto il cambio della password temporanea al primo accesso (IIN-12).
  cambioPasswordRichiesto,
}

/// @brief Risultato di `accedi`/`verificaMfa`: stato e dati per il passo successivo.
class EsitoAccesso {
  /// @brief Crea l'esito con lo stato e i campi pertinenti.
  EsitoAccesso(this.stato, {this.idAccount, this.ruolo, this.otpSimulato});

  /// @brief Stato dell'accesso.
  final StatoAccesso stato;

  /// @brief Identificativo account (document ID Firestore) per MFA/cambio password.
  final String? idAccount;

  /// @brief Ruolo RBAC dell'utente autenticato (a esito `ok`).
  final String? ruolo;

  /// @brief OTP restituito dal backend in simulazione (provider OTP fittizio, IIN-9).
  final String? otpSimulato;
}

/// @brief Contratto di autenticazione OP/PA verso il backend (iniettabile nei test).
abstract class AuthApi {
  /// @brief Avvia il login con credenziali (IIN-1); per OP/PA risponde `mfaRichiesta`.
  Future<EsitoAccesso> accedi(String identita, String password);

  /// @brief Completa il login col secondo fattore OTP (IIN-9).
  Future<EsitoAccesso> verificaMfa(String idAccount, String otp);

  /// @brief Richiede il reset password via email istituzionale (IIN-11/AP.12).
  Future<void> richiediReset(String identita);

  /// @brief Conferma il reset password con codice monouso e nuova password (IIN-11).
  ///
  /// Al successo il backend emette il token di sessione (auto-accesso): il codice
  /// via email funge da secondo fattore, bypassando l'OTP MFA.
  /// @param identita Email/username dichiarato.
  /// @param codice Codice monouso ricevuto via email.
  /// @param nuovaPassword Nuova password (validata IIN-5 lato client e server).
  /// @return [EsitoAccesso] con stato `ok` e ruolo se il reset è riuscito.
  Future<EsitoAccesso> confermaReset(
    String identita,
    String codice, [
    String? nuovaPassword,
  ]);

  /// @brief Cambia la password obbligatoria al primo accesso OP/PA (IIN-12).
  /// @param nuovaPassword Nuova password (validata IIN-5 lato client e server).
  Future<void> cambiaPasswordPrimoAccesso(String nuovaPassword);

  /// @brief Termina la sessione corrente (logout).
  Future<void> esci();
}

/// @brief Implementazione di [AuthApi] sul backend `/api/v1/auth` via Dio.
class AuthRepository implements AuthApi {
  /// @brief Crea il repository; il client API è iniettabile nei test.
  AuthRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  EsitoAccesso _interpreta(Map<String, dynamic> dati) {
    switch (dati['stato'] as String?) {
      case 'mfa_richiesta':
        return EsitoAccesso(
          StatoAccesso.mfaRichiesta,
          idAccount: dati['id_account']?.toString(),
          otpSimulato: dati['otp_simulato'] as String?,
        );
      case 'cambio_password_richiesto':
        return EsitoAccesso(
          StatoAccesso.cambioPasswordRichiesto,
          idAccount: dati['id_account']?.toString(),
          ruolo: dati['ruolo'] as String?,
        );
      default:
        // IIN-12: dopo l'MFA il backend segnala il primo accesso col flag dedicato.
        final cambio = dati['richiede_cambio_password'] == true;
        return EsitoAccesso(
          cambio ? StatoAccesso.cambioPasswordRichiesto : StatoAccesso.ok,
          idAccount: dati['id_account']?.toString(),
          ruolo: dati['ruolo'] as String?,
        );
    }
  }

  Future<EsitoAccesso> _accesso(
    Future<Response<dynamic>> Function() chiamata,
  ) async {
    try {
      final risposta = await chiamata();
      final dati = Map<String, dynamic>.from(risposta.data as Map);
      final esito = _interpreta(dati);
      // Token custodito sia ad accesso completo sia al primo accesso (serve per il
      // cambio password obbligatorio IIN-12, che è una chiamata autenticata).
      if (dati['access_token'] != null) {
        await _client.tokenStore.salva(dati['access_token'] as String);
      }
      return esito;
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<EsitoAccesso> accedi(String identita, String password) {
    return _accesso(
      () => _client.dio.post<dynamic>(
        '/auth/login',
        data: {'identita': identita, 'password': password},
      ),
    );
  }

  @override
  Future<EsitoAccesso> verificaMfa(String idAccount, String otp) {
    return _accesso(
      () => _client.dio.post<dynamic>(
        '/auth/mfa',
        data: {'id_account': idAccount, 'otp': otp},
      ),
    );
  }

  @override
  Future<void> richiediReset(String identita) async {
    try {
      await _client.dio.post<dynamic>(
        '/auth/password/reset',
        data: {'identita': identita},
      );
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<EsitoAccesso> confermaReset(
    String identita,
    String codice, [
    String? nuovaPassword,
  ]) async {
    try {
      final risposta = await _client.dio.post<dynamic>(
        '/auth/password/reset/conferma',
        data: {
          'identita': identita,
          'codice': codice,
          'nuova_password': nuovaPassword,
        },
      );
      final dati = Map<String, dynamic>.from(risposta.data as Map);
      // Il backend restituisce `reimpostata: true/false`. Se true include
      // access_token, id_account e ruolo per l'auto-accesso.
      if (dati['reimpostata'] == true && dati['access_token'] != null) {
        await _client.tokenStore.salva(dati['access_token'] as String);
        return EsitoAccesso(
          StatoAccesso.ok,
          idAccount: dati['id_account']?.toString(),
          ruolo: dati['ruolo'] as String?,
        );
      }
      // Codice errato o scaduto: reimpostata=false (anti-enumerazione).
      return EsitoAccesso(StatoAccesso.mfaRichiesta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<void> cambiaPasswordPrimoAccesso(String nuovaPassword) async {
    try {
      await _client.dio.post<dynamic>(
        '/auth/password/primo-accesso',
        data: {'nuova_password': nuovaPassword},
      );
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<void> esci() async {
    try {
      await _client.dio.post<dynamic>('/auth/logout');
    } on DioException catch (_) {
      // Logout best-effort: anche se la rete fallisce, cancelliamo il token locale.
    }
    await _client.tokenStore.cancella();
  }
}

/// @brief Repository di autenticazione condiviso (default reale; sovrascrivibile nei test).
final AuthRepository authRepository = AuthRepository();
