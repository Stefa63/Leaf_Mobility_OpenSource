import 'package:flutter/material.dart';
import 'package:web_dashboard/data/alerts_store.dart';
import 'package:web_dashboard/data/fleet_store.dart';
import 'package:web_dashboard/data/notifications_store.dart';
import 'package:web_dashboard/data/sos_store.dart';
import 'package:web_dashboard/screens/ap_dashboard.dart';
import 'package:web_dashboard/screens/op_dashboard.dart';
import 'package:web_dashboard/session.dart';

/// @brief Instrada alla console corretta in base al ruolo di [Session].
///
/// Stessa pagina di login per OP e AP; dopo l'accesso la dashboard di lavoro
/// differisce: OP → [OpDashboard], AP → [ApDashboard]. RBAC (IIN-5). All'ingresso
/// avvia il caricamento dello stato flotta dal backend (FASE 2.C): unico punto di
/// innesco, così le viste mappa restano testabili senza rete.
class HomeRouter extends StatefulWidget {
  const HomeRouter({super.key});

  @override
  State<HomeRouter> createState() => _HomeRouterState();
}

class _HomeRouterState extends State<HomeRouter> {
  @override
  void initState() {
    super.initState();
    FleetStore.carica(); // popola lo store dai dati reali (OP.01/OP.20/AP.10)
    AlertsStore.carica(); // allerte di soglia per la coda allarmi OP (OP.02/OP.22)
    NotificationsStore.carica(); // centro notifiche e badge campana reali (IIN-19)
    if (!Session.isPublicAdmin) {
      SosStore.carica(); // coda SOS live per la console operatore (UT.20/OP.08)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Session.isPublicAdmin ? const ApDashboard() : const OpDashboard();
  }
}
