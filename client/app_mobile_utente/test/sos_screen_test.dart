// Widget test della schermata SOS (UT.20, IIN-18).
//
// Verifica il countdown di 5 secondi prima dell'invio della posizione GPS,
// l'annullo durante il countdown e l'annullo dopo l'invio. Il canale di
// `permission_handler` e' stubbato con gli strumenti integrati di
// flutter_test (nessuna dipendenza aggiuntiva): la schermata interroga lo
// stato del permesso di localizzazione all'avvio.
//
// Nota determinismo: la pulsazione del tasto SOS e' un'animazione repeat,
// quindi si usa `pump` con durate esplicite e mai `pumpAndSettle`.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile_utente/api/api_client.dart';
import 'package:app_mobile_utente/api/sos_repository.dart';
import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/screens/sos_screen.dart';

/// Canale method-channel usato da `permission_handler` su Android/iOS.
const MethodChannel kPermissionChannel = MethodChannel(
  'flutter.baseflow.com/permissions/methods',
);

/// @brief Stubba il canale dei permessi restituendo "granted".
///
/// `PermissionStatus.granted` e' codificato dal plugin come intero `1`:
/// la SOSScreen mostrera' "Posizione GPS disponibile".
/// @param tester il driver del widget test.
void stubLocationGranted(WidgetTester tester) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    kPermissionChannel,
    (call) async => 1,
  );
}

/// SosApi fittizia: registra l'invio o simula un errore di rete (offline).
class _FakeSos implements SosApi {
  _FakeSos({this.errore = false});
  final bool errore;
  bool chiamato = false;
  double? lat;
  double? lon;

  @override
  Future<Map<String, dynamic>> segnala({
    required double lat,
    required double lon,
    String? idCorsa,
  }) async {
    chiamato = true;
    this.lat = lat;
    this.lon = lon;
    if (errore) throw LeafApiException('rete giù');
    return {'id_segnalazione': 'sos-1', 'stato': 'inoltrata'};
  }
}

/// @brief Monta la [SOSScreen] con repository e rilevatore di posizione fittizi.
///
/// Il rilevatore restituisce coordinate deterministiche e sincrone così il
/// flusso di invio si risolve nei `pump` del test (nessun canale di plugin GPS).
/// @return il widget radice da passare a `pumpWidget`.
Widget buildSosApp({SosApi? repo}) {
  return MaterialApp(
    home: SOSScreen(
      repo: repo ?? _FakeSos(),
      rilevaPosizione: () async => (lat: 41.12, lon: 16.87),
    ),
  );
}

void main() {
  setUp(() {
    // Lingua deterministica per i finder testuali (IIN-7).
    appLanguage.value = 'it';
  });

  testWidgets('Lo stato iniziale mostra il pulsante SOS e la posizione', (
    tester,
  ) async {
    stubLocationGranted(tester);
    await tester.pumpWidget(buildSosApp());
    await tester.pump();

    expect(find.text('SOS'), findsOneWidget);
    expect(find.text('Posizione GPS disponibile'), findsOneWidget);
    expect(
      find.text('Premi il pulsante SOS\nin caso di emergenza'),
      findsOneWidget,
    );
  });

  testWidgets('Il tap su SOS avvia il countdown e invia entro 5 s (IIN-18)', (
    tester,
  ) async {
    stubLocationGranted(tester);
    final fake = _FakeSos();
    await tester.pumpWidget(buildSosApp(repo: fake));
    await tester.pump();

    await tester.tap(find.text('SOS'));
    await tester.pump();

    expect(find.text('Invio SOS in…'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('4'), findsOneWidget);

    // Restanti 4 secondi → countdown a 0 → invio asincrono al backend.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pump(); // completa la _inviaSos asincrona
    await tester.pump();

    expect(fake.chiamato, isTrue); // segnalazione inoltrata (POST /sos)
    expect(fake.lat, isNotNull); // posizione (GPS reale o riserva Bari)
    expect(find.text('SOS Inviato'), findsOneWidget);
    expect(
      find.text(
        'La tua posizione GPS è stata comunicata ai soccorsi.\n'
        'Rimani calmo e attendi i soccorsi.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('In errore di rete mostra l\'avviso e torna allo stato idle (IIN-6)', (
    tester,
  ) async {
    stubLocationGranted(tester);
    await tester.pumpWidget(buildSosApp(repo: _FakeSos(errore: true)));
    await tester.pump();

    await tester.tap(find.text('SOS'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Invio non riuscito'), findsOneWidget);
    expect(find.text('SOS'), findsOneWidget); // ritentabile
  });

  testWidgets('Annulla durante il countdown ripristina lo stato idle', (
    tester,
  ) async {
    stubLocationGranted(tester);
    await tester.pumpWidget(buildSosApp());
    await tester.pump();

    await tester.tap(find.text('SOS'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.text('Annulla'));
    await tester.pump();

    expect(find.text('SOS'), findsOneWidget);
    expect(find.text('Invio SOS in…'), findsNothing);
    expect(find.text('SOS Inviato'), findsNothing);
  });

  testWidgets('Annulla SOS dopo l\'invio torna allo stato idle', (
    tester,
  ) async {
    stubLocationGranted(tester);
    await tester.pumpWidget(buildSosApp());
    await tester.pump();

    await tester.tap(find.text('SOS'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pump(); // completa la _inviaSos asincrona
    await tester.pump();
    expect(find.text('SOS Inviato'), findsOneWidget);

    await tester.tap(find.text('Annulla SOS'));
    await tester.pump();

    expect(find.text('SOS'), findsOneWidget);
    expect(find.text('SOS Inviato'), findsNothing);
  });
}
