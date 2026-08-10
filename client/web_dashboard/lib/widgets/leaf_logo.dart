import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:web_dashboard/theme.dart';

/// @brief Logo ufficiale LEAF Mobility.
///
/// Renderizza l'asset vettoriale `fulllogoSVG.svg` — lo stesso identico file
/// usato da [AppMobileUtente] (splash, login, drawer) — per garantire piena
/// coerenza di brand tra i due client. Reso via [flutter_svg], nitido a
/// qualunque dimensione.
class LeafLogo extends StatelessWidget {
  /// Lato in pixel logici del marchio (l'SVG e' quadrato).
  final double size;

  /// Se true affianca il wordmark testuale "LEAF Mobility".
  final bool showWordmark;

  const LeafLogo({super.key, this.size = 40, this.showWordmark = false});

  static const String _asset = 'assets/images/fulllogoSVG.svg';

  @override
  Widget build(BuildContext context) {
    final mark = SvgPicture.asset(
      _asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticsLabel: 'LEAF Mobility',
    );

    if (!showWordmark) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: size * 0.3),
        Text(
          'LEAF Mobility',
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkGreen,
          ),
        ),
      ],
    );
  }
}
