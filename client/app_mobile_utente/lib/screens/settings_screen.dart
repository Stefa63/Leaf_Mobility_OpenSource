import 'package:flutter/material.dart';
import 'package:app_mobile_utente/app_version.dart';
import 'package:app_mobile_utente/theme.dart';
import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/settings_store.dart';
import 'package:app_mobile_utente/screens/dev_mode_screen.dart';

/// @brief Schermata Impostazioni dell'app utente.
///
/// Raccoglie le impostazioni principali di un'app per mezzi a noleggio:
/// lingua (IIN-7), notifiche (IIN-19), privacy/posizione (IIN-16), sicurezza
/// (IIN-5) e informazioni. Per scelta di progetto NON e' previsto un tema
/// scuro. Le preferenze sono osservate da [AppSettings] e si ridisegnano live
/// al cambio lingua tramite [Translated].
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundBeige,
        appBar: AppBar(
          title: Text(
            tr('Impostazioni'),
            style: const TextStyle(color: AppTheme.darkGreen),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // ── Lingua ─────────────────────────────────────────────────
              _SectionTitle(tr('Lingua')),
              const SizedBox(height: 12),
              _languageCard(),
              const SizedBox(height: 24),

              // ── Notifiche ──────────────────────────────────────────────
              _SectionTitle(tr('Notifiche')),
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _SwitchSetting(
                    notifier: AppSettings.pushNotifications,
                    icon: Icons.notifications_active_outlined,
                    title: tr('Notifiche push'),
                    subtitle: tr('Ricevi avvisi importanti sul tuo noleggio.'),
                  ),
                  const _SettingsDivider(),
                  _SwitchSetting(
                    notifier: AppSettings.bookingReminders,
                    icon: Icons.timer_outlined,
                    title: tr('Promemoria prenotazione'),
                    subtitle: tr('Avviso prima della scadenza della riserva.'),
                  ),
                  const _SettingsDivider(),
                  _SwitchSetting(
                    notifier: AppSettings.promoNotifications,
                    icon: Icons.local_offer_outlined,
                    title: tr('Promozioni e offerte'),
                    subtitle: tr('Sconti e novità sul servizio.'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Privacy e posizione ────────────────────────────────────
              _SectionTitle(tr('Privacy e posizione')),
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _SwitchSetting(
                    notifier: AppSettings.locationServices,
                    icon: Icons.my_location_outlined,
                    title: tr('Servizi di localizzazione'),
                    subtitle: tr(
                      'Necessari per trovare e sbloccare i mezzi vicini.',
                    ),
                  ),
                  const _SettingsDivider(),
                  _SwitchSetting(
                    notifier: AppSettings.usageDataSharing,
                    icon: Icons.bar_chart_outlined,
                    title: tr('Condivisione dati di utilizzo'),
                    subtitle: tr(
                      'Dati anonimi e aggregati per migliorare il servizio.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Informazioni ───────────────────────────────────────────
              _SectionTitle(tr('Informazioni')),
              const SizedBox(height: 12),
              _SettingsCard(
                children: [
                  _NavSetting(
                    icon: Icons.description_outlined,
                    title: tr('Termini di servizio'),
                    onTap: () => _showStub(context),
                  ),
                  const _SettingsDivider(),
                  _NavSetting(
                    icon: Icons.privacy_tip_outlined,
                    title: tr('Informativa sulla privacy'),
                    onTap: () => _showStub(context),
                  ),
                  const _SettingsDivider(),
                  _InfoSetting(
                    icon: Icons.info_outline,
                    title: tr('Versione'),
                    value: kAppVersion,
                  ),
                  const _SettingsDivider(),
                  _NavSetting(
                    icon: Icons.developer_mode,
                    title: tr('Modalità sviluppatore'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const DevModeScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Card di selezione della lingua (Italiano / English). IIN-7.
  Widget _languageCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ValueListenableBuilder<String>(
        valueListenable: appLanguage,
        builder: (context, currentLanguage, child) {
          return RadioGroup<String>(
            groupValue: currentLanguage,
            onChanged: (value) {
              if (value != null) {
                appLanguage.value = value;
              }
            },
            child: Column(
              children: [
                RadioListTile<String>(
                  title: Row(
                    children: [
                      const Text('🇮🇹', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Text(
                        tr('Italiano'),
                        style: const TextStyle(color: AppTheme.textDark),
                      ),
                    ],
                  ),
                  value: 'it',
                  activeColor: AppTheme.primaryGreen,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                RadioListTile<String>(
                  title: Row(
                    children: [
                      const Text('🇬🇧', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Text(
                        tr('English'),
                        style: const TextStyle(color: AppTheme.textDark),
                      ),
                    ],
                  ),
                  value: 'en',
                  activeColor: AppTheme.primaryGreen,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Mostra un avviso temporaneo per le sezioni informative non ancora pronte.
  void _showStub(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('Sezione in fase di sviluppo.')),
        backgroundColor: AppTheme.accentBrown,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

/// Titolo di sezione delle impostazioni.
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: AppTheme.darkGreen,
    ),
  );
}

/// Contenitore-card che raggruppa più righe di impostazione.
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }
}

/// Divisore sottile tra righe di impostazione.
class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 16, endIndent: 16);
}

/// Riga di impostazione con interruttore booleano osservabile.
class _SwitchSetting extends StatelessWidget {
  final ValueNotifier<bool> notifier;
  final IconData icon;
  final String title;
  final String subtitle;
  const _SwitchSetting({
    required this.notifier,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, value, _) {
        return SwitchListTile(
          value: value,
          onChanged: (v) => notifier.value = v,
          activeThumbColor: AppTheme.primaryGreen,
          secondary: Icon(icon, color: AppTheme.accentBrown),
          title: Text(
            title,
            style: const TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
          ),
        );
      },
    );
  }
}

/// Riga di impostazione che apre una sotto-sezione.
class _NavSetting extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _NavSetting({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.accentBrown),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textDark,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textGrey),
      onTap: onTap,
    );
  }
}

/// Riga informativa in sola lettura (es. versione app).
class _InfoSetting extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _InfoSetting({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.accentBrown),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textDark,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      trailing: Text(
        value,
        style: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
      ),
    );
  }
}
