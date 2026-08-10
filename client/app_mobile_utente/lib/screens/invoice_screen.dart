import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/profile_store.dart';
import 'package:app_mobile_utente/screens/history_screen.dart';
import 'package:app_mobile_utente/screens/invoice_pdf.dart';
import 'package:app_mobile_utente/theme.dart';

/// @brief Fattura digitale stampabile di una corsa conclusa. UT.25.
///
/// Rende una copia digitale della fattura a partire dai dati reali della corsa
/// ([TripEntry] caricato dal backend) con lo **scorporo IVA** (aliquota 22%,
/// coerente con `gestore_corse._emetti_fattura` lato server). Il documento è
/// formattato come una ricevuta stampabile/screenshottabile; la generazione del
/// PDF nativo e la condivisione di sistema richiederebbero un pacchetto dedicato
/// (`printing`/`share_plus`) e sono lasciate a un'evoluzione successiva.
class InvoiceScreen extends StatelessWidget {
  /// @brief Crea la fattura per la corsa data.
  /// @param trip Corsa conclusa di cui emettere la copia digitale.
  const InvoiceScreen({required this.trip, super.key});

  /// Corsa di cui si mostra la fattura.
  final TripEntry trip;

  /// Aliquota IVA per lo scorporo (22%), allineata al Business Tier.
  static const double _aliquotaIva = 0.22;

  /// Imponibile scorporato dal totale lordo della corsa.
  double get _imponibile => trip.cost / (1 + _aliquotaIva);

  /// Quota IVA (totale lordo − imponibile).
  double get _iva => trip.cost - _imponibile;

  /// Apre il dialogo di stampa/condivisione nativo con il PDF della fattura.
  ///
  /// `Printing.layoutPdf` mostra l'anteprima e le opzioni di sistema (stampa,
  /// "Salva come PDF", condividi). Il PDF è generato da [buildInvoicePdf].
  Future<void> _stampaPdf() {
    return Printing.layoutPdf(
      name: 'Fattura_${trip.id}',
      onLayout: (format) => buildInvoicePdf(
        trip: trip,
        cliente:
            '${ProfileStore.firstName.value} ${ProfileStore.lastName.value}',
        format: format,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundBeige,
        appBar: AppBar(
          title: Text(
            tr('Fattura'),
            style: const TextStyle(color: AppTheme.darkGreen),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              tooltip: tr('Stampa o salva PDF'),
              icon: const Icon(Icons.print_outlined, color: AppTheme.darkGreen),
              onPressed: _stampaPdf,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Intestazione emittente.
                  Row(
                    children: [
                      const Icon(Icons.eco, color: AppTheme.primaryGreen),
                      const SizedBox(width: 8),
                      const Text(
                        'LEAF Mobility',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkGreen,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        tr('Fattura'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),

                  // Estremi del documento.
                  _Riga(tr('Numero'), 'FT-${trip.id}'),
                  _Riga(tr('Data'), '${trip.date} · ${trip.time}'),
                  _Riga(
                    tr('Cliente'),
                    '${ProfileStore.firstName.value} ${ProfileStore.lastName.value}',
                  ),
                  const SizedBox(height: 16),
                  _SezioneLabel(tr('Dettaglio corsa')),
                  const SizedBox(height: 8),
                  _Riga(tr('Veicolo'), trip.vehicleType),
                  _Riga(tr('Tragitto'), '${trip.from} → ${trip.to}'),
                  _Riga(tr('Durata'), '${trip.durationMinutes} ${tr('min')}'),
                  _Riga(
                    tr('Distanza'),
                    '${trip.distanceKm.toStringAsFixed(1)} km',
                  ),
                  const Divider(height: 28),

                  // Importi con scorporo IVA.
                  _RigaImporto(tr('Imponibile'), _imponibile),
                  _RigaImporto('${tr('IVA')} (22%)', _iva),
                  const SizedBox(height: 8),
                  _RigaImporto(tr('Totale'), trip.cost, totale: true),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      tr('Copia digitale — documento generato dall\'app.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _stampaPdf,
              icon: const Icon(Icons.print_outlined),
              label: Text(tr('Stampa o salva PDF')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// Riga chiave→valore di un estremo della fattura.
class _Riga extends StatelessWidget {
  const _Riga(this.etichetta, this.valore);

  final String etichetta;
  final String valore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              etichetta,
              style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
            ),
          ),
          Expanded(
            child: Text(
              valore,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Riga di un importo in euro; in grassetto evidenziato per il totale.
class _RigaImporto extends StatelessWidget {
  const _RigaImporto(this.etichetta, this.valore, {this.totale = false});

  final String etichetta;
  final double valore;
  final bool totale;

  @override
  Widget build(BuildContext context) {
    final stile = TextStyle(
      fontSize: totale ? 18 : 14,
      fontWeight: totale ? FontWeight.w800 : FontWeight.w500,
      color: totale ? AppTheme.darkGreen : AppTheme.textDark,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etichetta, style: stile),
          Text('${valore.toStringAsFixed(2)} €', style: stile),
        ],
      ),
    );
  }
}

/// Etichetta di sezione in maiuscoletto, coerente con le altre schermate.
class _SezioneLabel extends StatelessWidget {
  const _SezioneLabel(this.text);

  final String text;

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
