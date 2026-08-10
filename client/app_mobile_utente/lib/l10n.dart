import 'package:flutter/widgets.dart';

final ValueNotifier<String> appLanguage = ValueNotifier<String>('it');

/// @brief Ricostruisce il proprio sottoalbero al cambio di lingua dell'app.
///
/// Le schermate raggiunte via `Navigator.push` vengono costruite una sola
/// volta e memorizzate dalla route: un cambio di [appLanguage] non le
/// ricostruisce e i testi resterebbero nella lingua precedente. Avvolgendo il
/// contenuto della schermata in [Translated], la vista si ridisegna live al
/// cambio lingua senza introdurre dipendenze ne' pattern MVC (stesso pattern
/// osservabile di [appLanguage]). IIN-7 (internazionalizzazione).
class Translated extends StatelessWidget {
  /// Builder del contenuto localizzato della schermata.
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
  // Drawer & Navigation
  'Menù Principale': 'Main Menu',
  'Mie Prenotazioni': 'My Bookings',
  'Cronologia': 'History',
  'Abbonamenti': 'Subscriptions',
  'Acquista abbonamento': 'Buy subscription',
  'Gestione abbonamento': 'Manage subscription',
  'Impostazioni': 'Settings',
  'Supporto': 'Support',
  'SOS Emergenza': 'SOS Emergency',

  // Tabs
  'Home': 'Home',
  'Prenota': 'Book',
  'Mappa': 'Map',

  // Settings
  'Lingua': 'Language',
  'Italiano': 'Italian',
  'English': 'English',

  // Profile
  'Profilo': 'Profile',
  'Account': 'Account',
  'Dati sensibili': 'Sensitive Data',
  'Assistenza': 'Help',
  'Log out': 'Log out',

  // Subscription Manager
  'Il tuo abbonamento': 'Your subscription',
  'Abbonamento attivo': 'Active subscription',
  'Abbonamento scaduto': 'Expired subscription',
  'Nessun abbonamento attivo.': 'No active subscription.',
  'Stato abbonamento non disponibile offline.':
      'Subscription status unavailable offline.',
  'Scade il': 'Expires on',
  'giorni': 'days',
  'Nessun acquisto registrato.': 'No purchases recorded.',
  'Rimanente': 'Remaining',
  'Opzioni': 'Options',
  'Acquista nuovo abbonamento': 'Buy new subscription',
  'Storico acquisti': 'Purchase history',

  // Buy Subscription
  'Acquista Abbonamento': 'Buy Subscription',
  'Scegli il piano adatto a te': 'Choose the plan right for you',
  'Sblocchi illimitati': 'Unlimited unlocks',
  '120 min inclusi': '120 mins included',
  'Tutti i veicoli': 'All vehicles',
  '500 min inclusi': '500 mins included',
  'Minuti illimitati': 'Unlimited mins',
  'Supporto prioritario': 'Priority support',
  'Seleziona Piano': 'Select Plan',
  'Abbonamento attivato:': 'Subscription activated:',
  '24 ore': '24 hours',
  '7 giorni': '7 days',
  '30 giorni': '30 days',

  // Login
  'Benvenuto in Leaf Mobility': 'Welcome to Leaf Mobility',
  'Accedi o registrati per iniziare': 'Login or register to get started',
  'Accedi': 'Login',
  'Email': 'Email',
  'Password': 'Password',
  'Password dimenticata?': 'Forgot password?',
  'Riceverai un link di reset via email.':
      'You will receive a reset link via email.',
  'Nuovo utente? Registrati': 'New user? Sign up',
  'Inserisci email e password.': 'Enter email and password.',
  'Inserisci l\'email per il reset.': 'Enter the email for the reset.',
  'Credenziali non valide. Controlla email e password.':
      'Invalid credentials. Check email and password.',
  'Account bloccato per troppi tentativi. Riprova tra qualche minuto.':
      'Account locked due to too many attempts. Try again in a few minutes.',
  'Account sospeso. Contatta l\'assistenza.':
      'Account suspended. Contact support.',
  'Limite dispositivi raggiunto. Disconnetti un altro dispositivo per continuare.':
      'Device limit reached. Disconnect another device to continue.',
  'Account già esistente con questa email o username.':
      'An account with this email or username already exists.',
  'Servizio temporaneamente non disponibile. Riprova.':
      'Service temporarily unavailable. Try again.',
  'Devi cambiare la password temporanea. Contatta l\'operatore.':
      'You must change the temporary password. Contact the operator.',

