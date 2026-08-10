import 'package:flutter/material.dart';
import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/fleet_repository.dart';
import 'package:web_dashboard/data/alerts_store.dart';
import 'package:web_dashboard/data/fleet_data.dart';
import 'package:web_dashboard/data/fleet_store.dart';
import 'package:web_dashboard/data/sos_store.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/screens/active_bookings.dart';
import 'package:web_dashboard/screens/discount_management.dart';
import 'package:web_dashboard/screens/fleet_diagnostics.dart';
import 'package:web_dashboard/screens/geofencing_screen.dart';
import 'package:web_dashboard/screens/notifications_screen.dart';
import 'package:web_dashboard/screens/profile_screen.dart';
import 'package:web_dashboard/screens/settings_screen.dart';
import 'package:web_dashboard/screens/support_queue.dart';
import 'package:web_dashboard/screens/telemetry_viewer.dart';
import 'package:web_dashboard/screens/threshold_config.dart';
import 'package:web_dashboard/screens/ticket_management.dart';
import 'package:web_dashboard/screens/user_admin.dart';
import 'package:web_dashboard/theme.dart';
import 'package:web_dashboard/widgets/common.dart';
import 'package:web_dashboard/widgets/dashboard_shell.dart';
import 'package:web_dashboard/widgets/google_city_map.dart';

/// @brief Console dell'Operatore del Servizio (OP).
///
/// Vista operativa/tattica: coda allarmi real-time (SOS, fuori area, logistica),
/// mappa flotta Google con stato telemetrico per mezzo (OP.01/OP.20), filtri
/// rapidi e azioni operative (sblocco/blocco remoto, ticket, sospensione utente,
/// sconti). Gestione ticket, profilo e notifiche in sezioni dedicate.
class OpDashboard extends StatelessWidget {
  const OpDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <DashboardSection>[
      DashboardSection(
        icon: Icons.support_agent,
        label: 'Centro Operativo',
        builder: (context) => const _OpHome(),
      ),
      DashboardSection(
        icon: Icons.map_outlined,
        label: 'Mappa Flotta Live',
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            SectionHeader(
              title: 'Mappa Flotta Live',
              subtitle: 'Vista Flotta e Telemetria',
            ),
            SizedBox(height: 16),
            Expanded(child: OpFleetMap()),
          ],
        ),
      ),
      DashboardSection(
        icon: Icons.monitor_heart_outlined,
        label: 'Diagnostica Flotta',
        builder: (context) => const FleetDiagnostics(),
      ),
      DashboardSection(
        icon: Icons.sensors_outlined,
        label: 'Telemetria',
        builder: (context) => const TelemetryViewer(),
      ),
      DashboardSection(
        icon: Icons.tune_outlined,
        label: 'Config Soglie',
        builder: (context) => const ThresholdConfig(),
      ),
      DashboardSection(
        icon: Icons.event_available_outlined,
        label: 'Prenotazioni Attive',
        builder: (context) => const ActiveBookings(),
      ),
      DashboardSection(
        icon: Icons.layers_outlined,
        label: 'Aree Operative',
        builder: (context) => const GeofencingScreen(),
      ),
      DashboardSection(
        icon: Icons.build_outlined,
        label: 'Gestione Ticket',
        builder: (context) => const TicketManagement(),
      ),
      DashboardSection(
        icon: Icons.forum_outlined,
        label: 'Coda Assistenza',
        builder: (context) => const SupportQueue(),
      ),
      DashboardSection(
        icon: Icons.percent_outlined,
        label: 'Gestione Sconti',
        builder: (context) => const DiscountManagement(),
      ),
      DashboardSection(
        icon: Icons.manage_accounts_outlined,
        label: 'Gestione Utenti/AP',
        builder: (context) => const UserAdmin(),
      ),
    ];

    return DashboardShell(
      accent: AppTheme.opAccent,
      sections: sections,
      profileLabel: tr('Profilo Operatore'),
      profileBuilder: (context) => const ProfileScreen(accent: AppTheme.opAccent),
      notificationsBuilder: (context) =>
          const NotificationsScreen(accent: AppTheme.opAccent),
      settingsBuilder: (context) =>
          const SettingsScreen(accent: AppTheme.opAccent),
    );
  }
}

