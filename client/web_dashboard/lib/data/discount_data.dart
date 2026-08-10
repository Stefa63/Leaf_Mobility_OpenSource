// discount_data.dart
// Modelli e dati di riserva della Gestione Sconti (OP.09 / OP.15).
//
// DiscountRule e il mapper daApi traducono i documenti di /api/v1/promozioni.
// I dati di riserva (mock storici) alimentano la vista finché il backend non
// risponde, così senza rete (IIN-6) la schermata non resta vuota.

/// @brief Tipo di incentivo configurabile dall'Operatore (OP.09 / OP.15).
enum DiscountType { parkingBonus, geoDiscount }

/// @brief Regola di sconto/incentivo geografico.
class DiscountRule {
  /// @brief Crea una regola di sconto.
  DiscountRule({
    required this.id,
    required this.type,
    required this.name,
    required this.area,
    required this.value,
    required this.period,
    this.active = true,
  });

  /// @brief Costruisce una [DiscountRule] da un documento promozione della API.
  /// @param doc Documento promozione (`/api/v1/promozioni`).
  /// @return La regola mappata, o null se priva di identificativo.
  static DiscountRule? daApi(Map<String, dynamic> doc) {
    final id = doc['_id']?.toString();
    if (id == null || id.isEmpty) return null;
    final tipo = doc['tipo']?.toString();
    final geo = tipo != 'credito_bonus_parcheggio';
    final valore = doc['valore'];
    return DiscountRule(
      id: id,
      type: geo ? DiscountType.geoDiscount : DiscountType.parkingBonus,
      name: doc['descrizione']?.toString() ?? id,
      area: doc['id_area']?.toString() ?? '—',
      value: valore == null
          ? '—'
          : (geo ? '-$valore% corsa' : '+$valore € credito'),
      period: '—',
      active: doc['stato'] != 'sospesa',
    );
  }

  /// @brief Identificativo della regola.
  final String id;

  /// @brief Tipo di incentivo (bonus parcheggio / sconto geografico).
  final DiscountType type;

  /// @brief Nome/descrizione della regola.
  String name;

  /// @brief Area geografica di applicazione.
  final String area;

  /// @brief Valore leggibile dell'incentivo.
  final String value;

  /// @brief Periodo di validità leggibile.
  final String period;

  /// @brief Stato attivo/sospeso della regola.
  bool active;
}

/// @brief Dati di riserva della Gestione Sconti (mock storici, lista stabile).
class DiscountData {
  /// @brief Regole di sconto di riserva.
  static final List<DiscountRule> rules = [
    DiscountRule(
      id: 'SC-01',
      type: DiscountType.parkingBonus,
      name: 'Bonus rilascio Piazza Ferrarese',
      area: 'Piazza Ferrarese',
      value: '+0,50 € credito',
      period: 'Sempre attivo',
    ),
    DiscountRule(
      id: 'SC-02',
      type: DiscountType.geoDiscount,
      name: 'Sconto avvio Quartiere Libertà',
      area: 'Quartiere Libertà',
      value: '-20% avvio corsa',
      period: 'Lun–Ven 07:00–10:00',
    ),
    DiscountRule(
      id: 'SC-03',
      type: DiscountType.parkingBonus,
      name: 'Bonus hub Lungomare',
      area: 'Lungomare',
      value: '+0,30 € credito',
      period: 'Weekend',
      active: false,
    ),
    DiscountRule(
      id: 'SC-04',
      type: DiscountType.geoDiscount,
      name: 'Promo Japigia Sud',
      area: 'Japigia Sud',
      value: '-15% corsa',
      period: 'Tutti i giorni 20:00–23:00',
    ),
  ];
}
