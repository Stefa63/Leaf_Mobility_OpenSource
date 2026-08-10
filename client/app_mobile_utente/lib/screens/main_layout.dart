import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app_mobile_utente/theme.dart';
import 'package:app_mobile_utente/screens/home_tab.dart';
import 'package:app_mobile_utente/screens/map_tab.dart';
import 'package:app_mobile_utente/screens/booking_tab.dart';
import 'package:app_mobile_utente/widgets/drawer_menu.dart';
import 'package:app_mobile_utente/screens/profile_screen.dart';
import 'package:app_mobile_utente/screens/notifications_screen.dart';
import 'package:app_mobile_utente/screens/subscription_manager_screen.dart';
import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/profile_store.dart';
import 'package:app_mobile_utente/active_trip_store.dart';
import 'package:app_mobile_utente/api/api_client.dart';
import 'package:app_mobile_utente/api/profilo_repository.dart';
import 'package:app_mobile_utente/api/corse_repository.dart';

/// @brief Richiesta esterna di selezione di una tab della home.
///
/// Una route pushata sopra la home (es. il dettaglio tratta) può chiedere di
/// tornare alla home su una tab specifica valorizzando questo notifier prima del
/// pop: [MainLayout] lo osserva e aggiorna la tab corrente. Indice tab (2 = Mappa)
/// o null se nessuna richiesta pendente.
final ValueNotifier<int?> richiestaTabHome = ValueNotifier<int?>(null);

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    richiestaTabHome.addListener(_applicaRichiestaTab);
    _sincronizzaStato();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    richiestaTabHome.removeListener(_applicaRichiestaTab);
    super.dispose();
  }

  /// Applica una richiesta esterna di cambio tab (es. "Vedi su mappa", #4).
  void _applicaRichiestaTab() {
    final idx = richiestaTabHome.value;
    if (idx != null && mounted) {
      setState(() => _currentIndex = idx);
      richiestaTabHome.value = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Punto 1/2: al ritorno in primo piano (e all'avvio) si ri-sincronizza lo
    // stato dal backend senza richiedere un nuovo login.
    if (state == AppLifecycleState.resumed) {
      _sincronizzaStato();
    }
  }

  /// Ri-sincronizza i dati utente dal backend (profilo + corsa attiva) senza
  /// relogin: chiamato all'avvio e a ogni ritorno in primo piano (punto 1/2).
  Future<void> _sincronizzaStato() async {
    await _sincronizzaProfilo();
    await _sincronizzaCorsaAttiva();
  }

  /// Sincronizza i dati anagrafici reali dell'utente autenticato (UT.21): così
  /// l'intestazione del profilo, l'avatar in barra e la sezione Account mostrano
  /// l'account corrente e non più valori segnaposto. In caso di offline o
  /// sessione assente resta sui dati locali già caricati (IIN-6).
  Future<void> _sincronizzaProfilo() async {
    try {
      final p = await profiloRepository.profilo();
      String? leggi(Object? v) => v == null ? null : '$v';
      final nome = leggi(p['nome']);
      final cognome = leggi(p['cognome']);
      final email = leggi(p['email']);
      final telefono = leggi(p['telefono']);
      final residenza = leggi(p['residenza']);
      if (nome != null) ProfileStore.firstName.value = nome;
      if (cognome != null) ProfileStore.lastName.value = cognome;
      if (email != null) ProfileStore.email.value = email;
      if (telefono != null) ProfileStore.phone.value = telefono;
      if (residenza != null) ProfileStore.address.value = residenza;
    } on LeafApiException {
      // Offline o non autenticato: si resta sui dati locali.
    }
  }

  /// Recupera la corsa in corso/pausa dal backend e ripristina lo store locale
  /// (volatile), così la corsa attiva riappare dopo un riavvio dell'app (punto 2).
  Future<void> _sincronizzaCorsaAttiva() async {
    try {
      final corsa = await corseRepository.corsaAttiva();
      if (corsa != null) {
        restoreActiveTrip(corsa);
      } else {
        clearActiveTrip();
      }
    } on LeafApiException {
      // Offline o non autenticato: si resta sullo stato locale.
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Translated: ridisegna la shell (tab bar, titoli) al cambio lingua, anche
    // se questa route resta in fondo allo stack quando si torna dalle
    // Impostazioni. IIN-7.
    return Translated((context) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          leading: Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/images/fulllogoSVG.svg',
                width: 28,
                height: 28,
                placeholderBuilder: (_) => Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Leaf Mobility',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.darkGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ValueListenableBuilder<String?>(
                  valueListenable: ProfileStore.photoPath,
                  builder: (context, path, _) {
                    final hasPhoto = path != null && File(path).existsSync();
                    return CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.primaryGreen,
                      backgroundImage: hasPhoto ? FileImage(File(path)) : null,
                      child: hasPhoto
                          ? null
                          : const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        drawer: const DrawerMenu(),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          child: [
            HomeTab(onNuovaCorsa: () => _onTabTapped(2)),
            const BookingTab(),
            const MapTab(),
            const SubscriptionManagerScreen(),
          ][_currentIndex],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: tr('Home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.electric_scooter_outlined),
              activeIcon: const Icon(Icons.electric_scooter),
              label: tr('Prenota'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.map_outlined),
              activeIcon: const Icon(Icons.map),
              label: tr('Mappa'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              activeIcon: const Icon(Icons.account_balance_wallet),
              label: tr('Abbonamenti'),
            ),
          ],
        ),
      );
    });
  }
}
