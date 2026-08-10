import 'package:flutter/material.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/theme.dart';

/// @brief Selettore lingua ITA/ENG. IIN-7.
///
/// Aggiorna [appLanguage]: tutte le viste avvolte in [Translated] si
/// ridisegnano live nella lingua scelta.
class LangToggle extends StatelessWidget {
  const LangToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLanguage,
      builder: (context, lang, _) {
        Widget seg(String code, String label) {
          final selected = lang == code;
          return GestureDetector(
            onTap: () => appLanguage.value = code,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primaryGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : AppTheme.textGrey,
                ),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black12),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 4),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [seg('it', 'ITA'), seg('en', 'ENG')],
          ),
        );
      },
    );
  }
}
