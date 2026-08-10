import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app_mobile_utente/api/veicoli_repository.dart';
import 'package:app_mobile_utente/theme.dart';
import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/screens/sos_screen.dart';
import 'package:app_mobile_utente/screens/vehicle_detail_screen.dart';

// I dati mock di mappa (colori filtro, mezzi, ricariche) vivono nel
// part adiacente `map_tab_data.dart` per separare il dato dalla UI (TD-08).
part 'map_tab_data.dart';

/// Vehicle filter options — UT.05.
enum _VehicleFilter { all, scooter, bike, car, emoto, charge }

/// Map screen — sistemaTPL always integrated (architectural constraint).
/// UT.01 vehicles, UT.05 filters, UT.14 charging, UT.20 SOS FAB.
class MapTab extends StatefulWidget {
  const MapTab({super.key, VeicoliApi? veicoli}) : _veicoli = veicoli;

  /// Repository veicoli iniettabile (default reale; fittizio nei test).
  final VeicoliApi? _veicoli;

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  /// Repository risolto: quello iniettato (test) o il singleton reale.
  late final VeicoliApi _veicoli = widget._veicoli ?? veicoliRepository;

  /// Mezzi caricati da `/api/v1/veicoli` (record allineati a `_vehicleData`);
  /// null finché non caricati o in caso di fallback offline (IIN-6).
  List<(String, _VehicleFilter, LatLng, String)>? _mezziApi;

  /// Documenti mezzo grezzi della API, indicizzati per id record (= MarkerId),
  /// per aprire il dettaglio con il `docId` reale al tocco sul marker (UT.02/UT.10).
  final Map<String, Map<String, dynamic>> _docMezzoPerId = {};

  /// True quando l'ultimo caricamento è fallito e si mostrano i dati di riserva.
  bool _mezziOffline = false;

  /// Stazioni di ricarica da `/api/v1/stazioni` (record allineati a `_chargingData`);
  /// null finché non caricate o in caso di fallback offline ai dati di riserva (IIN-6, UT.14).
  List<(String, LatLng, String)>? _stazioniApi;

  GoogleMapController? _mapController;
  bool _locationGranted = false;
  bool _isCheckingPermission = true;
  bool _locationTimedOut = false;
  Timer? _permissionTimeout;
  LatLng? _userPosition;

  static const LatLng _fallbackCenter = LatLng(41.1172, 16.8726);
  static const double _initialZoom = 13.5;

  _VehicleFilter _activeFilter = _VehicleFilter.all;

  /// Custom icon cache for the current marker size bucket.
  final Map<_VehicleFilter, BitmapDescriptor> _icons = {};

  /// Last camera zoom reported by the map (updated on every camera move).
  double _currentZoom = _initialZoom;

  /// Pixel-size bucket the cached [_icons] were rendered for; -1 = none yet.
  int _iconSizeBucket = -1;

  /// Costruisce i marker dei mezzi filtrati per il filtro attivo (UT.01/UT.05).
  ///
  /// @return L'insieme dei [Marker] dei mezzi coerenti con `_activeFilter`.
  Set<Marker> _buildVehicleMarkers() {
    final Set<Marker> markers = {};
    for (final v in _mezziCorrenti) {
      if (_activeFilter != _VehicleFilter.all && _activeFilter != v.$2) {
        continue;
      }
      final icon =
          _icons[v.$2] ??
          BitmapDescriptor.defaultMarkerWithHue(_defaultHue(v.$2));
      markers.add(
        Marker(
          markerId: MarkerId(v.$1),
          position: v.$3,
          infoWindow: InfoWindow(
            title: v.$4,
            snippet: '${tr('Disponibile')} — ${_tariff(v.$2)}',
          ),
          icon: icon,
          onTap: () => _apriDettaglioMezzo(v.$1, v.$2),
        ),
      );
    }
    return markers;
  }

