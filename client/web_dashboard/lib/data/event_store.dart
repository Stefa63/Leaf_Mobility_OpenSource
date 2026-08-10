import 'package:flutter/foundation.dart';

import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/events_repository.dart';
import 'package:web_dashboard/data/event_data.dart';

/// @brief Stato osservabile della schermata Segnala Eventi da `/api/v1/eventi` (AP.09).
///
/// La schermata osserva [events] tramite [ValueListenableBuilder] (nessun MVC,
/// stesso pattern di `FleetStore`). Valore iniziale = dati di riserva [EventData]:
/// senza rete (IIN-6) resta sui mock con [offline] a true. Le mutazioni sono
/// ottimistiche con sync best-effort: solo i grandi eventi (AP.09) sono persistiti
/// su `/eventi`; cantieri e interruzioni restano locali (domini AP.04 di altri blocchi).
class EventStore {
  EventStore._();

  /// Eventi correnti (reali se caricati, altrimenti di riserva).
  static final ValueNotifier<List<CityEvent>> events =
      ValueNotifier<List<CityEvent>>(EventData.events);

  /// True quando l'ultimo caricamento è fallito (si mostrano i dati di riserva).
  static final ValueNotifier<bool> offline = ValueNotifier<bool>(false);

  static bool _inCorso = false;

  /// @brief Carica i grandi eventi dal backend e aggiorna lo store (AP.09).
  /// @param repo Repository da usare (iniettabile nei test).
  static Future<void> carica({EventiApi? repo}) async {
    if (_inCorso) return;
    _inCorso = true;
    try {
      final docs = await (repo ?? eventsRepository).elenco();
      events.value = docs
          .map(CityEvent.daApi)
          .whereType<CityEvent>()
          .toList(growable: false);
      offline.value = false;
    } on LeafApiException {
      offline.value = true; // resta sui dati di riserva
    } finally {
      _inCorso = false;
    }
  }

  /// @brief Inserisce un evento (ottimistico) e lo persiste tipizzato (AP.09/AP.04).
  ///
  /// Persiste tutte le categorie (grande evento, cantiere, interruzione) su
  /// `/eventi` col campo `categoria`; al successo memorizza l'id server in
  /// [CityEvent.serverId] (necessario per la cancellazione). In assenza di rete
  /// l'evento resta locale con [offline] a true (IIN-6), sync differita.
  /// @param evento Evento creato dal form.
  /// @param repo Repository da usare (iniettabile nei test).
  static Future<void> aggiungi(CityEvent evento, {EventiApi? repo}) async {
    events.value = [evento, ...events.value];
    final loc = evento.location;
    final poligono = loc == null
        ? <List<double>>[]
        : [
            [loc.latitude, loc.longitude],
            [loc.latitude + 0.001, loc.longitude],
            [loc.latitude + 0.001, loc.longitude + 0.001],
            [loc.latitude, loc.longitude + 0.001],
          ];
    final giorno = evento.date.toIso8601String().substring(0, 10);
    try {
      final idServer = await (repo ?? eventsRepository).crea(
        nome: evento.name,
        categoria: CityEvent.categoriaApi(evento.type),
        dataInizio: giorno,
        dataFine: giorno,
        poligono: poligono,
        area: evento.area,
      );
      evento.serverId = idServer;
      offline.value = false;
    } on LeafApiException {
      offline.value = true; // creato localmente, sync differita
    }
  }

  /// @brief Rimuove un evento (ottimistico) ed elimina dal backend se persistito (AP.09).
  ///
  /// Rimuove subito l'evento dallo store; se l'evento ha un [CityEvent.serverId]
  /// (caricato dal backend o creato e persistito) invia la DELETE reale. Gli
  /// eventi solo locali (dati di riserva mock) restano una rimozione locale.
  /// @param id Id di vista dell'evento da rimuovere.
  /// @param repo Repository da usare (iniettabile nei test).
  static Future<void> rimuovi(String id, {EventiApi? repo}) async {
    CityEvent? evento;
    for (final e in events.value) {
      if (e.id == id) {
        evento = e;
        break;
      }
    }
    events.value = events.value
        .where((e) => e.id != id)
        .toList(growable: false);
    final idServer = evento?.serverId;
    if (idServer == null) return; // solo locale/di riserva
    try {
      await (repo ?? eventsRepository).elimina(idServer);
      offline.value = false;
    } on LeafApiException {
      offline.value = true; // rimosso localmente, sync differita
    }
  }
}
