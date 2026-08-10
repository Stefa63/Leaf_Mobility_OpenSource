import 'package:flutter/material.dart';
import 'package:app_mobile_utente/api/corse_repository.dart';
import 'package:app_mobile_utente/api/veicoli_repository.dart';
import 'package:app_mobile_utente/theme.dart';
import 'package:app_mobile_utente/screens/search_screen.dart';
import 'package:app_mobile_utente/screens/vehicle_detail_screen.dart';
import 'package:app_mobile_utente/screens/history_screen.dart';
import 'package:app_mobile_utente/screens/trip_detail_screen.dart';
import 'package:app_mobile_utente/l10n.dart';

// Per-type colour palette — same keys as MapTab for visual consistency.
const _filterColors = {
  0: AppTheme.accentBrown, // Tutti
  1: Color(0xFF388E3C), // Scooter
  2: Color(0xFF0097A7), // Bici
  3: Color(0xFFE65100), // Auto
  4: Color(0xFF1565C0), // E-Moto
  5: Color(0xFFF57F17), // Ricarica
};

const _filterLabelsIt = ['Tutti', 'Scooter', 'Bici', 'Auto', 'E-Moto'];
const _filterLabelsEn = ['All', 'Scooter', 'Bike', 'Car', 'E-Moto'];
const _filterIcons = [
  Icons.grid_view_rounded,
  Icons.electric_scooter,
  Icons.pedal_bike,
  Icons.directions_car,
  Icons.electric_moped,
];

