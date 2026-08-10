import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:web_dashboard/api/api_config.dart';
import 'package:web_dashboard/api/events_repository.dart';
import 'package:web_dashboard/data/event_data.dart';
import 'package:web_dashboard/data/event_store.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/theme.dart';
import 'package:web_dashboard/widgets/common.dart';
import 'package:web_dashboard/widgets/google_city_map.dart';

/// @brief Schermata "Segnala Eventi" dell'Amministrazione Pubblica.
///
/// Consente di inserire a sistema le date e le coordinate dei grandi eventi
/// cittadini, dei cantieri/lavori temporanei e delle interruzioni di servizio,
/// così da notificare gli operatori sulle aree che richiederanno un
/// potenziamento o una limitazione della flotta. Si tocca la mappa per
/// posizionare l'evento. I grandi eventi (AP.09) sono persistiti su
/// `/api/v1/eventi` tramite [EventStore] (fallback ai dati di riserva senza
/// rete, IIN-6); cantieri e interruzioni restano locali (domini AP.04).
class EventReportingScreen extends StatefulWidget {
  const EventReportingScreen({super.key, this.autoload = true, this.repo});

  /// @brief Se true (default), carica i dati reali all'apertura; i test lo disattivano.
  final bool autoload;

  /// @brief Repository eventi iniettabile (default singleton reale; fake nei test).
  final EventiApi? repo;

  @override
  State<EventReportingScreen> createState() => _EventReportingScreenState();
}

class _EventReportingScreenState extends State<EventReportingScreen> {
  CityEventType _type = CityEventType.grandeEvento;
  DateTime _date = DateTime.now().add(const Duration(days: 3));
  LatLng? _draftLocation;
  int _seq = 3;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _areaCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.autoload && kAutoloadData) EventStore.carica(repo: widget.repo);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _areaCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  static ({IconData icon, String label, Color color, double hue}) _meta(
    CityEventType t,
  ) {
    switch (t) {
      case CityEventType.grandeEvento:
        return (
          icon: Icons.celebration_outlined,
          label: 'Grande Evento',
          color: AppTheme.apAccent,
          hue: BitmapDescriptor.hueCyan,
        );
      case CityEventType.cantiere:
        return (
          icon: Icons.construction_outlined,
          label: 'Cantiere / Lavori',
          color: AppTheme.accentBrown,
          hue: BitmapDescriptor.hueOrange,
        );
      case CityEventType.interruzione:
        return (
          icon: Icons.report_problem_outlined,
          label: 'Interruzione di Servizio',
          color: AppTheme.alarmCritical,
          hue: BitmapDescriptor.hueRed,
        );
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    for (final e in EventStore.events.value.where((e) => e.location != null)) {
      final meta = _meta(e.type);
      markers.add(
        Marker(
          markerId: MarkerId(e.id),
          position: e.location!,
          icon: BitmapDescriptor.defaultMarkerWithHue(meta.hue),
          infoWindow: InfoWindow(
            title: e.name,
            snippet: '${tr(meta.label)} · ${_fmtDate(e.date)}',
          ),
        ),
      );
    }
    if (_draftLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('__draft_event__'),
          position: _draftLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
          infoWindow: InfoWindow(title: tr('Nuovo evento')),
        ),
      );
    }
    return markers;
  }

  void _onMapTap(LatLng p) => setState(() => _draftLocation = p);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _reset() {
    setState(() {
      _nameCtrl.clear();
      _areaCtrl.clear();
      _noteCtrl.clear();
      _draftLocation = null;
      _type = CityEventType.grandeEvento;
      _date = DateTime.now().add(const Duration(days: 3));
    });
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty || _areaCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.alarmWarning,
          content: Text(tr('Inserisci almeno nome e area dell\'evento')),
        ),
      );
      return;
    }
    EventStore.aggiungi(
      CityEvent(
        id: 'EV-${(++_seq).toString().padLeft(2, '0')}',
        name: _nameCtrl.text.trim(),
        type: _type,
        date: _date,
        area: _areaCtrl.text.trim(),
        location: _draftLocation,
        note: _noteCtrl.text.trim(),
      ),
      repo: widget.repo,
    );
    _reset();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.apAccent,
        content: Text(
          '${tr('Evento registrato')} — ${tr('operatori notificati')}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return ValueListenableBuilder<List<CityEvent>>(
        valueListenable: EventStore.events,
        builder: (context, _, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(
              title: 'Segnala Eventi',
              subtitle: 'Grandi eventi, cantieri e interruzioni di servizio',
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final narrow = c.maxWidth < 1000;
                  final map = _mapCard();
                  final panel = SingleChildScrollView(child: _toolPanel());
                  if (narrow) {
                    return ListView(
                      children: [
                        SizedBox(height: 460, child: map),
                        const SizedBox(height: 16),
                        _toolPanel(),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: map),
                      const SizedBox(width: 18),
                      SizedBox(width: 340, child: panel),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
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
                const Icon(
                  Icons.add_location_alt_outlined,
                  size: 18,
                  color: AppTheme.apAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _draftLocation == null
                        ? tr('Tocca la mappa per posizionare l\'evento')
                        : tr('Posizione impostata — compila e salva'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GoogleCityMap(
                showVehicles: false,
                showCharging: false,
                showTpl: false,
                showLegend: false,
                extraMarkers: _buildMarkers(),
                onTap: _onMapTap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PanelCard(
          title: 'Nuovo Evento',
          icon: Icons.event_outlined,
          accent: AppTheme.apAccent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr('Tipo di evento'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textGrey,
                ),
              ),
              const SizedBox(height: 6),
              ...CityEventType.values.map(_typeRadio),
              const SizedBox(height: 10),
              TextField(
                controller: _nameCtrl,
                decoration: _deco('Nome evento'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _areaCtrl,
                decoration: _deco('Area / quartiere'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _noteCtrl,
                maxLines: 2,
                decoration: _deco('Note (opzionale)'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _pickDate,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.apAccent,
                  side: BorderSide(color: AppTheme.apAccent.withAlpha(90)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.centerLeft,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text('${tr('Data')}: ${_fmtDate(_date)}'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.close, size: 16),
                      label: Text(tr('Reset')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.apAccent,
                      ),
                      icon: const Icon(
                        Icons.notifications_active_outlined,
                        size: 16,
                      ),
                      label: Text(tr('Notifica')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PanelCard(
          title: 'Eventi Programmati',
          icon: Icons.event_note_outlined,
          accent: AppTheme.apAccent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: EventStore.events.value.isEmpty
                ? [
                    Text(
                      tr('Nessun evento programmato'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ]
                : EventStore.events.value.map(_eventTile).toList(),
          ),
        ),
      ],
    );
  }

  InputDecoration _deco(String hint) => InputDecoration(
    hintText: tr(hint),
    isDense: true,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  Widget _typeRadio(CityEventType t) {
    final meta = _meta(t);
    final selected = _type == t;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _type = t),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 18,
                color: selected ? meta.color : AppTheme.textGrey,
              ),
              const SizedBox(width: 10),
              Icon(meta.icon, size: 16, color: meta.color),
              const SizedBox(width: 8),
              Text(
                tr(meta.label),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eventTile(CityEvent e) {
    final meta = _meta(e.type);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: meta.color.withAlpha(28),
            child: Icon(meta.icon, size: 16, color: meta.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  '${tr(meta.label)} · ${e.area} · ${_fmtDate(e.date)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: tr('Elimina'),
            icon: const Icon(Icons.delete_outline, size: 18),
            color: AppTheme.alarmCritical,
            onPressed: () => EventStore.rimuovi(e.id, repo: widget.repo),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
