// Test dello store Segnala Eventi alimentato da /api/v1/eventi (AP.09, eventi tipizzati).

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/events_repository.dart';
import 'package:web_dashboard/data/event_data.dart';
import 'package:web_dashboard/data/event_store.dart';

/// EventiApi fittizia: registra creazione/cancellazione (o simula errore di rete).
class _FakeEventi implements EventiApi {
  _FakeEventi({this.errore = false});
  final bool errore;
  String? nomeCreato;
  String? categoriaCreata;
  String? idEliminato;

  @override
  Future<List<Map<String, dynamic>>> elenco() async {
    if (errore) throw LeafApiException('rete giù');
    return [
      {
        '_id': 'EV-90',
        'nome': 'Festa Patronale',
        'tipo': 'evento',
        'categoria': 'grande_evento',
        'data_inizio': '2026-07-10',
        'geometria': [
          {'lat': 41.12, 'lon': 16.86},
        ],
      },
    ];
  }

  @override
  Future<String> crea({
    required String nome,
    required String categoria,
    required String dataInizio,
    required String dataFine,
    required List<List<double>> poligono,
    String? area,
  }) async {
    if (errore) throw LeafApiException('rete giù');
    nomeCreato = nome;
    categoriaCreata = categoria;
    return 'EV-new';
  }

  @override
  Future<void> elimina(String idEvento) async {
    if (errore) throw LeafApiException('rete giù');
    idEliminato = idEvento;
  }
}

void main() {
  setUp(() {
    EventStore.events.value = EventData.events;
    EventStore.offline.value = false;
  });

  test('CityEvent.daApi mappa nome, data, posizione e categoria', () {
    final e = CityEvent.daApi({
      '_id': 'EV-90',
      'nome': 'Cantiere',
      'categoria': 'cantiere',
      'data_inizio': '2026-07-10',
      'geometria': [
        {'lat': 41.1, 'lon': 16.8},
      ],
    });
    expect(e, isNotNull);
    expect(e!.name, 'Cantiere');
    expect(e.type, CityEventType.cantiere);
    expect(e.serverId, 'EV-90');
    expect(e.location, isA<LatLng>());
  });

  test('carica popola gli eventi dai dati reali (AP.09)', () async {
    await EventStore.carica(repo: _FakeEventi());
    expect(EventStore.events.value.single.id, 'EV-90');
    expect(EventStore.offline.value, isFalse);
  });

  test('carica segnala offline e tiene i dati di riserva', () async {
    await EventStore.carica(repo: _FakeEventi(errore: true));
    expect(EventStore.offline.value, isTrue);
    expect(EventStore.events.value, EventData.events);
  });

  test('aggiungi inserisce e persiste memorizzando il serverId (AP.09)', () async {
    final repo = _FakeEventi();
    final evento = CityEvent(
      id: 'EV-99',
      name: 'Concerto Test',
      type: CityEventType.grandeEvento,
      date: DateTime(2026, 7, 10),
      area: 'Centro',
      location: const LatLng(41.12, 16.86),
    );
    await EventStore.aggiungi(evento, repo: repo);
    expect(EventStore.events.value.first.id, 'EV-99');
    expect(repo.nomeCreato, 'Concerto Test');
    expect(repo.categoriaCreata, 'grande_evento');
    expect(evento.serverId, 'EV-new');
  });

  test('aggiungi persiste anche i cantieri tipizzati (AP.04)', () async {
    final repo = _FakeEventi();
    final cantiere = CityEvent(
      id: 'EV-98',
      name: 'Cantiere Test',
      type: CityEventType.cantiere,
      date: DateTime(2026, 7, 10),
      area: 'Centro',
    );
    await EventStore.aggiungi(cantiere, repo: repo);
    expect(EventStore.events.value.first.id, 'EV-98');
    expect(repo.categoriaCreata, 'cantiere');
  });

  test('rimuovi elimina dal backend gli eventi persistiti (AP.09)', () async {
    final repo = _FakeEventi();
    await EventStore.carica(repo: repo);
    await EventStore.rimuovi('EV-90', repo: repo);
    expect(EventStore.events.value, isEmpty);
    expect(repo.idEliminato, 'EV-90');
  });

  test('rimuovi di un evento solo locale non chiama la DELETE', () async {
    final repo = _FakeEventi();
    final locale = CityEvent(
      id: 'EV-77',
      name: 'Solo locale',
      type: CityEventType.interruzione,
      date: DateTime(2026, 7, 10),
      area: 'Centro',
    );
    EventStore.events.value = [locale];
    await EventStore.rimuovi('EV-77', repo: repo);
    expect(EventStore.events.value, isEmpty);
    expect(repo.idEliminato, isNull);
  });
}
