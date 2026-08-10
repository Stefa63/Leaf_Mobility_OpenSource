// Widget test della console Operatore (OP.01, OP.20, IIN-9).
//
// Monta l'intera OpDashboard con il ServizioMappa sostituito dal fake di
// piattaforma (test/helpers/fake_maps_platform.dart): verifica il menu
// laterale con tutte le sezioni operative, il badge MFA in barra e la
// navigazione verso la Gestione Ticket.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:web_dashboard/api/api_config.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/screens/op_dashboard.dart';
import 'package:web_dashboard/session.dart';

import 'helpers/fake_maps_platform.dart';

/// @brief Monta la [OpDashboard] su superficie desktop con mappa fake.
///
/// Il `textScaler` e' ridotto solo nell'ambiente di test: il font "Ahem" dei
/// widget test rende ogni glifo a larghezza piena e farebbe traboccare di
/// pochi pixel le etichette compatte del telaio (footer del menu laterale),
/// cosa che non avviene con i font reali a runtime.
/// @param tester il driver del widget test.
Future<void> pumpOpDashboard(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1600, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(0.8)),
        child: child!,
      ),
      home: const OpDashboard(),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    // Lingua deterministica (IIN-7), sessione OP, mappa fake installata.
    appLanguage.value = 'it';
    Session.role = DashboardRole.operator;
    installFakeGoogleMapsPlatform();
    // La dashboard costruisce le schermate con autoload di default: disattivato
    // per evitare chiamate di rete reali (timer pendenti) nei widget test.
    kAutoloadData = false;
    addTearDown(() => kAutoloadData = true);
  });

  testWidgets('Il menu laterale espone tutte le sezioni operative (OP.20)', (
    tester,
  ) async {
    await pumpOpDashboard(tester);

    // "Centro Operativo" compare due volte: voce di menu + header sezione.
    expect(find.text('Centro Operativo'), findsWidgets);
    expect(find.text('Mappa Flotta Live'), findsOneWidget);
    expect(find.text('Gestione Ticket'), findsOneWidget);
    expect(find.text('Coda Assistenza'), findsOneWidget);
    expect(find.text('Gestione Sconti'), findsOneWidget);
    expect(find.text('Gestione Utenti/AP'), findsOneWidget);
  });

  testWidgets('La barra superiore conferma la MFA attiva (IIN-9)', (
    tester,
  ) async {
    await pumpOpDashboard(tester);

    expect(find.text('MFA: Attivo'), findsOneWidget);
    expect(find.text('Profilo Operatore'), findsOneWidget);
  });

  testWidgets('La home OP mostra la coda allarmi real-time (OP.01)', (
    tester,
  ) async {
    await pumpOpDashboard(tester);

    expect(
      find.text('Coda Allarmi e Notifiche Real-Time'),
      findsOneWidget,
    );
  });

  testWidgets('La voce di menu apre la Gestione Ticket (OP.19)', (
    tester,
  ) async {
    await pumpOpDashboard(tester);

    await tester.tap(find.text('Gestione Ticket'));
    await tester.pump();

    expect(find.text('Interventi e Assistenza Flotta'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Nuovo Ticket'), findsOneWidget);
  });
}
