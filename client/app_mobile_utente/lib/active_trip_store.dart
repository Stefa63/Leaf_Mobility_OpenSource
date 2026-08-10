import 'package:flutter/foundation.dart';
import 'package:app_mobile_utente/screens/vehicle_detail_screen.dart';

/// @brief Stato di una corsa in svolgimento. UT.10, UT.12.
enum TripStatus {
  /// Corsa in corso: il mezzo è sbloccato e in uso.
  inCorso,

  /// Corsa in pausa: il mezzo resta bloccato e riservato all'utente (UT.12).
  inPausa,
}

/// @brief Modello della corsa attiva dell'utente. UT.10 (avvio), UT.12 (pausa).
///
/// Rappresenta la corsa avviata sul backend (`id_corsa`) e il suo stato locale.
/// Tiene il minimo necessario alla UI di pausa/riprendi; i dati di dettaglio
/// (costo, km) restano a carico del Business Tier `gestore_corse`.
class ActiveTrip {
  /// @brief Crea la corsa attiva.
  ActiveTrip({
    required this.idCorsa,
    required this.vehicleId,
    required this.vehicleType,
    required this.startedAt,
    this.status = TripStatus.inCorso,
  });

  /// Identificativo della corsa sul backend.
  final String idCorsa;

  /// Codice del veicolo in uso (es. 'SC-001').
  final String vehicleId;

  /// Tipo di veicolo, per icona/colore coerenti con il resto dell'app.
  final VehicleType vehicleType;

  /// Istante di avvio della corsa.
  final DateTime startedAt;

  /// Stato corrente della corsa (in corso o in pausa).
  final TripStatus status;

  /// @brief Indica se la corsa è attualmente in pausa (UT.12).
  bool get isPaused => status == TripStatus.inPausa;

  /// @brief Copia con stato aggiornato (gli altri campi restano invariati).
  /// @param status Nuovo stato della corsa.
  /// @return Nuova istanza con lo stato richiesto.
  ActiveTrip copyWith({TripStatus? status}) => ActiveTrip(
    idCorsa: idCorsa,
    vehicleId: vehicleId,
    vehicleType: vehicleType,
    startedAt: startedAt,
    status: status ?? this.status,
  );
}

/// @brief Store globale della corsa attiva (al più una). UT.10, UT.12.
///
/// Segue lo stesso pattern di [bookingStore]: un [ValueNotifier] osservabile
/// dalle viste tramite [ValueListenableBuilder], senza nuove dipendenze né
/// pattern MVC. Vale `null` quando non c'è alcuna corsa in svolgimento.
final ValueNotifier<ActiveTrip?> activeTripStore = ValueNotifier<ActiveTrip?>(
  null,
);

/// @brief Registra l'avvio di una corsa come corsa attiva. UT.10.
/// @param idCorsa Identificativo della corsa restituito dal backend.
/// @param vehicleId Codice del veicolo in uso.
/// @param vehicleType Tipo di veicolo.
void startActiveTrip({
  required String idCorsa,
  required String vehicleId,
  required VehicleType vehicleType,
}) {
  activeTripStore.value = ActiveTrip(
    idCorsa: idCorsa,
    vehicleId: vehicleId,
    vehicleType: vehicleType,
    startedAt: DateTime.now(),
  );
}

/// @brief Aggiorna lo stato della corsa attiva (pausa/ripresa). UT.12.
/// @param status Nuovo stato da applicare; ignorato se non c'è corsa attiva.
void setActiveTripStatus(TripStatus status) {
  final corrente = activeTripStore.value;
  if (corrente == null) return;
  activeTripStore.value = corrente.copyWith(status: status);
}

/// @brief Termina la corsa attiva azzerando lo store. UT.04.
void clearActiveTrip() {
  activeTripStore.value = null;
}

/// @brief Ripristina la corsa attiva da un documento corsa del backend (UT.10/UT.12, punto 2).
///
/// Usato all'avvio/risveglio dell'app per recuperare una corsa in corso o in pausa
/// dopo che lo stato locale (volatile) è andato perso (`GET /corse/attiva`). Preserva
/// l'istante di avvio e lo stato di pausa indicati dal server.
///
/// @param corsa Documento corsa grezzo (`_id`, `codice_identificativo_mezzo`,
///   `tipo_mezzo`, `stato`, `data_ora_inizio`).
void restoreActiveTrip(Map<String, dynamic> corsa) {
  final id = corsa['_id']?.toString() ?? '';
  if (id.isEmpty) return;
  final inizio =
      DateTime.tryParse('${corsa['data_ora_inizio'] ?? ''}')?.toLocal() ??
      DateTime.now();
  activeTripStore.value = ActiveTrip(
    idCorsa: id,
    vehicleId:
        '${corsa['codice_identificativo_mezzo'] ?? corsa['id_mezzo'] ?? ''}',
    vehicleType: vehicleTypeDaApi('${corsa['tipo_mezzo'] ?? ''}'),
    startedAt: inizio,
    status: '${corsa['stato'] ?? 'in_corso'}' == 'in_pausa'
        ? TripStatus.inPausa
        : TripStatus.inCorso,
  );
}
