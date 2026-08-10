import 'package:flutter/material.dart';
import 'package:app_mobile_utente/api/api_client.dart';
import 'package:app_mobile_utente/api/corse_repository.dart';
import 'package:app_mobile_utente/theme.dart';
import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/screens/history_screen.dart';
import 'package:app_mobile_utente/screens/invoice_screen.dart';

/// Detail screen for a single past trip. UT.17 (storico corse).
///
/// Opened from the Home tab history strip and from the full history list.
/// Shows the ride characteristics (route, time, duration, distance), the
/// vehicle used and the cost breakdown, plus the star rating (UT.16).
class TripDetailScreen extends StatelessWidget {
  /// The trip whose details are displayed.
  final TripEntry trip;

  /// Repository corse iniettabile (default reale; fittizio nei test).
  final CorseApi? corse;

  const TripDetailScreen({required this.trip, super.key, this.corse});

  /// Material icon representing the vehicle type used for the trip.
  IconData get _vehicleIcon {
    switch (trip.vehicleType) {
      case 'E-Bike':
        return Icons.pedal_bike;
      case 'Auto':
        return Icons.directions_car;
      case 'E-Moto':
        return Icons.electric_moped;
      default:
        return Icons.electric_scooter;
    }
  }

  /// Average speed of the trip in km/h (defensive against zero duration).
  double get _avgSpeed => trip.durationMinutes == 0
      ? 0
      : trip.distanceKm / trip.durationMinutes * 60;

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${tr('Corsa')} ${trip.id}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Vehicle hero ─────────────────────────────────────────────
              Card(
                elevation: 0,
                color: AppTheme.primaryGreen.withAlpha(18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      Icon(
                        _vehicleIcon,
                        size: 64,
                        color: AppTheme.primaryGreen,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        trip.vehicleType,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${trip.date} · ${trip.time}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Route ────────────────────────────────────────────────────
              _SectionLabel(tr('Percorso')),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                color: AppTheme.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RoutePoint(
                        icon: Icons.trip_origin,
                        color: AppTheme.primaryGreen,
                        label: trip.from,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 8,
                          top: 4,
                          bottom: 4,
                        ),
                        child: Container(
                          width: 2,
                          height: 16,
                          color: Colors.black12,
                        ),
                      ),
                      _RoutePoint(
                        icon: Icons.location_on,
                        color: Colors.red,
                        label: trip.to,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Trip stats ───────────────────────────────────────────────
              _SectionLabel(tr('Dettagli corsa')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.schedule_outlined,
                      label: tr('Durata'),
                      value: '${trip.durationMinutes} ${tr('min')}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.straighten_outlined,
                      label: tr('Distanza'),
                      value: '${trip.distanceKm} km',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.speed_outlined,
                      label: tr('Velocità media'),
                      value: '${_avgSpeed.toStringAsFixed(0)} km/h',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.eco_outlined,
                      label: tr('CO₂ risparmiata'),
                      value:
                          '${(trip.distanceKm * 0.12).toStringAsFixed(2)} kg',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Cost ─────────────────────────────────────────────────────
              _SectionLabel(tr('Importo addebitato')),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          color: AppTheme.accentBrown,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          tr('Totale corsa'),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${trip.cost.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Invoice export (UT.25) ───────────────────────────────────
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => InvoiceScreen(trip: trip),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.download_outlined,
                  color: AppTheme.accentBrown,
                ),
                label: Text(
                  tr('Esporta fattura'),
                  style: const TextStyle(color: AppTheme.accentBrown),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.accentBrown),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),

              // ── Rate this trip (UT.16) ───────────────────────────────────
              OutlinedButton.icon(
                onPressed: () => _showRateDialog(context),
                icon: const Icon(Icons.star_outline, color: AppTheme.primaryGreen),
                label: Text(
                  tr('Valuta corsa'),
                  style: const TextStyle(color: AppTheme.primaryGreen),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryGreen),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),

              // ── Report this trip (UT.09) ─────────────────────────────────
              OutlinedButton.icon(
                onPressed: () => _showReportDialog(context),
                icon: const Icon(Icons.flag_outlined, color: Colors.red),
                label: Text(
                  tr('Segnala corsa'),
                  style: const TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Apre il modulo di segnalazione di un problema sulla corsa. UT.09.
  ///
  /// Invio simulato (snackbar di conferma) finche' il Business Tier
  /// `gestore_assistenza_ticket` non sara' disponibile, coerentemente con la
  /// schermata Assistenza.
  void _showReportDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => _ReportTripDialog(tripId: trip.id),
    );
  }

  /// Apre il dialogo di valutazione a stelle della corsa conclusa. UT.16.
  void _showRateDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) =>
          _RateTripDialog(tripId: trip.id, corse: corse ?? corseRepository),
    );
  }
}

