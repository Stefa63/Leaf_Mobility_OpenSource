import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:app_mobile_utente/api/api_client.dart';
import 'package:app_mobile_utente/api/profilo_repository.dart';
import 'package:app_mobile_utente/theme.dart';
import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/profile_store.dart';

/// @brief Schermata dei dati sensibili dell'utente. UT.11, UT.22.2.
///
/// Permette di visualizzare e modificare:
///   1. i documenti ufficiali (carta d'identita', patente) — caricamento KYC
///      di immagini JPG/PNG oppure di un PDF generato dalla foto del documento,
///      da galleria o fotocamera (IIN-6);
///   2. il metodo di pagamento registrato (UT.11).
///
/// Tutti i dati restano **locali** sul dispositivo ([ProfileStore]); la
/// cifratura at-rest (AES-256) e la verifica KYC saranno a carico del Business
/// Tier (`gestore_profili_ekyc`, `gateway_pagamenti`). I numeri di carta sono
/// sempre mostrati mascherati.
class SensitiveDataScreen extends StatefulWidget {
  /// @brief Crea la schermata; il repository profilo è iniettabile nei test.
  const SensitiveDataScreen({super.key, ProfiloApi? profilo})
    : _profilo = profilo;

  final ProfiloApi? _profilo;

  @override
  State<SensitiveDataScreen> createState() => _SensitiveDataScreenState();
}

class _SensitiveDataScreenState extends State<SensitiveDataScreen> {
  late final TextEditingController _holder;
  late final TextEditingController _number;
  late final TextEditingController _expiry;
  late final TextEditingController _cvv;
  late final TextEditingController _billing;

  late final ProfiloApi _profilo = widget._profilo ?? profiloRepository;

  /// Indica se il metodo di pagamento e' in modifica.
  bool _editingPayment = false;

  /// Registrazione del metodo di pagamento al backend in corso.
  bool _savingPayment = false;

  @override
  void initState() {
    super.initState();
    _holder = TextEditingController(text: ProfileStore.cardHolder.value);
    _number = TextEditingController(text: ProfileStore.cardNumber.value);
    _expiry = TextEditingController(text: ProfileStore.cardExpiry.value);
    _cvv = TextEditingController();
    // Indirizzo di fatturazione precompilato con la residenza del profilo: deve
    // coincidere (verifica server-side, punto 4/5).
    _billing = TextEditingController(text: ProfileStore.address.value);
  }

  @override
  void dispose() {
    _holder.dispose();
    _number.dispose();
    _expiry.dispose();
    _cvv.dispose();
    _billing.dispose();
    super.dispose();
  }

  /// Verifica un numero di carta con l'algoritmo di Luhn (checksum, punto 4).
  /// @param cifre Numero carta come sole cifre.
  /// @return True se il checksum di Luhn è valido.
  bool _luhnValido(String cifre) {
    if (cifre.length < 13) return false;
    var somma = 0;
    var raddoppia = false;
    for (var i = cifre.length - 1; i >= 0; i--) {
      var n = int.parse(cifre[i]);
      if (raddoppia) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      somma += n;
      raddoppia = !raddoppia;
    }
    return somma % 10 == 0;
  }

  /// Maschera un numero di carta lasciando in chiaro solo le ultime 4 cifre.
  String _maskCard(String raw) {
    final digits = raw.replaceAll(RegExp(r'\s'), '');
    if (digits.length < 4) return digits;
    final last4 = digits.substring(digits.length - 4);
    return '•••• •••• •••• $last4';
  }

