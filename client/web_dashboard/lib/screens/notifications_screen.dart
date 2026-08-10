import 'package:flutter/material.dart';
import 'package:web_dashboard/data/notifications_store.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/theme.dart';
import 'package:web_dashboard/widgets/common.dart';

/// @brief Centro notifiche per OP e AP.
///
/// Raggiunto dalla campana in alto a destra. Elenca gli eventi rilevanti per il
/// ruolo con filtro "tutte / non lette" e azione "segna tutte come lette". I
/// dati e lo stato di lettura vivono in [NotificationsStore] (osservabile),
/// condiviso con il badge della campana: leggere qui azzera subito il badge.
/// Pre-backend i dati sono mock; gli eventi reali arriveranno via push (IIN-19).
class NotificationsScreen extends StatefulWidget {
  /// Colore di accento del ruolo attivo (OP blu / AP teal).
  final Color accent;

  const NotificationsScreen({super.key, required this.accent});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _onlyUnread = false;

  Color _levelColor(NotifLevel l) {
    switch (l) {
      case NotifLevel.critical:
        return AppTheme.alarmCritical;
      case NotifLevel.warning:
        return AppTheme.alarmWarning;
      case NotifLevel.info:
        return widget.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return ValueListenableBuilder<int>(
        valueListenable: NotificationsStore.revision,
        builder: (context, _, _) {
          final items = NotificationsStore.items;
          final visible =
              _onlyUnread ? items.where((n) => !n.read).toList() : items;
          final unread = NotificationsStore.unreadCount;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SectionHeader(
                      title: 'Notifiche',
                      subtitle: '$unread ${tr('non lette')}',
                    ),
                  ),
                  TextButton.icon(
                    onPressed:
                        unread == 0 ? null : NotificationsStore.markAllRead,
                    icon: const Icon(Icons.done_all, size: 18),
                    label: Text(tr('Segna tutte come lette')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilterChip(
                    label: Text(tr('Tutte')),
                    selected: !_onlyUnread,
                    onSelected: (_) => setState(() => _onlyUnread = false),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(tr('Non lette')),
                    selected: _onlyUnread,
                    onSelected: (_) => setState(() => _onlyUnread = true),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: visible.isEmpty
                    ? Center(
                        child: Text(
                          tr('Nessuna notifica'),
                          style: const TextStyle(color: AppTheme.textGrey),
                        ),
                      )
                    : ListView.separated(
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _tile(visible[i]),
                      ),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _tile(DashNotification n) {
    final color = _levelColor(n.level);
    return Material(
      color: n.read ? Colors.white : color.withAlpha(14),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => NotificationsStore.markRead(n),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withAlpha(30),
                child: Icon(n.icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(n.title),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            n.read ? FontWeight.w500 : FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tr(n.body),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    tr(n.time),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textGrey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (!n.read)
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
