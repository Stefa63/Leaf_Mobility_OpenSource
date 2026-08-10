import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:web_dashboard/api/analytics_repository.dart';
import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/data/fleet_data.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/theme.dart';
import 'package:web_dashboard/widgets/common.dart';

/// Periodo di aggregazione dei report.
enum ReportPeriod { settimana, mese, trimestre }

/// @brief Schermata "Reportistica" dell'Amministrazione Pubblica.
///
/// Presenta report periodici aggregati e anonimi sulla mobilita' urbana:
/// noleggi per tipologia di mezzo, flussi orari, quota di flotta operativa vs
/// manutenzione e impatto ecologico (CO₂ risparmiata). I dati mostrati sono
/// gia' aggregati e non riconducibili al singolo cittadino. Pre-backend i
/// valori provengono da sorgenti statiche/derivate; l'estrazione reale e
/// l'export passeranno per `motore_analitica`.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, AnalyticsApi? analytics})
    : _analytics = analytics;

  /// Repository analitiche iniettabile (default reale; fittizio nei test).
  final AnalyticsApi? _analytics;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportPeriod _period = ReportPeriod.mese;

  late final AnalyticsApi _analytics =
      widget._analytics ?? analyticsRepository;

  /// Noleggi reali per tipo (num_corse), o null finché non caricati / in fallback.
  Map<VehicleType, int>? _rentalsReali;

  /// CO₂ totale reale risparmiata (kg) nell'intervallo, o null in fallback.
  double? _co2Reale;

  /// Flussi orari reali da `/analitiche/flussi`, o null in fallback (mock).
  Map<String, int>? _flussiReali;

  /// Percentuali operative reali da `/analitiche/operativi`, o null in fallback.
  Map<String, double>? _operativiReali;

  @override
  void initState() {
    super.initState();
    _caricaAnalitiche();
  }

  /// Giorni dell'intervallo in base al periodo selezionato (per la query reale).
  int get _giorni => switch (_period) {
        ReportPeriod.settimana => 7,
        ReportPeriod.mese => 30,
        ReportPeriod.trimestre => 90,
      };

  /// Carica le analitiche reali per l'intervallo corrente (AP.01/02/03/07).
  ///
  /// Usa gli endpoint granulari `/analitiche/{noleggi,flussi,operativi,co2}` con
  /// fallback indipendente: ogni sezione che fallisce resta sui dati di riserva
  /// mock (IIN-6). Il vecchio endpoint generico `/analitiche` è il fallback del
  /// conteggio noleggi per tipo.
  Future<void> _caricaAnalitiche() async {
    final dalla = DateTime.now()
        .subtract(Duration(days: _giorni))
        .toIso8601String();
    // ── Noleggi per tipo (fallback: /analitiche generico → mock) ────────────
    try {
      final perTipo = await _analytics.perTipo(dallaData: dalla);
      if (!mounted) return;
      final rentals = <VehicleType, int>{};
      var co2 = 0.0;
      for (final a in perTipo) {
        final t = _tipoDaApi('${a['tipo_mezzo'] ?? ''}');
        rentals[t] = (rentals[t] ?? 0) + ((a['num_corse'] ?? 0) as int);
        co2 += ((a['co2_risparmiata_kg'] ?? 0) as num).toDouble();
      }
      setState(() {
        _rentalsReali = rentals;
        _co2Reale = co2;
      });
    } on LeafApiException {
      // Offline / servizio non disponibile: si resta sui dati di riserva.
    }
    // ── Flussi orari (AP.02) ────────────────────────────────────────────────
    try {
      final flussi = await _analytics.flussiOrari(dallaData: dalla);
      if (!mounted) return;
      final raw = (flussi['flussi'] as Map?)?.cast<String, dynamic>() ?? {};
      final parsed = raw.map((k, v) => MapEntry(k, (v as num).toInt()));
      setState(() => _flussiReali = parsed);
    } on LeafApiException {
      // fallback mock
    }
    // ── Percentuali operativi (AP.03) ───────────────────────────────────────
    try {
      final ops = await _analytics.percentualiOperativi();
      if (!mounted) return;
      final raw = (ops['operativi'] as Map?)?.cast<String, dynamic>() ?? {};
      final parsed = raw.map((k, v) => MapEntry(k, (v as num).toDouble()));
      setState(() => _operativiReali = parsed);
    } on LeafApiException {
      // fallback mock
    }
  }

  /// Mappa il discriminante `tipo_mezzo` del server sull'enum di vista.
  static VehicleType _tipoDaApi(String tipo) {
    switch (tipo) {
      case 'ebike':
        return VehicleType.bike;
      case 'ecar':
        return VehicleType.car;
      case 'emotorbike':
        return VehicleType.emoto;
      default:
        return VehicleType.scooter;
    }
  }

  /// Fattore di scala dei volumi mock in funzione del periodo selezionato.
  double get _factor => switch (_period) {
        ReportPeriod.settimana => 0.25,
        ReportPeriod.mese => 1,
        ReportPeriod.trimestre => 3,
      };

  // ── Sorgenti aggregate (volumi mensili di base) ──────────────────────────
  static const Map<VehicleType, int> _rentalsBaseByType = {
    VehicleType.scooter: 1240,
    VehicleType.bike: 980,
    VehicleType.car: 430,
    VehicleType.emoto: 360,
  };

  // Flussi per fascia oraria (quota % della giornata, anonimi) — dati di riserva.
  static const List<(String, double)> _hourlyFlows = [
    ('00–06', 6),
    ('06–09', 22),
    ('09–12', 14),
    ('12–15', 12),
    ('15–18', 16),
    ('18–21', 21),
    ('21–24', 9),
  ];

  // Fasce orarie e relativo intervallo di ore [inizio, fine] per aggregare i
  // conteggi reali per ora (0-23) restituiti da `/analitiche/flussi` (AP.02).
  static const List<(String, int, int)> _hourBuckets = [
    ('00–06', 0, 5),
    ('06–09', 6, 8),
    ('09–12', 9, 11),
    ('12–15', 12, 14),
    ('15–18', 15, 17),
    ('18–21', 18, 20),
    ('21–24', 21, 23),
  ];

  /// Flussi per fascia oraria effettivi: quote % dai conteggi reali per ora se
  /// disponibili (`_flussiReali`), altrimenti i dati di riserva [_hourlyFlows].
  List<(String, double)> _hourlyFlowsEffettivi() {
    final reali = _flussiReali;
    if (reali == null || reali.isEmpty) return _hourlyFlows;
    final perFascia = <String, int>{};
    var totale = 0;
    for (final b in _hourBuckets) {
      var somma = 0;
      for (var h = b.$2; h <= b.$3; h++) {
        somma += reali['$h'] ?? 0;
      }
      perFascia[b.$1] = somma;
      totale += somma;
    }
    if (totale == 0) return _hourlyFlows;
    return _hourBuckets
        .map((b) => (b.$1, perFascia[b.$1]! * 100 / totale))
        .toList(growable: false);
  }

  // CO₂ risparmiata negli ultimi 6 mesi (kg).
  static const List<double> _co2Trend = [310, 355, 392, 421, 408, 450];

  /// Noleggi per tipo: reali se caricati da `/analitiche` (tipi assenti = 0),
  /// altrimenti i dati di riserva mock scalati per il periodo.
  int _rentals(VehicleType t) => _rentalsReali != null
      ? (_rentalsReali![t] ?? 0)
      : (_rentalsBaseByType[t]! * _factor).round();

  int get _rentalsTotal =>
      VehicleType.values.fold(0, (sum, t) => sum + _rentals(t));

  void _export(String fmt) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.accentBrown,
        content: Text('${tr('Esportazione')} $fmt — ${tr('in preparazione')}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: SectionHeader(
                    title: 'Reportistica',
                    subtitle: 'Report periodici aggregati sulla mobilità urbana',
                  ),
                ),
                _exportMenu(),
              ],
            ),
            const SizedBox(height: 16),
            _periodSelector(),
            const SizedBox(height: 16),
            _kpiRow(),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, c) {
                final twoCols = c.maxWidth >= 980;
                final cardW =
                    twoCols ? (c.maxWidth - 18) / 2 : c.maxWidth;
                return Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: [
                    SizedBox(width: cardW, child: _rentalsByTypeCard()),
                    SizedBox(width: cardW, child: _hourlyFlowsCard()),
                    SizedBox(width: cardW, child: _fleetStateCard()),
                    SizedBox(width: cardW, child: _co2Card()),
                  ],
                );
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _exportMenu() {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () => _export('PDF'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.apAccent,
            side: BorderSide(color: AppTheme.apAccent.withAlpha(90)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
          label: Text(tr('Esporta PDF')),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: () => _export('CSV'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.apAccent,
            side: BorderSide(color: AppTheme.apAccent.withAlpha(90)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.table_view_outlined, size: 18),
          label: Text(tr('Esporta CSV')),
        ),
      ],
    );
  }

  Widget _periodSelector() {
    Widget seg(ReportPeriod p, String label) {
      final selected = _period == p;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() => _period = p);
            _caricaAnalitiche(); // ricarica i volumi reali per il nuovo intervallo
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: selected ? AppTheme.apAccent.withAlpha(24) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? AppTheme.apAccent : Colors.black12,
              ),
            ),
            child: Text(
              tr(label),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? AppTheme.apAccent : AppTheme.textDark,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        seg(ReportPeriod.settimana, 'Settimana'),
        const SizedBox(width: 12),
        seg(ReportPeriod.mese, 'Mese'),
        const SizedBox(width: 12),
        seg(ReportPeriod.trimestre, 'Trimestre'),
      ],
    );
  }

  Widget _kpiRow() {
    return LayoutBuilder(
      builder: (context, c) {
        final twoCols = c.maxWidth < 760;
        final w = twoCols ? (c.maxWidth - 12) / 2 : (c.maxWidth - 36) / 3;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: w,
              child: _kpi(
                Icons.receipt_long_outlined,
                '$_rentalsTotal',
                'Noleggi totali',
                AppTheme.apAccent,
              ),
            ),
            SizedBox(
              width: w,
              child: _kpi(
                Icons.eco_outlined,
                '${(_co2Reale ?? _co2Trend.last * _factor).round()} kg',
                'CO₂ risparmiata',
                AppTheme.darkGreen,
              ),
            ),
            SizedBox(
              width: w,
              child: _kpi(
                Icons.directions_bike,
                '${FleetData.activePct}%',
                'Flotta operativa',
                AppTheme.statusAvailable,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _kpi(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 12),
          Column(
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
                tr(label),
                style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Report 1: noleggi per tipologia (bar chart) ──────────────────────────
  Widget _rentalsByTypeCard() {
    final maxV = VehicleType.values
        .map(_rentals)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    return _chartCard(
      'Noleggi per tipologia di mezzo',
      Icons.bar_chart,
      BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxV * 1.2,
          barTouchData: BarTouchData(enabled: false),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                getTitlesWidget: (v, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(
                    v.toInt().toString(),
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.textGrey),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) {
                  final t = VehicleType.values[v.toInt()];
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      tr(vehicleTypeLabel(t)),
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < VehicleType.values.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: _rentals(VehicleType.values[i]).toDouble(),
                    color: vehicleTypeColor(VehicleType.values[i]),
                    width: 26,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ── Report 2: flussi per fascia oraria (bar chart) ───────────────────────
  Widget _hourlyFlowsCard() {
    final flussi = _hourlyFlowsEffettivi();
    final maxV = flussi.map((e) => e.$2).reduce((a, b) => a > b ? a : b);
    return _chartCard(
      'Flussi di mobilità per fascia oraria',
      Icons.access_time,
      BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxV * 1.2,
          barTouchData: BarTouchData(enabled: false),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (v, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(
                    '${v.toInt()}%',
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.textGrey),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(
                    flussi[v.toInt()].$1,
                    style: const TextStyle(fontSize: 9),
                  ),
                ),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < flussi.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: flussi[i].$2,
                    color: AppTheme.apAccent,
                    width: 18,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(5),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      // Stimato solo finché i flussi reali non sono disponibili (fallback mock).
      stimato: _flussiReali == null,
    );
  }

  // ── Report 3: flotta operativa vs manutenzione (pie chart) ───────────────
  Widget _fleetStateCard() {
    final active = _operativiReali?['operativi'] ?? FleetData.activePct.toDouble();
    final low = _operativiReali?['scarico'] ?? FleetData.lowBatteryPct.toDouble();
    final maint = _operativiReali?['manutenzione'] ?? FleetData.maintenancePct.toDouble();
    final sections = [
      (active, 'Attivi', AppTheme.statusAvailable),
      (low, 'Scarichi', AppTheme.statusLowBattery),
      (maint, 'Manutenzione', AppTheme.statusMaintenance),
    ];
    return _chartCard(
      'Flotta operativa vs manutenzione',
      Icons.donut_large,
      Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 42,
                sections: [
                  for (final s in sections)
                    PieChartSectionData(
                      value: s.$1,
                      color: s.$3,
                      title: '${s.$1.round()}%',
                      radius: 46,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final s in sections)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: s.$3,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tr(s.$2),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Report 4: CO₂ risparmiata (line chart) ───────────────────────────────
  Widget _co2Card() {
    final spots = [
      for (var i = 0; i < _co2Trend.length; i++)
        FlSpot(i.toDouble(), _co2Trend[i] * _factor),
    ];
    final maxV = _co2Trend.reduce((a, b) => a > b ? a : b) * _factor;
    const months = ['Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu'];
    return _chartCard(
      'CO₂ risparmiata dalla flotta elettrica',
      Icons.eco_outlined,
      LineChart(
        LineChartData(
          minY: 0,
          maxY: maxV * 1.2,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(
                    '${v.toInt()}',
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.textGrey),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= months.length) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      tr(months[i]),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.darkGreen,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primaryGreen.withAlpha(40),
              ),
            ),
          ],
        ),
      ),
      stimato: true,
    );
  }

  /// @brief Badge "dato stimato" per le card ancora basate su sorgenti mock.
  ///
  /// Distingue visivamente i report stimati (flussi orari e trend CO₂ a 6 mesi,
  /// non esposti dal backend) da quelli reali da `/analitiche` (noleggi per tipo
  /// e KPI CO₂), evitando di presentare dati derivati come misurazioni effettive.
  Widget _badgeStimato() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.accentBrown.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, size: 12, color: AppTheme.accentBrown),
          const SizedBox(width: 4),
          Text(
            tr('dato stimato'),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.accentBrown,
            ),
          ),
        ],
      ),
    );
  }

  /// Card contenitore standard per un grafico, con titolo e altezza fissa.
  ///
  /// @param stimato true marca la card col badge "dato stimato" (sorgente mock).
  Widget _chartCard(
    String title,
    IconData icon,
    Widget chart, {
    bool stimato = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.apAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr(title),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                if (stimato) _badgeStimato(),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(height: 220, child: chart),
          ],
        ),
      ),
    );
  }
}
