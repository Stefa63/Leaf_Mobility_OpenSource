import 'package:flutter/material.dart';
import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/api_config.dart';
import 'package:web_dashboard/api/prenotazioni_repository.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/theme.dart';
import 'package:web_dashboard/widgets/common.dart';

/// @brief Prenotazione attiva mostrata nella console operatore (OP.12).
class _Booking {
  _Booking({
    required this.id,
    required this.utente,
    required this.mezzo,
    required this.tipo,
    this.inizio,
    this.scadenza,
  });

  /// @brief Costruisce una [_Booking] dal documento di `/api/v1/prenotazioni/attive`.
  /// @param d Documento prenotazione (con etichetta utente risolta lato server).
  /// @return La prenotazione mappata, o null se priva di identificativo.
  static _Booking? daApi(Map<String, dynamic> d) {
    final id = d['_id']?.toString();
    if (id == null || id.isEmpty) return null;
    final nominativo = d['nominativo']?.toString();
    final username = d['username']?.toString();
    final utente = (nominativo != null && nominativo.isNotEmpty)
        ? nominativo
        : (username != null && username.isNotEmpty)
        ? '@$username'
        : (d['id_utente']?.toString() ?? '—');
    return _Booking(
      id: id,
      utente: utente,
      mezzo: (d['codice_identificativo_mezzo'] ?? d['id_mezzo'] ?? '—').toString(),
      tipo: (d['tipo_mezzo'] ?? '').toString(),
      inizio: d['data_ora_inizio']?.toString(),
      scadenza: d['scadenza']?.toString(),
    );
  }

  final String id;
  final String utente;
  final String mezzo;
  final String tipo;
  final String? inizio;
  final String? scadenza;
}

/// @brief Prenotazioni attive con annullamento forzato dall'operatore (OP.12).
///
/// L'Operatore vede le prenotazioni attive sull'intera flotta (con l'utente che
/// trattiene il mezzo) e può forzarne l'annullamento per rimettere a disposizione
/// della community un mezzo trattenuto in modo anomalo, senza l'avvio della corsa.
/// I dati arrivano da `/api/v1/prenotazioni/attive`; senza rete (IIN-6) si mostra
/// lo stato vuoto con banner offline, mai dati fabbricati.
class ActiveBookings extends StatefulWidget {
  const ActiveBookings({super.key, this.autoload = true, this.repo});

  /// @brief Se true (default), carica i dati reali all'apertura; i test lo disattivano.
  final bool autoload;

  /// @brief Repository iniettabile (default singleton reale; fake nei test).
  final PrenotazioniOpApi? repo;

  @override
  State<ActiveBookings> createState() => _ActiveBookingsState();
}

class _ActiveBookingsState extends State<ActiveBookings> {
  final List<_Booking> _prenotazioni = [];
  bool _offline = false;
  bool _caricato = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoload && kAutoloadData) _carica();
  }

  /// @brief Carica le prenotazioni attive dal backend (OP.12); in errore segnala offline.
  Future<void> _carica() async {
    try {
      final docs = await (widget.repo ?? prenotazioniOpRepository).attive();
      if (!mounted) return;
      setState(() {
        _prenotazioni
          ..clear()
          ..addAll(docs.map(_Booking.daApi).whereType<_Booking>());
        _offline = false;
        _caricato = true;
      });
    } on LeafApiException {
      if (mounted) setState(() => _offline = true);
    }
  }

  /// @brief Forza l'annullamento di una prenotazione previa conferma (OP.12).
  /// @param b Prenotazione da annullare.
  Future<void> _annulla(_Booking b) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Annulla prenotazione')),
        content: Text(
          '${tr('Confermi l\'annullamento della prenotazione del mezzo')} ${b.mezzo} '
          '(${b.utente})? ${tr('Il mezzo tornerà disponibile.')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('Annulla')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.alarmCritical,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('Conferma')),
          ),
        ],
      ),
    );
    if (conferma != true) return;
    try {
      await (widget.repo ?? prenotazioniOpRepository).annulla(b.id);
      await _carica();
    } on LeafApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.alarmCritical,
          content: Text(e.messaggio),
        ),
      );
    }
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
                  title: 'Prenotazioni Attive',
                  subtitle: 'Mezzi prenotati senza corsa avviata',
                ),
              ),
              IconButton(
                tooltip: tr('Aggiorna'),
                onPressed: _carica,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_offline)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, size: 15, color: AppTheme.alarmWarning),
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
            ),
          Expanded(
            child: _prenotazioni.isEmpty
                ? Center(
                    child: Text(
                      _caricato
                          ? tr('Nessuna prenotazione attiva')
                          : tr('Caricamento…'),
                      style: const TextStyle(color: AppTheme.textGrey),
                    ),
                  )
                : ListView.separated(
                    itemCount: _prenotazioni.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _card(_prenotazioni[i]),
                  ),
          ),
        ],
      );
    });
  }

  Widget _card(_Booking b) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.opAccent.withAlpha(28),
              child: const Icon(
                Icons.event_available,
                color: AppTheme.opAccent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.mezzo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    b.tipo.isEmpty ? b.utente : '${b.utente} · ${b.tipo}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textGrey,
                    ),
                  ),
                  if (b.scadenza != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${tr('Scadenza')}: ${b.scadenza}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.alarmCritical,
              ),
              onPressed: () => _annulla(b),
              icon: const Icon(Icons.cancel_outlined, size: 16),
              label: Text(tr('Annulla')),
            ),
          ],
        ),
      ),
    );
  }
}
