import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app_mobile_utente/api/api_client.dart';
import 'package:app_mobile_utente/theme.dart';

/// @brief Schermata di avvio animata di LEAF Mobility.
///
/// Sequenza di caricamento minimalista e immediatamente comprensibile:
///   1. il logo-ruota entra con dissolvenza + scala e poi ruota di continuo,
///      come uno pneumatico che gira ("mezzo in movimento");
///   2. subito sotto, il nome "Leaf Mobility" viene "scritto" lettera per
///      lettera (effetto macchina da scrivere) con cursore lampeggiante;
///   3. una tagline appare in dissolvenza a testo completato;
///   4. al termine dell'attesa l'app naviga alla schermata di login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  /// Nome del brand digitato a video.
  static const String _brand = 'Leaf Mobility';

  /// Animazione d'ingresso (one-shot): dissolvenza + scala del logo.
  late final AnimationController _introCtrl;

  /// Rotazione continua del logo-ruota (loop): "pneumatico che gira".
  late final AnimationController _wheelCtrl;

  /// Effetto macchina da scrivere sul nome del brand.
  late final AnimationController _typeCtrl;

  /// Lampeggio del cursore di scrittura.
  late final AnimationController _caretCtrl;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;

  /// Numero di caratteri del brand attualmente visibili (0 → lunghezza nome).
  late final Animation<int> _typed;

  /// Dissolvenza della tagline, mostrata a testo completato.
  late final Animation<double> _taglineOpacity;

  @override
  void initState() {
    super.initState();

    _introCtrl = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    // La ruota gira di continuo finché la splash è a video.
    _wheelCtrl = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    )..repeat();

    _typeCtrl = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );

    _caretCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    _logoOpacity = CurvedAnimation(parent: _introCtrl, curve: Curves.easeOut);
    _logoScale = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _introCtrl, curve: Curves.easeOutBack));

    _typed = StepTween(
      begin: 0,
      end: _brand.length,
    ).animate(CurvedAnimation(parent: _typeCtrl, curve: Curves.easeOut));

    _taglineOpacity = CurvedAnimation(
      parent: _typeCtrl,
      curve: const Interval(0.85, 1.0, curve: Curves.easeIn),
    );

    _play();
  }

  /// Avvia la sequenza: ingresso logo → scrittura nome → navigazione.
  ///
  /// Al termine dell'animazione verifica se esiste un token di sessione
  /// persistito: se presente naviga direttamente alla home (accesso
  /// persistente), altrimenti alla schermata di login.
  Future<void> _play() async {
    await _introCtrl.forward();
    if (!mounted) return;
    await _typeCtrl.forward();
    if (!mounted) return;
    final token = await apiClient.tokenStore.leggi();
    final destinazione = (token != null && token.isNotEmpty) ? '/home' : '/login';
    Timer(const Duration(milliseconds: 700), () {
      if (mounted) Navigator.pushReplacementNamed(context, destinazione);
    });
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _wheelCtrl.dispose();
    _typeCtrl.dispose();
    _caretCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildWheel(),
              const SizedBox(height: 28),
              _buildTypedBrand(),
              const SizedBox(height: 10),
              _buildTagline(),
            ],
          ),
        ),
      ),
    );
  }

  /// Logo-ruota: entra in dissolvenza + scala, poi ruota di continuo.
  Widget _buildWheel() {
    return FadeTransition(
      opacity: _logoOpacity,
      child: ScaleTransition(
        scale: _logoScale,
        child: RotationTransition(
          turns: _wheelCtrl,
          child: SvgPicture.asset(
            'assets/images/fulllogoSVG.svg',
            width: 128,
            height: 128,
            placeholderBuilder: (_) => Container(
              width: 128,
              height: 128,
              decoration: const BoxDecoration(
                color: AppTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Nome del brand "scritto" lettera per lettera con cursore lampeggiante.
  Widget _buildTypedBrand() {
    return AnimatedBuilder(
      animation: Listenable.merge([_typed, _caretCtrl]),
      builder: (context, _) {
        final shown = _brand.substring(0, _typed.value);
        final typing = _typeCtrl.isAnimating || _typeCtrl.value < 1.0;
        // Cursore: lampeggia durante la scrittura, scompare a testo completato.
        final caretOpacity = typing ? _caretCtrl.value : 0.0;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              shown,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGreen,
                letterSpacing: 1.5,
              ),
            ),
            Opacity(
              opacity: caretOpacity,
              child: Container(
                width: 2.5,
                height: 26,
                margin: const EdgeInsets.only(left: 3, bottom: 2),
                color: AppTheme.primaryGreen,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Tagline in dissolvenza, visibile a nome completato.
  Widget _buildTagline() {
    return FadeTransition(
      opacity: _taglineOpacity,
      child: const Text(
        'Smart Mobility',
        style: TextStyle(
          fontSize: 13,
          color: AppTheme.textGrey,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
