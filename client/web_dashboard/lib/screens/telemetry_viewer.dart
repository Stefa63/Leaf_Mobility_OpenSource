import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/fleet_repository.dart';
import 'package:web_dashboard/data/fleet_store.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/theme.dart';
import 'package:web_dashboard/widgets/common.dart';

/// @brief Schermata "Telemetria" dell'Operatore (OP.07 + OP.14).
///
/// Consulta il **registro telemetrico** di un mezzo per codice univoco
/// (`GET /api/v1/mezzi/{cod}/telemetria`): sblocchi, blocchi, urti, anomalie,
/// rilevazioni GPS e batteria, con timestamp e posizione — i dati oggettivi
/// utili in caso di istruttoria per sinistri o anomalie (OP.07/OP.14). In
/// assenza di rete (IIN-6) mostra un avviso con possibilità di riprovare.
class TelemetryViewer extends StatefulWidget {
  const TelemetryViewer({super.key, this.repo, this.codiceIniziale});

  /// @brief Repository flotta iniettabile (default singleton reale; fake nei test).
  final FlottaApi? repo;

  /// @brief Codice mezzo precompilato (per i test); altrimenti dal [FleetStore].
  final String? codiceIniziale;

  @override
  State<TelemetryViewer> createState() => _TelemetryViewerState();
}

class _TelemetryViewerState extends State<TelemetryViewer> {
  late final FlottaApi _api = widget.repo ?? fleetRepository;
  late final TextEditingController _codice = TextEditingController(
    text: widget.codiceIniziale ?? _primoCodiceNoto(),
  );

  List<Map<String, dynamic>>? _eventi;
  bool _loading = false;
  bool _offline = false;
  bool _interrogato = false;

  /// Primo codice mezzo noto allo store (comodità: pre-riempie il campo).
  String _primoCodiceNoto() {
    final mezzi = FleetStore.vehicles.value;
    return mezzi.isEmpty ? '' : mezzi.first.id;
  }

  @override
  void dispose() {
    _codice.dispose();
    super.dispose();
  }

  /// Carica il registro telemetrico del mezzo indicato (OP.14).
  Future<void> _carica() async {
    final codice = _codice.text.trim();
    if (codice.isEmpty) return;
    setState(() {
      _loading = true;
      _interrogato = true;
    });
    try {
      final eventi = await _api.telemetria(codice);
      if (!mounted) return;
      setState(() {
        _eventi = eventi;
        _offline = false;
        _loading = false;
      });
    } on LeafApiException {
      if (!mounted) return;
      setState(() {
        _offline = true;
        _loading = false;
      });
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
              title: 'Telemetria',
              subtitle: 'Registro eventi telemetrici per codice mezzo',
            ),
            const SizedBox(height: 18),
            _ricercaCard(),
            const SizedBox(height: 18),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_offline)
              _offlineBanner()
            else if (_interrogato)
              _registroCard(),
          ],
        ),
      );
    });
  }

  // ── Ricerca per codice mezzo ──────────────────────────────────────────────
  Widget _ricercaCard() {
    return PanelCard(
      title: 'Consulta Mezzo',
      icon: Icons.sensors_outlined,
      accent: AppTheme.opAccent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: _codice,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _carica(),
              decoration: InputDecoration(
                labelText: tr('Codice mezzo'),
                hintText: 'BK-1',
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.opAccent,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
            ),
            icon: const Icon(Icons.search, size: 18),
            label: Text(tr('Carica')),
            onPressed: _loading ? null : _carica,
          ),
        ],
      ),
    );
  }

  // ── Registro eventi (OP.07/OP.14) ─────────────────────────────────────────
  Widget _registroCard() {
    final eventi = _eventi ?? const [];
    return PanelCard(
      title: 'Registro Telemetrico',
      icon: Icons.timeline_outlined,
      accent: AppTheme.opAccent,
      child: eventi.isEmpty
          ? Text(
              tr('Nessun evento telemetrico per questo mezzo'),
              style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
            )
          : Column(
              children: [for (final e in eventi) _eventoTile(e)],
            ),
    );
  }

  Widget _eventoTile(Map<String, dynamic> e) {
    final tipo = '${e['tipo'] ?? ''}';
    final colore = _coloreTipo(tipo);
    final sotto = <String>[
      _orario('${e['timestamp'] ?? ''}'),
      ?_posizione(e['posizione']),
      if (e['velocita'] != null) '${e['velocita']} km/h',
      if (e['batteria'] != null) '${e['batteria']}%',
      if ((e['dettagli'] as String?)?.isNotEmpty ?? false) '${e['dettagli']}',
    ].where((s) => s.isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colore.withAlpha(28),
            child: Icon(_iconaTipo(tipo), size: 16, color: colore),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(_etichettaTipo(tipo)),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colore,
                  ),
                ),
                if (sotto.isNotEmpty)
                  Text(
                    sotto,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.textGrey,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Estrae "lat, lon" dalla posizione (stringa JSON o mappa), o null.
  String? _posizione(dynamic raw) {
    Map<String, dynamic>? m;
    if (raw is Map) {
      m = Map<String, dynamic>.from(raw);
    } else if (raw is String && raw.isNotEmpty) {
      try {
        final d = jsonDecode(raw);
        if (d is Map) m = Map<String, dynamic>.from(d);
      } catch (_) {
        return null;
      }
    }
    if (m == null) return null;
    final lat = (m['lat'] as num?)?.toStringAsFixed(4);
    final lon = (m['lon'] as num?)?.toStringAsFixed(4);
    if (lat == null || lon == null) return null;
    return '$lat, $lon';
  }

  /// Riduce il timestamp ISO a "AAAA-MM-GG HH:MM" per la lettura.
  String _orario(String iso) {
    if (iso.isEmpty) return '';
    final t = iso.replaceFirst('T', ' ');
    return t.length >= 16 ? t.substring(0, 16) : t;
  }

  String _etichettaTipo(String tipo) => switch (tipo) {
        'sblocco' => 'Sblocco',
        'blocco' => 'Blocco motore',
        'urto' => 'Urto rilevato',
        'anomalia' => 'Anomalia',
        'gps' => 'Rilevazione GPS',
        'batteria' => 'Livello batteria',
        _ => 'Evento',
      };

  IconData _iconaTipo(String tipo) => switch (tipo) {
        'sblocco' => Icons.lock_open_outlined,
        'blocco' => Icons.lock_outline,
        'urto' => Icons.warning_amber_outlined,
        'anomalia' => Icons.error_outline,
        'gps' => Icons.my_location_outlined,
        'batteria' => Icons.battery_alert_outlined,
        _ => Icons.circle_outlined,
      };

  Color _coloreTipo(String tipo) => switch (tipo) {
        'sblocco' => AppTheme.opAccent,
        'blocco' => AppTheme.statusLowBattery,
        'urto' => const Color(0xFFE65100),
        'anomalia' => AppTheme.statusLowBattery,
        'gps' => const Color(0xFF1565C0),
        'batteria' => const Color(0xFFEF6C00),
        _ => AppTheme.textGrey,
      };

  Widget _offlineBanner() {
    return Container(
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
              tr('Telemetria non disponibile (offline)'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE65100),
              ),
            ),
          ),
          GestureDetector(
            onTap: _carica,
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
