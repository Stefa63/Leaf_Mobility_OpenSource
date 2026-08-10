import 'package:flutter/material.dart';
import 'package:web_dashboard/api/api_config.dart';
import 'package:web_dashboard/api/promotions_repository.dart';
import 'package:web_dashboard/data/discount_data.dart';
import 'package:web_dashboard/data/discount_store.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/theme.dart';
import 'package:web_dashboard/widgets/common.dart';

/// Richiesta "pendente" di aprire il form di creazione all'ingresso nella
/// schermata: usata dal pannello rapido dell'Operatore ("Configura Nuovo
/// Sconto") che naviga qui e fa aprire subito il dialog di creazione.
bool _createRequested = false;

/// @brief Segnala alla [DiscountManagement] di aprire il form di creazione
/// non appena viene montata (consumata una sola volta).
void requestDiscountCreateOnOpen() => _createRequested = true;

/// @brief Gestione Sconti dell'Operatore (OP.09 / OP.15).
///
/// Configura crediti bonus per i rilasci nelle aree di parcheggio designate
/// (OP.09) e sconti percentuali programmati su perimetri geografici per
/// incentivare la domanda nelle zone meno redditizie (OP.15). I dati sono
/// alimentati da `/api/v1/promozioni` tramite [DiscountStore] (fallback ai dati
/// di riserva senza rete, IIN-6; propagazione ai mezzi entro 30s, IIN-21).
class DiscountManagement extends StatefulWidget {
  const DiscountManagement({super.key, this.autoload = true, this.repo});

  /// @brief Se true (default), carica i dati reali all'apertura; i test lo disattivano.
  final bool autoload;

  /// @brief Repository promozioni iniettabile (default singleton reale; fake nei test).
  final PromozioniApi? repo;

  @override
  State<DiscountManagement> createState() => _DiscountManagementState();
}

class _DiscountManagementState extends State<DiscountManagement> {
  int _seq = 4;

  @override
  void initState() {
    super.initState();
    if (widget.autoload && kAutoloadData) DiscountStore.carica(repo: widget.repo);
    // Apertura automatica del form se richiesta dal pannello rapido OP.
    if (_createRequested) {
      _createRequested = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openCreateDialog();
      });
    }
  }

  /// Genera il prossimo identificativo regola progressivo (es. `SC-05`).
  String _nextId() => 'SC-${(++_seq).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return ValueListenableBuilder<List<DiscountRule>>(
        valueListenable: DiscountStore.rules,
        builder: (context, rules, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: SectionHeader(
                      title: 'Gestione Sconti',
                      subtitle: 'Incentivi al parcheggio e sconti geografici',
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _openCreateDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(tr('Nuova Regola')),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _summary(rules),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: rules.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _ruleCard(rules[i]),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _summary(List<DiscountRule> rules) {
    final activeCount = rules.where((r) => r.active).length;
    int countType(DiscountType t) => rules.where((r) => r.type == t).length;
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
        pill('Regole attive', activeCount, AppTheme.statusAvailable),
        pill('Bonus parcheggio', countType(DiscountType.parkingBonus),
            AppTheme.primaryGreen),
        pill('Sconti geografici', countType(DiscountType.geoDiscount),
            AppTheme.opAccent),
      ],
    );
  }

  ({IconData icon, String label, Color color}) _typeMeta(DiscountType t) {
    switch (t) {
      case DiscountType.parkingBonus:
        return (
          icon: Icons.local_parking,
          label: 'Bonus parcheggio',
          color: AppTheme.primaryGreen,
        );
      case DiscountType.geoDiscount:
        return (
          icon: Icons.percent,
          label: 'Sconto geografico',
          color: AppTheme.opAccent,
        );
    }
  }

  Widget _ruleCard(DiscountRule r) {
    final meta = _typeMeta(r.type);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: meta.color.withAlpha(28),
              child: Icon(meta.icon, color: meta.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        r.id,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textGrey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _typeBadge(meta.label, meta.color),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr(r.name),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      _meta(Icons.place_outlined, r.area),
                      _meta(Icons.savings_outlined, tr(r.value)),
                      _meta(Icons.schedule, tr(r.period)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Switch(
                  value: r.active,
                  activeThumbColor: AppTheme.opAccent,
                  onChanged: (v) =>
                      DiscountStore.imposta(r.id, attiva: v, repo: widget.repo),
                ),
                Text(
                  tr(r.active ? 'Attiva' : 'Sospesa'),
                  style: TextStyle(
                    fontSize: 11,
                    color: r.active
                        ? AppTheme.statusAvailable
                        : AppTheme.textGrey,
                  ),
                ),
              ],
            ),
            IconButton(
              tooltip: tr('Elimina'),
              icon: const Icon(Icons.delete_outline, size: 18),
              color: AppTheme.alarmCritical,
              onPressed: () => DiscountStore.rimuovi(r.id, repo: widget.repo),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tr(label),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
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

  /// @brief Apre il form di creazione di una nuova regola di agevolazione.
  ///
  /// Il form vive in un widget dedicato ([_CreateDiscountForm]) che possiede e
  /// dispone i propri controller nel suo `dispose()`: questo evita di liberare i
  /// `TextEditingController` mentre il dialog e' ancora in chiusura (animazione),
  /// che lascerebbe i campi agganciati a controller distrutti. Al salvataggio la
  /// regola viene aggiunta alla lista in memoria; la persistenza reale passera'
  /// per `gestore_corse` / `gestore_geofencing`.
  Future<void> _openCreateDialog() async {
    final created = await showDialog<DiscountRule>(
      context: context,
      builder: (context) => _CreateDiscountForm(id: _nextId()),
    );

    if (created != null && mounted) {
      DiscountStore.aggiungi(created, repo: widget.repo);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.statusAvailable,
          content: Text(
            '${tr('Regola creata')} — ${tr('propagazione ai mezzi entro 30s')}',
          ),
        ),
      );
    }
  }
}

