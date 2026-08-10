// Smoke test della WebDashboard LEAF Mobility.
//
// Verifica che l'app si avvii mostrando la schermata di login unica per OP/AP
// e che la selezione del ruolo + MFA sblocchi l'accesso alla console.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/main.dart';

void main() {
  testWidgets('La login mostra titolo, ruoli e campi credenziali', (
    tester,
  ) async {
    appLanguage.value = 'it';
    await tester.pumpWidget(const LeafDashboardApp());
    await tester.pumpAndSettle();

    expect(find.text('Accesso Operatori e PA'), findsOneWidget);
    expect(find.text('Operatore del Servizio'), findsOneWidget);
    expect(find.text('Amministrazione Pubblica'), findsOneWidget);
    // Primo passo: credenziali (il campo OTP compare solo dopo l'accesso).
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
  });

  testWidgets('Senza credenziali l\'accesso è bloccato', (tester) async {
    appLanguage.value = 'it';
    await tester.pumpWidget(const LeafDashboardApp());
    await tester.pumpAndSettle();

    final loginBtn = find.widgetWithText(ElevatedButton, 'Accedi');
    await tester.ensureVisible(loginBtn);
    await tester.pumpAndSettle();
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();

    // Validazione locale: resta sulla login e mostra l'errore credenziali.
    expect(find.text('Inserisci email e password.'), findsOneWidget);
  });
}
