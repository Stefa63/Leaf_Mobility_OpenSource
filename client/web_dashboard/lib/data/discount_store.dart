import 'package:flutter/foundation.dart';

import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/promotions_repository.dart';
import 'package:web_dashboard/data/discount_data.dart';

/// @brief Stato osservabile della Gestione Sconti da `/api/v1/promozioni` (OP.09/15).
///
/// La schermata osserva [rules] tramite [ValueListenableBuilder] (nessun MVC,
/// stesso pattern di `FleetStore`). Valore iniziale = dati di riserva
/// [DiscountData]: senza rete (IIN-6) resta sui mock con [offline] a true. Le
/// mutazioni sono ottimistiche (aggiornano subito lo store) con sync best-effort
/// verso il backend.
class DiscountStore {
  DiscountStore._();

  /// Tipo server della promozione per ciascun tipo UI.
  static String tipoServer(DiscountType t) => t == DiscountType.parkingBonus
      ? 'credito_bonus_parcheggio'
      : 'sconto_geografico';

  /// Regole correnti (reali se caricate, altrimenti di riserva).
  static final ValueNotifier<List<DiscountRule>> rules =
      ValueNotifier<List<DiscountRule>>(DiscountData.rules);

  /// True quando l'ultimo caricamento è fallito (si mostrano i dati di riserva).
  static final ValueNotifier<bool> offline = ValueNotifier<bool>(false);

  static bool _inCorso = false;

  /// @brief Carica le promozioni dal backend e aggiorna lo store.
  /// @param repo Repository da usare (iniettabile nei test).
  static Future<void> carica({PromozioniApi? repo}) async {
    if (_inCorso) return;
    _inCorso = true;
    try {
      final docs = await (repo ?? promotionsRepository).elenco();
      rules.value = docs
          .map(DiscountRule.daApi)
          .whereType<DiscountRule>()
          .toList(growable: false);
      offline.value = false;
    } on LeafApiException {
      offline.value = true; // resta sui dati di riserva
    } finally {
      _inCorso = false;
    }
  }

  /// @brief Inserisce una regola in testa (ottimistico) e la sincronizza (OP.09/15).
  /// @param regola Regola creata dal form.
  /// @param repo Repository da usare (iniettabile nei test).
  static Future<void> aggiungi(DiscountRule regola, {PromozioniApi? repo}) async {
    rules.value = [regola, ...rules.value];
    try {
      await (repo ?? promotionsRepository).crea(
        tipo: tipoServer(regola.type),
        descrizione: regola.name,
      );
    } on LeafApiException {
      offline.value = true; // creata localmente, sync differita
    }
  }

  /// @brief Attiva/sospende una regola (ottimistico + sync best-effort, OP.15).
  /// @param id Id della regola.
  /// @param attiva Nuovo stato.
  /// @param repo Repository da usare (iniettabile nei test).
  static Future<void> imposta(
    String id, {
    required bool attiva,
    PromozioniApi? repo,
  }) async {
    rules.value = rules.value.map((r) {
      if (r.id == id) r.active = attiva;
      return r;
    }).toList(growable: false);
    if (!attiva) {
      try {
        await (repo ?? promotionsRepository).disattiva(id);
      } on LeafApiException {
        offline.value = true;
      }
    }
  }

  /// @brief Rimuove una regola (ottimistico) disattivandola sul backend (OP.15).
  /// @param id Id della regola.
  /// @param repo Repository da usare (iniettabile nei test).
  static Future<void> rimuovi(String id, {PromozioniApi? repo}) async {
    rules.value =
        rules.value.where((r) => r.id != id).toList(growable: false);
    try {
      await (repo ?? promotionsRepository).disattiva(id);
    } on LeafApiException {
      offline.value = true;
    }
  }
}
