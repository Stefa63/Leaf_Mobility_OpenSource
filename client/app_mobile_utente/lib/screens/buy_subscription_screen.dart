import 'package:flutter/material.dart';
import 'package:app_mobile_utente/api/api_client.dart';
import 'package:app_mobile_utente/api/profilo_repository.dart';
import 'package:app_mobile_utente/theme.dart';
import 'package:app_mobile_utente/l10n.dart';

/// @brief Descrittore di un piano di abbonamento mostrato all'utente (UT.18).
///
/// L'`idPiano` corrisponde all'identificativo reale del piano sul backend
/// (`piani_abbonamento`): è il valore inviato a `POST /profilo/abbonamenti`.
/// Il catalogo è definito lato client in attesa di un endpoint `GET /piani`
/// (integration backlog §17).
class PianoAbbonamento {
  /// @brief Crea il descrittore di un piano.
  const PianoAbbonamento({
    required this.idPiano,
    required this.titolo,
    required this.prezzo,
    required this.durata,
    required this.caratteristiche,
    required this.colore,
    this.isPremium = false,
  });

  /// Identificativo del piano sul backend (es. `piano-base`).
  final String idPiano;

  /// Nome commerciale del piano.
  final String titolo;

  /// Prezzo formattato per la UI (es. `9,99 €`).
  final String prezzo;

  /// Durata leggibile del piano (es. `30 giorni`).
  final String durata;

  /// Vantaggi inclusi nel piano.
  final List<String> caratteristiche;

  /// Colore di accento della card.
  final Color colore;

  /// Indica il piano in evidenza (bordo/elevazione enfatizzati).
  final bool isPremium;
}

/// @brief Catalogo dei piani allineato agli id reali del seed backend (UT.18).
const List<PianoAbbonamento> kPianiAbbonamento = [
  PianoAbbonamento(
    idPiano: 'piano-base',
    titolo: 'LEAF Base',
    prezzo: '9,99 €',
    durata: '30 giorni',
    caratteristiche: [
      'Sblocchi illimitati',
      '120 min inclusi',
      'Tutti i veicoli',
    ],
    colore: AppTheme.primaryGreen,
  ),
  PianoAbbonamento(
    idPiano: 'piano-plus',
    titolo: 'LEAF Plus',
    prezzo: '19,99 €',
    durata: '30 giorni',
    caratteristiche: [
      'Sblocchi illimitati',
      '500 min inclusi',
      'Tutti i veicoli',
    ],
    colore: AppTheme.accentBrown,
  ),
  PianoAbbonamento(
    idPiano: 'piano-annuale',
    titolo: 'LEAF Annuale',
    prezzo: '149,00 €',
    durata: '365 giorni',
    caratteristiche: [
      'Sblocchi illimitati',
      'Minuti illimitati',
      'Supporto prioritario',
    ],
    colore: Color(0xFFB8860B),
    isPremium: true,
  ),
];

/// @brief Schermata di acquisto abbonamento: sottoscrive un piano reale (UT.18).
///
/// Mostra il catalogo [kPianiAbbonamento] e invia la sottoscrizione al backend
/// (`POST /profilo/abbonamenti`) tramite [ProfiloApi], iniettabile nei test.
class BuySubscriptionScreen extends StatefulWidget {
  /// @brief Crea la schermata; il repository profilo è iniettabile nei test.
  const BuySubscriptionScreen({super.key, ProfiloApi? profilo})
    : _profilo = profilo;

  final ProfiloApi? _profilo;

  @override
  State<BuySubscriptionScreen> createState() => _BuySubscriptionScreenState();
}

class _BuySubscriptionScreenState extends State<BuySubscriptionScreen> {
  late final ProfiloApi _profilo = widget._profilo ?? profiloRepository;

  /// Id del piano la cui sottoscrizione è in corso (null se nessuna).
  String? _inCorso;

  /// Sottoscrive il piano selezionato sul backend (UT.18).
  Future<void> _sottoscrivi(PianoAbbonamento piano) async {
    if (_inCorso != null) return;
    setState(() => _inCorso = piano.idPiano);
    try {
      await _profilo.sottoscriviAbbonamento(piano.idPiano);
      if (!mounted) return;
      _mostra(
        '${tr('Abbonamento attivato:')} ${piano.titolo}',
        AppTheme.primaryGreen,
      );
      Navigator.pop(context, true);
    } on LeafApiException catch (e) {
      if (!mounted) return;
      _mostra(e.messaggio, const Color(0xFFC62828));
    } finally {
      if (mounted) setState(() => _inCorso = null);
    }
  }

  /// Mostra un riscontro all'utente tramite SnackBar.
  void _mostra(String messaggio, Color colore) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(messaggio), backgroundColor: colore),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        title: Text(
          tr('Acquista Abbonamento'),
          style: const TextStyle(color: AppTheme.darkGreen),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr('Scegli il piano adatto a te'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGreen,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              for (final piano in kPianiAbbonamento) ...[
                _buildPlanCard(context, piano),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, PianoAbbonamento piano) {
    final bool caricamento = _inCorso == piano.idPiano;
    final bool disabilitato = _inCorso != null;
    return Card(
      elevation: piano.isPremium ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: piano.isPremium
            ? const BorderSide(color: Colors.amber, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  piano.titolo,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: piano.colore,
                  ),
                ),
                if (piano.isPremium) const Icon(Icons.star, color: Colors.amber),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  piano.prezzo,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '/ ${tr(piano.durata)}',
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...piano.caratteristiche.map(
              (f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 18,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(tr(f), style: const TextStyle(color: AppTheme.textDark)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: piano.colore,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: disabilitato ? null : () => _sottoscrivi(piano),
                child: caricamento
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        tr('Seleziona Piano'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