/// Dialogo di valutazione a stelle (1–5) di una corsa conclusa. UT.16.
class _RateTripDialog extends StatefulWidget {
  /// Identificativo della corsa da valutare.
  final String tripId;

  /// Repository corse per inviare la valutazione (`POST /corse/{id}/valutazione`).
  final CorseApi corse;

  const _RateTripDialog({required this.tripId, required this.corse});

  @override
  State<_RateTripDialog> createState() => _RateTripDialogState();
}

class _RateTripDialogState extends State<_RateTripDialog> {
  int _stelle = 0;
  bool _invio = false;

  Future<void> _submit() async {
    if (_stelle < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('Seleziona almeno una stella.')),
          backgroundColor: AppTheme.accentBrown,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    setState(() => _invio = true);
    try {
      await widget.corse.valuta(widget.tripId, _stelle);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('Grazie per la tua valutazione!')),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } on LeafApiException catch (e) {
      if (!mounted) return;
      setState(() => _invio = false);
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
    return AlertDialog(
      backgroundColor: AppTheme.backgroundBeige,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('${tr('Valuta corsa')} ${widget.tripId}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tr('Quanto sei soddisfatto della corsa?'),
            style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: _invio ? null : () => setState(() => _stelle = i),
                  icon: Icon(
                    i <= _stelle ? Icons.star : Icons.star_border,
                    color: AppTheme.primaryGreen,
                    size: 32,
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _invio ? null : () => Navigator.pop(context),
          child: Text(
            tr('Annulla'),
            style: const TextStyle(color: AppTheme.textGrey),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _invio ? null : _submit,
          icon: _invio
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_outlined, size: 18),
          label: Text(tr('Invia')),
        ),
      ],
    );
  }
}

/// Dialogo di segnalazione di una corsa: descrizione del problema + invio. UT.09.
class _ReportTripDialog extends StatefulWidget {
  /// Identificativo della corsa segnalata.
  final String tripId;

  const _ReportTripDialog({required this.tripId});

  @override
  State<_ReportTripDialog> createState() => _ReportTripDialogState();
}

class _ReportTripDialogState extends State<_ReportTripDialog> {
  final TextEditingController _message = TextEditingController();

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  void _submit() {
    if (_message.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('Inserisci un messaggio prima di inviare.')),
          backgroundColor: AppTheme.accentBrown,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('Grazie! La tua segnalazione è stata inviata.')),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.backgroundBeige,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('${tr('Segnala corsa')} ${widget.tripId}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('Descrivi il problema riscontrato durante la corsa.'),
            style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _message,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: tr('Descrivi il tuo feedback o il problema riscontrato…'),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            tr('Annulla'),
            style: const TextStyle(color: AppTheme.textGrey),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.send_outlined, size: 18),
          label: Text(tr('Invia')),
        ),
      ],
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AppTheme.textGrey,
      letterSpacing: 0.7,
    ),
  );
}

class _RoutePoint extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _RoutePoint({
    required this.icon,
    required this.color,
    required this.label,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    ],
  );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.accentBrown),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textGrey),
          ),
        ],
      ),
    );
  }
}
