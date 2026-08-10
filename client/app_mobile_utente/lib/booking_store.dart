import 'package:flutter/foundation.dart';
import 'package:app_mobile_utente/screens/vehicle_detail_screen.dart';

/// @brief Stato di una prenotazione di un mezzo. UT.02.
enum BookingStatus {
  /// Prenotazione attiva (veicolo riservato all'utente).
  attiva,

  /// Prenotazione annullata dall'utente. UT.12 (annullo) / OP.12.
  annullata,
}

/// @brief Modello di una prenotazione effettuata dall'utente. UT.02, UT.13.
///
/// Rappresenta la riserva esclusiva di un veicolo per un intervallo di minuti.
/// Le prenotazioni reali provengono dal backend (`/api/v1/prenotazioni`) via
/// [Booking.fromApi]; quelle locali (mezzi di riserva offline senza `docId`)
/// restano in-memory con [id] nullo.
class Booking {
  /// Id della prenotazione lato server (Firestore), per l'annullo (UT.12).
  /// Null per le prenotazioni locali dimostrative (offline, senza backend).
  final String? id;

  /// Codice identificativo del veicolo prenotato (es. 'SC-001').
  final String vehicleId;

  /// Etichetta leggibile del tipo di mezzo (es. 'Scooter Elettrico').
  final String vehicleTypeLabel;

  /// Tipo di veicolo, per icona/colore coerenti con il resto dell'app.
  final VehicleType vehicleType;

  /// Istante di creazione della prenotazione.
  final DateTime createdAt;

  /// Durata della riserva richiesta, in minuti.
  final int durationMinutes;

  /// Costo stimato della prenotazione, in euro.
  final double estimatedCost;

  /// Stato corrente della prenotazione.
  BookingStatus status;

  Booking({
    required this.vehicleId,
    required this.vehicleTypeLabel,
    required this.vehicleType,
    required this.createdAt,
    required this.durationMinutes,
    required this.estimatedCost,
    this.id,
    this.status = BookingStatus.attiva,
  });

  /// @brief Costruisce un [Booking] da un documento prenotazione della API (UT.02).
  ///
  /// La durata è derivata dalla finestra inizio→scadenza quando presente; il costo
  /// stimato è ricalcolato dalla tariffa al minuto del tipo di mezzo (coerente con
  /// la stima mostrata in fase di prenotazione, UT.03).
  ///
  /// @param doc Documento `prenotazioni` grezzo (`_id`, `codice_identificativo_mezzo`,
  ///   `tipo_mezzo`, `data_ora_inizio`, `data_ora_scadenza`…).
  /// @return Il modello di vista con `id` valorizzato per l'annullo.
  factory Booking.fromApi(Map<String, dynamic> doc) {
    final type = _vehicleTypeDaApi('${doc['tipo_mezzo'] ?? ''}');
    final createdAt =
        DateTime.tryParse('${doc['data_ora_inizio'] ?? ''}')?.toLocal() ??
        DateTime.now();
    final scadenza = doc['data_ora_scadenza'];
    final scadenzaDt = scadenza is String
        ? DateTime.tryParse(scadenza)?.toLocal()
        : null;
    final durata = scadenzaDt != null
        ? scadenzaDt.difference(createdAt).inMinutes
        : 0;
    final minuti = durata > 0 ? durata : 0;
    return Booking(
      id: doc['_id']?.toString(),
      vehicleId: '${doc['codice_identificativo_mezzo'] ?? doc['id_mezzo'] ?? ''}',
      vehicleTypeLabel: _etichettaTipoMezzo(type),
      vehicleType: type,
      createdAt: createdAt,
      durationMinutes: minuti,
      estimatedCost: _tariffaAlMinuto(type) * minuti,
    );
  }

  /// Istante di scadenza della riserva.
  DateTime get expiresAt => createdAt.add(Duration(minutes: durationMinutes));
}

/// Mappa il discriminante `tipo_mezzo` del server sull'enum di vista [VehicleType].
VehicleType _vehicleTypeDaApi(String tipo) {
  switch (tipo) {
    case 'ebike':
      return VehicleType.bike;
    case 'ecar':
      return VehicleType.car;
    case 'emotorbike':
      return VehicleType.emoto;
    default:
      return VehicleType.scooter;
  }
}

/// Etichetta leggibile del tipo di mezzo per la card prenotazione.
String _etichettaTipoMezzo(VehicleType t) {
  switch (t) {
    case VehicleType.scooter:
      return 'Scooter Elettrico';
    case VehicleType.bike:
      return 'E-Bike';
    case VehicleType.car:
      return 'Auto Elettrica';
    case VehicleType.emoto:
      return 'E-Moto';
  }
}

/// Tariffa al minuto (in euro) per tipo di mezzo, coerente con `booking_screen` (UT.03).
double _tariffaAlMinuto(VehicleType t) {
  switch (t) {
    case VehicleType.scooter:
      return 0.25;
    case VehicleType.bike:
      return 0.15;
    case VehicleType.car:
      return 0.45;
    case VehicleType.emoto:
      return 0.30;
  }
}

/// @brief Store globale in-memory delle prenotazioni utente. UT.02, UT.13.
///
/// Segue lo stesso pattern di [appLanguage]: un [ValueNotifier] osservabile
/// dalle viste tramite [ValueListenableBuilder], senza introdurre nuove
/// dipendenze ne' pattern MVC. Sara' sostituito dalle API del Business Tier.
final ValueNotifier<List<Booking>> bookingStore = ValueNotifier<List<Booking>>(
  <Booking>[],
);

/// @brief Aggiunge una nuova prenotazione in testa alla lista. UT.02.
/// @param booking la prenotazione da registrare.
void addBooking(Booking booking) {
  bookingStore.value = [booking, ...bookingStore.value];
}

/// @brief Annulla una prenotazione esistente. UT.12.
/// @param booking la prenotazione da contrassegnare come annullata.
void cancelBooking(Booking booking) {
  booking.status = BookingStatus.annullata;
  // Riassegna la lista per notificare gli ascoltatori.
  bookingStore.value = List<Booking>.of(bookingStore.value);
}
