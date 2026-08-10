import 'package:flutter/material.dart';
import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/api_config.dart';
import 'package:web_dashboard/api/maintenance_repository.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/theme.dart';
import 'package:web_dashboard/widgets/common.dart';

// Il form di creazione vive nel part adiacente `ticket_management_form.dart`.
// I ticket e i tecnici sono interamente reali (da `/manutenzione` e `/tecnici`):
// nessun dato di riserva fabbricato (dipendenza dal server).
part 'ticket_management_form.dart';

/// Tipo di ticket: guasto mezzo o richiesta di assistenza utente. OP.06/OP.19.
enum TicketType { guasto, assistenza }

/// Stato di lavorazione del ticket. OP.16/OP.19.
enum TicketStatus { daAssegnare, inCorso, terminato }

/// Priorita' dell'intervento.
enum TicketPriority { alta, media, bassa }

/// @brief Ticket di intervento/assistenza (mock pre-backend).
class Ticket {
  final String id;
  final TicketType type;
  final String vehicleId;
  final String subject;
  final TicketPriority priority;
  final DateTime date;
  TicketStatus status;
  String? technician;

  Ticket({
    required this.id,
    required this.type,
    required this.vehicleId,
    required this.subject,
    required this.priority,
    required this.date,
    required this.status,
    this.technician,
  });

  /// @brief Costruisce un [Ticket] di guasto da un documento di `/api/v1/manutenzione`.
  /// @param doc Documento ticket di manutenzione.
  /// @return Il ticket mappato, o null se privo di identificativo.
  static Ticket? daApi(Map<String, dynamic> doc) {
    final id = doc['_id']?.toString();
    if (id == null || id.isEmpty) return null;
    final priority = switch (doc['priorita']) {
      'alta' => TicketPriority.alta,
      'bassa' => TicketPriority.bassa,
      _ => TicketPriority.media,
    };
    final status = switch (doc['stato']) {
      'assegnato' => TicketStatus.inCorso,
      'chiuso' => TicketStatus.terminato,
      _ => TicketStatus.daAssegnare,
    };
    return Ticket(
      id: id,
      type: TicketType.guasto,
      vehicleId: (doc['codice_identificativo_mezzo'] ?? doc['id_mezzo'] ?? '—')
          .toString(),
      subject: doc['descrizione_guasto']?.toString() ?? '',
      priority: priority,
      date:
          DateTime.tryParse(doc['data_apertura']?.toString() ?? '') ??
          DateTime.now(),
      status: status,
      technician: doc['id_tecnico']?.toString(),
    );
  }
}

/// Finestra temporale per il filtro per data.
enum _DateRange { all, today, week, month }

/// @brief Schermata di gestione ticket dell'Operatore.
///
/// Elenco filtrabile per tipo (guasto/assistenza), data e stato
/// (da assegnare / in corso / terminato). Consente l'assegnazione a un tecnico
/// e la chiusura. Copre OP.03 (lista guasti), OP.06 (lista filtrabile),
/// OP.16/OP.19 (compila, assegna e traccia i ticket). Pre-backend i dati sono
/// mock; le operazioni reali passeranno per `gestore_assistenza_ticket`.
class TicketManagement extends StatefulWidget {
  const TicketManagement({super.key, this.autoload = true, this.repo});

  /// @brief Se true (default), carica i ticket reali all'apertura; i test lo disattivano.
  final bool autoload;

  /// @brief Repository manutenzione iniettabile (default singleton reale; fake nei test).
  final ManutenzioneApi? repo;

  @override
  State<TicketManagement> createState() => _TicketManagementState();
}

class _TicketManagementState extends State<TicketManagement> {
  TicketType? _typeFilter;
  TicketStatus? _statusFilter;
  _DateRange _dateFilter = _DateRange.all;

  final List<Ticket> _tickets = [];

  /// Tecnici reali assegnabili, caricati da `/api/v1/tecnici` (OP.16).
  List<Map<String, dynamic>> _tecnici = const [];

  /// True quando l'ultimo caricamento è fallito (lista vuota + banner offline).
  bool _offline = false;

