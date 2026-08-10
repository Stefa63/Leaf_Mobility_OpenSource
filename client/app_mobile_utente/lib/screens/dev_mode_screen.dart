import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:app_mobile_utente/api/api_client.dart';
import 'package:app_mobile_utente/api/api_config.dart';
import 'package:app_mobile_utente/dev_settings_store.dart';
import 'package:app_mobile_utente/theme.dart';

/// @brief Pannello "Modalità sviluppatore" per il debug di connettività.
///
/// Strumento interno (non destinato all'utente finale) che consente di:
///   - puntare l'app a un server diverso da quello di produzione, tipicamente
///     un'istanza in LAN (`http://192.168.x.x:8770/api/v1`) per il debug USB;
///   - verificare la raggiungibilità del server con un test di connessione
///     (`GET /salute`) che misura la latenza e mostra l'esito;
///   - abilitare un log di rete verboso visibile su `flutter run` (USB).
///
/// Le scelte sono persistite da [DevSettings] e applicate al [apiClient] a caldo.
class DevModeScreen extends StatefulWidget {
  const DevModeScreen({super.key});

  @override
  State<DevModeScreen> createState() => _DevModeScreenState();
}

class _DevModeScreenState extends State<DevModeScreen> {
  late final TextEditingController _urlCtrl;
  late bool _attiva;

  /// Esito dell'ultimo test di connessione (null = non ancora eseguito).
  String? _esitoTest;
  bool _esitoOk = false;
  bool _testInCorso = false;

  @override
  void initState() {
    super.initState();
    _attiva = DevSettings.abilitata.value;
    final iniziale = DevSettings.apiBasePersonalizzato.value.isNotEmpty
        ? DevSettings.apiBasePersonalizzato.value
        : kLeafApiBase;
    _urlCtrl = TextEditingController(text: iniziale);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  /// Salva la configurazione e la applica a caldo al client di rete.
  Future<void> _salva() async {
    await DevSettings.save(attiva: _attiva, apiBase: _urlCtrl.text);
    apiClient.applicaBaseUrl(DevSettings.apiBaseEffettivo);
    apiClient.abilitaLogVerboso(DevSettings.abilitata.value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Impostazioni di sviluppo salvate.'),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
    setState(() {});
  }

  /// Esegue un test di raggiungibilità verso `<url base>/salute`.
  Future<void> _testConnessione() async {
    final base = _urlCtrl.text.trim();
    if (base.isEmpty) return;
    setState(() {
      _testInCorso = true;
      _esitoTest = null;
    });
    final url = '${base.replaceAll(RegExp(r'/+$'), '')}/salute';
    final cronometro = Stopwatch()..start();
    try {
      final risposta = await apiClient.dio.getUri<dynamic>(
        Uri.parse(url),
        options: Options(
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      cronometro.stop();
      final corpo = risposta.data;
      final stato = (corpo is Map && corpo['stato'] != null)
          ? corpo['stato'].toString()
          : 'risposta';
      setState(() {
        _esitoOk = true;
        _esitoTest =
            'OK (HTTP ${risposta.statusCode}) · stato="$stato" · ${cronometro.elapsedMilliseconds} ms';
      });
    } on DioException catch (e) {
      cronometro.stop();
      setState(() {
        _esitoOk = false;
        _esitoTest =
            'FALLITO · ${e.type.name} · ${e.message ?? 'errore di rete'} (${cronometro.elapsedMilliseconds} ms)';
      });
    } finally {
      if (mounted) setState(() => _testInCorso = false);
    }
  }

  /// Reimposta l'URL al default di produzione (Cloudflare).
  void _ripristinaDefault() {
    setState(() => _urlCtrl.text = kLeafApiBase);
  }

  /// Inserisce il preset dell'emulatore Android (loopback host = 10.0.2.2).
  void _presetEmulatore() {
    setState(() => _urlCtrl.text = 'http://10.0.2.2:8770/api/v1');
  }

  String get _modalitaBuild {
    if (kReleaseMode) return 'release';
    if (kProfileMode) return 'profile';
    return 'debug';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        title: const Text(
          'Modalità sviluppatore',
          style: TextStyle(color: AppTheme.darkGreen),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _avviso(),
            const SizedBox(height: 20),
            _cardAttivazione(),
            const SizedBox(height: 20),
            _cardServer(),
            const SizedBox(height: 20),
            _cardDiagnostica(),
          ],
        ),
      ),
    );
  }

  Widget _avviso() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accentBrown.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.build_circle_outlined, color: AppTheme.accentBrown),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Strumento interno di debug. Usalo per puntare l\'app a un server '
              'di test (es. in LAN) e verificarne la raggiungibilità.',
              style: TextStyle(fontSize: 12, color: AppTheme.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardAttivazione() {
    return _card([
      SwitchListTile(
        value: _attiva,
        onChanged: (v) => setState(() => _attiva = v),
        activeThumbColor: AppTheme.primaryGreen,
        secondary: const Icon(Icons.developer_mode, color: AppTheme.accentBrown),
        title: const Text(
          'Abilita modalità sviluppatore',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: const Text(
          'Usa il server personalizzato e attiva il log di rete verboso (USB).',
          style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
        ),
      ),
    ]);
  }

  Widget _cardServer() {
    return _card([
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
        child: Text(
          'URL del server (/api/v1)',
          style: TextStyle(
            color: AppTheme.darkGreen,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          controller: _urlCtrl,
          enabled: _attiva,
          keyboardType: TextInputType.url,
          autocorrect: false,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'http://192.168.1.60:8770/api/v1',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            isDense: true,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Wrap(
          spacing: 8,
          children: [
            TextButton.icon(
              onPressed: _attiva ? _presetEmulatore : null,
              icon: const Icon(Icons.smartphone, size: 16),
              label: const Text('Emulatore'),
            ),
            TextButton.icon(
              onPressed: _attiva ? _ripristinaDefault : null,
              icon: const Icon(Icons.cloud_outlined, size: 16),
              label: const Text('Default (Cloudflare)'),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _salva,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Salva'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _testInCorso ? null : _testConnessione,
                icon: _testInCorso
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_tethering, size: 18),
                label: const Text('Test'),
              ),
            ),
          ],
        ),
      ),
      if (_esitoTest != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (_esitoOk ? AppTheme.primaryGreen : Colors.red)
                  .withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _esitoOk ? Icons.check_circle : Icons.error_outline,
                  color: _esitoOk ? AppTheme.primaryGreen : Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _esitoTest!,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
                  ),
                ),
              ],
            ),
          ),
        ),
    ]);
  }

  Widget _cardDiagnostica() {
    return _card([
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Text(
          'Diagnostica',
          style: TextStyle(
            color: AppTheme.darkGreen,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      _riga('URL effettivo', DevSettings.apiBaseEffettivo),
      _riga('Default produzione', kLeafApiBase),
      _riga('Build', _modalitaBuild),
      _riga('Piattaforma', defaultTargetPlatform.name),
      const SizedBox(height: 12),
    ]);
  }

  Widget _riga(String etichetta, String valore) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              etichetta,
              style: const TextStyle(
                color: AppTheme.textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valore,
              style: const TextStyle(color: AppTheme.textDark, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}
