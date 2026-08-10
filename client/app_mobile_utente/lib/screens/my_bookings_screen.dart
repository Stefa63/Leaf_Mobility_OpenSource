import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app_mobile_utente/active_trip_store.dart';
import 'package:app_mobile_utente/api/api_client.dart';
import 'package:app_mobile_utente/api/corse_repository.dart';
import 'package:app_mobile_utente/theme.dart';
import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/booking_store.dart';
import 'package:app_mobile_utente/screens/vehicle_detail_screen.dart';
import 'package:app_mobile_utente/widgets/stato_vista.dart';

/// Icona Material associata a un tipo di veicolo.
IconData iconForVehicleType(VehicleType type) {
  switch (type) {
    case VehicleType.scooter:
      return Icons.electric_scooter;
    case VehicleType.bike:
      return Icons.pedal_bike;
    case VehicleType.car:
      return Icons.directions_car;
    case VehicleType.emoto:
      return Icons.electric_moped;
  }
}

/// @brief Schermata "Mie Prenotazioni": corsa attiva + prenotazioni effettuate.
///
/// UT.02 (prenotazioni effettuate), UT.10/UT.12 (corsa attiva, pausa/riprendi).
/// Le prenotazioni sono caricate dal backend (`/api/v1/prenotazioni`, persistenti
/// e condivise) e unite alle eventuali prenotazioni locali offline; la corsa
/// attiva è osservata da [activeTripStore].
class MyBookingsScreen extends StatefulWidget {
  /// @brief Crea la schermata; il repository corse è iniettabile nei test.
  const MyBookingsScreen({super.key, CorseApi? corse}) : _corse = corse;

  final CorseApi? _corse;

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  /// Repository risolto: quello iniettato (test) o il singleton reale.
  late final CorseApi _corse = widget._corse ?? corseRepository;

  /// Contatore di ricarica: incrementarlo forza il reload del [CaricatoreVista]
  /// (es. dopo un annullo) senza gestione manuale dello stato della lista.
  int _ricarica = 0;

  /// Icona Material associata al tipo di veicolo prenotato.
  IconData _iconFor(Booking b) => iconForVehicleType(b.vehicleType);

  /// Orario in formato HH:mm.
  String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Carica le prenotazioni attive dal backend (UT.02/UT.21), unendo eventuali
  /// prenotazioni locali dimostrative (mezzi di riserva offline, `id` nullo).
  Future<List<Booking>> _caricaPrenotazioni() async {
    final docs = await _corse.prenotazioni();
    final server = docs.map(Booking.fromApi).toList();
    final locali = bookingStore.value.where(
      (b) => b.id == null && b.status == BookingStatus.attiva,
    );
    return [...server, ...locali];
  }

