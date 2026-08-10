import 'package:flutter/material.dart';
import 'package:app_mobile_utente/theme.dart';
import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/api/routing_repository.dart';
import 'package:app_mobile_utente/api/veicoli_repository.dart';
import 'package:app_mobile_utente/widgets/stato_vista.dart';
import 'package:app_mobile_utente/screens/vehicle_detail_screen.dart';
import 'package:app_mobile_utente/screens/route_detail_screen.dart';

// La cronologia locale, il fallback offline dei suggerimenti e i mapper dei
// payload API vivono nel part adiacente `search_screen_data.dart` (TD-08).
part 'search_screen_data.dart';

/// Full-screen search screen.
/// Requires BOTH departure AND arrival to show route list (UT.03, UT.07).
class SearchScreen extends StatefulWidget {
  /// Whether to focus the departure field first.
  final bool startWithDeparture;

  /// Repository di routing/geocoding iniettabile (default reale; fittizio nei test).
  final RoutingApi? routing;

  /// Repository veicoli iniettabile per i mezzi consigliati (default reale; test).
  final VeicoliApi? veicoli;

  const SearchScreen({
    this.startWithDeparture = true,
    this.routing,
    this.veicoli,
    super.key,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _depCtrl = TextEditingController();
  final _arrCtrl = TextEditingController();
  final _depFocus = FocusNode();
  final _arrFocus = FocusNode();

  bool _depActive = true; // which field is currently active
  String _depQuery = '';
  String _arrQuery = '';

  /// Repository effettivi (iniettabili nei test).
  RoutingApi get _routing => widget.routing ?? routingRepository;
  VeicoliApi get _veicoli => widget.veicoli ?? veicoliRepository;

  /// Suggerimenti di luogo correnti per il campo attivo (UT.07).
  List<LuogoSuggerito> _suggestions = const [];

  /// True mentre il geocoding è in corso (mostra l'indicatore di caricamento).
  bool _suggLoading = false;

  /// Sequenza per scartare le risposte di geocoding obsolete (anti-race).
  int _suggSeq = 0;

  bool get _depFilled => _depCtrl.text.trim().isNotEmpty;
  bool get _arrFilled => _arrCtrl.text.trim().isNotEmpty;
  bool get _bothFilled => _depFilled && _arrFilled;

  String get _activeQuery => _depActive ? _depQuery : _arrQuery;

  @override
  void initState() {
    super.initState();
    _depCtrl.addListener(() {
      setState(() => _depQuery = _depCtrl.text);
      if (_depActive) _aggiornaSuggerimenti();
    });
    _arrCtrl.addListener(() {
      setState(() => _arrQuery = _arrCtrl.text);
      if (!_depActive) _aggiornaSuggerimenti();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.startWithDeparture) {
        _depFocus.requestFocus();
      } else {
        _arrFocus.requestFocus();
        setState(() => _depActive = false);
      }
    });
  }

  /// @brief Aggiorna i suggerimenti di luogo per il campo attivo dal backend (UT.07).
  ///
  /// Chiama `/geocoding` sul gazetteer del server; in caso di errore (offline,
  /// IIN-6) ripiega sui suggerimenti di riserva filtrati localmente. Una sequenza
  /// monotòna scarta le risposte arrivate fuori ordine.
  Future<void> _aggiornaSuggerimenti() async {
    final query = _activeQuery.trim();
    final seq = ++_suggSeq;
    if (query.isEmpty || query == _posizioneCorrente) {
      setState(() {
        _suggestions = const [];
        _suggLoading = false;
      });
      return;
    }
    setState(() => _suggLoading = true);
    try {
      final risultati = await _routing.suggerisci(query);
      if (!mounted || seq != _suggSeq) return;
      setState(() {
        _suggestions = risultati;
        _suggLoading = false;
      });
    } catch (_) {
      if (!mounted || seq != _suggSeq) return;
      setState(() {
        _suggestions = _suggerimentiOffline
            .where((s) => s.toLowerCase().contains(query.toLowerCase()))
            .map((s) => LuogoSuggerito(nome: s, lat: 0, lon: 0))
            .toList(growable: false);
        _suggLoading = false;
      });
    }
  }

  /// @brief Carica le opzioni di percorso reali tra i due campi (UT.07/UT.08).
  ///
  /// Geocodifica i nomi lato server (o usa le coordinate della posizione corrente),
  /// recupera i veicoli reali vicino all'origine per i mezzi consigliati (best-effort)
  /// e mappa il payload in [RouteData]. Le eccezioni propagano al [CaricatoreVista]
  /// che mostra lo stato d'errore con "Riprova".
  Future<List<RouteData>> _caricaPercorsi() async {
    final dep = _depCtrl.text.trim();
    final arr = _arrCtrl.text.trim();
    final depPos = dep == _posizioneCorrente;
    final arrPos = arr == _posizioneCorrente;
    final payload = await _routing.percorsi(
      da: depPos ? null : dep,
      a: arrPos ? null : arr,
      daLat: depPos ? _centroBariLat : null,
      daLon: depPos ? _centroBariLon : null,
      aLat: arrPos ? _centroBariLat : null,
      aLon: arrPos ? _centroBariLon : null,
    );
    final percorsi = (payload['percorsi'] as List?) ?? const [];
    final origine = payload['origine'];
    double? oLat, oLon;
    if (origine is Map) {
      oLat = (origine['lat'] as num?)?.toDouble();
      oLon = (origine['lon'] as num?)?.toDouble();
    }
    var mezzi = const <VehicleData>[];
    try {
      final grezzi = await _veicoli.disponibili(lat: oLat, lon: oLon);
      mezzi = grezzi.map((m) => VehicleData.daApi(m)).toList(growable: false);
    } catch (_) {
      mezzi = const []; // best-effort: i mezzi consigliati restano assenti (IIN-6)
    }
    return _percorsiDaApi(percorsi, mezzi);
  }

  @override
  void dispose() {
    _depCtrl.dispose();
    _arrCtrl.dispose();
    _depFocus.dispose();
    _arrFocus.dispose();
    super.dispose();
  }

  /// Rende attivo il campo partenza ([dep] true) o arrivo e aggiorna i suggerimenti.
  ///
  /// @param dep True per attivare la partenza, false per l'arrivo.
  void _attiva(bool dep) {
    setState(() => _depActive = dep);
    _aggiornaSuggerimenti();
  }

  /// Applica la [location] scelta al campo attivo (partenza o arrivo) e sposta
  /// il focus al campo successivo se ancora vuoto (UT.07).
  ///
  /// @param location Localita' selezionata dai suggerimenti o dalla cronologia.
  void _selectLocation(String location) {
    if (_depActive) {
      _depCtrl.text = location;
      setState(() => _depQuery = location);
      // Auto-move focus to arrival if empty
      if (!_arrFilled) {
        setState(() => _depActive = false);
        _arrFocus.requestFocus();
      } else {
        FocusScope.of(context).unfocus();
      }
    } else {
      _arrCtrl.text = location;
      setState(() => _arrQuery = location);
      FocusScope.of(context).unfocus();
    }
  }

  /// Inverte i contenuti dei campi di partenza e arrivo.
  void _swap() {
    final tmp = _depCtrl.text;
    _depCtrl.text = _arrCtrl.text;
    _arrCtrl.text = tmp;
    setState(() {
      _depQuery = _depCtrl.text;
      _arrQuery = _arrCtrl.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        title: Text(tr('Cerca percorso')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_bothFilled)
            TextButton(
              onPressed: () {
                _depCtrl.clear();
                _arrCtrl.clear();
              },
              child: Text(
                tr('Cancella'),
                style: const TextStyle(
                  color: AppTheme.accentBrown,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Dual input panel ──────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      // Departure
                      GestureDetector(
                        onTap: () {
                          _attiva(true);
                          _depFocus.requestFocus();
                        },
                        child: TextField(
                          controller: _depCtrl,
                          focusNode: _depFocus,
                          onTap: () => _attiva(true),
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) {
                            _attiva(false);
                            _arrFocus.requestFocus();
                          },
                          decoration: InputDecoration(
                            hintText: tr('Da dove parti?'),
                            prefixIcon: const Icon(
                              Icons.trip_origin,
                              color: AppTheme.primaryGreen,
                              size: 18,
                            ),
                            suffixIcon: _depFilled
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () => _depCtrl.clear(),
                                  )
                                : null,
                            border: _inputBorder(_depActive),
                            focusedBorder: _inputBorder(true),
                            enabledBorder: _inputBorder(false),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            filled: true,
                            fillColor: AppTheme.backgroundBeige,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Arrival
                      GestureDetector(
                        onTap: () {
                          _attiva(false);
                          _arrFocus.requestFocus();
                        },
                        child: TextField(
                          controller: _arrCtrl,
                          focusNode: _arrFocus,
                          onTap: () => _attiva(false),
                          decoration: InputDecoration(
                            hintText: tr('Dove vuoi andare?'),
                            prefixIcon: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 18,
                            ),
                            suffixIcon: _arrFilled
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () => _arrCtrl.clear(),
                                  )
                                : null,
                            border: _inputBorder(!_depActive),
                            focusedBorder: _inputBorder(true),
                            enabledBorder: _inputBorder(false),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            filled: true,
                            fillColor: AppTheme.backgroundBeige,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Swap button
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    icon: const Icon(
                      Icons.swap_vert,
                      color: AppTheme.accentBrown,
                    ),
                    onPressed: _swap,
                    tooltip: tr('Inverti'),
                  ),
                ),
              ],
            ),
          ),
          // "Use current location" shortcut
          if (!_bothFilled)
            InkWell(
              onTap: () => _selectLocation('Posizione corrente'),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.my_location,
                      color: AppTheme.primaryGreen,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      tr('Usa posizione corrente'),
                      style: const TextStyle(
                        color: AppTheme.darkGreen,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const Divider(height: 1),

          // ── Body: suggestions / history / routes ──────────────────────
          Expanded(
            child: _bothFilled
                ? _buildRouteList()
                : _activeQuery.isEmpty
                ? _buildHistory()
                : _buildSuggestions(),
          ),
        ],
      ),
    );
  }

  /// Bordo del campo di testo, evidenziato quando [active].
  ///
  /// @param active Se il campo e' quello correntemente selezionato.
  /// @return Il bordo arrotondato con colore/spessore coerenti allo stato.
  OutlineInputBorder _inputBorder(bool active) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(
      color: active ? AppTheme.primaryGreen : Colors.black12,
      width: active ? 1.5 : 1.0,
    ),
  );

  /// @return La lista delle ricerche recenti (mostrata a query vuota, UT.07).
  Widget _buildHistory() => ListView(
    children: [
      _header(tr('Ricerche recenti')),
      ..._searchHistory.map(
        (h) => _LocationTile(
          icon: Icons.history,
          color: AppTheme.textGrey,
          label: h,
          onTap: () => _selectLocation(h),
        ),
      ),
    ],
  );

  /// @return La lista dei suggerimenti dal backend (UT.07): indicatore di
  /// caricamento durante il geocoding, messaggio "nessun risultato" se vuota.
  Widget _buildSuggestions() {
    if (_suggLoading && _suggestions.isEmpty) {
      return const VistaCaricamento();
    }
    if (_suggestions.isEmpty) {
      return Center(
        child: Text(
          tr('Nessun risultato.'),
          style: const TextStyle(color: AppTheme.textGrey),
        ),
      );
    }
    return ListView(
      children: [
        _header(tr('Suggerimenti')),
        ..._suggestions.map(
          (s) => _LocationTile(
            icon: Icons.place_outlined,
            color: AppTheme.accentBrown,
            label: s.nome,
            onTap: () => _selectLocation(s.nome),
          ),
        ),
      ],
    );
  }

  /// @return Le opzioni di percorso reali tra i due campi, con stati
  /// caricamento/errore/vuoto (UT.03/UT.07). La `key` su partenza|arrivo forza
  /// una nuova richiesta quando l'utente modifica i campi.
  Widget _buildRouteList() {
    return CaricatoreVista<List<RouteData>>(
      key: ValueKey('${_depCtrl.text}|${_arrCtrl.text}'),
      carica: _caricaPercorsi,
      messaggioCaricamento: tr('Ricerca percorsi…'),
      vuotoSe: (routes) => routes.isEmpty,
      vistaVuota: VistaVuota(
        titolo: tr('Nessun percorso disponibile'),
        sottotitolo: tr('Prova con un\'altra destinazione.'),
        icona: Icons.alt_route,
      ),
      costruisci: (context, routes) => ListView(
        children: [
          _header(
            '${tr('Percorsi disponibili')}  ·  ${routes.length} ${tr('opzioni')}',
          ),
          ...routes.map(
            (r) => _RouteTile(
              route: r,
              departure: _depCtrl.text,
              arrival: _arrCtrl.text,
            ),
          ),
        ],
      ),
    );
  }

  /// Intestazione di sezione in maiuscolo.
  ///
  /// @param text Etichetta della sezione.
  /// @return Il widget di intestazione formattato.
  Widget _header(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.textGrey,
        letterSpacing: 0.7,
      ),
    ),
  );
}