  /// Carica/aggiorna un documento KYC: immagine o PDF (IIN-6, UT.22.2).
  ///
  /// Offre tre modalità: immagine (JPG/PNG) da galleria o fotocamera, oppure
  /// selezione di un documento **già in PDF dal file manager** del dispositivo
  /// (non dalla galleria). Dopo la copia locale del file (resta sul dispositivo),
  /// notifica al backend il caricamento KYC inviando tipo e nome del file:
  /// l'estensione è rivalidata server-side (AG-SEC-01). Il `tipo` deve essere
  /// `patente` o `carta_identita`.
  Future<void> _uploadDocument({
    required String basename,
    required String tipo,
    required Future<void> Function(String?) onStored,
  }) async {
    final scelta = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.backgroundBeige,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppTheme.primaryGreen,
              ),
              title: Text(tr('Immagine dalla galleria')),
              onTap: () => Navigator.pop(context, 'img_gallery'),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: AppTheme.primaryGreen,
              ),
              title: Text(tr('Scatta una foto')),
              onTap: () => Navigator.pop(context, 'img_camera'),
            ),
            ListTile(
              leading: const Icon(
                Icons.picture_as_pdf_outlined,
                color: AppTheme.accentBrown,
              ),
              title: Text(tr('PDF dal file manager')),
              onTap: () => Navigator.pop(context, 'pdf_file'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!mounted || scelta == null) return;

    // PDF reale scelto dal file manager del dispositivo (UT.22.2).
    if (scelta == 'pdf_file') {
      final pdf = await _scegliPdfDaFile(basename);
      if (!mounted || pdf == null) return;
      await onStored(pdf.path);
      await _inviaKyc(tipo, pdf.uri.pathSegments.last);
      return;
    }

    // Immagine (JPG/PNG) da galleria o fotocamera.
    final result = await pickAndStoreImage(
      source: scelta == 'img_camera' ? ImageSource.camera : ImageSource.gallery,
      basename: basename,
    );
    if (!mounted) return;
    if (result.permissionDenied) {
      _showSnack(tr('Permesso negato. Abilitalo nelle impostazioni.'));
      return;
    }
    final file = result.file;
    if (file == null) return;
    await onStored(file.path);
    await _inviaKyc(tipo, file.uri.pathSegments.last);
  }

  /// Seleziona un documento già in formato PDF dal file manager e lo copia nella
  /// sandbox dell'app (UT.22.2). Filtra l'estensione a `.pdf` lato selettore;
  /// l'estensione è comunque rivalidata server-side (AG-SEC-01).
  /// @param basename Nome-base del file PDF di destinazione nella sandbox.
  /// @return Il file PDF copiato in sandbox, o null se l'utente annulla.
  Future<File?> _scegliPdfDaFile(String basename) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    final sorgente = result?.files.single.path;
    if (sorgente == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final dest = File('${dir.path}/$basename.pdf');
    await dest.writeAsBytes(await File(sorgente).readAsBytes());
    return dest;
  }

  /// Notifica al backend il caricamento di un documento KYC (UT.22.2).
  ///
  /// Tollerante all'assenza di rete (IIN-6): in caso di errore il file resta
  /// salvato localmente e all'utente viene mostrato il messaggio di dominio.
  Future<void> _inviaKyc(String tipo, String nomeFile) async {
    try {
      final dati = await _profilo.caricaKyc(tipo: tipo, nomeFile: nomeFile);
      if (!mounted) return;
      final stato = dati['stato_verifica']?.toString() ?? tr('in verifica');
      _showSnack('${tr('Documento inviato')} · $stato');
    } on LeafApiException catch (e) {
      if (!mounted) return;
      _showSnack(e.messaggio);
    }
  }

  /// Apre l'anteprima del documento: per i PDF usa il dialogo di sistema
  /// (riuso del pacchetto `printing`); per le immagini un viewer a schermo intero.
  void _viewDocument(String title, String path) {
    if (path.toLowerCase().endsWith('.pdf')) {
      Printing.layoutPdf(name: title, onLayout: (_) => File(path).readAsBytes());
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(title, style: const TextStyle(color: Colors.white)),
          ),
          body: Center(child: InteractiveViewer(child: Image.file(File(path)))),
        ),
      ),
    );
  }

  /// Registra il metodo di pagamento (UT.11).
  ///
  /// Invia la carta al backend per la verifica (`POST /profilo/pagamenti`); il
  /// PAN **non viene mai persistito in chiaro sul client**: localmente si salva
  /// solo il numero mascherato (quello restituito dal server o, in assenza di
  /// rete, mascherato localmente — IIN-6). In caso di errore di dominio il PAN
  /// non viene persistito e si resta in modifica.
  Future<void> _savePayment() async {
    if (_savingPayment) return;
    FocusScope.of(context).unfocus();
    final holder = _holder.text.trim();
    final expiry = _expiry.text.trim();
    final digits = _number.text.replaceAll(RegExp(r'\D'), '');
    final cvv = _cvv.text.replaceAll(RegExp(r'\D'), '');
    final billing = _billing.text.trim();
    final scadenza = _parseExpiry(expiry);

    // Validazione client stretta (punto 4): lunghezza+Luhn, scadenza futura,
    // CVV a 3 cifre, indirizzo di fatturazione presente. Niente salvataggio
    // parziale: la carta si registra solo se completa e valida.
    if (holder.isEmpty) {
      _showSnack(tr('Inserisci l\'intestatario della carta.'));
      return;
    }
    if (digits.length < 13 || digits.length > 19 || !_luhnValido(digits)) {
      _showSnack(tr('Numero carta non valido.'));
      return;
    }
    if (scadenza == null) {
      _showSnack(tr('Scadenza non valida (usa MM/AA).'));
      return;
    }
    if (!_scadenzaFutura(scadenza)) {
      _showSnack(tr('La carta è scaduta.'));
      return;
    }
    if (cvv.length != 3) {
      _showSnack(tr('Il codice di sicurezza deve avere 3 cifre.'));
      return;
    }
    if (billing.isEmpty) {
      _showSnack(tr('Inserisci l\'indirizzo di fatturazione.'));
      return;
    }

    setState(() => _savingPayment = true);
    try {
      final dati = await _profilo.registraPagamento(
        numero: digits,
        mese: scadenza.$1,
        anno: scadenza.$2,
        titolare: holder,
        cvv: cvv,
        indirizzoFatturazione: billing,
      );
      final mascherato = dati['pan_mascherato']?.toString() ?? _maskCard(digits);
      await ProfileStore.savePaymentMethod(
        holder: holder,
        number: mascherato,
        expiry: expiry,
      );
      if (!mounted) return;
      setState(() {
        _editingPayment = false;
        _savingPayment = false;
      });
      _showSnack(tr('Metodo di pagamento registrato'));
    } on LeafApiException catch (e) {
      if (!mounted) return;
      setState(() => _savingPayment = false);
      _showSnack(e.messaggio);
    }
  }

  /// Indica se la scadenza (mese, anno) è nel presente o nel futuro (punto 4).
  bool _scadenzaFutura((int, int) scadenza) {
    final ora = DateTime.now();
    final (mese, anno) = scadenza;
    // Valida fino all'ultimo giorno del mese di scadenza.
    final fineMese = DateTime(anno, mese + 1, 0, 23, 59, 59);
    return fineMese.isAfter(ora);
  }

  /// Converte una scadenza `MM/AA` in `(mese, anno)` a quattro cifre, o null.
  (int, int)? _parseExpiry(String raw) {
    final match = RegExp(r'^(\d{1,2})\s*/\s*(\d{2})$').firstMatch(raw.trim());
    if (match == null) return null;
    final mese = int.parse(match.group(1)!);
    final anno = 2000 + int.parse(match.group(2)!);
    if (mese < 1 || mese > 12) return null;
    return (mese, anno);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            tr('Dati sensibili'),
            style: const TextStyle(color: AppTheme.darkGreen),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Documenti importanti (UT.22.2) ──────────────────────────
            _SectionLabel(tr('Documenti importanti')),
            const SizedBox(height: 6),
            Text(
              tr('Formati accettati: PDF, JPG, PNG.'),
              style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<String?>(
              valueListenable: ProfileStore.idCardPath,
              builder: (context, path, _) => _DocumentCard(
                icon: Icons.badge_outlined,
                title: tr("Carta d'identità"),
                path: path,
                onUpload: () => _uploadDocument(
                  basename: 'kyc_id_card',
                  tipo: 'carta_identita',
                  onStored: ProfileStore.setIdCardPath,
                ),
                onView: path == null
                    ? null
                    : () => _viewDocument(tr("Carta d'identità"), path),
                onRemove: path == null
                    ? null
                    : () => ProfileStore.setIdCardPath(null),
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<String?>(
              valueListenable: ProfileStore.licensePath,
              builder: (context, path, _) => _DocumentCard(
                icon: Icons.directions_car_outlined,
                title: tr('Patente'),
                path: path,
                onUpload: () => _uploadDocument(
                  basename: 'kyc_license',
                  tipo: 'patente',
                  onStored: ProfileStore.setLicensePath,
                ),
                onView: path == null
                    ? null
                    : () => _viewDocument(tr('Patente'), path),
                onRemove: path == null
                    ? null
                    : () => ProfileStore.setLicensePath(null),
              ),
            ),
            const SizedBox(height: 28),

            // ── Metodo di pagamento (UT.11) ─────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionLabel(tr('Metodo di pagamento')),
                IconButton(
                  tooltip: _editingPayment
                      ? tr('Blocca campo')
                      : tr('Modifica campo'),
                  icon: _savingPayment
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryGreen,
                          ),
                        )
                      : Icon(
                          _editingPayment ? Icons.check : Icons.edit_outlined,
                          color: AppTheme.primaryGreen,
                        ),
                  onPressed: _savingPayment
                      ? null
                      : () {
                          if (_editingPayment) {
                            _savePayment();
                          } else {
                            // Non riproporre il PAN mascherato salvato: si
                            // riparte da un campo numero vuoto (UT.11).
                            _number.clear();
                            setState(() => _editingPayment = true);
                          }
                        },
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_editingPayment)
              _buildPaymentForm()
            else
              _buildPaymentSummary(),
          ],
        ),
      );
    });
  }

  /// Riepilogo del metodo di pagamento salvato (numero mascherato). UT.11.
  Widget _buildPaymentSummary() {
    return ValueListenableBuilder<String>(
      valueListenable: ProfileStore.cardNumber,
      builder: (context, number, _) {
        final hasCard = number.trim().isNotEmpty;
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: hasCard
              ? Row(
                  children: [
                    const Icon(
                      Icons.credit_card,
                      color: AppTheme.accentBrown,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _maskCard(number),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${ProfileStore.cardHolder.value}  ·  ${tr('Scadenza')} ${ProfileStore.cardExpiry.value}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    const Icon(
                      Icons.credit_card_off_outlined,
                      color: AppTheme.textGrey,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        tr('Nessun metodo di pagamento registrato.'),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  /// Modulo di inserimento/modifica del metodo di pagamento. UT.11.
  Widget _buildPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _holder,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: tr('Intestatario'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _number,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
          ],
          decoration: InputDecoration(
            labelText: tr('Numero carta'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _expiry,
                keyboardType: TextInputType.datetime,
                inputFormatters: [LengthLimitingTextInputFormatter(5)],
                decoration: InputDecoration(
                  labelText: tr('Scadenza (MM/AA)'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                controller: _cvv,
                keyboardType: TextInputType.number,
                obscureText: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: InputDecoration(
                  labelText: tr('CVV'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _billing,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: tr('Indirizzo di fatturazione'),
            helperText: tr('Deve coincidere con la residenza del profilo.'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _savePayment,
          child: Text(tr('Salva Modifiche')),
        ),
      ],
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

/// Card di un documento KYC: anteprima/stato + azioni carica/vedi/rimuovi.
class _DocumentCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? path;
  final VoidCallback onUpload;
  final VoidCallback? onView;
  final VoidCallback? onRemove;

  const _DocumentCard({
    required this.icon,
    required this.title,
    required this.path,
    required this.onUpload,
    required this.onView,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final loaded = path != null && File(path!).existsSync();
    final isPdf = path != null && path!.toLowerCase().endsWith('.pdf');
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          // Anteprima o icona segnaposto.
          GestureDetector(
            onTap: loaded ? onView : null,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withAlpha(28),
                borderRadius: BorderRadius.circular(10),
                image: loaded && !isPdf
                    ? DecorationImage(
                        image: FileImage(File(path!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: loaded && !isPdf
                  ? null
                  : Icon(
                      isPdf ? Icons.picture_as_pdf : icon,
                      color: AppTheme.primaryGreen,
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  loaded ? tr('Caricato') : tr('Non caricato'),
                  style: TextStyle(
                    fontSize: 12,
                    color: loaded ? AppTheme.primaryGreen : AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
          // Azioni.
          if (loaded && onRemove != null)
            IconButton(
              tooltip: tr('Rimuovi'),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onRemove,
            ),
          IconButton(
            tooltip: loaded ? tr('Sostituisci') : tr('Carica'),
            icon: Icon(
              loaded ? Icons.refresh : Icons.upload_file_outlined,
              color: AppTheme.primaryGreen,
            ),
            onPressed: onUpload,
          ),
        ],
      ),
    );
  }
}
