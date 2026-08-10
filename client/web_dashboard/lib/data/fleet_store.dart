import 'package:flutter/foundation.dart';

import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/fleet_repository.dart';
import 'package:web_dashboard/data/fleet_data.dart';

/// @brief Stato osservabile della flotta alimentato da `/api/v1/flotta` (FASE 2.C).
///
/// Le viste OP/PA (mappa e metriche) osservano [vehicles] tramite
/// [ValueListenableBuilder], senza introdurre pattern MVC (stesso pattern degli
/// store statici esistenti). Il valore iniziale sono i dati di riserva
/// [FleetData.vehicles]: così la mappa non è mai vuota e, in assenza di rete
/// (IIN-6), resta sui dati di riserva con [offline] a true. OP.01/OP.20/AP.03/AP.10.
class FleetStore {
  FleetStore._();

  /// Mezzi correnti: dati reali se caricati, altrimenti i dati di riserva.
  static final ValueNotifier<List<Vehicle>> vehicles =
      ValueNotifier<List<Vehicle>>(FleetData.vehicles);

  /// True quando l'ultimo caricamento è fallito (si mostrano i dati di riserva).
  static final ValueNotifier<bool> offline = ValueNotifier<bool>(false);

  /// Caricamento in corso (almeno uno) per evitare richieste sovrapposte.
  static bool _inCorso = false;

  /// @brief Carica lo stato della flotta dal backend e aggiorna lo store.
  ///
  /// In caso di errore mantiene i dati correnti e imposta [offline] (IIN-6).
  /// @param repo Repository da usare (iniettabile nei test).
  static Future<void> carica({FlottaApi? repo}) async {
    if (_inCorso) return;
    _inCorso = true;
    try {
      final docs = await (repo ?? fleetRepository).elenco();
      vehicles.value = docs
          .map(Vehicle.daApi)
          .whereType<Vehicle>()
          .toList(growable: false);
      offline.value = false;
    } on LeafApiException {
      offline.value = true; // resta sui dati di riserva
    } finally {
      _inCorso = false;
    }
  }
}