  /// Annulla una prenotazione: sul backend se ha un `id` reale (UT.12), altrimenti
  /// solo localmente; quindi forza la ricarica della lista.
  Future<void> _annulla(Booking b) async {
    final id = b.id;
    if (id == null) {
      cancelBooking(b);
      setState(() => _ricarica++);
      return;
    }
    try {
      await _corse.annullaPrenotazione(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('Prenotazione annullata')),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      setState(() => _ricarica++);
    } on LeafApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.messaggio),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        title: Text(tr('Mie Prenotazioni')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Corsa attiva con comandi pausa/riprendi (UT.12), se presente.
          ValueListenableBuilder<ActiveTrip?>(
            valueListenable: activeTripStore,
            builder: (context, trip, _) => trip == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _ActiveTripCard(trip: trip, corse: _corse),
                  ),
          ),
          Expanded(
            // Prenotazioni reali dal backend: caricamento→errore(retry)→vuoto→lista.
            child: CaricatoreVista<List<Booking>>(
              key: ValueKey(_ricarica),
              carica: _caricaPrenotazioni,
              vuotoSe: (bookings) => bookings.isEmpty,
              vistaVuota: VistaVuota(
                titolo: tr('Nessuna prenotazione attiva'),
                sottotitolo: tr('Le prenotazioni che effettui appariranno qui.'),
                icona: Icons.event_busy_outlined,
              ),
              costruisci: (context, bookings) => ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: bookings.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, i) =>
                    _buildBookingCard(context, bookings[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card di una singola prenotazione, con azione di annullo se attiva.
  Widget _buildBookingCard(BuildContext context, Booking b) {
    final bool active = b.status == BookingStatus.attiva;
    final Color statusColor = active ? AppTheme.primaryGreen : Colors.grey;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withAlpha(28),
                child: Icon(_iconFor(b), color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${b.vehicleTypeLabel} · ${b.vehicleId}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${tr('Riservato alle')} ${_hhmm(b.createdAt)} · ${b.durationMinutes} ${tr('min')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(active: active),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.schedule_outlined,
                    size: 16,
                    color: AppTheme.accentBrown,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${tr('Scade alle')} ${_hhmm(b.expiresAt)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              Text(
                '${b.estimatedCost.toStringAsFixed(2)} €',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGreen,
                ),
              ),
            ],
          ),
          if (active) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _annulla(b),
                icon: const Icon(
                  Icons.cancel_outlined,
                  color: Colors.red,
                  size: 18,
                ),
                label: Text(
                  tr('Annulla prenotazione'),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// @brief Card della corsa in svolgimento con comandi pausa/riprendi (UT.12).
///
/// Invia al backend `pausa`/`riprendi` (`/corse/{id}/pausa|riprendi`) tramite
/// [CorseApi] e aggiorna lo stato osservabile [activeTripStore]. Mantiene il
/// mezzo bloccato e a disposizione dell'utente senza terminare il noleggio.
class _ActiveTripCard extends StatefulWidget {
  const _ActiveTripCard({required this.trip, CorseApi? corse}) : _corse = corse;

  /// Corsa attiva da rappresentare.
  final ActiveTrip trip;

  /// Repository corse usato per pausa/riprendi (default reale; test).
  final CorseApi? _corse;

  @override
  State<_ActiveTripCard> createState() => _ActiveTripCardState();
}

class _ActiveTripCardState extends State<_ActiveTripCard> {
  late final CorseApi _corse = widget._corse ?? corseRepository;

  /// Operazione pausa/riprendi in corso (disabilita il pulsante).
  bool _inCorso = false;

  /// Conclusione del noleggio in corso (disabilita i pulsanti).
  bool _conclusione = false;

  /// Conclude il noleggio: termina la corsa sul backend, mostra l'importo finale
  /// e azzera la corsa attiva (UT.04). L'eventuale copertura da abbonamento è
  /// riflessa nel riepilogo (punto 3/8).
  Future<void> _concludi() async {
    if (_conclusione) return;
    setState(() => _conclusione = true);
    // OP.05/OP.04: posizione GPS di chiusura best-effort (riserva: nessuna coordinata).
    double? lat;
    double? lon;
    try {
      final pos = await Geolocator.getCurrentPosition();
      lat = pos.latitude;
      lon = pos.longitude;
    } catch (_) {
      // GPS non disponibile: si conclude comunque senza coordinate.
    }
    try {
      final dati = await _corse.termina(widget.trip.idCorsa, lat: lat, lon: lon);
      clearActiveTrip();
      if (!mounted) return;
      final coperto = dati['coperto_da_abbonamento'] == true;
      final cent = (dati['costo_finale_cent'] as num?)?.toInt() ?? 0;
      final fuoriArea = dati['fuori_area_operativa'] == true;
      final base = coperto
          ? '${tr('Noleggio concluso')} · ${tr('coperto da abbonamento')}'
          : '${tr('Noleggio concluso')} · ${(cent / 100).toStringAsFixed(2)} €';
      final messaggio = fuoriArea
          ? '$base · ${tr('rilascio fuori area operativa')}'
          : base;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(messaggio),
          backgroundColor: fuoriArea
              ? const Color(0xFFE65100)
              : AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } on LeafApiException catch (e) {
      if (!mounted) return;
      setState(() => _conclusione = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.messaggio), backgroundColor: const Color(0xFFC62828)),
      );
    }
  }

  /// Mette in pausa o riprende la corsa sul backend (UT.12).
  Future<void> _commuta() async {
    if (_inCorso) return;
    final trip = widget.trip;
    setState(() => _inCorso = true);
    try {
      if (trip.isPaused) {
        await _corse.riprendi(trip.idCorsa);
        setActiveTripStatus(TripStatus.inCorso);
      } else {
        await _corse.pausa(trip.idCorsa);
        setActiveTripStatus(TripStatus.inPausa);
      }
    } on LeafApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.messaggio), backgroundColor: const Color(0xFFC62828)),
      );
    } finally {
      if (mounted) setState(() => _inCorso = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final bool paused = trip.isPaused;
    final Color accento = paused ? AppTheme.accentBrown : AppTheme.primaryGreen;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accento.withAlpha(120)),
        boxShadow: [
          BoxShadow(
            color: accento.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: accento.withAlpha(28),
                child: Icon(iconForVehicleType(trip.vehicleType), color: accento),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tr('Corsa in corso')} · ${trip.vehicleId}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      paused ? tr('In pausa') : tr('In movimento'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accento,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accento,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: (_inCorso || _conclusione) ? null : _commuta,
              icon: _inCorso
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(paused ? Icons.play_arrow : Icons.pause),
              label: Text(
                paused ? tr('Riprendi corsa') : tr('Pausa corsa'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC62828),
                side: const BorderSide(color: Color(0xFFC62828)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: (_inCorso || _conclusione) ? null : _concludi,
              icon: _conclusione
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFC62828),
                      ),
                    )
                  : const Icon(Icons.stop_circle_outlined),
              label: Text(
                tr('Concludi noleggio'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge di stato (Attiva / Annullata) della prenotazione.
class _StatusBadge extends StatelessWidget {
  final bool active;
  const _StatusBadge({required this.active});
  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.primaryGreen : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        active ? tr('Attiva') : tr('Annullata'),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
