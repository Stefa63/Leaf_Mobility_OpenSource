import 'package:flutter/material.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/theme.dart';

/// @brief Pulsante azione rapida dei pannelli laterali OP/AP.
///
/// Se [onPressed] e' fornito esegue l'azione collegata (apertura dialog o
/// navigazione a una sezione); altrimenti mostra un feedback "in sviluppo": il
/// comando reale passera' per l'`api_gateway_sicurezza` quando il server sara'
/// disponibile.
class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  /// Azione collegata; se null il pulsante mostra il feedback pre-backend.
  final VoidCallback? onPressed;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.accent,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: accent,
            side: BorderSide(color: accent.withAlpha(90)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            alignment: Alignment.centerLeft,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: Icon(icon, size: 18),
          label: Text(
            tr(label),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          onPressed: onPressed ??
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppTheme.accentBrown,
                    content: Text(
                      '${tr(label)} — ${tr('Funzione disponibile con il backend')}',
                    ),
                  ),
                );
              },
        ),
      ),
    );
  }
}

/// @brief Tile di un allarme/notifica nella coda real-time dell'Operatore.
class AlarmTile extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;

  /// @brief Azione opzionale al tocco della tessera (es. presa in carico SOS, OP.08).
  final VoidCallback? onTap;

  const AlarmTile({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final contenuto = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right, color: AppTheme.textGrey, size: 20),
        ],
      ),
    );
    if (onTap == null) return contenuto;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: contenuto,
    );
  }
}

/// @brief Intestazione di sezione (titolo + sottotitolo opzionale).
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SectionHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(title),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            tr(subtitle!),
            style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
          ),
        ],
      ],
    );
  }
}

/// @brief Card pannello generica con titolo e contenuto.
class PanelCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final Widget child;

  const PanelCard({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: accent),
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
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
