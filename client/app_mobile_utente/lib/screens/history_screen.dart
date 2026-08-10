import 'package:flutter/material.dart';
import 'package:app_mobile_utente/api/corse_repository.dart';
import 'package:app_mobile_utente/theme.dart';
import 'package:app_mobile_utente/screens/trip_detail_screen.dart';
import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/widgets/stato_vista.dart';

/// A single trip entry in the history. UT.17.
class TripEntry {
  final String id;
  final String date;
  final String time;
  final String from;
  final String to;
  final String vehicleType;
  final double cost;
  final int durationMinutes;
  final double distanceKm;

  const TripEntry({
    required this.id,
    required this.date,
    required this.time,
    required this.from,
    required this.to,
    required this.vehicleType,
    required this.cost,
    required this.durationMinutes,
    required this.distanceKm,
  });

  /// @brief Costruisce una voce di cronologia da un documento corsa della API (UT.17).
  ///
  /// Mappa i campi del documento `corse` (snake_case lato server) sul modello di
  /// vista. Il documento corsa non porta i nomi di partenza/arrivo (il modello
  /// dati non li registra): si usa il codice del mezzo come riferimento e l'arrivo
  /// resta non disponibile ('—'). Importi in centesimi → euro; tipo mezzo
  /// normalizzato sulle etichette già usate dalla UI.
  ///
  /// @param doc Documento corsa grezzo restituito da `/api/v1/corse`.
  /// @param progressivo Identificativo progressivo assegnato per l'ordinamento.
  /// @return La voce [TripEntry] corrispondente.
  factory TripEntry.daApi(Map<String, dynamic> doc, {required int progressivo}) {
    final centesimi =
        (doc['costo_finale_cent'] ?? doc['costo_stimato_cent'] ?? 0) as num;
    final inizio = DateTime.tryParse('${doc['data_ora_inizio'] ?? ''}');
    final codice = (doc['codice_identificativo_mezzo'] ?? '—').toString();
    return TripEntry(
      id: '#${progressivo.toString().padLeft(4, '0')}',
      date: inizio == null
          ? '—'
          : '${inizio.day.toString().padLeft(2, '0')}/${inizio.month.toString().padLeft(2, '0')}',
      time: inizio == null
          ? ''
          : '${inizio.hour.toString().padLeft(2, '0')}:${inizio.minute.toString().padLeft(2, '0')}',
      from: codice,
      to: '—',
      vehicleType: _etichettaTipo('${doc['tipo_mezzo'] ?? ''}'),
      cost: centesimi / 100.0,
      durationMinutes: (doc['durata_min'] ?? 0) as int,
      distanceKm: ((doc['km_percorsi'] ?? 0) as num).toDouble(),
    );
  }

  /// @brief Normalizza il discriminante `tipo_mezzo` del server sull'etichetta UI.
  /// @param tipo Tipo mezzo lato server (ebike/monopattino/ecar/emotorbike).
  /// @return Etichetta coerente con le icone di [_TripTile] (E-Bike/Auto/E-Moto/Scooter).
  static String _etichettaTipo(String tipo) {
    switch (tipo) {
      case 'ebike':
        return 'E-Bike';
      case 'ecar':
        return 'Auto';
      case 'emotorbike':
        return 'E-Moto';
      default:
        return 'Scooter';
    }
  }

  /// Progressivo numerico ricavato dall'id (es. '#0010' -> 10).
  ///
  /// Le corse sono registrate in ordine cronologico crescente di id, quindi
  /// questo valore funge da chiave di ordinamento affidabile per data/ora.
  int get sequence => int.tryParse(id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
}

/// @brief Converte i documenti corsa della API in voci di cronologia ordinabili.
///
/// La API restituisce le corse dalla più recente; si assegna un progressivo
/// decrescente così che [TripEntry.sequence] rifletta l'ordine cronologico
/// (valore più alto = corsa più recente), coerente con l'ordinamento "Data".
///
/// @param corse Lista di documenti corsa grezzi da `/api/v1/corse`.
/// @return Lista di [TripEntry] pronte per la vista.
List<TripEntry> corseInVoci(List<Map<String, dynamic>> corse) {
  final totale = corse.length;
  return [
    for (var i = 0; i < totale; i++)
      TripEntry.daApi(corse[i], progressivo: totale - i),
  ];
}

/// Criteri di ordinamento disponibili per la cronologia delle corse. UT.17.
enum _SortField { data, durata, distanza, costo }

/// Trip history screen — UT.17 (storico corse: tragitti e spese).
///
/// Connected with the home tab history section and drawer Cronologia item.
/// Permette di consultare le corse ordinandole secondo diversi criteri
/// (data, durata, distanza, costo) in ordine crescente o decrescente.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, CorseApi? corse}) : _corse = corse;

  /// Repository corse iniettabile (default reale; fittizio nei test).
  final CorseApi? _corse;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  /// Criterio di ordinamento corrente.
  _SortField _sortField = _SortField.data;

  /// Ordine decrescente (più recente / più alto prima) quando true.
  bool _descending = true;

