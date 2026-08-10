import 'package:dio/dio.dart';

import 'package:app_mobile_utente/api/api_client.dart';

/// @brief Contratto del ciclo di vita corse e dei documenti collegati (UT.02/04/10/17/25).
abstract class CorseApi {
  /// @brief Prenota un mezzo con blocco esclusivo (UT.02).
  /// @param idMezzo Identificativo del mezzo da prenotare.
  /// @param durataMin Durata della riserva in minuti (opzionale, UT.15).
  /// @return Payload con `id_prenotazione`.
  Future<Map<String, dynamic>> prenota(String idMezzo, {int? durataMin});

  /// @brief Prenotazioni attive dell'utente, dalla più recente (UT.02/UT.21).
  /// @return Lista delle prenotazioni attive (documenti grezzi della API).
  Future<List<Map<String, dynamic>>> prenotazioni();

  /// @brief Annulla una prenotazione attiva e libera il mezzo (UT.12).
  /// @param idPrenotazione Identificativo della prenotazione da annullare.
  /// @return Payload con `id_prenotazione`, `id_mezzo`, `annullata`.
  Future<Map<String, dynamic>> annullaPrenotazione(String idPrenotazione);

  /// @brief Avvia una corsa sbloccando il mezzo (UT.10).
  /// @param idMezzo Identificativo del mezzo.
  /// @param idPrenotazione Prenotazione da convertire (opzionale).
  /// @return Payload con `id_corsa`, `costo_stimato_cent`, `sbloccato`.
  Future<Map<String, dynamic>> avvia(String idMezzo, {String? idPrenotazione});

  /// @brief Corsa in corso o in pausa dell'utente, per il recupero post-riavvio (UT.10/UT.12).
  /// @return Documento corsa attiva (con `_id`, `id_mezzo`, `tipo_mezzo`, `stato`), o null.
  Future<Map<String, dynamic>?> corsaAttiva();

  /// @brief Conclude una corsa: costo finale, addebito e fattura (UT.04/UT.25).
  /// @param idCorsa Identificativo della corsa.
  /// @param km Chilometri percorsi (IIN-24).
  /// @param lat Latitudine GPS di chiusura (opzionale, OP.05/OP.04).
  /// @param lon Longitudine GPS di chiusura (opzionale, OP.05/OP.04).
  /// @return Payload con `costo_finale_cent`, `id_pagamento`, `id_fattura`, `fuori_area_operativa`.
  Future<Map<String, dynamic>> termina(
    String idCorsa, {
    double km = 0.0,
    double? lat,
    double? lon,
  });

  /// @brief Stima preventiva del costo di una corsa prima di confermare (UT.03).
  /// @param idMezzo Identificativo del mezzo selezionato.
  /// @param durataMin Durata stimata in minuti (opzionale).
  /// @return Payload con `costo_stimato_cent`.
  Future<Map<String, dynamic>> stima(String idMezzo, {int? durataMin});

  /// @brief Mette in pausa una corsa mantenendo il mezzo bloccato (UT.12).
  /// @param idCorsa Identificativo della corsa.
  /// @return Payload con `id_corsa`, `stato`.
  Future<Map<String, dynamic>> pausa(String idCorsa);

  /// @brief Riprende una corsa precedentemente messa in pausa (UT.12).
  /// @param idCorsa Identificativo della corsa.
  /// @return Payload con `id_corsa`, `stato`.
  Future<Map<String, dynamic>> riprendi(String idCorsa);

  /// @brief Registra la valutazione a stelle di una corsa conclusa (UT.16).
  /// @param idCorsa Identificativo della corsa.
  /// @param stelle Valutazione da 1 a 5.
  /// @return Payload con `id_corsa`, `valutazione`.
  Future<Map<String, dynamic>> valuta(String idCorsa, int stelle);

  /// @brief Storico delle corse dell'utente, dalla più recente (UT.17).
  /// @return Lista delle corse passate (documenti grezzi).
  Future<List<Map<String, dynamic>>> storico();

  /// @brief Elenco delle fatture dell'utente (UT.25).
  /// @return Lista delle fatture (documenti grezzi).
  Future<List<Map<String, dynamic>>> fatture();
}

/// @brief Implementazione di [CorseApi] su `/api/v1` via Dio (Bearer automatico).
class CorseRepository implements CorseApi {
  /// @brief Crea il repository; il client API è iniettabile nei test.
  CorseRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<Map<String, dynamic>> prenota(String idMezzo, {int? durataMin}) {
    return _postDati('/prenotazioni', {
      'id_mezzo': idMezzo,
      'durata_min': ?durataMin,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> prenotazioni() {
    return _elenco('/prenotazioni', 'prenotazioni');
  }

  @override
  Future<Map<String, dynamic>> annullaPrenotazione(String idPrenotazione) {
    return _postDati('/prenotazioni/$idPrenotazione/annulla', const {});
  }

  @override
  Future<Map<String, dynamic>> avvia(String idMezzo, {String? idPrenotazione}) {
    return _postDati('/corse', {
      'id_mezzo': idMezzo,
      'id_prenotazione': ?idPrenotazione,
    });
  }

  @override
  Future<Map<String, dynamic>?> corsaAttiva() async {
    try {
      final risposta = await _client.dio.get<dynamic>('/corse/attiva');
      final dati = ApiClient.payload(risposta);
      final corsa = dati['corsa'];
      return corsa is Map ? Map<String, dynamic>.from(corsa) : null;
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<Map<String, dynamic>> termina(
    String idCorsa, {
    double km = 0.0,
    double? lat,
    double? lon,
  }) {
    return _postDati('/corse/$idCorsa/termina', {'km': km, 'lat': ?lat, 'lon': ?lon});
  }

  @override
  Future<Map<String, dynamic>> stima(String idMezzo, {int? durataMin}) {
    return _postDati('/corse/stima', {
      'id_mezzo': idMezzo,
      'durata_min': ?durataMin,
    });
  }

  @override
  Future<Map<String, dynamic>> pausa(String idCorsa) {
    return _postDati('/corse/$idCorsa/pausa', const {});
  }

  @override
  Future<Map<String, dynamic>> riprendi(String idCorsa) {
    return _postDati('/corse/$idCorsa/riprendi', const {});
  }

  @override
  Future<Map<String, dynamic>> valuta(String idCorsa, int stelle) {
    return _postDati('/corse/$idCorsa/valutazione', {'stelle': stelle});
  }

  @override
  Future<List<Map<String, dynamic>>> storico() {
    return _elenco('/corse', 'corse');
  }

  @override
  Future<List<Map<String, dynamic>>> fatture() {
    return _elenco('/fatture', 'fatture');
  }

  /// @brief POST che restituisce il solo payload `dati` dell'inviluppo.
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

  /// @brief GET che estrae una lista nominata dal payload `dati`.
  Future<List<Map<String, dynamic>>> _elenco(
    String percorso,
    String chiave,
  ) async {
    try {
      final risposta = await _client.dio.get<dynamic>(percorso);
      final dati = ApiClient.payload(risposta);
      final elementi = (dati[chiave] as List?) ?? const [];
      return elementi
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

/// @brief Repository corse condiviso (default reale; sovrascrivibile nei test).
final CorseRepository corseRepository = CorseRepository();
