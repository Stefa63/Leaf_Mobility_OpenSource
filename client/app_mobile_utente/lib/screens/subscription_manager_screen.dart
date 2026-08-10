import 'package:flutter/material.dart';
import 'package:app_mobile_utente/api/profilo_repository.dart';
import 'package:app_mobile_utente/theme.dart';
import 'package:app_mobile_utente/screens/buy_subscription_screen.dart';
import 'package:app_mobile_utente/l10n.dart';

/// @brief Gestione abbonamenti: stato reale + acquisto + storico (UT.18/UT.21).
///
/// Carica gli abbonamenti dell'utente da `GET /profilo/abbonamenti` e mostra
/// quello attivo (piano, scadenza, percentuale residua). In assenza di rete
/// degrada con un avviso (IIN-6). Il repository profilo è iniettabile nei test.
class SubscriptionManagerScreen extends StatefulWidget {
  /// @brief Crea la schermata; il repository profilo è iniettabile nei test.
  const SubscriptionManagerScreen({super.key, ProfiloApi? profilo})
    : _profilo = profilo;

  final ProfiloApi? _profilo;

  @override
  State<SubscriptionManagerScreen> createState() =>
      _SubscriptionManagerScreenState();
}

class _SubscriptionManagerScreenState
    extends State<SubscriptionManagerScreen> {
  late final ProfiloApi _profilo = widget._profilo ?? profiloRepository;

  bool _caricamento = true;
  bool _offline = false;
  List<Map<String, dynamic>> _abbonamenti = const [];

  @override
  void initState() {
    super.initState();
    _carica();
  }

  /// Carica gli abbonamenti dell'utente dal backend (UT.18/UT.21).
  Future<void> _carica() async {
    setState(() => _caricamento = true);
    try {
      final elenco = await _profilo.abbonamenti();
      if (!mounted) return;
      setState(() {
        _abbonamenti = elenco;
        _caricamento = false;
        _offline = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _caricamento = false;
        _offline = true;
      });
    }
  }

  /// Abbonamento attivo corrente, o il più recente, o null se nessuno.
  Map<String, dynamic>? get _attivo {
    for (final a in _abbonamenti) {
      if (a['stato'] == 'attivo') return a;
    }
    return _abbonamenti.isEmpty ? null : _abbonamenti.first;
  }

  /// Nome commerciale del piano dal catalogo client a partire dall'id.
  String _nomePiano(String? idPiano) {
    for (final p in kPianiAbbonamento) {
      if (p.idPiano == idPiano) return p.titolo;
    }
    return idPiano ?? '—';
  }

  /// Frazione residua [0..1] dell'abbonamento. Preferisce la quota a **token**
  /// (decrementata dagli utilizzi, punto 8): la percentuale cala a ogni corsa.
  /// Se l'abbonamento non porta i token, ripiega sulla durata temporale.
  double _frazioneResidua(Map<String, dynamic> abb) {
    final inclusi = (abb['token_inclusi'] as num?)?.toInt() ?? 0;
    if (inclusi > 0) {
      final residui = (abb['token_residui'] as num?)?.toInt() ?? 0;
      return (residui / inclusi).clamp(0.0, 1.0);
    }
    final inizio = DateTime.tryParse('${abb['data_inizio'] ?? ''}');
    final fine = DateTime.tryParse('${abb['data_fine'] ?? ''}');
    if (inizio == null || fine == null) return 0;
    final totale = fine.difference(inizio).inSeconds;
    if (totale <= 0) return 0;
    final residuo = fine.difference(DateTime.now()).inSeconds;
    return (residuo / totale).clamp(0.0, 1.0);
  }

  /// Etichetta dei token residui se l'abbonamento li prevede, altrimenti null.
  String? _tokenResiduiLabel(Map<String, dynamic> abb) {
    final inclusi = (abb['token_inclusi'] as num?)?.toInt() ?? 0;
    if (inclusi <= 0) return null;
    final residui = (abb['token_residui'] as num?)?.toInt() ?? 0;
    return '$residui / $inclusi ${tr('token')}';
  }

  /// Giorni residui (>= 0) dell'abbonamento dato.
  int _giorniResidui(Map<String, dynamic> abb) {
    final fine = DateTime.tryParse('${abb['data_fine'] ?? ''}');
    if (fine == null) return 0;
    final giorni = fine.difference(DateTime.now()).inDays;
    return giorni < 0 ? 0 : giorni;
  }

  /// Apre l'acquisto di un nuovo abbonamento e ricarica al ritorno.
  Future<void> _acquista() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const BuySubscriptionScreen()),
    );
    await _carica();
  }

  /// Mostra lo storico degli acquisti (tutti gli abbonamenti).
  void _mostraStorico() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.backgroundBeige,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Translated((context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Storico acquisti'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGreen,
                  ),
                ),
                const SizedBox(height: 12),
                if (_abbonamenti.isEmpty)
                  Text(
                    tr('Nessun acquisto registrato.'),
                    style: const TextStyle(color: AppTheme.textGrey),
                  )
                else
                  ..._abbonamenti.map(
                    (a) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.receipt_long_outlined,
                        color: AppTheme.accentBrown,
                      ),
                      title: Text(_nomePiano(a['id_piano'] as String?)),
                      subtitle: Text(
                        '${tr('Scade il')} ${_dataBreve(a['data_fine'])}',
                      ),
                      trailing: Text(
                        '${((a['prezzo_cent'] as num?) ?? 0) / 100} €',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkGreen,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Data ISO → `gg/mm/aaaa` (o '—' se non valida).
  String _dataBreve(Object? iso) {
    final d = DateTime.tryParse('$iso');
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundBeige,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  tr('Il tuo abbonamento'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGreen,
                  ),
                ),
                const SizedBox(height: 24),
                if (_caricamento)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  _buildStato(),
                const SizedBox(height: 32),
                Text(
                  tr('Opzioni'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGreen,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: const Icon(
                    Icons.add_shopping_cart,
                    color: AppTheme.primaryGreen,
                  ),
                  title: Text(tr('Acquista nuovo abbonamento')),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textGrey,
                  ),
                  onTap: _acquista,
                ),
                const SizedBox(height: 12),
                ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: const Icon(
                    Icons.history,
                    color: AppTheme.accentBrown,
                  ),
                  title: Text(tr('Storico acquisti')),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textGrey,
                  ),
                  onTap: _mostraStorico,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// Card di stato: abbonamento attivo, nessuno o avviso offline (IIN-6).
  Widget _buildStato() {
    if (_offline) {
      return _CardMessaggio(
        icona: Icons.cloud_off_outlined,
        testo: tr('Stato abbonamento non disponibile offline.'),
      );
    }
    final attivo = _attivo;
    if (attivo == null) {
      return _CardMessaggio(
        icona: Icons.card_membership_outlined,
        testo: tr('Nessun abbonamento attivo.'),
      );
    }
    final frazione = _frazioneResidua(attivo);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nomePiano(attivo['id_piano'] as String?),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    attivo['stato'] == 'attivo'
                        ? tr('Abbonamento attivo')
                        : tr('Abbonamento scaduto'),
                    style: const TextStyle(color: AppTheme.textGrey),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${tr('Scade il')} ${_dataBreve(attivo['data_fine'])}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.accentBrown,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(frazione * 100).round()}%',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: Colors.amber.shade700,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr('Rimanente'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_giorniResidui(attivo)} ${tr('giorni')}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.amber.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_tokenResiduiLabel(attivo) != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _tokenResiduiLabel(attivo)!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Card informativa con icona e messaggio (stato vuoto/offline).
class _CardMessaggio extends StatelessWidget {
  const _CardMessaggio({required this.icona, required this.testo});

  final IconData icona;
  final String testo;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Icon(icona, color: AppTheme.textGrey),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                testo,
                style: const TextStyle(color: AppTheme.textGrey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
