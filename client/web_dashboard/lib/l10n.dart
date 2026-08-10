import 'package:flutter/widgets.dart';

/// Lingua attiva della dashboard (osservabile, default Italiano). IIN-7.
final ValueNotifier<String> appLanguage = ValueNotifier<String>('it');

/// @brief Ricostruisce il proprio sottoalbero al cambio lingua.
///
/// Stesso pattern osservabile adottato da [AppMobileUtente]: avvolgendo una
/// vista in [Translated] i suoi testi si ridisegnano live al cambio di
/// [appLanguage] senza dipendenze ne' pattern MVC. IIN-7.
class Translated extends StatelessWidget {
  /// Builder del contenuto localizzato.
  final WidgetBuilder builder;

  const Translated(this.builder, {super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLanguage,
      builder: (context, _, _) => builder(context),
    );
  }
}

const Map<String, String> _en = {
  // Login
  'Accesso Operatori e PA': 'Operators & PA Access',
  'Console di gestione LEAF Mobility': 'LEAF Mobility management console',
  'Email': 'Email',
  'Password': 'Password',
  'Ruolo': 'Role',
  'Operatore del Servizio': 'Service Operator',
  'Amministrazione Pubblica': 'Public Administration',
  'Codice OTP': 'OTP Code',
  'Inserisci il codice a 6 cifre inviato via email':
      'Enter the 6-digit code sent via email',
  'Accedi': 'Sign in',
  'Password dimenticata?': 'Forgot password?',
  'Riceverai un link di reset via email istituzionale.':
      'You will receive a reset link via your institutional email.',
  'Inserisci un codice OTP a 6 cifre.': 'Enter a 6-digit OTP code.',
  'Inserisci email e password.': 'Enter email and password.',
  'Verifica': 'Verify',
  'Indietro': 'Back',
  'Codice OTP non valido.': 'Invalid OTP code.',
  'Accesso riservato a operatori e amministrazioni.':
      'Access restricted to operators and administrations.',
  // Cambio password obbligatorio al primo accesso (IIN-12)
  'Primo accesso: cambia la password': 'First access: change your password',
  'Per motivi di sicurezza imposta una nuova password al posto di quella temporanea.':
      'For security, set a new password to replace the temporary one.',
  'Nuova password': 'New password',
  'Conferma password': 'Confirm password',
  'Imposta password': 'Set password',
  'La password deve avere almeno 8 caratteri, una maiuscola, un numero e un carattere speciale.':
      'The password must be at least 8 characters with an uppercase letter, '
          'a number and a special character.',
  'Le due password non coincidono.': 'The two passwords do not match.',

  // Reset password (IIN-11/AP.12/UT.24)
  'Recupero password': 'Password recovery',
  'Inserisci la tua email per ricevere il codice di reset.':
      'Enter your email to receive the reset code.',
  'Inserisci il codice ricevuto e la nuova password.':
      'Enter the code received and the new password.',
  'Invia codice': 'Send code',
  'Codice inviato! Controlla la tua email.':
      'Code sent! Check your email.',
  'Codice di reset': 'Reset code',
  'Il codice non è valido o è scaduto.':
      'The code is not valid or has expired.',
  'Password reimpostata con successo!': 'Password reset successfully!',
  'Per sicurezza ti consigliamo di cambiare la password dalle impostazioni.':
      'For security, we recommend changing your password in settings.',
  'Torna al login': 'Back to login',

  // Stati di vista (caricamento / errore / vuoto / offline) — FASE 2.C, IIN-2/IIN-6
  'Riprova': 'Retry',
  'Caricamento…': 'Loading…',
  'Qualcosa è andato storto': 'Something went wrong',
  'Sei offline. Controlla la connessione.':
      'You are offline. Check your connection.',
  'Dati non aggiornati (offline)': 'Data not up to date (offline)',
  'Richiesta presa in carico.': 'Request taken in charge.',
  'Scrivi la risposta all\'utente…': 'Write the reply to the user…',
  'Risolto': 'Resolved',
  'Invia': 'Send',

  // Top bar / shell
  'MFA: Attivo': 'MFA: Active',
  'Profilo Comune': 'Municipality Profile',
  'Profilo Operatore': 'Operator Profile',
  'Gestione Profilo': 'Profile Management',
  'Notifiche': 'Notifications',
  'Logout': 'Logout',
  'Allarmi': 'Alarms',
  'Aggiornamento ogni 5s': 'Refresh every 5s',

  // AP menu
  'Home Dashboard': 'Home Dashboard',
  'Mappa & Heatmap': 'Map & Heatmap',
  'Gestione Geofencing': 'Geofencing',
  'Segnala Eventi': 'Report Events',
  'Reportistica': 'Reports',
  'Impostazioni Account': 'Account Settings',

  // OP menu
  'Centro Operativo': 'Operations Center',
  'Mappa Flotta Live': 'Live Fleet Map',
  'Gestione Ticket': 'Ticket Management',
  'Coda Assistenza': 'Support Queue',
  'Gestione Sconti': 'Discount Management',
  'Gestione Utenti/AP': 'Users/PA Management',

  // AP dashboard content
  'Flotta Operativa': 'Operational Fleet',
  'Attivi': 'Active',
  'Scarichi': 'Low battery',
  'Manutenzione': 'Maintenance',
  'Impatto Ecologico (Mese)': 'Ecological Impact (Month)',
  'CO₂ risparmiata': 'CO₂ saved',
  'percorsi dalla flotta': 'travelled by the fleet',
  'Distribuzione Aree': 'Area Distribution',
  'Quartiere Centro': 'Downtown',
  'Zona Est': 'East Zone',
  'Zona Ovest': 'West Zone',
  'Alta': 'High',
  'Media': 'Medium',
  'Bassa': 'Low',
  'Vista Cartografica Interattiva': 'Interactive Cartographic View',
  'Overlay Attivi': 'Active Overlays',
  'Heatmap Utilizzo Odierno': "Today's Usage Heatmap",
  'Cantieri Attivi': 'Active Worksites',
  'Slow-Zones Istituite': 'Established Slow-Zones',
  'Pannello Rapido: Interventi': 'Quick Panel: Interventions',
  'Inserisci Cantiere/Interruzione': 'Add Worksite/Closure',
  'Definisci Slow-Zone': 'Define Slow-Zone',
  'Notifica Grande Evento': 'Notify Major Event',
  'Estrai Report (PDF/CSV)': 'Export Report (PDF/CSV)',

  // OP dashboard content
  'Coda Allarmi e Notifiche Real-Time': 'Real-Time Alarms & Notifications Queue',
  'SOS Attivo': 'Active SOS',
  'Utente': 'User',
  'Allarme': 'Alarm',
  'Fuori Area': 'Out of Area',
  'Logistica': 'Logistics',
  'sotto soglia minima': 'below minimum threshold',
  'Vista Flotta e Telemetria': 'Fleet & Telemetry View',
  'Azioni Rapide': 'Quick Actions',
  'Sblocco/Blocco Remoto': 'Remote Lock/Unlock',
  'Crea Ticket Riparazione': 'Create Repair Ticket',
  'Sospendi Utente': 'Suspend User',
  'Configura Nuovo Sconto': 'Configure New Discount',
  'Seleziona il mezzo': 'Select the vehicle',
  'Annulla': 'Cancel',
  'Blocca': 'Lock',
  'Sblocca': 'Unlock',
  'Comando di sblocco inviato': 'Unlock command sent',
  'Comando di blocco inviato': 'Lock command sent',
  'Filtri Vista Rapidi': 'Quick View Filters',
  'Mezzi in Uso': 'Vehicles In Use',
  'Mezzi Disponibili': 'Available Vehicles',
  'Mezzi in Manutenzione': 'Vehicles in Maintenance',
  'Batteria < 15% (Critica)': 'Battery < 15% (Critical)',

  // Map legend & filters
  'Tutti': 'All',
  'Scooter': 'Scooter',
  'Bici': 'Bike',
  'Auto': 'Car',
  'E-Moto': 'E-Moto',
  'Ricarica': 'Charging',
  'Disponibile': 'Available',
  'In uso': 'In use',
  'In manutenzione': 'Under maintenance',
  'Batteria scarica': 'Low battery',
  'Stazione di ricarica': 'Charging station',
  'Trasporto Pubblico (TPL)': 'Public Transport (LPT)',
  'Legenda': 'Legend',
  'mezzi visualizzati': 'vehicles shown',
  'Batteria': 'Battery',
  'Stato': 'Status',
  'posti': 'slots',

  // Profile screen
  'Profilo Amministrazione Pubblica': 'Public Administration Profile',
  'Dati Account': 'Account Data',
  'Sicurezza': 'Security',
  'Autenticazione a due fattori attiva (OTP via email)':
      'Two-factor authentication active (OTP via email)',
  'Salva Modifiche': 'Save Changes',
  'Cambia Password': 'Change Password',
  'Registro Accessi': 'Access Log',
  'Dispositivi Collegati': 'Connected Devices',
  'Ente': 'Entity',
  'Nome e Cognome': 'Full Name',
  'Telefono': 'Phone',
  'Dipartimento': 'Department',
  'Reparto': 'Unit',

  // Notifications
  'non lette': 'unread',
  'Non lette': 'Unread',
  'Segna tutte come lette': 'Mark all as read',
  'Nessuna notifica': 'No notifications',

  // Ticket management
  'Interventi e Assistenza Flotta': 'Fleet Interventions & Support',
  'Nuovo Ticket': 'New Ticket',
  'ticket': 'tickets',
  'Da assegnare': 'To assign',
  'In corso': 'In progress',
  'Terminati': 'Completed',
  'Terminato': 'Completed',
  'Tutti i tipi': 'All types',
  'Guasto': 'Fault',
  'Assistenza Utente': 'User Support',
  'Tutti gli stati': 'All statuses',
  'Tutte le date': 'All dates',
  'Oggi': 'Today',
  'Ultimi 7 giorni': 'Last 7 days',
  'Ultimi 30 giorni': 'Last 30 days',
  'Azzera filtri': 'Clear filters',
  'Nessun ticket per i filtri selezionati':
      'No tickets for the selected filters',
  'Non assegnato': 'Unassigned',
  'Assegna': 'Assign',
  'Riassegna': 'Reassign',
  'Chiudi': 'Close',
  'Assegna a un tecnico': 'Assign to a technician',
  'Tipo di ticket': 'Ticket type',
  'Codice mezzo (es. CA-015)': 'Vehicle ID (e.g. CA-015)',
  "Oggetto dell'intervento": 'Intervention subject',
  'Priorità': 'Priority',
  'Tecnico (opzionale)': 'Technician (optional)',
  'Crea ticket': 'Create ticket',
  'Ticket creato': 'Ticket created',

  // Geofencing
  'Aree operative, interdizioni e slow-zone':
      'Operational areas, no-go zones and slow-zones',
  'Area Operativa': 'Operational Area',
  'Interdizione Totale': 'Total No-Go Zone',
  'Slow-zone': 'Slow-zone',
  'Cantiere / Lavori': 'Worksite / Roadworks',
  'Vertice': 'Vertex',
  'vertici': 'vertices',
  "Tocca la mappa per iniziare a disegnare un'area":
      'Tap the map to start drawing an area',
  'vertici — completa o annulla': 'vertices — complete or cancel',
  'Nuova Area': 'New Area',
  'Tipo di area': 'Area type',
  'Limite': 'Limit',
  'Annulla punto': 'Undo point',
  'Reset': 'Reset',
  'Completa area': 'Complete area',
  'Aree Configurate': 'Configured Areas',
  'Elimina': 'Delete',
  'Area salvata': 'Area saved',
  'propagazione ai mezzi entro 30s': 'propagation to vehicles within 30s',

  // Settings
  'Impostazioni': 'Settings',
  'Preferenze della console': 'Console preferences',
  'Lingua dell\'interfaccia': 'Interface language',
  'Aspetto e Accessibilità': 'Appearance & Accessibility',
  'Testo ingrandito': 'Larger text',
  'Aumenta la dimensione dei caratteri': 'Increase font size',
  'Allarmi critici (SOS, fuori area)': 'Critical alarms (SOS, out of area)',
  'Notifiche push immediate': 'Immediate push notifications',
  'Avvisi logistici e soglie': 'Logistics & threshold alerts',
  'Batteria, ricollocamento, soglie minime':
      'Battery, relocation, minimum thresholds',
  'Riepilogo giornaliero via email': 'Daily email summary',
  'Digest delle attività alle 20:00': 'Activity digest at 20:00',
  'Suoni di notifica': 'Notification sounds',
  'Segnale acustico per gli allarmi': 'Audible alert for alarms',
  'Dati e Privacy': 'Data & Privacy',
  'Frequenza aggiornamento dashboard': 'Dashboard refresh rate',
  'Consenso geolocalizzazione': 'Geolocation consent',
  'Necessario per la mappa flotta (GDPR)': 'Required for the fleet map (GDPR)',
  'Esporta i miei dati': 'Export my data',

  // Support queue (Coda Assistenza)
  'Richieste di supporto in entrata': 'Incoming support requests',
  'Nessuna richiesta in coda': 'No requests in queue',
  'Nuove': 'New',
  'In carico': 'In progress',
  'Risolte': 'Resolved',
  'Tutte': 'All',
  'Non assegnata': 'Unassigned',
  'Prendi in carico': 'Take in charge',
  'Rispondi': 'Reply',
  'Risolvi': 'Resolve',
  'Nuova': 'New',
  'Risolta': 'Resolved',

  // Discount management (Gestione Sconti)
  'Incentivi al parcheggio e sconti geografici':
      'Parking incentives & geographic discounts',
  'Nuova Regola': 'New Rule',
  'Regole attive': 'Active rules',
  'Bonus parcheggio': 'Parking bonus',
  'Sconti geografici': 'Geographic discounts',
  'Sconto geografico': 'Geographic discount',
  'Attiva': 'Active',
  'Sospesa': 'Suspended',
  'Tipo di incentivo': 'Incentive type',
  'Nome della regola': 'Rule name',
  'Area geografica': 'Geographic area',
  'Valore (es. +0,50 € credito)': 'Value (e.g. +0,50 € credit)',
  'Valore (es. -20% avvio corsa)': 'Value (e.g. -20% ride start)',
  'Periodo (es. Lun–Ven 07:00–10:00)': 'Period (e.g. Mon–Fri 07:00–10:00)',
  'Attiva alla creazione': 'Active on creation',
  'Crea regola': 'Create rule',
  'Regola creata': 'Rule created',
  'Campo obbligatorio': 'Required field',

  // Event reporting (Segnala Eventi)
  'Grandi eventi, cantieri e interruzioni di servizio':
      'Major events, worksites and service disruptions',
  'Grande Evento': 'Major Event',
  'Interruzione di Servizio': 'Service Disruption',
  'Nuovo evento': 'New event',
  "Tocca la mappa per posizionare l'evento":
      'Tap the map to place the event',
  'Posizione impostata — compila e salva': 'Location set — fill in and save',
  'Nuovo Evento': 'New Event',
  'Tipo di evento': 'Event type',
  'Nome evento': 'Event name',
  'Area / quartiere': 'Area / district',
  'Note (opzionale)': 'Notes (optional)',
  'Data': 'Date',
  'Notifica': 'Notify',
  'Eventi Programmati': 'Scheduled Events',
  'Nessun evento programmato': 'No scheduled events',
  "Inserisci almeno nome e area dell'evento":
      'Enter at least the event name and area',
  'Evento registrato': 'Event saved',
  'operatori notificati': 'operators notified',

  // Reports (Reportistica)
  'Report periodici aggregati sulla mobilità urbana':
      'Periodic aggregated reports on urban mobility',
  'Esporta PDF': 'Export PDF',
  'Esporta CSV': 'Export CSV',
  'Esportazione': 'Export',
  'in preparazione': 'in preparation',
  'Settimana': 'Week',
  'Mese': 'Month',
  'Trimestre': 'Quarter',
  'Noleggi totali': 'Total rentals',
  'Flotta operativa': 'Operational fleet',
  'Noleggi per tipologia di mezzo': 'Rentals by vehicle type',
  'Flussi di mobilità per fascia oraria': 'Mobility flows by time slot',
  'Flotta operativa vs manutenzione': 'Operational fleet vs maintenance',
  'CO₂ risparmiata dalla flotta elettrica': 'CO₂ saved by the electric fleet',
  'Gen': 'Jan',
  'Feb': 'Feb',
  'Mar': 'Mar',
  'Apr': 'Apr',
  'Mag': 'May',
  'Giu': 'Jun',

  // User / PA management (Gestione Utenti/AP)
  'Account utenti e provisioning Amministrazione':
      'User accounts & Administration provisioning',
  'Crea Account AP': 'Create PA Account',
  'Utenti': 'Users',
  'Account AP': 'PA Accounts',
  'Cerca per ID, nome o email': 'Search by ID, name or email',
  'Nessun utente trovato': 'No users found',
  'Sospeso': 'Suspended',
  'Attivo': 'Active',
  'Riattiva': 'Reactivate',
  'Sospendi': 'Suspend',
  'Primo accesso in attesa': 'First access pending',
  'Reinvia credenziali': 'Resend credentials',

  // Live fleet map filters
  'Tipo di veicolo': 'Vehicle type',
  'Layer mappa': 'Map layers',

  // Generic
  'In sviluppo': 'Under development',
  'Funzione disponibile con il backend': 'Feature available with the backend',
  'Lingua': 'Language',
  'Sezione in sviluppo. Sarà collegata al server.':
      'Section under development. Will be wired to the server.',
};

/// @brief Traduce [key] nella lingua attiva.
/// @param key Testo sorgente in italiano (chiave del dizionario).
/// @return Traduzione inglese se [appLanguage] == 'en', altrimenti l'italiano.
String tr(String key) {
  if (appLanguage.value == 'en') {
    return _en[key] ?? key;
  }
  return key;
}
