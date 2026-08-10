import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:app_mobile_utente/screens/history_screen.dart';

/// Aliquota IVA per lo scorporo (22%), allineata al Business Tier.
const double _aliquotaIva = 0.22;

/// @brief Costruisce il PDF della fattura di una corsa (UT.25).
///
/// Genera un documento stampabile/condivisibile dai dati reali della corsa con
/// lo **scorporo IVA** (22%, coerente con `gestore_corse._emetti_fattura`). È
/// puro Dart (nessun canale di piattaforma): usato sia per il dialogo di stampa
/// nativo (`Printing.layoutPdf`) sia nei test. Gli importi usano la sigla `EUR`
/// (garantita dai font standard del PDF) anziché il simbolo €.
///
/// @param trip Corsa conclusa di cui emettere la fattura.
/// @param cliente Nome completo dell'intestatario.
/// @param format Formato pagina richiesto (default A4).
/// @return I byte del PDF generato.
Future<Uint8List> buildInvoicePdf({
  required TripEntry trip,
  required String cliente,
  PdfPageFormat format = PdfPageFormat.a4,
}) async {
  final imponibile = trip.cost / (1 + _aliquotaIva);
  final iva = trip.cost - imponibile;
  final doc = pw.Document();

  doc.addPage(
    pw.Page(
      pageFormat: format,
      build: (context) => pw.Padding(
        padding: const pw.EdgeInsets.all(28),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'LEAF Mobility',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800,
                  ),
                ),
                pw.Text(
                  'FATTURA',
                  style: const pw.TextStyle(
                    fontSize: 13,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Divider(),
            pw.SizedBox(height: 8),
            _riga('Numero', 'FT-${trip.id}'),
            _riga('Data', '${trip.date}  ${trip.time}'),
            _riga('Cliente', cliente),
            pw.SizedBox(height: 16),
            pw.Text(
              'DETTAGLIO CORSA',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 6),
            _riga('Veicolo', trip.vehicleType),
            _riga('Tragitto', '${trip.from} -> ${trip.to}'),
            _riga('Durata', '${trip.durationMinutes} min'),
            _riga('Distanza', '${trip.distanceKm.toStringAsFixed(1)} km'),
            pw.SizedBox(height: 16),
            pw.Divider(),
            _importo('Imponibile', imponibile),
            _importo('IVA (22%)', iva),
            pw.SizedBox(height: 4),
            _importo('Totale', trip.cost, totale: true),
            pw.Spacer(),
            pw.Center(
              child: pw.Text(
                'Copia digitale - documento generato dall\'app.',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  return doc.save();
}

/// Riga chiave→valore di un estremo della fattura nel PDF.
pw.Widget _riga(String etichetta, String valore) => pw.Padding(
  padding: const pw.EdgeInsets.symmetric(vertical: 3),
  child: pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(
        width: 96,
        child: pw.Text(
          etichetta,
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
        ),
      ),
      pw.Expanded(
        child: pw.Text(
          valore,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
      ),
    ],
  ),
);

/// Riga di un importo (in EUR); in grassetto per il totale.
pw.Widget _importo(String etichetta, double valore, {bool totale = false}) {
  final stile = pw.TextStyle(
    fontSize: totale ? 15 : 11,
    fontWeight: totale ? pw.FontWeight.bold : pw.FontWeight.normal,
  );
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(etichetta, style: stile),
        pw.Text('${valore.toStringAsFixed(2)} EUR', style: stile),
      ],
    ),
  );
}
