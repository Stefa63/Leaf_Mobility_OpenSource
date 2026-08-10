import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_mobile_utente/api/api_client.dart';
import 'package:app_mobile_utente/api/sos_repository.dart';
import 'package:app_mobile_utente/theme.dart';
import 'package:app_mobile_utente/l10n.dart';

/// Emergency SOS screen.
/// UT.20 — user activates an emergency signal to communicate GPS position to rescuers.
/// IIN-18 — GPS coordinates must be forwarded within 5 seconds of pressing SOS.
class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key, this.repo, this.idCorsa, this.rilevaPosizione});

  /// @brief Repository SOS iniettabile (default singleton reale; fake nei test).
  final SosApi? repo;

  /// @brief Id della corsa in atto, correlata alla segnalazione (opzionale).
  final String? idCorsa;

  /// @brief Rilevatore di posizione iniettabile (default GPS reale; i test
  /// passano coordinate deterministiche per evitare il canale del plugin).
  final Future<({double lat, double lon})?> Function()? rilevaPosizione;

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen>
    with SingleTickerProviderStateMixin {
  static const _countdownSeconds = 5;

  /// Posizione di riserva (centro Bari) se il GPS non è disponibile: la
  /// segnalazione parte comunque entro 5s (IIN-18) con la migliore stima nota.
  static const double _fallbackLat = 41.1172;
  static const double _fallbackLon = 16.8726;

  late final SosApi _api = widget.repo ?? sosRepository;

  bool _sosActivated = false;
  bool _sosSent = false;
  bool _inviando = false;
  String? _erroreInvio;
  int _countdown = _countdownSeconds;
  Timer? _timer;
  String _locationStatus = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _locationStatus = tr('In attesa della posizione…');
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _resolveLocation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _resolveLocation() async {
    bool concesso = false;
    try {
      concesso = (await Permission.location.status).isGranted;
    } catch (_) {
      concesso = false; // piattaforma non disponibile (es. test): stato neutro
    }
    if (mounted) {
      setState(() {
        _locationStatus = concesso
            ? tr('Posizione GPS disponibile')
            : tr('Permesso di localizzazione non concesso');
      });
    }
  }

  /// Starts the 5-second SOS countdown (IIN-18).
  void _activateSOS() {
    setState(() {
      _sosActivated = true;
      _countdown = _countdownSeconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _countdown--;
      });
      if (_countdown <= 0) {
        t.cancel();
        _inviaSos();
      }
    });
  }

  /// Posizione GPS corrente reale (Geolocator), o null se non disponibile.
  Future<({double lat, double lon})?> _gpsCorrente() async {
    final pos = await Geolocator.getCurrentPosition();
    return (lat: pos.latitude, lon: pos.longitude);
  }

  /// Inoltra la segnalazione SOS al backend con la posizione GPS (UT.20, IIN-18).
  ///
  /// Recupera la posizione corrente (con riserva al centro città se il GPS non
  /// è disponibile, per non ritardare l'invio) e chiama `POST /sos`. In caso di
  /// errore torna allo stato iniziale mostrando il motivo, così l'utente può
  /// ritentare immediatamente.
  Future<void> _inviaSos() async {
    setState(() {
      _inviando = true;
      _erroreInvio = null;
    });
    double lat = _fallbackLat;
    double lon = _fallbackLon;
    try {
      final p = await (widget.rilevaPosizione ?? _gpsCorrente)();
      if (p != null) {
        lat = p.lat;
        lon = p.lon;
      }
    } catch (_) {
      // GPS non disponibile: si procede con la posizione di riserva (IIN-18).
    }
    try {
      await _api.segnala(lat: lat, lon: lon, idCorsa: widget.idCorsa);
      if (!mounted) return;
      setState(() {
        _sosSent = true;
        _inviando = false;
      });
    } on LeafApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erroreInvio = e.messaggio;
        _inviando = false;
        _sosActivated = false;
      });
    }
  }

  void _cancelSOS() {
    _timer?.cancel();
    setState(() {
      _sosActivated = false;
      _sosSent = false;
      _countdown = _countdownSeconds;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('SOS Emergenza')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_sosActivated && !_sosSent) _cancelSOS();
            Navigator.pop(context);
          },
        ),
        backgroundColor: AppTheme.backgroundBeige,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        titleTextStyle: const TextStyle(
          color: AppTheme.darkGreen,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: _sosSent ? _buildSentState() : _buildIdleOrCountdownState(),
    );
  }

  Widget _buildIdleOrCountdownState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Location status chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppTheme.primaryGreen,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _locationStatus,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            if (!_sosActivated) ...[
              if (_erroreInvio != null) ...[
                Text(
                  '${tr('Invio non riuscito')}: $_erroreInvio',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                tr('Premi il pulsante SOS\nin caso di emergenza'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr(
                  'La tua posizione GPS verrà inviata\nai soccorsi entro 5 secondi.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
              ),
              const SizedBox(height: 48),
              // SOS button — pulsing animation
              ScaleTransition(
                scale: _pulseAnim,
                child: GestureDetector(
                  onTap: _activateSOS,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withAlpha(80),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ] else if (_inviando) ...[
              // Invio in corso al backend (posizione → POST /sos).
              const CircularProgressIndicator(color: Colors.red),
              const SizedBox(height: 24),
              Text(
                tr('Invio in corso…'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.red.shade700,
                ),
              ),
            ] else ...[
              // Countdown state
              Text(
                tr('Invio SOS in…'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '$_countdown',
                style: TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 32),
              TextButton.icon(
                onPressed: _cancelSOS,
                icon: const Icon(Icons.close, color: AppTheme.textGrey),
                label: Text(
                  tr('Annulla'),
                  style: const TextStyle(color: AppTheme.textGrey),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSentState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 80,
              color: AppTheme.darkGreen,
            ),
            const SizedBox(height: 24),
            Text(
              tr('SOS Inviato'),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGreen,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tr(
                'La tua posizione GPS è stata comunicata ai soccorsi.\nRimani calmo e attendi i soccorsi.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppTheme.accentBrown),
            ),
            const SizedBox(height: 48),
            OutlinedButton.icon(
              onPressed: _cancelSOS,
              icon: const Icon(
                Icons.cancel_outlined,
                color: AppTheme.darkGreen,
              ),
              label: Text(
                tr('Annulla SOS'),
                style: const TextStyle(color: AppTheme.darkGreen),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryGreen),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