  // Home
  'Da dove parti?': 'Where are you starting from?',
  'Dove vuoi andare?': 'Where do you want to go?',
  'Cronologia Percorsi': 'Trip History',
  'Vedi tutte': 'See all',
  'Mezzi Disponibili Vicino a Te': 'Vehicles Available Near You',
  'Nessun mezzo disponibile per questo filtro.':
      'No vehicles available for this filter.',
  'Tutti': 'All',
  'Auto': 'Car',
  'Bici': 'Bike',
  'Corsa': 'Trip',

  // History
  'Cronologia Corse': 'Trip History',
  'corse': 'trips',
  'Data': 'Date',
  'Durata': 'Duration',
  'Distanza': 'Distance',
  'Costo': 'Cost',
  'Ordine crescente': 'Ascending order',
  'Ordine decrescente': 'Descending order',
  'Ordina per': 'Sort by',
  'Nessuna corsa registrata': 'No trips recorded',
  'Le corse che completi appariranno qui.':
      'The trips you complete will appear here.',

  // SOS
  'Premi il pulsante SOS\nin caso di emergenza':
      'Press the SOS button\nin case of emergency',
  'La tua posizione GPS verrà inviata\nai soccorsi entro 5 secondi.':
      'Your GPS position will be sent\nto rescuers within 5 seconds.',
  'Invio SOS in…': 'Sending SOS in…',
  'Annulla': 'Cancel',
  'SOS Inviato': 'SOS Sent',
  'La tua posizione GPS è stata comunicata ai soccorsi.\nRimani calmo e attendi i soccorsi.':
      'Your GPS position has been sent to rescuers.\nStay calm and wait for help.',
  'Annulla SOS': 'Cancel SOS',
  'In attesa della posizione…': 'Waiting for position…',
  'Posizione GPS disponibile': 'GPS position available',
  'Permesso di localizzazione non concesso': 'Location permission not granted',

  // Unavailable Service
  'Servizio non disponibile': 'Service unavailable',
  'Torna alla home': 'Back to home',

  // Map / General
  'Ricarica': 'Charging',
  'Servizio Non Disponibile': 'Service Unavailable',
  'Scooter': 'Scooter',
  'E-Moto': 'E-Moto',
  'Disponibile': 'Available',
  'In uso': 'In use',
  'In manutenzione': 'Under maintenance',
  'Posizione non disponibile': 'Location unavailable',
  'Dati non aggiornati (offline)': 'Data not up to date (offline)',
  'Verifica i permessi di localizzazione nelle impostazioni del dispositivo.':
      'Check location permissions in your device settings.',
  'Riprova': 'Retry',

  // Stati di vista (caricamento / errore / vuoto / offline) — FASE 2.B, IIN-2/IIN-6
  'Caricamento…': 'Loading…',
  'Qualcosa è andato storto': 'Something went wrong',
  'Sei offline. Controlla la connessione.':
      'You are offline. Check your connection.',
  'Nessun dato disponibile': 'No data available',

  // Account / Registration / Profile
  'Dati Utente': 'User Data',
  'Nome': 'First name',
  'Cognome': 'Last name',
  'Residenza completa': 'Full address',
  'Numero telefonico': 'Phone number',
  'Salva Modifiche': 'Save Changes',
  'Registrazione': 'Registration',
  'Completa il tuo profilo': 'Complete your profile',
  'Inserisci i tuoi dati per iniziare ad usare Leaf Mobility':
      'Enter your details to start using Leaf Mobility',
  'Registrati': 'Sign up',
  'Data di nascita': 'Date of birth',
  'Compila email, username, password e data di nascita.':
      'Fill in email, username, password and date of birth.',
  'Compila tutti i campi, inclusa la data di nascita.':
      'Fill in all fields, including the date of birth.',
  'Residenza (via di fatturazione)': 'Residence (billing address)',
  'CVV': 'CVV',
  'Indirizzo di fatturazione': 'Billing address',
  'Deve coincidere con la residenza del profilo.':
      'Must match the profile residence.',
  'Inserisci l\'intestatario della carta.': 'Enter the cardholder name.',
  'Numero carta non valido.': 'Invalid card number.',
  'Scadenza non valida (usa MM/AA).': 'Invalid expiry (use MM/YY).',
  'La carta è scaduta.': 'The card has expired.',
  'Il codice di sicurezza deve avere 3 cifre.':
      'The security code must be 3 digits.',
  'Inserisci l\'indirizzo di fatturazione.': 'Enter the billing address.',
  'Carica la patente per noleggiare auto o moto elettriche.':
      'Upload your driving licence to rent electric cars or motorbikes.',
  'Per questo mezzo serve la patente: caricala nei dati sensibili.':
      'This vehicle requires a driving licence: upload it in sensitive data.',
  'Concludi noleggio': 'End rental',
  'Noleggio concluso': 'Rental ended',
  'coperto da abbonamento': 'covered by subscription',
  'Sblocco': 'Unlock',
  'Gratuito': 'Free',
  'Coperta da abbonamento': 'Covered by subscription',
  'Abbonamento utilizzato': 'Subscription used',
  'Token residui': 'Remaining tokens',
  'token': 'tokens',

