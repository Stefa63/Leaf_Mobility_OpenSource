import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:web_dashboard/data/fleet_data.dart';
import 'package:web_dashboard/data/fleet_store.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/theme.dart';

/// Colore del layer ricarica (coerente con i marker e la legenda).
const Color kChargingColor = Color(0xFFFBC02D);

/// Colore del layer trasporto pubblico (sistemaTPL integrato).
const Color kTplColor = Color(0xFF8E24AA);

/// @brief Mappa Google reale della citta' (Bari) per le console OP/AP.
///
/// Sostituisce la mappa schematica dove e' richiesta la cartografia reale: usa
/// `google_maps_flutter` (ServizioMappa / MapInterface) con la stessa API key
/// di [AppMobileUtente]. I marker di flotta, ricariche e fermate TPL sono
/// alimentati da [FleetData] (sistemaTPL integrato nativamente nella mappa,
/// vincolo architetturale) e disegnati con le **stesse icone dell'app utente**
/// (cerchio bianco + glifo del tipo di mezzo) per renderli facilmente
/// riconoscibili; il colore del marker codifica lo stato operativo del mezzo.
/// Supporta overlay heatmap (cerchi di concentrazione) e disegno di poligoni di
/// geofencing.
class GoogleCityMap extends StatefulWidget {
  /// Stati operativi da mostrare; null = tutti. OP.01 / OP.20.
  final Set<VehicleStatus>? statusFilter;

  /// Tipologie da mostrare; null = tutte. OP.01 / OP.20 / UT.05.
  final Set<VehicleType>? typeFilters;

  final bool showVehicles;
  final bool showCharging;
  final bool showTpl;

  /// Cerchi traslucidi di concentrazione (approssimazione heatmap per AP).
  final bool showHeatCircles;

  /// Mostra la legenda in basso a sinistra.
  final bool showLegend;

  /// Poligoni di geofencing da disegnare sopra la mappa.
  final Set<Polygon> polygons;

  /// Polilinee aggiuntive (es. perimetro in corso di disegno).
  final Set<Polyline> polylines;

  /// Marker aggiuntivi (es. vertici dell'area in disegno).
  final Set<Marker> extraMarkers;

  /// Callback al tocco sulla mappa (usata per disegnare le aree). null = mappa
  /// in sola consultazione.
  final void Function(LatLng position)? onTap;

  const GoogleCityMap({
    super.key,
    this.statusFilter,
    this.typeFilters,
    this.showVehicles = true,
    this.showCharging = true,
    this.showTpl = true,
    this.showHeatCircles = false,
    this.showLegend = true,
    this.polygons = const {},
    this.polylines = const {},
    this.extraMarkers = const {},
    this.onTap,
  });

  /// Centro cartografico (coincide col fallback di [AppMobileUtente]).
  static const LatLng _center = LatLng(41.1172, 16.8726);
  static const double _initialZoom = 12.5;

  @override
  State<GoogleCityMap> createState() => _GoogleCityMapState();
}

class _GoogleCityMapState extends State<GoogleCityMap> {
  // Il ciclo di vita del controller della mappa e' gestito interamente dal
  // widget [GoogleMap]: NON va disposto manualmente. Su Flutter Web una seconda
  // dispose() rientra in `_map(mapId)` dopo la rimozione dell'entry e fa
  // scattare l'assertion "Maps cannot be retrieved before calling buildView!".

  /// Cache delle icone custom generate via canvas. Le chiavi distinguono il
  /// tipo di mezzo + stato (es. `v_scooter_inUse`), la ricarica (`chg`) e il
  /// TPL (`tpl`). Vuota finche' i bitmap non sono pronti: nel frattempo si usa
  /// il fallback `defaultMarkerWithHue`.
  final Map<String, BitmapDescriptor> _iconCache = {};

  /// Diametro fisso del marker in pixel logici (le icone non riscalano con lo
  /// zoom: dimensione costante sufficiente alla scala cittadina).
  static const double _iconSize = 54;

  @override
  void initState() {
    super.initState();
    _buildIcons();
    // Ridisegna i marker quando lo stato flotta cambia (caricamento /api/v1/flotta).
    // Il caricamento è innescato dopo il login (HomeRouter), non dalla mappa.
    FleetStore.vehicles.addListener(_onFleetChanged);
  }

  @override
  void dispose() {
    FleetStore.vehicles.removeListener(_onFleetChanged);
    super.dispose();
  }

  /// Aggiorna la vista all'arrivo dei dati flotta dal backend.
  void _onFleetChanged() {
    if (mounted) setState(() {});
  }

  /// (Re)genera i bitmap custom (cerchio bianco + glifo) per veicoli, ricarica
  /// e TPL, poi aggiorna lo stato per ridisegnare i marker reali.
  Future<void> _buildIcons() async {
    final cache = <String, BitmapDescriptor>{};

    Future<void> add(String key, IconData icon, Color color) async {
      try {
        cache[key] = await _buildMarkerBitmap(icon, color, _iconSize);
      } catch (_) {
        // Fallback gestito a runtime in _iconFor* se la chiave manca.
      }
    }

    for (final t in VehicleType.values) {
      for (final s in VehicleStatus.values) {
        await add('v_${t.name}_${s.name}', vehicleTypeIcon(t),
            vehicleStatusColor(s));
      }
    }
    await add('chg', Icons.bolt, kChargingColor);
    await add('tpl', Icons.directions_bus, kTplColor);

    if (mounted) setState(() => _iconCache.addAll(cache));
  }

