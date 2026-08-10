import 'package:flutter/material.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/screens/home_router.dart';
import 'package:web_dashboard/screens/login_screen.dart';
import 'package:web_dashboard/theme.dart';

/// Punto di ingresso della WebDashboard (Flutter Web) per OP e AP.
void main() {
  runApp(const LeafDashboardApp());
}

/// @brief Applicazione WebDashboard LEAF Mobility.
///
/// Accesso protetto da MFA (IIN-9) tramite un'unica schermata di login per OP e
/// AP; dopo l'accesso il [HomeRouter] mostra la console del ruolo scelto.
/// Internazionalizzazione IT/EN live via [appLanguage] (IIN-7).
class LeafDashboardApp extends StatelessWidget {
  const LeafDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLanguage,
      builder: (context, lang, child) {
        return MaterialApp(
          title: 'LEAF Mobility — Dashboard',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          initialRoute: '/login',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeRouter(),
          },
        );
      },
    );
  }
}
