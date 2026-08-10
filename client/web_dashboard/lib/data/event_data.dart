// event_data.dart
// Modelli e dati di riserva della schermata Segnala Eventi (AP.09).
//
// CityEvent e il mapper daApi traducono i documenti evento di /api/v1/eventi
// (aree_limitate di tipo "evento"). I dati di riserva (mock storici) alimentano
// la vista finché il backend non risponde, così senza rete (IIN-6) la schermata
// non resta vuota.

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// @brief Tipologia di evento cittadino segnalabile dall'Amministrazione Pubblica.
enum CityEventType { grandeEvento, cantiere, interruzione }

/// @brief Evento cittadino segnalato a sistema.
class CityEvent {
  /// @brief Crea un evento cittadino.
  CityEvent({
    required this.id,
    required this.name,
    required this.type,
    required this.date,
    required this.area,
    this.location,
    this.note = '',
    this.serverId,
  });

  /// @brief Mappa la categoria del documento server sull'enum di vista.
  /// @param categoria Discriminante `categoria` dell'area di tipo "evento".
  /// @return Il [CityEventType] corrispondente (default grande evento).
  static CityEventType tipoDaCategoria(String categoria) {
    switch (categoria) {
      case 'cantiere':
        return CityEventType.cantiere;
      case 'interruzione':
        return CityEventType.interruzione;
      default:
        return CityEventType.grandeEvento;
    }
  }

  /// @brief Categoria server corrispondente a un [CityEventType] (per il POST).
  /// @param t Tipo di evento di vista.
  /// @return La stringa `categoria` attesa dal backend.
  static String categoriaApi(CityEventType t) {
    switch (t) {
      case CityEventType.cantiere:
        return 'cantiere';
      case CityEventType.interruzione:
        return 'interruzione';
      case CityEventType.grandeEvento:
        return 'grande_evento';
    }
  }

  /// @brief Costruisce un [CityEvent] da un documento evento della API (AP.09).
  /// @param doc Documento area di tipo "evento" (`/api/v1/eventi`).
  /// @return L'evento mappato, o null se privo di identificativo.
  static CityEvent? daApi(Map<String, dynamic> doc) {
    final id = doc['_id']?.toString();
    if (id == null || id.isEmpty) return null;
    LatLng? location;
    final geometria = doc['geometria'];
    if (geometria is List && geometria.isNotEmpty) {
      final p = geometria.first;
      if (p is Map && p['lat'] != null && p['lon'] != null) {
        location = LatLng(
          (p['lat'] as num).toDouble(),
          (p['lon'] as num).toDouble(),
        );
      }
    }
    return CityEvent(
      id: id,
      serverId: id,
      name: doc['nome']?.toString() ?? id,
      type: tipoDaCategoria(doc['categoria']?.toString() ?? ''),
      date:
          DateTime.tryParse(doc['data_inizio']?.toString() ?? '') ??
          DateTime.now(),
      area: doc['area']?.toString() ?? '—',
      location: location,
    );
  }

  /// @brief Identificativo dell'evento.
  final String id;

  /// @brief Nome dell'evento.
  String name;

  /// @brief Tipo di evento (grande evento / cantiere / interruzione).
  final CityEventType type;

  /// @brief Data dell'evento.
  final DateTime date;

  /// @brief Area/quartiere interessato.
  final String area;

  /// @brief Posizione sulla mappa (opzionale).
  final LatLng? location;

  /// @brief Nota descrittiva opzionale.
  final String note;

  /// @brief Id lato server per la cancellazione (null se solo locale/di riserva).
  ///
  /// Valorizzato dal mapper [daApi] per gli eventi caricati dal backend e
  /// dallo store dopo una creazione persistita; resta null per i dati di
  /// riserva mock, che non esistono sul server e non vanno eliminati via API.
  String? serverId;
}

/// @brief Dati di riserva della schermata Segnala Eventi (mock storici, lista stabile).
class EventData {
  /// @brief Eventi programmati di riserva.
  static final List<CityEvent> events = [
    CityEvent(
      id: 'EV-01',
      name: 'Concerto Fiera del Levante',
      type: CityEventType.grandeEvento,
      date: DateTime.now().add(const Duration(days: 5)),
      area: 'Fiera del Levante',
      location: const LatLng(41.1300, 16.8505),
      note: 'Afflusso elevato previsto in serata',
    ),
    CityEvent(
      id: 'EV-02',
      name: 'Cantiere Corso Cavour',
      type: CityEventType.cantiere,
      date: DateTime.now().add(const Duration(days: 1)),
      area: 'Corso Cavour',
      location: const LatLng(41.1248, 16.8648),
      note: 'Restringimento carreggiata, sosta inibita',
    ),
    CityEvent(
      id: 'EV-03',
      name: 'Manutenzione rete – Japigia',
      type: CityEventType.interruzione,
      date: DateTime.now().add(const Duration(days: 2)),
      area: 'Japigia',
      location: const LatLng(41.0958, 16.8718),
    ),
  ];
}
