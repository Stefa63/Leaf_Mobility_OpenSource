part of 'ticket_management.dart';

/// @brief Dialog di compilazione di un nuovo ticket di intervento/assistenza.
///
/// Copre OP.16 / OP.19: l'Operatore seleziona il tipo (guasto mezzo o assistenza
/// utente), indica il codice del mezzo e l'oggetto, imposta la priorita' e puo'
/// assegnare subito un tecnico. Se un tecnico viene scelto il ticket nasce
/// "In corso", altrimenti "Da assegnare". Widget con stato dedicato: possiede i
/// controller dei campi e li dispone in [dispose] (eseguito quando la route e'
/// realmente rimossa), evitando il rilascio anticipato che corromperebbe
/// l'albero alla chiusura del dialog. Ritorna il [Ticket] creato via
/// `Navigator.pop`, oppure null se annullato.
class _CreateTicketForm extends StatefulWidget {
  final String id;
  final List<String> technicians;

  const _CreateTicketForm({required this.id, required this.technicians});

  @override
  State<_CreateTicketForm> createState() => _CreateTicketFormState();
}

class _CreateTicketFormState extends State<_CreateTicketForm> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  TicketType _type = TicketType.guasto;
  TicketPriority _priority = TicketPriority.media;

  /// Tecnico assegnato in fase di creazione; null = nessuna assegnazione.
  String? _technician;

  @override
  void dispose() {
    _vehicleCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  /// @param v Valore del campo.
  /// @return Messaggio d'errore se [v] e' vuoto, altrimenti null.
  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? tr('Campo obbligatorio') : null;

  /// @param hint Segnaposto tradotto del campo.
  /// @return La decorazione uniforme dei campi del form.
  InputDecoration _deco(String hint) => InputDecoration(
        hintText: tr(hint),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  /// @param t Tipo di ticket.
  /// @return L'etichetta testuale del tipo.
  static String _typeLabel(TicketType t) => switch (t) {
        TicketType.guasto => 'Guasto',
        TicketType.assistenza => 'Assistenza Utente',
      };

  /// @param p Priorita' del ticket.
  /// @return L'etichetta testuale della priorita'.
  static String _priorityLabel(TicketPriority p) => switch (p) {
        TicketPriority.alta => 'Alta',
        TicketPriority.media => 'Media',
        TicketPriority.bassa => 'Bassa',
      };

  /// Valida il form e, se corretto, chiude il dialog restituendo il [Ticket]
  /// creato (OP.16/OP.19).
  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      Ticket(
        id: widget.id,
        type: _type,
        vehicleId: _vehicleCtrl.text.trim(),
        subject: _subjectCtrl.text.trim(),
        priority: _priority,
        date: DateTime.now(),
        // Assegnando subito un tecnico il ticket entra "In corso" (OP.16).
        status: _technician == null
            ? TicketStatus.daAssegnare
            : TicketStatus.inCorso,
        technician: _technician,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return AlertDialog(
        title: Text('${tr('Nuovo Ticket')} · ${widget.id}'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('Tipo di ticket'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGrey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<TicketType>(
                    initialValue: _type,
                    isExpanded: true,
                    decoration: _deco('Tipo di ticket'),
                    items: TicketType.values
                        .map(
                          (t) => DropdownMenuItem<TicketType>(
                            value: t,
                            child: Text(
                              tr(_typeLabel(t)),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _type = v ?? _type),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _vehicleCtrl,
                    decoration: _deco('Codice mezzo (es. CA-015)'),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _subjectCtrl,
                    decoration: _deco("Oggetto dell'intervento"),
                    minLines: 2,
                    maxLines: 3,
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr('Priorità'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGrey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<TicketPriority>(
                    initialValue: _priority,
                    isExpanded: true,
                    decoration: _deco('Priorità'),
                    items: TicketPriority.values
                        .map(
                          (p) => DropdownMenuItem<TicketPriority>(
                            value: p,
                            child: Text(
                              tr(_priorityLabel(p)),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _priority = v ?? _priority),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr('Tecnico (opzionale)'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGrey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String?>(
                    initialValue: _technician,
                    isExpanded: true,
                    decoration: _deco('Tecnico (opzionale)'),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          tr('Non assegnato'),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      ...widget.technicians.map(
                        (tech) => DropdownMenuItem<String?>(
                          value: tech,
                          child: Text(
                            tech,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _technician = v),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('Annulla')),
          ),
          ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check, size: 18),
            label: Text(tr('Crea ticket')),
          ),
        ],
      );
    });
  }
}
