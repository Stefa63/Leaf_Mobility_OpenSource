part of 'search_screen.dart';

// ── Dati e mapper della ricerca percorsi ──────────────────────────────────────
// Suggerimenti e opzioni di percorso arrivano dal backend (UT.07): geocoding sul
// gazetteer del server (`/geocoding`) e percorsi multimodali (`/percorsi`). Qui
// restano la cronologia locale (nessun endpoint dedicato), il fallback offline dei
// suggerimenti (IIN-6) e i mapper dei payload API → modelli di vista.

/// Cronologia delle ricerche recenti mostrata a campo vuoto (UT.07).
/// Locale: non esiste un endpoint server dedicato alla cronologia di ricerca.
const List<String> _searchHistory = [
  'Stazione Bari Centrale',
  'Piazza Umberto I – Bari',
  'Lungomare di Bari',
  'Ospedale Policlinico',
];

/// Suggerimenti di riserva usati se il geocoding del server non risponde (IIN-6).
const List<String> _suggerimentiOffline = [
  'Stazione Bari Centrale',
  'Piazza Umberto I – Bari',
  'Lungomare di Bari',
  'Ospedale Policlinico – Bari',
  'Quartiere Libertà – Bari',
  'Quartiere Poggiofranco',
  'Bari Vecchia – Basilica San Nicola',
  'Teatro Petruzzelli – Bari',
  'Fiera del Levante',
  'Aeroporto Karol Wojtyla – Bari',
  'Piazza Moro – Bari',
  'Carrassi – Bari',
  'Japigia – Bari',
  'Torre a Mare – Bari',
];

/// Sentinella della scorciatoia "usa posizione corrente".
const String _posizioneCorrente = 'Posizione corrente';

/// Coordinate di riferimento per la posizione corrente finché il GPS non è cablato
/// in questa schermata (centro di Bari — Stazione Centrale). Usate come origine/
/// destinazione quando l'utente sceglie "Usa posizione corrente".
const double _centroBariLat = 41.1171;
const double _centroBariLon = 16.8719;

/// @brief Mappa il discriminante `tipo_mezzo`/`tipo_consigliato` del server sull'enum di vista.
/// @param tipo Discriminante del server (ebike/ecar/emotorbike/monopattino).
/// @return Il [VehicleType] corrispondente (default scooter).
VehicleType _tipoVeicoloDaApi(String tipo) {
  switch (tipo) {
    case 'ebike':
      return VehicleType.bike;
    case 'ecar':
      return VehicleType.car;
    case 'emotorbike':
      return VehicleType.emoto;
    default:
      return VehicleType.scooter;
  }
}

/// @brief Riepilogo testuale della modalità di trasporto del percorso (UT.07).
/// @param tipo Tipo di mezzo consigliato per la tratta in sharing.
/// @param haTpl Se il percorso integra il trasporto pubblico locale.
/// @return Una breve descrizione della modalità.
String _riepilogoTrasporto(VehicleType tipo, bool haTpl) {
  const etichette = {
    VehicleType.scooter: 'Scooter elettrico',
    VehicleType.bike: 'E-Bike',
    VehicleType.car: 'Auto elettrica',
    VehicleType.emoto: 'E-Moto',
  };
  final mezzo = etichette[tipo] ?? 'Mezzo in sharing';
  return haTpl ? '$mezzo + Bus TPL fino a destinazione' : '$mezzo — percorso diretto';
}

/// @brief Costruisce una [RouteData] da un'opzione di percorso della API (UT.07/UT.08).
///
/// I mezzi consigliati sono i veicoli reali disponibili vicino alla partenza filtrati
/// per il tipo consigliato dell'opzione; se nessuno è disponibile, [RouteData.recommended]
/// resta vuota e l'icona della modalità deriva da [RouteData.recommendedType].
///
/// @param opzione Opzione grezza `{nome, descrizione, durata_min, distanza_km, ha_tpl, tipo_consigliato}`.
/// @param mezzi Veicoli reali disponibili vicino all'origine (da `/veicoli`).
/// @return Il modello di vista del percorso.
RouteData _percorsoDaApi(
  Map<String, dynamic> opzione,
  List<VehicleData> mezzi,
) {
  final tipo = _tipoVeicoloDaApi('${opzione['tipo_consigliato'] ?? ''}');
  final haTpl = opzione['ha_tpl'] == true;
  final consigliati = mezzi.where((m) => m.type == tipo).take(2).toList();
  return RouteData(
    name: '${opzione['nome'] ?? 'Percorso'}',
    description: '${opzione['descrizione'] ?? ''}',
    durationMinutes: ((opzione['durata_min'] ?? 0) as num).round(),
    distanceKm: double.parse(((opzione['distanza_km'] ?? 0) as num).toStringAsFixed(1)),
    transportSummary: _riepilogoTrasporto(tipo, haTpl),
    hasTpl: haTpl,
    recommendedType: tipo,
    recommended: consigliati,
  );
}

/// @brief Mappa l'elenco di opzioni della API in [RouteData] (UT.07).
/// @param percorsi Lista grezza `percorsi` del payload `/percorsi`.
/// @param mezzi Veicoli reali disponibili vicino all'origine.
/// @return Lista ordinata di percorsi proposti all'utente.
List<RouteData> _percorsiDaApi(
  List<dynamic> percorsi,
  List<VehicleData> mezzi,
) => percorsi
    .map((p) => _percorsoDaApi(Map<String, dynamic>.from(p as Map), mezzi))
    .toList(growable: false);