/// @brief Dialog di creazione di una regola di sconto (OP.09 / OP.15).
///
/// Widget con stato dedicato: possiede i controller dei campi e li dispone in
/// [dispose] (eseguito quando la route e' realmente rimossa), evitando il
/// rilascio anticipato che corrompeva l'albero alla chiusura del dialog.
/// Ritorna la [DiscountRule] creata via `Navigator.pop`, oppure null se annullato.
class _CreateDiscountForm extends StatefulWidget {
  final String id;

  const _CreateDiscountForm({required this.id});

  @override
  State<_CreateDiscountForm> createState() => _CreateDiscountFormState();
}

class _CreateDiscountFormState extends State<_CreateDiscountForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _periodCtrl = TextEditingController();
  DiscountType _type = DiscountType.parkingBonus;
  bool _active = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _areaCtrl.dispose();
    _valueCtrl.dispose();
    _periodCtrl.dispose();
    super.dispose();
  }

  static ({IconData icon, String label, Color color}) _typeMeta(
    DiscountType t,
  ) {
    switch (t) {
      case DiscountType.parkingBonus:
        return (
          icon: Icons.local_parking,
          label: 'Bonus parcheggio',
          color: AppTheme.primaryGreen,
        );
      case DiscountType.geoDiscount:
        return (
          icon: Icons.percent,
          label: 'Sconto geografico',
          color: AppTheme.opAccent,
        );
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? tr('Campo obbligatorio') : null;

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: tr(hint),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      DiscountRule(
        id: widget.id,
        type: _type,
        name: _nameCtrl.text.trim(),
        area: _areaCtrl.text.trim(),
        value: _valueCtrl.text.trim(),
        period: _periodCtrl.text.trim(),
        active: _active,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return AlertDialog(
        title: Text(tr('Nuova Regola')),
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
                    tr('Tipo di incentivo'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGrey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<DiscountType>(
                    initialValue: _type,
                    isExpanded: true,
                    decoration: _deco('Tipo di incentivo'),
                    items: DiscountType.values
                        .map(
                          (t) => DropdownMenuItem<DiscountType>(
                            value: t,
                            child: Text(
                              tr(_typeMeta(t).label),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _type = v ?? _type),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: _deco('Nome della regola'),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _areaCtrl,
                    decoration: _deco('Area geografica'),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _valueCtrl,
                    decoration: _deco(
                      _type == DiscountType.parkingBonus
                          ? 'Valore (es. +0,50 € credito)'
                          : 'Valore (es. -20% avvio corsa)',
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _periodCtrl,
                    decoration: _deco('Periodo (es. Lun–Ven 07:00–10:00)'),
                    validator: _required,
                  ),
                  const SizedBox(height: 4),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppTheme.opAccent,
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                    title: Text(
                      tr('Attiva alla creazione'),
                      style: const TextStyle(fontSize: 13),
                    ),
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
            label: Text(tr('Crea regola')),
          ),
        ],
      );
    });
  }
}
