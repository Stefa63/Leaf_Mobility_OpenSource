// Widget test della gestione ticket dell'Operatore (OP.06, OP.16, OP.19).
//
// I ticket e i tecnici sono interamente reali (iniettati via repository fake):
// nessun seed mock. Copre il caricamento dei guasti da /manutenzione, il filtro
// per stato, l'assegnazione a un tecnico reale (con passaggio a "In corso"), la
// chiusura e la creazione di un nuovo ticket con validazione dei campi.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:web_dashboard/api/maintenance_repository.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/screens/ticket_management.dart';

/// @brief ManutenzioneApi fittizia: guasti e tecnici deterministici, azioni tracciate.
class _FakeManutenzione implements ManutenzioneApi {
  _FakeManutenzione({this.docs = const [], this.tecnici = const []});
  final List<Map<String, dynamic>> docs;
  final List<Map<String, dynamic>> tecnici;
  String? chiuso;
  String? assegnatoTicket;
  String? assegnatoTecnico;
  String? mezzoCreato;

  @override
  Future<List<Map<String, dynamic>>> elenco({String? stato}) async => docs;

  @override
  Future<List<Map<String, dynamic>>> elencoTecnici() async => tecnici;

  @override
  Future<String> crea({
    required String idMezzo,
    required String descrizione,
    String priorita = 'media',
  }) async {
    mezzoCreato = idMezzo;
    return 'MN-new';
  }

  @override
  Future<void> assegna(String idTicket, String idTecnico) async {
    assegnatoTicket = idTicket;
    assegnatoTecnico = idTecnico;
  }

  @override
  Future<void> chiudi(String idTicket) async => chiuso = idTicket;
}

/// Tecnici reali simulati per i menu di assegnazione (OP.16).
const _tecnici = [
  {'_id': 'tec1', 'nome': 'A. Russo'},
  {'_id': 'tec2', 'nome': 'L. Bianchi'},
];

/// Documenti guasto in tre stati distinti per i filtri.
const _treGuasti = [
  {
    '_id': 'MN-1',
    'codice_identificativo_mezzo': 'SC-009',
    'descrizione_guasto': 'Freni da revisionare',
    'priorita': 'alta',
    'stato': 'aperto',
  },
  {
    '_id': 'MN-2',
    'codice_identificativo_mezzo': 'BK-026',
    'descrizione_guasto': 'Batteria non carica',
    'priorita': 'media',
    'stato': 'assegnato',
    'id_tecnico': 'tec1',
  },
  {
    '_id': 'MN-3',
    'codice_identificativo_mezzo': 'CA-015',
    'descrizione_guasto': 'Pneumatico',
    'priorita': 'bassa',
    'stato': 'chiuso',
  },
];

/// @brief Monta la [TicketManagement] su superficie desktop, caricando dal repo fake.
Future<void> pumpTicketScreen(WidgetTester tester, {required ManutenzioneApi api}) async {
  await tester.binding.setSurfaceSize(const Size(1600, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: TicketManagement(repo: api))),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    appLanguage.value = 'it';
  });

  testWidgets('Carica e mostra i guasti reali da /manutenzione (OP.19)', (
    tester,
  ) async {
    await pumpTicketScreen(
      tester,
      api: _FakeManutenzione(docs: [_treGuasti.first]),
    );

    expect(find.text('MN-1'), findsOneWidget);
    expect(find.text('Freni da revisionare'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Nuovo Ticket'), findsOneWidget);
  });

  testWidgets('Il filtro per stato mostra solo i ticket terminati (OP.06)', (
    tester,
  ) async {
    await pumpTicketScreen(tester, api: _FakeManutenzione(docs: _treGuasti));

    expect(find.text('3 ticket'), findsOneWidget);
    await tester.tap(find.text('Tutti gli stati'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminato').last);
    await tester.pumpAndSettle();

    expect(find.text('1 ticket'), findsOneWidget);
    expect(find.text('MN-3'), findsOneWidget);
    expect(find.text('MN-1'), findsNothing);
  });

  testWidgets(
    'L\'assegnazione a un tecnico reale porta il ticket "In corso" (OP.16)',
    (tester) async {
      final api = _FakeManutenzione(docs: [_treGuasti.first], tecnici: _tecnici);
      await pumpTicketScreen(tester, api: api);

      await tester.tap(find.text('Assegna'));
      await tester.pumpAndSettle();
      expect(find.text('Assegna a un tecnico'), findsOneWidget);

      await tester.tap(find.text('A. Russo').last);
      await tester.pumpAndSettle();

      // Assegnazione reale inviata al server (OP.16).
      expect(api.assegnatoTicket, 'MN-1');
      expect(api.assegnatoTecnico, 'tec1');
      // Passato "In corso": ora espone "Chiudi".
      expect(find.text('Chiudi'), findsOneWidget);
    },
  );

  testWidgets('Chiudi porta un ticket "In corso" a "Terminato" (OP.19)', (
    tester,
  ) async {
    final api = _FakeManutenzione(docs: [_treGuasti[1]], tecnici: _tecnici);
    await pumpTicketScreen(tester, api: api);

    expect(find.text('Chiudi'), findsOneWidget);
    await tester.tap(find.text('Chiudi'));
    await tester.pump();

    expect(api.chiuso, 'MN-2');
    expect(find.text('Chiudi'), findsNothing);
  });

  testWidgets(
    'Nuovo ticket: validazione campi e inserimento in lista (OP.16/OP.19)',
    (tester) async {
      final api = _FakeManutenzione(tecnici: _tecnici);
      await pumpTicketScreen(tester, api: api);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Nuovo Ticket'));
      await tester.pumpAndSettle();
      // Il progressivo parte da TK-0001 (nessun seed).
      expect(find.text('Nuovo Ticket · TK-0001'), findsOneWidget);

      // Campi vuoti → la validazione blocca la creazione.
      await tester.tap(find.text('Crea ticket'));
      await tester.pumpAndSettle();
      expect(find.text('Campo obbligatorio'), findsNWidgets(2));

      await tester.enterText(find.byType(TextFormField).at(0), 'SC-009');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Manubrio allentato',
      );
      await tester.tap(find.text('Crea ticket'));
      await tester.pumpAndSettle();

      expect(find.text('TK-0001'), findsOneWidget);
      expect(find.text('1 ticket'), findsOneWidget);
      expect(find.textContaining('Ticket creato'), findsOneWidget);
      expect(api.mezzoCreato, 'SC-009');
    },
  );

  test('Ticket.daApi mappa il documento di manutenzione (OP.19)', () {
    final t = Ticket.daApi({
      '_id': 'MN-1',
      'id_mezzo': 'SC-009',
      'descrizione_guasto': 'Freni',
      'priorita': 'alta',
      'stato': 'assegnato',
      'id_tecnico': 'tec-01',
    });
    expect(t, isNotNull);
    expect(t!.type, TicketType.guasto);
    expect(t.priority, TicketPriority.alta);
    expect(t.status, TicketStatus.inCorso);
    expect(t.technician, 'tec-01');
  });
}
