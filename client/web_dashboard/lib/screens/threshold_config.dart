import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/api_config.dart';
import 'package:web_dashboard/api/areas_repository.dart';
import 'package:web_dashboard/api/fleet_repository.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/theme.dart';
import 'package:web_dashboard/widgets/common.dart';

/// @brief Schermata "Config Soglie" dell'Operatore (OP.02 + OP.22).
///
/// Due form di configurazione delle soglie di allerta della flotta:
/// la **soglia minima di mezzi per area** (OP.02, `POST /soglie/area`) e la
/// **soglia di allerta batteria** (OP.22, `POST /soglie/batteria`). L'elenco
/// delle aree per il primo form arriva da `/api/v1/aree`; in assenza di rete
/// (IIN-6) il form area resta inattivo con avviso, quello batteria è sempre
/// utilizzabile. Le allerte risultanti compaiono nella coda del Centro Operativo.
class ThresholdConfig extends StatefulWidget {
  const ThresholdConfig({
    super.key,
    this.autoload = true,
    this.fleetRepo,
    this.areeRepo,
  });

  /// @brief Se true (default), carica le aree reali all'apertura; i test lo disattivano.
  final bool autoload;

  /// @brief Repository flotta iniettabile (default singleton reale; fake nei test).
  final FlottaApi? fleetRepo;

  /// @brief Repository aree iniettabile (default singleton reale; fake nei test).
  final AreeApi? areeRepo;

  @override
  State<ThresholdConfig> createState() => _ThresholdConfigState();
}

class _ThresholdConfigState extends State<ThresholdConfig> {
  late final FlottaApi _flotta = widget.fleetRepo ?? fleetRepository;
  late final AreeApi _aree = widget.areeRepo ?? areasRepository;

  /// Tipi di mezzo selezionabili per la soglia batteria (allineati a TIPI_MEZZO_AMMESSI).
  static const List<({String valore, String etichetta})> _tipiMezzo = [
    (valore: '', etichetta: 'Tutti i mezzi'),
    (valore: 'ebike', etichetta: 'E-bike'),
    (valore: 'monopattino', etichetta: 'Monopattino'),
    (valore: 'ecar', etichetta: 'Auto elettrica'),
    (valore: 'emotorbike', etichetta: 'Moto elettrica'),
  ];

  List<Map<String, dynamic>> _listaAree = const [];
  String? _idAreaSelezionata;
  String _tipoBatteria = '';

  final TextEditingController _minimoArea = TextEditingController();
  final TextEditingController _percentualeBatteria =
      TextEditingController(text: '20');

