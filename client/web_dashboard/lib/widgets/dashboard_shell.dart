import 'package:flutter/material.dart';
import 'package:web_dashboard/api/auth_repository.dart';
import 'package:web_dashboard/data/notifications_store.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/theme.dart';
import 'package:web_dashboard/widgets/lang_toggle.dart';
import 'package:web_dashboard/widgets/leaf_logo.dart';

/// @brief Voce del menu laterale: icona, etichetta (chiave i18n) e contenuto.
@immutable
class DashboardSection {
  final IconData icon;
  final String label;
  final WidgetBuilder builder;

  const DashboardSection({
    required this.icon,
    required this.label,
    required this.builder,
  });
}

/// Viste raggiungibili dalla top bar (fuori dal menu laterale).
enum _TopView { none, profile, notifications, settings }

/// @brief Accesso alla navigazione dello [DashboardShell] dai discendenti.
///
/// Espone alla sottostante gerarchia (es. i pannelli rapidi nella home) il
/// cambio di sezione del menu laterale, senza introdurre pattern MVC: e' un
/// semplice [InheritedWidget]. Usare [jumpTo] con l'indice o, piu' comodo,
/// [indexOfLabel] per risolvere l'indice dalla chiave i18n della voce di menu.
class DashboardScope extends InheritedWidget {
  /// Apre la sezione del menu laterale all'indice indicato.
  final void Function(int index) jumpTo;

  /// Indice della sezione con la [label] data, o -1 se assente.
  final int Function(String label) indexOfLabel;

  const DashboardScope({
    super.key,
    required this.jumpTo,
    required this.indexOfLabel,
    required super.child,
  });

  static DashboardScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DashboardScope>();

  /// Risolve [label] e, se presente, apre la relativa sezione.
  void jumpToLabel(String label) {
    final i = indexOfLabel(label);
    if (i >= 0) jumpTo(i);
  }

  @override
  bool updateShouldNotify(DashboardScope oldWidget) => false;
}

/// @brief Telaio comune delle console OP/AP: top navigation bar + side menu.
///
/// La stessa impalcatura serve entrambi i ruoli; cambiano [sections], colore
/// [accent] e profilo. La tendina del profilo (in alto a destra) apre gestione
/// profilo o impostazioni; la campana apre il centro notifiche con badge "non
/// lette" alimentato live da [NotificationsStore]. Refresh metriche dichiarato a
/// 5s in barra (IIN-20).
class DashboardShell extends StatefulWidget {
  final Color accent;
  final List<DashboardSection> sections;
  final String profileLabel;

  /// Contenuto della schermata "Gestione Profilo" (tendina in alto a destra).
  final WidgetBuilder profileBuilder;

  /// Contenuto del centro notifiche (campana in alto a destra).
  final WidgetBuilder notificationsBuilder;

  /// Contenuto della schermata "Impostazioni" (tendina in alto a destra).
  final WidgetBuilder settingsBuilder;

  /// Repository di autenticazione per il logout (default reale; fittizio nei test).
  final AuthApi? auth;

  const DashboardShell({
    super.key,
    required this.accent,
    required this.sections,
    required this.profileLabel,
    required this.profileBuilder,
    required this.notificationsBuilder,
    required this.settingsBuilder,
    this.auth,
  });

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _selected = 0;
  _TopView _topView = _TopView.none;

  void _openSection(int i) => setState(() {
        _selected = i;
        _topView = _TopView.none;
      });

