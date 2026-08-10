import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/areas_repository.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/theme.dart';
import 'package:web_dashboard/widgets/common.dart';
import 'package:web_dashboard/widgets/google_city_map.dart';

/// Tipologia di area di geofencing tracciabile dall'Amministrazione Pubblica.
/// AP.04 (cantiere), AP.06 (interdizione totale), AP.08 (slow-zone).
enum GeoAreaType { operativa, interdetta, slowZone, cantiere }

/// @brief Stringa `tipo` lato server per una tipologia di area di vista.
String tipoAreaApi(GeoAreaType t) {
  switch (t) {
    case GeoAreaType.operativa:
      return 'area_operativa';
    case GeoAreaType.interdetta:
      return 'interdizione';
    case GeoAreaType.slowZone:
      return 'slow_zone';
    case GeoAreaType.cantiere:
      return 'cantiere';
  }
}

/// @brief Tipologia di vista a partire dalla stringa `tipo` del server.
GeoAreaType tipoAreaDaApi(String tipo) {
  switch (tipo) {
    case 'interdizione':
    case 'interdetta':
      return GeoAreaType.interdetta;
    case 'slow_zone':
      return GeoAreaType.slowZone;
    case 'cantiere':
      return GeoAreaType.cantiere;
    default:
      return GeoAreaType.operativa;
  }
}

/// @brief Area di geofencing disegnata sulla mappa.
class GeoArea {
  final String id;
  String name;
  final GeoAreaType type;
  final List<LatLng> points;

  /// Limite di velocita' in km/h (solo per [GeoAreaType.slowZone]).
  final int? speedLimit;

  GeoArea({
    required this.id,
    required this.name,
    required this.type,
    required this.points,
    this.speedLimit,
  });

  /// @brief Costruisce una [GeoArea] da un documento `aree_limitate` della API.
  ///
  /// Accetta sia il poligono come `poligono` (`[[lat,lon], …]`) sia come
  /// `geometria` (`[{lat,lon}, …]`). Ritorna null se i vertici sono < 3.
  ///
  /// @param d Documento area grezzo da `/api/v1/aree`.
  /// @return La [GeoArea] corrispondente, o null se poligono non valido.
  static GeoArea? daApi(Map<String, dynamic> d) {
    final punti = _puntiDa(d);
    if (punti.length < 3) return null;
    return GeoArea(
      id: '${d['_id'] ?? ''}',
      name: '${d['nome'] ?? '—'}',
      type: tipoAreaDaApi('${d['tipo'] ?? ''}'),
      points: punti,
      speedLimit: (d['limite_velocita_kmh'] as num?)?.toInt(),
    );
  }

  /// Estrae i vertici dal documento, supportando `poligono` o `geometria`.
  static List<LatLng> _puntiDa(Map<String, dynamic> d) {
    final poligono = d['poligono'];
    if (poligono is List) {
      return [
        for (final p in poligono)
          if (p is List && p.length >= 2)
            LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()),
      ];
    }
    final geometria = d['geometria'];
    if (geometria is List) {
      return [
        for (final p in geometria)
          if (p is Map && p['lat'] != null && p['lon'] != null)
            LatLng((p['lat'] as num).toDouble(), (p['lon'] as num).toDouble()),
      ];
    }
    return const [];
  }
}

/// @brief Schermata di geofencing dell'Amministrazione Pubblica.
///
/// Permette di disegnare sulla mappa Google aree operative e non operative,
/// perimetri di interdizione totale (AP.06), slow-zone con limite di velocita'
/// (AP.08) e cantieri/lavori temporanei (AP.04). Si tocca la mappa per aggiungere
/// i vertici e si completa il poligono. Pre-backend le aree restano in memoria
/// locale; il salvataggio reale passera' per `gestore_geofencing` e sara'
/// propagato ai mezzi entro 30s (IIN-21).
class GeofencingScreen extends StatefulWidget {
  const GeofencingScreen({super.key, AreeApi? aree}) : _aree = aree;

  /// Repository aree iniettabile (default reale; fittizio nei test).
  final AreeApi? _aree;

  @override
  State<GeofencingScreen> createState() => _GeofencingScreenState();
}

class _GeofencingScreenState extends State<GeofencingScreen> {
  GeoAreaType _drawType = GeoAreaType.operativa;
  int _speedLimit = 20;
  final List<LatLng> _draft = [];
  int _seq = 3;

