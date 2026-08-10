import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_dashboard/api/promotions_repository.dart';
import 'package:web_dashboard/data/discount_data.dart';
import 'package:web_dashboard/data/discount_store.dart';
import 'package:web_dashboard/screens/discount_management.dart';

/// PromozioniApi fittizia: nessuna rete (le azioni restano locali nei test).
class _FakePromozioni implements PromozioniApi {
  @override
  Future<List<Map<String, dynamic>>> elenco({bool soloAttive = false}) async =>
      const [];

  @override
  Future<String> crea({
    required String tipo,
    required String descrizione,
    num? valore,
    String? idArea,
  }) async => 'PR-test';

  @override
  Future<void> disattiva(String idPromozione) async {}
}

/// Regressione: il form di creazione sconto deve aprirsi e chiudersi (sia con
/// "Crea regola" che con "Annulla") senza far cadere l'albero dei widget. In
/// precedenza i `TextEditingController` venivano disposti subito dopo
/// `await showDialog`, mentre il dialog era ancora in animazione di chiusura,
/// provocando `'attached': is not true` / `'_dependents.isEmpty': is not true`.
void main() {
  setUp(() {
    DiscountStore.rules.value = DiscountData.rules;
    DiscountStore.offline.value = false;
  });

  testWidgets('Creazione regola sconto: open + submit', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiscountManagement(autoload: false, repo: _FakePromozioni()),
        ),
      ),
    );

    await tester.tap(find.text('Nuova Regola'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Regola di test');
    await tester.enterText(find.byType(TextFormField).at(1), 'Centro');
    await tester.enterText(find.byType(TextFormField).at(2), '+0,50 € credito');
    await tester.enterText(find.byType(TextFormField).at(3), 'Sempre attivo');

    await tester.tap(find.text('Crea regola'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Regola di test'), findsOneWidget);
  });

  testWidgets('Creazione regola sconto: open + annulla', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiscountManagement(autoload: false, repo: _FakePromozioni()),
        ),
      ),
    );

    await tester.tap(find.text('Nuova Regola'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
