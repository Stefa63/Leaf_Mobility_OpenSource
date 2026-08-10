import 'package:flutter/material.dart';
import 'package:web_dashboard/theme.dart';

/// @brief Card metrica della dashboard (titolo + righe valore/etichetta).
///
/// Blocco visivo riusato dalle home di OP e AP per le metriche in tempo reale
/// (refresh ≤ 5s, IIN-20). Niente logica di business: pura presentazione.
class MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accent;
  final List<Widget> children;

  const MetricCard({
    super.key,
    required this.icon,
    required this.title,
    required this.accent,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withAlpha(28),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// @brief Riga "pallino colorato + etichetta + valore" per le card metrica.
class MetricRow extends StatelessWidget {
  final Color dot;
  final String label;
  final String value;

  const MetricRow({
    super.key,
    required this.dot,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// @brief Grande numero con etichetta sottostante (KPI singolo).
class BigStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const BigStat({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
        ),
      ],
    );
  }
}