  // Notifications
  'Notifiche': 'Notifications',
  'Nessuna notifica': 'No notifications',
  'Le tue notifiche appariranno qui.': 'Your notifications will appear here.',

  // Vehicle detail
  'Scooter Elettrico': 'Electric Scooter',
  'E-Bike': 'E-Bike',
  'Auto Elettrica': 'Electric Car',
  'Batteria': 'Battery',
  'Caratteristiche': 'Features',
  'Autonomia': 'Range',
  'Distanza da te': 'Distance from you',
  'Attesa stimata': 'Estimated wait',
  'Tariffa': 'Rate',
  'Prenota mezzo': 'Book vehicle',
  'Sblocca con QR': 'Unlock with QR',
  'Vedi su mappa': 'View on map',
  'Sblocco mezzo… (funzione in sviluppo)':
      'Unlocking vehicle… (feature in development)',
  'Mezzo sbloccato — corsa avviata': 'Vehicle unlocked — trip started',
  'min': 'min',
  'batteria': 'battery',
  'autonomia': 'range',

  // Booking
  'Durata prenotazione': 'Booking duration',
  'Costo stimato': 'Estimated cost',
  '€/min': '€/min',
  'La prenotazione mantiene il mezzo riservato fino allo scadere del tempo.':
      'The booking keeps the vehicle reserved until the time expires.',
  'Conferma prenotazione': 'Confirm booking',
  'Prenotazione confermata': 'Booking confirmed',

  // My bookings
  'Nessuna prenotazione attiva': 'No active bookings',
  'Le prenotazioni che effettui appariranno qui.':
      'The bookings you make will appear here.',
  'Riservato alle': 'Reserved at',
  'Scade alle': 'Expires at',
  'Annulla prenotazione': 'Cancel booking',
  'Attiva': 'Active',
  'Annullata': 'Cancelled',

  // Search
  'Cerca percorso': 'Search route',
  'Cancella': 'Clear',
  'Inverti': 'Swap',
  'Usa posizione corrente': 'Use current location',
  'Nessun risultato.': 'No results.',
  'Ricerche recenti': 'Recent searches',
  'Suggerimenti': 'Suggestions',
  'Percorsi disponibili': 'Available routes',
  'opzioni': 'options',

  // Route detail
  'Modalità di trasporto': 'Transport mode',
  'Mezzi consigliati vicino alla partenza':
      'Recommended vehicles near departure',
  'Integrazione TPL disponibile': 'Public transport integration available',
  'Stima costo': 'Cost estimate',
  'Scheda mezzo': 'Vehicle details',

  // Search mock routes (data)
  'Percorso diretto': 'Direct route',
  'Il percorso più veloce': 'The fastest route',
  'Scooter elettrico — percorso diretto': 'Electric scooter — direct route',
  'Via Lungomare': 'Seafront route',
  'Percorso panoramico, leggermente più lungo': 'Scenic route, slightly longer',
  'E-Bike — percorso panoramico lungo il mare':
      'E-Bike — scenic route along the sea',
  'Con TPL integrato': 'With public transport',
  'Mezzo + autobus: economico e veloce': 'Vehicle + bus: cheap and fast',
  'E-Bike fino alla fermata + Bus TPL fino alla destinazione':
      'E-Bike to the stop + public bus to the destination',
  'Percorso comfort': 'Comfort route',
  'In auto elettrica — massimo comfort': 'By electric car — maximum comfort',
  'Auto elettrica — percorso diretto': 'Electric car — direct route',

