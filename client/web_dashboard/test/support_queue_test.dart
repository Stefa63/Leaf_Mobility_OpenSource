// Widget test della Coda Assistenza (OP.08).
//
// Verifica l'header e l'elenco delle richieste di supporto in entrata
// gestite dall'operatore.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:web_dashboard/api/assistenza_repository.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/screens/support_queue.dart';

/// @brief AssistenzaApi fittizia: una richiesta deterministica, nessuna rete.
class _FakeAssistenza implements AssistenzaApi {
  String? rispostoA;
  String? statoInviato;

  @override
  Future<List<Map<String, dynamic>>> coda({String? stato}) async => [
    {
      '_id': 'AS-2051',
      'id_utente': 'U-1029',
      'oggetto': 'Sblocco non riuscito su EM-015',
      'messaggio': 'Ho premuto sblocca ma il mezzo non risponde.',
      'stato': 'aperto',
    },
  ];

  @override
  Future<void> rispondi(
    String idTicket,
    String risposta, {
    String stato = 'in_lavorazione',
  }) async {
    rispostoA = idTicket;
    statoInviato = stato;
  }
}

/// @brief Monta la [SupportQueue] in un telaio di test desktop.
/// @param tester il driver del widget test.
Future<void> pumpSupportQueue(WidgetTester tester, AssistenzaApi api) async {
  await tester.binding.setSurfaceSize(const Size(1400, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(0.8),
        ),
        child: child!,
      ),
      home: Scaffold(body: SupportQueue(assistenza: api)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    appLanguage.value = 'it';
  });

  testWidgets('Coda Assistenza mostra header e richieste in entrata (OP.08)', (
    tester,
  ) async {
    await pumpSupportQueue(tester, _FakeAssistenza());

    expect(find.text('Coda Assistenza'), findsOneWidget);
    expect(find.text('AS-2051'), findsOneWidget);
  });

  testWidgets('Prendi in carico invia la transizione di stato (OP.08)', (
    tester,
  ) async {
    final api = _FakeAssistenza();
    await pumpSupportQueue(tester, api);

    await tester.tap(find.text('Prendi in carico'));
    await tester.pumpAndSettle();

    expect(api.rispostoA, 'AS-2051');
    expect(api.statoInviato, 'in_lavorazione');
  });
}
