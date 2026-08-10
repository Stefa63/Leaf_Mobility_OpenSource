import 'package:dio/dio.dart';

import 'package:app_mobile_utente/api/api_client.dart';

/// @brief Contratto di accesso al profilo utente (UT.21), iniettabile nei test.
abstract class ProfiloApi {
  /// @brief Recupera i dati del profilo dell'utente autenticato.
  /// @return Vista profilo (mai contenente la password hash).
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<Map<String, dynamic>> profilo();

  /// @brief Aggiorna i dati anagrafici del profilo (whitelist server-side).
  /// @param modifiche Coppie campo→valore da aggiornare (nome, cognome, telefono, …).
  /// @return Vista profilo aggiornata.
  /// @throws LeafApiException Su errore di rete o conflitto.
  Future<Map<String, dynamic>> aggiorna(Map<String, dynamic> modifiche);

  /// @brief Registra un metodo di pagamento verificato (UT.11).
  ///
  /// Il PAN viene inviato al backend per la verifica ma **non è mai persistito
  /// in chiaro lato client**: il server restituisce solo il numero mascherato.
  /// @param numero Numero della carta (solo cifre, 12–23).
  /// @param mese Mese di scadenza (1–12).
  /// @param anno Anno di scadenza (≥ 2024).
  /// @param titolare Intestatario della carta.
  /// @param cvv Codice di sicurezza a 3 cifre (verificato, mai persistito — PCI).
  /// @param indirizzoFatturazione Via di fatturazione; deve coincidere con la residenza.
  /// @return Payload con `id_metodo`, `pan_mascherato`.
  /// @throws LeafApiException Su errore di rete o carta non valida.
  Future<Map<String, dynamic>> registraPagamento({
    required String numero,
    required int mese,
    required int anno,
    required String titolare,
    required String cvv,
    required String indirizzoFatturazione,
  });

  /// @brief Sottoscrive un piano di abbonamento periodico (UT.18).
  /// @param idPiano Identificativo del piano scelto (deve esistere sul backend).
  /// @return Payload con `id_abbonamento`, `id_piano`, `data_fine`.
  /// @throws LeafApiException Su errore di rete o piano inesistente.
  Future<Map<String, dynamic>> sottoscriviAbbonamento(String idPiano);

  /// @brief Elenca gli abbonamenti dell'utente, dal più recente (UT.18/UT.21).
  /// @return Lista degli abbonamenti (`id_piano`, `stato`, `data_inizio/fine`, `prezzo_cent`).
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> abbonamenti();

  /// @brief Carica un documento KYC (solo PDF/JPG/PNG, UT.22.2, IIN-6).
  ///
  /// Invia tipo e nome del file: l'estensione è validata server-side
  /// (AG-SEC-01); i byte del documento restano sul dispositivo.
  /// @param tipo Tipo di documento (`patente` o `carta_identita`).
  /// @param nomeFile Nome del file con estensione ammessa.
  /// @return Payload con `id_documento`, `stato_verifica`.
  /// @throws LeafApiException Su errore di rete o formato/tipo non ammessi.
  Future<Map<String, dynamic>> caricaKyc({
    required String tipo,
    required String nomeFile,
  });
}

/// @brief Implementazione di [ProfiloApi] su `/api/v1/profilo` via Dio (Bearer automatico).
class ProfiloRepository implements ProfiloApi {
  /// @brief Crea il repository; il client API è iniettabile nei test.
  ProfiloRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<Map<String, dynamic>> profilo() async {
    try {
      final risposta = await _client.dio.get<dynamic>('/profilo');
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<Map<String, dynamic>> aggiorna(Map<String, dynamic> modifiche) async {
    try {
      final risposta = await _client.dio.put<dynamic>(
        '/profilo',
        data: modifiche,
      );
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<Map<String, dynamic>> registraPagamento({
    required String numero,
    required int mese,
    required int anno,
    required String titolare,
    required String cvv,
    required String indirizzoFatturazione,
  }) {
    return _postDati('/profilo/pagamenti', {
      'numero': numero,
      'mese': mese,
      'anno': anno,
      'titolare': titolare,
      'cvv': cvv,
      'indirizzo_fatturazione': indirizzoFatturazione,
    });
  }

  @override
  Future<Map<String, dynamic>> sottoscriviAbbonamento(String idPiano) {
    return _postDati('/profilo/abbonamenti', {'id_piano': idPiano});
  }

  @override
  Future<List<Map<String, dynamic>>> abbonamenti() async {
    try {
      final risposta = await _client.dio.get<dynamic>('/profilo/abbonamenti');
      final dati = ApiClient.payload(risposta);
      final elenco = (dati['abbonamenti'] as List?) ?? const [];
      return elenco
          .map((a) => Map<String, dynamic>.from(a as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<Map<String, dynamic>> caricaKyc({
    required String tipo,
    required String nomeFile,
  }) {
    return _postDati('/profilo/kyc', {'tipo': tipo, 'nome_file': nomeFile});
  }

  /// @brief POST che restituisce il solo payload `dati` dell'inviluppo.
  /// @param percorso Percorso relativo dell'endpoint.
  /// @param corpo Corpo JSON della richiesta.
  /// @return Mappa del payload `dati`.
  /// @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<Map<String, dynamic>> _postDati(
    String percorso,
    Map<String, dynamic> corpo,
  ) async {
    try {
      final risposta = await _client.dio.post<dynamic>(percorso, data: corpo);
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

/// @brief Repository profilo condiviso (default reale; sovrascrivibile nei test).
final ProfiloRepository profiloRepository = ProfiloRepository();