/// Home dell'Operatore (Centro Operativo).
class _OpHome extends StatelessWidget {
  const _OpHome();

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Centro Operativo',
              subtitle: 'Coda Allarmi e Notifiche Real-Time',
            ),
            const SizedBox(height: 18),
            // ── Coda allarmi prioritari ──────────────────────────────────
            _alarmQueue(),
            const SizedBox(height: 18),
            // ── Mappa flotta + azioni rapide ─────────────────────────────
            LayoutBuilder(
              builder: (context, c) {
                final narrow = c.maxWidth < 1000;
                const map = SizedBox(height: 480, child: OpFleetMap());
                final panel = _actionsPanel(context);
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [map, const SizedBox(height: 18), panel],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(flex: 3, child: map),
                    const SizedBox(width: 18),
                    SizedBox(width: 300, child: panel),
                  ],
                );
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _alarmQueue() {
    // Coda allarmi interamente reale: SOS da `/sos` (UT.20/OP.08) + allerte
    // logistiche/batteria da `/soglie/allerte` (OP.02/OP.22). Nessun allarme fabbricato:
    // se non ci sono segnalazioni o allerte reali si mostra lo stato "nessun allarme".
    return ValueListenableBuilder<List<SosSegnalazione>>(
      valueListenable: SosStore.sos,
      builder: (context, sosList, _) {
        return ValueListenableBuilder<List<FleetAlert>>(
          valueListenable: AlertsStore.allerte,
          builder: (context, allerte, _) {
            return LayoutBuilder(
              builder: (context, c) {
                final twoCols = c.maxWidth < 1100;
                final w = twoCols ? c.maxWidth : (c.maxWidth - 32) / 3;
                final tiles = <Widget>[
                  // SOS reali in cima (priorità massima), poi le allerte di soglia.
                  for (final s in sosList)
                    SizedBox(width: w, child: _sosTile(context, s)),
                  for (final a in allerte) SizedBox(width: w, child: _alertTile(a)),
                ];
                if (tiles.isEmpty) return _nessunAllarme();
                return Wrap(spacing: 16, runSpacing: 12, children: tiles);
              },
            );
          },
        );
      },
    );
  }

  /// @brief Stato neutro della coda allarmi quando non ci sono SOS né allerte reali.
  /// @return La tessera informativa "Nessun allarme attivo".
  Widget _nessunAllarme() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.statusAvailable.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppTheme.statusAvailable,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            tr('Nessun allarme attivo'),
            style: const TextStyle(color: AppTheme.textGrey),
          ),
        ],
      ),
    );
  }

  /// @brief Tessera di una segnalazione SOS reale, azionabile dall'operatore (OP.08).
  /// @param context Contesto per il dialog delle azioni.
  /// @param s Segnalazione SOS da rappresentare.
  /// @return La [AlarmTile] critica con tocco per la presa in carico/chiusura.
  Widget _sosTile(BuildContext context, SosSegnalazione s) {
    final inCarico = s.stato == 'presa_in_carico';
    final dettagli = <String>[
      if (s.zona != null) s.zona!,
      if (inCarico) tr('Presa in carico'),
    ];
    return AlarmTile(
      color: AppTheme.alarmCritical,
      icon: Icons.sos,
      title: '${tr('SOS Attivo')}: ${s.utente}',
      subtitle: dettagli.isEmpty ? tr('Tocca per gestire') : dettagli.join(' · '),
      onTap: () => _azioniSos(context, s),
    );
  }

  /// @brief Dialog delle azioni su una segnalazione SOS: presa in carico/chiusura (OP.08).
  /// @param context Contesto per il dialog e gli avvisi.
  /// @param s Segnalazione SOS su cui agire.
  Future<void> _azioniSos(BuildContext context, SosSegnalazione s) async {
    final azione = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('${tr('SOS')} · ${s.utente}'),
        children: [
          if (s.stato != 'presa_in_carico')
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'presa_in_carico'),
              child: Row(
                children: [
                  const Icon(Icons.assignment_ind_outlined, size: 18),
                  const SizedBox(width: 10),
                  Text(tr('Prendi in carico')),
                ],
              ),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'chiusa'),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 18),
                const SizedBox(width: 10),
                Text(tr('Chiudi segnalazione')),
              ],
            ),
          ),
        ],
      ),
    );
    if (azione == null) return;
    try {
      await SosStore.aggiornaStato(s.id, azione);
    } on LeafApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.alarmCritical,
            content: Text(e.messaggio),
          ),
        );
      }
    }
  }

  /// @brief Converte un'allerta di soglia reale nella relativa tessera allarme.
  ///
  /// @param a Allerta tipizzata (`mezzi_area` per OP.02, `batteria` per OP.22).
  /// @return La [AlarmTile] corrispondente, con colore/icona coerenti al tipo.
  Widget _alertTile(FleetAlert a) {
    if (a.tipo == 'batteria') {
      return AlarmTile(
        color: AppTheme.alarmWarning,
        icon: Icons.battery_alert,
        title: '${tr('Batteria')}: ${a.mezzo ?? '—'}',
        subtitle: '${a.batteria ?? 0}% < ${a.soglia ?? 0}%',
      );
    }
    return AlarmTile(
      color: AppTheme.alarmInfo,
      icon: Icons.inventory_2_outlined,
      title: '${tr('Logistica')}: ${a.area ?? '—'}',
      subtitle:
          '${a.presenti ?? 0}/${a.minimo ?? 0} ${tr('mezzi')} · ${tr('sotto soglia minima')}',
    );
  }

  Widget _actionsPanel(BuildContext context) {
    final scope = DashboardScope.of(context);
    return PanelCard(
      title: 'Azioni Rapide',
      icon: Icons.flash_on,
      accent: AppTheme.opAccent,
      child: Column(
        children: [
          QuickActionButton(
            icon: Icons.lock_open,
            label: 'Sblocco/Blocco Remoto',
            accent: AppTheme.opAccent,
            onPressed: () => showRemoteLockDialog(context),
          ),
          QuickActionButton(
            icon: Icons.build,
            label: 'Crea Ticket Riparazione',
            accent: AppTheme.opAccent,
            onPressed: () => scope?.jumpToLabel('Gestione Ticket'),
          ),
          QuickActionButton(
            icon: Icons.person_off,
            label: 'Sospendi Utente',
            accent: AppTheme.opAccent,
            onPressed: () => scope?.jumpToLabel('Gestione Utenti/AP'),
          ),
          QuickActionButton(
            icon: Icons.local_offer,
            label: 'Configura Nuovo Sconto',
            accent: AppTheme.opAccent,
            onPressed: () {
              requestDiscountCreateOnOpen();
              scope?.jumpToLabel('Gestione Sconti');
            },
          ),
        ],
      ),
    );
  }
}