  /// Disegna un cerchio bianco con un glifo colorato all'interno, lato [sz] px.
  /// Replica l'estetica dei marker dell'app utente (map_tab.dart) per rendere i
  /// mezzi e le stazioni di ricarica immediatamente riconoscibili.
  Future<BitmapDescriptor> _buildMarkerBitmap(
    IconData icon,
    Color color,
    double sz,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final r = sz / 2;

    // Ombra
    canvas.drawCircle(
      Offset(r, r + sz * 0.03),
      r - sz * 0.06,
      Paint()
        ..color = Colors.black.withAlpha(45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sz * 0.05),
    );
    // Riempimento bianco
    canvas.drawCircle(
      Offset(r, r),
      r - sz * 0.05,
      Paint()..color = Colors.white,
    );
    // Bordo colorato (codifica lo stato/tipo)
    canvas.drawCircle(
      Offset(r, r),
      r - sz * 0.05,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = sz * 0.06,
    );

    // Glifo dell'icona
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: sz * 0.48,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((sz - tp.width) / 2, (sz - tp.height) / 2));

    final img = await recorder.endRecording().toImage(sz.toInt(), sz.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }

  bool _vehiclePasses(Vehicle v) {
    if (widget.typeFilters != null && !widget.typeFilters!.contains(v.type)) {
      return false;
    }
    if (widget.statusFilter != null &&
        !widget.statusFilter!.contains(v.status)) {
      return false;
    }
    return true;
  }

  /// Tonalita' del marker di fallback in funzione dello stato operativo.
  static double _statusHue(VehicleStatus s) {
    switch (s) {
      case VehicleStatus.available:
        return BitmapDescriptor.hueGreen;
      case VehicleStatus.inUse:
        return BitmapDescriptor.hueAzure;
      case VehicleStatus.maintenance:
        return BitmapDescriptor.hueRed;
      case VehicleStatus.lowBattery:
        return BitmapDescriptor.hueOrange;
    }
  }

  /// Icona del veicolo: bitmap custom se pronta, altrimenti fallback per stato.
  BitmapDescriptor _vehicleIcon(Vehicle v) {
    return _iconCache['v_${v.type.name}_${v.status.name}'] ??
        BitmapDescriptor.defaultMarkerWithHue(_statusHue(v.status));
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    if (widget.showVehicles) {
      for (final v in FleetStore.vehicles.value.where(_vehiclePasses)) {
        markers.add(
          Marker(
            markerId: MarkerId(v.id),
            position: LatLng(v.lat, v.lng),
            icon: _vehicleIcon(v),
            anchor: const Offset(0.5, 0.5),
            infoWindow: InfoWindow(
              title: '${v.id} · ${tr(vehicleTypeLabel(v.type))}',
              snippet: '${tr('Batteria')}: ${v.battery}% · '
                  '${tr(vehicleStatusLabel(v.status))}',
            ),
          ),
        );
      }
    }

    if (widget.showCharging) {
      final icon = _iconCache['chg'] ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      for (final c in FleetData.charging) {
        markers.add(
          Marker(
            markerId: MarkerId(c.id),
            position: LatLng(c.lat, c.lng),
            icon: icon,
            anchor: const Offset(0.5, 0.5),
            infoWindow: InfoWindow(
              title: '${tr('Ricarica')} – ${c.area}',
              snippet: '${c.slots} ${tr('posti')}',
            ),
          ),
        );
      }
    }

    if (widget.showTpl) {
      final icon = _iconCache['tpl'] ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      for (final s in FleetData.tplStops) {
        markers.add(
          Marker(
            markerId: MarkerId(s.id),
            position: LatLng(s.lat, s.lng),
            icon: icon,
            anchor: const Offset(0.5, 0.5),
            infoWindow: InfoWindow(
              title: s.name,
              snippet: tr('Trasporto Pubblico (TPL)'),
            ),
          ),
        );
      }
    }

    markers.addAll(widget.extraMarkers);
    return markers;
  }

  Set<Circle> _buildHeatCircles() {
    if (!widget.showHeatCircles) return const {};
    final circles = <Circle>{};
    var i = 0;
    for (final v in FleetStore.vehicles.value) {
      circles.add(
        Circle(
          circleId: CircleId('heat_${v.id}_${i++}'),
          center: LatLng(v.lat, v.lng),
          radius: 220,
          fillColor: const Color(0xFFE53935).withAlpha(45),
          strokeColor: const Color(0x00000000),
          strokeWidth: 0,
        ),
      );
    }
    return circles;
  }

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: GoogleCityMap._center,
                zoom: GoogleCityMap._initialZoom,
              ),
              markers: _buildMarkers(),
              circles: _buildHeatCircles(),
              polygons: widget.polygons,
              polylines: widget.polylines,
              onTap: widget.onTap,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
              cameraTargetBounds: CameraTargetBounds(
                LatLngBounds(
                  southwest: const LatLng(MapBounds.minLat, MapBounds.minLng),
                  northeast: const LatLng(MapBounds.maxLat, MapBounds.maxLng),
                ),
              ),
            ),
            if (widget.showLegend)
              Positioned(left: 12, bottom: 12, child: _legend()),
          ],
        ),
      );
    });
  }

  Widget _legend() {
    Widget row(Color c, String label) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 11)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(235),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tr('Legenda'),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textGrey,
            ),
          ),
          const SizedBox(height: 4),
          row(AppTheme.statusAvailable, tr('Disponibile')),
          row(AppTheme.statusInUse, tr('In uso')),
          row(AppTheme.statusMaintenance, tr('In manutenzione')),
          row(AppTheme.statusLowBattery, tr('Batteria scarica')),
          row(kChargingColor, tr('Ricarica')),
          row(kTplColor, tr('Trasporto Pubblico (TPL)')),
        ],
      ),
    );
  }
}