  // Trip detail (UT.17 / UT.25)
  'Percorso': 'Route',
  'Dettagli corsa': 'Trip details',
  'Velocità media': 'Average speed',
  'CO₂ risparmiata': 'CO₂ saved',
  'Importo addebitato': 'Amount charged',
  'Totale corsa': 'Trip total',
  'Esporta fattura': 'Export invoice',

  // Invoice (UT.25)
  'Fattura': 'Invoice',
  'Numero': 'Number',
  'Cliente': 'Customer',
  'Dettaglio corsa': 'Trip detail',
  'Veicolo': 'Vehicle',
  'Tragitto': 'Route',
  'Imponibile': 'Taxable amount',
  'IVA': 'VAT',
  'Totale': 'Total',
  'posti': 'spots',
  'Copia digitale — documento generato dall\'app.':
      'Digital copy — document generated by the app.',
  'Stampa o salva PDF': 'Print or save PDF',

  // Support / Assistance (UT.09)
  'Come possiamo aiutarti?': 'How can we help you?',
  'Contattaci o inviaci un feedback: il nostro team ti risponderà al più presto.':
      'Contact us or send feedback: our team will get back to you shortly.',
  'Contatti diretti': 'Direct contacts',
  'Chiama il supporto': 'Call support',
  'Scrivici una email': 'Email us',
  'Domande frequenti': 'Frequently asked questions',
  'Come sblocco un mezzo?': 'How do I unlock a vehicle?',
  'Inquadra il QR code del mezzo o usa il pulsante "Sblocca" nella scheda del veicolo.':
      'Scan the vehicle QR code or use the "Unlock" button on the vehicle card.',
  'Come annullo una prenotazione?': 'How do I cancel a booking?',
  'Vai in "Mie Prenotazioni" dal menu e premi "Annulla prenotazione".':
      'Go to "My Bookings" from the menu and tap "Cancel booking".',
  'Come funziona la fatturazione?': 'How does billing work?',
  'Il costo è calcolato al minuto in base alla tariffa del mezzo; ricevi un riepilogo a fine corsa.':
      'The cost is calculated per minute based on the vehicle rate; you get a summary at the end of the trip.',
  'Invia feedback o segnalazione': 'Send feedback or report',
  'Tipo di richiesta': 'Request type',
  'Segnalazione': 'Report',
  'Suggerimento': 'Suggestion',
  'Come valuti la tua esperienza?': 'How would you rate your experience?',
  'Il tuo messaggio': 'Your message',
  'Descrivi il tuo feedback o il problema riscontrato…':
      'Describe your feedback or the issue you encountered…',
  'Invia': 'Send',
  'Inserisci un messaggio prima di inviare.':
      'Please enter a message before sending.',
  'Grazie! La tua segnalazione è stata inviata.':
      'Thank you! Your report has been sent.',
  'Tempo di risposta stimato: entro 24 ore.':
      'Estimated response time: within 24 hours.',

  // Booking tab (UT.02)
  'Prenota un mezzo': 'Book a vehicle',
  'Seleziona un veicolo disponibile per riservarlo.':
      'Select an available vehicle to reserve it.',

