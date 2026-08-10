import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/theme.dart';
import 'package:web_dashboard/widgets/common.dart';
import 'package:web_dashboard/screens/change_password_screen.dart';
import 'package:web_dashboard/api/auth_repository.dart';

/// @brief Schermata Impostazioni per OP e AP.
///
/// Raggiunta dalla tendina del profilo in alto a destra. Raccoglie le
/// preferenze utili alla console: lingua, accessibilita' (testo ingrandito),
/// preferenze di notifica, cadenza di aggiornamento delle dashboard e
/// privacy/GDPR. La modifica del tema/colori non e' consentita. Le preferenze
/// sono persistite localmente con `shared_preferences` (localStorage su web) e
/// ricaricate all'avvio; la persistenza lato server passera' per
/// `gestore_profili_ekyc` / `api_gateway_sicurezza`.
class SettingsScreen extends StatefulWidget {
  /// Colore di accento del ruolo attivo (OP blu / AP teal).
  final Color accent;

  const SettingsScreen({super.key, required this.accent});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Preferenze locali, persistite via shared_preferences (localStorage su web).
  bool _largeText = false;
  bool _notifCritical = true;
  bool _notifLogistics = true;
  bool _notifEmailDigest = false;
  bool _notifSound = true;
  bool _geoConsent = true;
  int _refreshSeconds = 5;

  /// Archivio delle preferenze; null finché il caricamento non è completato.
  SharedPreferences? _prefs;

  // Chiavi di persistenza delle preferenze della console.
  static const String _kLargeText = 'impostazioni.testo_ingrandito';
  static const String _kNotifCritical = 'impostazioni.notifiche_critiche';
  static const String _kNotifLogistics = 'impostazioni.notifiche_logistiche';
  static const String _kNotifEmailDigest = 'impostazioni.notifiche_email';
  static const String _kNotifSound = 'impostazioni.notifiche_suono';
  static const String _kGeoConsent = 'impostazioni.consenso_geo';
  static const String _kRefreshSeconds = 'impostazioni.refresh_secondi';

  @override
  void initState() {
    super.initState();
    _caricaPreferenze();
  }