/// @brief Dialog di sblocco/blocco motore remoto di un mezzo (OP.11).
///
/// Self-contained: seleziona un mezzo dalla flotta e invia il comando. Blocco e
/// sblocco motore sono cablati agli endpoint reali
/// `/api/v1/mezzi/{codice}/blocco-motore` e `/sblocco-motore` (che inoltrano a
/// `gateway_iot`).
/// @param context Contesto per il dialog e i feedback.
/// @param repo Repository flotta iniettabile (default reale; fittizio nei test).
Future<void> showRemoteLockDialog(
  BuildContext context, {
  FlottaApi? repo,
}) async {
  Vehicle selected = FleetData.vehicles.first;
  final result = await showDialog<(Vehicle, bool)>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            title: Text(tr('Sblocco/Blocco Remoto')),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('Seleziona il mezzo'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Vehicle>(
                    initialValue: selected,
                    isExpanded: true,
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: FleetData.vehicles
                        .map(
                          (v) => DropdownMenuItem<Vehicle>(
                            value: v,
                            child: Text(
                              '${v.id} · ${tr(vehicleTypeLabel(v.type))} · '
                              '${tr(vehicleStatusLabel(v.status))}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setLocal(() => selected = v ?? selected),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(tr('Annulla')),
              ),
              TextButton.icon(
                onPressed: () => Navigator.pop(context, (selected, false)),
                icon: const Icon(Icons.lock_outline, size: 18),
                label: Text(tr('Blocca')),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, (selected, true)),
                icon: const Icon(Icons.lock_open, size: 18),
                label: Text(tr('Sblocca')),
              ),
            ],
          );
        },
      );
    },
  );

  if (result == null || !context.mounted) return;
  final (vehicle, unlock) = result;
  final messenger = ScaffoldMessenger.of(context);
  final api = repo ?? fleetRepository;

  // Blocco/sblocco motore remoto reale (OP.11) via gli endpoint dedicati.
  try {
    if (unlock) {
      await api.sbloccoMotore(vehicle.id);
    } else {
      await api.bloccoMotore(vehicle.id);
    }
    if (!context.mounted) return;
    final esito = unlock
        ? tr('Comando di sblocco inviato')
        : tr('Comando di blocco inviato');
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.opAccent,
        content: Text('$esito — ${vehicle.id}'),
      ),
    );
  } on LeafApiException {
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.alarmCritical,
        content: Text('${tr('Invio comando non riuscito')} — ${vehicle.id}'),
      ),
    );
  }
}

/// @brief Mappa flotta Google con filtri di stato rapidi (OP.01 / OP.20).
///
/// Estratta come widget riusabile: usata sia nella home (Centro Operativo) che
/// nella sezione "Mappa Flotta Live". Cartografia reale via [GoogleCityMap].
class OpFleetMap extends StatefulWidget {
  const OpFleetMap({super.key});