  /// Repository risolto: quello iniettato (test) o il singleton reale.
  late final CorseApi _corse = widget._corse ?? corseRepository;

  /// Etichetta localizzata associata a un criterio di ordinamento.
  String _labelFor(_SortField field) {
    switch (field) {
      case _SortField.data:
        return tr('Data');
      case _SortField.durata:
        return tr('Durata');
      case _SortField.distanza:
        return tr('Distanza');
      case _SortField.costo:
        return tr('Costo');
    }
  }

  /// Ordina una lista di corse secondo criterio e direzione correnti.
  /// @param trips Lista di partenza (non modificata).
  /// @return Nuova lista ordinata.
  List<TripEntry> _ordina(List<TripEntry> trips) {
    final ordinate = List<TripEntry>.of(trips);
    ordinate.sort((a, b) {
      final int cmp;
      switch (_sortField) {
        case _SortField.data:
          cmp = a.sequence.compareTo(b.sequence);
        case _SortField.durata:
          cmp = a.durationMinutes.compareTo(b.durationMinutes);
        case _SortField.distanza:
          cmp = a.distanceKm.compareTo(b.distanceKm);
        case _SortField.costo:
          cmp = a.cost.compareTo(b.cost);
      }
      return _descending ? -cmp : cmp;
    });
    return ordinate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Cronologia Corse')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: _descending
                ? tr('Ordine decrescente')
                : tr('Ordine crescente'),
            icon: Icon(_descending ? Icons.arrow_downward : Icons.arrow_upward),
            onPressed: () => setState(() => _descending = !_descending),
          ),
        ],
      ),
      // UT.17 — storico reale dell'utente via repository; stati di
      // caricamento/errore(retry)/vuoto uniformi (FASE 2.B).
      body: CaricatoreVista<List<TripEntry>>(
        carica: () async => corseInVoci(await _corse.storico()),
        vuotoSe: (trips) => trips.isEmpty,
        vistaVuota: VistaVuota(
          titolo: tr('Nessuna corsa registrata'),
          sottotitolo: tr('Le corse che completi appariranno qui.'),
          icona: Icons.directions_bike_outlined,
        ),
        costruisci: (context, trips) => _contenuto(trips),
      ),
    );
  }

  /// Corpo della schermata a dati disponibili: riepilogo, ordinamento e lista.
  /// @param caricate Corse caricate dalla API (non ancora ordinate).
  Widget _contenuto(List<TripEntry> caricate) {
    final trips = _ordina(caricate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary strip
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: AppTheme.surfaceColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryChip(
                icon: Icons.directions_bike_outlined,
                label: '${caricate.length} ${tr('corse')}',
              ),
              _SummaryChip(
                icon: Icons.straighten_outlined,
                label:
                    '${caricate.fold(0.0, (s, t) => s + t.distanceKm).toStringAsFixed(1)} km',
              ),
              _SummaryChip(
                icon: Icons.euro_outlined,
                label:
                    '${caricate.fold(0.0, (s, t) => s + t.cost).toStringAsFixed(2)} €',
              ),
            ],
          ),
        ),
        _buildSortBar(),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: trips.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, i) => _TripTile(trip: trips[i]),
          ),
        ),
      ],
    );
  }

  /// Barra di selezione del criterio di ordinamento (chip orizzontali).
  Widget _buildSortBar() {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Text(
                '${tr('Ordina per')}:',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          for (final field in _SortField.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(_labelFor(field)),
                selected: _sortField == field,
                showCheckmark: false,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _sortField == field ? Colors.white : AppTheme.textDark,
                ),
                backgroundColor: Colors.white,
                selectedColor: AppTheme.primaryGreen,
                side: BorderSide(
                  color: _sortField == field
                      ? AppTheme.primaryGreen
                      : AppTheme.textGrey.withValues(alpha: 0.3),
                ),
                onSelected: (_) => setState(() => _sortField = field),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SummaryChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: AppTheme.accentBrown),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textDark,
        ),
      ),
    ],
  );
}

class _TripTile extends StatelessWidget {
  final TripEntry trip;
  const _TripTile({required this.trip});

  IconData get _icon {
    switch (trip.vehicleType) {
      case 'E-Bike':
        return Icons.pedal_bike;
      case 'Auto':
        return Icons.directions_car;
      case 'E-Moto':
        return Icons.electric_moped;
      default:
        return Icons.electric_scooter;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
      ),
      leading: CircleAvatar(
        backgroundColor: AppTheme.surfaceColor,
        child: Icon(_icon, color: AppTheme.accentBrown, size: 22),
      ),
      title: Row(
        children: [
          Text(
            trip.id,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${trip.from} → ${trip.to}',
              style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: Text(
        '${trip.date} ${trip.time}  ·  ${trip.vehicleType}  ·  ${trip.distanceKm} km  ·  ${trip.durationMinutes} min',
        style: const TextStyle(fontSize: 11, color: AppTheme.textGrey),
      ),
      trailing: Text(
        '${trip.cost.toStringAsFixed(2)} €',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: AppTheme.darkGreen,
        ),
      ),
    );
  }
}
