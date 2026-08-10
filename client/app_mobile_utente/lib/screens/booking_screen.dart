import 'package:flutter/material.dart';
import 'package:app_mobile_utente/api/api_client.dart';
import 'package:app_mobile_utente/api/corse_repository.dart';
import 'package:app_mobile_utente/theme.dart';
import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/booking_store.dart';
import 'package:app_mobile_utente/screens/vehicle_detail_screen.dart';
import 'package:app_mobile_utente/screens/my_bookings_screen.dart';

/// @brief Schermata di prenotazione di un mezzo. UT.02.
///
/// Consente di scegliere la durata della riserva, mostra il costo stimato in
/// base alla tariffa del veicolo e conferma la prenotazione. Quando il mezzo
/// porta un `docId` reale (proveniente dalla API), la prenotazione è inviata al
/// backend via [CorseApi.prenota]; in ogni caso viene registrata nello
/// [bookingStore] per la vista "Mie Prenotazioni". UT.03 (stima costo), UT.02.
class BookingScreen extends StatefulWidget {
  /// Veicolo da prenotare.
  final VehicleData vehicle;

  const BookingScreen({required this.vehicle, super.key, CorseApi? corse})
    : _corse = corse;

  /// Repository corse iniettabile (default reale; fittizio nei test).
  final CorseApi? _corse;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  /// Opzioni di durata della riserva (in minuti).
  static const List<int> _durations = [15, 30, 45, 60];

  /// Durata selezionata, in minuti.
  int _selectedMinutes = 15;

  /// Repository risolto: quello iniettato (test) o il singleton reale.
  late final CorseApi _corse = widget._corse ?? corseRepository;

  /// Prenotazione in corso verso il backend (disabilita il pulsante).
  bool _invio = false;

  /// Costo stimato reale dal backend (centesimi), o null se non disponibile.
  int? _costoStimatoCent;

  /// Stima dettagliata dal backend (sblocco/corsa/totale + stato abbonamento),
  /// o null in fallback locale/offline (punto 8).
  Map<String, dynamic>? _stima;

  @override
  void initState() {
    super.initState();
    _aggiornaStima();
  }

  /// Richiede al backend la stima reale del costo per la durata scelta (UT.03).
  ///
  /// Disponibile solo per i mezzi con `docId` reale; in assenza di rete o di
  /// `docId` la vista ricade sul calcolo locale per-tariffa (fallback, IIN-6).
  Future<void> _aggiornaStima() async {
    final docId = widget.vehicle.docId;
    if (docId == null || docId.isEmpty) return;
    final durata = _selectedMinutes;
    try {
      final esito = await _corse.stima(docId, durataMin: durata);
      if (!mounted || durata != _selectedMinutes) return;
      setState(() {
        _stima = esito;
        _costoStimatoCent = (esito['costo_stimato_cent'] as num?)?.toInt();
      });
    } on LeafApiException {
      if (!mounted) return;
      setState(() {
        _stima = null;
        _costoStimatoCent = null; // fallback alla stima locale
      });
    }
  }

  /// Tariffa al minuto del veicolo, in euro.
  double get _ratePerMinute {
    switch (widget.vehicle.type) {
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

  /// Costo stimato locale per la durata selezionata (fallback). UT.03.
  double get _estimatedCost => _ratePerMinute * _selectedMinutes;

  /// Costo da mostrare: stima reale del backend se disponibile, altrimenti locale.
  double get _costoVisuale =>
      _costoStimatoCent != null ? _costoStimatoCent! / 100.0 : _estimatedCost;

  /// Registra la prenotazione e apre l'elenco "Mie Prenotazioni". UT.02/UT.15.
  ///
  /// Per i mezzi con `docId` reale la prenotazione è inviata al backend con la
  /// durata scelta (blocco esclusivo + scadenza lato server): è quella la fonte
  /// di verità, perciò NON viene duplicata localmente. Per i mezzi di riserva
  /// offline (senza `docId`) si registra una prenotazione locale dimostrativa.
  Future<void> _confirm() async {
    if (_invio) return;
    final docId = widget.vehicle.docId;
    if (docId != null && docId.isNotEmpty) {
      setState(() => _invio = true);
      try {
        await _corse.prenota(docId, durataMin: _selectedMinutes);
      } on LeafApiException catch (e) {
        if (!mounted) return;
        setState(() => _invio = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.messaggio),
            backgroundColor: const Color(0xFFC62828),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }
    } else {
      // Mezzo di riserva offline (senza docId): prenotazione locale dimostrativa.
      addBooking(
        Booking(
          vehicleId: widget.vehicle.id,
          vehicleTypeLabel: widget.vehicle.typeLabel,
          vehicleType: widget.vehicle.type,
          createdAt: DateTime.now(),
          durationMinutes: _selectedMinutes,
          estimatedCost: _costoVisuale,
        ),
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('Prenotazione confermata')),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MyBookingsScreen(corse: _corse)),
    );
  }

  /// Contenitore del riquadro costo (sfondo coerente con le altre schermate).
  Widget _boxCosto(Widget child) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    decoration: BoxDecoration(
      color: AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(14),
    ),
    child: child,
  );

