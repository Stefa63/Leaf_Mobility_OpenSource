import 'package:flutter/material.dart';
import 'package:app_mobile_utente/theme.dart';
import 'package:app_mobile_utente/l10n.dart';

class UnavailableServiceTab extends StatelessWidget {
  final String title;

  const UnavailableServiceTab({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.eco,
            size: 100,
            color: Colors.grey, // sad leaf in grey
          ),
          const SizedBox(height: 24),
          Text(
            tr('Servizio non disponibile'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            appLanguage.value == 'en'
                ? 'The $title section is under development.'
                : 'La sezione $title è in fase di sviluppo.',
            style: const TextStyle(fontSize: 16, color: AppTheme.textGrey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Navigating back to home by replacing with MainLayout which defaults to Home
              Navigator.pushReplacementNamed(context, '/home');
            },
            icon: const Icon(Icons.home),
            label: Text(tr('Torna alla home')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