  /// Indice della prima sezione con la chiave i18n [label], o -1 se assente.
  int _indexOfLabel(String label) =>
      widget.sections.indexWhere((s) => s.label == label);

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return DashboardScope(
        jumpTo: _openSection,
        indexOfLabel: _indexOfLabel,
        child: Scaffold(
          backgroundColor: AppTheme.backgroundBeige,
          body: Column(
            children: [
              _topBar(context),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sideMenu(),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: _content(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _content(BuildContext context) {
    switch (_topView) {
      case _TopView.profile:
        return widget.profileBuilder(context);
      case _TopView.notifications:
        return widget.notificationsBuilder(context);
      case _TopView.settings:
        return widget.settingsBuilder(context);
      case _TopView.none:
        return widget.sections[_selected].builder(context);
    }
  }

  Widget _topBar(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            const LeafLogo(size: 34, showWordmark: true),
            const Spacer(),
            const LangToggle(),
            const SizedBox(width: 16),
            _mfaBadge(),
            const SizedBox(width: 16),
            _alarmsBell(),
            const SizedBox(width: 16),
            _profileMenu(context),
          ],
        ),
      ),
    );
  }

  Widget _mfaBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield, size: 15, color: AppTheme.darkGreen),
          const SizedBox(width: 6),
          Text(
            tr('MFA: Attivo'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _alarmsBell() {
    final selected = _topView == _TopView.notifications;
    // Badge "non lette" live dallo store condiviso: leggere nel centro
    // notifiche lo azzera immediatamente (fix campana "sempre 3").
    return Tooltip(
      message: tr('Notifiche'),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _topView = _TopView.notifications),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: ValueListenableBuilder<int>(
            valueListenable: NotificationsStore.revision,
            builder: (context, _, _) {
              final unread = NotificationsStore.unreadCount;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: selected ? widget.accent : AppTheme.textDark,
                  ),
                  if (unread > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.alarmCritical,
                          shape: BoxShape.circle,
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$unread',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// @brief Esegue il logout reale e torna alla schermata di login.
  ///
  /// Chiama `AuthApi.esci()` (POST `/auth/logout` + cancellazione del token
  /// custodito): best-effort sulla rete, ma il token locale è sempre rimosso.
  /// La navigazione verso `/login` avviene comunque al termine.
  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    await (widget.auth ?? authRepository).esci();
    if (!mounted) return;
    navigator.pushReplacementNamed('/login');
  }

  Widget _profileMenu(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: widget.profileLabel,
      onSelected: (v) {
        switch (v) {
          case 'profile':
            setState(() => _topView = _TopView.profile);
          case 'settings':
            setState(() => _topView = _TopView.settings);
          case 'logout':
            _logout(context);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              const Icon(Icons.manage_accounts_outlined,
                  size: 18, color: AppTheme.textDark),
              const SizedBox(width: 10),
              Text(tr('Gestione Profilo')),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              const Icon(Icons.settings_outlined,
                  size: 18, color: AppTheme.textDark),
              const SizedBox(width: 10),
              Text(tr('Impostazioni')),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout, size: 18, color: AppTheme.textDark),
              const SizedBox(width: 10),
              Text(tr('Logout')),
            ],
          ),
        ),
      ],
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: widget.accent.withAlpha(40),
            child: Icon(Icons.person, size: 18, color: widget.accent),
          ),
          const SizedBox(width: 8),
          Text(
            widget.profileLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: AppTheme.textGrey),
        ],
      ),
    );
  }

  Widget _sideMenu() {
    return Container(
      width: 248,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: widget.sections.length,
              itemBuilder: (context, i) {
                final s = widget.sections[i];
                final selected = i == _selected && _topView == _TopView.none;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Material(
                    color: selected
                        ? widget.accent.withAlpha(24)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _openSection(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              s.icon,
                              size: 20,
                              color: selected
                                  ? widget.accent
                                  : AppTheme.textGrey,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                tr(s.label),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: selected
                                      ? widget.accent
                                      : AppTheme.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  tr('Aggiornamento ogni 5s'),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// @brief Segnaposto per le sezioni non ancora collegate al backend.
class SectionPlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;

  const SectionPlaceholder({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppTheme.textGrey.withAlpha(120)),
            const SizedBox(height: 16),
            Text(
              tr(title),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr('Sezione in sviluppo. Sarà collegata al server.'),
              style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
            ),
          ],
        ),
      );
    });
  }
}
