// Widget test delle Notifiche: lista reale + segna-letta + offline (UT.15/UT.19, IIN-19).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile_utente/api/api_client.dart';
import 'package:app_mobile_utente/api/notifiche_repository.dart';
import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/screens/notifications_screen.dart';

/// NotificheApi fittizia: due notifiche (una non letta) o errore di rete.
class _FakeNotifiche implements NotificheApi {
  _FakeNotifiche({this.errore = false});
  final bool errore;
  final List<String> lette = [];

  @override
  Future<List<Map<String, dynamic>>> elenco({bool soloNonLette = false}) async {
    if (errore) throw LeafApiException('rete giù');
    return [
      {
        '_id': 'n1',
        'tipo': 'prenotazione',
        'titolo': 'Prenotazione in scadenza',
        'messaggio': 'La tua prenotazione scade tra 1 minuto',
        'letta': false,
      },
      {
        '_id': 'n2',
        'tipo': 'servizio',
        'titolo': 'Interruzione servizio',
        'messaggio': 'Manutenzione programmata stanotte',
        'letta': true,
      },
    ];
  }

  @override
  Future<void> segnaLetta(String idNotifica) async {
    lette.add(idNotifica);
  }
}

Future<void> _pump(WidgetTester tester, NotificheApi repo) async {
  appLanguage.value = 'it';
  await tester.pumpWidget(MaterialApp(home: NotificationsScreen(repo: repo)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Mostra le notifiche reali, dalla più recente (UT.15/UT.19)', (
    tester,
  ) async {
    await _pump(tester, _FakeNotifiche());

    expect(find.text('Prenotazione in scadenza'), findsOneWidget);
    expect(find.text('Interruzione servizio'), findsOneWidget);
  });

  testWidgets('Il tap su una notifica non letta la marca come letta', (
    tester,
  ) async {
    final fake = _FakeNotifiche();
    await _pump(tester, fake);

    await tester.tap(find.text('Prenotazione in scadenza'));
    await tester.pumpAndSettle();

    expect(fake.lette, contains('n1'));
  });

  testWidgets('In errore di rete mostra il banner offline (IIN-6)', (
    tester,
  ) async {
    await _pump(tester, _FakeNotifiche(errore: true));

    expect(find.text('Notifiche non aggiornate (offline)'), findsOneWidget);
  });
}
