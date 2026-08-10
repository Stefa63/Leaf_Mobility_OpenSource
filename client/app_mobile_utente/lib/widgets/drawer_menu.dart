import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:app_mobile_utente/app_version.dart';
import 'package:app_mobile_utente/theme.dart';
import 'package:app_mobile_utente/screens/sos_screen.dart';
import 'package:app_mobile_utente/screens/history_screen.dart';
import 'package:app_mobile_utente/screens/settings_screen.dart';
import 'package:app_mobile_utente/screens/buy_subscription_screen.dart';
import 'package:app_mobile_utente/screens/my_bookings_screen.dart';
import 'package:app_mobile_utente/screens/support_screen.dart';
import 'package:app_mobile_utente/l10n.dart';

/// Main navigation drawer. Menu items preserve exact labels, icons and routes.
class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    // Translated: il drawer e' un widget `const` agganciato allo Scaffold e non
    // verrebbe ricostruito al cambio di [appLanguage] (Flutter salta il rebuild
    // dei widget const identici). Avvolgendolo, le voci del menu si ritraducono
    // live quando si cambia lingua dalle Impostazioni. IIN-7.
    return Translated((context) {
      return Drawer(
        backgroundColor: AppTheme.backgroundBeige,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textDark),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              // Header: logo + title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/images/fulllogoSVG.svg',
                      width: 40,
                      height: 40,
                      placeholderBuilder: (_) => Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Text(
                        tr('Menù Principale'),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.black12, thickness: 1),
              // Menu items
              ListTile(
                dense: false,
                leading: const Icon(
                  Icons.electric_scooter,
                  color: AppTheme.accentBrown,
                ),
                title: Text(
                  tr('Mie Prenotazioni'),
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textDark),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                  );
                },
              ),
              ListTile(
                dense: false,
                leading: const Icon(Icons.history, color: AppTheme.accentBrown),
                title: Text(
                  tr('Cronologia'),
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textDark),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  );
                },
              ),
              ListTile(
                dense: false,
                leading: const Icon(
                  Icons.card_membership,
                  color: AppTheme.accentBrown,
                ),
                title: Text(
                  tr('Acquista abbonamento'),
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textDark),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BuySubscriptionScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                dense: false,
                leading: const Icon(
                  Icons.settings,
                  color: AppTheme.accentBrown,
                ),
                title: Text(
                  tr('Impostazioni'),
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textDark),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
              ListTile(
                dense: false,
                leading: const Icon(
                  Icons.support_agent,
                  color: AppTheme.accentBrown,
                ),
                title: Text(
                  tr('Supporto'),
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textDark),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SupportScreen()),
                  );
                },
              ),
              const Divider(color: Colors.black12, thickness: 1),
              // SOS emergency entry — UT.20, IIN-18
              ListTile(
                dense: false,
                tileColor: Colors.red.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                leading: const Icon(Icons.sos, color: Colors.red),
                title: Text(
                  tr('SOS Emergenza'),
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SOSScreen()),
                  );
                },
              ),
              const Spacer(),
              const Divider(color: Colors.black12, thickness: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  '${tr('Versione')} $kAppVersion',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