  late final AreeApi _aree = widget._aree ?? areasRepository;

  /// True quando l'ultimo caricamento è fallito (si mostrano i dati di riserva).
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _caricaAree();
  }

  /// Carica le aree configurate dal backend (AP.04/06/08).
  ///
  /// In caso di errore mantiene i dati di riserva mock e segnala offline (IIN-6).
  Future<void> _caricaAree() async {
    try {
      final docs = await _aree.elenco();
      if (!mounted) return;
      final aree = docs.map(GeoArea.daApi).whereType<GeoArea>().toList();
      setState(() {
        _areas
          ..clear()
          ..addAll(aree);
        _offline = false;
      });
    } on LeafApiException {
      if (mounted) setState(() => _offline = true); // resta sui dati di riserva
    }
  }

  final List<GeoArea> _areas = [
    GeoArea(
      id: 'GF-01',
      name: 'Area Operativa Centro',
      type: GeoAreaType.operativa,
      points: const [
        LatLng(41.1255, 16.8650),
        LatLng(41.1265, 16.8740),
        LatLng(41.1190, 16.8760),
        LatLng(41.1180, 16.8660),
      ],
    ),
    GeoArea(
      id: 'GF-02',
      name: 'Zona Pedonale San Nicola',
      type: GeoAreaType.interdetta,
      points: const [
        LatLng(41.1300, 16.8665),
        LatLng(41.1312, 16.8700),
        LatLng(41.1288, 16.8712),
        LatLng(41.1282, 16.8675),
      ],
    ),
    GeoArea(
      id: 'GF-03',
      name: 'Slow-zone Lungomare',
      type: GeoAreaType.slowZone,
      speedLimit: 15,
      points: const [
        LatLng(41.1270, 16.8730),
        LatLng(41.1255, 16.8775),
        LatLng(41.1230, 16.8760),
        LatLng(41.1245, 16.8720),
      ],
    ),
  ];

  static (String, Color) _typeMeta(GeoAreaType t) {
    switch (t) {
      case GeoAreaType.operativa:
        return ('Area Operativa', AppTheme.statusAvailable);
      case GeoAreaType.interdetta:
        return ('Interdizione Totale', AppTheme.alarmCritical);
      case GeoAreaType.slowZone:
        return ('Slow-zone', AppTheme.alarmWarning);
      case GeoAreaType.cantiere:
        return ('Cantiere / Lavori', AppTheme.accentBrown);
    }
  }

  Set<Polygon> _buildPolygons() {
    final polys = <Polygon>{};
    for (final a in _areas) {
      final color = _typeMeta(a.type).$2;
      polys.add(
        Polygon(
          polygonId: PolygonId(a.id),
          points: a.points,
          fillColor: color.withAlpha(60),
          strokeColor: color,
          strokeWidth: 2,
        ),
      );
    }
    if (_draft.length >= 3) {
      final color = _typeMeta(_drawType).$2;
      polys.add(
        Polygon(
          polygonId: const PolygonId('__draft__'),
          points: _draft,
          fillColor: color.withAlpha(40),
          strokeColor: color,
          strokeWidth: 2,
        ),
      );
    }
    return polys;
  }

  Set<Polyline> _buildPolylines() {
    if (_draft.length < 2) return const {};
    final color = _typeMeta(_drawType).$2;
    return {
      Polyline(
        polylineId: const PolylineId('__draft_line__'),
        points: _draft,
        color: color,
        width: 2,
      ),
    };
  }

  Set<Marker> _buildDraftMarkers() {
    final markers = <Marker>{};
    for (var i = 0; i < _draft.length; i++) {
      markers.add(
        Marker(
          markerId: MarkerId('__draft_$i'),
          position: _draft[i],
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRose,
          ),
          infoWindow: InfoWindow(title: '${tr('Vertice')} ${i + 1}'),
        ),
      );
    }
    return markers;
  }

  void _onMapTap(LatLng p) => setState(() => _draft.add(p));

  void _undoLast() {
    if (_draft.isNotEmpty) setState(() => _draft.removeLast());
  }

  void _cancelDraft() => setState(_draft.clear);

  Future<void> _completeArea() async {
    if (_draft.length < 3) return;
    final meta = _typeMeta(_drawType);
    final payload = <String, dynamic>{
      'tipo': tipoAreaApi(_drawType),
      'nome': '${tr(meta.$1)} ${_seq + 1}',
      'poligono': [
        for (final p in _draft) [p.latitude, p.longitude],
      ],
      if (_drawType == GeoAreaType.slowZone) 'limite_velocita_kmh': _speedLimit,
    };
    try {
      await _aree.crea(payload);
      if (!mounted) return;
      _seq++;
      setState(_draft.clear);
      await _caricaAree(); // riallinea con l'elenco reale (id server)
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.apAccent,
          content: Text(
            '${tr('Area salvata')} — ${tr('propagazione ai mezzi entro 30s')}',
          ),
        ),
      );
    } on LeafApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFC62828),
          content: Text(e.messaggio),
        ),
      );
    }
  }

  /// Elimina un'area sul backend e aggiorna la lista (AP.04).
  Future<void> _eliminaArea(GeoArea a) async {
    try {
      await _aree.elimina(a.id);
      if (mounted) setState(() => _areas.remove(a));
    } on LeafApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFC62828),
          content: Text(e.messaggio),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Gestione Geofencing',
            subtitle: 'Aree operative, interdizioni e slow-zone',
          ),
          if (_offline)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, size: 16, color: Color(0xFFE65100)),
                  const SizedBox(width: 8),
                  Text(
                    tr('Dati non aggiornati (offline)'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ],
              ),
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
                    SizedBox(width: 320, child: panel),
                  ],
                );
              },
            ),
          ),
        ],
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
                const Icon(Icons.edit_location_alt_outlined,
                    size: 18, color: AppTheme.apAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _draft.isEmpty
                        ? tr('Tocca la mappa per iniziare a disegnare un\'area')
                        : '${_draft.length} ${tr('vertici — completa o annulla')}',
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
                polygons: _buildPolygons(),
                polylines: _buildPolylines(),
                extraMarkers: _buildDraftMarkers(),
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
          title: 'Nuova Area',
          icon: Icons.draw_outlined,
          accent: AppTheme.apAccent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr('Tipo di area'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textGrey,
                ),
              ),
              const SizedBox(height: 8),
              ...GeoAreaType.values.map(_typeRadio),
              if (_drawType == GeoAreaType.slowZone) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.speed, size: 18, color: AppTheme.alarmWarning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${tr('Limite')}: $_speedLimit km/h',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _speedLimit.toDouble(),
                  min: 5,
                  max: 30,
                  divisions: 5,
                  label: '$_speedLimit km/h',
                  activeColor: AppTheme.apAccent,
                  onChanged: (v) => setState(() => _speedLimit = v.round()),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _draft.isEmpty ? null : _undoLast,
                      icon: const Icon(Icons.undo, size: 16),
                      label: Text(tr('Annulla punto')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _draft.isEmpty ? null : _cancelDraft,
                      icon: const Icon(Icons.close, size: 16),
                      label: Text(tr('Reset')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _draft.length >= 3 ? _completeArea : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.apAccent,
                ),
                icon: const Icon(Icons.check, size: 18),
                label: Text(tr('Completa area')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PanelCard(
          title: 'Aree Configurate',
          icon: Icons.layers_outlined,
          accent: AppTheme.apAccent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _areas.map(_areaTile).toList(),
          ),
        ),
      ],
    );
  }

  Widget _typeRadio(GeoAreaType t) {
    final meta = _typeMeta(t);
    final selected = _drawType == t;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _drawType = t),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 18,
                color: selected ? meta.$2 : AppTheme.textGrey,
              ),
              const SizedBox(width: 10),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: meta.$2.withAlpha(120),
                  border: Border.all(color: meta.$2, width: 2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                tr(meta.$1),
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

  Widget _areaTile(GeoArea a) {
    final meta = _typeMeta(a.type);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: meta.$2.withAlpha(120),
              border: Border.all(color: meta.$2, width: 2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  a.speedLimit != null
                      ? '${tr(meta.$1)} · ${a.speedLimit} km/h'
                      : '${tr(meta.$1)} · ${a.points.length} ${tr('vertici')}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textGrey),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: tr('Elimina'),
            icon: const Icon(Icons.delete_outline, size: 18),
            color: AppTheme.alarmCritical,
            onPressed: () => _eliminaArea(a),
          ),
        ],
      ),
    );
  }
}
