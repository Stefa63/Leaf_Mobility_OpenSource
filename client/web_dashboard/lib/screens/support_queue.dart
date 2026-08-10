import 'package:flutter/material.dart';
import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/assistenza_repository.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/theme.dart';
import 'package:web_dashboard/widgets/common.dart';

/// Canale da cui proviene la richiesta di assistenza.
enum SupportChannel { chat, email, telefono }

/// Stato di lavorazione della richiesta. OP.08.
enum SupportStatus { nuova, inCarico, risolta }

/// @brief Richiesta di assistenza utente in coda.
class SupportRequest {
  final String id;
  final String user;
  final SupportChannel channel;
  final String subject;
  final String lastMessage;
  final String time;
  SupportStatus status;
  String? operator;

  SupportRequest({
    required this.id,
    required this.user,
    required this.channel,
    required this.subject,
    required this.lastMessage,
    required this.time,
    required this.status,
    this.operator,
  });

  /// @brief Costruisce una richiesta dalla forma del documento ticket della API.
  ///
  /// Mappa `stato` (aperto/in_lavorazione/chiuso) sullo stato di vista; il canale
  /// non è modellato lato server (default chat); l'ultimo messaggio è la risposta
  /// se presente, altrimenti il messaggio dell'utente. OP.08.
  ///
  /// @param d Documento ticket grezzo da `/api/v1/assistenza`.
  /// @return La [SupportRequest] corrispondente.
  factory SupportRequest.daApi(Map<String, dynamic> d) {
    final stato = '${d['stato'] ?? 'aperto'}';
    final risposta = d['risposta'];
    return SupportRequest(
      id: '${d['_id'] ?? ''}',
      user: '${d['id_utente'] ?? '—'}',
      channel: SupportChannel.chat,
      subject: '${d['oggetto'] ?? ''}',
      lastMessage: '${risposta ?? d['messaggio'] ?? ''}',
      time: '${d['data_ora'] ?? ''}',
      status: _statoDaApi(stato),
      operator: d['id_operatore']?.toString(),
    );
  }

  /// Mappa lo `stato` del ticket server sullo stato di vista.
  static SupportStatus _statoDaApi(String stato) {
    switch (stato) {
      case 'in_lavorazione':
        return SupportStatus.inCarico;
      case 'chiuso':
        return SupportStatus.risolta;
      default:
        return SupportStatus.nuova;
    }
  }
}

/// @brief Coda centralizzata delle richieste di assistenza (OP.08).
///
/// L'Operatore vede le richieste in entrata dai diversi canali, le prende in
/// carico, risponde e le chiude. Filtro per stato (nuove / in carico / risolte).
/// I dati provengono esclusivamente da `/api/v1/assistenza` (gestore_assistenza_ticket):
/// nessun dato di riserva fabbricato, a backend non raggiungibile la coda resta vuota.
class SupportQueue extends StatefulWidget {
  const SupportQueue({super.key, AssistenzaApi? assistenza})
    : _assistenza = assistenza;

  /// Repository assistenza iniettabile (default reale; fittizio nei test).
  final AssistenzaApi? _assistenza;

  @override
  State<SupportQueue> createState() => _SupportQueueState();
}

class _SupportQueueState extends State<SupportQueue> {
  SupportStatus? _statusFilter;

  late final AssistenzaApi _assistenza =
      widget._assistenza ?? assistenzaRepository;

  /// True quando l'ultimo caricamento è fallito (lista vuota + banner offline).
  bool _offline = false;

