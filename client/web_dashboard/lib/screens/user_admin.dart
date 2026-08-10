import 'package:flutter/material.dart';
import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/api_config.dart';
import 'package:web_dashboard/data/users_admin_data.dart';
import 'package:web_dashboard/data/users_admin_store.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/theme.dart';
import 'package:web_dashboard/widgets/common.dart';

/// @brief Gestione Utenti e Amministratori Pubblici (OP.10 / OP.17 / OP.18).
///
/// Due viste commutabili: gli account utente (sospensione per violazioni — OP.10
/// — e riattivazione manuale — OP.18) e gli account di Amministrazione Pubblica,
/// creati esclusivamente dall'Operatore tramite provisioning (OP.17, niente
/// registrazioni pubbliche; primo accesso con cambio password obbligatorio,
/// IIN-12). I dati sono alimentati da `/api/v1/utenti` tramite [UsersAdminStore]
/// (fallback ai dati di riserva senza rete, IIN-6).
class UserAdmin extends StatefulWidget {
  const UserAdmin({super.key, this.autoload = true});

  /// @brief Se true (default), carica i dati reali all'apertura; i test lo disattivano.
  final bool autoload;

  @override
  State<UserAdmin> createState() => _UserAdminState();
}

class _UserAdminState extends State<UserAdmin> {
  bool _showAp = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (widget.autoload && kAutoloadData) UsersAdminStore.carica();
  }

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'Gestione Utenti/AP',
                  subtitle: 'Account utenti e provisioning Amministrazione',
                ),
              ),
              if (_showAp)
                ElevatedButton.icon(
                  onPressed: _apriProvisioning,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(tr('Crea Account AP')),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _segmented(),
          const SizedBox(height: 16),
          if (!_showAp) _searchField(),
          if (!_showAp) const SizedBox(height: 12),
          _offlineBanner(),
          Expanded(child: _showAp ? _apList() : _userList()),
        ],
      );
    });
  }

  Widget _offlineBanner() {
    return ValueListenableBuilder<bool>(
      valueListenable: UsersAdminStore.offline,
      builder: (context, offline, _) {
        if (!offline) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const Icon(
                Icons.cloud_off,
                size: 15,
                color: AppTheme.alarmWarning,
              ),
              const SizedBox(width: 6),
              Text(
                tr('Dati non aggiornati: backend non raggiungibile'),
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.alarmWarning,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _segmented() {
    Widget seg(String label, IconData icon, bool ap) {
      final selected = _showAp == ap;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _showAp = ap),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? AppTheme.opAccent.withAlpha(24) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? AppTheme.opAccent : Colors.black12,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? AppTheme.opAccent : AppTheme.textGrey,
                ),
                const SizedBox(width: 8),
                Text(
                  tr(label),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    color: selected ? AppTheme.opAccent : AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        seg('Utenti', Icons.people_outline, false),
        const SizedBox(width: 12),
        seg('Account AP', Icons.account_balance_outlined, true),
      ],
    );
  }

  Widget _searchField() {
    return TextField(
      onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
      decoration: InputDecoration(
        hintText: tr('Cerca per ID, nome, username o email'),
        prefixIcon: const Icon(Icons.search, size: 20),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _userList() {
    return ValueListenableBuilder<List<ManagedUser>>(
      valueListenable: UsersAdminStore.users,
      builder: (context, utenti, _) {
        final list = utenti.where((u) {
          if (_query.isEmpty) return true;
          return u.id.toLowerCase().contains(_query) ||
              u.name.toLowerCase().contains(_query) ||
              u.username.toLowerCase().contains(_query) ||
              u.email.toLowerCase().contains(_query);
        }).toList();
        if (list.isEmpty) {
          return Center(
            child: Text(
              tr('Nessun utente trovato'),
              style: const TextStyle(color: AppTheme.textGrey),
            ),
          );
        }
        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _userCard(list[i]),
        );
      },
    );
  }

  Widget _userCard(ManagedUser u) {
    final suspended = u.status == UserStatus.sospeso;
    final statusColor = suspended
        ? AppTheme.alarmCritical
        : AppTheme.statusAvailable;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.opAccent.withAlpha(28),
              child: const Icon(Icons.person, color: AppTheme.opAccent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          u.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        u.username.isNotEmpty ? '@${u.username}' : '· ${u.id}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.opAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    u.email,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textGrey,
                    ),
                  ),
                  if (suspended && u.note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      tr(u.note),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.alarmCritical,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _statusBadge(suspended ? 'Sospeso' : 'Attivo', statusColor),
            const SizedBox(width: 8),
            suspended
                ? TextButton.icon(
                    onPressed: () => _cambiaStato(u, sospendi: false),
                    icon: const Icon(Icons.lock_open, size: 16),
                    label: Text(tr('Riattiva')),
                  )
                : TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.alarmCritical,
                    ),
                    onPressed: () => _cambiaStato(u, sospendi: true),
                    icon: const Icon(Icons.person_off, size: 16),
                    label: Text(tr('Sospendi')),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _apList() {
    return ValueListenableBuilder<List<ApAccount>>(
      valueListenable: UsersAdminStore.apAccounts,
      builder: (context, account, _) {
        if (account.isEmpty) {
          return Center(
            child: Text(
              tr('Nessun account AP'),
              style: const TextStyle(color: AppTheme.textGrey),
            ),
          );
        }
        return ListView.separated(
          itemCount: account.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _apCard(account[i]),
        );
      },
    );
  }

  Widget _apCard(ApAccount a) {
    final pending = a.status == ApStatus.primoAccesso;
    final color = pending ? AppTheme.alarmWarning : AppTheme.statusAvailable;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.apAccent.withAlpha(28),
              child: const Icon(Icons.account_balance, color: AppTheme.apAccent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          a.ente,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '· ${a.id}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    a.email,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            _statusBadge(
              pending ? 'Primo accesso in attesa' : 'Attivo',
              color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            tr(label),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// @brief Sospende/riattiva un account via API, con feedback d'errore (OP.10/OP.18).
  Future<void> _cambiaStato(ManagedUser u, {required bool sospendi}) async {
    try {
      await UsersAdminStore.impostaStato(u.id, sospendi: sospendi);
    } on LeafApiException catch (e) {
      if (mounted) _avviso(e.messaggio);
    }
  }

  /// @brief Apre il dialog di provisioning di un nuovo account AP (OP.17).
  Future<void> _apriProvisioning() async {
    final emailCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final enteCtrl = TextEditingController();
    final emailIstCtrl = TextEditingController();
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Crea Account AP')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _campo(enteCtrl, 'Ente'),
              _campo(usernameCtrl, 'Username'),
              _campo(emailCtrl, 'Email'),
              _campo(emailIstCtrl, 'Email istituzionale'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('Annulla')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('Crea')),
          ),
        ],
      ),
    );
    if (conferma != true) return;
    try {
      final temporanea = await UsersAdminStore.provisionaPa(
        email: emailCtrl.text.trim(),
        username: usernameCtrl.text.trim(),
        ente: enteCtrl.text.trim(),
        emailIstituzionale: emailIstCtrl.text.trim(),
      );
      if (mounted) {
        _avviso('${tr('Password temporanea')}: $temporanea');
      }
    } on LeafApiException catch (e) {
      if (mounted) _avviso(e.messaggio);
    }
  }

  Widget _campo(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: tr(label),
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  void _avviso(String messaggio) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.accentBrown,
        content: Text(messaggio),
      ),
    );
  }
}
