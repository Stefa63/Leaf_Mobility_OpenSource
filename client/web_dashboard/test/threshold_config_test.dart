// Widget test della Config Soglie: soglia mezzi per area (OP.02) + batteria (OP.22).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/areas_repository.dart';
import 'package:web_dashboard/api/fleet_repository.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/screens/threshold_config.dart';

/// FlottaApi fittizia: registra gli argomenti delle soglie impostate.
class _FakeFlotta implements FlottaApi {
  String? areaId;
  int? areaMinimo;
  int? batteriaPct;
  String? batteriaTipo;
  bool batteriaChiamata = false;

  @override
  Future<String> impostaSogliaArea({
    required String idArea,
    required int minimo,
  }) async {
    areaId = idArea;
    areaMinimo = minimo;
    return 'sog-1';
  }

  @override
  Future<String> impostaSogliaBatteria({
    required int percentuale,
    String? tipoMezzo,
  }) async {
    batteriaChiamata = true;
    batteriaPct = percentuale;
    batteriaTipo = tipoMezzo;
    return 'sog-2';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} non usato nei test');
}

/// AreeApi fittizia: una sola area attiva, o errore di rete.
class _FakeAree implements AreeApi {
  _FakeAree({this.errore = false});
  final bool errore;

  @override
  Future<List<Map<String, dynamic>>> elenco({bool soloAttive = false}) async {
    if (errore) throw LeafApiException('rete giù');
    return [
      {'_id': 'area-centro', 'nome': 'Centro Storico'},
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} non usato nei test');
}

Future<void> _pump(
  WidgetTester tester,
  FlottaApi flotta,
  AreeApi aree,
) async {
  appLanguage.value = 'it';
  await tester.binding.setSurfaceSize(const Size(1200, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ThresholdConfig(fleetRepo: flotta, areeRepo: aree),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Imposta la soglia batteria con i valori del form (OP.22)', (
    tester,
  ) async {
    final flotta = _FakeFlotta();
    await _pump(tester, flotta, _FakeAree());

    expect(find.text('Config Soglie'), findsOneWidget);

    await tester.tap(find.text('Salva soglia batteria'));
    await tester.pumpAndSettle();

    expect(flotta.batteriaChiamata, isTrue);
    expect(flotta.batteriaPct, 20); // valore predefinito del campo
    expect(flotta.batteriaTipo, isNull); // "Tutti i mezzi"
  });

  testWidgets('Imposta la soglia area selezionando area e minimo (OP.02)', (
    tester,
  ) async {
    final flotta = _FakeFlotta();
    await _pump(tester, flotta, _FakeAree());

    // Seleziona l'area dal dropdown.
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Centro Storico').last);
    await tester.pumpAndSettle();

    // Inserisce il numero minimo di mezzi.
    await tester.enterText(
      find.widgetWithText(TextField, 'Numero minimo di mezzi'),
      '5',
    );
    await tester.tap(find.text('Salva soglia area'));
    await tester.pumpAndSettle();

    expect(flotta.areaId, 'area-centro');
    expect(flotta.areaMinimo, 5);
  });

  testWidgets('Aree offline mostra l\'avviso ma il form batteria resta (IIN-6)', (
    tester,
  ) async {
    await _pump(tester, _FakeFlotta(), _FakeAree(errore: true));

    expect(find.text('Aree non disponibili (offline)'), findsOneWidget);
    expect(find.text('Salva soglia batteria'), findsOneWidget);
  });
}
