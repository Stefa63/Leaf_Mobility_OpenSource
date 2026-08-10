import 'package:flutter/material.dart';
import 'package:web_dashboard/api/analytics_repository.dart';
import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/api_config.dart';
import 'package:web_dashboard/data/fleet_data.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/screens/event_reporting_screen.dart';
import 'package:web_dashboard/screens/geofencing_screen.dart';
import 'package:web_dashboard/screens/notifications_screen.dart';
import 'package:web_dashboard/screens/profile_screen.dart';
import 'package:web_dashboard/screens/reports_screen.dart';
import 'package:web_dashboard/screens/settings_screen.dart';
import 'package:web_dashboard/theme.dart';
import 'package:web_dashboard/widgets/common.dart';
import 'package:web_dashboard/widgets/dashboard_shell.dart';
import 'package:web_dashboard/widgets/google_city_map.dart';
import 'package:web_dashboard/widgets/metric_card.dart';

/// @brief Console dell'Amministrazione Pubblica (AP).
///
/// Vista orientata alla pianificazione: metriche aggregate e anonime
/// (IIN-15), heatmap di utilizzo (AP.05), distribuzione flotta in tempo reale
/// (AP.10), strumenti di geofencing/eventi e reportistica. I dati di mobilita'
/// mostrati sono gia' aggregati: nessun dato riconducibile al singolo cittadino.
class ApDashboard extends StatelessWidget {
  const ApDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <DashboardSection>[
      DashboardSection(
        icon: Icons.dashboard_outlined,
        label: 'Home Dashboard',
        builder: (context) => const _ApHome(),
      ),
      DashboardSection(
        icon: Icons.map_outlined,
        label: 'Mappa & Heatmap',
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            SectionHeader(
              title: 'Mappa & Heatmap',
              subtitle: 'Vista Cartografica Interattiva',
            ),
            SizedBox(height: 16),
            Expanded(child: GoogleCityMap(showHeatCircles: true)),
          ],
        ),
      ),
      DashboardSection(
        icon: Icons.block_outlined,
        label: 'Gestione Geofencing',
        builder: (context) => const GeofencingScreen(),
      ),
      DashboardSection(
        icon: Icons.warning_amber_outlined,
        label: 'Segnala Eventi',
        builder: (context) => const EventReportingScreen(),
      ),
      DashboardSection(
        icon: Icons.description_outlined,
        label: 'Reportistica',
        builder: (context) => const ReportsScreen(),
      ),
    ];

    return DashboardShell(
      accent: AppTheme.apAccent,
      sections: sections,
      profileLabel: tr('Profilo Comune'),
      profileBuilder: (context) => const ProfileScreen(accent: AppTheme.apAccent),
      notificationsBuilder: (context) =>
          const NotificationsScreen(accent: AppTheme.apAccent),
      settingsBuilder: (context) =>
          const SettingsScreen(accent: AppTheme.apAccent),
    );
  }
}

/// Home dell'Amministrazione Pubblica.
class _ApHome extends StatefulWidget {
  const _ApHome();

  @override
  State<_ApHome> createState() => _ApHomeState();
}

class _ApHomeState extends State<_ApHome> {
  /// Percentuali operative reali da `/analitiche/operativi` (AP.03), o null in fallback.
  Map<String, double>? _operativiReali;

  @override
  void initState() {
    super.initState();
    if (kAutoloadData) _caricaOperativi();
  }

  /// Carica la quota reale di flotta operativa/scarica/in manutenzione (AP.03).
  ///
  /// In assenza di rete resta sui dati di riserva [FleetData] (IIN-6).
  Future<void> _caricaOperativi() async {
    try {
      final ops = await analyticsRepository.percentualiOperativi();
      if (!mounted) return;
      final raw = (ops['operativi'] as Map?)?.cast<String, dynamic>() ?? {};
      setState(
        () => _operativiReali = raw.map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      );
    } on LeafApiException {
      // Offline / servizio non disponibile: si resta sui dati di riserva.
    }
  }

