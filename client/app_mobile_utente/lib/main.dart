import 'package:flutter/material.dart';
import 'package:app_mobile_utente/theme.dart';
import 'package:app_mobile_utente/screens/splash_screen.dart';
import 'package:app_mobile_utente/screens/login_screen.dart';
import 'package:app_mobile_utente/screens/main_layout.dart';

import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/profile_store.dart';
import 'package:app_mobile_utente/dev_settings_store.dart';
import 'package:app_mobile_utente/api/api_client.dart';

Future<void> main() async {
  // Necessario prima di usare i plugin (SharedPreferences) in fase di avvio.
  WidgetsFlutterBinding.ensureInitialized();
  // Ripristina i dati di profilo persistiti localmente sul dispositivo. UT.21.
  await ProfileStore.load();
  // Ripristina le preferenze di sviluppo e, se attive, ripunta il client di rete
  // all'eventuale server LAN configurato + abilita il log verboso (debug USB).
  await DevSettings.load();
  apiClient.applicaBaseUrl(DevSettings.apiBaseEffettivo);
  apiClient.abilitaLogVerboso(DevSettings.abilitata.value);
  runApp(const LeafMobilityApp());
}

class LeafMobilityApp extends StatelessWidget {
  const LeafMobilityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLanguage,
      builder: (context, lang, child) {
        return MaterialApp(
          title: 'Leaf Mobility',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const MainLayout(),
          },
        );
      },
    );
  }
}