  /// Apre il dettaglio del mezzo toccato sulla mappa per prenotazione/sblocco
  /// (UT.02/UT.10). Usa il documento reale della API (con `docId`) quando
  /// disponibile; in fallback offline costruisce una vista minima dai dati di
  /// riserva (path dimostrativo senza `docId`).
  /// @param idRecord Id del record/marker del mezzo toccato.
  /// @param filtro Filtro/tipo del mezzo, per la vista offline di riserva.
  void _apriDettaglioMezzo(String idRecord, _VehicleFilter filtro) {
    final doc = _docMezzoPerId[idRecord];
    final veicolo = doc != null
        ? VehicleData.daApi(doc)
        : VehicleData(
            id: idRecord,
            type: _tipoVeicolo(filtro),
            batteryPercent: 0,
            rangeKm: 0,
            distanceMeters: 0,
          );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicle: veicolo)),
    );
  }

  /// Mappa il filtro mappa sul tipo veicolo della vista dettaglio (fallback offline).
  static VehicleType _tipoVeicolo(_VehicleFilter f) {
    switch (f) {
      case _VehicleFilter.bike:
        return VehicleType.bike;
      case _VehicleFilter.car:
        return VehicleType.car;
      case _VehicleFilter.emoto:
        return VehicleType.emoto;
      default:
        return VehicleType.scooter;
    }
  }

  /// Mezzi da rappresentare: quelli reali della API se caricati, altrimenti i
  /// dati di riserva locali (`_vehicleData`) per non lasciare la mappa vuota in
  /// assenza di connessione (IIN-6, degradazione controllata).
  List<(String, _VehicleFilter, LatLng, String)> get _mezziCorrenti =>
      _mezziApi ?? _vehicleData;

  /// Carica i mezzi disponibili dalla API e li converte in record per i marker.
  ///
  /// In caso di errore di rete mantiene i dati di riserva e segnala lo stato
  /// offline (IIN-6) senza interrompere l'uso della mappa.
  Future<void> _caricaMezzi() async {
    try {
      // La mappa mostra TUTTI i mezzi disponibili in città (UT.01): nessun
      // filtro per raggio sulla posizione GPS. Diversamente, con l'utente
      // lontano dall'area dei mezzi, la mappa resterebbe priva di marker pur in
      // presenza di mezzi disponibili (mentre le stazioni, non filtrate, sì). Il
      // filtro di prossimità resta alla ricerca "nei dintorni" (search, UT.05).
      final docs = await _veicoli.disponibili();
      if (!mounted) return;
      final convertiti = <(String, _VehicleFilter, LatLng, String)>[];
      final perId = <String, Map<String, dynamic>>{};
      for (final d in docs) {
        final record = _recordDaDoc(d);
        if (record == null) continue;
        convertiti.add(record);
        perId[record.$1] = d; // chiave = MarkerId, per il tocco sul marker
      }
      setState(() {
        _mezziApi = convertiti;
        _docMezzoPerId
          ..clear()
          ..addAll(perId);
        _mezziOffline = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _mezziOffline = true); // resta sui dati di riserva
    }
  }

  /// Carica le stazioni di ricarica dalla API e le converte in record marker (UT.14).
  ///
  /// In caso di errore di rete mantiene i dati di riserva `_chargingData`
  /// (IIN-6) senza interrompere l'uso della mappa.
  Future<void> _caricaStazioni() async {
    try {
      final docs = await _veicoli.stazioni();
      if (!mounted) return;
      final convertite = docs
          .map(_stazioneDaDoc)
          .whereType<(String, LatLng, String)>()
          .toList(growable: false);
      setState(() => _stazioniApi = convertite);
    } catch (_) {
      // Resta sui dati di riserva _chargingData (offline, IIN-6).
    }
  }

  /// Converte un documento stazione della API nel record usato dai marker (UT.14).
  /// @param d Documento stazione grezzo (`_id`, `nome`, `lat`, `lon`, `num_colonnine`…).
  /// @return Record `(id, posizione, etichetta)`, o null se privo di coordinate.
  (String, LatLng, String)? _stazioneDaDoc(Map<String, dynamic> d) {
    final lat = d['lat'];
    final lon = d['lon'];
    if (lat is! num || lon is! num) return null;
    final id = '${d['_id'] ?? d['nome'] ?? ''}';
    final nome = '${d['nome'] ?? tr('Ricarica')}';
    final posti = d['num_colonnine'];
    final etichetta =
        '${tr('Ricarica')} – $nome${posti != null ? ' · $posti ${tr('posti')}' : ''}';
    return (id, LatLng(lat.toDouble(), lon.toDouble()), etichetta);
  }

  /// Converte un documento mezzo della API nel record usato dai marker.
  /// @param d Documento mezzo grezzo (`codice_identificativo`, `tipo_mezzo`, `posizione`…).
  /// @return Record `(id, filtro, posizione, etichetta)`, o null se senza posizione.
  (String, _VehicleFilter, LatLng, String)? _recordDaDoc(
    Map<String, dynamic> d,
  ) {
    final pos = d['posizione'];
    if (pos is! Map || pos['lat'] == null || pos['lon'] == null) return null;
    final filtro = _filtroDaTipo('${d['tipo_mezzo'] ?? ''}');
    final codice = '${d['codice_identificativo'] ?? d['_id'] ?? ''}';
    final batteria = d['livello_batteria_pct'];
    final etichetta =
        '${_nomeTipo(filtro)} $codice${batteria != null ? ' · $batteria%' : ''}';
    return (
      codice.isEmpty ? '${d['_id']}' : codice,
      filtro,
      LatLng((pos['lat'] as num).toDouble(), (pos['lon'] as num).toDouble()),
      etichetta,
    );
  }

  /// Mappa il discriminante `tipo_mezzo` del server sul filtro UI (UT.05).
  static _VehicleFilter _filtroDaTipo(String tipo) {
    switch (tipo) {
      case 'ebike':
        return _VehicleFilter.bike;
      case 'ecar':
        return _VehicleFilter.car;
      case 'emotorbike':
        return _VehicleFilter.emoto;
      default:
        return _VehicleFilter.scooter;
    }
  }

  /// Etichetta leggibile del tipo per il titolo del marker.
  static String _nomeTipo(_VehicleFilter f) {
    switch (f) {
      case _VehicleFilter.bike:
        return 'E-Bike';
      case _VehicleFilter.car:
        return 'Auto';
      case _VehicleFilter.emoto:
        return 'E-Moto';
      default:
        return 'Scooter';
    }
  }

  /// @return L'insieme dei [Marker] delle stazioni di ricarica (UT.14).
  ///
  /// Usa le stazioni reali da `/api/v1/stazioni` quando disponibili, altrimenti
  /// i dati di riserva `_chargingData` (offline, IIN-6).
  Set<Marker> _buildChargingMarkers() {
    final icon =
        _icons[_VehicleFilter.charge] ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
    final stazioni = _stazioniApi ?? _chargingData;
    return {
      for (final c in stazioni)
        Marker(
          markerId: MarkerId(c.$1),
          position: c.$2,
          infoWindow: InfoWindow(title: c.$3),
          icon: icon,
        ),
    };
  }

  /// @return I marker da mostrare: mezzi e/o ricariche in base al filtro attivo
  /// (UT.01/UT.05/UT.14).
  Set<Marker> get _activeMarkers {
    if (_activeFilter == _VehicleFilter.charge) {
      return _buildChargingMarkers();
    }
    return {..._buildVehicleMarkers(), ..._buildChargingMarkers()};
  }

  static double _defaultHue(_VehicleFilter f) {
    switch (f) {
      case _VehicleFilter.scooter:
        return BitmapDescriptor.hueGreen;
      case _VehicleFilter.bike:
        return BitmapDescriptor.hueCyan;
      case _VehicleFilter.car:
        return BitmapDescriptor.hueOrange;
      case _VehicleFilter.emoto:
        return BitmapDescriptor.hueBlue;
      case _VehicleFilter.charge:
        return BitmapDescriptor.hueYellow;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  static String _tariff(_VehicleFilter f) {
    switch (f) {
      case _VehicleFilter.scooter:
        return '0.25 €/min';
      case _VehicleFilter.bike:
        return '0.15 €/min';
      case _VehicleFilter.car:
        return '0.45 €/min';
      case _VehicleFilter.emoto:
        return '0.30 €/min';
      default:
        return '';
    }
  }

  // ── Zoom-responsive marker sizing ──────────────────────────────────────────
  /// Maps the current camera [zoom] to a marker diameter in logical pixels.
  /// Zoomed out → small markers; zoomed in → larger markers.
  static double _sizeForZoom(double zoom) =>
      (26 + (zoom - 11) * 6.5).clamp(24.0, 66.0);

  /// Buckets a size to the nearest 6px so icons are regenerated only when the
  /// visible size meaningfully changes (avoids rebuilding on every frame).
  static int _bucketFor(double size) => (size / 6).round();

  /// (Re)generates the custom marker bitmaps for the given pixel [size].
  Future<void> _buildIconsForSize(double size) async {
    final entries = <(_VehicleFilter, IconData, Color)>[
      (_VehicleFilter.scooter, Icons.electric_scooter, const Color(0xFF388E3C)),
      (_VehicleFilter.bike, Icons.pedal_bike, const Color(0xFF0097A7)),
      (_VehicleFilter.car, Icons.directions_car, const Color(0xFFE65100)),
      (_VehicleFilter.emoto, Icons.electric_moped, const Color(0xFF1565C0)),
      (_VehicleFilter.charge, Icons.bolt, const Color(0xFFF57F17)),
    ];

    final loaded = <_VehicleFilter, BitmapDescriptor>{};
    for (final e in entries) {
      try {
        loaded[e.$1] = await _buildMarkerBitmap(e.$2, e.$3, size);
      } catch (_) {
        // Fallback to default hue marker if canvas fails.
      }
    }
    if (mounted) setState(() => _icons.addAll(loaded));
  }

  /// Recomputes the marker size for the current zoom and regenerates the icon
  /// bitmaps if the size bucket changed. Called on camera idle.
  Future<void> _maybeRescaleMarkers() async {
    final bucket = _bucketFor(_sizeForZoom(_currentZoom));
    if (bucket == _iconSizeBucket) return;
    _iconSizeBucket = bucket;
    await _buildIconsForSize(bucket * 6.0);
  }

  /// Draws a white circle with a coloured icon inside, sized to [sz] px.
  /// UT.01 visual requirement; scales with the map zoom level.
  Future<BitmapDescriptor> _buildMarkerBitmap(
    IconData icon,
    Color color,
    double sz,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final r = sz / 2;

    // Drop shadow
    canvas.drawCircle(
      Offset(r, r + sz * 0.03),
      r - sz * 0.06,
      Paint()
        ..color = Colors.black.withAlpha(45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sz * 0.05),
    );
    // White fill
    canvas.drawCircle(
      Offset(r, r),
      r - sz * 0.05,
      Paint()..color = Colors.white,
    );
    // Coloured border
    canvas.drawCircle(
      Offset(r, r),
      r - sz * 0.05,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = sz * 0.06,
    );

    // Icon glyph
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: sz * 0.48,
          fontFamily: icon.fontFamily,
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

  @override
  void initState() {
    super.initState();
    _iconSizeBucket = _bucketFor(_sizeForZoom(_initialZoom));
    _buildIconsForSize(_iconSizeBucket * 6.0);
    _permissionTimeout = Timer(
      const Duration(seconds: 10),
      _onPermissionTimeout,
    );
    _requestLocationPermission();
    _caricaMezzi(); // mezzi reali (UT.01/UT.05), indipendente dal permesso GPS
    _caricaStazioni(); // stazioni di ricarica reali (UT.14)
  }

  @override
  void dispose() {
    _permissionTimeout?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  /// Mostra lo stato di errore se il permesso non arriva entro il timeout.
  void _onPermissionTimeout() {
    if (_isCheckingPermission && mounted) {
      setState(() {
        _isCheckingPermission = false;
        _locationTimedOut = true;
      });
    }
  }

  /// Richiede il permesso di localizzazione e, se concesso, recupera la
  /// posizione utente (UT.01).
  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) status = await Permission.location.request();
    if (!mounted) return;
    _permissionTimeout?.cancel();
    setState(() {
      _locationGranted = status.isGranted;
      _isCheckingPermission = false;
    });
    if (status.isGranted) _fetchUserPosition();
  }

  /// Recupera la posizione GPS corrente e centra la camera su di essa.
  Future<void> _fetchUserPosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      _userPosition = LatLng(pos.latitude, pos.longitude);
      _animateCameraToUser();
    } catch (_) {}
  }

  /// Anima la camera sulla posizione utente, se disponibile.
  void _animateCameraToUser() {
    if (_mapController != null && _userPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _userPosition!, zoom: 15.5),
        ),
      );
    }
  }

  /// Callback alla creazione della mappa: memorizza il controller e centra
  /// la camera sull'utente.
  ///
  /// @param c Controller della [GoogleMap] appena creata.
  void _onMapCreated(GoogleMapController c) {
    _mapController = c;
    _animateCameraToUser();
  }

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      if (_isCheckingPermission) {
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        );
      }
      if (_locationTimedOut) return _buildErrorState();

      return Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _userPosition ?? _fallbackCenter,
              zoom: _initialZoom,
            ),
            myLocationEnabled: _locationGranted,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _activeMarkers,
            onCameraMove: (pos) => _currentZoom = pos.zoom,
            onCameraIdle: _maybeRescaleMarkers,
          ),
          // UT.05 filter chips
          Positioned(top: 12, left: 12, right: 12, child: _buildFilterChips()),
          // IIN-6 — avviso dati di riserva quando la rete non risponde.
          if (_mezziOffline)
            Positioned(top: 64, left: 12, right: 12, child: _buildOfflineBanner()),
          // Locate-me FAB
          if (_locationGranted)
            Positioned(
              bottom: 104,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'locate_me',
                backgroundColor: Colors.white,
                onPressed: _userPosition != null
                    ? _animateCameraToUser
                    : _fetchUserPosition,
                child: const Icon(
                  Icons.my_location,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          // UT.20 SOS FAB — large touch target (≥48dp) for emergency use.
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'sos_fab',
              backgroundColor: Colors.red,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SOSScreen()),
              ),
              child: const Text(
                'SOS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  /// @return La barra orizzontale di chip per filtrare i mezzi per tipo (UT.05).
  Widget _buildFilterChips() {
    final filters = [
      (_VehicleFilter.all, tr('Tutti'), Icons.grid_view_rounded),
      (_VehicleFilter.scooter, tr('Scooter'), Icons.electric_scooter),
      (_VehicleFilter.bike, tr('Bici'), Icons.pedal_bike),
      (_VehicleFilter.car, tr('Auto'), Icons.directions_car),
      (_VehicleFilter.emoto, tr('E-Moto'), Icons.electric_moped),
      (_VehicleFilter.charge, tr('Ricarica'), Icons.bolt),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final sel = _activeFilter == f.$1;
          final col = _filterColor[f.$1]!;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: sel,
              label: Text(f.$2),
              avatar: Icon(f.$3, size: 15, color: sel ? Colors.white : col),
              backgroundColor: Colors.white,
              selectedColor: col,
              showCheckmark: false,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: sel ? Colors.white : AppTheme.textDark,
              ),
              side: BorderSide(color: sel ? col : Colors.black12),
              elevation: sel ? 3 : 1,
              onSelected: (_) => setState(() => _activeFilter = f.$1),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// @return Banner compatto che segnala l'uso dei dati di riserva (IIN-6).
  Widget _buildOfflineBanner() {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE65100)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 16, color: Color(0xFFE65100)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                tr('Dati non aggiornati (offline)'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE65100),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _caricaMezzi,
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
      ),
    );
  }

  /// @return Lo stato di errore con invito a verificare i permessi e a riprovare.
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off_outlined,
              size: 64,
              color: AppTheme.textGrey,
            ),
            const SizedBox(height: 16),
            Text(
              tr('Posizione non disponibile'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr(
                'Verifica i permessi di localizzazione nelle impostazioni del dispositivo.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                setState(() {
                  _isCheckingPermission = true;
                  _locationTimedOut = false;
                });
                _permissionTimeout = Timer(
                  const Duration(seconds: 10),
                  _onPermissionTimeout,
                );
                await _requestLocationPermission();
              },
              icon: const Icon(Icons.refresh),
              label: Text(tr('Riprova')),
            ),
          ],
        ),
      ),
    );
  }
}