  /// @brief Carica le preferenze persistite e aggiorna la vista.
  ///
  /// Eseguita all'avvio: legge i valori salvati (se presenti) mantenendo i
  /// default per le chiavi assenti, così le scelte sopravvivono al riavvio.
  Future<void> _caricaPreferenze() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _largeText = prefs.getBool(_kLargeText) ?? _largeText;
      _notifCritical = prefs.getBool(_kNotifCritical) ?? _notifCritical;
      _notifLogistics = prefs.getBool(_kNotifLogistics) ?? _notifLogistics;
      _notifEmailDigest = prefs.getBool(_kNotifEmailDigest) ?? _notifEmailDigest;
      _notifSound = prefs.getBool(_kNotifSound) ?? _notifSound;
      _geoConsent = prefs.getBool(_kGeoConsent) ?? _geoConsent;
      _refreshSeconds = prefs.getInt(_kRefreshSeconds) ?? _refreshSeconds;
    });
  }

  /// @brief Persiste una preferenza booleana (no-op se l'archivio non è pronto).
  void _salvaBool(String chiave, bool valore) => _prefs?.setBool(chiave, valore);

  /// @brief Persiste una preferenza numerica (no-op se l'archivio non è pronto).
  void _salvaInt(String chiave, int valore) => _prefs?.setInt(chiave, valore);

  void _feedback(String key) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.accentBrown,
        content: Text('${tr(key)} — ${tr('Funzione disponibile con il backend')}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Impostazioni',
              subtitle: 'Preferenze della console',
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, c) {
                final narrow = c.maxWidth < 900;
                final left = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _languageCard(),
                    const SizedBox(height: 18),
                    _accessibilityCard(),
                    const SizedBox(height: 18),
                    _securityCard(),
                  ],
                );
                final right = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _notificationsCard(),
                    const SizedBox(height: 18),
                    _dataPrivacyCard(),
                  ],
                );
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [left, const SizedBox(height: 18), right],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: left),
                    const SizedBox(width: 18),
                    Expanded(child: right),
                  ],
                );
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _languageCard() {
    Widget option(String code, String label) {
      final selected = appLanguage.value == code;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => appLanguage.value = code),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: selected ? widget.accent : AppTheme.textGrey,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PanelCard(
      title: 'Lingua',
      icon: Icons.translate,
      accent: widget.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr('Lingua dell\'interfaccia'),
            style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
          ),
          const SizedBox(height: 6),
          option('it', 'Italiano'),
          option('en', 'English'),
        ],
      ),
    );
  }

  Widget _accessibilityCard() {
    return PanelCard(
      title: 'Aspetto e Accessibilità',
      icon: Icons.accessibility_new,
      accent: widget.accent,
      child: Column(
        children: [
          _switchTile(
            icon: Icons.format_size,
            label: 'Testo ingrandito',
            subtitle: 'Aumenta la dimensione dei caratteri',
            value: _largeText,
            onChanged: (v) {
              setState(() => _largeText = v);
              _salvaBool(_kLargeText, v);
            },
          ),
        ],
      ),
    );
  }

  Widget _securityCard() {
    return PanelCard(
      title: 'Sicurezza Account',
      icon: Icons.security,
      accent: widget.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr('Impostazioni di accesso e sicurezza'),
            style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangePasswordScreen(auth: authRepository),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: widget.accent,
              side: BorderSide(color: widget.accent.withAlpha(90)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.password_outlined, size: 18),
            label: Text(tr('Cambia password')),
          ),
        ],
      ),
    );
  }

  Widget _notificationsCard() {
    return PanelCard(
      title: 'Notifiche',
      icon: Icons.notifications_active_outlined,
      accent: widget.accent,
      child: Column(
        children: [
          _switchTile(
            icon: Icons.priority_high,
            label: 'Allarmi critici (SOS, fuori area)',
            subtitle: 'Notifiche push immediate',
            value: _notifCritical,
            onChanged: (v) {
              setState(() => _notifCritical = v);
              _salvaBool(_kNotifCritical, v);
            },
          ),
          _switchTile(
            icon: Icons.inventory_2_outlined,
            label: 'Avvisi logistici e soglie',
            subtitle: 'Batteria, ricollocamento, soglie minime',
            value: _notifLogistics,
            onChanged: (v) {
              setState(() => _notifLogistics = v);
              _salvaBool(_kNotifLogistics, v);
            },
          ),
          _switchTile(
            icon: Icons.mark_email_unread_outlined,
            label: 'Riepilogo giornaliero via email',
            subtitle: 'Digest delle attività alle 20:00',
            value: _notifEmailDigest,
            onChanged: (v) {
              setState(() => _notifEmailDigest = v);
              _salvaBool(_kNotifEmailDigest, v);
            },
          ),
          _switchTile(
            icon: Icons.volume_up_outlined,
            label: 'Suoni di notifica',
            subtitle: 'Segnale acustico per gli allarmi',
            value: _notifSound,
            onChanged: (v) {
              setState(() => _notifSound = v);
              _salvaBool(_kNotifSound, v);
            },
          ),
        ],
      ),
    );
  }

  Widget _dataPrivacyCard() {
    return PanelCard(
      title: 'Dati e Privacy',
      icon: Icons.privacy_tip_outlined,
      accent: widget.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.refresh, size: 18, color: AppTheme.textGrey),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tr('Frequenza aggiornamento dashboard'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              DropdownButton<int>(
                value: _refreshSeconds,
                underline: const SizedBox.shrink(),
                borderRadius: BorderRadius.circular(12),
                style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
                items: const [3, 5, 10]
                    .map((s) => DropdownMenuItem<int>(
                          value: s,
                          child: Text('$s s'),
                        ))
                    .toList(),
                onChanged: (v) {
                  final s = v ?? _refreshSeconds;
                  setState(() => _refreshSeconds = s);
                  _salvaInt(_kRefreshSeconds, s);
                },
              ),
            ],
          ),
          const Divider(height: 22),
          _switchTile(
            icon: Icons.my_location_outlined,
            label: 'Consenso geolocalizzazione',
            subtitle: 'Necessario per la mappa flotta (GDPR)',
            value: _geoConsent,
            onChanged: (v) {
              setState(() => _geoConsent = v);
              _salvaBool(_kGeoConsent, v);
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _feedback('Esporta i miei dati'),
            style: OutlinedButton.styleFrom(
              foregroundColor: widget.accent,
              side: BorderSide(color: widget.accent.withAlpha(90)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.download_outlined, size: 18),
            label: Text(tr('Esporta i miei dati')),
          ),
        ],
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(label),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tr(subtitle),
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textGrey),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: widget.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