/// @brief Riga di un suggerimento di luogo o di una ricerca recente (UT.07).
class _LocationTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _LocationTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: color, size: 20),
    title: Text(
      label,
      style: const TextStyle(fontSize: 14, color: AppTheme.textDark),
    ),
    onTap: onTap,
  );
}

/// @brief Card di un'opzione di percorso; apre il dettaglio al tap (UT.03/UT.07).
class _RouteTile extends StatelessWidget {
  final RouteData route;
  final String departure;
  final String arrival;
  const _RouteTile({
    required this.route,
    required this.departure,
    required this.arrival,
  });

  /// @return Il tipo di mezzo della modalità: dal primo consigliato reale, o dal
  /// tipo consigliato del percorso se nessun mezzo è disponibile (offline/vuoto).
  VehicleType? get _modeType => route.recommended.isNotEmpty
      ? route.recommended.first.type
      : route.recommendedType;

  /// @return L'icona della modalità principale del percorso.
  IconData get _modeIcon {
    final type = _modeType;
    if (type == null) return Icons.directions;
    return VehicleData(
      id: '',
      type: type,
      batteryPercent: 0,
      rangeKm: 0,
      distanceMeters: 0,
    ).typeIcon;
  }

  /// @return Il colore associato alla modalità principale del percorso.
  Color get _modeColor {
    final type = _modeType;
    if (type == null) return AppTheme.primaryGreen;
    return VehicleData(
      id: '',
      type: type,
      batteryPercent: 0,
      rangeKm: 0,
      distanceMeters: 0,
    ).typeColor;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RouteDetailScreen(
              route: route,
              departure: departure,
              arrival: arrival,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _modeColor.withAlpha(22),
                child: Icon(_modeIcon, color: _modeColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(route.name),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tr(route.description),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGrey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _Chip(
                          Icons.schedule_outlined,
                          '${route.durationMinutes} min',
                        ),
                        const SizedBox(width: 8),
                        _Chip(
                          Icons.straighten_outlined,
                          '${route.distanceKm} km',
                        ),
                        if (route.hasTpl) ...[
                          const SizedBox(width: 8),
                          const _Chip(
                            Icons.directions_bus_outlined,
                            'TPL',
                            color: Colors.blue,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textGrey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// @brief Piccola etichetta con icona usata nelle card percorso (durata, km, TPL).
class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip(this.icon, this.label, {this.color = AppTheme.accentBrown});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 3),
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}
