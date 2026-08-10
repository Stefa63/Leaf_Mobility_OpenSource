import 'package:flutter/foundation.dart';

import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/fleet_repository.dart';

/// @brief Allerta operativa derivata dalle soglie configurate (OP.02/OP.22).
///
/// Due forme, distinte dal discriminante [tipo]:
/// - `mezzi_area`: un'area è scesa sotto il minimo di mezzi richiesto (OP.02);
/// - `batteria`: un mezzo è sotto la percentuale di batteria di allerta (OP.22).
/// I campi non pertinenti alla forma restano `null`.
class FleetAlert {
  /// @brief Costruisce un'allerta tipizzata della flotta.
  const FleetAlert({
    required this.tipo,
    this.area,
    this.presenti,
    this.minimo,
    this.mezzo,
    this.batteria,
    this.soglia,
  });

  /// Discriminante della forma: `mezzi_area` oppure `batteria`.
  final String tipo;

  // ── Forma `mezzi_area` (OP.02) ─────────────────────────────────────────────
  /// Nome (o id) dell'area sotto soglia.
  final String? area;

  /// Mezzi attualmente presenti nell'area.
  final int? presenti;

  /// Minimo di mezzi richiesto per l'area.
  final int? minimo;

  // ── Forma `batteria` (OP.22) ───────────────────────────────────────────────
  /// Codice identificativo del mezzo sotto soglia batteria.
  final String? mezzo;

  /// Percentuale di batteria attuale del mezzo.
  final int? batteria;

  /// Percentuale di allerta configurata.
  final int? soglia;

  /// @brief Costruisce un'allerta dal documento grezzo della API.
  /// @param doc Documento allerta (`/soglie/allerte`).
  /// @return L'allerta tipizzata, o `null` se il `tipo` non è riconosciuto.
  static FleetAlert? daApi(Map<String, dynamic> doc) {
    final tipo = '${doc['tipo'] ?? ''}';
    switch (tipo) {
      case 'mezzi_area':
        return FleetAlert(
          tipo: tipo,
          area: doc['area']?.toString(),
          presenti: (doc['presenti'] as num?)?.toInt(),
          minimo: (doc['minimo'] as num?)?.toInt(),
        );
      case 'batteria':
        return FleetAlert(
          tipo: tipo,
          mezzo: doc['mezzo']?.toString(),
          batteria: (doc['batteria'] as num?)?.toInt(),
          soglia: (doc['soglia'] as num?)?.toInt(),
        );
      default:
        return null;
    }
  }
}

/// @brief Stato osservabile delle allerte di soglia alimentato da `/api/v1/soglie/allerte`.
///
/// La home dell'Operatore osserva [allerte] tramite [ValueListenableBuilder] per
/// alimentare la coda allarmi real-time (OP.02/OP.22), senza pattern MVC (stesso
/// approccio di [FleetStore]). In assenza di rete (IIN-6) la lista resta vuota e
/// [offline] passa a true: la vista ricade sui propri dati di riserva statici.
class AlertsStore {
  AlertsStore._();

  /// Allerte attive correnti (vuota finché non caricate o in fallback offline).
  static final ValueNotifier<List<FleetAlert>> allerte =
      ValueNotifier<List<FleetAlert>>(const []);

  /// True quando l'ultimo caricamento è fallito (si mostrano i dati di riserva).
  static final ValueNotifier<bool> offline = ValueNotifier<bool>(false);

  /// Caricamento in corso, per evitare richieste sovrapposte.
  static bool _inCorso = false;

  /// @brief Carica le allerte di soglia dal backend e aggiorna lo store.
  ///
  /// In caso di errore svuota le allerte reali e imposta [offline] (IIN-6),
  /// lasciando alla vista i propri dati di riserva.
  /// @param repo Repository da usare (iniettabile nei test).
  static Future<void> carica({FlottaApi? repo}) async {
    if (_inCorso) return;
    _inCorso = true;
    try {
      final docs = await (repo ?? fleetRepository).soglieAllerte();
      allerte.value = docs
          .map(FleetAlert.daApi)
          .whereType<FleetAlert>()
          .toList(growable: false);
      offline.value = false;
    } on LeafApiException {
      allerte.value = const [];
      offline.value = true; // la vista resta sui dati di riserva
    } finally {
      _inCorso = false;
    }
  }
}