  /// Percentuale per chiave reale (operativi/scarico/manutenzione) o riserva mock.
  int _pct(String chiave, int riserva) =>
      (_operativiReali?[chiave] ?? riserva.toDouble()).round();

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Home Dashboard',
              subtitle: 'Vista Cartografica Interattiva',
            ),
            const SizedBox(height: 18),
            // ── Metriche in tempo reale ──────────────────────────────────
            LayoutBuilder(
              builder: (context, c) {
                final twoCols = c.maxWidth < 1100;
                final cardW = twoCols
                    ? (c.maxWidth - 18) / 2
                    : (c.maxWidth - 36) / 3;
                return Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: [
                    SizedBox(width: cardW, child: _fleetCard()),
                    SizedBox(width: cardW, child: _ecoCard()),
                    SizedBox(width: cardW, child: _areaCard()),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            // ── Mappa + pannello interventi ──────────────────────────────
            LayoutBuilder(
              builder: (context, c) {
                final narrow = c.maxWidth < 1000;
                final map = SizedBox(
                  height: 460,
                  child: _mapCard(),
                );
                final panel = _interventionPanel(context);
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [map, const SizedBox(height: 18), panel],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: map),
                    const SizedBox(width: 18),
                    SizedBox(width: 300, child: panel),
                  ],
                );
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _fleetCard() {
    return MetricCard(
      icon: Icons.directions_bike,
      title: tr('Flotta Operativa'),
      accent: AppTheme.apAccent,
      children: [
        MetricRow(
          dot: AppTheme.statusAvailable,
          label: tr('Attivi'),
          value: '${_pct('operativi', FleetData.activePct)}%',
        ),
        MetricRow(
          dot: AppTheme.statusLowBattery,
          label: tr('Scarichi'),
          value: '${_pct('scarico', FleetData.lowBatteryPct)}%',
        ),
        MetricRow(
          dot: AppTheme.statusMaintenance,
          label: tr('Manutenzione'),
          value: '${_pct('manutenzione', FleetData.maintenancePct)}%',
        ),
      ],
    );
  }

  Widget _ecoCard() {
    return MetricCard(
      icon: Icons.eco_outlined,
      title: tr('Impatto Ecologico (Mese)'),
      accent: AppTheme.primaryGreen,
      children: [
        const BigStat(
          value: '-450 kg',
          label: 'CO₂',
          color: AppTheme.darkGreen,
        ),
        const SizedBox(height: 8),
        Text(
          tr('CO₂ risparmiata'),
          style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
        ),
        const Divider(height: 20),
        const BigStat(
          value: '12.000 km',
          label: '',
          color: AppTheme.apAccent,
        ),
        Text(
          tr('percorsi dalla flotta'),
          style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
        ),
      ],
    );
  }

  Widget _areaCard() {
    return MetricCard(
      icon: Icons.pie_chart_outline,
      title: tr('Distribuzione Aree'),
      accent: AppTheme.accentBrown,
      children: [
        MetricRow(
          dot: AppTheme.statusMaintenance,
          label: tr('Quartiere Centro'),
          value: tr('Alta'),
        ),
        MetricRow(
          dot: AppTheme.statusLowBattery,
          label: tr('Zona Ovest'),
          value: tr('Media'),
        ),
        MetricRow(
          dot: AppTheme.statusInUse,
          label: tr('Zona Est'),
          value: tr('Bassa'),
        ),
      ],
    );
  }

  Widget _mapCard() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.map_outlined,
                    size: 18, color: AppTheme.apAccent),
                const SizedBox(width: 8),
                Text(
                  tr('Heatmap Utilizzo Odierno'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const Spacer(),
                _overlayChip(Icons.construction, '${tr('Cantieri Attivi')} (3)'),
                const SizedBox(width: 8),
                _overlayChip(
                    Icons.speed, '${tr('Slow-Zones Istituite')} (2)'),
              ],
            ),
            const SizedBox(height: 12),
            const Expanded(child: GoogleCityMap(showHeatCircles: true)),
          ],
        ),
      ),
    );
  }

  Widget _overlayChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textGrey),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _interventionPanel(BuildContext context) {
    final scope = DashboardScope.of(context);
    return PanelCard(
      title: 'Pannello Rapido: Interventi',
      icon: Icons.bolt,
      accent: AppTheme.apAccent,
      child: Column(
        children: [
          QuickActionButton(
            icon: Icons.add_road,
            label: 'Inserisci Cantiere/Interruzione',
            accent: AppTheme.apAccent,
            onPressed: () => scope?.jumpToLabel('Gestione Geofencing'),
          ),
          QuickActionButton(
            icon: Icons.speed,
            label: 'Definisci Slow-Zone',
            accent: AppTheme.apAccent,
            onPressed: () => scope?.jumpToLabel('Gestione Geofencing'),
          ),
          QuickActionButton(
            icon: Icons.event,
            label: 'Notifica Grande Evento',
            accent: AppTheme.apAccent,
            onPressed: () => scope?.jumpToLabel('Segnala Eventi'),
          ),
          QuickActionButton(
            icon: Icons.download,
            label: 'Estrai Report (PDF/CSV)',
            accent: AppTheme.apAccent,
            onPressed: () => scope?.jumpToLabel('Reportistica'),
          ),
        ],
      ),
    );
  }
}
