// Test dello store Gestione Sconti alimentato da /api/v1/promozioni (Blocco 1, OP.09/15).

import 'package:flutter_test/flutter_test.dart';

import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/promotions_repository.dart';
import 'package:web_dashboard/data/discount_data.dart';
import 'package:web_dashboard/data/discount_store.dart';

/// PromozioniApi fittizia: una promozione deterministica (o errore di rete).
class _FakePromozioni implements PromozioniApi {
  _FakePromozioni({this.errore = false});
  final bool errore;
  String? disattivata;
  String? tipoCreato;

  @override
  Future<List<Map<String, dynamic>>> elenco({bool soloAttive = false}) async {
    if (errore) throw LeafApiException('rete giù');
    return [
      {
        '_id': 'PR-1',
        'tipo': 'credito_bonus_parcheggio',
        'descrizione': 'Bonus hub centrale',
        'valore': 50,
        'stato': 'attiva',
      },
    ];
  }

  @override
  Future<String> crea({
    required String tipo,
    required String descrizione,
    num? valore,
    String? idArea,
  }) async {
    tipoCreato = tipo;
    return 'PR-new';
  }

  @override
  Future<void> disattiva(String idPromozione) async {
    disattivata = idPromozione;
  }
}

void main() {
  setUp(() {
    DiscountStore.rules.value = DiscountData.rules;
    DiscountStore.offline.value = false;
  });

  test('DiscountRule.daApi distingue il tipo dal documento', () {
    final r = DiscountRule.daApi({
      '_id': 'PR-1',
      'tipo': 'sconto_geografico',
      'descrizione': 'Promo periferia',
      'valore': 20,
      'stato': 'attiva',
    });
    expect(r, isNotNull);
    expect(r!.type, DiscountType.geoDiscount);
    expect(r.active, isTrue);
  });

  test('carica popola le regole dai dati reali', () async {
    await DiscountStore.carica(repo: _FakePromozioni());
    expect(DiscountStore.rules.value.single.id, 'PR-1');
    expect(DiscountStore.rules.value.single.type, DiscountType.parkingBonus);
    expect(DiscountStore.offline.value, isFalse);
  });

  test('carica segnala offline e tiene i dati di riserva', () async {
    await DiscountStore.carica(repo: _FakePromozioni(errore: true));
    expect(DiscountStore.offline.value, isTrue);
    expect(DiscountStore.rules.value, DiscountData.rules);
  });

  test('aggiungi inserisce in testa e crea sul backend (OP.09/15)', () async {
    final repo = _FakePromozioni();
    final regola = DiscountRule(
      id: 'SC-99',
      type: DiscountType.geoDiscount,
      name: 'Test',
      area: 'Centro',
      value: '-10%',
      period: '—',
    );
    await DiscountStore.aggiungi(regola, repo: repo);
    expect(DiscountStore.rules.value.first.id, 'SC-99');
    expect(repo.tipoCreato, 'sconto_geografico');
  });

  test('rimuovi toglie la regola e la disattiva sul backend (OP.15)', () async {
    final repo = _FakePromozioni();
    await DiscountStore.carica(repo: repo);
    await DiscountStore.rimuovi('PR-1', repo: repo);
    expect(DiscountStore.rules.value, isEmpty);
    expect(repo.disattivata, 'PR-1');
  });
}