  bool _caricamentoAree = true;
  bool _offlineAree = false;
  bool _salvataggioArea = false;
  bool _salvataggioBatteria = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoload && kAutoloadData) {
      _caricaAree();
    } else {
      _caricamentoAree = false;
    }
  }

  @override
  void dispose() {
    _minimoArea.dispose();
    _percentualeBatteria.dispose();
    super.dispose();
  }

  /// Carica le aree attive per il selettore della soglia area (OP.02).
  Future<void> _caricaAree() async {
    setState(() => _caricamentoAree = true);
    try {
      final aree = await _aree.elenco(soloAttive: true);
      if (!mounted) return;
      setState(() {
        _listaAree = aree;
        _offlineAree = false;
        _caricamentoAree = false;
      });
    } on LeafApiException {
      if (!mounted) return;
      setState(() {
        _offlineAree = true;
        _caricamentoAree = false;
      });
    }
  }

  String _nomeArea(Map<String, dynamic> a) =>
      '${a['nome'] ?? a['_id'] ?? tr('Area')}';

  String _idArea(Map<String, dynamic> a) => '${a['_id'] ?? ''}';

  void _avviso(String messaggio, {bool errore = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: errore ? AppTheme.statusLowBattery : AppTheme.opAccent,
        content: Text(messaggio),
      ),
    );
  }

  /// Salva la soglia minima di mezzi per l'area selezionata (OP.02).
  Future<void> _salvaSogliaArea() async {
    final idArea = _idAreaSelezionata;
    final minimo = int.tryParse(_minimoArea.text.trim());
    if (idArea == null || idArea.isEmpty) {
      _avviso(tr('Seleziona un\'area'), errore: true);
      return;
    }
    if (minimo == null || minimo < 0) {
      _avviso(tr('Inserisci un numero minimo valido'), errore: true);
      return;
    }
    setState(() => _salvataggioArea = true);
    try {
      await _flotta.impostaSogliaArea(idArea: idArea, minimo: minimo);
      _avviso(tr('Soglia area salvata'));
    } on LeafApiException catch (e) {
      _avviso('${tr('Errore salvataggio')}: ${e.messaggio}', errore: true);
    } finally {
      if (mounted) setState(() => _salvataggioArea = false);
    }
  }

  /// Salva la soglia di allerta batteria, eventualmente per tipo di mezzo (OP.22).
  Future<void> _salvaSogliaBatteria() async {
    final pct = int.tryParse(_percentualeBatteria.text.trim());
    if (pct == null || pct < 1 || pct > 100) {
      _avviso(tr('Inserisci una percentuale tra 1 e 100'), errore: true);
      return;
    }
    setState(() => _salvataggioBatteria = true);
    try {
      await _flotta.impostaSogliaBatteria(
        percentuale: pct,
        tipoMezzo: _tipoBatteria.isEmpty ? null : _tipoBatteria,
      );
      _avviso(tr('Soglia batteria salvata'));
    } on LeafApiException catch (e) {
      _avviso('${tr('Errore salvataggio')}: ${e.messaggio}', errore: true);
    } finally {
      if (mounted) setState(() => _salvataggioBatteria = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Config Soglie',
              subtitle: 'Soglie di allerta flotta: mezzi per area e batteria',
            ),
            const SizedBox(height: 18),
            _sogliaAreaCard(),
            const SizedBox(height: 18),
            _sogliaBatteriaCard(),
          ],
        ),
      );
    });
  }

  // ── Soglia minima mezzi per area (OP.02) ──────────────────────────────────
  Widget _sogliaAreaCard() {
    return PanelCard(
      title: 'Soglia Mezzi per Area',
      icon: Icons.place_outlined,
      accent: AppTheme.opAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('Ricevi un alert quando i mezzi disponibili in un\'area '
                'scendono sotto il minimo (OP.02).'),
            style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
          ),
          const SizedBox(height: 14),
          if (_caricamentoAree)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            if (_offlineAree)
              _avvisoInline(tr('Aree non disponibili (offline)'), _caricaAree),
            DropdownButtonFormField<String>(
              initialValue: _idAreaSelezionata,
              isExpanded: true,
              decoration: _decor(tr('Area')),
              hint: Text(tr('Seleziona un\'area')),
              items: [
                for (final a in _listaAree)
                  DropdownMenuItem(
                    value: _idArea(a),
                    child: Text(_nomeArea(a)),
                  ),
              ],
              onChanged: _listaAree.isEmpty
                  ? null
                  : (v) => setState(() => _idAreaSelezionata = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _minimoArea,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _decor(tr('Numero minimo di mezzi')),
            ),
            const SizedBox(height: 14),
            _bottoneSalva(
              etichetta: tr('Salva soglia area'),
              inCorso: _salvataggioArea,
              onPressed: _salvaSogliaArea,
            ),
          ],
        ],
      ),
    );
  }

  // ── Soglia allerta batteria (OP.22) ───────────────────────────────────────
  Widget _sogliaBatteriaCard() {
    return PanelCard(
      title: 'Soglia Allerta Batteria',
      icon: Icons.battery_alert_outlined,
      accent: AppTheme.opAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('Pianifica gli interventi di ricarica quando la batteria '
                'scende sotto la soglia (OP.22).'),
            style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _percentualeBatteria,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _decor(tr('Percentuale di allerta (1–100)')),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _tipoBatteria,
            isExpanded: true,
            decoration: _decor(tr('Tipo di mezzo')),
            items: [
              for (final t in _tipiMezzo)
                DropdownMenuItem(
                  value: t.valore,
                  child: Text(tr(t.etichetta)),
                ),
            ],
            onChanged: (v) => setState(() => _tipoBatteria = v ?? ''),
          ),
          const SizedBox(height: 14),
          _bottoneSalva(
            etichetta: tr('Salva soglia batteria'),
            inCorso: _salvataggioBatteria,
            onPressed: _salvaSogliaBatteria,
          ),
        ],
      ),
    );
  }

  InputDecoration _decor(String label) => InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      );

  Widget _bottoneSalva({
    required String etichetta,
    required bool inCorso,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.opAccent,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: inCorso
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_outlined, size: 18),
        label: Text(etichetta),
        onPressed: inCorso ? null : onPressed,
      ),
    );
  }

  Widget _avvisoInline(String testo, VoidCallback onRetry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE65100)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: 16, color: Color(0xFFE65100)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              testo,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE65100),
              ),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              tr('Riprova'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE65100),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
