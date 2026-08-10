// Widget test della console Amministrazione Pubblica (AP.03, AP.05, IIN-15).
//
// Monta l'intera ApDashboard con il ServizioMappa sostituito dal fake di
// piattaforma: verifica le sezioni di pianificazione, le metriche aggregate
// coerenti con FleetData e l'anonimizzazione della vista (IIN-15): la home AP
// non espone identificativi di singoli mezzi o utenti, solo dati aggregati.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:web_dashboard/api/api_config.dart';
import 'package:web_dashboard/data/fleet_data.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/screens/ap_dashboard.dart';
import 'package:web_dashboard/session.dart';

import 'helpers/fake_maps_platform.dart';

/// @brief Monta la [ApDashboard] su superficie desktop con mappa fake.
///
/// Il `textScaler` e' ridotto solo nell'ambiente di test: il font "Ahem" dei
/// widget test rende ogni glifo a larghezza piena e farebbe traboccare di
/// pochi pixel le etichette compatte del telaio (footer del menu laterale),
/// cosa che non avviene con i font reali a runtime.
/// @param tester il driver del widget test.
Future<void> pumpApDashboard(WidgetTester tester) async {
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
      home: const ApDashboard(),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    // Lingua deterministica (IIN-7), sessione AP, mappa fake installata.
    appLanguage.value = 'it';
    Session.role = DashboardRole.publicAdmin;
    installFakeGoogleMapsPlatform();
    kAutoloadData = false;
    addTearDown(() => kAutoloadData = true);
  });

  testWidgets('Il menu laterale espone le sezioni di pianificazione', (
    tester,
  ) async {
    await pumpApDashboard(tester);

    // "Home Dashboard" compare due volte: voce di menu + header sezione.
    expect(find.text('Home Dashboard'), findsWidgets);
    expect(find.text('Mappa & Heatmap'), findsOneWidget);
    expect(find.text('Gestione Geofencing'), findsOneWidget);
    expect(find.text('Segnala Eventi'), findsOneWidget);
    expect(find.text('Reportistica'), findsOneWidget);
    expect(find.text('Profilo Comune'), findsOneWidget);
  });

  testWidgets('Le metriche di flotta sono aggregate da FleetData (AP.03)', (
    tester,
  ) async {
    await pumpApDashboard(tester);

    expect(find.text('Flotta Operativa'), findsOneWidget);
    expect(find.text('Attivi'), findsOneWidget);
    // Percentuali calcolate dagli stessi aggregati mostrati alla PA.
    expect(find.text('${FleetData.activePct}%'), findsOneWidget);
    expect(find.text('${FleetData.maintenancePct}%'), findsOneWidget);
    expect(find.text('Impatto Ecologico (Mese)'), findsOneWidget);
    expect(find.text('Heatmap Utilizzo Odierno'), findsOneWidget);
  });

  testWidgets(
    'La home AP non espone identificativi singoli: dati anonimi (IIN-15)',
    (tester) async {
      await pumpApDashboard(tester);

      // Nessun codice di singolo veicolo (SC-/BK-/CA-/EM-) ne' email utente:
      // la vista PA aggrega per area/percentuale, non per mezzo o cittadino.
      for (final v in FleetData.vehicles) {
        expect(find.textContaining(v.id), findsNothing);
      }
      expect(find.textContaining('@'), findsNothing);
    },
  );

  testWidgets('Il badge MFA e\' presente anche nella console AP (IIN-9)', (
    tester,
  ) async {
    await pumpApDashboard(tester);

    expect(find.text('MFA: Attivo'), findsOneWidget);
  });
}