  final List<SupportRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    _caricaCoda();
  }

  /// Carica la coda di assistenza dal backend (OP.08).
  ///
  /// In caso di errore svuota la coda e segnala offline (IIN-6): nessun dato
  /// fabbricato, la vista dipende esclusivamente dal server.
  Future<void> _caricaCoda() async {
    try {
      final docs = await _assistenza.coda();
      if (!mounted) return;
      setState(() {
        _requests
          ..clear()
          ..addAll(docs.map(SupportRequest.daApi));
        _offline = false;
      });
    } on LeafApiException {
      if (mounted) setState(() => _offline = true);
    }
  }

  /// Invia una risposta/transizione di stato al backend e ricarica (OP.08).
  /// @param r Richiesta su cui agire.
  /// @param risposta Testo della risposta.
  /// @param stato Nuovo stato del ticket (in_lavorazione/chiuso).
  Future<void> _inviaRisposta(
    SupportRequest r,
    String risposta,
    String stato,
  ) async {
    try {
      await _assistenza.rispondi(r.id, risposta, stato: stato);
      await _caricaCoda();
    } on LeafApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFC62828),
          content: Text(e.messaggio),
        ),
      );
    }
  }

  /// Apre un dialogo per comporre la risposta e la invia (OP.08).
  Future<void> _rispondiDialog(SupportRequest r) async {
    final ctrl = TextEditingController();
    final testo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Rispondi')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: tr('Scrivi la risposta all\'utente…'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('Annulla')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: Text(tr('Invia')),
          ),
        ],
      ),
    );
    if (testo != null && testo.isNotEmpty) {
      await _inviaRisposta(r, testo, 'in_lavorazione');
    }
  }

  int _countStatus(SupportStatus s) =>
      _requests.where((r) => r.status == s).length;

  List<SupportRequest> get _filtered => _statusFilter == null
      ? _requests
      : _requests.where((r) => r.status == _statusFilter).toList();

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      final list = _filtered;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Coda Assistenza',
            subtitle: 'Richieste di supporto in entrata',
          ),
          if (_offline)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, size: 16, color: Color(0xFFE65100)),
                  const SizedBox(width: 8),
                  Text(
                    tr('Dati non aggiornati (offline)'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          _statusSummary(),
          const SizedBox(height: 16),
          _filterBar(),
          const SizedBox(height: 8),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text(
                      tr('Nessuna richiesta in coda'),
                      style: const TextStyle(color: AppTheme.textGrey),
                    ),
                  )
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _card(list[i]),
                  ),
          ),
        ],
      );
    });
  }

  Widget _statusSummary() {
    Widget pill(String label, int n, Color c) => Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: c.withAlpha(18),
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: c, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$n',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: c,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tr(label),
                  style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
                ),
              ],
            ),
          ),
        );

    return Row(
      children: [
        pill('Nuove', _countStatus(SupportStatus.nuova), AppTheme.alarmCritical),
        pill('In carico', _countStatus(SupportStatus.inCarico),
            AppTheme.statusInUse),
        pill('Risolte', _countStatus(SupportStatus.risolta),
            AppTheme.statusAvailable),
      ],
    );
  }

  Widget _filterBar() {
    Widget chip(String label, SupportStatus? value) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(tr(label)),
            selected: _statusFilter == value,
            onSelected: (_) => setState(() => _statusFilter = value),
          ),
        );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        chip('Tutte', null),
        chip('Nuove', SupportStatus.nuova),
        chip('In carico', SupportStatus.inCarico),
        chip('Risolte', SupportStatus.risolta),
      ],
    );
  }

  IconData _channelIcon(SupportChannel c) {
    switch (c) {
      case SupportChannel.chat:
        return Icons.chat_bubble_outline;
      case SupportChannel.email:
        return Icons.email_outlined;
      case SupportChannel.telefono:
        return Icons.phone_outlined;
    }
  }

  Widget _card(SupportRequest r) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_channelIcon(r.channel), size: 20, color: AppTheme.opAccent),
                const SizedBox(width: 8),
                Text(
                  r.id,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '· ${r.user}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
                ),
                const Spacer(),
                _statusChip(r.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tr(r.subject),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tr(r.lastMessage),
              style: const TextStyle(fontSize: 12.5, color: AppTheme.textGrey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _meta(Icons.schedule, r.time),
                _meta(
                  Icons.support_agent,
                  r.operator ?? tr('Non assegnata'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (r.status == SupportStatus.nuova)
                  TextButton.icon(
                    onPressed: () => _inviaRisposta(
                      r,
                      tr('Richiesta presa in carico.'),
                      'in_lavorazione',
                    ),
                    icon: const Icon(Icons.assignment_ind_outlined, size: 16),
                    label: Text(tr('Prendi in carico')),
                  ),
                if (r.status != SupportStatus.risolta) ...[
                  TextButton.icon(
                    onPressed: () => _rispondiDialog(r),
                    icon: const Icon(Icons.reply, size: 16),
                    label: Text(tr('Rispondi')),
                  ),
                  TextButton.icon(
                    onPressed: () => _inviaRisposta(
                      r,
                      r.lastMessage.isNotEmpty ? r.lastMessage : tr('Risolto'),
                      'chiuso',
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: Text(tr('Risolvi')),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textGrey),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
      ],
    );
  }

  Widget _statusChip(SupportStatus s) {
    final (label, color) = switch (s) {
      SupportStatus.nuova => ('Nuova', AppTheme.alarmCritical),
      SupportStatus.inCarico => ('In carico', AppTheme.statusInUse),
      SupportStatus.risolta => ('Risolta', AppTheme.statusAvailable),
    };
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

}