  @override
  State<OpFleetMap> createState() => _OpFleetMapState();
}

class _OpFleetMapState extends State<OpFleetMap> {
  final Set<VehicleStatus> _active = {
    VehicleStatus.inUse,
    VehicleStatus.available,
    VehicleStatus.maintenance,
    VehicleStatus.lowBattery,
  };

  // Filtro per tipologia di mezzo (OP.01 / OP.20): tutte attive di default.
  final Set<VehicleType> _types = {...VehicleType.values};

  // Visibilita' dei layer non-flotta sulla mappa.
  bool _showCharging = true;
  bool _showTpl = true;

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.my_location,
                      size: 18, color: AppTheme.opAccent),
                  const SizedBox(width: 8),
                  Text(
                    tr('Vista Flotta e Telemetria'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _filterLabel('Stato'),
              const SizedBox(height: 6),
              _statusChips(),
              const SizedBox(height: 10),
              _filterLabel('Tipo di veicolo'),
              const SizedBox(height: 6),
              _typeChips(),
              const SizedBox(height: 10),
              _filterLabel('Layer mappa'),
              const SizedBox(height: 6),
              _layerChips(),
              // IIN-6 — avviso dati di riserva quando /flotta non risponde.
              ValueListenableBuilder<bool>(
                valueListenable: FleetStore.offline,
                builder: (context, offline, _) => offline
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _offlineBanner(),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GoogleCityMap(
                  statusFilter: _active,
                  typeFilters: _types,
                  showCharging: _showCharging,
                  showTpl: _showTpl,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _filterLabel(String key) {
    return Text(
      tr(key),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppTheme.textGrey,
      ),
    );
  }

  Widget _statusChips() {
    final filters = <(VehicleStatus, String)>[
      (VehicleStatus.inUse, 'Mezzi in Uso'),
      (VehicleStatus.available, 'Mezzi Disponibili'),
      (VehicleStatus.maintenance, 'Mezzi in Manutenzione'),
      (VehicleStatus.lowBattery, 'Batteria < 15% (Critica)'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters.map((f) {
        final sel = _active.contains(f.$1);
        final col = vehicleStatusColor(f.$1);
        return FilterChip(
          selected: sel,
          showCheckmark: true,
          checkmarkColor: Colors.white,
          label: Text(tr(f.$2)),
          backgroundColor: Colors.white,
          selectedColor: col,
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: sel ? Colors.white : AppTheme.textDark,
          ),
          side: BorderSide(color: sel ? col : Colors.black12),
          onSelected: (v) => setState(() {
            if (v) {
              _active.add(f.$1);
            } else {
              _active.remove(f.$1);
            }
          }),
        );
      }).toList(),
    );
  }

  Widget _typeChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: VehicleType.values.map((t) {
        final sel = _types.contains(t);
        final col = vehicleTypeColor(t);
        return FilterChip(
          selected: sel,
          showCheckmark: false,
          avatar: Icon(
            vehicleTypeIcon(t),
            size: 16,
            color: sel ? Colors.white : col,
          ),
          label: Text(tr(vehicleTypeLabel(t))),
          backgroundColor: Colors.white,
          selectedColor: col,
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: sel ? Colors.white : AppTheme.textDark,
          ),
          side: BorderSide(color: sel ? col : Colors.black12),
          onSelected: (v) => setState(() {
            if (v) {
              _types.add(t);
            } else {
              _types.remove(t);
            }
          }),
        );
      }).toList(),
    );
  }

  Widget _layerChips() {
    Widget toggle(IconData icon, String label, Color col, bool sel,
        ValueChanged<bool> onSel) {
      return FilterChip(
        selected: sel,
        showCheckmark: false,
        avatar: Icon(icon, size: 16, color: sel ? Colors.white : col),
        label: Text(tr(label)),
        backgroundColor: Colors.white,
        selectedColor: col,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: sel ? Colors.white : AppTheme.textDark,
        ),
        side: BorderSide(color: sel ? col : Colors.black12),
        onSelected: onSel,
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        toggle(Icons.ev_station, 'Ricarica', const Color(0xFFFBC02D),
            _showCharging, (v) => setState(() => _showCharging = v)),
        toggle(Icons.directions_bus, 'Trasporto Pubblico (TPL)',
            const Color(0xFF8E24AA), _showTpl,
            (v) => setState(() => _showTpl = v)),
      ],
    );
  }

  /// Banner compatto che segnala l'uso dei dati di riserva flotta (IIN-6).
  Widget _offlineBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE65100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 16, color: Color(0xFFE65100)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              tr('Dati non aggiornati (offline)'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE65100),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: FleetStore.carica,
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