  /// Contatore progressivo per i codici ticket creati nella sessione.
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    if (widget.autoload && kAutoloadData) _carica();
  }

  /// @brief Carica i ticket di manutenzione reali (OP.19) e li fonde con la coda mock.
  ///
  /// Sostituisce i guasti con quelli reali da `/api/v1/manutenzione`, mantenendo le
  /// richieste di assistenza (dominio della coda assistenza, OP.08). In errore (IIN-6)
  /// resta sui dati di riserva con [_offline] a true.
  Future<void> _carica() async {
    final repo = widget.repo ?? maintenanceRepository;
    // Tecnici reali (OP.16): best-effort, così l'assegnazione non usa più i mock.
    try {
      final tecnici = await repo.elencoTecnici();
      if (mounted) setState(() => _tecnici = tecnici);
    } on LeafApiException {
      // si resta sui nomi di riserva finché il backend non risponde (IIN-6)
    }
    try {
      final docs = await repo.elenco();
      final reali = docs.map(Ticket.daApi).whereType<Ticket>().toList();
      // Risolve l'id tecnico del documento nel nome leggibile (OP.16).
      for (final t in reali) {
        t.technician = _nomeTecnico(t.technician);
      }
      if (!mounted) return;
      setState(() {
        _tickets
          ..removeWhere((t) => t.type == TicketType.guasto)
          ..insertAll(0, reali);
        _offline = false;
      });
    } on LeafApiException {
      if (mounted) setState(() => _offline = true);
    }
  }

  /// Genera il prossimo identificativo ticket progressivo (es. `TK-0045`).
  String _nextId() => 'TK-${(++_seq).toString().padLeft(4, '0')}';

  /// @param t Ticket da valutare.
  /// @return `true` se la data del ticket rientra nella finestra `_dateFilter`.
  bool _passesDate(Ticket t) {
    final now = DateTime.now();
    switch (_dateFilter) {
      case _DateRange.all:
        return true;
      case _DateRange.today:
        return t.date.year == now.year &&
            t.date.month == now.month &&
            t.date.day == now.day;
      case _DateRange.week:
        return now.difference(t.date).inDays < 7;
      case _DateRange.month:
        return now.difference(t.date).inDays < 30;
    }
  }

  /// @return I ticket che soddisfano i filtri attivi di tipo, stato e data
  /// (OP.06).
  List<Ticket> get _filtered => _tickets.where((t) {
    if (_typeFilter != null && t.type != _typeFilter) return false;
    if (_statusFilter != null && t.status != _statusFilter) return false;
    return _passesDate(t);
  }).toList();

  /// @param s Stato da conteggiare.
  /// @return Il numero di ticket nello stato [s].
  int _countStatus(TicketStatus s) =>
      _tickets.where((t) => t.status == s).length;

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      final list = _filtered;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'Gestione Ticket',
                  subtitle: 'Interventi e Assistenza Flotta',
                ),
              ),
              ElevatedButton.icon(
                onPressed: _openCreateDialog,
                icon: const Icon(Icons.add, size: 18),
                label: Text(tr('Nuovo Ticket')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _statusSummary(),
          const SizedBox(height: 16),
          _filterBar(),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${list.length} ${tr('ticket')}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
              ),
              if (_offline) ...[
                const SizedBox(width: 10),
                const Icon(
                  Icons.cloud_off,
                  size: 13,
                  color: AppTheme.alarmWarning,
                ),
                const SizedBox(width: 4),
                Text(
                  tr('offline'),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.alarmWarning,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text(
                      tr('Nessun ticket per i filtri selezionati'),
                      style: const TextStyle(color: AppTheme.textGrey),
                    ),
                  )
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _ticketCard(list[i]),
                  ),
          ),
        ],
      );
    });
  }

  /// @return La fascia riepilogativa con i conteggi per stato del ticket.
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
        pill(
          'Da assegnare',
          _countStatus(TicketStatus.daAssegnare),
          AppTheme.alarmWarning,
        ),
        pill(
          'In corso',
          _countStatus(TicketStatus.inCorso),
          AppTheme.statusInUse,
        ),
        pill(
          'Terminati',
          _countStatus(TicketStatus.terminato),
          AppTheme.statusAvailable,
        ),
      ],
    );
  }

  /// @return La barra dei filtri per tipo, stato e data, con azzeramento (OP.06).
  Widget _filterBar() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _dropdown<TicketType?>(
          icon: Icons.category_outlined,
          value: _typeFilter,
          hint: 'Tutti i tipi',
          items: {
            null: 'Tutti i tipi',
            TicketType.guasto: 'Guasto',
            TicketType.assistenza: 'Assistenza Utente',
          },
          onChanged: (v) => setState(() => _typeFilter = v),
        ),
        _dropdown<TicketStatus?>(
          icon: Icons.flag_outlined,
          value: _statusFilter,
          hint: 'Tutti gli stati',
          items: {
            null: 'Tutti gli stati',
            TicketStatus.daAssegnare: 'Da assegnare',
            TicketStatus.inCorso: 'In corso',
            TicketStatus.terminato: 'Terminato',
          },
          onChanged: (v) => setState(() => _statusFilter = v),
        ),
        _dropdown<_DateRange>(
          icon: Icons.calendar_today_outlined,
          value: _dateFilter,
          hint: 'Tutte le date',
          items: const {
            _DateRange.all: 'Tutte le date',
            _DateRange.today: 'Oggi',
            _DateRange.week: 'Ultimi 7 giorni',
            _DateRange.month: 'Ultimi 30 giorni',
          },
          onChanged: (v) => setState(() => _dateFilter = v ?? _DateRange.all),
        ),
        if (_typeFilter != null ||
            _statusFilter != null ||
            _dateFilter != _DateRange.all)
          TextButton.icon(
            onPressed: () => setState(() {
              _typeFilter = null;
              _statusFilter = null;
              _dateFilter = _DateRange.all;
            }),
            icon: const Icon(Icons.clear, size: 16),
            label: Text(tr('Azzera filtri')),
          ),
      ],
    );
  }

  /// Menu a tendina compatto e tradotto per un filtro.
  ///
  /// @param icon Icona mostrata a sinistra del menu.
  /// @param value Valore correntemente selezionato.
  /// @param hint Testo segnaposto quando nessun valore e' scelto.
  /// @param items Mappa valore→etichetta delle voci selezionabili.
  /// @param onChanged Callback invocata alla scelta di una voce.
  /// @return Il widget del menu a tendina.
  Widget _dropdown<T>({
    required IconData icon,
    required T value,
    required String hint,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppTheme.textGrey),
          const SizedBox(width: 8),
          DropdownButton<T>(
            value: value,
            hint: Text(tr(hint)),
            underline: const SizedBox.shrink(),
            borderRadius: BorderRadius.circular(12),
            style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
            items: items.entries
                .map(
                  (e) => DropdownMenuItem<T>(
                    value: e.key,
                    child: Text(tr(e.value)),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  /// Card di un ticket con azioni di assegnazione e chiusura (OP.16/OP.19).
  ///
  /// @param t Ticket da rappresentare.
  /// @return Il widget card del ticket.
  Widget _ticketCard(Ticket t) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  t.type == TicketType.guasto
                      ? Icons.build_circle_outlined
                      : Icons.support_agent,
                  size: 20,
                  color: AppTheme.opAccent,
                ),
                const SizedBox(width: 8),
                Text(
                  t.id,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(width: 8),
                _priorityChip(t.priority),
                const Spacer(),
                _statusChip(t.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tr(t.subject),
              style: const TextStyle(fontSize: 13.5, color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _meta(Icons.directions_car_outlined, t.vehicleId),
                _meta(Icons.calendar_today_outlined, _fmtDate(t.date)),
                _meta(
                  Icons.engineering_outlined,
                  t.technician ?? tr('Non assegnato'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (t.status != TicketStatus.terminato)
                  TextButton.icon(
                    onPressed: () => _assignDialog(t),
                    icon: const Icon(Icons.person_add_alt, size: 16),
                    label: Text(
                      t.technician == null ? tr('Assegna') : tr('Riassegna'),
                    ),
                  ),
                if (t.status == TicketStatus.inCorso)
                  TextButton.icon(
                    onPressed: () => _chiudi(t),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: Text(tr('Chiudi')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Coppia icona+testo per i metadati del ticket (mezzo, data, tecnico).
  ///
  /// @param icon Icona del metadato.
  /// @param text Testo del metadato.
  /// @return Il widget riga del metadato.
  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textGrey),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
        ),
      ],
    );
  }

  /// @param p Priorita' del ticket.
  /// @return Il chip colorato della priorita'.
  Widget _priorityChip(TicketPriority p) {
    final (label, color) = switch (p) {
      TicketPriority.alta => ('Alta', AppTheme.alarmCritical),
      TicketPriority.media => ('Media', AppTheme.alarmWarning),
      TicketPriority.bassa => ('Bassa', AppTheme.textGrey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tr(label),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  /// @param s Stato del ticket.
  /// @return Il chip colorato dello stato, con pallino indicatore.
  Widget _statusChip(TicketStatus s) {
    final (label, color) = switch (s) {
      TicketStatus.daAssegnare => ('Da assegnare', AppTheme.alarmWarning),
      TicketStatus.inCorso => ('In corso', AppTheme.statusInUse),
      TicketStatus.terminato => ('Terminato', AppTheme.statusAvailable),
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

  /// @param d Data da formattare.
  /// @return La data nel formato `gg/mm/aaaa`.
  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// Apre il dialog di scelta del tecnico e assegna il ticket (OP.16).
  ///
  /// Se il ticket era "Da assegnare" passa a "In corso" alla conferma.
  ///
  /// @param t Ticket da assegnare/riassegnare.
  Future<void> _assignDialog(Ticket t) async {
    final nomi = _tecniciNomi();
    final chosen = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(tr('Assegna a un tecnico')),
        children: nomi
            .map(
              (tech) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, tech),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.engineering_outlined, size: 18),
                      const SizedBox(width: 10),
                      Text(tech),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
    if (chosen == null) return;
    // Assegnazione reale lato server quando il ticket e il tecnico sono reali (OP.16);
    // sui dati di riserva (id tecnico assente) resta un aggiornamento locale.
    final idTecnico = _idTecnicoPerNome(chosen);
    if (idTecnico != null) {
      try {
        await (widget.repo ?? maintenanceRepository).assegna(t.id, idTecnico);
      } on LeafApiException catch (e) {
        if (!mounted) return;
        setState(() => _offline = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.alarmCritical,
            content: Text(e.messaggio),
          ),
        );
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      t.technician = chosen;
      if (t.status == TicketStatus.daAssegnare) {
        t.status = TicketStatus.inCorso;
      }
    });
  }

  /// @brief Nome leggibile del tecnico dato il suo id (OP.16); ripiega sull'id.
  /// @param id Id del tecnico (o null se non assegnato).
  /// @return Il nome del tecnico, l'id se non risolvibile, o null se assente.
  String? _nomeTecnico(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final t in _tecnici) {
      if ('${t['_id']}' == id) return '${t['nome'] ?? t['_id']}';
    }
    return id;
  }

  /// @brief Id del tecnico dato il nome visualizzato, per l'assegnazione server.
  /// @param nome Nome del tecnico scelto nel menu.
  /// @return L'id del tecnico, o null se il nome non corrisponde a un tecnico reale.
  String? _idTecnicoPerNome(String nome) {
    for (final t in _tecnici) {
      if ('${t['nome'] ?? ''}' == nome) return '${t['_id']}';
    }
    return null;
  }

  /// @brief Nomi dei tecnici reali per i menu di assegnazione (OP.16).
  /// @return Elenco dei nomi tecnico selezionabili (vuoto se il backend non risponde).
  List<String> _tecniciNomi() =>
      _tecnici.map((t) => '${t['nome'] ?? t['_id']}').toList();

  /// @brief Apre il form di compilazione e assegnazione di un nuovo ticket.
  ///
  /// Realizza OP.16 (compila e assegna a un tecnico registrato) e OP.19
  /// (crea, assegna e traccia ticket di manutenzione). Il form vive in un widget
  /// dedicato ([_CreateTicketForm]) che possiede e dispone i propri
  /// `TextEditingController` nel suo `dispose()`, evitando di liberarli mentre il
  /// dialog e' ancora in chiusura (animazione) — gotcha gia' osservato sul form
  /// sconti. Al salvataggio il ticket viene aggiunto alla lista in memoria; la
  /// persistenza reale passera' per `gestore_assistenza_ticket`.
  Future<void> _openCreateDialog() async {
    final created = await showDialog<Ticket>(
      context: context,
      builder: (context) =>
          _CreateTicketForm(id: _nextId(), technicians: _tecniciNomi()),
    );

    if (created != null && mounted) {
      setState(() => _tickets.insert(0, created));
      // Persistenza reale dei soli guasti (OP.19); le assistenze hanno la propria coda.
      if (created.type == TicketType.guasto) {
        _sync(() async {
          final repo = widget.repo ?? maintenanceRepository;
          final idTicket = await repo.crea(
            idMezzo: created.vehicleId,
            descrizione: created.subject,
            priorita: _prioritaServer(created.priority),
          );
          // OP.16: se in creazione è stato scelto un tecnico reale, assegna subito.
          final nome = created.technician;
          final idTecnico = nome == null ? null : _idTecnicoPerNome(nome);
          if (idTecnico != null) await repo.assegna(idTicket, idTecnico);
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.statusAvailable,
          content: Text('${tr('Ticket creato')} ${created.id}'),
        ),
      );
    }
  }

  /// @brief Chiude un ticket (ottimistico) sincronizzando il backend (OP.19).
  /// @param t Ticket da chiudere.
  void _chiudi(Ticket t) {
    setState(() => t.status = TicketStatus.terminato);
    _sync(() async => (widget.repo ?? maintenanceRepository).chiudi(t.id));
  }

  /// @brief Sincronizzazione best-effort: in errore di rete segnala solo l'offline (IIN-6).
  /// @param azione Operazione remota da eseguire senza annullare l'azione locale.
  Future<void> _sync(Future<void> Function() azione) async {
    try {
      await azione();
    } on LeafApiException {
      if (mounted) setState(() => _offline = true);
    }
  }

  /// @brief Traduce la priorità UI nel valore atteso dal backend.
  /// @param p Priorità del ticket.
  /// @return "alta" | "media" | "bassa".
  static String _prioritaServer(TicketPriority p) => switch (p) {
    TicketPriority.alta => 'alta',
    TicketPriority.media => 'media',
    TicketPriority.bassa => 'bassa',
  };
}
