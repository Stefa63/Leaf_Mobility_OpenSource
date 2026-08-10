# Documentazione Doxygen — App Mobile Utente

**Progetto:** LEAF Mobility — App Mobile Utente  
**Percorso sorgente:** `client/app_mobile_utente/lib/`  
**Generata il:** 04/08/2026
**Versione:** 1.0.0-alpha.31+31

---

## Indice

1. [Entry Point — main.dart](#1-entry-point--maindart)
2. [Theme — theme.dart](#2-theme--themedart)
3. [Internazionalizzazione — l10n.dart](#3-internazionalizzazione--l10ndart)
4. [Store — booking_store.dart](#4-store--booking_storedart)
5. [Store — profile_store.dart](#5-store--profile_storedart)
6. [Store — settings_store.dart](#6-store--settings_storedart)
7. [Screens](#7-screens)
    - 7.1 [SplashScreen](#71-splashscreen)
    - 7.2 [LoginScreen](#72-loginscreen)
    - 7.3 [RegistrationScreen](#73-registrationscreen)
    - 7.4 [MainLayout](#74-mainlayout)
    - 7.5 [HomeTab](#75-hometab)
    - 7.6 [MapTab](#76-maptab)
    - 7.7 [BookingTab](#77-bookingtab)
    - 7.8 [BookingScreen](#78-bookingscreen)
    - 7.9 [MyBookingsScreen](#79-mybookingsscreen)
    - 7.10 [VehicleDetailScreen](#710-vehicledetailscreen)
    - 7.11 [SearchScreen](#711-searchscreen)
    - 7.12 [RouteDetailScreen](#712-routedetailscreen)
    - 7.13 [HistoryScreen](#713-historyscreen)
    - 7.14 [TripDetailScreen](#714-tripdetailscreen)
    - 7.15 [ProfileScreen](#715-profilescreen)
    - 7.16 [AccountScreen](#716-accountscreen)
    - 7.17 [SensitiveDataScreen](#717-sensitivedatascreen)
    - 7.18 [SettingsScreen](#718-settingsscreen)
    - 7.19 [SupportScreen](#719-supportscreen)
    - 7.20 [FaqScreen](#720-faqscreen)
    - 7.21 [SOSScreen](#721-sosscreen)
    - 7.22 [NotificationsScreen](#722-notificationsscreen)
    - 7.23 [SubscriptionManagerScreen](#723-subscriptionmanagerscreen)
    - 7.24 [BuySubscriptionScreen](#724-buysubscriptionscreen)
    - 7.25 [UnavailableServiceTab](#725-unavailableservicetab)
8. [Widgets](#8-widgets)
    - 8.1 [DrawerMenu](#81-drawermenu)

---

## 1. Entry Point — `main.dart`

**File:** `lib/main.dart`

### `main()`
```
Future<void> main() async
```
Inizializza i plugin Flutter (`WidgetsFlutterBinding.ensureInitialized()`), ripristina i dati di profilo persistiti localmente sul dispositivo (UT.21) tramite `ProfileStore.load()` e avvia l'app con `runApp(LeafMobilityApp())`.

### `LeafMobilityApp`
```
class LeafMobilityApp extends StatelessWidget
```
Widget radice dell'applicazione. Configura il `MaterialApp` con il tema `AppTheme.lightTheme`, le route (`/` → SplashScreen, `/login` → LoginScreen, `/home` → MainLayout) e l'ascolto di `appLanguage` per il cambio lingua live.

---

## 2. Theme — `theme.dart`

**File:** `lib/theme.dart`

### `AppTheme`
```
class AppTheme
```
Definisce la palette cromatica e il tema Material dell'app.

| Costante | Valore | Descrizione |
|---|---|---|
| `backgroundBeige` | `#FCFBF7` | Sfondo chiaro principale |
| `primaryGreen` | `#4CAF50` | Verde primario del brand |
| `darkGreen` | `#2E7D32` | Verde scuro per titoli |
| `accentBrown` | `#795548` | Accento marrone |
| `textDark` | `#333333` | Testo principale scuro |
| `textGrey` | `#6E6E6E` | Testo secondario grigio (WCAG AA ≥4.5:1) |
| `surfaceColor` | `#F1F8F1` | Superficie verde chiaro desaturato |

#### `lightTheme` → `ThemeData`
Tema chiaro con tipografia Google Fonts Inter, `AppBar` senza elevazione, `BottomNavigationBar` con verde primario, pulsanti elevati arrotondati e card con ombra leggera.

---

## 3. Internazionalizzazione — `l10n.dart`

**File:** `lib/l10n.dart`

### `appLanguage`
```
final ValueNotifier<String> appLanguage = ValueNotifier<String>('it')
```
Notifier osservabile della lingua corrente (`'it'` o `'en'`).

### `Translated`
```
/// @brief Ricostruisce il proprio sottoalbero al cambio di lingua dell'app.
class Translated extends StatelessWidget
```
Le schermate raggiunte via `Navigator.push` vengono costruite una sola volta e memorizzate dalla route: un cambio di `appLanguage` non le ricostruisce e i testi resterebbero nella lingua precedente. Avvolgendo il contenuto della schermata in `Translated`, la vista si ridisegna live al cambio lingua senza introdurre dipendenze né pattern MVC (stesso pattern osservabile di `appLanguage`). IIN-7 (internazionalizzazione).

**Parametri:**
- `builder` — Builder del contenuto localizzato della schermata.

### `tr(String key)` → `String`
Traduce la chiave italiana nel testo inglese quando `appLanguage.value == 'en'`; altrimenti restituisce la chiave inalterata.

---

## 4. Store — `booking_store.dart`

**File:** `lib/booking_store.dart`

### `BookingStatus`
```
/// @brief Stato di una prenotazione di un mezzo. UT.02.
enum BookingStatus { attiva, annullata }
```
| Valore | Descrizione |
|---|---|
| `attiva` | Prenotazione attiva (veicolo riservato all'utente) |
| `annullata` | Prenotazione annullata dall'utente. UT.12 (annullo) / OP.12 |

### `Booking`
```
/// @brief Modello di una prenotazione effettuata dall'utente. UT.02, UT.13.
class Booking
```
Rappresenta la riserva esclusiva di un veicolo per un intervallo di minuti. I dati sono volatili (mock in-memory): in attesa del Business Tier server.

| Campo | Tipo | Descrizione |
|---|---|---|
| `vehicleId` | `String` | Codice identificativo del veicolo prenotato (es. `'SC-001'`) |
| `vehicleTypeLabel` | `String` | Etichetta leggibile del tipo di mezzo (es. `'Scooter Elettrico'`) |
| `vehicleType` | `VehicleType` | Tipo di veicolo, per icona/colore coerenti con il resto dell'app |
| `createdAt` | `DateTime` | Istante di creazione della prenotazione |
| `durationMinutes` | `int` | Durata della riserva richiesta, in minuti |
| `estimatedCost` | `double` | Costo stimato della prenotazione, in euro |
| `status` | `BookingStatus` | Stato corrente della prenotazione |

#### `expiresAt` → `DateTime`
Istante di scadenza della riserva.

### `bookingStore`
```
/// @brief Store globale in-memory delle prenotazioni utente. UT.02, UT.13.
final ValueNotifier<List<Booking>> bookingStore
```
Segue lo stesso pattern di `appLanguage`: un `ValueNotifier` osservabile dalle viste tramite `ValueListenableBuilder`, senza introdurre nuove dipendenze né pattern MVC. Sarà sostituito dalle API del Business Tier.

### `addBooking(Booking booking)` → `void`
```
/// @brief Aggiunge una nuova prenotazione in testa alla lista. UT.02.
/// @param booking la prenotazione da registrare.
```

### `cancelBooking(Booking booking)` → `void`
```
/// @brief Annulla una prenotazione esistente. UT.12.
/// @param booking la prenotazione da contrassegnare come annullata.
```

---

## 5. Store — `profile_store.dart`

**File:** `lib/profile_store.dart`

### `ProfileStore`
```
/// @brief Store osservabile dei dati di profilo e dei dati sensibili dell'utente.
class ProfileStore
```
Segue lo stesso pattern di `appLanguage` / `bookingStore` / `AppSettings`: un gruppo di `ValueNotifier` consultabili dalle viste tramite `ValueListenableBuilder`, senza introdurre pattern MVC. A differenza degli altri store (volatili), questo persiste i dati **localmente sul dispositivo** (UT.21, UT.22.2): i campi testuali via `SharedPreferences` e i file (foto profilo, documenti KYC) copiati nella sandbox dell'app (`getApplicationDocumentsDirectory`). Nessun dato lascia il dispositivo: la sincronizzazione cifrata (AES-256, IIN-4) sarà a carico del Business Tier `gestore_profili_ekyc` quando disponibile.

#### Dati anagrafici (UT.21)

| Campo | Tipo | Descrizione |
|---|---|---|
| `firstName` | `ValueNotifier<String>` | Nome dell'utente |
| `lastName` | `ValueNotifier<String>` | Cognome dell'utente |
| `email` | `ValueNotifier<String>` | Indirizzo email di accesso. IIN-1 |
| `address` | `ValueNotifier<String>` | Residenza completa dell'utente |
| `phone` | `ValueNotifier<String>` | Numero telefonico dell'utente |
| `photoPath` | `ValueNotifier<String?>` | Percorso locale della foto profilo, o null |

#### Dati sensibili: documenti KYC (UT.22.2, IIN-6)

| Campo | Tipo | Descrizione |
|---|---|---|
| `idCardPath` | `ValueNotifier<String?>` | Percorso locale della scansione/foto della carta d'identità, o null |
| `licensePath` | `ValueNotifier<String?>` | Percorso locale della scansione/foto della patente, o null |

#### Dati sensibili: metodo di pagamento (UT.11)

| Campo | Tipo | Descrizione |
|---|---|---|
| `cardHolder` | `ValueNotifier<String>` | Intestatario della carta registrata |
| `cardNumber` | `ValueNotifier<String>` | Numero della carta (memorizzato in chiaro solo localmente; in produzione sarà tokenizzato dal `gateway_pagamenti`). Mostrato sempre mascherato |
| `cardExpiry` | `ValueNotifier<String>` | Scadenza della carta in formato MM/AA |

#### `load()` → `Future<void>`
```
/// @brief Carica i dati persistiti localmente. Da invocare una sola volta
///        all'avvio (in `main`) prima di costruire l'app.
```

#### `savePersonalData(...)` → `Future<void>`
```
/// @brief Salva i dati anagrafici modificati nell'archivio locale. UT.21.
```

#### `savePaymentMethod(...)` → `Future<void>`
```
/// @brief Salva il metodo di pagamento nell'archivio locale. UT.11.
```

#### `setPhotoPath(String? path)` → `Future<void>`
```
/// @brief Imposta (o azzera) la foto profilo persistendone il percorso. UT.21.
```

#### `setIdCardPath(String? path)` → `Future<void>`
```
/// @brief Imposta (o azzera) il documento carta d'identità. UT.22.2.
```

#### `setLicensePath(String? path)` → `Future<void>`
```
/// @brief Imposta (o azzera) il documento patente. UT.22.2.
```

### `PickResult`
```
/// @brief Esito della selezione di un'immagine locale.
/// @param file il file selezionato e copiato nella sandbox, o null.
/// @param permissionDenied true se l'utente ha negato il permesso richiesto.
typedef PickResult = ({File? file, bool permissionDenied})
```

### `pickAndStoreImage(...)` → `Future<PickResult>`
```
/// @brief Seleziona un'immagine da galleria o fotocamera e la copia nella
///        sandbox dell'app (resta locale sul dispositivo).
///
/// Richiede esplicitamente il permesso di accesso a fotocamera/galleria
/// (IIN-16, GDPR) tramite `permission_handler` prima di aprire il picker.
/// Le immagini sono JPG/PNG, conformi ai formati KYC ammessi (IIN-6).
///
/// @param source origine dell'immagine (galleria o fotocamera).
/// @param basename nome-base del file di destinazione nella sandbox.
/// @return [PickResult] con il file copiato oppure il flag di permesso negato.
```

---

## 6. Store — `settings_store.dart`

**File:** `lib/settings_store.dart`

### `AppSettings`
```
/// @brief Preferenze applicative dell'utente per un servizio di noleggio mezzi.
class AppSettings
```
Segue lo stesso pattern osservabile di `appLanguage` / `bookingStore`: un gruppo di `ValueNotifier` consultabili dalle viste tramite `ValueListenableBuilder`, senza introdurre nuove dipendenze né pattern MVC. Lo stato è volatile (in-memory): sarà persistito/sincronizzato dal Business Tier server. NB: non è previsto alcun tema scuro (vincolo di progetto).

| Campo | Tipo | Descrizione |
|---|---|---|
| `pushNotifications` | `ValueNotifier<bool>` | Abilitazione globale delle notifiche push. IIN-19 |
| `bookingReminders` | `ValueNotifier<bool>` | Promemoria a schermo prima della scadenza della prenotazione. UT.15 |
| `promoNotifications` | `ValueNotifier<bool>` | Notifiche commerciali (promozioni e offerte). UT.18 |
| `locationServices` | `ValueNotifier<bool>` | Consenso ai servizi di localizzazione (GPS). IIN-16 (GDPR) |
| `usageDataSharing` | `ValueNotifier<bool>` | Condivisione di dati di utilizzo anonimi e aggregati. IIN-15 |

> **Nota (PR #3, allineamento 27/06/2026):** il campo `biometricUnlock` (conferma
> biometrica prima dello sblocco del mezzo, IIN-5) è stato **rimosso** dallo store e
> dalla relativa sezione "Sicurezza" della SettingsScreen. La documentazione qui sopra
> riflette i 5 campi effettivamente presenti in `settings_store.dart`.

---

## 7. Screens

### 7.1 SplashScreen

**File:** `lib/screens/splash_screen.dart`

```
/// @brief Schermata di avvio animata di LEAF Mobility.
///
/// Sequenza di caricamento minimalista e immediatamente comprensibile:
///   1. il logo-ruota entra con dissolvenza + scala e poi ruota di continuo,
///      come uno pneumatico che gira ("mezzo in movimento");
///   2. subito sotto, il nome "Leaf Mobility" viene "scritto" lettera per
///      lettera (effetto macchina da scrivere) con cursore lampeggiante;
///   3. una tagline appare in dissolvenza a testo completato;
///   4. al termine dell'attesa l'app naviga alla schermata di login.
class SplashScreen extends StatefulWidget
```

**Controller di animazione:**

| Campo | Descrizione |
|---|---|
| `_introCtrl` | Animazione d'ingresso (one-shot): dissolvenza + scala del logo |
| `_wheelCtrl` | Rotazione continua del logo-ruota (loop): "pneumatico che gira" |
| `_typeCtrl` | Effetto macchina da scrivere sul nome del brand |
| `_caretCtrl` | Lampeggio del cursore di scrittura |
| `_typed` | Numero di caratteri del brand attualmente visibili (0 → lunghezza nome) |
| `_taglineOpacity` | Dissolvenza della tagline, mostrata a testo completato |

**Metodi principali:**
- `_play()` — Avvia la sequenza: ingresso logo → scrittura nome → navigazione al login.
- `_buildWheel()` — Logo-ruota: entra in dissolvenza + scala, poi ruota di continuo.
- `_buildTypedBrand()` — Nome del brand "scritto" lettera per lettera con cursore lampeggiante.
- `_buildTagline()` — Tagline in dissolvenza, visibile a nome completato.

---

### 7.2 LoginScreen

**File:** `lib/screens/login_screen.dart`

```
class LoginScreen extends StatelessWidget
```
Schermata di accesso dell'utente. Presenta logo SVG, campi email/password, pulsante di login (accetta qualsiasi credenziale), link "Password dimenticata?" (UT.24 — password reset via email) e pulsante di registrazione.

---

### 7.3 RegistrationScreen

**File:** `lib/screens/registration_screen.dart`

```
class RegistrationScreen extends StatelessWidget
```
Modulo di registrazione nuovo utente con i campi: Nome, Cognome, Email, Residenza completa, Password, Numero telefonico. Accetta qualsiasi input e naviga alla home.

---

### 7.4 MainLayout

**File:** `lib/screens/main_layout.dart`

```
class MainLayout extends StatefulWidget
```
Layout principale dell'app con `AppBar` (logo, notifiche, avatar profilo), drawer menu laterale, `BottomNavigationBar` a 4 tab (Home, Prenota, Mappa, Abbonamenti) e corpo animato con `AnimatedSwitcher`. Si ridisegna al cambio lingua tramite `Translated` (IIN-7).

---

### 7.5 HomeTab

**File:** `lib/screens/home_tab.dart`

```
/// Home tab — search, history, available vehicles. UT.03, UT.05, UT.07.
class HomeTab extends StatefulWidget
```
Tab principale con: card di ricerca duale (partenza/arrivo), chip filtro per tipo di mezzo (UT.05), striscia cronologia percorsi (UT.17, ordine crescente) e griglia mezzi disponibili vicini.

**Widget interni:**
- `_DualSearchCard` — Two-part departure/arrival search card — navigates to SearchScreen on tap. UT.03, UT.07.
- `_GreenDot` — Indicatore circolare verde per la partenza.

---

### 7.6 MapTab

**File:** `lib/screens/map_tab.dart`

```
/// Map screen — sistemaTPL always integrated (architectural constraint).
/// UT.01 vehicles, UT.05 filters, UT.14 charging, UT.20 SOS FAB.
class MapTab extends StatefulWidget
```
Mappa Google con marker dei mezzi (veicoli + stazioni di ricarica + fermate TPL Bari), chip filtro per tipo di veicolo, FAB per localizzazione utente e FAB SOS di emergenza (UT.20). I marker si ridimensionano in base al livello di zoom della mappa. La localizzazione GPS è richiesta tramite `permission_handler` con timeout di 10 secondi.

**Filtri veicoli (UT.05):**

| Filtro | Colore |
|---|---|
| Tutti | `accentBrown` |
| Scooter | `#388E3C` |
| Bici | `#0097A7` |
| Auto | `#E65100` |
| E-Moto | `#1565C0` |
| Ricarica | `#F57F17` |

---

### 7.7 BookingTab

**File:** `lib/screens/booking_tab.dart`

```
/// @brief Tab "Prenota": punto d'accesso alla prenotazione dei mezzi. UT.02.
///
/// Sostituisce il vecchio segnaposto "Servizio non disponibile": elenca i mezzi
/// disponibili nei dintorni e, al tap, apre la [BookingScreen] del veicolo
/// scelto. In testa offre una scorciatoia a "Mie Prenotazioni". Si ridisegna al
/// cambio lingua tramite [Translated]. IIN-7.
class BookingTab extends StatelessWidget
```

---

### 7.8 BookingScreen

**File:** `lib/screens/booking_screen.dart`

```
/// @brief Schermata di prenotazione di un mezzo. UT.02.
///
/// Consente di scegliere la durata della riserva, mostra il costo stimato in
/// base alla tariffa del veicolo e conferma la prenotazione registrandola
/// nello [bookingStore]. UT.03 (stima costo), UT.02 (prenotazione).
class BookingScreen extends StatefulWidget
```

| Campo | Tipo | Descrizione |
|---|---|---|
| `vehicle` | `VehicleData` | Veicolo da prenotare |
| `_durations` | `List<int>` | Opzioni di durata della riserva (in minuti): 15, 30, 45, 60 |
| `_selectedMinutes` | `int` | Durata selezionata, in minuti |
| `_ratePerMinute` | `double` | Tariffa al minuto del veicolo, in euro |
| `_estimatedCost` | `double` | Costo stimato per la durata selezionata. UT.03 |

#### `_confirm()` → `void`
Registra la prenotazione e torna all'elenco "Mie Prenotazioni". UT.02.

---

### 7.9 MyBookingsScreen

**File:** `lib/screens/my_bookings_screen.dart`

```
/// @brief Schermata "Mie Prenotazioni": elenco delle prenotazioni effettuate.
///
/// UT.02 (prenotazioni effettuate), UT.12 (annullo prenotazione).
/// Osserva lo [bookingStore] e si aggiorna automaticamente quando l'utente
/// crea o annulla una prenotazione.
class MyBookingsScreen extends StatelessWidget
```

---

### 7.10 VehicleDetailScreen

**File:** `lib/screens/vehicle_detail_screen.dart`

#### `VehicleType`
```
/// Vehicle type constants — shared across detail and search screens.
enum VehicleType { scooter, bike, car, emoto }
```

#### `VehicleData`
```
/// Vehicle data model used by SearchScreen and VehicleDetailScreen.
class VehicleData
```

| Campo | Tipo | Descrizione |
|---|---|---|
| `id` | `String` | Identificativo veicolo |
| `type` | `VehicleType` | Tipo di veicolo |
| `batteryPercent` | `int` | Percentuale batteria (0–100) |
| `rangeKm` | `int` | Autonomia stimata in km |
| `distanceMeters` | `int` | Distanza dall'utente/punto di partenza |
| `status` | `String` | 'Disponibile' / 'In uso' / 'In manutenzione' |

#### `VehicleDetailScreen`
```
/// Vehicle detail screen — shows all user-visible characteristics.
/// UT.05 (filter/view characteristics), UT.06 (wait time estimate),
/// UT.10 (unlock stub), UT.02 (booking stub).
class VehicleDetailScreen extends StatelessWidget
```

#### `kAvailableVehicles`
```
/// Mezzi disponibili nei dintorni (mock condiviso fino al `gestore_flotta`).
const List<VehicleData> kAvailableVehicles
```
Esposto come elenco pubblico così da poter essere riusato sia dalla home che dalla tab "Prenota" senza duplicare i dati di mock. UT.01, UT.05.

---

### 7.11 SearchScreen

**File:** `lib/screens/search_screen.dart`

```
/// Full-screen search screen.
/// Requires BOTH departure AND arrival to show route list (UT.03, UT.07).
class SearchScreen extends StatefulWidget
```
Ricerca a schermo intero con campo partenza e arrivo, suggerimenti località (filtro in tempo reale), cronologia ricerche recenti e, quando entrambi i campi sono compilati, elenco dei percorsi disponibili (UT.07). Include shortcut "Usa posizione corrente".

---

### 7.12 RouteDetailScreen

**File:** `lib/screens/route_detail_screen.dart`

#### `RouteData`
```
/// A single route option. UT.07 (route options with TPL integration).
class RouteData
```

| Campo | Tipo | Descrizione |
|---|---|---|
| `name` | `String` | Nome del percorso |
| `description` | `String` | Descrizione |
| `durationMinutes` | `int` | Durata in minuti |
| `distanceKm` | `double` | Distanza in km |
| `transportSummary` | `String` | Modalità di trasporto (es. "Scooter + TPL Bus") |
| `recommended` | `List<VehicleData>` | Veicoli consigliati |
| `hasTpl` | `bool` | Integrazione TPL disponibile |

#### `RouteDetailScreen`
```
/// Route detail screen — UT.07, UT.08, UT.03.
/// Shows route summary, recommended vehicles and lets user view vehicle info.
class RouteDetailScreen extends StatelessWidget
```

---

### 7.13 HistoryScreen

**File:** `lib/screens/history_screen.dart`

#### `TripEntry`
```
/// A single trip entry in the history. UT.17.
class TripEntry
```

| Campo | Tipo | Descrizione |
|---|---|---|
| `id` | `String` | Identificativo corsa (es. `'#0010'`) |
| `date` | `String` | Data della corsa |
| `time` | `String` | Orario della corsa |
| `from` | `String` | Punto di partenza |
| `to` | `String` | Punto di arrivo |
| `vehicleType` | `String` | Tipo di veicolo usato |
| `cost` | `double` | Costo della corsa in euro |
| `durationMinutes` | `int` | Durata in minuti |
| `distanceKm` | `double` | Distanza in km |

##### `sequence` → `int`
Progressivo numerico ricavato dall'id (es. `'#0010'` → 10). Le corse sono registrate in ordine cronologico crescente di id, quindi questo valore funge da chiave di ordinamento affidabile per data/ora.

#### `HistoryScreen`
```
/// Trip history screen — UT.17 (storico corse: tragitti e spese).
///
/// Connected with the home tab history section and drawer Cronologia item.
/// Permette di consultare le corse ordinandole secondo diversi criteri
/// (data, durata, distanza, costo) in ordine crescente o decrescente.
class HistoryScreen extends StatefulWidget
```

**Criteri di ordinamento (`_SortField`):**
Criteri di ordinamento disponibili per la cronologia delle corse (UT.17): `data`, `durata`, `distanza`, `costo`.

---

### 7.14 TripDetailScreen

**File:** `lib/screens/trip_detail_screen.dart`

```
/// Detail screen for a single past trip. UT.17 (storico corse).
///
/// Opened from the Home tab history strip and from the full history list.
/// Shows the ride characteristics (route, time, duration, distance), the
/// vehicle used and the cost breakdown.
class TripDetailScreen extends StatelessWidget
```

#### `_showReportDialog(BuildContext context)` → `void`
Apre il modulo di segnalazione di un problema sulla corsa. UT.09. Invio simulato (snackbar di conferma) finché il Business Tier `gestore_assistenza_ticket` non sarà disponibile, coerentemente con la schermata Assistenza.

---

### 7.15 ProfileScreen

**File:** `lib/screens/profile_screen.dart`

```
class ProfileScreen extends StatelessWidget
```
Hub di navigazione del profilo utente: avatar, nome/cognome, email e voci menu (Account, Gestione abbonamento, Dati sensibili, Assistenza, Log out). Riflette i dati locali del profilo (UT.21).

---

### 7.16 AccountScreen

**File:** `lib/screens/account_screen.dart`

```
/// @brief Schermata dei dati anagrafici dell'utente, visualizzabili e
///        modificabili. UT.21.
///
/// Ogni campo è di sola lettura finché non si tocca la matita di fianco, che
/// lo abilita singolarmente alla modifica. La foto profilo può essere caricata
/// da galleria o fotocamera e resta **locale** sul dispositivo
/// ([ProfileStore]). Le modifiche sono persistite localmente al salvataggio.
class AccountScreen extends StatefulWidget
```

---

### 7.17 SensitiveDataScreen

**File:** `lib/screens/sensitive_data_screen.dart`

```
/// @brief Schermata dei dati sensibili dell'utente. UT.11, UT.22.2.
///
/// Permette di visualizzare e modificare:
///   1. i documenti ufficiali (carta d'identità, patente) — caricamento KYC
///      di immagini JPG/PNG da galleria o fotocamera (IIN-6);
///   2. il metodo di pagamento registrato (UT.11).
///
/// Tutti i dati restano **locali** sul dispositivo ([ProfileStore]); la
/// cifratura at-rest (AES-256) e la verifica KYC saranno a carico del Business
/// Tier (`gestore_profili_ekyc`, `gateway_pagamenti`). I numeri di carta sono
/// sempre mostrati mascherati.
class SensitiveDataScreen extends StatefulWidget
```

---

### 7.18 SettingsScreen

**File:** `lib/screens/settings_screen.dart`

```
/// @brief Schermata Impostazioni dell'app utente.
///
/// Raccoglie le impostazioni principali di un'app per mezzi a noleggio:
/// lingua (IIN-7), notifiche (IIN-19), privacy/posizione (IIN-16), sicurezza
/// (IIN-5) e informazioni. Per scelta di progetto NON è previsto un tema
/// scuro. Le preferenze sono osservate da [AppSettings] e si ridisegnano live
/// al cambio lingua tramite [Translated].
class SettingsScreen extends StatefulWidget
```

**Sezioni:**
- **Lingua** — Card di selezione della lingua (Italiano / English). IIN-7.
- **Notifiche** — Push, promemoria prenotazione, promozioni.
- **Privacy e posizione** — Servizi di localizzazione, condivisione dati di utilizzo.
- **Informazioni** — Termini di servizio, informativa privacy, versione.

> **Nota (PR #3, allineamento 27/06/2026):** la sezione **Sicurezza** (conferma sblocco
> con biometria, IIN-5) è stata **rimossa** dalla Ui insieme al campo `biometricUnlock`.
> Le sezioni effettive della schermata sono ora quattro: Lingua, Notifiche, Privacy e
> posizione, Informazioni. Il `@brief` riprodotto sopra cita ancora "sicurezza (IIN-5)"
> perché copia letterale del docstring sorgente, non ancora ripulito (fuori scope §3:
> nessuna modifica al codice).

---

### 7.19 SupportScreen

**File:** `lib/screens/support_screen.dart`

```
/// @brief Schermata di assistenza utente con invio feedback/segnalazioni. UT.09.
///
/// Raccoglie tre blocchi coerenti con l'estetica minimalista dell'app:
///   1. contatti diretti (email/telefono, mock in attesa del Business Tier);
///   2. domande frequenti (FAQ) come pannelli espandibili;
///   3. modulo di invio feedback/segnalazione con tipo richiesta, valutazione
///      a stelle e messaggio.
///
/// I dati sono volatili: l'invio è simulato (snackbar di conferma) finché il
/// `gestore_assistenza_ticket` del Business Tier non sarà disponibile.
class SupportScreen extends StatefulWidget
```

**Tipologia richiesta (`_RequestType`):** `feedback`, `report`, `suggestion`.

---

### 7.20 FaqScreen

**File:** `lib/screens/faq_screen.dart`

#### `_Faq`
```
/// @brief Coppia domanda/risposta delle FAQ (chiavi in italiano, tradotte a UI).
class _Faq
```

| Campo | Tipo | Descrizione |
|---|---|---|
| `question` | `String` | Chiave della domanda (lingua sorgente italiana, tradotta via `tr`) |
| `answer` | `String` | Chiave della risposta (lingua sorgente italiana, tradotta via `tr`) |

#### `FaqScreen`
```
/// @brief Schermata FAQ dedicata: barra di ricerca + domande più comuni. UT.09.
///
/// Filtra in tempo reale le domande e le risposte in base al testo digitato e
/// mostra l'elenco come pannelli espandibili. Si ritraduce live al cambio
/// lingua tramite [Translated]. IIN-7.
class FaqScreen extends StatefulWidget
```

---

### 7.21 SOSScreen

**File:** `lib/screens/sos_screen.dart`

```
/// Emergency SOS screen.
/// UT.20 — user activates an emergency signal to communicate GPS position to rescuers.
/// IIN-18 — GPS coordinates must be forwarded within 5 seconds of pressing SOS.
class SOSScreen extends StatefulWidget
```

Schermata di emergenza con pulsante SOS pulsante, countdown di 5 secondi (IIN-18), stato di invio e possibilità di annullamento. Richiede il permesso di localizzazione per comunicare le coordinate GPS ai soccorsi.

---

### 7.22 NotificationsScreen

**File:** `lib/screens/notifications_screen.dart`

```
/// Empty-state notifications screen.
/// References: UT.15 (booking expiry), UT.19 (service interruption), UT.20 (SOS confirmation).
class NotificationsScreen extends StatelessWidget
```

Schermata di stato vuoto per le notifiche. Mostrerà avvisi di scadenza prenotazione (UT.15), interruzioni servizio (UT.19) e conferme SOS (UT.20) quando il backend sarà disponibile.

---

### 7.23 SubscriptionManagerScreen

**File:** `lib/screens/subscription_manager_screen.dart`

```
class SubscriptionManagerScreen extends StatelessWidget
```
Gestione dell'abbonamento attivo: card riepilogativa con piano corrente (Piano Premium), percentuale rimanente, data di scadenza e opzioni (acquista nuovo abbonamento, storico acquisti).

---

### 7.24 BuySubscriptionScreen

**File:** `lib/screens/buy_subscription_screen.dart`

```
class BuySubscriptionScreen extends StatelessWidget
```
Schermata di acquisto abbonamento con tre piani: Daily Pass (4,99 €/24h), Weekly Pass (14,99 €/7gg), Monthly Premium (39,99 €/30gg). Acquisto simulato con snackbar di conferma.

---

### 7.25 UnavailableServiceTab

**File:** `lib/screens/unavailable_service_tab.dart`

```
class UnavailableServiceTab extends StatelessWidget
```
Segnaposto per le sezioni del servizio non ancora sviluppate. Mostra un'icona foglia grigia, un messaggio di servizio non disponibile e un pulsante per tornare alla home.

---

## 8. Widgets

### 8.1 DrawerMenu

**File:** `lib/widgets/drawer_menu.dart`

```
/// Main navigation drawer. Menu items preserve exact labels, icons and routes.
class DrawerMenu extends StatelessWidget
```
Menu laterale di navigazione principale dell'app. Contiene: header con logo e titolo "Menù Principale", voci di navigazione (Mie Prenotazioni, Cronologia, Acquista abbonamento, Impostazioni, Supporto), voce SOS di emergenza evidenziata in rosso (UT.20, IIN-18) e versione app. Si ritraduce live al cambio lingua tramite `Translated` (IIN-7).


## 9. Doxygen Esteso (Estratto dal Codice - 04/08/2026)

### File: `active_trip_store.dart`

### `enum TripStatus`
@brief Stato di una corsa in svolgimento. UT.10, UT.12.

### `class ActiveTrip`
Corsa in corso: il mezzo è sbloccato e in uso.
  inCorso,

   Corsa in pausa: il mezzo resta bloccato e riservato all'utente (UT.12).
  inPausa,
}

 @brief Modello della corsa attiva dell'utente. UT.10 (avvio), UT.12 (pausa).

 Rappresenta la corsa avviata sul backend (`id_corsa`) e il suo stato locale.
 Tiene il minimo necessario alla UI di pausa/riprendi; i dati di dettaglio
 (costo, km) restano a carico del Business Tier `gestore_corse`.

### `final ValueNotifier`
@brief Crea la corsa attiva.
  ActiveTrip({
    required this.idCorsa,
    required this.vehicleId,
    required this.vehicleType,
    required this.startedAt,
    this.status = TripStatus.inCorso,
  });

   Identificativo della corsa sul backend.
  final String idCorsa;

   Codice del veicolo in uso (es. 'SC-001').
  final String vehicleId;

   Tipo di veicolo, per icona/colore coerenti con il resto dell'app.
  final VehicleType vehicleType;

   Istante di avvio della corsa.
  final DateTime startedAt;

   Stato corrente della corsa (in corso o in pausa).
  final TripStatus status;

   @brief Indica se la corsa è attualmente in pausa (UT.12).
  bool get isPaused => status == TripStatus.inPausa;

   @brief Copia con stato aggiornato (gli altri campi restano invariati).
   @param status Nuovo stato della corsa.
   @return Nuova istanza con lo stato richiesto.
  ActiveTrip copyWith({TripStatus? status}) => ActiveTrip(
    idCorsa: idCorsa,
    vehicleId: vehicleId,
    vehicleType: vehicleType,
    startedAt: startedAt,
    status: status ?? this.status,
  );
}

 @brief Store globale della corsa attiva (al più una). UT.10, UT.12.

 Segue lo stesso pattern di [bookingStore]: un [ValueNotifier] osservabile
 dalle viste tramite [ValueListenableBuilder], senza nuove dipendenze né
 pattern MVC. Vale `null` quando non c'è alcuna corsa in svolgimento.

### `void startActiveTrip`
@brief Registra l'avvio di una corsa come corsa attiva. UT.10.
 @param idCorsa Identificativo della corsa restituito dal backend.
 @param vehicleId Codice del veicolo in uso.
 @param vehicleType Tipo di veicolo.

### `void setActiveTripStatus`
@brief Aggiorna lo stato della corsa attiva (pausa/ripresa). UT.12.
 @param status Nuovo stato da applicare; ignorato se non c'è corsa attiva.

### `void clearActiveTrip`
@brief Termina la corsa attiva azzerando lo store. UT.04.

### `void restoreActiveTrip`
@brief Ripristina la corsa attiva da un documento corsa del backend (UT.10/UT.12, punto 2).

 Usato all'avvio/risveglio dell'app per recuperare una corsa in corso o in pausa
 dopo che lo stato locale (volatile) è andato perso (`GET /corse/attiva`). Preserva
 l'istante di avvio e lo stato di pausa indicati dal server.

 @param corsa Documento corsa grezzo (`_id`, `codice_identificativo_mezzo`,
   `tipo_mezzo`, `stato`, `data_ora_inizio`).

### File: `app_version.dart`

### `const String`
@file app_version.dart
 @brief Versione logica unica dell'app mobile (§8 DIRECTIVES — schema
        `1.0.0.0-alpha.N`).

 Sorgente **unica** del numero di versione mostrato in UI (drawer e
 impostazioni): evita la deriva tra punti hard-coded indipendenti. Va tenuta
 allineata al campo `version:` di `pubspec.yaml` ad ogni bump (§8).
library;

 Versione logica corrente dell'app (formato a 4 segmenti, §8).
 Mapping pubspec: `1.0.0.0-alpha.31` → `version: 1.0.0-alpha.31+31`.

### File: `booking_store.dart`

### `enum BookingStatus`
@brief Stato di una prenotazione di un mezzo. UT.02.

### `class Booking`
Prenotazione attiva (veicolo riservato all'utente).
  attiva,

   Prenotazione annullata dall'utente. UT.12 (annullo) / OP.12.
  annullata,
}

 @brief Modello di una prenotazione effettuata dall'utente. UT.02, UT.13.

 Rappresenta la riserva esclusiva di un veicolo per un intervallo di minuti.
 Le prenotazioni reali provengono dal backend (`/api/v1/prenotazioni`) via
 [Booking.fromApi]; quelle locali (mezzi di riserva offline senza `docId`)
 restano in-memory con [id] nullo.

### `VehicleType _vehicleTypeDaApi`
Id della prenotazione lato server (Firestore), per l'annullo (UT.12).
   Null per le prenotazioni locali dimostrative (offline, senza backend).
  final String? id;

   Codice identificativo del veicolo prenotato (es. 'SC-001').
  final String vehicleId;

   Etichetta leggibile del tipo di mezzo (es. 'Scooter Elettrico').
  final String vehicleTypeLabel;

   Tipo di veicolo, per icona/colore coerenti con il resto dell'app.
  final VehicleType vehicleType;

   Istante di creazione della prenotazione.
  final DateTime createdAt;

   Durata della riserva richiesta, in minuti.
  final int durationMinutes;

   Costo stimato della prenotazione, in euro.
  final double estimatedCost;

   Stato corrente della prenotazione.
  BookingStatus status;

  Booking({
    required this.vehicleId,
    required this.vehicleTypeLabel,
    required this.vehicleType,
    required this.createdAt,
    required this.durationMinutes,
    required this.estimatedCost,
    this.id,
    this.status = BookingStatus.attiva,
  });

   @brief Costruisce un [Booking] da un documento prenotazione della API (UT.02).
  
   La durata è derivata dalla finestra inizio→scadenza quando presente; il costo
   stimato è ricalcolato dalla tariffa al minuto del tipo di mezzo (coerente con
   la stima mostrata in fase di prenotazione, UT.03).
  
   @param doc Documento `prenotazioni` grezzo (`_id`, `codice_identificativo_mezzo`,
     `tipo_mezzo`, `data_ora_inizio`, `data_ora_scadenza`…).
   @return Il modello di vista con `id` valorizzato per l'annullo.
  factory Booking.fromApi(Map<String, dynamic> doc) {
    final type = _vehicleTypeDaApi('${doc['tipo_mezzo'] ?? ''}');
    final createdAt =
        DateTime.tryParse('${doc['data_ora_inizio'] ?? ''}')?.toLocal() ??
        DateTime.now();
    final scadenza = doc['data_ora_scadenza'];
    final scadenzaDt = scadenza is String
        ? DateTime.tryParse(scadenza)?.toLocal()
        : null;
    final durata = scadenzaDt != null
        ? scadenzaDt.difference(createdAt).inMinutes
        : 0;
    final minuti = durata > 0 ? durata : 0;
    return Booking(
      id: doc['_id']?.toString(),
      vehicleId: '${doc['codice_identificativo_mezzo'] ?? doc['id_mezzo'] ?? ''}',
      vehicleTypeLabel: _etichettaTipoMezzo(type),
      vehicleType: type,
      createdAt: createdAt,
      durationMinutes: minuti,
      estimatedCost: _tariffaAlMinuto(type) * minuti,
    );
  }

   Istante di scadenza della riserva.
  DateTime get expiresAt => createdAt.add(Duration(minutes: durationMinutes));
}

 Mappa il discriminante `tipo_mezzo` del server sull'enum di vista [VehicleType].

### `String _etichettaTipoMezzo`
Etichetta leggibile del tipo di mezzo per la card prenotazione.

### `double _tariffaAlMinuto`
Tariffa al minuto (in euro) per tipo di mezzo, coerente con `booking_screen` (UT.03).

### `final ValueNotifier`
@brief Store globale in-memory delle prenotazioni utente. UT.02, UT.13.

 Segue lo stesso pattern di [appLanguage]: un [ValueNotifier] osservabile
 dalle viste tramite [ValueListenableBuilder], senza introdurre nuove
 dipendenze ne' pattern MVC. Sara' sostituito dalle API del Business Tier.

### `void addBooking`
@brief Aggiunge una nuova prenotazione in testa alla lista. UT.02.
 @param booking la prenotazione da registrare.

### `void cancelBooking`
@brief Annulla una prenotazione esistente. UT.12.
 @param booking la prenotazione da contrassegnare come annullata.

### File: `dev_settings_store.dart`

### `class DevSettings`
@brief Impostazioni della "Modalità sviluppatore" dell'app utente.

 Consente, in fase di sviluppo/debug, di puntare l'app a un server diverso da
 quello di produzione (es. un'istanza in LAN `http://192.168.1.60:8770/api/v1`)
 senza dover ricompilare con `--dart-define`. Segue lo stesso pattern
 osservabile del resto dell'app ([AppSettings]/[appLanguage]): [ValueNotifier]
 consultabili dalle viste, nessun nuovo pattern ne' dipendenza (usa
 `shared_preferences`, gia' presente).

 Lo stato e' persistito on-device, cosi' l'override sopravvive ai riavvii
 dell'app durante una sessione di debug USB.

### File: `l10n.dart`

### `class Translated`
@brief Ricostruisce il proprio sottoalbero al cambio di lingua dell'app.

 Le schermate raggiunte via `Navigator.push` vengono costruite una sola
 volta e memorizzate dalla route: un cambio di [appLanguage] non le
 ricostruisce e i testi resterebbero nella lingua precedente. Avvolgendo il
 contenuto della schermata in [Translated], la vista si ridisegna live al
 cambio lingua senza introdurre dipendenze ne' pattern MVC (stesso pattern
 osservabile di [appLanguage]). IIN-7 (internazionalizzazione).

### `const Map`
Builder del contenuto localizzato della schermata.
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

### File: `profile_store.dart`

### `class ProfileStore`
@brief Store osservabile dei dati di profilo e dei dati sensibili dell'utente.

 Segue lo stesso pattern di [appLanguage] / [bookingStore] / [AppSettings]:
 un gruppo di [ValueNotifier] consultabili dalle viste tramite
 [ValueListenableBuilder], senza introdurre pattern MVC. A differenza degli
 altri store (volatili), questo persiste i dati **localmente sul dispositivo**
 (UT.21, UT.22.2): i campi testuali via [SharedPreferences] e i file
 (foto profilo, documenti KYC) copiati nella sandbox dell'app
 ([getApplicationDocumentsDirectory]). Nessun dato lascia il dispositivo:
 la sincronizzazione cifrata (AES-256, IIN-4) sara' a carico del Business
 Tier `gestore_profili_ekyc` quando disponibile.

### `typedef PickResult`
Nome dell'utente (vuoto finché non sincronizzato dal backend, UT.21).
  static final ValueNotifier<String> firstName = ValueNotifier<String>('');

   Cognome dell'utente (vuoto finché non sincronizzato dal backend, UT.21).
  static final ValueNotifier<String> lastName = ValueNotifier<String>('');

   Indirizzo email di accesso. IIN-1.
  static final ValueNotifier<String> email = ValueNotifier<String>('');

   Residenza completa dell'utente.
  static final ValueNotifier<String> address = ValueNotifier<String>('');

   Numero telefonico dell'utente.
  static final ValueNotifier<String> phone = ValueNotifier<String>('');

   Percorso locale della foto profilo (file nella sandbox dell'app), o null.
  static final ValueNotifier<String?> photoPath = ValueNotifier<String?>(null);

  // ── Dati sensibili: documenti KYC (UT.22.2, IIN-6) ────────────────────────

   Percorso locale della scansione/foto della carta d'identita', o null.
  static final ValueNotifier<String?> idCardPath = ValueNotifier<String?>(null);

   Percorso locale della scansione/foto della patente, o null.
  static final ValueNotifier<String?> licensePath = ValueNotifier<String?>(
    null,
  );

  // ── Dati sensibili: metodo di pagamento (UT.11) ───────────────────────────

   Intestatario della carta registrata.
  static final ValueNotifier<String> cardHolder = ValueNotifier<String>('');

   Numero della carta (memorizzato in chiaro solo localmente; in produzione
   sara' tokenizzato dal `gateway_pagamenti`). Mostrato sempre mascherato.
  static final ValueNotifier<String> cardNumber = ValueNotifier<String>('');

   Scadenza della carta in formato MM/AA.
  static final ValueNotifier<String> cardExpiry = ValueNotifier<String>('');

  // ── Persistenza locale ────────────────────────────────────────────────────

  static const String _kFirstName = 'profile.firstName';
  static const String _kLastName = 'profile.lastName';
  static const String _kEmail = 'profile.email';
  static const String _kAddress = 'profile.address';
  static const String _kPhone = 'profile.phone';
  static const String _kPhotoPath = 'profile.photoPath';
  static const String _kIdCardPath = 'profile.idCardPath';
  static const String _kLicensePath = 'profile.licensePath';
  static const String _kCardHolder = 'profile.cardHolder';
  static const String _kCardNumber = 'profile.cardNumber';
  static const String _kCardExpiry = 'profile.cardExpiry';

   @brief Carica i dati persistiti localmente. Da invocare una sola volta
          all'avvio (in `main`) prima di costruire l'app.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    firstName.value = prefs.getString(_kFirstName) ?? firstName.value;
    lastName.value = prefs.getString(_kLastName) ?? lastName.value;
    email.value = prefs.getString(_kEmail) ?? email.value;
    address.value = prefs.getString(_kAddress) ?? address.value;
    phone.value = prefs.getString(_kPhone) ?? phone.value;
    photoPath.value = prefs.getString(_kPhotoPath);
    idCardPath.value = prefs.getString(_kIdCardPath);
    licensePath.value = prefs.getString(_kLicensePath);
    cardHolder.value = prefs.getString(_kCardHolder) ?? '';
    cardNumber.value = prefs.getString(_kCardNumber) ?? '';
    cardExpiry.value = prefs.getString(_kCardExpiry) ?? '';
  }

   @brief Salva i dati anagrafici modificati nell'archivio locale. UT.21.
  static Future<void> savePersonalData({
    required String firstNameValue,
    required String lastNameValue,
    required String emailValue,
    required String addressValue,
    required String phoneValue,
  }) async {
    firstName.value = firstNameValue;
    lastName.value = lastNameValue;
    email.value = emailValue;
    address.value = addressValue;
    phone.value = phoneValue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFirstName, firstNameValue);
    await prefs.setString(_kLastName, lastNameValue);
    await prefs.setString(_kEmail, emailValue);
    await prefs.setString(_kAddress, addressValue);
    await prefs.setString(_kPhone, phoneValue);
  }

   @brief Salva il metodo di pagamento nell'archivio locale. UT.11.
  static Future<void> savePaymentMethod({
    required String holder,
    required String number,
    required String expiry,
  }) async {
    cardHolder.value = holder;
    cardNumber.value = number;
    cardExpiry.value = expiry;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCardHolder, holder);
    await prefs.setString(_kCardNumber, number);
    await prefs.setString(_kCardExpiry, expiry);
  }

   @brief Imposta (o azzera) la foto profilo persistendone il percorso. UT.21.
  static Future<void> setPhotoPath(String? path) async {
    photoPath.value = path;
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_kPhotoPath);
    } else {
      await prefs.setString(_kPhotoPath, path);
    }
  }

   @brief Imposta (o azzera) il documento carta d'identita'. UT.22.2.
  static Future<void> setIdCardPath(String? path) async {
    idCardPath.value = path;
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_kIdCardPath);
    } else {
      await prefs.setString(_kIdCardPath, path);
    }
  }

   @brief Imposta (o azzera) il documento patente. UT.22.2.
  static Future<void> setLicensePath(String? path) async {
    licensePath.value = path;
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_kLicensePath);
    } else {
      await prefs.setString(_kLicensePath, path);
    }
  }
}

 @brief Esito della selezione di un'immagine locale.
 @param file il file selezionato e copiato nella sandbox, o null.
 @param permissionDenied true se l'utente ha negato il permesso richiesto.

### File: `settings_store.dart`

### `class AppSettings`
@brief Preferenze applicative dell'utente per un servizio di noleggio mezzi.

 Segue lo stesso pattern osservabile di [appLanguage] / [bookingStore]: un
 gruppo di [ValueNotifier] consultabili dalle viste tramite
 [ValueListenableBuilder], senza introdurre nuove dipendenze ne' pattern MVC.
 Lo stato e' volatile (in-memory): sara' persistito/sincronizzato dal Business
 Tier server. NB: non e' previsto alcun tema scuro (vincolo di progetto).

### File: `api\api_client.dart`

### `class LeafApiException`
@brief Eccezione applicativa di rete: porta il messaggio di dominio e il codice HTTP.

 Normalizza gli errori del backend (campo `dettaglio`) e di trasporto, cosi' che
 la UI possa mostrare un messaggio leggibile senza conoscere i dettagli di Dio.

### `class TokenStore`
@brief Crea l'eccezione con messaggio e codice opzionale.
  LeafApiException(this.messaggio, {this.codice});

   @brief Messaggio leggibile per l'utente.
  final String messaggio;

   @brief Codice HTTP associato (se disponibile).
  final int? codice;

  @override
  String toString() => messaggio;
}

 @brief Custodia cifrata del token JWT on-device (Keychain/Keystore) — TD-10 / IIN-4.

 I dati sensibili (token di sessione) non sono mai salvati in chiaro: si appoggiano
 all'archivio sicuro di piattaforma fornito da `flutter_secure_storage`.

### `class DeviceIdStore`
@brief Crea la custodia; consente di iniettare uno storage fittizio nei test.
  TokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const String _chiave = 'leaf_jwt';

   @brief Salva il token JWT in modo cifrato.
   @param token Token di accesso da custodire.
  Future<void> salva(String token) =>
      _storage.write(key: _chiave, value: token);

   @brief Legge il token JWT custodito.
   @return Il token, o null se assente.
  Future<String?> leggi() => _storage.read(key: _chiave);

   @brief Cancella il token (logout).
  Future<void> cancella() => _storage.delete(key: _chiave);
}

 @brief Custodia dell'identificativo stabile del dispositivo (IIN-14).

 Il backend limita a 3 i dispositivi attivi per utente: il client invia al login un
 `device_id` stabile, generato una sola volta al primo avvio (UUID v4) e conservato
 nell'archivio sicuro di piattaforma (`flutter_secure_storage`, nessuna dipendenza nuova).

### `class ApiClient`
@brief Crea la custodia; consente di iniettare uno storage fittizio nei test.
  DeviceIdStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const String _chiave = 'leaf_device_id';

   @brief Restituisce il device_id stabile, generandolo e salvandolo al primo accesso.
   @return Identificativo univoco e persistente del dispositivo (UUID v4).
  Future<String> ottieni() async {
    final esistente = await _storage.read(key: _chiave);
    if (esistente != null && esistente.isNotEmpty) return esistente;
    final nuovo = _generaUuidV4();
    await _storage.write(key: _chiave, value: nuovo);
    return nuovo;
  }

   @brief Genera un UUID v4 con sorgente casuale crittografica (RFC 4122).
   @return Stringa UUID v4 (8-4-4-4-12 cifre esadecimali).
  static String _generaUuidV4() {
    final rnd = Random.secure();
    final byte = List<int>.generate(16, (_) => rnd.nextInt(256));
    byte[6] = (byte[6] & 0x0f) | 0x40; // versione 4
    byte[8] = (byte[8] & 0x3f) | 0x80; // variante RFC 4122
    final hex = byte.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}'
        '-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

 @brief Client HTTP verso il backend LEAF: inietta il Bearer token e normalizza gli errori.

 Espone l'istanza Dio (riusabile dai repository) e la custodia del token. Un interceptor
 aggiunge automaticamente l'header `Authorization: Bearer <jwt>` quando un token e' presente.

### `final ApiClient`
@brief Crea il client; Dio, TokenStore e DeviceIdStore sono iniettabili (test).
   @param dio Istanza Dio personalizzata (opzionale).
   @param tokenStore Custodia del token personalizzata (opzionale).
   @param deviceIdStore Custodia del device_id personalizzata (opzionale, IIN-14).
  ApiClient({Dio? dio, TokenStore? tokenStore, DeviceIdStore? deviceIdStore})
    : tokenStore = tokenStore ?? TokenStore(),
      deviceIdStore = deviceIdStore ?? DeviceIdStore(),
      dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: kLeafApiBase,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            ),
          ) {
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await this.tokenStore.leggi();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

   @brief Istanza Dio condivisa coi repository.
  final Dio dio;

   @brief Custodia cifrata del token di sessione.
  final TokenStore tokenStore;

   @brief Custodia dell'identificativo stabile del dispositivo (IIN-14).
  final DeviceIdStore deviceIdStore;

   @brief Interceptor di log verboso (modalita' sviluppatore), se attivo.
  
   Tenuto come riferimento per poterlo rimuovere quando la modalita' viene
   disattivata, evitando di accumulare interceptor duplicati.
  Interceptor? _logInterceptor;

   @brief Ripunta il client a un nuovo URL base (es. server LAN in debug).
  
   Usato dalla Modalita' sviluppatore per cambiare endpoint a runtime senza
   ricompilare. Se [base] e' vuoto non modifica nulla.
   @param base Nuovo URL base completo (`http://host:porta/api/v1`).
  void applicaBaseUrl(String base) {
    if (base.trim().isEmpty) return;
    dio.options.baseUrl = base.trim();
  }

   @brief Attiva/disattiva il log verboso delle richieste (debug USB).
  
   Con `flutter run` collegato via USB, il [LogInterceptor] stampa richieste e
   risposte sulla console, utile per diagnosticare i problemi di connettivita'.
   @param attivo True per abilitare il log, False per rimuoverlo.
  void abilitaLogVerboso(bool attivo) {
    if (attivo && _logInterceptor == null) {
      _logInterceptor = LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        logPrint: (Object o) => debugPrint('[LEAF-API] $o'),
      );
      dio.interceptors.add(_logInterceptor!);
    } else if (!attivo && _logInterceptor != null) {
      dio.interceptors.remove(_logInterceptor);
      _logInterceptor = null;
    }
  }

   @brief Converte un errore Dio nell'eccezione applicativa con messaggio di dominio.
   @param errore Errore sollevato da Dio.
   @return Eccezione applicativa leggibile.
  static LeafApiException erroreDa(DioException errore) {
    final dati = errore.response?.data;
    final dettaglio = (dati is Map)
        ? (dati['detail'] ?? dati['dettaglio'] ?? dati['messaggio'])?.toString()
        : null;
    return LeafApiException(
      dettaglio ?? 'Impossibile contattare il servizio. Riprova.',
      codice: errore.response?.statusCode,
    );
  }

   @brief Estrae il payload `dati` dall'inviluppo uniforme della API dati.
  
   Gli endpoint dati rispondono con `{disponibile, messaggio, dati}`: quando il
   servizio è ancora "in sviluppo" (`disponibile == false`) o non porta dati, si
   solleva un'eccezione col messaggio di dominio, così la UI mostra lo stato d'errore.
  
   @param risposta Risposta Dio con corpo a inviluppo.
   @return Mappa del payload `dati`.
   @throws LeafApiException Se il servizio non è disponibile o non ha prodotto dati.
  static Map<String, dynamic> payload(Response<dynamic> risposta) {
    final corpo = risposta.data;
    if (corpo is Map && corpo['disponibile'] == true && corpo['dati'] is Map) {
      return Map<String, dynamic>.from(corpo['dati'] as Map);
    }
    final messaggio = (corpo is Map && corpo['messaggio'] != null)
        ? corpo['messaggio'].toString()
        : 'Servizio non disponibile';
    throw LeafApiException(messaggio, codice: risposta.statusCode);
  }
}

 @brief Istanza condivisa del client API (singleton applicativo).

### File: `api\api_config.dart`

### `const String`
Configurazione dell'endpoint del backend LEAF (Presentation Tier `/api/v1`).

 Il valore di default punta al backend esposto via tunnel Cloudflare sul
 dominio del progetto (`api.leafmobility.org`), raggiungibile da internet.
 Sovrascrivibile a compile-time: `flutter run --dart-define=LEAF_API_BASE=...`
 (es. `http://10.0.2.2:8770/api/v1` per l'emulatore Android in locale).
library;

 @brief Base URL delle API client-facing del backend LEAF Mobility.

### File: `api\assistenza_repository.dart`

### `abstract class`
@brief Contratto della richiesta di assistenza utente (UT.09), iniettabile nei test.

### `class AssistenzaRepository`
@brief Apre una richiesta di assistenza in coda per l'utente autenticato.
   @param oggetto Oggetto sintetico della richiesta.
   @param messaggio Testo della richiesta di supporto.
   @param idCorsa Corsa correlata (opzionale).
   @return Payload con `id_ticket`.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<Map<String, dynamic>> apri(
    String oggetto,
    String messaggio, {
    String? idCorsa,
  });
}

 @brief Implementazione di [AssistenzaApi] su `/api/v1/assistenza` via Dio (Bearer automatico).

### `final AssistenzaRepository`
@brief Crea il repository; il client API è iniettabile nei test.
  AssistenzaRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<Map<String, dynamic>> apri(
    String oggetto,
    String messaggio, {
    String? idCorsa,
  }) async {
    try {
      final risposta = await _client.dio.post<dynamic>(
        '/assistenza',
        data: {
          'oggetto': oggetto,
          'messaggio': messaggio,
          'id_corsa': ?idCorsa,
        },
      );
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

 @brief Repository assistenza condiviso (default reale; sovrascrivibile nei test).

### File: `api\auth_repository.dart`

### `enum StatoAccesso`
@brief Esito di un passo di accesso (IIN-1/9/12).

### `class EsitoAccesso`
Accesso completato: token emesso e custodito.
  ok,

   Richiesto il secondo fattore OTP (OP/AP o UT con MFA, IIN-9).
  mfaRichiesta,

   Richiesto il cambio della password temporanea al primo accesso (IIN-12).
  cambioPasswordRichiesto,
}

 @brief Risultato di `accedi`/`verificaMfa`: stato e dati per il passo successivo.

### `abstract class`
@brief Crea l'esito con lo stato e i campi pertinenti.
  EsitoAccesso(this.stato, {this.idAccount, this.ruolo, this.otpSimulato});

   @brief Stato dell'accesso.
  final StatoAccesso stato;

   @brief Identificativo account (document ID Firestore, stringa) per MFA/cambio password.
  final String? idAccount;

   @brief Ruolo RBAC dell'utente autenticato (a esito `ok`).
  final String? ruolo;

   @brief OTP restituito dal backend in simulazione (provider OTP fittizio, IIN-9).
  final String? otpSimulato;
}

 @brief Contratto di autenticazione verso il backend (iniettabile nei test).

### `class AuthRepository`
@brief Avvia il login con credenziali (IIN-1).
  Future<EsitoAccesso> accedi(
    String identita,
    String password, {
    String? dispositivo,
  });

   @brief Completa il login col secondo fattore OTP (IIN-9).
  Future<EsitoAccesso> verificaMfa(
    String idAccount,
    String otp, {
    String? dispositivo,
  });

   @brief Registra un nuovo utente UT coi dati anagrafici (UT.22.1).
  Future<void> registra(
    String email,
    String username,
    String password, {
    String? dataNascita,
    String? nome,
    String? cognome,
    String? residenza,
  });

   @brief Richiede il reset password via email (IIN-11).
  Future<void> richiediReset(String identita);

   @brief Conferma il reset password con codice monouso e nuova password (IIN-11).
  
   Al successo il backend emette il token di sessione (auto-accesso): il codice
   via email funge da secondo fattore, bypassando l'OTP MFA.
   @param identita Email/username dichiarato.
   @param codice Codice monouso ricevuto via email.
   @param nuovaPassword Nuova password scelta dall'utente (validata IIN-5).
   @return [EsitoAccesso] con stato `ok` e ruolo se il reset è riuscito.
  Future<EsitoAccesso> confermaReset(
    String identita,
    String codice,
    String nuovaPassword,
  );

   @brief Termina la sessione corrente (logout).
  Future<void> esci();
}

 @brief Implementazione di [AuthApi] sul backend `/api/v1/auth` via Dio.

### `final AuthRepository`
@brief Crea il repository; il client API e' iniettabile nei test.
  AuthRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  EsitoAccesso _interpreta(Map<String, dynamic> dati) {
    switch (dati['stato'] as String?) {
      case 'mfa_richiesta':
        return EsitoAccesso(
          StatoAccesso.mfaRichiesta,
          idAccount: dati['id_account']?.toString(),
          otpSimulato: dati['otp_simulato'] as String?,
        );
      case 'cambio_password_richiesto':
        return EsitoAccesso(
          StatoAccesso.cambioPasswordRichiesto,
          idAccount: dati['id_account']?.toString(),
        );
      default:
        return EsitoAccesso(
          StatoAccesso.ok,
          idAccount: dati['id_account']?.toString(),
          ruolo: dati['ruolo'] as String?,
        );
    }
  }

  Future<EsitoAccesso> _accesso(
    Future<Response<dynamic>> Function() chiamata,
  ) async {
    try {
      final risposta = await chiamata();
      final dati = Map<String, dynamic>.from(risposta.data as Map);
      final esito = _interpreta(dati);
      if (esito.stato == StatoAccesso.ok && dati['access_token'] != null) {
        await _client.tokenStore.salva(dati['access_token'] as String);
      }
      return esito;
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<EsitoAccesso> accedi(
    String identita,
    String password, {
    String? dispositivo,
  }) async {
    // IIN-14: il login porta sempre un device_id stabile (limite di 3 dispositivi attivi).
    final device = dispositivo ?? await _client.deviceIdStore.ottieni();
    return _accesso(
      () => _client.dio.post<dynamic>(
        '/auth/login',
        data: {
          'identita': identita,
          'password': password,
          'dispositivo': device,
        },
      ),
    );
  }

  @override
  Future<EsitoAccesso> verificaMfa(
    String idAccount,
    String otp, {
    String? dispositivo,
  }) {
    return _accesso(
      () => _client.dio.post<dynamic>(
        '/auth/mfa',
        data: {
          'id_account': idAccount,
          'otp': otp,
          'dispositivo': ?dispositivo,
        },
      ),
    );
  }

  @override
  Future<void> registra(
    String email,
    String username,
    String password, {
    String? dataNascita,
    String? nome,
    String? cognome,
    String? residenza,
  }) async {
    try {
      await _client.dio.post<dynamic>(
        '/auth/registrazione',
        data: {
          'email': email,
          'username': username,
          'password': password,
          'data_nascita': ?dataNascita,
          'nome': ?nome,
          'cognome': ?cognome,
          'residenza': ?residenza,
        },
      );
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<void> richiediReset(String identita) async {
    try {
      await _client.dio.post<dynamic>(
        '/auth/password/reset',
        data: {'identita': identita},
      );
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<EsitoAccesso> confermaReset(
    String identita,
    String codice,
    String nuovaPassword,
  ) async {
    try {
      final risposta = await _client.dio.post<dynamic>(
        '/auth/password/reset/conferma',
        data: {
          'identita': identita,
          'codice': codice,
          'nuova_password': nuovaPassword,
        },
      );
      final dati = Map<String, dynamic>.from(risposta.data as Map);
      // Il backend restituisce `reimpostata: true/false`. Se true include
      // access_token, id_account e ruolo per l'auto-accesso.
      if (dati['reimpostata'] == true && dati['access_token'] != null) {
        await _client.tokenStore.salva(dati['access_token'] as String);
        return EsitoAccesso(
          StatoAccesso.ok,
          idAccount: dati['id_account']?.toString(),
          ruolo: dati['ruolo'] as String?,
        );
      }
      // Codice errato o scaduto: reimpostata=false (anti-enumerazione).
      return EsitoAccesso(StatoAccesso.mfaRichiesta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<void> esci() async {
    try {
      await _client.dio.post<dynamic>('/auth/logout');
    } on DioException catch (_) {
      // Logout best-effort: anche se la rete fallisce, cancelliamo il token locale.
    }
    await _client.tokenStore.cancella();
  }
}

 @brief Repository di autenticazione condiviso (default reale; sovrascrivibile nei test).

### File: `api\corse_repository.dart`

### `abstract class`
@brief Contratto del ciclo di vita corse e dei documenti collegati (UT.02/04/10/17/25).

### `class CorseRepository`
@brief Prenota un mezzo con blocco esclusivo (UT.02).
   @param idMezzo Identificativo del mezzo da prenotare.
   @param durataMin Durata della riserva in minuti (opzionale, UT.15).
   @return Payload con `id_prenotazione`.
  Future<Map<String, dynamic>> prenota(String idMezzo, {int? durataMin});

   @brief Prenotazioni attive dell'utente, dalla più recente (UT.02/UT.21).
   @return Lista delle prenotazioni attive (documenti grezzi della API).
  Future<List<Map<String, dynamic>>> prenotazioni();

   @brief Annulla una prenotazione attiva e libera il mezzo (UT.12).
   @param idPrenotazione Identificativo della prenotazione da annullare.
   @return Payload con `id_prenotazione`, `id_mezzo`, `annullata`.
  Future<Map<String, dynamic>> annullaPrenotazione(String idPrenotazione);

   @brief Avvia una corsa sbloccando il mezzo (UT.10).
   @param idMezzo Identificativo del mezzo.
   @param idPrenotazione Prenotazione da convertire (opzionale).
   @return Payload con `id_corsa`, `costo_stimato_cent`, `sbloccato`.
  Future<Map<String, dynamic>> avvia(String idMezzo, {String? idPrenotazione});

   @brief Corsa in corso o in pausa dell'utente, per il recupero post-riavvio (UT.10/UT.12).
   @return Documento corsa attiva (con `_id`, `id_mezzo`, `tipo_mezzo`, `stato`), o null.
  Future<Map<String, dynamic>?> corsaAttiva();

   @brief Conclude una corsa: costo finale, addebito e fattura (UT.04/UT.25).
   @param idCorsa Identificativo della corsa.
   @param km Chilometri percorsi (IIN-24).
   @param lat Latitudine GPS di chiusura (opzionale, OP.05/OP.04).
   @param lon Longitudine GPS di chiusura (opzionale, OP.05/OP.04).
   @return Payload con `costo_finale_cent`, `id_pagamento`, `id_fattura`, `fuori_area_operativa`.
  Future<Map<String, dynamic>> termina(
    String idCorsa, {
    double km = 0.0,
    double? lat,
    double? lon,
  });

   @brief Stima preventiva del costo di una corsa prima di confermare (UT.03).
   @param idMezzo Identificativo del mezzo selezionato.
   @param durataMin Durata stimata in minuti (opzionale).
   @return Payload con `costo_stimato_cent`.
  Future<Map<String, dynamic>> stima(String idMezzo, {int? durataMin});

   @brief Mette in pausa una corsa mantenendo il mezzo bloccato (UT.12).
   @param idCorsa Identificativo della corsa.
   @return Payload con `id_corsa`, `stato`.
  Future<Map<String, dynamic>> pausa(String idCorsa);

   @brief Riprende una corsa precedentemente messa in pausa (UT.12).
   @param idCorsa Identificativo della corsa.
   @return Payload con `id_corsa`, `stato`.
  Future<Map<String, dynamic>> riprendi(String idCorsa);

   @brief Registra la valutazione a stelle di una corsa conclusa (UT.16).
   @param idCorsa Identificativo della corsa.
   @param stelle Valutazione da 1 a 5.
   @return Payload con `id_corsa`, `valutazione`.
  Future<Map<String, dynamic>> valuta(String idCorsa, int stelle);

   @brief Storico delle corse dell'utente, dalla più recente (UT.17).
   @return Lista delle corse passate (documenti grezzi).
  Future<List<Map<String, dynamic>>> storico();

   @brief Elenco delle fatture dell'utente (UT.25).
   @return Lista delle fatture (documenti grezzi).
  Future<List<Map<String, dynamic>>> fatture();
}

 @brief Implementazione di [CorseApi] su `/api/v1` via Dio (Bearer automatico).

### `final CorseRepository`
@brief Crea il repository; il client API è iniettabile nei test.
  CorseRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<Map<String, dynamic>> prenota(String idMezzo, {int? durataMin}) {
    return _postDati('/prenotazioni', {
      'id_mezzo': idMezzo,
      'durata_min': ?durataMin,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> prenotazioni() {
    return _elenco('/prenotazioni', 'prenotazioni');
  }

  @override
  Future<Map<String, dynamic>> annullaPrenotazione(String idPrenotazione) {
    return _postDati('/prenotazioni/$idPrenotazione/annulla', const {});
  }

  @override
  Future<Map<String, dynamic>> avvia(String idMezzo, {String? idPrenotazione}) {
    return _postDati('/corse', {
      'id_mezzo': idMezzo,
      'id_prenotazione': ?idPrenotazione,
    });
  }

  @override
  Future<Map<String, dynamic>?> corsaAttiva() async {
    try {
      final risposta = await _client.dio.get<dynamic>('/corse/attiva');
      final dati = ApiClient.payload(risposta);
      final corsa = dati['corsa'];
      return corsa is Map ? Map<String, dynamic>.from(corsa) : null;
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<Map<String, dynamic>> termina(
    String idCorsa, {
    double km = 0.0,
    double? lat,
    double? lon,
  }) {
    return _postDati('/corse/$idCorsa/termina', {'km': km, 'lat': ?lat, 'lon': ?lon});
  }

  @override
  Future<Map<String, dynamic>> stima(String idMezzo, {int? durataMin}) {
    return _postDati('/corse/stima', {
      'id_mezzo': idMezzo,
      'durata_min': ?durataMin,
    });
  }

  @override
  Future<Map<String, dynamic>> pausa(String idCorsa) {
    return _postDati('/corse/$idCorsa/pausa', const {});
  }

  @override
  Future<Map<String, dynamic>> riprendi(String idCorsa) {
    return _postDati('/corse/$idCorsa/riprendi', const {});
  }

  @override
  Future<Map<String, dynamic>> valuta(String idCorsa, int stelle) {
    return _postDati('/corse/$idCorsa/valutazione', {'stelle': stelle});
  }

  @override
  Future<List<Map<String, dynamic>>> storico() {
    return _elenco('/corse', 'corse');
  }

  @override
  Future<List<Map<String, dynamic>>> fatture() {
    return _elenco('/fatture', 'fatture');
  }

   @brief POST che restituisce il solo payload `dati` dell'inviluppo.
  Future<Map<String, dynamic>> _postDati(
    String percorso,
    Map<String, dynamic> corpo,
  ) async {
    try {
      final risposta = await _client.dio.post<dynamic>(percorso, data: corpo);
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

   @brief GET che estrae una lista nominata dal payload `dati`.
  Future<List<Map<String, dynamic>>> _elenco(
    String percorso,
    String chiave,
  ) async {
    try {
      final risposta = await _client.dio.get<dynamic>(percorso);
      final dati = ApiClient.payload(risposta);
      final elementi = (dati[chiave] as List?) ?? const [];
      return elementi
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

 @brief Repository corse condiviso (default reale; sovrascrivibile nei test).

### File: `api\notifiche_repository.dart`

### `abstract class`
@brief Contratto delle notifiche utente (UT.15/UT.19, IIN-19), iniettabile nei test.

### `class NotificheRepository`
@brief Elenca le notifiche dell'utente autenticato e i broadcast.
   @param soloNonLette Se true restituisce solo le notifiche non lette.
   @return Lista di notifiche (documenti grezzi della API), dalla più recente.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> elenco({bool soloNonLette = false});

   @brief Marca una notifica come letta.
   @param idNotifica Id della notifica.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<void> segnaLetta(String idNotifica);
}

 @brief Implementazione di [NotificheApi] su `/api/v1/notifiche` via Dio (Bearer automatico).

### `final NotificheRepository`
@brief Crea il repository; il client API è iniettabile nei test.
  NotificheRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<List<Map<String, dynamic>>> elenco({bool soloNonLette = false}) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/notifiche',
        queryParameters: {'solo_non_lette': soloNonLette},
      );
      final dati = ApiClient.payload(risposta);
      final notifiche = (dati['notifiche'] as List?) ?? const [];
      return notifiche
          .map((n) => Map<String, dynamic>.from(n as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<void> segnaLetta(String idNotifica) async {
    try {
      await _client.dio.post<dynamic>('/notifiche/$idNotifica/letta');
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

 @brief Repository notifiche condiviso (default reale; sovrascrivibile nei test).

### File: `api\profilo_repository.dart`

### `abstract class`
@brief Contratto di accesso al profilo utente (UT.21), iniettabile nei test.

### `class ProfiloRepository`
@brief Recupera i dati del profilo dell'utente autenticato.
   @return Vista profilo (mai contenente la password hash).
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<Map<String, dynamic>> profilo();

   @brief Aggiorna i dati anagrafici del profilo (whitelist server-side).
   @param modifiche Coppie campo→valore da aggiornare (nome, cognome, telefono, …).
   @return Vista profilo aggiornata.
   @throws LeafApiException Su errore di rete o conflitto.
  Future<Map<String, dynamic>> aggiorna(Map<String, dynamic> modifiche);

   @brief Registra un metodo di pagamento verificato (UT.11).
  
   Il PAN viene inviato al backend per la verifica ma **non è mai persistito
   in chiaro lato client**: il server restituisce solo il numero mascherato.
   @param numero Numero della carta (solo cifre, 12–23).
   @param mese Mese di scadenza (1–12).
   @param anno Anno di scadenza (≥ 2024).
   @param titolare Intestatario della carta.
   @param cvv Codice di sicurezza a 3 cifre (verificato, mai persistito — PCI).
   @param indirizzoFatturazione Via di fatturazione; deve coincidere con la residenza.
   @return Payload con `id_metodo`, `pan_mascherato`.
   @throws LeafApiException Su errore di rete o carta non valida.
  Future<Map<String, dynamic>> registraPagamento({
    required String numero,
    required int mese,
    required int anno,
    required String titolare,
    required String cvv,
    required String indirizzoFatturazione,
  });

   @brief Sottoscrive un piano di abbonamento periodico (UT.18).
   @param idPiano Identificativo del piano scelto (deve esistere sul backend).
   @return Payload con `id_abbonamento`, `id_piano`, `data_fine`.
   @throws LeafApiException Su errore di rete o piano inesistente.
  Future<Map<String, dynamic>> sottoscriviAbbonamento(String idPiano);

   @brief Elenca gli abbonamenti dell'utente, dal più recente (UT.18/UT.21).
   @return Lista degli abbonamenti (`id_piano`, `stato`, `data_inizio/fine`, `prezzo_cent`).
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> abbonamenti();

   @brief Carica un documento KYC (solo PDF/JPG/PNG, UT.22.2, IIN-6).
  
   Invia tipo e nome del file: l'estensione è validata server-side
   (AG-SEC-01); i byte del documento restano sul dispositivo.
   @param tipo Tipo di documento (`patente` o `carta_identita`).
   @param nomeFile Nome del file con estensione ammessa.
   @return Payload con `id_documento`, `stato_verifica`.
   @throws LeafApiException Su errore di rete o formato/tipo non ammessi.
  Future<Map<String, dynamic>> caricaKyc({
    required String tipo,
    required String nomeFile,
  });
}

 @brief Implementazione di [ProfiloApi] su `/api/v1/profilo` via Dio (Bearer automatico).

### `final ProfiloRepository`
@brief Crea il repository; il client API è iniettabile nei test.
  ProfiloRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<Map<String, dynamic>> profilo() async {
    try {
      final risposta = await _client.dio.get<dynamic>('/profilo');
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<Map<String, dynamic>> aggiorna(Map<String, dynamic> modifiche) async {
    try {
      final risposta = await _client.dio.put<dynamic>(
        '/profilo',
        data: modifiche,
      );
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<Map<String, dynamic>> registraPagamento({
    required String numero,
    required int mese,
    required int anno,
    required String titolare,
    required String cvv,
    required String indirizzoFatturazione,
  }) {
    return _postDati('/profilo/pagamenti', {
      'numero': numero,
      'mese': mese,
      'anno': anno,
      'titolare': titolare,
      'cvv': cvv,
      'indirizzo_fatturazione': indirizzoFatturazione,
    });
  }

  @override
  Future<Map<String, dynamic>> sottoscriviAbbonamento(String idPiano) {
    return _postDati('/profilo/abbonamenti', {'id_piano': idPiano});
  }

  @override
  Future<List<Map<String, dynamic>>> abbonamenti() async {
    try {
      final risposta = await _client.dio.get<dynamic>('/profilo/abbonamenti');
      final dati = ApiClient.payload(risposta);
      final elenco = (dati['abbonamenti'] as List?) ?? const [];
      return elenco
          .map((a) => Map<String, dynamic>.from(a as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<Map<String, dynamic>> caricaKyc({
    required String tipo,
    required String nomeFile,
  }) {
    return _postDati('/profilo/kyc', {'tipo': tipo, 'nome_file': nomeFile});
  }

   @brief POST che restituisce il solo payload `dati` dell'inviluppo.
   @param percorso Percorso relativo dell'endpoint.
   @param corpo Corpo JSON della richiesta.
   @return Mappa del payload `dati`.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<Map<String, dynamic>> _postDati(
    String percorso,
    Map<String, dynamic> corpo,
  ) async {
    try {
      final risposta = await _client.dio.post<dynamic>(percorso, data: corpo);
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

 @brief Repository profilo condiviso (default reale; sovrascrivibile nei test).

### File: `api\routing_repository.dart`

### `class LuogoSuggerito`
@brief Suggerimento di luogo (autocompletamento) dal gazetteer del server (UT.07).

### `abstract class`
@brief Crea il suggerimento di luogo.
   @param nome Nome canonico del luogo.
   @param lat Latitudine del luogo (gradi decimali).
   @param lon Longitudine del luogo (gradi decimali).
  const LuogoSuggerito({
    required this.nome,
    required this.lat,
    required this.lon,
  });

   Nome canonico del luogo mostrato nei suggerimenti.
  final String nome;

   Latitudine del luogo (gradi decimali, WGS84).
  final double lat;

   Longitudine del luogo (gradi decimali, WGS84).
  final double lon;

   @brief Costruisce il suggerimento da un elemento `luoghi` della API.
   @param mappa Elemento grezzo `{nome, lat, lon}` del payload `/geocoding`.
   @return Il modello di vista del suggerimento.
  factory LuogoSuggerito.daApi(Map<String, dynamic> mappa) => LuogoSuggerito(
    nome: '${mappa['nome'] ?? ''}',
    lat: ((mappa['lat'] ?? 0) as num).toDouble(),
    lon: ((mappa['lon'] ?? 0) as num).toDouble(),
  );
}

 @brief Contratto di ricerca percorsi e geocoding (UT.07/UT.08), iniettabile nei test.

### `class RoutingRepository`
@brief Suggerimenti di luogo per l'autocompletamento (gazetteer server).
   @param query Testo parziale digitato dall'utente.
   @return Elenco di luoghi suggeriti (vuoto se la query è vuota).
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<LuogoSuggerito>> suggerisci(String query);

   @brief Opzioni di percorso multimodali tra due luoghi (per nome o coordinate).
   @param da Nome del luogo di partenza (geocodificato dal server).
   @param a Nome del luogo di arrivo (geocodificato dal server).
   @param daLat Latitudine di partenza, che prevale su [da] (es. posizione corrente).
   @param daLon Longitudine di partenza, che prevale su [da].
   @param aLat Latitudine di arrivo, che prevale su [a].
   @param aLon Longitudine di arrivo, che prevale su [a].
   @return Payload `{origine, destinazione, percorsi, totale}`.
   @throws LeafApiException Se un luogo non è riconosciuto o su errore di rete.
  Future<Map<String, dynamic>> percorsi({
    String? da,
    String? a,
    double? daLat,
    double? daLon,
    double? aLat,
    double? aLon,
  });
}

 @brief Implementazione di [RoutingApi] su `/api/v1/geocoding` e `/api/v1/percorsi` via Dio.

### `final RoutingRepository`
@brief Crea il repository; il client API è iniettabile nei test.
  RoutingRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<List<LuogoSuggerito>> suggerisci(String query) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/geocoding',
        queryParameters: {'q': query},
      );
      final dati = ApiClient.payload(risposta);
      final luoghi = (dati['luoghi'] as List?) ?? const [];
      return luoghi
          .map((e) => LuogoSuggerito.daApi(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<Map<String, dynamic>> percorsi({
    String? da,
    String? a,
    double? daLat,
    double? daLon,
    double? aLat,
    double? aLon,
  }) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/percorsi',
        queryParameters: {
          'da': ?da,
          'a': ?a,
          'da_lat': ?daLat,
          'da_lon': ?daLon,
          'a_lat': ?aLat,
          'a_lon': ?aLon,
        },
      );
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

 @brief Repository di routing condiviso (default reale; sovrascrivibile nei test).

### File: `api\sos_repository.dart`

### `abstract class`
@brief Contratto della segnalazione di emergenza SOS (UT.20, IIN-18), iniettabile nei test.

### `class SosRepository`
@brief Inoltra una segnalazione SOS con la posizione GPS corrente.
   @param lat Latitudine rilevata.
   @param lon Longitudine rilevata.
   @param idCorsa Corsa in atto correlata (opzionale).
   @return Payload con `id_segnalazione`/`stato`.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<Map<String, dynamic>> segnala({
    required double lat,
    required double lon,
    String? idCorsa,
  });
}

 @brief Implementazione di [SosApi] su `/api/v1/sos` via Dio (Bearer automatico).

### `final SosRepository`
@brief Crea il repository; il client API è iniettabile nei test.
  SosRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<Map<String, dynamic>> segnala({
    required double lat,
    required double lon,
    String? idCorsa,
  }) async {
    try {
      final risposta = await _client.dio.post<dynamic>(
        '/sos',
        data: {'lat': lat, 'lon': lon, 'id_corsa': ?idCorsa},
      );
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

 @brief Repository SOS condiviso (default reale; sovrascrivibile nei test).

### File: `api\veicoli_repository.dart`

### `abstract class`
@brief Contratto di accesso ai veicoli/mappa (UT.01/UT.05), iniettabile nei test.

### `class VeicoliRepository`
@brief Elenca i mezzi disponibili, opzionalmente nei pressi di un punto.
   @param lat Latitudine del centro di ricerca (opzionale).
   @param lon Longitudine del centro di ricerca (opzionale).
   @return Lista dei mezzi disponibili (documenti grezzi della API).
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> disponibili({double? lat, double? lon});

   @brief Elenca le stazioni di ricarica attive sulla mappa (UT.14).
   @return Lista delle stazioni (`_id`, `nome`, `lat`, `lon`, `num_colonnine`…).
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> stazioni();
}

 @brief Implementazione di [VeicoliApi] su `/api/v1/veicoli` via Dio.

### `final VeicoliRepository`
@brief Crea il repository; il client API è iniettabile nei test.
  VeicoliRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<List<Map<String, dynamic>>> disponibili({
    double? lat,
    double? lon,
  }) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/veicoli',
        queryParameters: {'lat': ?lat, 'lon': ?lon},
      );
      final dati = ApiClient.payload(risposta);
      final mezzi = (dati['mezzi'] as List?) ?? const [];
      return mezzi
          .map((m) => Map<String, dynamic>.from(m as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> stazioni() async {
    try {
      final risposta = await _client.dio.get<dynamic>('/stazioni');
      final dati = ApiClient.payload(risposta);
      final elenco = (dati['stazioni'] as List?) ?? const [];
      return elenco
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

 @brief Repository veicoli condiviso (default reale; sovrascrivibile nei test).

### File: `screens\account_screen.dart`

### `class AccountScreen`
@brief Schermata dei dati anagrafici dell'utente, visualizzabili e
        modificabili. UT.21.

 Ogni campo e' di sola lettura finche' non si tocca la matita di fianco, che
 lo abilita singolarmente alla modifica. La foto profilo puo' essere caricata
 da galleria o fotocamera e resta **locale** sul dispositivo
 ([ProfileStore]). Le modifiche sono persistite localmente al salvataggio.

### `class _AccountScreenState`
Repository profilo iniettabile (default reale; fittizio nei test).
  final ProfiloApi? _profilo;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

### File: `screens\booking_screen.dart`

### `class BookingScreen`
@brief Schermata di prenotazione di un mezzo. UT.02.

 Consente di scegliere la durata della riserva, mostra il costo stimato in
 base alla tariffa del veicolo e conferma la prenotazione. Quando il mezzo
 porta un `docId` reale (proveniente dalla API), la prenotazione è inviata al
 backend via [CorseApi.prenota]; in ogni caso viene registrata nello
 [bookingStore] per la vista "Mie Prenotazioni". UT.03 (stima costo), UT.02.

### `class _BookingScreenState`
Veicolo da prenotare.
  final VehicleData vehicle;

  const BookingScreen({required this.vehicle, super.key, CorseApi? corse})
    : _corse = corse;

   Repository corse iniettabile (default reale; fittizio nei test).
  final CorseApi? _corse;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

### `class _SectionLabel`
Opzioni di durata della riserva (in minuti).
  static const List<int> _durations = [15, 30, 45, 60];

   Durata selezionata, in minuti.
  int _selectedMinutes = 15;

   Repository risolto: quello iniettato (test) o il singleton reale.
  late final CorseApi _corse = widget._corse ?? corseRepository;

   Prenotazione in corso verso il backend (disabilita il pulsante).
  bool _invio = false;

   Costo stimato reale dal backend (centesimi), o null se non disponibile.
  int? _costoStimatoCent;

   Stima dettagliata dal backend (sblocco/corsa/totale + stato abbonamento),
   o null in fallback locale/offline (punto 8).
  Map<String, dynamic>? _stima;

  @override
  void initState() {
    super.initState();
    _aggiornaStima();
  }

   Richiede al backend la stima reale del costo per la durata scelta (UT.03).
  
   Disponibile solo per i mezzi con `docId` reale; in assenza di rete o di
   `docId` la vista ricade sul calcolo locale per-tariffa (fallback, IIN-6).
  Future<void> _aggiornaStima() async {
    final docId = widget.vehicle.docId;
    if (docId == null || docId.isEmpty) return;
    final durata = _selectedMinutes;
    try {
      final esito = await _corse.stima(docId, durataMin: durata);
      if (!mounted || durata != _selectedMinutes) return;
      setState(() {
        _stima = esito;
        _costoStimatoCent = (esito['costo_stimato_cent'] as num?)?.toInt();
      });
    } on LeafApiException {
      if (!mounted) return;
      setState(() {
        _stima = null;
        _costoStimatoCent = null; // fallback alla stima locale
      });
    }
  }

   Tariffa al minuto del veicolo, in euro.
  double get _ratePerMinute {
    switch (widget.vehicle.type) {
      case VehicleType.scooter:
        return 0.25;
      case VehicleType.bike:
        return 0.15;
      case VehicleType.car:
        return 0.45;
      case VehicleType.emoto:
        return 0.30;
    }
  }

   Costo stimato locale per la durata selezionata (fallback). UT.03.
  double get _estimatedCost => _ratePerMinute * _selectedMinutes;

   Costo da mostrare: stima reale del backend se disponibile, altrimenti locale.
  double get _costoVisuale =>
      _costoStimatoCent != null ? _costoStimatoCent! / 100.0 : _estimatedCost;

   Registra la prenotazione e apre l'elenco "Mie Prenotazioni". UT.02/UT.15.
  
   Per i mezzi con `docId` reale la prenotazione è inviata al backend con la
   durata scelta (blocco esclusivo + scadenza lato server): è quella la fonte
   di verità, perciò NON viene duplicata localmente. Per i mezzi di riserva
   offline (senza `docId`) si registra una prenotazione locale dimostrativa.
  Future<void> _confirm() async {
    if (_invio) return;
    final docId = widget.vehicle.docId;
    if (docId != null && docId.isNotEmpty) {
      setState(() => _invio = true);
      try {
        await _corse.prenota(docId, durataMin: _selectedMinutes);
      } on LeafApiException catch (e) {
        if (!mounted) return;
        setState(() => _invio = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.messaggio),
            backgroundColor: const Color(0xFFC62828),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }
    } else {
      // Mezzo di riserva offline (senza docId): prenotazione locale dimostrativa.
      addBooking(
        Booking(
          vehicleId: widget.vehicle.id,
          vehicleTypeLabel: widget.vehicle.typeLabel,
          vehicleType: widget.vehicle.type,
          createdAt: DateTime.now(),
          durationMinutes: _selectedMinutes,
          estimatedCost: _costoVisuale,
        ),
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('Prenotazione confermata')),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MyBookingsScreen(corse: _corse)),
    );
  }

   Contenitore del riquadro costo (sfondo coerente con le altre schermate).
  Widget _boxCosto(Widget child) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    decoration: BoxDecoration(
      color: AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(14),
    ),
    child: child,
  );

   Riga "etichetta — valore" del riquadro costo (forte = voce totale).
  Widget _rigaCosto(String label, String valore, {required bool forte}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: forte ? 15 : 13,
            fontWeight: forte ? FontWeight.bold : FontWeight.normal,
            color: forte ? AppTheme.darkGreen : AppTheme.textDark,
          ),
        ),
        Text(
          valore,
          style: TextStyle(
            fontSize: forte ? 18 : 14,
            fontWeight: forte ? FontWeight.bold : FontWeight.w600,
            color: forte ? AppTheme.darkGreen : AppTheme.textDark,
          ),
        ),
      ],
    );
  }

   Riquadro costo (punto 8): con abbonamento mostra % usata + token (sblocco
   gratis, corsa coperta); senza abbonamento mostra sblocco + corsa + totale
   separati; in fallback offline la stima locale per-tariffa.
  Widget _buildCosto() {
    final stima = _stima;
    if (stima != null && stima['ha_abbonamento'] == true) {
      final inclusi = (stima['token_inclusi'] as num?)?.toInt() ?? 0;
      final residui = (stima['token_residui'] as num?)?.toInt() ?? 0;
      final pct = (stima['percentuale_usata'] as num?)?.toInt() ?? 0;
      return _boxCosto(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _rigaCosto(tr('Sblocco'), tr('Gratuito'), forte: false),
            const SizedBox(height: 6),
            _rigaCosto(tr('Corsa'), tr('Coperta da abbonamento'), forte: false),
            const Divider(height: 20),
            _rigaCosto(tr('Abbonamento utilizzato'), '$pct%', forte: true),
            const SizedBox(height: 4),
            Text(
              '${tr('Token residui')}: $residui / $inclusi',
              style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
            ),
          ],
        ),
      );
    }
    if (stima != null) {
      final sblocco = ((stima['sblocco_cent'] as num?)?.toInt() ?? 0) / 100.0;
      final corsa = ((stima['corsa_cent'] as num?)?.toInt() ?? 0) / 100.0;
      final totale = ((stima['totale_cent'] as num?)?.toInt() ?? 0) / 100.0;
      return _boxCosto(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _rigaCosto(
              tr('Sblocco'),
              '${sblocco.toStringAsFixed(2)} €',
              forte: false,
            ),
            const SizedBox(height: 6),
            _rigaCosto(
              '${tr('Corsa')} ($_selectedMinutes ${tr('min')})',
              '${corsa.toStringAsFixed(2)} €',
              forte: false,
            ),
            const Divider(height: 20),
            _rigaCosto(
              tr('Totale'),
              '${totale.toStringAsFixed(2)} €',
              forte: true,
            ),
          ],
        ),
      );
    }
    return _boxCosto(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${_ratePerMinute.toStringAsFixed(2)} ${tr('€/min')} × $_selectedMinutes ${tr('min')}',
              style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
            ),
          ),
          Text(
            '${_costoVisuale.toStringAsFixed(2)} €',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGreen,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.vehicle.typeColor;
    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        title: Text(tr('Prenota mezzo')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Vehicle summary ──────────────────────────────────────────
            Card(
              elevation: 0,
              color: color.withAlpha(18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
                    Icon(widget.vehicle.typeIcon, size: 64, color: color),
                    const SizedBox(height: 10),
                    Text(
                      widget.vehicle.typeLabel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.vehicle.id,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textGrey,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Duration selection ───────────────────────────────────────
            _SectionLabel(tr('Durata prenotazione')),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _durations.map((m) {
                final selected = m == _selectedMinutes;
                return ChoiceChip(
                  label: Text('$m ${tr('min')}'),
                  selected: selected,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppTheme.textDark,
                  ),
                  backgroundColor: Colors.white,
                  selectedColor: AppTheme.primaryGreen,
                  side: BorderSide(
                    color: selected ? AppTheme.primaryGreen : Colors.black12,
                  ),
                  onSelected: (_) {
                    setState(() => _selectedMinutes = m);
                    _aggiornaStima();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Cost estimate (UT.03, punto 8) ───────────────────────────
            _SectionLabel(tr('Costo stimato')),
            const SizedBox(height: 10),
            _buildCosto(),
            const SizedBox(height: 8),
            Text(
              tr(
                'La prenotazione mantiene il mezzo riservato fino allo scadere del tempo.',
              ),
              style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
            ),
            const SizedBox(height: 32),

            // ── Confirm ──────────────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: _invio ? null : _confirm,
              icon: _invio
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(tr('Conferma prenotazione')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

 Etichetta di sezione in maiuscoletto, coerente con le altre schermate.

### File: `screens\booking_tab.dart`

### `class BookingTab`
@brief Tab "Prenota": punto d'accesso alla prenotazione dei mezzi. UT.02.

 Sostituisce il vecchio segnaposto "Servizio non disponibile": elenca i mezzi
 disponibili nei dintorni e, al tap, apre la [BookingScreen] del veicolo
 scelto. In testa offre una scorciatoia a "Mie Prenotazioni". Si ridisegna al
 cambio lingua tramite [Translated]. IIN-7.

### `class _BookingsShortcut`
Scorciatoia in evidenza verso l'elenco delle prenotazioni attive.

### `class _BookableVehicleTile`
Riga di un veicolo prenotabile: icona, tipo, batteria/autonomia e azione.

### File: `screens\buy_subscription_screen.dart`

### `class PianoAbbonamento`
@brief Descrittore di un piano di abbonamento mostrato all'utente (UT.18).

 L'`idPiano` corrisponde all'identificativo reale del piano sul backend
 (`piani_abbonamento`): è il valore inviato a `POST /profilo/abbonamenti`.
 Il catalogo è definito lato client in attesa di un endpoint `GET /piani`
 (integration backlog §17).

### `const List`
@brief Crea il descrittore di un piano.
  const PianoAbbonamento({
    required this.idPiano,
    required this.titolo,
    required this.prezzo,
    required this.durata,
    required this.caratteristiche,
    required this.colore,
    this.isPremium = false,
  });

   Identificativo del piano sul backend (es. `piano-base`).
  final String idPiano;

   Nome commerciale del piano.
  final String titolo;

   Prezzo formattato per la UI (es. `9,99 €`).
  final String prezzo;

   Durata leggibile del piano (es. `30 giorni`).
  final String durata;

   Vantaggi inclusi nel piano.
  final List<String> caratteristiche;

   Colore di accento della card.
  final Color colore;

   Indica il piano in evidenza (bordo/elevazione enfatizzati).
  final bool isPremium;
}

 @brief Catalogo dei piani allineato agli id reali del seed backend (UT.18).

### `class BuySubscriptionScreen`
@brief Schermata di acquisto abbonamento: sottoscrive un piano reale (UT.18).

 Mostra il catalogo [kPianiAbbonamento] e invia la sottoscrizione al backend
 (`POST /profilo/abbonamenti`) tramite [ProfiloApi], iniettabile nei test.

### `class _BuySubscriptionScreenState`
@brief Crea la schermata; il repository profilo è iniettabile nei test.
  const BuySubscriptionScreen({super.key, ProfiloApi? profilo})
    : _profilo = profilo;

  final ProfiloApi? _profilo;

  @override
  State<BuySubscriptionScreen> createState() => _BuySubscriptionScreenState();
}

### File: `screens\dev_mode_screen.dart`

### `class DevModeScreen`
@brief Pannello "Modalità sviluppatore" per il debug di connettività.

 Strumento interno (non destinato all'utente finale) che consente di:
   - puntare l'app a un server diverso da quello di produzione, tipicamente
     un'istanza in LAN (`http://192.168.x.x:8770/api/v1`) per il debug USB;
   - verificare la raggiungibilità del server con un test di connessione
     (`GET /salute`) che misura la latenza e mostra l'esito;
   - abilitare un log di rete verboso visibile su `flutter run` (USB).

 Le scelte sono persistite da [DevSettings] e applicate al [apiClient] a caldo.

### File: `screens\faq_screen.dart`

### `class _Faq`
@brief Coppia domanda/risposta delle FAQ (chiavi in italiano, tradotte a UI).

### `const List`
Chiave della domanda (lingua sorgente italiana, tradotta via [tr]).
  final String question;

   Chiave della risposta (lingua sorgente italiana, tradotta via [tr]).
  final String answer;

  const _Faq(this.question, this.answer);
}

 Elenco delle domande più comuni. Le stringhe sono chiavi tradotte in [tr].

### `class FaqScreen`
@brief Schermata FAQ dedicata: barra di ricerca + domande più comuni. UT.09.

 Filtra in tempo reale le domande e le risposte in base al testo digitato e
 mostra l'elenco come pannelli espandibili. Si ritraduce live al cambio
 lingua tramite [Translated]. IIN-7.

### `class _FaqTile`
Controller della barra di ricerca.
  final TextEditingController _searchController = TextEditingController();

   Testo di ricerca corrente (minuscolo) usato per filtrare le FAQ.
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

   FAQ che soddisfano la ricerca corrente (su domanda e risposta tradotte).
  List<_Faq> get _filtered {
    if (_query.isEmpty) return _kFaqs;
    return _kFaqs.where((f) {
      final q = tr(f.question).toLowerCase();
      final a = tr(f.answer).toLowerCase();
      return q.contains(_query) || a.contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      final results = _filtered;
      return Scaffold(
        backgroundColor: AppTheme.backgroundBeige,
        appBar: AppBar(
          title: Text(
            tr('Domande frequenti'),
            style: const TextStyle(color: AppTheme.darkGreen),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // ── Barra di ricerca ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: tr('Cerca una risposta…'),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.textGrey,
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: AppTheme.textGrey,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.primaryGreen),
                  ),
                ),
              ),
            ),
            // ── Elenco / stato vuoto ───────────────────────────────────────
            Expanded(
              child: results.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _query.isEmpty
                                ? tr('Domande più comuni')
                                : '${results.length} ${tr('risultati')}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textGrey,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                        ...results.map(
                          (f) => _FaqTile(
                            question: tr(f.question),
                            answer: tr(f.answer),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      );
    });
  }

   Stato vuoto mostrato quando la ricerca non produce risultati.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.help_outline, size: 64, color: AppTheme.textGrey),
            const SizedBox(height: 16),
            Text(
              tr('Nessuna risposta trovata'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textGrey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tr('Prova con altre parole o contatta il supporto.'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
            ),
          ],
        ),
      ),
    );
  }
}

 Pannello FAQ espandibile (domanda/risposta).

### File: `screens\history_screen.dart`

### `class TripEntry`
A single trip entry in the history. UT.17.

### `enum _SortField`
@brief Costruisce una voce di cronologia da un documento corsa della API (UT.17).
  
   Mappa i campi del documento `corse` (snake_case lato server) sul modello di
   vista. Il documento corsa non porta i nomi di partenza/arrivo (il modello
   dati non li registra): si usa il codice del mezzo come riferimento e l'arrivo
   resta non disponibile ('—'). Importi in centesimi → euro; tipo mezzo
   normalizzato sulle etichette già usate dalla UI.
  
   @param doc Documento corsa grezzo restituito da `/api/v1/corse`.
   @param progressivo Identificativo progressivo assegnato per l'ordinamento.
   @return La voce [TripEntry] corrispondente.
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

   @brief Normalizza il discriminante `tipo_mezzo` del server sull'etichetta UI.
   @param tipo Tipo mezzo lato server (ebike/monopattino/ecar/emotorbike).
   @return Etichetta coerente con le icone di [_TripTile] (E-Bike/Auto/E-Moto/Scooter).
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

   Progressivo numerico ricavato dall'id (es. '#0010' -> 10).
  
   Le corse sono registrate in ordine cronologico crescente di id, quindi
   questo valore funge da chiave di ordinamento affidabile per data/ora.
  int get sequence => int.tryParse(id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
}

 @brief Converte i documenti corsa della API in voci di cronologia ordinabili.

 La API restituisce le corse dalla più recente; si assegna un progressivo
 decrescente così che [TripEntry.sequence] rifletta l'ordine cronologico
 (valore più alto = corsa più recente), coerente con l'ordinamento "Data".

 @param corse Lista di documenti corsa grezzi da `/api/v1/corse`.
 @return Lista di [TripEntry] pronte per la vista.
List<TripEntry> corseInVoci(List<Map<String, dynamic>> corse) {
  final totale = corse.length;
  return [
    for (var i = 0; i < totale; i++)
      TripEntry.daApi(corse[i], progressivo: totale - i),
  ];
}

 Criteri di ordinamento disponibili per la cronologia delle corse. UT.17.

### `class HistoryScreen`
Trip history screen — UT.17 (storico corse: tragitti e spese).

 Connected with the home tab history section and drawer Cronologia item.
 Permette di consultare le corse ordinandole secondo diversi criteri
 (data, durata, distanza, costo) in ordine crescente o decrescente.

### `class _HistoryScreenState`
Repository corse iniettabile (default reale; fittizio nei test).
  final CorseApi? _corse;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

### `class _SummaryChip`
Criterio di ordinamento corrente.
  _SortField _sortField = _SortField.data;

   Ordine decrescente (più recente / più alto prima) quando true.
  bool _descending = true;

   Repository risolto: quello iniettato (test) o il singleton reale.
  late final CorseApi _corse = widget._corse ?? corseRepository;

   Etichetta localizzata associata a un criterio di ordinamento.
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

   Ordina una lista di corse secondo criterio e direzione correnti.
   @param trips Lista di partenza (non modificata).
   @return Nuova lista ordinata.
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

   Corpo della schermata a dati disponibili: riepilogo, ordinamento e lista.
   @param caricate Corse caricate dalla API (non ancora ordinate).
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

   Barra di selezione del criterio di ordinamento (chip orizzontali).
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

### File: `screens\home_tab.dart`

### `class HomeTab`
Home tab — search, history, available vehicles. UT.03, UT.05, UT.07.

### `class _HomeTabState`
Callback invocata dalla card "+" quando la cronologia è vuota: porta
   l'utente alla mappa per scegliere un mezzo e avviare una nuova corsa (UT.10).
  final VoidCallback? onNuovaCorsa;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

### `class _DualSearchCard`
Mezzi reali caricati dalla API; null fino al caricamento o in fallback.
  List<VehicleData>? _veicoliApi;

   Cronologia reale caricata dalla API; null fino al caricamento o in fallback.
  List<TripEntry>? _storicoApi;

  @override
  void initState() {
    super.initState();
    _caricaVeicoli();
    _caricaStorico();
  }

   Carica i mezzi disponibili dalla API (fallback ai dati di riserva, IIN-6).
  Future<void> _caricaVeicoli() async {
    try {
      final docs = await veicoliRepository.disponibili();
      if (!mounted) return;
      setState(
        () => _veicoliApi = docs
            .map((d) => VehicleData.daApi(d))
            .toList(growable: false),
      );
    } catch (_) {
      // Resta sui dati di riserva mock.
    }
  }

   Carica lo storico corse dalla API (fallback ai dati di riserva, IIN-6).
  Future<void> _caricaStorico() async {
    try {
      final corse = await corseRepository.storico();
      if (!mounted) return;
      setState(() => _storicoApi = corseInVoci(corse));
    } catch (_) {
      // Resta sui dati di riserva mock.
    }
  }

   Mezzi da mostrare: reali se caricati, altrimenti i dati di riserva.
  List<VehicleData> get _veicoliCorrenti => _veicoliApi ?? _vehicles;

   Cronologia da mostrare: solo i percorsi reali registrati a DB per l'utente
   (UT.17). Nessun dato fittizio — se non ce ne sono, la home mostra la card
   "+". Coerente con la cronologia del menù laterale (HistoryScreen).
  List<TripEntry> get _storicoCorrente => _storicoApi ?? const <TripEntry>[];

  // Mock vehicle cards aligned with Bari map markers.
  static const _vehicles = [
    VehicleData(
      id: 'SC-001',
      type: VehicleType.scooter,
      batteryPercent: 78,
      rangeKm: 42,
      distanceMeters: 120,
    ),
    VehicleData(
      id: 'BK-003',
      type: VehicleType.bike,
      batteryPercent: 91,
      rangeKm: 55,
      distanceMeters: 230,
    ),
    VehicleData(
      id: 'CA-007',
      type: VehicleType.car,
      batteryPercent: 65,
      rangeKm: 195,
      distanceMeters: 450,
    ),
    VehicleData(
      id: 'EM-002',
      type: VehicleType.emoto,
      batteryPercent: 85,
      rangeKm: 68,
      distanceMeters: 710,
    ),
  ];

  List<String> get _filterLabels => appLanguage.value == 'en'
      ? _filterLabelsEn.toList()
      : _filterLabelsIt.toList();

  List<VehicleData> get _filtered {
    final veicoli = _veicoliCorrenti;
    if (_selectedFilter == 0 || _selectedFilter == 5) return veicoli;
    final types = [
      VehicleType.scooter,
      VehicleType.bike,
      VehicleType.car,
      VehicleType.emoto,
    ];
    final target = types[_selectedFilter - 1];
    return veicoli.where((v) => v.type == target).toList();
  }

   Cronologia ordinata in modo crescente (corse meno recenti prima). UT.17.
  List<TripEntry> get _ascendingHistory {
    final trips = List<TripEntry>.of(_storicoCorrente);
    trips.sort((a, b) => a.sequence.compareTo(b.sequence));
    return trips;
  }

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DualSearchCard(),
            const SizedBox(height: 20),
            // UT.05 — filter chips
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _filterLabels.length,
                itemBuilder: (context, i) {
                  final selected = _selectedFilter == i;
                  final color = _filterColors[i]!;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: selected,
                      label: Text(_filterLabels[i]),
                      avatar: Icon(
                        _filterIcons[i],
                        size: 15,
                        color: selected ? Colors.white : color,
                      ),
                      backgroundColor: Colors.white,
                      selectedColor: color,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: selected ? Colors.white : AppTheme.textDark,
                      ),
                      side: BorderSide(
                        color: selected ? color : Colors.black12,
                      ),
                      elevation: selected ? 2 : 1,
                      onSelected: (_) => setState(() => _selectedFilter = i),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('Cronologia Percorsi'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGreen,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                  child: Text(
                    tr('Vedi tutte'),
                    style: const TextStyle(
                      color: AppTheme.accentBrown,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: _ascendingHistory.isEmpty
                  ? _buildAddRideCard(context)
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _ascendingHistory.length,
                      itemBuilder: (context, index) =>
                          _buildHistoryCard(context, _ascendingHistory[index]),
                    ),
            ),
            const SizedBox(height: 32),
            Text(
              tr('Mezzi Disponibili Vicino a Te'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGreen,
              ),
            ),
            const SizedBox(height: 16),
            if (_filtered.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    tr('Nessun mezzo disponibile per questo filtro.'),
                    style: const TextStyle(color: AppTheme.textGrey),
                  ),
                ),
              )
            else
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _filtered
                      .map((v) => _buildVehicleCard(context, v))
                      .toList(),
                ),
              ),
          ],
        ),
      );
    });
  }

   Builds a compact, tappable history card for the home strip.
   Tapping it opens the full trip detail (UT.17).
  Widget _buildHistoryCard(BuildContext context, TripEntry trip) {
    IconData icon;
    switch (trip.vehicleType) {
      case 'E-Bike':
        icon = Icons.pedal_bike;
      case 'Auto':
        icon = Icons.directions_car;
      case 'E-Moto':
        icon = Icons.electric_moped;
      default:
        icon = Icons.electric_scooter;
    }
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(icon, size: 16, color: AppTheme.accentBrown),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${tr('Corsa')} ${trip.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '${trip.cost.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGreen,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '${trip.from} → ${trip.to}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${trip.date}, ${trip.time}',
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

   Card "+" mostrata quando non esistono corse passate registrate a DB:
   invita ad avviarne una nuova portando alla mappa (UT.10). Ha la stessa
   dimensione delle card della cronologia per coerenza visiva.
  Widget _buildAddRideCard(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 250,
        height: 120,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => widget.onNuovaCorsa?.call(),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryGreen, width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    size: 34,
                    color: AppTheme.primaryGreen,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('Nessuna corsa: iniziane una nuova'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.darkGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, VehicleData v) {
    final color = v.typeColor;
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicle: v)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(v.typeIcon, size: 32, color: color),
                const SizedBox(height: 6),
                Text(
                  v.typeLabel.split(' ').first,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${v.batteryPercent}% · ~${v.rangeKm} km',
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

 Two-part departure/arrival search card — navigates to SearchScreen on tap.
 UT.03, UT.07.

### File: `screens\invoice_pdf.dart`

### `const double`
Aliquota IVA per lo scorporo (22%), allineata al Business Tier.

### File: `screens\invoice_screen.dart`

### `class InvoiceScreen`
@brief Fattura digitale stampabile di una corsa conclusa. UT.25.

 Rende una copia digitale della fattura a partire dai dati reali della corsa
 ([TripEntry] caricato dal backend) con lo **scorporo IVA** (aliquota 22%,
 coerente con `gestore_corse._emetti_fattura` lato server). Il documento è
 formattato come una ricevuta stampabile/screenshottabile; la generazione del
 PDF nativo e la condivisione di sistema richiederebbero un pacchetto dedicato
 (`printing`/`share_plus`) e sono lasciate a un'evoluzione successiva.

### `class _Riga`
@brief Crea la fattura per la corsa data.
   @param trip Corsa conclusa di cui emettere la copia digitale.
  const InvoiceScreen({required this.trip, super.key});

   Corsa di cui si mostra la fattura.
  final TripEntry trip;

   Aliquota IVA per lo scorporo (22%), allineata al Business Tier.
  static const double _aliquotaIva = 0.22;

   Imponibile scorporato dal totale lordo della corsa.
  double get _imponibile => trip.cost / (1 + _aliquotaIva);

   Quota IVA (totale lordo − imponibile).
  double get _iva => trip.cost - _imponibile;

   Apre il dialogo di stampa/condivisione nativo con il PDF della fattura.
  
   `Printing.layoutPdf` mostra l'anteprima e le opzioni di sistema (stampa,
   "Salva come PDF", condividi). Il PDF è generato da [buildInvoicePdf].
  Future<void> _stampaPdf() {
    return Printing.layoutPdf(
      name: 'Fattura_${trip.id}',
      onLayout: (format) => buildInvoicePdf(
        trip: trip,
        cliente:
            '${ProfileStore.firstName.value} ${ProfileStore.lastName.value}',
        format: format,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundBeige,
        appBar: AppBar(
          title: Text(
            tr('Fattura'),
            style: const TextStyle(color: AppTheme.darkGreen),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              tooltip: tr('Stampa o salva PDF'),
              icon: const Icon(Icons.print_outlined, color: AppTheme.darkGreen),
              onPressed: _stampaPdf,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Intestazione emittente.
                  Row(
                    children: [
                      const Icon(Icons.eco, color: AppTheme.primaryGreen),
                      const SizedBox(width: 8),
                      const Text(
                        'LEAF Mobility',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkGreen,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        tr('Fattura'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),

                  // Estremi del documento.
                  _Riga(tr('Numero'), 'FT-${trip.id}'),
                  _Riga(tr('Data'), '${trip.date} · ${trip.time}'),
                  _Riga(
                    tr('Cliente'),
                    '${ProfileStore.firstName.value} ${ProfileStore.lastName.value}',
                  ),
                  const SizedBox(height: 16),
                  _SezioneLabel(tr('Dettaglio corsa')),
                  const SizedBox(height: 8),
                  _Riga(tr('Veicolo'), trip.vehicleType),
                  _Riga(tr('Tragitto'), '${trip.from} → ${trip.to}'),
                  _Riga(tr('Durata'), '${trip.durationMinutes} ${tr('min')}'),
                  _Riga(
                    tr('Distanza'),
                    '${trip.distanceKm.toStringAsFixed(1)} km',
                  ),
                  const Divider(height: 28),

                  // Importi con scorporo IVA.
                  _RigaImporto(tr('Imponibile'), _imponibile),
                  _RigaImporto('${tr('IVA')} (22%)', _iva),
                  const SizedBox(height: 8),
                  _RigaImporto(tr('Totale'), trip.cost, totale: true),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      tr('Copia digitale — documento generato dall\'app.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _stampaPdf,
              icon: const Icon(Icons.print_outlined),
              label: Text(tr('Stampa o salva PDF')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

 Riga chiave→valore di un estremo della fattura.

### `class _RigaImporto`
Riga di un importo in euro; in grassetto evidenziato per il totale.

### `class _SezioneLabel`
Etichetta di sezione in maiuscoletto, coerente con le altre schermate.

### File: `screens\login_screen.dart`

### `class LoginScreen`
@brief Schermata di accesso cablata al backend `/api/v1/auth` (IIN-1/IIN-9/UT.24).

 Gestisce l'intero flusso di autenticazione reale: credenziali (IIN-1), secondo
 fattore OTP per gli utenti con MFA (IIN-9), reset password via email (UT.24) e
 rimando alla registrazione (UT.22). Espone stati di caricamento ed errore: la UI
 non assume mai un esito positivo prima della risposta del server.

### `class _LoginScreenState`
Repository di autenticazione iniettabile (default reale; fittizio nei test).
  final AuthApi? _auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

### File: `screens\main_layout.dart`

### `final ValueNotifier`
@brief Richiesta esterna di selezione di una tab della home.

 Una route pushata sopra la home (es. il dettaglio tratta) può chiedere di
 tornare alla home su una tab specifica valorizzando questo notifier prima del
 pop: [MainLayout] lo osserva e aggiorna la tab corrente. Indice tab (2 = Mappa)
 o null se nessuna richiesta pendente.

### File: `screens\map_tab.dart`

### `enum _VehicleFilter`
Vehicle filter options — UT.05.

### `class MapTab`
Map screen — sistemaTPL always integrated (architectural constraint).
 UT.01 vehicles, UT.05 filters, UT.14 charging, UT.20 SOS FAB.

### `class _MapTabState`
Repository veicoli iniettabile (default reale; fittizio nei test).
  final VeicoliApi? _veicoli;

  @override
  State<MapTab> createState() => _MapTabState();
}

### File: `screens\map_tab_data.dart`

### `const Map`
Colore identificativo di ciascun filtro mezzo nelle chip (UT.05).

### `const _vehicleData`
Mezzi disponibili sulla mappa: `(id, filtro, posizione, etichetta)` (UT.01/UT.05).

### `const _chargingData`
Stazioni di ricarica autorizzate: `(id, posizione, etichetta)` (UT.14).

 Posizioni reali su Bari fornite dal team (coordinate da DMS a gradi decimali),
 allineate al seed server `bootstrap_seed.py` (CHG-01..CHG-10): questa è la vista
 di riserva offline quando `/api/v1/stazioni` non è raggiungibile (IIN-6).

### File: `screens\my_bookings_screen.dart`

### `IconData iconForVehicleType`
Icona Material associata a un tipo di veicolo.

### `class MyBookingsScreen`
@brief Schermata "Mie Prenotazioni": corsa attiva + prenotazioni effettuate.

 UT.02 (prenotazioni effettuate), UT.10/UT.12 (corsa attiva, pausa/riprendi).
 Le prenotazioni sono caricate dal backend (`/api/v1/prenotazioni`, persistenti
 e condivise) e unite alle eventuali prenotazioni locali offline; la corsa
 attiva è osservata da [activeTripStore].

### `class _MyBookingsScreenState`
@brief Crea la schermata; il repository corse è iniettabile nei test.
  const MyBookingsScreen({super.key, CorseApi? corse}) : _corse = corse;

  final CorseApi? _corse;

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

### `class _ActiveTripCard`
Repository risolto: quello iniettato (test) o il singleton reale.
  late final CorseApi _corse = widget._corse ?? corseRepository;

   Contatore di ricarica: incrementarlo forza il reload del [CaricatoreVista]
   (es. dopo un annullo) senza gestione manuale dello stato della lista.
  int _ricarica = 0;

   Icona Material associata al tipo di veicolo prenotato.
  IconData _iconFor(Booking b) => iconForVehicleType(b.vehicleType);

   Orario in formato HH:mm.
  String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

   Carica le prenotazioni attive dal backend (UT.02/UT.21), unendo eventuali
   prenotazioni locali dimostrative (mezzi di riserva offline, `id` nullo).
  Future<List<Booking>> _caricaPrenotazioni() async {
    final docs = await _corse.prenotazioni();
    final server = docs.map(Booking.fromApi).toList();
    final locali = bookingStore.value.where(
      (b) => b.id == null && b.status == BookingStatus.attiva,
    );
    return [...server, ...locali];
  }

   Annulla una prenotazione: sul backend se ha un `id` reale (UT.12), altrimenti
   solo localmente; quindi forza la ricarica della lista.
  Future<void> _annulla(Booking b) async {
    final id = b.id;
    if (id == null) {
      cancelBooking(b);
      setState(() => _ricarica++);
      return;
    }
    try {
      await _corse.annullaPrenotazione(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('Prenotazione annullata')),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      setState(() => _ricarica++);
    } on LeafApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.messaggio),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        title: Text(tr('Mie Prenotazioni')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Corsa attiva con comandi pausa/riprendi (UT.12), se presente.
          ValueListenableBuilder<ActiveTrip?>(
            valueListenable: activeTripStore,
            builder: (context, trip, _) => trip == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _ActiveTripCard(trip: trip, corse: _corse),
                  ),
          ),
          Expanded(
            // Prenotazioni reali dal backend: caricamento→errore(retry)→vuoto→lista.
            child: CaricatoreVista<List<Booking>>(
              key: ValueKey(_ricarica),
              carica: _caricaPrenotazioni,
              vuotoSe: (bookings) => bookings.isEmpty,
              vistaVuota: VistaVuota(
                titolo: tr('Nessuna prenotazione attiva'),
                sottotitolo: tr('Le prenotazioni che effettui appariranno qui.'),
                icona: Icons.event_busy_outlined,
              ),
              costruisci: (context, bookings) => ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: bookings.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, i) =>
                    _buildBookingCard(context, bookings[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

   Card di una singola prenotazione, con azione di annullo se attiva.
  Widget _buildBookingCard(BuildContext context, Booking b) {
    final bool active = b.status == BookingStatus.attiva;
    final Color statusColor = active ? AppTheme.primaryGreen : Colors.grey;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withAlpha(28),
                child: Icon(_iconFor(b), color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${b.vehicleTypeLabel} · ${b.vehicleId}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${tr('Riservato alle')} ${_hhmm(b.createdAt)} · ${b.durationMinutes} ${tr('min')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(active: active),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.schedule_outlined,
                    size: 16,
                    color: AppTheme.accentBrown,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${tr('Scade alle')} ${_hhmm(b.expiresAt)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              Text(
                '${b.estimatedCost.toStringAsFixed(2)} €',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGreen,
                ),
              ),
            ],
          ),
          if (active) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _annulla(b),
                icon: const Icon(
                  Icons.cancel_outlined,
                  color: Colors.red,
                  size: 18,
                ),
                label: Text(
                  tr('Annulla prenotazione'),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

 @brief Card della corsa in svolgimento con comandi pausa/riprendi (UT.12).

 Invia al backend `pausa`/`riprendi` (`/corse/{id}/pausa|riprendi`) tramite
 [CorseApi] e aggiorna lo stato osservabile [activeTripStore]. Mantiene il
 mezzo bloccato e a disposizione dell'utente senza terminare il noleggio.

### `class _ActiveTripCardState`
Corsa attiva da rappresentare.
  final ActiveTrip trip;

   Repository corse usato per pausa/riprendi (default reale; test).
  final CorseApi? _corse;

  @override
  State<_ActiveTripCard> createState() => _ActiveTripCardState();
}

### `class _StatusBadge`
Operazione pausa/riprendi in corso (disabilita il pulsante).
  bool _inCorso = false;

   Conclusione del noleggio in corso (disabilita i pulsanti).
  bool _conclusione = false;

   Conclude il noleggio: termina la corsa sul backend, mostra l'importo finale
   e azzera la corsa attiva (UT.04). L'eventuale copertura da abbonamento è
   riflessa nel riepilogo (punto 3/8).
  Future<void> _concludi() async {
    if (_conclusione) return;
    setState(() => _conclusione = true);
    // OP.05/OP.04: posizione GPS di chiusura best-effort (riserva: nessuna coordinata).
    double? lat;
    double? lon;
    try {
      final pos = await Geolocator.getCurrentPosition();
      lat = pos.latitude;
      lon = pos.longitude;
    } catch (_) {
      // GPS non disponibile: si conclude comunque senza coordinate.
    }
    try {
      final dati = await _corse.termina(widget.trip.idCorsa, lat: lat, lon: lon);
      clearActiveTrip();
      if (!mounted) return;
      final coperto = dati['coperto_da_abbonamento'] == true;
      final cent = (dati['costo_finale_cent'] as num?)?.toInt() ?? 0;
      final fuoriArea = dati['fuori_area_operativa'] == true;
      final base = coperto
          ? '${tr('Noleggio concluso')} · ${tr('coperto da abbonamento')}'
          : '${tr('Noleggio concluso')} · ${(cent / 100).toStringAsFixed(2)} €';
      final messaggio = fuoriArea
          ? '$base · ${tr('rilascio fuori area operativa')}'
          : base;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(messaggio),
          backgroundColor: fuoriArea
              ? const Color(0xFFE65100)
              : AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } on LeafApiException catch (e) {
      if (!mounted) return;
      setState(() => _conclusione = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.messaggio), backgroundColor: const Color(0xFFC62828)),
      );
    }
  }

   Mette in pausa o riprende la corsa sul backend (UT.12).
  Future<void> _commuta() async {
    if (_inCorso) return;
    final trip = widget.trip;
    setState(() => _inCorso = true);
    try {
      if (trip.isPaused) {
        await _corse.riprendi(trip.idCorsa);
        setActiveTripStatus(TripStatus.inCorso);
      } else {
        await _corse.pausa(trip.idCorsa);
        setActiveTripStatus(TripStatus.inPausa);
      }
    } on LeafApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.messaggio), backgroundColor: const Color(0xFFC62828)),
      );
    } finally {
      if (mounted) setState(() => _inCorso = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final bool paused = trip.isPaused;
    final Color accento = paused ? AppTheme.accentBrown : AppTheme.primaryGreen;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accento.withAlpha(120)),
        boxShadow: [
          BoxShadow(
            color: accento.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: accento.withAlpha(28),
                child: Icon(iconForVehicleType(trip.vehicleType), color: accento),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tr('Corsa in corso')} · ${trip.vehicleId}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      paused ? tr('In pausa') : tr('In movimento'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accento,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accento,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: (_inCorso || _conclusione) ? null : _commuta,
              icon: _inCorso
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(paused ? Icons.play_arrow : Icons.pause),
              label: Text(
                paused ? tr('Riprendi corsa') : tr('Pausa corsa'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC62828),
                side: const BorderSide(color: Color(0xFFC62828)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: (_inCorso || _conclusione) ? null : _concludi,
              icon: _conclusione
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFC62828),
                      ),
                    )
                  : const Icon(Icons.stop_circle_outlined),
              label: Text(
                tr('Concludi noleggio'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

 Badge di stato (Attiva / Annullata) della prenotazione.

### File: `screens\notifications_screen.dart`

### `class NotificationsScreen`
Notifications screen wired to `GET /api/v1/notifiche` (UT.15/UT.19, IIN-19).

 Mostra le notifiche reali dell'utente e i broadcast di servizio (scadenza
 prenotazione, interruzione servizio), dalla più recente; il tap su una
 notifica non letta la marca come letta (`POST /notifiche/{id}/letta`). In
 assenza di rete (IIN-6) mostra un avviso con possibilità di riprovare.

### `class _NotificationsScreenState`
@brief Repository notifiche iniettabile (default singleton reale; fake nei test).
  final NotificheApi? repo;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

### File: `screens\registration_screen.dart`

### `class RegistrationScreen`
@brief Registrazione di un nuovo utente UT cablata su `/api/v1/auth/registrazione` (UT.22.1).

 Raccoglie le credenziali di base (email, username, password) e le invia al backend,
 che applica la politica password IIN-5 e l'unicità di email/username. Gestisce gli
 stati di caricamento ed errore; al successo riporta al login per l'accesso (UT.23).

### `class _RegistrationScreenState`
Repository di autenticazione iniettabile (default reale; fittizio nei test).
  final AuthApi? _auth;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

### File: `screens\reset_password_screen.dart`

### `class ResetPasswordScreen`
@brief Schermata di recupero password per utenti UT (IIN-11/UT.24).

 Flusso a due fasi:
 1. Inserimento email → richiesta codice di reset al backend.
 2. Inserimento codice ricevuto via email + nuova password → conferma reset
    e ritorno alla schermata di login con notifica di successo.

 Il codice via email è monouso, valido 15 min (IIN-11). La nuova password
 viene salvata come password definitiva dell'account (non temporanea).

### `enum _FaseReset`
Repository di autenticazione iniettabile (default reale; fittizio nei test).
  final AuthApi? _auth;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

 Fase corrente del flusso di reset.

### File: `screens\route_detail_screen.dart`

### `class RouteData`
A single route option. UT.07 (route options with TPL integration).

### `class RouteDetailScreen`
Tipo di mezzo consigliato per il percorso (UT.08). Permette di mostrare
   l'icona della modalità anche quando [recommended] è vuota (nessun mezzo
   reale disponibile nelle vicinanze / offline). Null per i percorsi mock.
  final VehicleType? recommendedType;

  const RouteData({
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.distanceKm,
    required this.transportSummary,
    required this.recommended,
    this.hasTpl = false,
    this.recommendedType,
  });
}

 Route detail screen — UT.07, UT.08, UT.03.
 Shows route summary, recommended vehicles and lets user view vehicle info.

### File: `screens\search_screen.dart`

### `class SearchScreen`
Full-screen search screen.
 Requires BOTH departure AND arrival to show route list (UT.03, UT.07).

### `class _SearchScreenState`
Whether to focus the departure field first.
  final bool startWithDeparture;

   Repository di routing/geocoding iniettabile (default reale; fittizio nei test).
  final RoutingApi? routing;

   Repository veicoli iniettabile per i mezzi consigliati (default reale; test).
  final VeicoliApi? veicoli;

  const SearchScreen({
    this.startWithDeparture = true,
    this.routing,
    this.veicoli,
    super.key,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

### `class _LocationTile`
Repository effettivi (iniettabili nei test).
  RoutingApi get _routing => widget.routing ?? routingRepository;
  VeicoliApi get _veicoli => widget.veicoli ?? veicoliRepository;

   Suggerimenti di luogo correnti per il campo attivo (UT.07).
  List<LuogoSuggerito> _suggestions = const [];

   True mentre il geocoding è in corso (mostra l'indicatore di caricamento).
  bool _suggLoading = false;

   Sequenza per scartare le risposte di geocoding obsolete (anti-race).
  int _suggSeq = 0;

  bool get _depFilled => _depCtrl.text.trim().isNotEmpty;
  bool get _arrFilled => _arrCtrl.text.trim().isNotEmpty;
  bool get _bothFilled => _depFilled && _arrFilled;

  String get _activeQuery => _depActive ? _depQuery : _arrQuery;

  @override
  void initState() {
    super.initState();
    _depCtrl.addListener(() {
      setState(() => _depQuery = _depCtrl.text);
      if (_depActive) _aggiornaSuggerimenti();
    });
    _arrCtrl.addListener(() {
      setState(() => _arrQuery = _arrCtrl.text);
      if (!_depActive) _aggiornaSuggerimenti();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.startWithDeparture) {
        _depFocus.requestFocus();
      } else {
        _arrFocus.requestFocus();
        setState(() => _depActive = false);
      }
    });
  }

   @brief Aggiorna i suggerimenti di luogo per il campo attivo dal backend (UT.07).
  
   Chiama `/geocoding` sul gazetteer del server; in caso di errore (offline,
   IIN-6) ripiega sui suggerimenti di riserva filtrati localmente. Una sequenza
   monotòna scarta le risposte arrivate fuori ordine.
  Future<void> _aggiornaSuggerimenti() async {
    final query = _activeQuery.trim();
    final seq = ++_suggSeq;
    if (query.isEmpty || query == _posizioneCorrente) {
      setState(() {
        _suggestions = const [];
        _suggLoading = false;
      });
      return;
    }
    setState(() => _suggLoading = true);
    try {
      final risultati = await _routing.suggerisci(query);
      if (!mounted || seq != _suggSeq) return;
      setState(() {
        _suggestions = risultati;
        _suggLoading = false;
      });
    } catch (_) {
      if (!mounted || seq != _suggSeq) return;
      setState(() {
        _suggestions = _suggerimentiOffline
            .where((s) => s.toLowerCase().contains(query.toLowerCase()))
            .map((s) => LuogoSuggerito(nome: s, lat: 0, lon: 0))
            .toList(growable: false);
        _suggLoading = false;
      });
    }
  }

   @brief Carica le opzioni di percorso reali tra i due campi (UT.07/UT.08).
  
   Geocodifica i nomi lato server (o usa le coordinate della posizione corrente),
   recupera i veicoli reali vicino all'origine per i mezzi consigliati (best-effort)
   e mappa il payload in [RouteData]. Le eccezioni propagano al [CaricatoreVista]
   che mostra lo stato d'errore con "Riprova".
  Future<List<RouteData>> _caricaPercorsi() async {
    final dep = _depCtrl.text.trim();
    final arr = _arrCtrl.text.trim();
    final depPos = dep == _posizioneCorrente;
    final arrPos = arr == _posizioneCorrente;
    final payload = await _routing.percorsi(
      da: depPos ? null : dep,
      a: arrPos ? null : arr,
      daLat: depPos ? _centroBariLat : null,
      daLon: depPos ? _centroBariLon : null,
      aLat: arrPos ? _centroBariLat : null,
      aLon: arrPos ? _centroBariLon : null,
    );
    final percorsi = (payload['percorsi'] as List?) ?? const [];
    final origine = payload['origine'];
    double? oLat, oLon;
    if (origine is Map) {
      oLat = (origine['lat'] as num?)?.toDouble();
      oLon = (origine['lon'] as num?)?.toDouble();
    }
    var mezzi = const <VehicleData>[];
    try {
      final grezzi = await _veicoli.disponibili(lat: oLat, lon: oLon);
      mezzi = grezzi.map((m) => VehicleData.daApi(m)).toList(growable: false);
    } catch (_) {
      mezzi = const []; // best-effort: i mezzi consigliati restano assenti (IIN-6)
    }
    return _percorsiDaApi(percorsi, mezzi);
  }

  @override
  void dispose() {
    _depCtrl.dispose();
    _arrCtrl.dispose();
    _depFocus.dispose();
    _arrFocus.dispose();
    super.dispose();
  }

   Rende attivo il campo partenza ([dep] true) o arrivo e aggiorna i suggerimenti.
  
   @param dep True per attivare la partenza, false per l'arrivo.
  void _attiva(bool dep) {
    setState(() => _depActive = dep);
    _aggiornaSuggerimenti();
  }

   Applica la [location] scelta al campo attivo (partenza o arrivo) e sposta
   il focus al campo successivo se ancora vuoto (UT.07).
  
   @param location Localita' selezionata dai suggerimenti o dalla cronologia.
  void _selectLocation(String location) {
    if (_depActive) {
      _depCtrl.text = location;
      setState(() => _depQuery = location);
      // Auto-move focus to arrival if empty
      if (!_arrFilled) {
        setState(() => _depActive = false);
        _arrFocus.requestFocus();
      } else {
        FocusScope.of(context).unfocus();
      }
    } else {
      _arrCtrl.text = location;
      setState(() => _arrQuery = location);
      FocusScope.of(context).unfocus();
    }
  }

   Inverte i contenuti dei campi di partenza e arrivo.
  void _swap() {
    final tmp = _depCtrl.text;
    _depCtrl.text = _arrCtrl.text;
    _arrCtrl.text = tmp;
    setState(() {
      _depQuery = _depCtrl.text;
      _arrQuery = _arrCtrl.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        title: Text(tr('Cerca percorso')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_bothFilled)
            TextButton(
              onPressed: () {
                _depCtrl.clear();
                _arrCtrl.clear();
              },
              child: Text(
                tr('Cancella'),
                style: const TextStyle(
                  color: AppTheme.accentBrown,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Dual input panel ──────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      // Departure
                      GestureDetector(
                        onTap: () {
                          _attiva(true);
                          _depFocus.requestFocus();
                        },
                        child: TextField(
                          controller: _depCtrl,
                          focusNode: _depFocus,
                          onTap: () => _attiva(true),
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) {
                            _attiva(false);
                            _arrFocus.requestFocus();
                          },
                          decoration: InputDecoration(
                            hintText: tr('Da dove parti?'),
                            prefixIcon: const Icon(
                              Icons.trip_origin,
                              color: AppTheme.primaryGreen,
                              size: 18,
                            ),
                            suffixIcon: _depFilled
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () => _depCtrl.clear(),
                                  )
                                : null,
                            border: _inputBorder(_depActive),
                            focusedBorder: _inputBorder(true),
                            enabledBorder: _inputBorder(false),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            filled: true,
                            fillColor: AppTheme.backgroundBeige,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Arrival
                      GestureDetector(
                        onTap: () {
                          _attiva(false);
                          _arrFocus.requestFocus();
                        },
                        child: TextField(
                          controller: _arrCtrl,
                          focusNode: _arrFocus,
                          onTap: () => _attiva(false),
                          decoration: InputDecoration(
                            hintText: tr('Dove vuoi andare?'),
                            prefixIcon: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 18,
                            ),
                            suffixIcon: _arrFilled
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () => _arrCtrl.clear(),
                                  )
                                : null,
                            border: _inputBorder(!_depActive),
                            focusedBorder: _inputBorder(true),
                            enabledBorder: _inputBorder(false),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            filled: true,
                            fillColor: AppTheme.backgroundBeige,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Swap button
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    icon: const Icon(
                      Icons.swap_vert,
                      color: AppTheme.accentBrown,
                    ),
                    onPressed: _swap,
                    tooltip: tr('Inverti'),
                  ),
                ),
              ],
            ),
          ),
          // "Use current location" shortcut
          if (!_bothFilled)
            InkWell(
              onTap: () => _selectLocation('Posizione corrente'),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.my_location,
                      color: AppTheme.primaryGreen,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      tr('Usa posizione corrente'),
                      style: const TextStyle(
                        color: AppTheme.darkGreen,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const Divider(height: 1),

          // ── Body: suggestions / history / routes ──────────────────────
          Expanded(
            child: _bothFilled
                ? _buildRouteList()
                : _activeQuery.isEmpty
                ? _buildHistory()
                : _buildSuggestions(),
          ),
        ],
      ),
    );
  }

   Bordo del campo di testo, evidenziato quando [active].
  
   @param active Se il campo e' quello correntemente selezionato.
   @return Il bordo arrotondato con colore/spessore coerenti allo stato.
  OutlineInputBorder _inputBorder(bool active) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(
      color: active ? AppTheme.primaryGreen : Colors.black12,
      width: active ? 1.5 : 1.0,
    ),
  );

   @return La lista delle ricerche recenti (mostrata a query vuota, UT.07).
  Widget _buildHistory() => ListView(
    children: [
      _header(tr('Ricerche recenti')),
      ..._searchHistory.map(
        (h) => _LocationTile(
          icon: Icons.history,
          color: AppTheme.textGrey,
          label: h,
          onTap: () => _selectLocation(h),
        ),
      ),
    ],
  );

   @return La lista dei suggerimenti dal backend (UT.07): indicatore di
   caricamento durante il geocoding, messaggio "nessun risultato" se vuota.
  Widget _buildSuggestions() {
    if (_suggLoading && _suggestions.isEmpty) {
      return const VistaCaricamento();
    }
    if (_suggestions.isEmpty) {
      return Center(
        child: Text(
          tr('Nessun risultato.'),
          style: const TextStyle(color: AppTheme.textGrey),
        ),
      );
    }
    return ListView(
      children: [
        _header(tr('Suggerimenti')),
        ..._suggestions.map(
          (s) => _LocationTile(
            icon: Icons.place_outlined,
            color: AppTheme.accentBrown,
            label: s.nome,
            onTap: () => _selectLocation(s.nome),
          ),
        ),
      ],
    );
  }

   @return Le opzioni di percorso reali tra i due campi, con stati
   caricamento/errore/vuoto (UT.03/UT.07). La `key` su partenza|arrivo forza
   una nuova richiesta quando l'utente modifica i campi.
  Widget _buildRouteList() {
    return CaricatoreVista<List<RouteData>>(
      key: ValueKey('${_depCtrl.text}|${_arrCtrl.text}'),
      carica: _caricaPercorsi,
      messaggioCaricamento: tr('Ricerca percorsi…'),
      vuotoSe: (routes) => routes.isEmpty,
      vistaVuota: VistaVuota(
        titolo: tr('Nessun percorso disponibile'),
        sottotitolo: tr('Prova con un\'altra destinazione.'),
        icona: Icons.alt_route,
      ),
      costruisci: (context, routes) => ListView(
        children: [
          _header(
            '${tr('Percorsi disponibili')}  ·  ${routes.length} ${tr('opzioni')}',
          ),
          ...routes.map(
            (r) => _RouteTile(
              route: r,
              departure: _depCtrl.text,
              arrival: _arrCtrl.text,
            ),
          ),
        ],
      ),
    );
  }

   Intestazione di sezione in maiuscolo.
  
   @param text Etichetta della sezione.
   @return Il widget di intestazione formattato.
  Widget _header(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.textGrey,
        letterSpacing: 0.7,
      ),
    ),
  );
}

 @brief Riga di un suggerimento di luogo o di una ricerca recente (UT.07).

### `class _RouteTile`
@brief Card di un'opzione di percorso; apre il dettaglio al tap (UT.03/UT.07).

### `class _Chip`
@return Il tipo di mezzo della modalità: dal primo consigliato reale, o dal
   tipo consigliato del percorso se nessun mezzo è disponibile (offline/vuoto).
  VehicleType? get _modeType => route.recommended.isNotEmpty
      ? route.recommended.first.type
      : route.recommendedType;

   @return L'icona della modalità principale del percorso.
  IconData get _modeIcon {
    final type = _modeType;
    if (type == null) return Icons.directions;
    return VehicleData(
      id: '',
      type: type,
      batteryPercent: 0,
      rangeKm: 0,
      distanceMeters: 0,
    ).typeIcon;
  }

   @return Il colore associato alla modalità principale del percorso.
  Color get _modeColor {
    final type = _modeType;
    if (type == null) return AppTheme.primaryGreen;
    return VehicleData(
      id: '',
      type: type,
      batteryPercent: 0,
      rangeKm: 0,
      distanceMeters: 0,
    ).typeColor;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RouteDetailScreen(
              route: route,
              departure: departure,
              arrival: arrival,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _modeColor.withAlpha(22),
                child: Icon(_modeIcon, color: _modeColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(route.name),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tr(route.description),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGrey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _Chip(
                          Icons.schedule_outlined,
                          '${route.durationMinutes} min',
                        ),
                        const SizedBox(width: 8),
                        _Chip(
                          Icons.straighten_outlined,
                          '${route.distanceKm} km',
                        ),
                        if (route.hasTpl) ...[
                          const SizedBox(width: 8),
                          const _Chip(
                            Icons.directions_bus_outlined,
                            'TPL',
                            color: Colors.blue,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textGrey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

 @brief Piccola etichetta con icona usata nelle card percorso (durata, km, TPL).

### File: `screens\search_screen_data.dart`

### `const List`
Cronologia delle ricerche recenti mostrata a campo vuoto (UT.07).
 Locale: non esiste un endpoint server dedicato alla cronologia di ricerca.

### `const List`
Suggerimenti di riserva usati se il geocoding del server non risponde (IIN-6).

### `const String`
Sentinella della scorciatoia "usa posizione corrente".

### `const double`
Coordinate di riferimento per la posizione corrente finché il GPS non è cablato
 in questa schermata (centro di Bari — Stazione Centrale). Usate come origine/
 destinazione quando l'utente sceglie "Usa posizione corrente".

### `VehicleType _tipoVeicoloDaApi`
@brief Mappa il discriminante `tipo_mezzo`/`tipo_consigliato` del server sull'enum di vista.
 @param tipo Discriminante del server (ebike/ecar/emotorbike/monopattino).
 @return Il [VehicleType] corrispondente (default scooter).

### `String _riepilogoTrasporto`
@brief Riepilogo testuale della modalità di trasporto del percorso (UT.07).
 @param tipo Tipo di mezzo consigliato per la tratta in sharing.
 @param haTpl Se il percorso integra il trasporto pubblico locale.
 @return Una breve descrizione della modalità.

### `RouteData _percorsoDaApi`
@brief Costruisce una [RouteData] da un'opzione di percorso della API (UT.07/UT.08).

 I mezzi consigliati sono i veicoli reali disponibili vicino alla partenza filtrati
 per il tipo consigliato dell'opzione; se nessuno è disponibile, [RouteData.recommended]
 resta vuota e l'icona della modalità deriva da [RouteData.recommendedType].

 @param opzione Opzione grezza `{nome, descrizione, durata_min, distanza_km, ha_tpl, tipo_consigliato}`.
 @param mezzi Veicoli reali disponibili vicino all'origine (da `/veicoli`).
 @return Il modello di vista del percorso.

### File: `screens\sensitive_data_screen.dart`

### `class SensitiveDataScreen`
@brief Schermata dei dati sensibili dell'utente. UT.11, UT.22.2.

 Permette di visualizzare e modificare:
   1. i documenti ufficiali (carta d'identita', patente) — caricamento KYC
      di immagini JPG/PNG oppure di un PDF generato dalla foto del documento,
      da galleria o fotocamera (IIN-6);
   2. il metodo di pagamento registrato (UT.11).

 Tutti i dati restano **locali** sul dispositivo ([ProfileStore]); la
 cifratura at-rest (AES-256) e la verifica KYC saranno a carico del Business
 Tier (`gestore_profili_ekyc`, `gateway_pagamenti`). I numeri di carta sono
 sempre mostrati mascherati.

### `class _SensitiveDataScreenState`
@brief Crea la schermata; il repository profilo è iniettabile nei test.
  const SensitiveDataScreen({super.key, ProfiloApi? profilo})
    : _profilo = profilo;

  final ProfiloApi? _profilo;

  @override
  State<SensitiveDataScreen> createState() => _SensitiveDataScreenState();
}

### `class _SectionLabel`
Indica se il metodo di pagamento e' in modifica.
  bool _editingPayment = false;

   Registrazione del metodo di pagamento al backend in corso.
  bool _savingPayment = false;

  @override
  void initState() {
    super.initState();
    _holder = TextEditingController(text: ProfileStore.cardHolder.value);
    _number = TextEditingController(text: ProfileStore.cardNumber.value);
    _expiry = TextEditingController(text: ProfileStore.cardExpiry.value);
    _cvv = TextEditingController();
    // Indirizzo di fatturazione precompilato con la residenza del profilo: deve
    // coincidere (verifica server-side, punto 4/5).
    _billing = TextEditingController(text: ProfileStore.address.value);
  }

  @override
  void dispose() {
    _holder.dispose();
    _number.dispose();
    _expiry.dispose();
    _cvv.dispose();
    _billing.dispose();
    super.dispose();
  }

   Verifica un numero di carta con l'algoritmo di Luhn (checksum, punto 4).
   @param cifre Numero carta come sole cifre.
   @return True se il checksum di Luhn è valido.
  bool _luhnValido(String cifre) {
    if (cifre.length < 13) return false;
    var somma = 0;
    var raddoppia = false;
    for (var i = cifre.length - 1; i >= 0; i--) {
      var n = int.parse(cifre[i]);
      if (raddoppia) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      somma += n;
      raddoppia = !raddoppia;
    }
    return somma % 10 == 0;
  }

   Maschera un numero di carta lasciando in chiaro solo le ultime 4 cifre.
  String _maskCard(String raw) {
    final digits = raw.replaceAll(RegExp(r'\s'), '');
    if (digits.length < 4) return digits;
    final last4 = digits.substring(digits.length - 4);
    return '•••• •••• •••• $last4';
  }

   Carica/aggiorna un documento KYC: immagine o PDF (IIN-6, UT.22.2).
  
   Offre tre modalità: immagine (JPG/PNG) da galleria o fotocamera, oppure
   selezione di un documento **già in PDF dal file manager** del dispositivo
   (non dalla galleria). Dopo la copia locale del file (resta sul dispositivo),
   notifica al backend il caricamento KYC inviando tipo e nome del file:
   l'estensione è rivalidata server-side (AG-SEC-01). Il `tipo` deve essere
   `patente` o `carta_identita`.
  Future<void> _uploadDocument({
    required String basename,
    required String tipo,
    required Future<void> Function(String?) onStored,
  }) async {
    final scelta = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.backgroundBeige,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppTheme.primaryGreen,
              ),
              title: Text(tr('Immagine dalla galleria')),
              onTap: () => Navigator.pop(context, 'img_gallery'),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: AppTheme.primaryGreen,
              ),
              title: Text(tr('Scatta una foto')),
              onTap: () => Navigator.pop(context, 'img_camera'),
            ),
            ListTile(
              leading: const Icon(
                Icons.picture_as_pdf_outlined,
                color: AppTheme.accentBrown,
              ),
              title: Text(tr('PDF dal file manager')),
              onTap: () => Navigator.pop(context, 'pdf_file'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!mounted || scelta == null) return;

    // PDF reale scelto dal file manager del dispositivo (UT.22.2).
    if (scelta == 'pdf_file') {
      final pdf = await _scegliPdfDaFile(basename);
      if (!mounted || pdf == null) return;
      await onStored(pdf.path);
      await _inviaKyc(tipo, pdf.uri.pathSegments.last);
      return;
    }

    // Immagine (JPG/PNG) da galleria o fotocamera.
    final result = await pickAndStoreImage(
      source: scelta == 'img_camera' ? ImageSource.camera : ImageSource.gallery,
      basename: basename,
    );
    if (!mounted) return;
    if (result.permissionDenied) {
      _showSnack(tr('Permesso negato. Abilitalo nelle impostazioni.'));
      return;
    }
    final file = result.file;
    if (file == null) return;
    await onStored(file.path);
    await _inviaKyc(tipo, file.uri.pathSegments.last);
  }

   Seleziona un documento già in formato PDF dal file manager e lo copia nella
   sandbox dell'app (UT.22.2). Filtra l'estensione a `.pdf` lato selettore;
   l'estensione è comunque rivalidata server-side (AG-SEC-01).
   @param basename Nome-base del file PDF di destinazione nella sandbox.
   @return Il file PDF copiato in sandbox, o null se l'utente annulla.
  Future<File?> _scegliPdfDaFile(String basename) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    final sorgente = result?.files.single.path;
    if (sorgente == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final dest = File('${dir.path}/$basename.pdf');
    await dest.writeAsBytes(await File(sorgente).readAsBytes());
    return dest;
  }

   Notifica al backend il caricamento di un documento KYC (UT.22.2).
  
   Tollerante all'assenza di rete (IIN-6): in caso di errore il file resta
   salvato localmente e all'utente viene mostrato il messaggio di dominio.
  Future<void> _inviaKyc(String tipo, String nomeFile) async {
    try {
      final dati = await _profilo.caricaKyc(tipo: tipo, nomeFile: nomeFile);
      if (!mounted) return;
      final stato = dati['stato_verifica']?.toString() ?? tr('in verifica');
      _showSnack('${tr('Documento inviato')} · $stato');
    } on LeafApiException catch (e) {
      if (!mounted) return;
      _showSnack(e.messaggio);
    }
  }

   Apre l'anteprima del documento: per i PDF usa il dialogo di sistema
   (riuso del pacchetto `printing`); per le immagini un viewer a schermo intero.
  void _viewDocument(String title, String path) {
    if (path.toLowerCase().endsWith('.pdf')) {
      Printing.layoutPdf(name: title, onLayout: (_) => File(path).readAsBytes());
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(title, style: const TextStyle(color: Colors.white)),
          ),
          body: Center(child: InteractiveViewer(child: Image.file(File(path)))),
        ),
      ),
    );
  }

   Registra il metodo di pagamento (UT.11).
  
   Invia la carta al backend per la verifica (`POST /profilo/pagamenti`); il
   PAN **non viene mai persistito in chiaro sul client**: localmente si salva
   solo il numero mascherato (quello restituito dal server o, in assenza di
   rete, mascherato localmente — IIN-6). In caso di errore di dominio il PAN
   non viene persistito e si resta in modifica.
  Future<void> _savePayment() async {
    if (_savingPayment) return;
    FocusScope.of(context).unfocus();
    final holder = _holder.text.trim();
    final expiry = _expiry.text.trim();
    final digits = _number.text.replaceAll(RegExp(r'\D'), '');
    final cvv = _cvv.text.replaceAll(RegExp(r'\D'), '');
    final billing = _billing.text.trim();
    final scadenza = _parseExpiry(expiry);

    // Validazione client stretta (punto 4): lunghezza+Luhn, scadenza futura,
    // CVV a 3 cifre, indirizzo di fatturazione presente. Niente salvataggio
    // parziale: la carta si registra solo se completa e valida.
    if (holder.isEmpty) {
      _showSnack(tr('Inserisci l\'intestatario della carta.'));
      return;
    }
    if (digits.length < 13 || digits.length > 19 || !_luhnValido(digits)) {
      _showSnack(tr('Numero carta non valido.'));
      return;
    }
    if (scadenza == null) {
      _showSnack(tr('Scadenza non valida (usa MM/AA).'));
      return;
    }
    if (!_scadenzaFutura(scadenza)) {
      _showSnack(tr('La carta è scaduta.'));
      return;
    }
    if (cvv.length != 3) {
      _showSnack(tr('Il codice di sicurezza deve avere 3 cifre.'));
      return;
    }
    if (billing.isEmpty) {
      _showSnack(tr('Inserisci l\'indirizzo di fatturazione.'));
      return;
    }

    setState(() => _savingPayment = true);
    try {
      final dati = await _profilo.registraPagamento(
        numero: digits,
        mese: scadenza.$1,
        anno: scadenza.$2,
        titolare: holder,
        cvv: cvv,
        indirizzoFatturazione: billing,
      );
      final mascherato = dati['pan_mascherato']?.toString() ?? _maskCard(digits);
      await ProfileStore.savePaymentMethod(
        holder: holder,
        number: mascherato,
        expiry: expiry,
      );
      if (!mounted) return;
      setState(() {
        _editingPayment = false;
        _savingPayment = false;
      });
      _showSnack(tr('Metodo di pagamento registrato'));
    } on LeafApiException catch (e) {
      if (!mounted) return;
      setState(() => _savingPayment = false);
      _showSnack(e.messaggio);
    }
  }

   Indica se la scadenza (mese, anno) è nel presente o nel futuro (punto 4).
  bool _scadenzaFutura((int, int) scadenza) {
    final ora = DateTime.now();
    final (mese, anno) = scadenza;
    // Valida fino all'ultimo giorno del mese di scadenza.
    final fineMese = DateTime(anno, mese + 1, 0, 23, 59, 59);
    return fineMese.isAfter(ora);
  }

   Converte una scadenza `MM/AA` in `(mese, anno)` a quattro cifre, o null.
  (int, int)? _parseExpiry(String raw) {
    final match = RegExp(r'^(\d{1,2})\s*/\s*(\d{2})$').firstMatch(raw.trim());
    if (match == null) return null;
    final mese = int.parse(match.group(1)!);
    final anno = 2000 + int.parse(match.group(2)!);
    if (mese < 1 || mese > 12) return null;
    return (mese, anno);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundBeige,
        appBar: AppBar(
          title: Text(
            tr('Dati sensibili'),
            style: const TextStyle(color: AppTheme.darkGreen),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Documenti importanti (UT.22.2) ──────────────────────────
            _SectionLabel(tr('Documenti importanti')),
            const SizedBox(height: 6),
            Text(
              tr('Formati accettati: PDF, JPG, PNG.'),
              style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<String?>(
              valueListenable: ProfileStore.idCardPath,
              builder: (context, path, _) => _DocumentCard(
                icon: Icons.badge_outlined,
                title: tr("Carta d'identità"),
                path: path,
                onUpload: () => _uploadDocument(
                  basename: 'kyc_id_card',
                  tipo: 'carta_identita',
                  onStored: ProfileStore.setIdCardPath,
                ),
                onView: path == null
                    ? null
                    : () => _viewDocument(tr("Carta d'identità"), path),
                onRemove: path == null
                    ? null
                    : () => ProfileStore.setIdCardPath(null),
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<String?>(
              valueListenable: ProfileStore.licensePath,
              builder: (context, path, _) => _DocumentCard(
                icon: Icons.directions_car_outlined,
                title: tr('Patente'),
                path: path,
                onUpload: () => _uploadDocument(
                  basename: 'kyc_license',
                  tipo: 'patente',
                  onStored: ProfileStore.setLicensePath,
                ),
                onView: path == null
                    ? null
                    : () => _viewDocument(tr('Patente'), path),
                onRemove: path == null
                    ? null
                    : () => ProfileStore.setLicensePath(null),
              ),
            ),
            const SizedBox(height: 28),

            // ── Metodo di pagamento (UT.11) ─────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionLabel(tr('Metodo di pagamento')),
                IconButton(
                  tooltip: _editingPayment
                      ? tr('Blocca campo')
                      : tr('Modifica campo'),
                  icon: _savingPayment
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryGreen,
                          ),
                        )
                      : Icon(
                          _editingPayment ? Icons.check : Icons.edit_outlined,
                          color: AppTheme.primaryGreen,
                        ),
                  onPressed: _savingPayment
                      ? null
                      : () {
                          if (_editingPayment) {
                            _savePayment();
                          } else {
                            // Non riproporre il PAN mascherato salvato: si
                            // riparte da un campo numero vuoto (UT.11).
                            _number.clear();
                            setState(() => _editingPayment = true);
                          }
                        },
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_editingPayment)
              _buildPaymentForm()
            else
              _buildPaymentSummary(),
          ],
        ),
      );
    });
  }

   Riepilogo del metodo di pagamento salvato (numero mascherato). UT.11.
  Widget _buildPaymentSummary() {
    return ValueListenableBuilder<String>(
      valueListenable: ProfileStore.cardNumber,
      builder: (context, number, _) {
        final hasCard = number.trim().isNotEmpty;
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: hasCard
              ? Row(
                  children: [
                    const Icon(
                      Icons.credit_card,
                      color: AppTheme.accentBrown,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _maskCard(number),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${ProfileStore.cardHolder.value}  ·  ${tr('Scadenza')} ${ProfileStore.cardExpiry.value}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    const Icon(
                      Icons.credit_card_off_outlined,
                      color: AppTheme.textGrey,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        tr('Nessun metodo di pagamento registrato.'),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

   Modulo di inserimento/modifica del metodo di pagamento. UT.11.
  Widget _buildPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _holder,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: tr('Intestatario'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _number,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
          ],
          decoration: InputDecoration(
            labelText: tr('Numero carta'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _expiry,
                keyboardType: TextInputType.datetime,
                inputFormatters: [LengthLimitingTextInputFormatter(5)],
                decoration: InputDecoration(
                  labelText: tr('Scadenza (MM/AA)'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                controller: _cvv,
                keyboardType: TextInputType.number,
                obscureText: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: InputDecoration(
                  labelText: tr('CVV'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _billing,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: tr('Indirizzo di fatturazione'),
            helperText: tr('Deve coincidere con la residenza del profilo.'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _savePayment,
          child: Text(tr('Salva Modifiche')),
        ),
      ],
    );
  }
}

 Etichetta di sezione in maiuscoletto, coerente con le altre schermate.

### `class _DocumentCard`
Card di un documento KYC: anteprima/stato + azioni carica/vedi/rimuovi.

### File: `screens\settings_screen.dart`

### `class SettingsScreen`
@brief Schermata Impostazioni dell'app utente.

 Raccoglie le impostazioni principali di un'app per mezzi a noleggio:
 lingua (IIN-7), notifiche (IIN-19), privacy/posizione (IIN-16), sicurezza
 (IIN-5) e informazioni. Per scelta di progetto NON e' previsto un tema
 scuro. Le preferenze sono osservate da [AppSettings] e si ridisegnano live
 al cambio lingua tramite [Translated].

### `class _SectionTitle`
Card di selezione della lingua (Italiano / English). IIN-7.
  Widget _languageCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ValueListenableBuilder<String>(
        valueListenable: appLanguage,
        builder: (context, currentLanguage, child) {
          return RadioGroup<String>(
            groupValue: currentLanguage,
            onChanged: (value) {
              if (value != null) {
                appLanguage.value = value;
              }
            },
            child: Column(
              children: [
                RadioListTile<String>(
                  title: Row(
                    children: [
                      const Text('🇮🇹', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Text(
                        tr('Italiano'),
                        style: const TextStyle(color: AppTheme.textDark),
                      ),
                    ],
                  ),
                  value: 'it',
                  activeColor: AppTheme.primaryGreen,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                RadioListTile<String>(
                  title: Row(
                    children: [
                      const Text('🇬🇧', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Text(
                        tr('English'),
                        style: const TextStyle(color: AppTheme.textDark),
                      ),
                    ],
                  ),
                  value: 'en',
                  activeColor: AppTheme.primaryGreen,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

   Mostra un avviso temporaneo per le sezioni informative non ancora pronte.
  void _showStub(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('Sezione in fase di sviluppo.')),
        backgroundColor: AppTheme.accentBrown,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

 Titolo di sezione delle impostazioni.

### `class _SettingsCard`
Contenitore-card che raggruppa più righe di impostazione.

### `class _SettingsDivider`
Divisore sottile tra righe di impostazione.

### `class _SwitchSetting`
Riga di impostazione con interruttore booleano osservabile.

### `class _NavSetting`
Riga di impostazione che apre una sotto-sezione.

### `class _InfoSetting`
Riga informativa in sola lettura (es. versione app).

### File: `screens\sos_screen.dart`

### `class SOSScreen`
Emergency SOS screen.
 UT.20 — user activates an emergency signal to communicate GPS position to rescuers.
 IIN-18 — GPS coordinates must be forwarded within 5 seconds of pressing SOS.

### `class _SOSScreenState`
@brief Repository SOS iniettabile (default singleton reale; fake nei test).
  final SosApi? repo;

   @brief Id della corsa in atto, correlata alla segnalazione (opzionale).
  final String? idCorsa;

   @brief Rilevatore di posizione iniettabile (default GPS reale; i test
   passano coordinate deterministiche per evitare il canale del plugin).
  final Future<({double lat, double lon})?> Function()? rilevaPosizione;

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

### File: `screens\splash_screen.dart`

### `class SplashScreen`
@brief Schermata di avvio animata di LEAF Mobility.

 Sequenza di caricamento minimalista e immediatamente comprensibile:
   1. il logo-ruota entra con dissolvenza + scala e poi ruota di continuo,
      come uno pneumatico che gira ("mezzo in movimento");
   2. subito sotto, il nome "Leaf Mobility" viene "scritto" lettera per
      lettera (effetto macchina da scrivere) con cursore lampeggiante;
   3. una tagline appare in dissolvenza a testo completato;
   4. al termine dell'attesa l'app naviga alla schermata di login.

### File: `screens\subscription_manager_screen.dart`

### `class SubscriptionManagerScreen`
@brief Gestione abbonamenti: stato reale + acquisto + storico (UT.18/UT.21).

 Carica gli abbonamenti dell'utente da `GET /profilo/abbonamenti` e mostra
 quello attivo (piano, scadenza, percentuale residua). In assenza di rete
 degrada con un avviso (IIN-6). Il repository profilo è iniettabile nei test.

### `class _SubscriptionManagerScreenState`
@brief Crea la schermata; il repository profilo è iniettabile nei test.
  const SubscriptionManagerScreen({super.key, ProfiloApi? profilo})
    : _profilo = profilo;

  final ProfiloApi? _profilo;

  @override
  State<SubscriptionManagerScreen> createState() =>
      _SubscriptionManagerScreenState();
}

### `class _CardMessaggio`
Carica gli abbonamenti dell'utente dal backend (UT.18/UT.21).
  Future<void> _carica() async {
    setState(() => _caricamento = true);
    try {
      final elenco = await _profilo.abbonamenti();
      if (!mounted) return;
      setState(() {
        _abbonamenti = elenco;
        _caricamento = false;
        _offline = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _caricamento = false;
        _offline = true;
      });
    }
  }

   Abbonamento attivo corrente, o il più recente, o null se nessuno.
  Map<String, dynamic>? get _attivo {
    for (final a in _abbonamenti) {
      if (a['stato'] == 'attivo') return a;
    }
    return _abbonamenti.isEmpty ? null : _abbonamenti.first;
  }

   Nome commerciale del piano dal catalogo client a partire dall'id.
  String _nomePiano(String? idPiano) {
    for (final p in kPianiAbbonamento) {
      if (p.idPiano == idPiano) return p.titolo;
    }
    return idPiano ?? '—';
  }

   Frazione residua [0..1] dell'abbonamento. Preferisce la quota a **token**
   (decrementata dagli utilizzi, punto 8): la percentuale cala a ogni corsa.
   Se l'abbonamento non porta i token, ripiega sulla durata temporale.
  double _frazioneResidua(Map<String, dynamic> abb) {
    final inclusi = (abb['token_inclusi'] as num?)?.toInt() ?? 0;
    if (inclusi > 0) {
      final residui = (abb['token_residui'] as num?)?.toInt() ?? 0;
      return (residui / inclusi).clamp(0.0, 1.0);
    }
    final inizio = DateTime.tryParse('${abb['data_inizio'] ?? ''}');
    final fine = DateTime.tryParse('${abb['data_fine'] ?? ''}');
    if (inizio == null || fine == null) return 0;
    final totale = fine.difference(inizio).inSeconds;
    if (totale <= 0) return 0;
    final residuo = fine.difference(DateTime.now()).inSeconds;
    return (residuo / totale).clamp(0.0, 1.0);
  }

   Etichetta dei token residui se l'abbonamento li prevede, altrimenti null.
  String? _tokenResiduiLabel(Map<String, dynamic> abb) {
    final inclusi = (abb['token_inclusi'] as num?)?.toInt() ?? 0;
    if (inclusi <= 0) return null;
    final residui = (abb['token_residui'] as num?)?.toInt() ?? 0;
    return '$residui / $inclusi ${tr('token')}';
  }

   Giorni residui (>= 0) dell'abbonamento dato.
  int _giorniResidui(Map<String, dynamic> abb) {
    final fine = DateTime.tryParse('${abb['data_fine'] ?? ''}');
    if (fine == null) return 0;
    final giorni = fine.difference(DateTime.now()).inDays;
    return giorni < 0 ? 0 : giorni;
  }

   Apre l'acquisto di un nuovo abbonamento e ricarica al ritorno.
  Future<void> _acquista() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const BuySubscriptionScreen()),
    );
    await _carica();
  }

   Mostra lo storico degli acquisti (tutti gli abbonamenti).
  void _mostraStorico() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.backgroundBeige,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Translated((context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Storico acquisti'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGreen,
                  ),
                ),
                const SizedBox(height: 12),
                if (_abbonamenti.isEmpty)
                  Text(
                    tr('Nessun acquisto registrato.'),
                    style: const TextStyle(color: AppTheme.textGrey),
                  )
                else
                  ..._abbonamenti.map(
                    (a) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.receipt_long_outlined,
                        color: AppTheme.accentBrown,
                      ),
                      title: Text(_nomePiano(a['id_piano'] as String?)),
                      subtitle: Text(
                        '${tr('Scade il')} ${_dataBreve(a['data_fine'])}',
                      ),
                      trailing: Text(
                        '${((a['prezzo_cent'] as num?) ?? 0) / 100} €',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkGreen,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

   Data ISO → `gg/mm/aaaa` (o '—' se non valida).
  String _dataBreve(Object? iso) {
    final d = DateTime.tryParse('$iso');
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundBeige,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  tr('Il tuo abbonamento'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGreen,
                  ),
                ),
                const SizedBox(height: 24),
                if (_caricamento)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  _buildStato(),
                const SizedBox(height: 32),
                Text(
                  tr('Opzioni'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGreen,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: const Icon(
                    Icons.add_shopping_cart,
                    color: AppTheme.primaryGreen,
                  ),
                  title: Text(tr('Acquista nuovo abbonamento')),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textGrey,
                  ),
                  onTap: _acquista,
                ),
                const SizedBox(height: 12),
                ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: const Icon(
                    Icons.history,
                    color: AppTheme.accentBrown,
                  ),
                  title: Text(tr('Storico acquisti')),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textGrey,
                  ),
                  onTap: _mostraStorico,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

   Card di stato: abbonamento attivo, nessuno o avviso offline (IIN-6).
  Widget _buildStato() {
    if (_offline) {
      return _CardMessaggio(
        icona: Icons.cloud_off_outlined,
        testo: tr('Stato abbonamento non disponibile offline.'),
      );
    }
    final attivo = _attivo;
    if (attivo == null) {
      return _CardMessaggio(
        icona: Icons.card_membership_outlined,
        testo: tr('Nessun abbonamento attivo.'),
      );
    }
    final frazione = _frazioneResidua(attivo);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nomePiano(attivo['id_piano'] as String?),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    attivo['stato'] == 'attivo'
                        ? tr('Abbonamento attivo')
                        : tr('Abbonamento scaduto'),
                    style: const TextStyle(color: AppTheme.textGrey),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${tr('Scade il')} ${_dataBreve(attivo['data_fine'])}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.accentBrown,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(frazione * 100).round()}%',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: Colors.amber.shade700,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr('Rimanente'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_giorniResidui(attivo)} ${tr('giorni')}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.amber.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_tokenResiduiLabel(attivo) != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _tokenResiduiLabel(attivo)!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

 Card informativa con icona e messaggio (stato vuoto/offline).

### File: `screens\support_screen.dart`

### `class SupportScreen`
@brief Schermata di assistenza utente con invio feedback/segnalazioni. UT.09.

 Raccoglie tre blocchi coerenti con l'estetica minimalista dell'app:
   1. contatti diretti (email/telefono, mock in attesa del Business Tier);
   2. domande frequenti (FAQ) come pannelli espandibili;
   3. modulo di invio feedback/segnalazione con tipo richiesta, valutazione
      a stelle e messaggio.

 L'invio della segnalazione Ã¨ cablato al Business Tier: chiama
 `POST /api/v1/assistenza` tramite [AssistenzaApi] con stati loading/errore
 (riusa `stato_vista.dart`). Il repository Ã¨ iniettabile per i test.

### `enum _RequestType`
@brief Crea la schermata di assistenza.
   @param assistenza Repository di assistenza iniettabile (default reale).
  const SupportScreen({super.key, this.assistenza});

   Repository di assistenza usato per inviare la segnalazione (UT.09).
   Se null si usa l'istanza condivisa [assistenzaRepository]; fittizio nei test.
  final AssistenzaApi? assistenza;

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

 Tipologia della richiesta inviata dall'utente.

### `class _SectionLabel`
Tipo di richiesta attualmente selezionato.
  _RequestType _type = _RequestType.feedback;

   Valutazione a stelle (0â€“5) dell'esperienza.
  int _rating = 0;

   Controller del messaggio della segnalazione.
  final TextEditingController _messageController = TextEditingController();

   Stato dell'invio della segnalazione (loading/pronto), riusa [StatoCaricamento].
  StatoCaricamento _statoInvio = StatoCaricamento.pronto;

   Repository di assistenza effettivo (iniettabile nei test).
  AssistenzaApi get _assistenza => widget.assistenza ?? assistenzaRepository;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

   Etichetta localizzata del tipo di richiesta.
  String _labelFor(_RequestType t) {
    switch (t) {
      case _RequestType.feedback:
        return tr('Feedback');
      case _RequestType.report:
        return tr('Segnalazione');
      case _RequestType.suggestion:
        return tr('Suggerimento');
    }
  }

   @brief Mostra uno snackbar coerente con l'estetica minimalista.
   @param testo Messaggio da mostrare.
   @param colore Colore di sfondo (verde = successo, marrone = avviso/errore).
  void _mostraSnack(String testo, Color colore) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(testo),
        backgroundColor: colore,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

   @brief Valida il messaggio e invia la segnalazione al Business Tier. UT.09.
  
   Costruisce oggetto (dal tipo richiesta) e messaggio (con eventuale
   valutazione a stelle) e chiama `POST /api/v1/assistenza`. Durante l'invio
   il pulsante mostra lo stato di caricamento; in caso di errore mostra il
   messaggio di dominio del backend ([LeafApiException]).
  Future<void> _submit() async {
    if (_statoInvio == StatoCaricamento.caricamento) return;
    if (_messageController.text.trim().isEmpty) {
      _mostraSnack(
        tr('Inserisci un messaggio prima di inviare.'),
        AppTheme.accentBrown,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    final oggetto = _labelFor(_type);
    final messaggio = _rating > 0
        ? '${tr('Valutazione')}: $_rating/5\n${_messageController.text.trim()}'
        : _messageController.text.trim();
    setState(() => _statoInvio = StatoCaricamento.caricamento);
    try {
      await _assistenza.apri(oggetto, messaggio);
      if (!mounted) return;
      setState(() {
        _statoInvio = StatoCaricamento.pronto;
        _messageController.clear();
        _rating = 0;
        _type = _RequestType.feedback;
      });
      _mostraSnack(
        tr('Grazie! La tua segnalazione Ã¨ stata inviata.'),
        AppTheme.primaryGreen,
      );
    } catch (errore) {
      if (!mounted) return;
      setState(() => _statoInvio = StatoCaricamento.pronto);
      final messaggioErrore = errore is LeafApiException
          ? errore.messaggio
          : tr('Qualcosa Ã¨ andato storto');
      _mostraSnack(messaggioErrore, AppTheme.accentBrown);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundBeige,
        appBar: AppBar(
          title: Text(
            tr('Assistenza'),
            style: const TextStyle(color: AppTheme.darkGreen),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Text(
              tr('Come possiamo aiutarti?'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGreen,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tr(
                'Contattaci o inviaci un feedback: il nostro team ti risponderÃ  al piÃ¹ presto.',
              ),
              style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
            ),
            const SizedBox(height: 24),

            // â”€â”€ Direct contacts â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _SectionLabel(tr('Contatti diretti')),
            const SizedBox(height: 10),
            _ContactTile(
              icon: Icons.phone_outlined,
              title: tr('Chiama il supporto'),
              subtitle: '+39 080 123 4567',
            ),
            const SizedBox(height: 10),
            _ContactTile(
              icon: Icons.mail_outline,
              title: tr('Scrivici una email'),
              subtitle: 'support@leafmobility.example.com',
            ),
            const SizedBox(height: 28),

            // â”€â”€ FAQ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            // Sezione dedicata: barra di ricerca + domande piÃ¹ comuni (UT.09).
            _SectionLabel(tr('Domande frequenti')),
            const SizedBox(height: 10),
            _NavTile(
              icon: Icons.quiz_outlined,
              title: tr('Domande frequenti'),
              subtitle: tr('Cerca tra le domande piÃ¹ comuni'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FaqScreen()),
              ),
            ),
            const SizedBox(height: 28),

            // â”€â”€ Feedback / report form â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _SectionLabel(tr('Invia feedback o segnalazione')),
            const SizedBox(height: 14),
            Text(
              tr('Tipo di richiesta'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _RequestType.values.map((t) {
                final selected = t == _type;
                return ChoiceChip(
                  label: Text(_labelFor(t)),
                  selected: selected,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppTheme.textDark,
                  ),
                  backgroundColor: Colors.white,
                  selectedColor: AppTheme.primaryGreen,
                  side: BorderSide(
                    color: selected ? AppTheme.primaryGreen : Colors.black12,
                  ),
                  onSelected: (_) => setState(() => _type = t),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Star rating â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Text(
              tr('Come valuti la tua esperienza?'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: List.generate(5, (i) {
                final filled = i < _rating;
                return IconButton(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  constraints: const BoxConstraints(),
                  iconSize: 32,
                  icon: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: filled ? AppTheme.primaryGreen : AppTheme.textGrey,
                  ),
                  onPressed: () => setState(() => _rating = i + 1),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Message â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Text(
              tr('Il tuo messaggio'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: tr(
                  'Descrivi il tuo feedback o il problema riscontratoâ€¦',
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.primaryGreen),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _statoInvio == StatoCaricamento.caricamento
                  ? null
                  : _submit,
              icon: _statoInvio == StatoCaricamento.caricamento
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(
                _statoInvio == StatoCaricamento.caricamento
                    ? tr('Invioâ€¦')
                    : tr('Invia'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                tr('Tempo di risposta stimato: entro 24 ore.'),
                style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
              ),
            ),
          ],
        ),
      );
    });
  }
}

 Etichetta di sezione in maiuscoletto, coerente con le altre schermate.

### `class _ContactTile`
Riga di contatto diretto (telefono / email), mock in attesa del server.

### `class _NavTile`
Riga di navigazione verso una sezione dedicata (es. FAQ).

### File: `screens\trip_detail_screen.dart`

### `class TripDetailScreen`
Detail screen for a single past trip. UT.17 (storico corse).

 Opened from the Home tab history strip and from the full history list.
 Shows the ride characteristics (route, time, duration, distance), the
 vehicle used and the cost breakdown, plus the star rating (UT.16).

### `class _RateTripDialog`
The trip whose details are displayed.
  final TripEntry trip;

   Repository corse iniettabile (default reale; fittizio nei test).
  final CorseApi? corse;

  const TripDetailScreen({required this.trip, super.key, this.corse});

   Material icon representing the vehicle type used for the trip.
  IconData get _vehicleIcon {
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

   Average speed of the trip in km/h (defensive against zero duration).
  double get _avgSpeed => trip.durationMinutes == 0
      ? 0
      : trip.distanceKm / trip.durationMinutes * 60;

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${tr('Corsa')} ${trip.id}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Vehicle hero ─────────────────────────────────────────────
              Card(
                elevation: 0,
                color: AppTheme.primaryGreen.withAlpha(18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      Icon(
                        _vehicleIcon,
                        size: 64,
                        color: AppTheme.primaryGreen,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        trip.vehicleType,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${trip.date} · ${trip.time}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Route ────────────────────────────────────────────────────
              _SectionLabel(tr('Percorso')),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                color: AppTheme.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RoutePoint(
                        icon: Icons.trip_origin,
                        color: AppTheme.primaryGreen,
                        label: trip.from,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 8,
                          top: 4,
                          bottom: 4,
                        ),
                        child: Container(
                          width: 2,
                          height: 16,
                          color: Colors.black12,
                        ),
                      ),
                      _RoutePoint(
                        icon: Icons.location_on,
                        color: Colors.red,
                        label: trip.to,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Trip stats ───────────────────────────────────────────────
              _SectionLabel(tr('Dettagli corsa')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.schedule_outlined,
                      label: tr('Durata'),
                      value: '${trip.durationMinutes} ${tr('min')}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.straighten_outlined,
                      label: tr('Distanza'),
                      value: '${trip.distanceKm} km',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.speed_outlined,
                      label: tr('Velocità media'),
                      value: '${_avgSpeed.toStringAsFixed(0)} km/h',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.eco_outlined,
                      label: tr('CO₂ risparmiata'),
                      value:
                          '${(trip.distanceKm * 0.12).toStringAsFixed(2)} kg',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Cost ─────────────────────────────────────────────────────
              _SectionLabel(tr('Importo addebitato')),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          color: AppTheme.accentBrown,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          tr('Totale corsa'),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${trip.cost.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Invoice export (UT.25) ───────────────────────────────────
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => InvoiceScreen(trip: trip),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.download_outlined,
                  color: AppTheme.accentBrown,
                ),
                label: Text(
                  tr('Esporta fattura'),
                  style: const TextStyle(color: AppTheme.accentBrown),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.accentBrown),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),

              // ── Rate this trip (UT.16) ───────────────────────────────────
              OutlinedButton.icon(
                onPressed: () => _showRateDialog(context),
                icon: const Icon(Icons.star_outline, color: AppTheme.primaryGreen),
                label: Text(
                  tr('Valuta corsa'),
                  style: const TextStyle(color: AppTheme.primaryGreen),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryGreen),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),

              // ── Report this trip (UT.09) ─────────────────────────────────
              OutlinedButton.icon(
                onPressed: () => _showReportDialog(context),
                icon: const Icon(Icons.flag_outlined, color: Colors.red),
                label: Text(
                  tr('Segnala corsa'),
                  style: const TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

   Apre il modulo di segnalazione di un problema sulla corsa. UT.09.
  
   Invio simulato (snackbar di conferma) finche' il Business Tier
   `gestore_assistenza_ticket` non sara' disponibile, coerentemente con la
   schermata Assistenza.
  void _showReportDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => _ReportTripDialog(tripId: trip.id),
    );
  }

   Apre il dialogo di valutazione a stelle della corsa conclusa. UT.16.
  void _showRateDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) =>
          _RateTripDialog(tripId: trip.id, corse: corse ?? corseRepository),
    );
  }
}

 Dialogo di valutazione a stelle (1–5) di una corsa conclusa. UT.16.

### `class _RateTripDialogState`
Identificativo della corsa da valutare.
  final String tripId;

   Repository corse per inviare la valutazione (`POST /corse/{id}/valutazione`).
  final CorseApi corse;

  const _RateTripDialog({required this.tripId, required this.corse});

  @override
  State<_RateTripDialog> createState() => _RateTripDialogState();
}

### `class _ReportTripDialog`
Dialogo di segnalazione di una corsa: descrizione del problema + invio. UT.09.

### `class _ReportTripDialogState`
Identificativo della corsa segnalata.
  final String tripId;

  const _ReportTripDialog({required this.tripId});

  @override
  State<_ReportTripDialog> createState() => _ReportTripDialogState();
}

### File: `screens\vehicle_detail_screen.dart`

### `enum VehicleType`
Vehicle type constants — shared across detail and search screens.

### `bool richiedePatente`
@brief Indica se il tipo di mezzo richiede la patente (auto/moto, punto 6, UT.22.2).

### `bool patenteMancante`
@brief True se l'utente non ha la patente caricata ma il mezzo la richiede (punto 6).

### `VehicleType vehicleTypeDaApi`
@brief Mappa il discriminante `tipo_mezzo` del server sull'enum [VehicleType].
 @param tipo Discriminante grezzo (ebike/ecar/emotorbike/monopattino).
 @return Il [VehicleType] corrispondente (scooter come default).

### `const List`
Mezzi disponibili nei dintorni (mock condiviso fino al `gestore_flotta`).

 Esposto come elenco pubblico cosi' da poter essere riusato sia dalla home
 che dalla tab "Prenota" senza duplicare i dati di mock. UT.01, UT.05.

### `class VehicleData`
Vehicle data model used by SearchScreen and VehicleDetailScreen.

### `class VehicleDetailScreen`
Id del documento mezzo lato server (Firestore), per prenotazione/avvio
   corsa (UT.02/UT.10). Null per i dati di riserva mock (path locale offline).
  final String? docId;

  const VehicleData({
    required this.id,
    required this.type,
    required this.batteryPercent,
    required this.rangeKm,
    required this.distanceMeters,
    this.status = 'Disponibile',
    this.docId,
  });

   @brief Costruisce un [VehicleData] da un documento mezzo della API (UT.01/UT.05).
   @param doc Documento `mezzi` grezzo (`_id`, `codice_identificativo`, `tipo_mezzo`…).
   @param distanceMeters Distanza stimata dall'utente in metri (default 0).
   @return Il modello di vista con `docId` valorizzato per la prenotazione.
  factory VehicleData.daApi(Map<String, dynamic> doc, {int distanceMeters = 0}) {
    return VehicleData(
      id: '${doc['codice_identificativo'] ?? doc['_id'] ?? ''}',
      type: _tipoDaApi('${doc['tipo_mezzo'] ?? ''}'),
      batteryPercent: (doc['livello_batteria_pct'] ?? 0) as int,
      rangeKm: ((doc['autonomia_km'] ?? 0) as num).round(),
      distanceMeters: distanceMeters,
      docId: doc['_id']?.toString(),
    );
  }

   Mappa il discriminante `tipo_mezzo` del server sull'enum di vista.
  static VehicleType _tipoDaApi(String tipo) {
    switch (tipo) {
      case 'ebike':
        return VehicleType.bike;
      case 'ecar':
        return VehicleType.car;
      case 'emotorbike':
        return VehicleType.emoto;
      default:
        return VehicleType.scooter;
    }
  }

  String get typeLabel {
    switch (type) {
      case VehicleType.scooter:
        return 'Scooter Elettrico';
      case VehicleType.bike:
        return 'E-Bike';
      case VehicleType.car:
        return 'Auto Elettrica';
      case VehicleType.emoto:
        return 'E-Moto';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case VehicleType.scooter:
        return Icons.electric_scooter;
      case VehicleType.bike:
        return Icons.pedal_bike;
      case VehicleType.car:
        return Icons.directions_car;
      case VehicleType.emoto:
        return Icons.electric_moped;
    }
  }

  Color get typeColor {
    switch (type) {
      case VehicleType.scooter:
        return const Color(0xFF388E3C);
      case VehicleType.bike:
        return const Color(0xFF0097A7);
      case VehicleType.car:
        return const Color(0xFFE65100);
      case VehicleType.emoto:
        return const Color(0xFF1565C0);
    }
  }
}

 Vehicle detail screen — shows all user-visible characteristics.
 UT.05 (filter/view characteristics), UT.06 (wait time estimate),
 UT.10 (unlock stub), UT.02 (booking stub).

### `class _UnlockButton`
Repository corse iniettabile per l'avvio corsa (default reale; test).
  final CorseApi? corse;

  const VehicleDetailScreen({required this.vehicle, super.key, this.corse});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(vehicle.typeLabel)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero vehicle card ────────────────────────────────────────
            Card(
              elevation: 0,
              color: vehicle.typeColor.withAlpha(18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(vehicle.typeIcon, size: 72, color: vehicle.typeColor),
                    const SizedBox(height: 12),
                    Text(
                      vehicle.id,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _StatusBadge(vehicle.status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Battery ──────────────────────────────────────────────────
            _SectionTitle(tr('Batteria')),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  vehicle.batteryPercent > 30
                      ? Icons.battery_charging_full
                      : Icons.battery_alert,
                  color: vehicle.batteryPercent > 30
                      ? AppTheme.primaryGreen
                      : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: vehicle.batteryPercent / 100,
                      minHeight: 12,
                      backgroundColor: Colors.black12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        vehicle.batteryPercent > 30
                            ? AppTheme.primaryGreen
                            : Colors.orange,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${vehicle.batteryPercent}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Stats grid ───────────────────────────────────────────────
            _SectionTitle(tr('Caratteristiche')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.route,
                    label: tr('Autonomia'),
                    value: '~${vehicle.rangeKm} km',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.near_me_outlined,
                    label: tr('Distanza da te'),
                    value: vehicle.distanceMeters < 1000
                        ? '${vehicle.distanceMeters} m'
                        : '${(vehicle.distanceMeters / 1000).toStringAsFixed(1)} km',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.timer_outlined,
                    // UT.06 — estimated wait time
                    label: tr('Attesa stimata'),
                    value: vehicle.distanceMeters < 300
                        ? '< 2 ${tr('min')}'
                        : '~${(vehicle.distanceMeters / 80).ceil()} ${tr('min')}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.euro_outlined,
                    // UT.03 — cost estimation (stub)
                    label: tr('Tariffa'),
                    value: _tariffLabel(vehicle.type),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Actions ──────────────────────────────────────────────────
            // Avviso patente per auto/moto elettriche senza patente (punto 6).
            if (patenteMancante(vehicle.type)) ...[
              _AvvisoPatente(),
              const SizedBox(height: 12),
            ],
            // UT.02 — booking
            ElevatedButton.icon(
              onPressed: () {
                if (patenteMancante(vehicle.type)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        tr('Carica la patente per noleggiare auto o moto elettriche.'),
                      ),
                      backgroundColor: const Color(0xFFC62828),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingScreen(vehicle: vehicle),
                  ),
                );
              },
              icon: const Icon(Icons.event_available_outlined),
              label: Text(tr('Prenota mezzo')),
              style: ElevatedButton.styleFrom(
                backgroundColor: vehicle.typeColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            // UT.10 — sblocco mezzo / avvio corsa
            _UnlockButton(vehicle: vehicle, corse: corse ?? corseRepository),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (r) => false,
              ),
              icon: const Icon(Icons.map_outlined, color: AppTheme.accentBrown),
              label: Text(
                tr('Vedi su mappa'),
                style: const TextStyle(color: AppTheme.accentBrown),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _tariffLabel(VehicleType t) {
    switch (t) {
      case VehicleType.scooter:
        return '0.25 €/min';
      case VehicleType.bike:
        return '0.15 €/min';
      case VehicleType.car:
        return '0.45 €/min';
      case VehicleType.emoto:
        return '0.30 €/min';
    }
  }
}

 @brief Pulsante "Sblocca con QR" che avvia la corsa sul backend (UT.10).

 Con un `docId` reale invia `corse.avvia(docId)` mostrando lo stato di
 caricamento ed eventuali errori di dominio; senza `docId` (dati di riserva
 mock) mantiene il comportamento dimostrativo "in sviluppo".

### `class _UnlockButtonState`
Veicolo da sbloccare.
  final VehicleData vehicle;

   Repository corse usato per l'avvio.
  final CorseApi corse;

  @override
  State<_UnlockButton> createState() => _UnlockButtonState();
}

### `class _AvvisoPatente`
Avvio corsa in corso (disabilita il pulsante e mostra lo spinner).
  bool _avvio = false;

   Avvia la corsa sul backend, o mostra il messaggio dimostrativo sui mock.
  Future<void> _sblocca() async {
    if (_avvio) return;
    // Punto 6: auto e moto elettriche non avviabili senza patente caricata.
    if (patenteMancante(widget.vehicle.type)) {
      _mostra(
        tr('Carica la patente per noleggiare auto o moto elettriche.'),
        const Color(0xFFC62828),
      );
      return;
    }
    final docId = widget.vehicle.docId;
    if (docId == null || docId.isEmpty) {
      _mostra(tr('Sblocco mezzo… (funzione in sviluppo)'), AppTheme.accentBrown);
      return;
    }
    setState(() => _avvio = true);
    try {
      final dati = await widget.corse.avvia(docId);
      // Registra la corsa attiva per abilitare pausa/riprendi (UT.12).
      final idCorsa = dati['id_corsa']?.toString();
      if (idCorsa != null && idCorsa.isNotEmpty) {
        startActiveTrip(
          idCorsa: idCorsa,
          vehicleId: widget.vehicle.id,
          vehicleType: widget.vehicle.type,
        );
      }
      if (!mounted) return;
      _mostra(tr('Mezzo sbloccato — corsa avviata'), AppTheme.primaryGreen);
    } on LeafApiException catch (e) {
      if (!mounted) return;
      _mostra(e.messaggio, const Color(0xFFC62828));
    } finally {
      if (mounted) setState(() => _avvio = false);
    }
  }

   Mostra un riscontro all'utente tramite SnackBar.
  void _mostra(String messaggio, Color colore) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(messaggio),
        backgroundColor: colore,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _avvio ? null : _sblocca,
      icon: _avvio
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: widget.vehicle.typeColor,
              ),
            )
          : const Icon(Icons.qr_code_scanner),
      label: Text(tr('Sblocca con QR')),
      style: OutlinedButton.styleFrom(
        foregroundColor: widget.vehicle.typeColor,
        side: BorderSide(color: widget.vehicle.typeColor),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

 Banner che avvisa l'utente che il mezzo richiede la patente (punto 6, UT.22.2).

### File: `widgets\drawer_menu.dart`

### `class DrawerMenu`
Main navigation drawer. Menu items preserve exact labels, icons and routes.

### File: `widgets\stato_vista.dart`

### `enum StatoCaricamento`
@brief Stato di una vista che dipende da una chiamata di rete.

 Modella in modo uniforme i casi previsti dalla FASE 2.B (cablaggio client):
 caricamento, errore (con possibilità di riprovare), assenza di dati ed esito
 positivo. Usato dai widget [VistaCaricamento]/[VistaErrore]/[VistaVuota] e dal
 caricatore [CaricatoreVista]. Alto contrasto richiesto da IIN-2.

### `class VistaCaricamento`
Richiesta in corso.
  caricamento,

   Richiesta fallita (rete o servizio non disponibile).
  errore,

   Richiesta riuscita ma nessun dato da mostrare.
  vuoto,

   Richiesta riuscita con dati disponibili.
  pronto,
}

 @brief Indicatore di caricamento centrato con messaggio opzionale (IIN-2).

### `class VistaErrore`
@brief Crea l'indicatore di caricamento.
   @param messaggio Testo opzionale sotto lo spinner.
  const VistaCaricamento({super.key, this.messaggio});

   Messaggio mostrato sotto lo spinner, o null per il default localizzato.
  final String? messaggio;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryGreen),
          const SizedBox(height: 16),
          Text(
            messaggio ?? tr('Caricamento…'),
            style: const TextStyle(fontSize: 15, color: AppTheme.textGrey),
          ),
        ],
      ),
    );
  }
}

 @brief Stato di errore ad alto contrasto con pulsante "Riprova" (IIN-2).

 Riconosce gli errori di rete/servizio: se l'eccezione è una
 [LeafApiException] senza codice HTTP, suggerisce un problema di connessione
 (offline, IIN-6); altrimenti mostra il messaggio di dominio del backend.

### `class VistaVuota`
@brief Crea lo stato di errore.
   @param messaggio Messaggio di errore leggibile.
   @param onRiprova Callback del pulsante "Riprova" (null = pulsante assente).
   @param offline true per mostrare l'icona/copy di assenza connessione.
  const VistaErrore({
    super.key,
    required this.messaggio,
    this.onRiprova,
    this.offline = false,
  });

   Messaggio di errore mostrato all'utente.
  final String messaggio;

   Azione di ripristino; se null, il pulsante non viene mostrato.
  final VoidCallback? onRiprova;

   Indica un errore di connettività (cambia icona e titolo).
  final bool offline;

   @brief Costruisce lo stato di errore a partire da un'eccezione.
   @param errore Eccezione catturata (tipicamente [LeafApiException]).
   @param onRiprova Callback del pulsante "Riprova".
   @return Un [VistaErrore] con messaggio e modalità offline derivati.
  factory VistaErrore.da(Object errore, {VoidCallback? onRiprova}) {
    final offline = errore is LeafApiException && errore.codice == null;
    final messaggio = errore is LeafApiException
        ? errore.messaggio
        : tr('Qualcosa è andato storto');
    return VistaErrore(
      messaggio: offline ? tr('Sei offline. Controlla la connessione.') : messaggio,
      onRiprova: onRiprova,
      offline: offline,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              offline ? Icons.wifi_off : Icons.error_outline,
              size: 64,
              color: const Color(0xFFC62828),
            ),
            const SizedBox(height: 20),
            Text(
              offline ? tr('Sei offline. Controlla la connessione.') : tr('Qualcosa è andato storto'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              messaggio,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppTheme.textGrey),
            ),
            if (onRiprova != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRiprova,
                icon: const Icon(Icons.refresh),
                label: Text(tr('Riprova')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

 @brief Stato "nessun dato" neutro con icona, titolo e sottotitolo (IIN-2).

### `class CaricatoreVista`
@brief Crea lo stato vuoto.
   @param titolo Titolo principale.
   @param sottotitolo Testo esplicativo opzionale.
   @param icona Icona mostrata in cima (default: contenitore vuoto).
  const VistaVuota({
    super.key,
    required this.titolo,
    this.sottotitolo,
    this.icona = Icons.inbox_outlined,
  });

   Titolo principale dello stato vuoto.
  final String titolo;

   Sottotitolo esplicativo opzionale.
  final String? sottotitolo;

   Icona mostrata sopra il titolo.
  final IconData icona;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icona, size: 64, color: AppTheme.textGrey),
            const SizedBox(height: 20),
            Text(
              titolo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            if (sottotitolo != null) ...[
              const SizedBox(height: 8),
              Text(
                sottotitolo!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: AppTheme.textGrey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

 @brief Carica un [Future] e ne rende lo stato in modo uniforme.

 Centralizza il ciclo caricamento→errore(retry)→vuoto→dati così che le
 schermate cablate ai repository non duplichino la stessa logica. Espone una
 `key` di ricarica interna per il pulsante "Riprova" senza richiedere alle
 viste chiamanti di gestire manualmente lo stato.

 @tparam T Tipo del dato prodotto dalla chiamata.

### `class _CaricatoreVistaState`
@brief Crea il caricatore di vista.
   @param carica Funzione che avvia la chiamata e ritorna il dato.
   @param costruisci Builder del contenuto in caso di esito positivo.
   @param vuotoSe Predicato che indica quando il dato è "vuoto" (opzionale).
   @param vistaVuota Widget mostrato quando [vuotoSe] è vero (opzionale).
   @param messaggioCaricamento Testo opzionale durante il caricamento.
  const CaricatoreVista({
    super.key,
    required this.carica,
    required this.costruisci,
    this.vuotoSe,
    this.vistaVuota,
    this.messaggioCaricamento,
  });

   Funzione asincrona che produce il dato da mostrare.
  final Future<T> Function() carica;

   Builder del contenuto in caso di successo.
  final Widget Function(BuildContext context, T dati) costruisci;

   Predicato di "vuoto" sul dato ottenuto; se null, mai vuoto.
  final bool Function(T dati)? vuotoSe;

   Vista da mostrare quando il dato è vuoto; se null, usa [costruisci].
  final Widget? vistaVuota;

   Messaggio opzionale durante il caricamento.
  final String? messaggioCaricamento;

  @override
  State<CaricatoreVista<T>> createState() => _CaricatoreVistaState<T>();
}