  /// Riga "etichetta — valore" del riquadro costo (forte = voce totale).
  Widget _rigaCosto(String label, String valore, {required bool forte}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: forte ? 15 : 13,
            fontWeight: forte ? FontWeight.bold : FontWeight.normal,
            color: forte ? AppTheme.darkGreen : AppTheme.textDark,
          ),
        ),
        Text(
          valore,
          style: TextStyle(
            fontSize: forte ? 18 : 14,
            fontWeight: forte ? FontWeight.bold : FontWeight.w600,
            color: forte ? AppTheme.darkGreen : AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  /// Riquadro costo (punto 8): con abbonamento mostra % usata + token (sblocco
  /// gratis, corsa coperta); senza abbonamento mostra sblocco + corsa + totale
  /// separati; in fallback offline la stima locale per-tariffa.
  Widget _buildCosto() {
    final stima = _stima;
    if (stima != null && stima['ha_abbonamento'] == true) {
      final inclusi = (stima['token_inclusi'] as num?)?.toInt() ?? 0;
      final residui = (stima['token_residui'] as num?)?.toInt() ?? 0;
      final pct = (stima['percentuale_usata'] as num?)?.toInt() ?? 0;
      return _boxCosto(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _rigaCosto(tr('Sblocco'), tr('Gratuito'), forte: false),
            const SizedBox(height: 6),
            _rigaCosto(tr('Corsa'), tr('Coperta da abbonamento'), forte: false),
            const Divider(height: 20),
            _rigaCosto(tr('Abbonamento utilizzato'), '$pct%', forte: true),
            const SizedBox(height: 4),
            Text(
              '${tr('Token residui')}: $residui / $inclusi',
              style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
            ),
          ],
        ),
      );
    }
    if (stima != null) {
      final sblocco = ((stima['sblocco_cent'] as num?)?.toInt() ?? 0) / 100.0;
      final corsa = ((stima['corsa_cent'] as num?)?.toInt() ?? 0) / 100.0;
      final totale = ((stima['totale_cent'] as num?)?.toInt() ?? 0) / 100.0;
      return _boxCosto(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _rigaCosto(
              tr('Sblocco'),
              '${sblocco.toStringAsFixed(2)} €',
              forte: false,
            ),
            const SizedBox(height: 6),
            _rigaCosto(
              '${tr('Corsa')} ($_selectedMinutes ${tr('min')})',
              '${corsa.toStringAsFixed(2)} €',
              forte: false,
            ),
            const Divider(height: 20),
            _rigaCosto(
              tr('Totale'),
              '${totale.toStringAsFixed(2)} €',
              forte: true,
            ),
          ],
        ),
      );
    }
    return _boxCosto(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${_ratePerMinute.toStringAsFixed(2)} ${tr('€/min')} × $_selectedMinutes ${tr('min')}',
              style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
            ),
          ),
          Text(
            '${_costoVisuale.toStringAsFixed(2)} €',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGreen,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.vehicle.typeColor;
    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        title: Text(tr('Prenota mezzo')),
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
            // ── Vehicle summary ──────────────────────────────────────────
            Card(
              elevation: 0,
              color: color.withAlpha(18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
                    Icon(widget.vehicle.typeIcon, size: 64, color: color),
                    const SizedBox(height: 10),
                    Text(
                      widget.vehicle.typeLabel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.vehicle.id,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textGrey,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Duration selection ───────────────────────────────────────
            _SectionLabel(tr('Durata prenotazione')),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _durations.map((m) {
                final selected = m == _selectedMinutes;
                return ChoiceChip(
                  label: Text('$m ${tr('min')}'),
                  selected: selected,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppTheme.textDark,
                  ),
                  backgroundColor: Colors.white,
                  selectedColor: AppTheme.primaryGreen,
                  side: BorderSide(
                    color: selected ? AppTheme.primaryGreen : Colors.black12,
                  ),
                  onSelected: (_) {
                    setState(() => _selectedMinutes = m);
                    _aggiornaStima();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Cost estimate (UT.03, punto 8) ───────────────────────────
            _SectionLabel(tr('Costo stimato')),
            const SizedBox(height: 10),
            _buildCosto(),
            const SizedBox(height: 8),
            Text(
              tr(
                'La prenotazione mantiene il mezzo riservato fino allo scadere del tempo.',
              ),
              style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
            ),
            const SizedBox(height: 32),

            // ── Confirm ──────────────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: _invio ? null : _confirm,
              icon: _invio
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(tr('Conferma prenotazione')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Etichetta di sezione in maiuscoletto, coerente con le altre schermate.
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
