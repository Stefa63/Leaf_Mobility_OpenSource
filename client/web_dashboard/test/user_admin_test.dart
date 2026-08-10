// Widget test della Gestione Utenti/AP (account utenti e provisioning AP).
//
// Verifica l'header e l'elenco degli account utente alimentati dallo store
// (dati reali dal server, nessun mock fabbricato) e la presenza dello username.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:web_dashboard/data/users_admin_data.dart';
import 'package:web_dashboard/data/users_admin_store.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/screens/user_admin.dart';

/// @brief Monta la [UserAdmin] in un telaio di test desktop.
/// @param tester il driver del widget test.
Future<void> pumpUserAdmin(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1400, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(0.8),
        ),
        child: child!,
      ),
      home: const Scaffold(body: UserAdmin(autoload: false)),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    appLanguage.value = 'it';
    // Dati reali simulati nello store (lo store parte vuoto: niente mock).
    UsersAdminStore.users.value = [
      ManagedUser(
        id: 'U-1',
        name: 'Giulia Conti',
        username: 'giulia.conti',
        email: 'giulia.conti@email.it',
        status: UserStatus.attivo,
      ),
      ManagedUser(
        id: 'U-2',
        name: 'Marco Ferrari',
        username: 'm.ferrari',
        email: 'm.ferrari@email.it',
        status: UserStatus.attivo,
      ),
    ];
  });

  tearDown(() {
    UsersAdminStore.users.value = const [];
    UsersAdminStore.apAccounts.value = const [];
  });

  testWidgets('Gestione Utenti/AP mostra header ed elenco account dal server', (
    tester,
  ) async {
    await pumpUserAdmin(tester);

    expect(find.text('Gestione Utenti/AP'), findsOneWidget);
    expect(find.text('Giulia Conti'), findsOneWidget);
    expect(find.text('Marco Ferrari'), findsOneWidget);
  });

  testWidgets('La card utente mostra lo username (Blocco A)', (tester) async {
    await pumpUserAdmin(tester);

    expect(find.text('@giulia.conti'), findsOneWidget);
    expect(find.text('@m.ferrari'), findsOneWidget);
  });
}
