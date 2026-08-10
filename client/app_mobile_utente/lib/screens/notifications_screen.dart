import 'package:flutter/material.dart';
import 'package:app_mobile_utente/api/api_client.dart';
import 'package:app_mobile_utente/api/notifiche_repository.dart';
import 'package:app_mobile_utente/theme.dart';
import 'package:app_mobile_utente/l10n.dart';

/// Notifications screen wired to `GET /api/v1/notifiche` (UT.15/UT.19, IIN-19).
///
/// Mostra le notifiche reali dell'utente e i broadcast di servizio (scadenza
/// prenotazione, interruzione servizio), dalla più recente; il tap su una
/// notifica non letta la marca come letta (`POST /notifiche/{id}/letta`). In
/// assenza di rete (IIN-6) mostra un avviso con possibilità di riprovare.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.repo});

  /// @brief Repository notifiche iniettabile (default singleton reale; fake nei test).
  final NotificheApi? repo;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificheApi _api = widget.repo ?? notificheRepository;

  List<Map<String, dynamic>> _notifiche = const [];
  bool _loading = true;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _carica();
  }

  Future<void> _carica() async {
    setState(() => _loading = true);
    try {
      final notifiche = await _api.elenco();
      if (!mounted) return;
      setState(() {
        _notifiche = notifiche;
        _offline = false;
        _loading = false;
      });
    } on LeafApiException {
      if (!mounted) return;
      setState(() {
        _offline = true;
        _loading = false;
      });
    }
  }

  /// Marca la notifica come letta (best-effort) e aggiorna la vista (UT.15/19).
  Future<void> _segnaLetta(int indice) async {
    final n = _notifiche[indice];
    if (n['letta'] == true) return;
    setState(() => _notifiche = [
          for (var i = 0; i < _notifiche.length; i++)
            if (i == indice) {..._notifiche[i], 'letta': true} else _notifiche[i],
        ]);
    final id = '${n['_id'] ?? ''}';
    if (id.isEmpty) return;
    try {
      await _api.segnaLetta(id);
    } on LeafApiException {
      // Best-effort: lo stato locale resta letto; si riallinea al prossimo carico.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Notifiche')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carica,
              child: _notifiche.isEmpty ? _statoVuoto() : _lista(),
            ),
    );
  }

  Widget _lista() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _notifiche.length + (_offline ? 1 : 0),
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        if (_offline && i == 0) return _bannerOffline();
        final indice = _offline ? i - 1 : i;
        return _tile(_notifiche[indice], indice);
      },
    );
  }

  Widget _tile(Map<String, dynamic> n, int indice) {
    final letta = n['letta'] == true;
    final tipo = '${n['tipo'] ?? ''}';
    return ListTile(
      onTap: letta ? null : () => _segnaLetta(indice),
      leading: CircleAvatar(
        backgroundColor: _coloreTipo(tipo).withAlpha(28),
        child: Icon(_iconaTipo(tipo), color: _coloreTipo(tipo), size: 20),
      ),
      title: Text(
        '${n['titolo'] ?? tr('Notifica')}',
        style: TextStyle(
          fontWeight: letta ? FontWeight.w500 : FontWeight.bold,
          color: AppTheme.textDark,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        '${n['messaggio'] ?? ''}',
        style: const TextStyle(fontSize: 12.5, color: AppTheme.textGrey),
      ),
      trailing: letta
          ? null
          : const Icon(Icons.circle, size: 10, color: AppTheme.primaryGreen),
    );
  }

  Color _coloreTipo(String tipo) => switch (tipo) {
        'prenotazione' => AppTheme.primaryGreen,
        'servizio' => AppTheme.accentBrown,
        _ => AppTheme.textGrey,
      };

  IconData _iconaTipo(String tipo) => switch (tipo) {
        'prenotazione' => Icons.event_available_outlined,
        'servizio' => Icons.campaign_outlined,
        _ => Icons.notifications_none_outlined,
      };

  Widget _statoVuoto() {
    return ListView(
      children: [
        const SizedBox(height: 120),
        if (_offline)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _bannerOffline(),
          ),
        const Icon(
          Icons.notifications_none_outlined,
          size: 64,
          color: AppTheme.textGrey,
        ),
        const SizedBox(height: 16),
        Text(
          tr('Nessuna notifica'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.textGrey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tr('Le tue notifiche appariranno qui.'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
        ),
      ],
    );
  }

  Widget _bannerOffline() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE65100)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: 16, color: Color(0xFFE65100)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tr('Notifiche non aggiornate (offline)'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE65100),
              ),
            ),
          ),
          GestureDetector(
            onTap: _carica,
            child: Text(
              tr('Riprova'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE65100),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
