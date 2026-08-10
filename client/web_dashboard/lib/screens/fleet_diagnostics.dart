import 'package:flutter/material.dart';
import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/api_config.dart';
import 'package:web_dashboard/api/fleet_repository.dart';
import 'package:web_dashboard/data/fleet_data.dart';
import 'package:web_dashboard/data/fleet_store.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/theme.dart';
import 'package:web_dashboard/widgets/common.dart';

/// @brief Schermata "Diagnostica Flotta" dell'Operatore (OP.03 + OP.13).
///
/// Riunisce due viste di stato della flotta utili alla squadra di recupero:
/// il **report giornaliero** (conteggio mezzi per stato operativo e batteria
/// scarica, OP.13) e l'**elenco dei mezzi guasti** da ritirare (OP.03). I dati
/// arrivano da `/api/v1/flotta/report` e `/api/v1/mezzi-guasti`; in assenza di
/// rete (IIN-6) la vista ricade sui mezzi già noti allo [FleetStore].
class FleetDiagnostics extends StatefulWidget {
  const FleetDiagnostics({super.key, this.autoload = true, this.repo});

  /// @brief Se true (default), carica i dati reali all'apertura; i test lo disattivano.
  final bool autoload;

  /// @brief Repository flotta iniettabile (default singleton reale; fake nei test).
  final FlottaApi? repo;

  @override
  State<FleetDiagnostics> createState() => _FleetDiagnosticsState();
}

class _FleetDiagnosticsState extends State<FleetDiagnostics> {
  late final FlottaApi _api = widget.repo ?? fleetRepository;

  /// Report giornaliero reale `{per_stato, batteria_scarica, totale}`, o null.
  Map<String, dynamic>? _report;

  /// Mezzi guasti reali (documenti), o null finché non caricati / in fallback.
  List<Map<String, dynamic>>? _guasti;

  bool _loading = true;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoload && kAutoloadData) {
      _carica();
    } else {
      _loading = false;
    }
  }

  /// Carica report giornaliero (OP.13) ed elenco mezzi guasti (OP.03).
  ///
  /// In caso di errore mostra i dati di riserva derivati dallo [FleetStore]
  /// con un avviso di non aggiornamento (IIN-6).
  Future<void> _carica() async {
    setState(() => _loading = true);
    try {
      final report = await _api.reportGiornaliero();
      final guasti = await _api.mezziGuasti();
      if (!mounted) return;
      setState(() {
        _report = report;
        _guasti = guasti;
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

  // ── Normalizzazione dati per la vista (reale o di riserva) ────────────────

  /// Conteggio per stato operativo: reale dal report, o derivato dai dati di riserva.
  Map<VehicleStatus, int> get _perStato {
    final perStato = _report?['per_stato'];
    if (perStato is Map) {
      final out = <VehicleStatus, int>{};
      perStato.forEach((k, v) {
        final s = vehicleStatusFromApi('$k');
        out[s] = (out[s] ?? 0) + ((v as num?)?.toInt() ?? 0);
      });
      return out;
    }
    // Fallback: conteggio dai mezzi noti allo store.
    final out = <VehicleStatus, int>{};
    for (final v in FleetStore.vehicles.value) {
      out[v.status] = (out[v.status] ?? 0) + 1;
    }
    return out;
  }

  int get _totale =>
      (_report?['totale'] as num?)?.toInt() ?? FleetStore.vehicles.value.length;

  int get _batteriaScarica =>
      (_report?['batteria_scarica'] as num?)?.toInt() ??
      FleetStore.vehicles.value.where((v) => v.battery < 15).length;

  /// Mezzi guasti per la lista: reali, o i mezzi in manutenzione dei dati di riserva.
  List<({String codice, VehicleType tipo, int batteria})> get _guastiView {
    final reali = _guasti;
    if (reali != null) {
      return reali
          .map(
            (m) => (
              codice: '${m['codice_identificativo'] ?? m['_id'] ?? '—'}',
              tipo: vehicleTypeFromApi('${m['tipo_mezzo'] ?? ''}'),
              batteria: (m['livello_batteria_pct'] as num?)?.toInt() ?? 0,
            ),
          )
          .toList(growable: false);
    }
    return FleetStore.vehicles.value
        .where((v) => v.status == VehicleStatus.maintenance)
        .map((v) => (codice: v.id, tipo: v.type, batteria: v.battery))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: SectionHeader(
                    title: 'Diagnostica Flotta',
                    subtitle:
                        'Report giornaliero per stato e mezzi da ritirare',
                  ),
                ),
                IconButton(
                  tooltip: tr('Aggiorna'),
                  icon: const Icon(Icons.refresh, color: AppTheme.opAccent),
                  onPressed: _loading ? null : _carica,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_offline) _offlineBanner(),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              const SizedBox(height: 8),
              _reportCard(),
              const SizedBox(height: 18),
              _guastiCard(),
            ],
          ],
        ),
      );
    });
  }

  // ── Report giornaliero (OP.13) ────────────────────────────────────────────
  Widget _reportCard() {
    final perStato = _perStato;
    final tiles = <Widget>[
      _statTile(Icons.directions_bike, '$_totale', tr('Totale mezzi'),
          AppTheme.opAccent),
      for (final s in VehicleStatus.values)
        if ((perStato[s] ?? 0) > 0)
          _statTile(
            Icons.circle,
            '${perStato[s]}',
            tr(vehicleStatusLabel(s)),
            vehicleStatusColor(s),
          ),
      _statTile(Icons.battery_alert, '$_batteriaScarica',
          tr('Batteria scarica'), AppTheme.statusLowBattery),
    ];
    return PanelCard(
      title: 'Report Giornaliero',
      icon: Icons.assignment_outlined,
      accent: AppTheme.opAccent,
      child: LayoutBuilder(
        builder: (context, c) {
          final cols = c.maxWidth < 560 ? 2 : 3;
          final w = (c.maxWidth - (cols - 1) * 12) / cols;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [for (final t in tiles) SizedBox(width: w, child: t)],
          );
        },
      ),
    );
  }

  Widget _statTile(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Mezzi guasti (OP.03) ──────────────────────────────────────────────────
  Widget _guastiCard() {
    final guasti = _guastiView;
    return PanelCard(
      title: 'Mezzi Guasti da Ritirare',
      icon: Icons.build_circle_outlined,
      accent: AppTheme.opAccent,
      child: guasti.isEmpty
          ? Text(
              tr('Nessun mezzo guasto'),
              style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
            )
          : Column(
              children: [for (final g in guasti) _guastoTile(g)],
            ),
    );
  }

  Widget _guastoTile(({String codice, VehicleType tipo, int batteria}) g) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: vehicleTypeColor(g.tipo).withAlpha(28),
            child: Icon(
              vehicleTypeIcon(g.tipo),
              size: 16,
              color: vehicleTypeColor(g.tipo),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${g.codice} · ${tr(vehicleTypeLabel(g.tipo))}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ),
          Icon(Icons.battery_std, size: 14, color: AppTheme.textGrey),
          const SizedBox(width: 4),
          Text(
            '${g.batteria}%',
            style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _offlineBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
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
              tr('Dati non aggiornati (offline)'),
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
