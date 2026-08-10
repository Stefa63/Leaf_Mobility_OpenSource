import 'package:flutter/material.dart';
import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/notifications_repository.dart';
import 'package:web_dashboard/session.dart';

/// Severita' visiva della notifica.
enum NotifLevel { critical, warning, info }

/// @brief Voce del centro notifiche.
class DashNotification {
  final IconData icon;
  final NotifLevel level;
  final String title;
  final String body;
  final String time;

  /// Id del backend (per segna-letta via API), null se mock.
  final String? remoteId;
  bool read;

  DashNotification({
    required this.icon,
    required this.level,
    required this.title,
    required this.body,
    required this.time,
    this.remoteId,
    this.read = false,
  });

  /// @brief Costruisce una [DashNotification] da un documento `/api/v1/notifiche`.
  /// @param d Documento notifica grezzo.
  /// @return La notifica mappata.
  static DashNotification daApi(Map<String, dynamic> d) {
    final tipo = '${d['tipo'] ?? 'info'}';
    final level = switch (tipo) {
      'emergenza' || 'sos' => NotifLevel.critical,
      'allerta' || 'warning' => NotifLevel.warning,
      _ => NotifLevel.info,
    };
    final icon = switch (tipo) {
      'emergenza' || 'sos' => Icons.sos,
      'allerta' || 'warning' => Icons.warning_amber,
      'manutenzione' => Icons.build_outlined,
      _ => Icons.notifications_outlined,
    };
    return DashNotification(
      icon: icon,
      level: level,
      title: '${d['titolo'] ?? ''}',
      body: '${d['messaggio'] ?? ''}',
      time: _formattaData(d['timestamp']?.toString()),
      remoteId: d['_id']?.toString(),
      read: d['letta'] == true,
    );
  }

  /// Formatta un timestamp ISO-8601 in una stringa leggibile breve.
  static String _formattaData(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min fa';
    if (diff.inHours < 24) return '${diff.inHours} h fa';
    if (diff.inDays == 1) return 'Ieri';
    return '${diff.inDays} g fa';
  }
}

/// @brief Sorgente osservabile condivisa delle notifiche con backend reale (IIN-19).
///
/// Stesso pattern osservabile di [appLanguage]: un solo elenco e un contatore
/// di revisione condivisi tra la campana della top bar (badge "non lette") e il
/// centro notifiche, cosi' che leggere una notifica aggiorni subito il badge —
/// niente MVC. Il caricamento reale avviene via [NotificationsRepository]; in
/// caso di errore di rete (IIN-6) si resta sui dati di riserva mock.
class NotificationsStore {
  NotificationsStore._();

  /// Incrementato ad ogni mutazione: gli ascoltatori si ridisegnano.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static List<DashNotification> _items = <DashNotification>[];
  static bool? _seededForAp;

  /// True quando l'ultimo caricamento è fallito (si mostrano i dati di riserva).
  static bool _offline = false;

  /// Indica se lo store è in modalità offline (dati di riserva).
  static bool get offline => _offline;

  static bool _inCorso = false;

  /// Elenco corrente; (ri)seminato al primo accesso o al cambio di ruolo.
  static List<DashNotification> get items {
    if (_seededForAp != Session.isPublicAdmin) {
      _items = _seed(Session.isPublicAdmin);
      _seededForAp = Session.isPublicAdmin;
    }
    return _items;
  }

  /// Numero di notifiche non lette (alimenta il badge della campana).
  static int get unreadCount => items.where((n) => !n.read).length;

  /// @brief Carica le notifiche reali dal backend (IIN-19).
  ///
  /// In caso di errore mantiene i dati di riserva mock e imposta offline (IIN-6).
  /// @param repo Repository da usare (iniettabile nei test).
  static Future<void> carica({NotificheApi? repo}) async {
    if (_inCorso) return;
    _inCorso = true;
    try {
      final docs = await (repo ?? notificationsRepository).elenco();
      _items = docs.map(DashNotification.daApi).toList();
      _offline = false;
      revision.value++;
    } on LeafApiException {
      _offline = true; // resta sui dati di riserva
    } finally {
      _inCorso = false;
    }
  }

  /// @brief Marca una notifica come letta e notifica gli ascoltatori.
  ///
  /// Se la notifica ha un [remoteId], invia anche la conferma al backend
  /// (best-effort: se fallisce, la lettura resta locale).
  /// @param n Notifica da marcare.
  /// @param repo Repository da usare (iniettabile nei test).
  static void markRead(DashNotification n, {NotificheApi? repo}) {
    if (n.read) return;
    n.read = true;
    revision.value++;
    if (n.remoteId != null) {
      (repo ?? notificationsRepository)
          .segnaLetta(n.remoteId!)
          .catchError((_) {}); // best-effort
    }
  }

  /// @brief Marca tutte le notifiche come lette (azzera il badge).
  /// @param repo Repository da usare (iniettabile nei test).
  static void markAllRead({NotificheApi? repo}) {
    var changed = false;
    for (final n in items) {
      if (!n.read) {
        n.read = true;
        changed = true;
        if (n.remoteId != null) {
          (repo ?? notificationsRepository)
              .segnaLetta(n.remoteId!)
              .catchError((_) {}); // best-effort
        }
      }
    }
    if (changed) revision.value++;
  }

  static List<DashNotification> _seed(bool isAp) {
    if (isAp) {
      return [
        DashNotification(
          icon: Icons.description_outlined,
          level: NotifLevel.info,
          title: 'Report mensile noleggi pronto',
          body: 'Il report aggregato per tipologia di mezzo è disponibile.',
          time: '08:30',
        ),
        DashNotification(
          icon: Icons.speed,
          level: NotifLevel.info,
          title: 'Slow-zone propagata',
          body: 'La slow-zone "Centro Storico" è attiva su tutti i mezzi.',
          time: 'Ieri',
          read: true,
        ),
        DashNotification(
          icon: Icons.warning_amber,
          level: NotifLevel.warning,
          title: 'Soglia minima di servizio',
          body: 'La Zona Ovest è sotto la soglia operativa concordata.',
          time: 'Ieri',
        ),
        DashNotification(
          icon: Icons.event,
          level: NotifLevel.info,
          title: 'Grande evento registrato',
          body:
              'Concerto allo Stadio il 12/06 — potenziamento flotta suggerito.',
          time: '2 g fa',
          read: true,
        ),
      ];
    }
    return [
      DashNotification(
        icon: Icons.sos,
        level: NotifLevel.critical,
        title: 'SOS attivo — Utente U-1029',
        body: 'Segnalazione di emergenza ricevuta nella Zona Ovest.',
        time: 'Ora',
      ),
      DashNotification(
        icon: Icons.wrong_location_outlined,
        level: NotifLevel.warning,
        title: 'Scooter SC-021 fuori area',
        body: 'Il mezzo ha superato il perimetro operativo.',
        time: '5 min fa',
      ),
      DashNotification(
        icon: Icons.battery_alert,
        level: NotifLevel.warning,
        title: 'Batteria critica EM-015',
        body: 'Livello batteria 8% — pianificare ricarica.',
        time: '20 min fa',
      ),
      DashNotification(
        icon: Icons.build_outlined,
        level: NotifLevel.info,
        title: 'Ticket TK-0044 assegnato',
        body: 'Intervento su CA-015 assegnato al tecnico L. Bianchi.',
        time: '1 h fa',
        read: true,
      ),
    ];
  }
}