/// Home tab — search, history, available vehicles. UT.03, UT.05, UT.07.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key, this.onNuovaCorsa});

  /// Callback invocata dalla card "+" quando la cronologia è vuota: porta
  /// l'utente alla mappa per scegliere un mezzo e avviare una nuova corsa (UT.10).
  final VoidCallback? onNuovaCorsa;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  int _selectedFilter = 0;

  /// Mezzi reali caricati dalla API; null fino al caricamento o in fallback.
  List<VehicleData>? _veicoliApi;

  /// Cronologia reale caricata dalla API; null fino al caricamento o in fallback.
  List<TripEntry>? _storicoApi;

  @override
  void initState() {
    super.initState();
    _caricaVeicoli();
    _caricaStorico();
  }

  /// Carica i mezzi disponibili dalla API (fallback ai dati di riserva, IIN-6).
  Future<void> _caricaVeicoli() async {
    try {
      final docs = await veicoliRepository.disponibili();
      if (!mounted) return;
      setState(
        () => _veicoliApi = docs
            .map((d) => VehicleData.daApi(d))
            .toList(growable: false),
      );
    } catch (_) {
      // Resta sui dati di riserva mock.
    }
  }

  /// Carica lo storico corse dalla API (fallback ai dati di riserva, IIN-6).
  Future<void> _caricaStorico() async {
    try {
      final corse = await corseRepository.storico();
      if (!mounted) return;
      setState(() => _storicoApi = corseInVoci(corse));
    } catch (_) {
      // Resta sui dati di riserva mock.
    }
  }

  /// Mezzi da mostrare: reali se caricati, altrimenti i dati di riserva.
  List<VehicleData> get _veicoliCorrenti => _veicoliApi ?? _vehicles;

  /// Cronologia da mostrare: solo i percorsi reali registrati a DB per l'utente
  /// (UT.17). Nessun dato fittizio — se non ce ne sono, la home mostra la card
  /// "+". Coerente con la cronologia del menù laterale (HistoryScreen).
  List<TripEntry> get _storicoCorrente => _storicoApi ?? const <TripEntry>[];

  // Mock vehicle cards aligned with Bari map markers.
  static const _vehicles = [
    VehicleData(
      id: 'SC-001',
      type: VehicleType.scooter,
      batteryPercent: 78,
      rangeKm: 42,
      distanceMeters: 120,
    ),
    VehicleData(
      id: 'BK-003',
      type: VehicleType.bike,
      batteryPercent: 91,
      rangeKm: 55,
      distanceMeters: 230,
    ),
    VehicleData(
      id: 'CA-007',
      type: VehicleType.car,
      batteryPercent: 65,
      rangeKm: 195,
      distanceMeters: 450,
    ),
    VehicleData(
      id: 'EM-002',
      type: VehicleType.emoto,
      batteryPercent: 85,
      rangeKm: 68,
      distanceMeters: 710,
    ),
  ];

  List<String> get _filterLabels => appLanguage.value == 'en'
      ? _filterLabelsEn.toList()
      : _filterLabelsIt.toList();

  List<VehicleData> get _filtered {
    final veicoli = _veicoliCorrenti;
    if (_selectedFilter == 0 || _selectedFilter == 5) return veicoli;
    final types = [
      VehicleType.scooter,
      VehicleType.bike,
      VehicleType.car,
      VehicleType.emoto,
    ];
    final target = types[_selectedFilter - 1];
    return veicoli.where((v) => v.type == target).toList();
  }

  /// Cronologia ordinata in modo crescente (corse meno recenti prima). UT.17.
  List<TripEntry> get _ascendingHistory {
    final trips = List<TripEntry>.of(_storicoCorrente);
    trips.sort((a, b) => a.sequence.compareTo(b.sequence));
    return trips;
  }

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DualSearchCard(),
            const SizedBox(height: 20),
            // UT.05 — filter chips
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _filterLabels.length,
                itemBuilder: (context, i) {
                  final selected = _selectedFilter == i;
                  final color = _filterColors[i]!;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: selected,
                      label: Text(_filterLabels[i]),
                      avatar: Icon(
                        _filterIcons[i],
                        size: 15,
                        color: selected ? Colors.white : color,
                      ),
                      backgroundColor: Colors.white,
                      selectedColor: color,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: selected ? Colors.white : AppTheme.textDark,
                      ),
                      side: BorderSide(
                        color: selected ? color : Colors.black12,
                      ),
                      elevation: selected ? 2 : 1,
                      onSelected: (_) => setState(() => _selectedFilter = i),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('Cronologia Percorsi'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGreen,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                  child: Text(
                    tr('Vedi tutte'),
                    style: const TextStyle(
                      color: AppTheme.accentBrown,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: _ascendingHistory.isEmpty
                  ? _buildAddRideCard(context)
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _ascendingHistory.length,
                      itemBuilder: (context, index) =>
                          _buildHistoryCard(context, _ascendingHistory[index]),
                    ),
            ),
            const SizedBox(height: 32),
            Text(
              tr('Mezzi Disponibili Vicino a Te'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGreen,
              ),
            ),
            const SizedBox(height: 16),
            if (_filtered.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    tr('Nessun mezzo disponibile per questo filtro.'),
                    style: const TextStyle(color: AppTheme.textGrey),
                  ),
                ),
              )
            else
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _filtered
                      .map((v) => _buildVehicleCard(context, v))
                      .toList(),
                ),
              ),
          ],
        ),
      );
    });
  }

  /// Builds a compact, tappable history card for the home strip.
  /// Tapping it opens the full trip detail (UT.17).
  Widget _buildHistoryCard(BuildContext context, TripEntry trip) {
    IconData icon;
    switch (trip.vehicleType) {
      case 'E-Bike':
        icon = Icons.pedal_bike;
      case 'Auto':
        icon = Icons.directions_car;
      case 'E-Moto':
        icon = Icons.electric_moped;
      default:
        icon = Icons.electric_scooter;
    }
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(icon, size: 16, color: AppTheme.accentBrown),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${tr('Corsa')} ${trip.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '${trip.cost.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGreen,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '${trip.from} → ${trip.to}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${trip.date}, ${trip.time}',
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Card "+" mostrata quando non esistono corse passate registrate a DB:
  /// invita ad avviarne una nuova portando alla mappa (UT.10). Ha la stessa
  /// dimensione delle card della cronologia per coerenza visiva.
  Widget _buildAddRideCard(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 250,
        height: 120,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => widget.onNuovaCorsa?.call(),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryGreen, width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    size: 34,
                    color: AppTheme.primaryGreen,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('Nessuna corsa: iniziane una nuova'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.darkGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, VehicleData v) {
    final color = v.typeColor;
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicle: v)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(v.typeIcon, size: 32, color: color),
                const SizedBox(height: 6),
                Text(
                  v.typeLabel.split(' ').first,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${v.batteryPercent}% · ~${v.rangeKm} km',
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two-part departure/arrival search card — navigates to SearchScreen on tap.
/// UT.03, UT.07.
class _DualSearchCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final double cardWidth = MediaQuery.of(context).size.width * 0.9;
    return Center(
      child: SizedBox(
        width: cardWidth,
        child: Card(
          elevation: 4,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: Colors.black.withAlpha(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Departure
              InkWell(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const SearchScreen(startWithDeparture: true),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      const _GreenDot(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tr('Da dove parti?'),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
              // Arrival
              InkWell(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const SearchScreen(startWithDeparture: false),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tr('Dove vuoi andare?'),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GreenDot extends StatelessWidget {
  const _GreenDot();
  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: const BoxDecoration(
      color: AppTheme.primaryGreen,
      shape: BoxShape.circle,
    ),
  );
}