  // FAQ section (UT.09)
  'Cerca tra le domande più comuni': 'Search the most common questions',
  'Cerca una risposta…': 'Search for an answer…',
  'Domande più comuni': 'Most common questions',
  'risultati': 'results',
  'Nessuna risposta trovata': 'No answer found',
  'Prova con altre parole o contatta il supporto.':
      'Try different words or contact support.',
  'Come prenoto un mezzo?': 'How do I book a vehicle?',
  'Apri la sezione "Prenota", scegli un veicolo disponibile e conferma la durata della riserva.':
      'Open the "Book" section, choose an available vehicle and confirm the reservation duration.',
  'Come metto in pausa una corsa?': 'How do I pause a trip?',
  'Durante la corsa attiva la "pausa corsa": il mezzo resta bloccato e riservato a te senza terminare il noleggio.':
      'During the trip enable "pause trip": the vehicle stays locked and reserved for you without ending the rental.',
  'Come ottengo la fattura della corsa?': 'How do I get the trip invoice?',
  'Apri la corsa dalla cronologia e premi "Esporta fattura" per ottenere una copia digitale stampabile.':
      'Open the trip from history and tap "Export invoice" to get a printable digital copy.',
  'Come cambio la lingua dell\'app?': 'How do I change the app language?',
  'Vai in "Impostazioni" dal menu laterale e scegli la lingua preferita nella sezione "Lingua".':
      'Go to "Settings" from the side menu and choose your preferred language under "Language".',
  'Come funziona il tasto SOS?': 'How does the SOS button work?',
  'In caso di emergenza premi il tasto SOS: la tua posizione GPS viene inviata ai soccorsi entro 5 secondi.':
      'In an emergency press the SOS button: your GPS position is sent to rescuers within 5 seconds.',
  'Quali metodi di pagamento posso usare?': 'Which payment methods can I use?',
  'Puoi registrare un metodo di pagamento verificato dal tuo profilo per l\'addebito automatico a fine noleggio.':
      'You can register a verified payment method from your profile for automatic charging at the end of the rental.',
  'Come recupero la password?': 'How do I recover my password?',
  'Nella schermata di accesso premi "Password dimenticata?": riceverai un link di reset via email.':
      'On the login screen tap "Forgot password?": you will receive a reset link via email.',

  // Settings (rental-app preferences)
  'Notifiche push': 'Push notifications',
  'Ricevi avvisi importanti sul tuo noleggio.':
      'Receive important alerts about your rental.',
  'Promemoria prenotazione': 'Booking reminder',
  'Avviso prima della scadenza della riserva.':
      'Alert before the reservation expires.',
  'Promozioni e offerte': 'Promotions and offers',
  'Sconti e novità sul servizio.': 'Discounts and service news.',
  'Privacy e posizione': 'Privacy and location',
  'Servizi di localizzazione': 'Location services',
  'Necessari per trovare e sbloccare i mezzi vicini.':
      'Required to find and unlock nearby vehicles.',
  'Condivisione dati di utilizzo': 'Usage data sharing',
  'Dati anonimi e aggregati per migliorare il servizio.':
      'Anonymous, aggregated data to improve the service.',
  'Sicurezza': 'Security',
  'Conferma sblocco con biometria': 'Biometric unlock confirmation',
  'Richiedi impronta o volto prima di sbloccare.':
      'Require fingerprint or face before unlocking.',
  'Informazioni': 'About',
  'Termini di servizio': 'Terms of service',
  'Informativa sulla privacy': 'Privacy policy',
  'Versione': 'Version',
  'Sezione in fase di sviluppo.': 'Section under development.',

  // Account (edit + profile photo, UT.21)
  'Modifiche salvate': 'Changes saved',
  'Modifica campo': 'Edit field',
  'Blocca campo': 'Lock field',
  'Scegli dalla galleria': 'Choose from gallery',
  'Scatta una foto': 'Take a photo',
  'Immagine dalla galleria': 'Image from gallery',
  'PDF dal file manager': 'PDF from file manager',
  'Rimuovi foto': 'Remove photo',
  'Permesso negato. Abilitalo nelle impostazioni.':
      'Permission denied. Enable it in settings.',

  // Sensitive data (documents + payment, UT.11 / UT.22.2)
  'Documenti importanti': 'Important documents',
  'Formati accettati: PDF, JPG, PNG.': 'Accepted formats: PDF, JPG, PNG.',
  "Carta d'identità": 'ID card',
  'Patente': 'Driving licence',
  'Metodo di pagamento': 'Payment method',
  'Scadenza': 'Expiry',
  'Nessun metodo di pagamento registrato.': 'No payment method registered.',
  'Intestatario': 'Cardholder',
  'Numero carta': 'Card number',
  'Scadenza (MM/AA)': 'Expiry (MM/YY)',
  'Caricato': 'Uploaded',
  'Non caricato': 'Not uploaded',
  'Rimuovi': 'Remove',
  'Sostituisci': 'Replace',
  'Carica': 'Upload',

  // Trip report (UT.09)
  'Segnala corsa': 'Report trip',
  'Descrivi il problema riscontrato durante la corsa.':
      'Describe the problem you encountered during the trip.',
};

String tr(String key) {
  if (appLanguage.value == 'en') {
    return _en[key] ?? key;
  }
  return key;
}
