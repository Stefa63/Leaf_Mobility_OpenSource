# Documentazione Doxygen — Web Dashboard

**Progetto:** LEAF Mobility — Web Dashboard (Flutter Web)  
**Percorso sorgente:** `client/web_dashboard/lib/`  
**Generata il:** 04/08/2026
**Ruoli:** Operatore del Servizio (OP) · Amministrazione Pubblica (AP)

---

## Indice

1. [Entry Point — main.dart](#1-entry-point--maindart)
2. [Theme — theme.dart](#2-theme--themedart)
3. [Session — session.dart](#3-session--sessiondart)
4. [Internazionalizzazione — l10n.dart](#4-internazionalizzazione--l10ndart)
5. [Data Layer](#5-data-layer)
    - 5.1 [fleet_data.dart](#51-fleet_datadart)
    - 5.2 [notifications_store.dart](#52-notifications_storedart)
6. [Screens](#6-screens)
    - 6.1 [LoginScreen](#61-loginscreen)
    - 6.2 [HomeRouter](#62-homerouter)
    - 6.3 [OpDashboard](#63-opdashboard)
    - 6.4 [ApDashboard](#64-apdashboard)
    - 6.5 [TicketManagement](#65-ticketmanagement)
    - 6.6 [SupportQueue](#66-supportqueue)
    - 6.7 [DiscountManagement](#67-discountmanagement)
    - 6.8 [UserAdmin](#68-useradmin)
    - 6.9 [GeofencingScreen](#69-geofencingscreen)
    - 6.10 [EventReportingScreen](#610-eventreportingscreen)
    - 6.11 [ReportsScreen](#611-reportsscreen)
    - 6.12 [ProfileScreen](#612-profilescreen)
    - 6.13 [NotificationsScreen](#613-notificationsscreen)
    - 6.14 [SettingsScreen](#614-settingsscreen)
7. [Widgets](#7-widgets)
    - 7.1 [DashboardShell](#71-dashboardshell)
    - 7.2 [QuickActionButton](#72-quickactionbutton)
    - 7.3 [AlarmTile](#73-alarmtile)
    - 7.4 [SectionHeader](#74-sectionheader)
    - 7.5 [PanelCard](#75-panelcard)
    - 7.6 [MetricCard](#76-metriccard)
    - 7.7 [MetricRow](#77-metricrow)
    - 7.8 [BigStat](#78-bigstat)
    - 7.9 [GoogleCityMap](#79-googlecitymap)
    - 7.10 [CityMap (schematica)](#710-citymap-schematica)
    - 7.11 [LeafLogo](#711-leaflogo)
    - 7.12 [LangToggle](#712-langtoggle)
    - 7.13 [SectionPlaceholder](#713-sectionplaceholder)

---

## 1. Entry Point — `main.dart`

**File:** `lib/main.dart`

### `main()`
```
void main()
```
Punto di ingresso della WebDashboard (Flutter Web) per OP e AP.

### `LeafDashboardApp`
```
/// @brief Applicazione WebDashboard LEAF Mobility.
///
/// Accesso protetto da MFA (IIN-9) tramite un'unica schermata di login per OP e
/// AP; dopo l'accesso il [HomeRouter] mostra la console del ruolo scelto.
/// Internazionalizzazione IT/EN live via [appLanguage] (IIN-7).
class LeafDashboardApp extends StatelessWidget
```

Configura il `MaterialApp` con il tema `AppTheme.lightTheme`, le route (`/login` → LoginScreen, `/home` → HomeRouter) e l'ascolto di `appLanguage` per il cambio lingua live.

---

## 2. Theme — `theme.dart`

**File:** `lib/theme.dart`

### `AppTheme`
```
/// @brief Palette e tema della WebDashboard LEAF Mobility.
///
/// Riusa la stessa identità cromatica di [AppMobileUtente] (verde minimalista
/// su beige) per coerenza visiva tra i client, estendendola con gli accenti di
/// ruolo (OP / AP) e i colori di stato della flotta usati dalle dashboard
/// operative. IIN-2 (usabilità, alto contrasto).
class AppTheme
```

#### Palette base (allineata ad AppMobileUtente)

| Costante | Valore | Descrizione |
|---|---|---|
| `backgroundBeige` | `#FCFBF7` | Sfondo chiaro principale |
| `primaryGreen` | `#4CAF50` | Verde primario del brand |
| `darkGreen` | `#2E7D32` | Verde scuro per titoli |
| `accentBrown` | `#795548` | Accento marrone |
| `textDark` | `#333333` | Testo principale scuro |
| `textGrey` | `#6E6E6E` | Testo secondario grigio |
| `surfaceColor` | `#F1F8F1` | Superficie verde chiaro desaturato |

#### Accenti di ruolo

| Costante | Valore | Descrizione |
|---|---|---|
| `opAccent` | `#1565C0` | Operatore del Servizio (OP): blu operativo / tattico |
| `apAccent` | `#00897B` | Amministrazione Pubblica (AP): teal istituzionale |

#### Colori di stato flotta (condivisi OP)

| Costante | Valore | Descrizione |
|---|---|---|
| `statusAvailable` | `#43A047` | Mezzo disponibile |
| `statusInUse` | `#1E88E5` | Mezzo in uso |
| `statusMaintenance` | `#E53935` | Mezzo in manutenzione |
| `statusLowBattery` | `#F9A825` | Batteria critica (< 15%) |

#### Colori semantici allarmi

| Costante | Valore | Descrizione |
|---|---|---|
| `alarmCritical` | `#D32F2F` | Allarme critico (SOS, fuori area) |
| `alarmWarning` | `#F57C00` | Avviso (sotto soglia, logistica) |
| `alarmInfo` | `#FBC02D` | Informazione |

#### Mappa schematica

| Costante | Valore | Descrizione |
|---|---|---|
| `mapLand` | `#EDEFE9` | Terreno |
| `mapSea` | `#D9E8EC` | Mare |
| `mapRoad` | `#FFFFFF` | Strade |
| `mapDistrict` | `#E3E7DD` | Quartieri |

#### `lightTheme` → `ThemeData`
Tema chiaro con tipografia Google Fonts Inter, Material 3, card con ombra leggera, pulsanti arrotondati.

---

## 3. Session — `session.dart`

**File:** `lib/session.dart`

### `DashboardRole`
```
/// Ruoli con accesso alla WebDashboard (RBAC). IIN-5.
enum DashboardRole { operator, publicAdmin }
```

### `Session`
```
/// @brief Stato di sessione della dashboard (mock pre-backend).
///
/// Conserva ruolo ed email scelti in fase di login. Finché l'`api_gateway_
/// sicurezza` non sarà disponibile, l'autenticazione è simulata: nessun
/// token JWT reale viene emesso. Semplice contenitore osservabile, niente MVC.
class Session
```

| Campo | Tipo | Descrizione |
|---|---|---|
| `role` | `DashboardRole` | Ruolo attivo corrente |
| `email` | `String` | Email dell'utente autenticato |

#### `isPublicAdmin` → `bool`
True quando il ruolo attivo è Amministrazione Pubblica.

---

## 4. Internazionalizzazione — `l10n.dart`

**File:** `lib/l10n.dart`

### `appLanguage`
```
final ValueNotifier<String> appLanguage = ValueNotifier<String>('it')
```
Notifier osservabile della lingua corrente (`'it'` o `'en'`).

### `Translated`
```
/// @brief Ricostruisce il proprio sottoalbero al cambio lingua.
class Translated extends StatelessWidget
```
Stesso pattern della versione mobile. Avvolgendo il contenuto della schermata in `Translated`, la vista si ridisegna live al cambio lingua senza introdurre dipendenze né pattern MVC.

### `tr(String key)` → `String`
```
/// @brief Traduce [key] nella lingua attiva.
/// @param key Testo sorgente in italiano (chiave del dizionario).
/// @return Traduzione inglese se [appLanguage] == 'en', altrimenti l'italiano.
```

---

## 5. Data Layer

### 5.1 `fleet_data.dart`

**File:** `lib/data/fleet_data.dart`

#### `VehicleType`
```
/// Tipologia di veicolo condivisa (allineata ai filtri di AppMobileUtente).
enum VehicleType { scooter, bike, car, emoto }
```

#### `VehicleStatus`
```
/// Stato operativo del mezzo visibile nelle dashboard OP. OP.20.
enum VehicleStatus { available, inUse, maintenance, lowBattery }
```

#### `Vehicle`
```
/// @brief Veicolo della flotta condivisa LEAF Mobility.
///
/// Le coordinate replicano 1:1 quelle mostrate sulla mappa di
/// [AppMobileUtente] (map_tab.dart): la vista di OP/AP coincide così con la
/// vista utente, come richiesto. UT.01 / OP.01 / AP.10.
class Vehicle
```

| Campo | Tipo | Descrizione |
|---|---|---|
| `id` | `String` | Codice identificativo del veicolo (es. `'SC-001'`) |
| `type` | `VehicleType` | Tipologia di veicolo |
| `lat` | `double` | Latitudine (WGS 84) |
| `lng` | `double` | Longitudine (WGS 84) |
| `battery` | `int` | Livello batteria (0–100) |
| `status` | `VehicleStatus` | Stato operativo corrente |

#### `ChargingStation`
```
/// @brief Stazione di ricarica condivisa. UT.14 / OP.22.
class ChargingStation
```

| Campo | Tipo | Descrizione |
|---|---|---|
| `id` | `String` | Codice stazione |
| `lat` / `lng` | `double` | Coordinate |
| `slots` | `int` | Numero di slot di ricarica |
| `area` | `String` | Nome dell'area |

#### `TplStop`
```
/// @brief Fermata del sistema TPL (trasporto pubblico locale).
///
/// Integrata nativamente nei dati mappa (vincolo architetturale: sistemaTPL
/// non è un modulo separato).
class TplStop
```

| Campo | Tipo | Descrizione |
|---|---|---|
| `id` | `String` | Codice fermata |
| `lat` / `lng` | `double` | Coordinate |
| `name` | `String` | Nome della fermata |

#### `MapBounds`
```
/// @brief Riquadro geografico per la proiezione lat/lng → coordinate schermo.
///
/// Bounds centrati su Bari, scelti per contenere l'intera flotta mostrata in
/// [AppMobileUtente]. La proiezione è equirettangolare (sufficiente alla
/// scala cittadina) con il nord in alto.
class MapBounds
```

##### `project(double lat, double lng)` → `Offset`
```
/// @brief Proietta una coordinata geografica in frazioni [0,1] dell'area.
/// @param lat Latitudine.
/// @param lng Longitudine.
/// @return Offset con dx/dy in [0,1] (origine in alto a sinistra).
```

#### `FleetData`
```
/// @brief Sorgente dati condivisa della flotta (mock pre-backend).
///
/// Finché il Business Tier (`gestore_flotta`) non sarà disponibile, queste
/// strutture statiche alimentano sia la mappa che le metriche. Le posizioni
/// coincidono con quelle di [AppMobileUtente]; gli stati operativi sono
/// aggiunti per le viste OP. OP.01 / OP.03 / OP.20 / AP.03 / AP.10.
class FleetData
```

**Dati statici:**
- `vehicles` — 32 veicoli (11 scooter, 9 bici, 7 auto, 6 e-moto)
- `charging` — 14 stazioni di ricarica
- `tplStops` — 5 fermate del trasporto pubblico locale

**Metodi aggregati:**
- `activeCount` — Mezzi operativi (disponibili o in uso) = "Attivi" delle dashboard. AP.03.
- `activePct` — Percentuale di mezzi attivi sul totale, arrotondata.
- `lowBatteryPct` — Percentuale di mezzi con batteria critica.
- `maintenancePct` — Percentuale di mezzi in manutenzione.

#### Funzioni helper di presentazione

| Funzione | Doxygen | Descrizione |
|---|---|---|
| `vehicleTypeColor(VehicleType)` | `/// @brief Colore associato alla tipologia di mezzo (coerente con i marker).` | Scooter = verde, Bici = cyan, Auto = arancio, E-Moto = blu |
| `vehicleTypeIcon(VehicleType)` | `/// @brief Icona Material associata alla tipologia di mezzo.` | Scooter → electric_scooter, ecc. |
| `vehicleTypeLabel(VehicleType)` | `/// @brief Etichetta (chiave i18n) della tipologia di mezzo.` | Chiave per la traduzione |
| `vehicleStatusColor(VehicleStatus)` | `/// @brief Colore associato allo stato operativo del mezzo.` | Available = verde, InUse = blu, ecc. |
| `vehicleStatusLabel(VehicleStatus)` | `/// @brief Etichetta (chiave i18n) dello stato operativo del mezzo.` | Chiave per la traduzione |

---

### 5.2 `notifications_store.dart`

**File:** `lib/data/notifications_store.dart`

#### `NotifLevel`
```
/// Severità visiva della notifica.
enum NotifLevel { critical, warning, info }
```

#### `DashNotification`
```
/// @brief Voce del centro notifiche (mock pre-backend).
class DashNotification
```

| Campo | Tipo | Descrizione |
|---|---|---|
| `icon` | `IconData` | Icona della notifica |
| `level` | `NotifLevel` | Severità visiva |
| `title` | `String` | Titolo della notifica |
| `body` | `String` | Corpo del messaggio |
| `time` | `String` | Timestamp leggibile |
| `read` | `bool` | Stato di lettura |

#### `NotificationsStore`
```
/// @brief Sorgente osservabile condivisa delle notifiche (mock pre-backend).
///
/// Stesso pattern osservabile di [appLanguage]: un solo elenco e un contatore
/// di revisione condivisi tra la campana della top bar (badge "non lette") e il
/// centro notifiche, così che leggere una notifica aggiorni subito il badge —
/// niente MVC. Le notifiche reali arriveranno via push dal server (IIN-19).
/// Il seed dipende dal ruolo attivo ([Session]) e viene ricalcolato se il ruolo
/// cambia (logout/login).
class NotificationsStore
```

##### `revision` → `ValueNotifier<int>`
Incrementato ad ogni mutazione: gli ascoltatori si ridisegnano.

##### `items` → `List<DashNotification>`
Elenco corrente; (ri)seminato al primo accesso o al cambio di ruolo.

##### `unreadCount` → `int`
Numero di notifiche non lette (alimenta il badge della campana).

##### `markRead(DashNotification n)` → `void`
```
/// @brief Marca una notifica come letta e notifica gli ascoltatori.
/// @param n Notifica da marcare.
```

##### `markAllRead()` → `void`
```
/// @brief Marca tutte le notifiche come lette (azzera il badge).
```

---

## 6. Screens

### 6.1 LoginScreen

**File:** `lib/screens/login_screen.dart`

```
/// @brief Schermata di accesso unica per OP e AP.
///
/// La stessa interfaccia serve entrambe le figure: la scelta del [DashboardRole]
/// determina quale console di lavoro verrà mostrata dopo l'accesso. Finché
/// l'`api_gateway_sicurezza` non è implementato, qualunque credenziale viene
/// accettata; il codice OTP (inviato via email) è richiesto come secondo
/// fattore. Premendo Invio su un qualsiasi campo si tenta l'accesso.
class LoginScreen extends StatefulWidget
```

**Campi:**
- `_emailCtrl` — Controller del campo email
- `_passwordCtrl` — Controller del campo password
- `_otpCtrl` — Controller del campo OTP (6 cifre, IIN-9 MFA)
- `_role` — Ruolo selezionato (`DashboardRole`)

**Metodi:**
- `_submit()` — Valida l'OTP (6 cifre), imposta la sessione e naviga alla home.
- `_roleSelector()` — Selettore di ruolo (OP / AP) con animazione di selezione.

---

### 6.2 HomeRouter

**File:** `lib/screens/home_router.dart`

```
/// @brief Instrada alla console corretta in base al ruolo di [Session].
///
/// Stessa pagina di login per OP e AP; dopo l'accesso la dashboard di lavoro
/// differisce: OP → [OpDashboard], AP → [ApDashboard]. RBAC (IIN-5).
class HomeRouter extends StatelessWidget
```

---

### 6.3 OpDashboard

**File:** `lib/screens/op_dashboard.dart`

```
/// @brief Console dell'Operatore del Servizio (OP).
///
/// Vista operativa/tattica: coda allarmi real-time (SOS, fuori area, logistica),
/// mappa flotta Google con stato telemetrico per mezzo (OP.01/OP.20), filtri
/// rapidi e azioni operative (sblocco/blocco remoto, ticket, sospensione utente,
/// sconti). Gestione ticket, profilo e notifiche in sezioni dedicate.
class OpDashboard extends StatelessWidget
```

**Sezioni del menu laterale:**

| Icona | Etichetta | Schermata |
|---|---|---|
| `support_agent` | Centro Operativo | `_OpHome` (home) |
| `map_outlined` | Mappa Flotta Live | `OpFleetMap` |
| `build_outlined` | Gestione Ticket | `TicketManagement` |
| `forum_outlined` | Coda Assistenza | `SupportQueue` |
| `percent_outlined` | Gestione Sconti | `DiscountManagement` |
| `manage_accounts` | Gestione Utenti/AP | `UserAdmin` |

**Azioni rapide del Centro Operativo:**
- Sblocco/Blocco Remoto (OP.11)
- Crea Ticket Riparazione
- Sospendi Utente
- Configura Nuovo Sconto

#### `showRemoteLockDialog(BuildContext context)` → `Future<void>`
```
/// @brief Dialog di sblocco/blocco motore remoto di un mezzo (OP.11).
///
/// Self-contained: seleziona un mezzo dalla flotta e invia il comando. Il
/// comando reale passerà per `gateway_iot` quando il backend sarà disponibile.
```

#### `OpFleetMap`
```
/// @brief Mappa flotta Google con filtri di stato rapidi (OP.01 / OP.20).
///
/// Estratta come widget riusabile: usata sia nella home (Centro Operativo) che
/// nella sezione "Mappa Flotta Live". Cartografia reale via [GoogleCityMap].
class OpFleetMap extends StatefulWidget
```

**Filtri disponibili:**
- **Stato:** Mezzi in Uso, Disponibili, In Manutenzione, Batteria < 15%
- **Tipo di veicolo:** Scooter, Bici, Auto, E-Moto
- **Layer mappa:** Ricarica, Trasporto Pubblico (TPL)

---

### 6.4 ApDashboard

**File:** `lib/screens/ap_dashboard.dart`

```
/// @brief Console dell'Amministrazione Pubblica (AP).
///
/// Vista orientata alla pianificazione: metriche aggregate e anonime
/// (IIN-15), heatmap di utilizzo (AP.05), distribuzione flotta in tempo reale
/// (AP.10), strumenti di geofencing/eventi e reportistica. I dati di mobilità
/// mostrati sono già aggregati: nessun dato riconducibile al singolo cittadino.
class ApDashboard extends StatelessWidget
```

**Sezioni del menu laterale:**

| Icona | Etichetta | Schermata |
|---|---|---|
| `dashboard_outlined` | Home Dashboard | `_ApHome` |
| `map_outlined` | Mappa & Heatmap | `GoogleCityMap` (con heatmap) |
| `block_outlined` | Gestione Geofencing | `GeofencingScreen` |
| `warning_amber` | Segnala Eventi | `EventReportingScreen` |
| `description_outlined` | Reportistica | `ReportsScreen` |

**Metriche della Home Dashboard:**
- **Flotta Operativa:** Attivi, Scarichi, Manutenzione (percentuali)
- **Impatto Ecologico (Mese):** CO₂ risparmiata, km percorsi
- **Distribuzione Aree:** Domanda per quartiere (Centro, Ovest, Est)

**Pannello Rapido — Interventi:**
- Inserisci Cantiere/Interruzione → Gestione Geofencing
- Definisci Slow-Zone → Gestione Geofencing
- Notifica Grande Evento → Segnala Eventi
- Estrai Report (PDF/CSV) → Reportistica

---

### 6.5 TicketManagement

**File:** `lib/screens/ticket_management.dart`

#### `TicketType`
```
/// Tipo di ticket: guasto mezzo o richiesta di assistenza utente. OP.06/OP.19.
enum TicketType { guasto, assistenza }
```

#### `TicketStatus`
```
/// Stato di lavorazione del ticket. OP.16/OP.19.
enum TicketStatus { daAssegnare, inCorso, terminato }
```

#### `TicketPriority`
```
/// Priorità dell'intervento.
enum TicketPriority { alta, media, bassa }
```

#### `Ticket`
```
/// @brief Ticket di intervento/assistenza (mock pre-backend).
class Ticket
```

| Campo | Tipo | Descrizione |
|---|---|---|
| `id` | `String` | Codice ticket progressivo (es. `'TK-0044'`) |
| `type` | `TicketType` | Tipo: guasto o assistenza |
| `vehicleId` | `String` | Codice del mezzo interessato |
| `subject` | `String` | Oggetto dell'intervento |
| `priority` | `TicketPriority` | Priorità (alta, media, bassa) |
| `date` | `DateTime` | Data di apertura |
| `status` | `TicketStatus` | Stato di lavorazione |
| `technician` | `String?` | Tecnico assegnato, o null |

#### `TicketManagement`
```
/// @brief Schermata di gestione ticket dell'Operatore.
///
/// Elenco filtrabile per tipo (guasto/assistenza), data e stato
/// (da assegnare / in corso / terminato). Consente l'assegnazione a un tecnico
/// e la chiusura. Copre OP.03 (lista guasti), OP.06 (lista filtrabile),
/// OP.16/OP.19 (compila, assegna e traccia i ticket). Pre-backend i dati sono
/// mock; le operazioni reali passeranno per `gestore_assistenza_ticket`.
class TicketManagement extends StatefulWidget
```

#### `_CreateTicketForm`
```
/// @brief Dialog di compilazione di un nuovo ticket di intervento/assistenza.
///
/// Copre OP.16 / OP.19: l'Operatore seleziona il tipo (guasto mezzo o assistenza
/// utente), indica il codice del mezzo e l'oggetto, imposta la priorità e può
/// assegnare subito un tecnico. Se un tecnico viene scelto il ticket nasce
/// "In corso", altrimenti "Da assegnare". Widget con stato dedicato: possiede i
/// controller dei campi e li dispone in [dispose] (eseguito quando la route è
/// realmente rimossa), evitando il rilascio anticipato che corromperebbe
/// l'albero alla chiusura del dialog. Ritorna il [Ticket] creato via
/// `Navigator.pop`, oppure null se annullato.
class _CreateTicketForm extends StatefulWidget
```

---

### 6.6 SupportQueue

**File:** `lib/screens/support_queue.dart`

#### `SupportChannel`
```
/// Canale da cui proviene la richiesta di assistenza.
enum SupportChannel { chat, email, telefono }
```

#### `SupportStatus`
```
/// Stato di lavorazione della richiesta. OP.08.
enum SupportStatus { nuova, inCarico, risolta }
```

#### `SupportRequest`
```
/// @brief Richiesta di assistenza utente in coda (mock pre-backend).
class SupportRequest
```

| Campo | Tipo | Descrizione |
|---|---|---|
| `id` | `String` | Codice richiesta (es. `'AS-2051'`) |
| `user` | `String` | Identificativo utente |
| `channel` | `SupportChannel` | Canale di provenienza |
| `subject` | `String` | Oggetto della richiesta |
| `lastMessage` | `String` | Ultimo messaggio in conversazione |
| `time` | `String` | Timestamp leggibile |
| `status` | `SupportStatus` | Stato di lavorazione |
| `operator` | `String?` | Operatore che ha preso in carico |

#### `SupportQueue`
```
/// @brief Coda centralizzata delle richieste di assistenza (OP.08).
///
/// L'Operatore vede le richieste in entrata dai diversi canali, le prende in
/// carico, risponde e le chiude. Filtro per stato (nuove / in carico / risolte).
/// Pre-backend i dati sono mock; le richieste reali e le risposte passeranno per
/// `gestore_assistenza_ticket`.
class SupportQueue extends StatefulWidget
```

---

### 6.7 DiscountManagement

**File:** `lib/screens/discount_management.dart`

#### `DiscountType`
```
/// Tipo di incentivo configurabile dall'Operatore.
/// OP.09 (credito bonus per rilascio in area), OP.15 (sconto geografico).
enum DiscountType { parkingBonus, geoDiscount }
```

#### `requestDiscountCreateOnOpen()` → `void`
```
/// @brief Segnala alla [DiscountManagement] di aprire il form di creazione
/// non appena viene montata (consumata una sola volta).
```

#### `DiscountRule`
```
/// @brief Regola di sconto/incentivo geografico (mock pre-backend).
class DiscountRule
```

| Campo | Tipo | Descrizione |
|---|---|---|
| `id` | `String` | Codice regola progressivo (es. `'SC-01'`) |
| `type` | `DiscountType` | Tipo di incentivo |
| `name` | `String` | Nome della regola |
| `area` | `String` | Area geografica di applicazione |
| `value` | `String` | Valore dell'incentivo (es. `'+0,50 € credito'`, `'-20% avvio corsa'`) |
| `period` | `String` | Periodo di validità (es. `'Lun–Ven 07:00–10:00'`) |
| `active` | `bool` | Stato di attivazione |

#### `DiscountManagement`
```
/// @brief Gestione Sconti dell'Operatore (OP.09 / OP.15).
///
/// Configura crediti bonus per i rilasci nelle aree di parcheggio designate
/// (OP.09) e sconti percentuali programmati su perimetri geografici per
/// incentivare la domanda nelle zone meno redditizie (OP.15). Pre-backend le
/// regole restano in memoria; il salvataggio reale passerà per `gestore_corse`
/// / `gestore_geofencing` e sarà propagato ai mezzi entro 30s (IIN-21).
class DiscountManagement extends StatefulWidget
```

#### `_CreateDiscountForm`
```
/// @brief Dialog di creazione di una regola di sconto (OP.09 / OP.15).
///
/// Widget con stato dedicato: possiede i controller dei campi e li dispone in
/// [dispose] (eseguito quando la route è realmente rimossa), evitando il
/// rilascio anticipato che corrompeva l'albero alla chiusura del dialog.
/// Ritorna la [DiscountRule] creata via `Navigator.pop`, oppure null se annullato.
class _CreateDiscountForm extends StatefulWidget
```

---

### 6.8 UserAdmin

**File:** `lib/screens/user_admin.dart`

#### `UserStatus`
```
/// Stato dell'account di un utente del servizio. OP.10 / OP.18.
enum UserStatus { attivo, sospeso }
```

#### `ApStatus`
```
/// Stato dell'account di un Amministratore Pubblico. OP.17 (provisioning).
enum ApStatus { attivo, primoAccesso }
```

#### `ManagedUser`
```
/// @brief Account utente gestibile dall'Operatore (mock pre-backend).
class ManagedUser
```

| Campo | Tipo | Descrizione |
|---|---|---|
| `id` | `String` | Identificativo utente (es. `'U-1029'`) |
| `name` | `String` | Nome completo |
| `email` | `String` | Email |
| `status` | `UserStatus` | Stato dell'account |
| `note` | `String` | Motivazione sospensione |

#### `ApAccount`
```
/// @brief Account di Amministrazione Pubblica creato dall'Operatore.
class ApAccount
```

| Campo | Tipo | Descrizione |
|---|---|---|
| `id` | `String` | Codice account AP (es. `'AP-01'`) |
| `ente` | `String` | Nome dell'ente pubblico |
| `email` | `String` | Email istituzionale |
| `status` | `ApStatus` | Stato dell'account |

#### `UserAdmin`
```
/// @brief Gestione Utenti e Amministratori Pubblici (OP.10 / OP.17 / OP.18).
///
/// Due viste commutabili: gli account utente (sospensione per violazioni — OP.10
/// — e riattivazione manuale — OP.18) e gli account di Amministrazione Pubblica,
/// creati esclusivamente dall'Operatore tramite provisioning (OP.17, niente
/// registrazioni pubbliche; primo accesso con cambio password obbligatorio,
/// IIN-12). Pre-backend i dati sono mock; le operazioni reali passeranno per
/// `gestore_profili_ekyc` / `api_gateway_sicurezza`.
class UserAdmin extends StatefulWidget
```

---

### 6.9 GeofencingScreen

**File:** `lib/screens/geofencing_screen.dart`

#### `GeoAreaType`
```
/// Tipologia di area di geofencing tracciabile dall'Amministrazione Pubblica.
/// AP.04 (cantiere), AP.06 (interdizione totale), AP.08 (slow-zone).
enum GeoAreaType { operativa, interdetta, slowZone, cantiere }
```

#### `GeoArea`
```
/// @brief Area di geofencing disegnata sulla mappa (mock pre-backend).
class GeoArea
```

| Campo | Tipo | Descrizione |
|---|---|---|
| `id` | `String` | Codice area (es. `'GF-01'`) |
| `name` | `String` | Nome descrittivo |
| `type` | `GeoAreaType` | Tipologia di area |
| `points` | `List<LatLng>` | Vertici del poligono |
| `speedLimit` | `int?` | Limite di velocità in km/h (solo slow-zone) |

#### `GeofencingScreen`
```
/// @brief Schermata di geofencing dell'Amministrazione Pubblica.
///
/// Permette di disegnare sulla mappa Google aree operative e non operative,
/// perimetri di interdizione totale (AP.06), slow-zone con limite di velocità
/// (AP.08) e cantieri/lavori temporanei (AP.04). Si tocca la mappa per aggiungere
/// i vertici e si completa il poligono. Pre-backend le aree restano in memoria
/// locale; il salvataggio reale passerà per `gestore_geofencing` e sarà
/// propagato ai mezzi entro 30s (IIN-21).
class GeofencingScreen extends StatefulWidget
```

---

### 6.10 EventReportingScreen

**File:** `lib/screens/event_reporting_screen.dart`

#### `CityEventType`
```
/// Tipologia di evento cittadino segnalabile dall'Amministrazione Pubblica.
/// AP.09 (grande evento), AP.04 (cantiere/lavori), interruzione di servizio.
enum CityEventType { grandeEvento, cantiere, interruzione }
```

#### `CityEvent`
```
/// @brief Evento cittadino segnalato a sistema (mock pre-backend).
class CityEvent
```

| Campo | Tipo | Descrizione |
|---|---|---|
| `id` | `String` | Codice evento (es. `'EV-01'`) |
| `name` | `String` | Nome dell'evento |
| `type` | `CityEventType` | Tipologia |
| `date` | `DateTime` | Data dell'evento |
| `area` | `String` | Area/quartiere interessato |
| `location` | `LatLng?` | Posizione sulla mappa |
| `note` | `String` | Note aggiuntive |

#### `EventReportingScreen`
```
/// @brief Schermata "Segnala Eventi" dell'Amministrazione Pubblica.
///
/// Consente di inserire a sistema le date e le coordinate dei grandi eventi
/// cittadini, dei cantieri/lavori temporanei e delle interruzioni di servizio,
/// così da notificare gli operatori sulle aree che richiederanno un
/// potenziamento o una limitazione della flotta. Si tocca la mappa per
/// posizionare l'evento. Pre-backend gli eventi restano in memoria; la
/// notifica reale agli operatori passerà per `gestore_attività` /
/// `motore_analitica`.
class EventReportingScreen extends StatefulWidget
```

---

### 6.11 ReportsScreen

**File:** `lib/screens/reports_screen.dart`

#### `ReportPeriod`
```
/// Periodo di aggregazione dei report.
enum ReportPeriod { settimana, mese, trimestre }
```

#### `ReportsScreen`
```
/// @brief Schermata "Reportistica" dell'Amministrazione Pubblica.
///
/// Presenta report periodici aggregati e anonimi sulla mobilità urbana:
/// noleggi per tipologia di mezzo, flussi orari, quota di flotta operativa vs
/// manutenzione e impatto ecologico (CO₂ risparmiata). I dati mostrati sono
/// già aggregati e non riconducibili al singolo cittadino. Pre-backend i
/// valori provengono da sorgenti statiche/derivate; l'estrazione reale e
/// l'export passeranno per `motore_analitica`.
class ReportsScreen extends StatefulWidget
```

**Report disponibili (grafici `fl_chart`):**
- **Noleggi per tipologia di mezzo** — Bar chart per Scooter, Bici, Auto, E-Moto
- **Flussi di mobilità per fascia oraria** — Bar chart (7 fasce: 00–06 fino a 21–24)
- **Flotta operativa vs manutenzione** — Pie chart (attivi, scarichi, manutenzione)
- **CO₂ risparmiata dalla flotta elettrica** — Line chart con trend ultimi 6 mesi

**Export:** Esportazione PDF e CSV (mock, in attesa di `motore_analitica`).

---

### 6.12 ProfileScreen

**File:** `lib/screens/profile_screen.dart`

```
/// @brief Schermata di gestione profilo per OP e AP.
class ProfileScreen extends StatelessWidget
```

Gestione del profilo operatore/amministratore: avatar, dati personali (nome, ruolo, email, telefono), con accento cromatico variabile in base al ruolo.

---

### 6.13 NotificationsScreen

**File:** `lib/screens/notifications_screen.dart`

```
/// @brief Centro notifiche per OP e AP.
class NotificationsScreen extends StatelessWidget
```

Centro notifiche con elenco delle notifiche dal `NotificationsStore`, marcatura come letta al tap, pulsante "Segna tutte come lette" e badge "non lette" sincronizzato live con la campana nella top bar. Le notifiche OP sono orientate all'operatività (SOS, fuori area, batteria, ticket), quelle AP alla pianificazione (report, slow-zone, soglie, eventi).

---

### 6.14 SettingsScreen

**File:** `lib/screens/settings_screen.dart`

```
/// @brief Schermata Impostazioni per OP e AP.
class SettingsScreen extends StatelessWidget
```

Impostazioni condivise per entrambi i ruoli con accento cromatico variabile (OP.opAccent / AP.apAccent). Sezioni: lingua, notifiche, sicurezza, informazioni.

---

## 7. Widgets

### 7.1 DashboardShell

**File:** `lib/widgets/dashboard_shell.dart`

#### `DashboardSection`
```
/// @brief Voce del menu laterale: icona, etichetta (chiave i18n) e contenuto.
class DashboardSection
```

| Campo | Tipo | Descrizione |
|---|---|---|
| `icon` | `IconData` | Icona della voce di menu |
| `label` | `String` | Chiave i18n dell'etichetta |
| `builder` | `WidgetBuilder` | Builder del contenuto della sezione |

#### `DashboardScope`
```
/// @brief Accesso alla navigazione dello [DashboardShell] dai discendenti.
///
/// Espone alla sottostante gerarchia (es. i pannelli rapidi nella home) il
/// cambio di sezione del menu laterale, senza introdurre pattern MVC: è un
/// semplice [InheritedWidget]. Usare [jumpTo] con l'indice o, più comodo,
/// [indexOfLabel] per risolvere l'indice dalla chiave i18n della voce di menu.
class DashboardScope extends InheritedWidget
```

##### `jumpTo(int index)` → `void`
Apre la sezione del menu laterale all'indice indicato.

##### `indexOfLabel(String label)` → `int`
Indice della sezione con la `label` data, o -1 se assente.

##### `jumpToLabel(String label)` → `void`
Risolve `label` e, se presente, apre la relativa sezione.

#### `DashboardShell`
```
/// @brief Telaio comune delle console OP/AP: top navigation bar + side menu.
///
/// La stessa impalcatura serve entrambi i ruoli; cambiano [sections], colore
/// [accent] e profilo. La tendina del profilo (in alto a destra) apre gestione
/// profilo o impostazioni; la campana apre il centro notifiche con badge "non
/// lette" alimentato live da [NotificationsStore]. Refresh metriche dichiarato a
/// 5s in barra (IIN-20).
class DashboardShell extends StatefulWidget
```

| Campo | Tipo | Descrizione |
|---|---|---|
| `accent` | `Color` | Colore accento del ruolo (OP blu / AP teal) |
| `sections` | `List<DashboardSection>` | Voci del menu laterale |
| `profileLabel` | `String` | Etichetta del profilo nella top bar |
| `profileBuilder` | `WidgetBuilder` | Builder della schermata profilo |
| `notificationsBuilder` | `WidgetBuilder` | Builder del centro notifiche |
| `settingsBuilder` | `WidgetBuilder` | Builder della schermata impostazioni |

#### `SectionPlaceholder`
```
/// @brief Segnaposto per le sezioni non ancora collegate al backend.
class SectionPlaceholder extends StatelessWidget
```

---

### 7.2 QuickActionButton

**File:** `lib/widgets/common.dart`

```
/// @brief Pulsante azione rapida dei pannelli laterali OP/AP.
///
/// Se [onPressed] è fornito esegue l'azione collegata (apertura dialog o
/// navigazione a una sezione); altrimenti mostra un feedback "in sviluppo": il
/// comando reale passerà per l'`api_gateway_sicurezza` quando il server sarà
/// disponibile.
class QuickActionButton extends StatelessWidget
```

---

### 7.3 AlarmTile

**File:** `lib/widgets/common.dart`

```
/// @brief Tile di un allarme/notifica nella coda real-time dell'Operatore.
class AlarmTile extends StatelessWidget
```

---

### 7.4 SectionHeader

**File:** `lib/widgets/common.dart`

```
/// @brief Intestazione di sezione (titolo + sottotitolo opzionale).
class SectionHeader extends StatelessWidget
```

---

### 7.5 PanelCard

**File:** `lib/widgets/common.dart`

```
/// @brief Card pannello generica con titolo e contenuto.
class PanelCard extends StatelessWidget
```

---

### 7.6 MetricCard

**File:** `lib/widgets/metric_card.dart`

```
/// @brief Card metrica della dashboard (titolo + righe valore/etichetta).
///
/// Blocco visivo riusato dalle home di OP e AP per le metriche in tempo reale
/// (refresh ≤ 5s, IIN-20). Niente logica di business: pura presentazione.
class MetricCard extends StatelessWidget
```

---

### 7.7 MetricRow

**File:** `lib/widgets/metric_card.dart`

```
/// @brief Riga "pallino colorato + etichetta + valore" per le card metrica.
class MetricRow extends StatelessWidget
```

---

### 7.8 BigStat

**File:** `lib/widgets/metric_card.dart`

```
/// @brief Grande numero con etichetta sottostante (KPI singolo).
class BigStat extends StatelessWidget
```

---

### 7.9 GoogleCityMap

**File:** `lib/widgets/google_city_map.dart`

```
/// @brief Mappa Google reale della città (Bari) per le console OP/AP.
class GoogleCityMap extends StatefulWidget
```

Mappa Google Maps integrata con marker per veicoli, stazioni di ricarica e fermate TPL, con filtri di stato e tipo. Supporta overlay poligoni (geofencing), polyline (bozze), marker aggiuntivi (eventi), heatmap di utilizzo (AP) e callback `onTap` per interazione (disegno aree/posizionamento eventi). Legenda integrata con icone per tipo veicolo e stazione.

---

### 7.10 CityMap (schematica)

**File:** `lib/widgets/city_map.dart`

```
/// @brief Mappa schematica interattiva della città (Bari).
class CityMap extends StatefulWidget
```

Fallback schematico della mappa (canvas CustomPainter) usato prima dell'integrazione di Google Maps. Disegna sfondo cartografico (quartieri, strade, mare), marker per i veicoli e heatmap di utilizzo (AP.05).

#### `_CityMapPainter`
```
/// @brief Painter dello sfondo cartografico schematico + heatmap.
class _CityMapPainter extends CustomPainter
```

---

### 7.11 LeafLogo

**File:** `lib/widgets/leaf_logo.dart`

```
/// @brief Logo ufficiale LEAF Mobility.
class LeafLogo extends StatelessWidget
```

Logo con icona foglia e wordmark opzionale "LEAF Mobility".

---

### 7.12 LangToggle

**File:** `lib/widgets/lang_toggle.dart`

```
/// @brief Selettore lingua ITA/ENG. IIN-7.
class LangToggle extends StatelessWidget
```

Toggle a chip con bandiera per la commutazione live tra italiano e inglese.

---

### 7.13 SectionPlaceholder

**File:** `lib/widgets/dashboard_shell.dart`

```
/// @brief Segnaposto per le sezioni non ancora collegate al backend.
class SectionPlaceholder extends StatelessWidget
```

Widget di stato vuoto con icona, titolo e messaggio "Sezione in sviluppo. Sarà collegata al server." per le sezioni non ancora implementate.


## 9. Doxygen Esteso (Estratto dal Codice - 04/08/2026)

### File: `l10n.dart`

### `final ValueNotifier`
Lingua attiva della dashboard (osservabile, default Italiano). IIN-7.

### `class Translated`
@brief Ricostruisce il proprio sottoalbero al cambio lingua.

 Stesso pattern osservabile adottato da [AppMobileUtente]: avvolgendo una
 vista in [Translated] i suoi testi si ridisegnano live al cambio di
 [appLanguage] senza dipendenze ne' pattern MVC. IIN-7.

### `const Map`
Builder del contenuto localizzato.
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

### `String tr`
@brief Traduce [key] nella lingua attiva.
 @param key Testo sorgente in italiano (chiave del dizionario).
 @return Traduzione inglese se [appLanguage] == 'en', altrimenti l'italiano.

### File: `main.dart`

### `void main`
Punto di ingresso della WebDashboard (Flutter Web) per OP e AP.

### `class LeafDashboardApp`
@brief Applicazione WebDashboard LEAF Mobility.

 Accesso protetto da MFA (IIN-9) tramite un'unica schermata di login per OP e
 AP; dopo l'accesso il [HomeRouter] mostra la console del ruolo scelto.
 Internazionalizzazione IT/EN live via [appLanguage] (IIN-7).

### File: `session.dart`

### `enum DashboardRole`
Ruoli con accesso alla WebDashboard (RBAC). IIN-5.

### `class Session`
@brief Stato di sessione della dashboard (mock pre-backend).

 Conserva ruolo ed email scelti in fase di login. Finche' l'`api_gateway_
 sicurezza` non sara' disponibile, l'autenticazione e' simulata: nessun
 token JWT reale viene emesso. Semplice contenitore osservabile, niente MVC.

### File: `theme.dart`

### `class AppTheme`
@brief Palette e tema della WebDashboard LEAF Mobility.

 Riusa la stessa identita' cromatica di [AppMobileUtente] (verde minimalista
 su beige) per coerenza visiva tra i client, estendendola con gli accenti di
 ruolo (OP / AP) e i colori di stato della flotta usati dalle dashboard
 operative. IIN-2 (usabilita', alto contrasto).

### File: `api\analytics_repository.dart`

### `abstract class`
@brief Contratto di accesso alle analitiche aggregate e anonime (AP.01/02/07, IIN-15).

### `class AnalyticsRepository`
@brief Aggregati di mobilità per tipo di mezzo, opzionalmente in un intervallo.
   @param dallaData Inizio intervallo ISO-8601 (opzionale).
   @param allaData Fine intervallo ISO-8601 (opzionale).
   @return Lista di aggregati per tipo (documenti grezzi della API).
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> perTipo({
    String? dallaData,
    String? allaData,
  });

   @brief Conteggio noleggi per tipologia di mezzo, anonimo (AP.01, IIN-15).
   @param dallaData Inizio intervallo ISO-8601 (opzionale).
   @param allaData Fine intervallo ISO-8601 (opzionale).
   @return Mappa `{noleggi: {tipo: conteggio}}` dal backend.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<Map<String, dynamic>> noleggiPerTipo({
    String? dallaData,
    String? allaData,
  });

   @brief Distribuzione dei noleggi per fascia oraria, anonima (AP.02, IIN-15).
   @param dallaData Inizio intervallo ISO-8601 (opzionale).
   @param allaData Fine intervallo ISO-8601 (opzionale).
   @return Mappa `{flussi: {ora: conteggio}}` dal backend.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<Map<String, dynamic>> flussiOrari({
    String? dallaData,
    String? allaData,
  });

   @brief Percentuale mezzi operativi vs manutenzione vs scarico (AP.03).
   @return Mappa `{operativi, manutenzione, scarico}` dal backend.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<Map<String, dynamic>> percentualiOperativi();

   @brief Stima della CO₂ risparmiata dalla flotta elettrica, anonima (AP.07, IIN-15).
   @param dallaData Inizio intervallo ISO-8601 (opzionale).
   @param allaData Fine intervallo ISO-8601 (opzionale).
   @return Mappa `{km_totali, co2_risparmiata_kg, km_per_tipo}` dal backend.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<Map<String, dynamic>> co2Risparmiata({
    String? dallaData,
    String? allaData,
  });
}

 @brief Implementazione di [AnalyticsApi] su `/api/v1/analitiche` via Dio (Bearer PA/OP).

### `final AnalyticsRepository`
@brief Crea il repository; il client API è iniettabile nei test.
  AnalyticsRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<List<Map<String, dynamic>>> perTipo({
    String? dallaData,
    String? allaData,
  }) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/analitiche',
        queryParameters: {'dalla_data': ?dallaData, 'alla_data': ?allaData},
      );
      final dati = ApiClient.payload(risposta);
      final aggregati = (dati['per_tipo'] as List?) ?? const [];
      return aggregati
          .map((a) => Map<String, dynamic>.from(a as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<Map<String, dynamic>> noleggiPerTipo({
    String? dallaData,
    String? allaData,
  }) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/analitiche/noleggi',
        queryParameters: {'dalla_data': ?dallaData, 'alla_data': ?allaData},
      );
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<Map<String, dynamic>> flussiOrari({
    String? dallaData,
    String? allaData,
  }) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/analitiche/flussi',
        queryParameters: {'dalla_data': ?dallaData, 'alla_data': ?allaData},
      );
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<Map<String, dynamic>> percentualiOperativi() async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/analitiche/operativi',
      );
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<Map<String, dynamic>> co2Risparmiata({
    String? dallaData,
    String? allaData,
  }) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/analitiche/co2',
        queryParameters: {'dalla_data': ?dallaData, 'alla_data': ?allaData},
      );
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

 @brief Repository analitiche condiviso (default reale; sovrascrivibile nei test).

### File: `api\api_client.dart`

### `class LeafApiException`
@brief Eccezione applicativa di rete: porta il messaggio di dominio e il codice HTTP.

 Normalizza gli errori del backend (campo `dettaglio`) e di trasporto, così che
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

 @brief Custodia cifrata del token JWT (Keychain/Keystore/Web storage) — IIN-4.

 Il token di sessione OP/PA non è mai salvato in chiaro: si appoggia
 all'archivio sicuro di piattaforma fornito da `flutter_secure_storage`.

### `class ApiClient`
@brief Crea la custodia; consente di iniettare uno storage fittizio nei test.
  TokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const String _chiave = 'leaf_jwt_web';

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

 @brief Client HTTP verso il backend LEAF: inietta il Bearer token e normalizza gli errori.

 Espone l'istanza Dio (riusabile dai repository) e la custodia del token. Un
 interceptor aggiunge automaticamente l'header `Authorization: Bearer <jwt>`
 quando un token è presente.

### `final ApiClient`
@brief Crea il client; Dio e TokenStore sono iniettabili (test).
   @param dio Istanza Dio personalizzata (opzionale).
   @param tokenStore Custodia del token personalizzata (opzionale).
  ApiClient({Dio? dio, TokenStore? tokenStore})
    : tokenStore = tokenStore ?? TokenStore(),
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

 La WebDashboard punta al backend esposto via tunnel Cloudflare sul dominio
 del progetto (`api.leafmobility.org`). Sovrascrivibile a compile-time:
 `flutter run -d chrome --dart-define=LEAF_API_BASE=...`
 (es. `http://localhost:8770/api/v1` per il runtime in locale).
library;

 @brief Base URL delle API client-facing del backend LEAF Mobility.

### `bool kAutoloadData`
@brief Abilita il caricamento automatico dei dati all'apertura delle schermate.

 True in produzione. I widget test che montano una dashboard intera (la quale
 costruisce le schermate con `autoload` di default) lo impostano a false per
 evitare chiamate di rete reali (timer pendenti); i test mirati iniettano un
 repository fittizio e lo lasciano a true.

### File: `api\areas_repository.dart`

### `abstract class`
@brief Contratto di accesso alle aree di geofencing (AP.04/06/08).

### `class AreasRepository`
@brief Elenca le aree limitate configurate.
   @param soloAttive Se true, restituisce solo le aree attive.
   @return Lista di aree (documenti grezzi della API).
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> elenco({bool soloAttive = false});

   @brief Crea una nuova area limitata.
   @param dati Definizione area (tipo, nome, poligono, limite_velocita_kmh).
   @return Id dell'area creata.
   @throws LeafApiException Su errore di rete o validazione.
  Future<String> crea(Map<String, dynamic> dati);

   @brief Elimina un'area limitata (riapertura al transito, AP.04).
   @param idArea Id dell'area da eliminare.
   @throws LeafApiException Su errore di rete.
  Future<void> elimina(String idArea);
}

 @brief Implementazione di [AreeApi] su `/api/v1/aree` via Dio (Bearer PA/OP).

### `final AreasRepository`
@brief Crea il repository; il client API è iniettabile nei test.
  AreasRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<List<Map<String, dynamic>>> elenco({bool soloAttive = false}) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/aree',
        queryParameters: {'solo_attive': soloAttive},
      );
      final dati = ApiClient.payload(risposta);
      final aree = (dati['aree'] as List?) ?? const [];
      return aree
          .map((a) => Map<String, dynamic>.from(a as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<String> crea(Map<String, dynamic> dati) async {
    try {
      final risposta = await _client.dio.post<dynamic>('/aree', data: dati);
      final payload = ApiClient.payload(risposta);
      return '${payload['id_area'] ?? ''}';
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<void> elimina(String idArea) async {
    try {
      await _client.dio.delete<dynamic>('/aree/$idArea');
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

 @brief Repository aree condiviso (default reale; sovrascrivibile nei test).

### File: `api\assistenza_repository.dart`

### `abstract class`
@brief Contratto di accesso alla coda di assistenza lato operatore (OP.08).

### `class AssistenzaRepository`
@brief Coda centralizzata delle richieste di assistenza.
   @param stato Filtro opzionale su stato (aperto/in_lavorazione/chiuso).
   @return Lista di ticket (documenti grezzi della API).
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> coda({String? stato});

   @brief Prende in carico e/o risponde a un ticket (OP.08).
   @param idTicket Id del ticket di assistenza.
   @param risposta Testo della risposta all'utente.
   @param stato Nuovo stato (aperto/in_lavorazione/chiuso).
   @throws LeafApiException Su errore di rete.
  Future<void> rispondi(
    String idTicket,
    String risposta, {
    String stato = 'in_lavorazione',
  });
}

 @brief Implementazione di [AssistenzaApi] su `/api/v1/assistenza` via Dio (Bearer OP).

### `final AssistenzaRepository`
@brief Crea il repository; il client API è iniettabile nei test.
  AssistenzaRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<List<Map<String, dynamic>>> coda({String? stato}) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/assistenza',
        queryParameters: {'stato': ?stato},
      );
      final dati = ApiClient.payload(risposta);
      final ticket = (dati['ticket'] as List?) ?? const [];
      return ticket
          .map((t) => Map<String, dynamic>.from(t as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<void> rispondi(
    String idTicket,
    String risposta, {
    String stato = 'in_lavorazione',
  }) async {
    try {
      await _client.dio.put<dynamic>(
        '/assistenza/$idTicket/risposta',
        data: {'risposta': risposta, 'stato': stato},
      );
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

 @brief Repository assistenza condiviso (default reale; sovrascrivibile nei test).

### File: `api\auth_repository.dart`

### `enum StatoAccesso`
@brief Esito di un passo di accesso OP/PA (IIN-1/9/12).

### `class EsitoAccesso`
Accesso completato: token emesso e custodito.
  ok,

   Richiesto il secondo fattore OTP (OP/PA, IIN-9 — sempre per la dashboard).
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

   @brief Identificativo account (document ID Firestore) per MFA/cambio password.
  final String? idAccount;

   @brief Ruolo RBAC dell'utente autenticato (a esito `ok`).
  final String? ruolo;

   @brief OTP restituito dal backend in simulazione (provider OTP fittizio, IIN-9).
  final String? otpSimulato;
}

 @brief Contratto di autenticazione OP/PA verso il backend (iniettabile nei test).

### `class AuthRepository`
@brief Avvia il login con credenziali (IIN-1); per OP/PA risponde `mfaRichiesta`.
  Future<EsitoAccesso> accedi(String identita, String password);

   @brief Completa il login col secondo fattore OTP (IIN-9).
  Future<EsitoAccesso> verificaMfa(String idAccount, String otp);

   @brief Richiede il reset password via email istituzionale (IIN-11/AP.12).
  Future<void> richiediReset(String identita);

   @brief Conferma il reset password con codice monouso e nuova password (IIN-11).
  
   Al successo il backend emette il token di sessione (auto-accesso): il codice
   via email funge da secondo fattore, bypassando l'OTP MFA.
   @param identita Email/username dichiarato.
   @param codice Codice monouso ricevuto via email.
   @param nuovaPassword Nuova password (validata IIN-5 lato client e server).
   @return [EsitoAccesso] con stato `ok` e ruolo se il reset è riuscito.
  Future<EsitoAccesso> confermaReset(
    String identita,
    String codice, [
    String? nuovaPassword,
  ]);

   @brief Cambia la password obbligatoria al primo accesso OP/PA (IIN-12).
   @param nuovaPassword Nuova password (validata IIN-5 lato client e server).
  Future<void> cambiaPasswordPrimoAccesso(String nuovaPassword);

   @brief Termina la sessione corrente (logout).
  Future<void> esci();
}

 @brief Implementazione di [AuthApi] sul backend `/api/v1/auth` via Dio.

### `final AuthRepository`
@brief Crea il repository; il client API è iniettabile nei test.
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
          ruolo: dati['ruolo'] as String?,
        );
      default:
        // IIN-12: dopo l'MFA il backend segnala il primo accesso col flag dedicato.
        final cambio = dati['richiede_cambio_password'] == true;
        return EsitoAccesso(
          cambio ? StatoAccesso.cambioPasswordRichiesto : StatoAccesso.ok,
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
      // Token custodito sia ad accesso completo sia al primo accesso (serve per il
      // cambio password obbligatorio IIN-12, che è una chiamata autenticata).
      if (dati['access_token'] != null) {
        await _client.tokenStore.salva(dati['access_token'] as String);
      }
      return esito;
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<EsitoAccesso> accedi(String identita, String password) {
    return _accesso(
      () => _client.dio.post<dynamic>(
        '/auth/login',
        data: {'identita': identita, 'password': password},
      ),
    );
  }

  @override
  Future<EsitoAccesso> verificaMfa(String idAccount, String otp) {
    return _accesso(
      () => _client.dio.post<dynamic>(
        '/auth/mfa',
        data: {'id_account': idAccount, 'otp': otp},
      ),
    );
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
    String codice, [
    String? nuovaPassword,
  ]) async {
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
  Future<void> cambiaPasswordPrimoAccesso(String nuovaPassword) async {
    try {
      await _client.dio.post<dynamic>(
        '/auth/password/primo-accesso',
        data: {'nuova_password': nuovaPassword},
      );
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

### File: `api\events_repository.dart`

### `abstract class`
@brief Contratto dei grandi eventi cittadini su mappa (AP.09).

### `class EventsRepository`
@brief Elenca i grandi eventi cittadini configurati.
   @return Lista di eventi (aree limitate di tipo "evento", con date e perimetro).
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> elenco();

   @brief Inserisce un evento cittadino tipizzato su mappa (AP.09/AP.04).
   @param nome Nome dell'evento.
   @param categoria Categoria (grande_evento / cantiere / interruzione).
   @param dataInizio Data di inizio (ISO-8601).
   @param dataFine Data di fine (ISO-8601).
   @param poligono Perimetro geografico come lista di coppie [lat, lon].
   @param area Area/quartiere interessato (opzionale).
   @return Id dell'evento creato.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<String> crea({
    required String nome,
    required String categoria,
    required String dataInizio,
    required String dataFine,
    required List<List<double>> poligono,
    String? area,
  });

   @brief Elimina un evento cittadino dalla mappa (AP.09).
   @param idEvento Id dell'evento (area di tipo "evento") da rimuovere.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<void> elimina(String idEvento);
}

 @brief Implementazione di [EventiApi] su `/api/v1` via Dio (Bearer PA).

### `final EventsRepository`
@brief Crea il repository; il client API è iniettabile nei test.
  EventsRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<List<Map<String, dynamic>>> elenco() async {
    try {
      final risposta = await _client.dio.get<dynamic>('/eventi');
      final dati = ApiClient.payload(risposta);
      final eventi = (dati['eventi'] as List?) ?? const [];
      return eventi
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<String> crea({
    required String nome,
    required String categoria,
    required String dataInizio,
    required String dataFine,
    required List<List<double>> poligono,
    String? area,
  }) async {
    try {
      final risposta = await _client.dio.post<dynamic>(
        '/eventi',
        data: {
          'nome': nome,
          'categoria': categoria,
          'data_inizio': dataInizio,
          'data_fine': dataFine,
          'poligono': poligono,
          if (area != null && area.isNotEmpty) 'area': area,
        },
      );
      return ApiClient.payload(risposta)['id_evento'].toString();
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<void> elimina(String idEvento) async {
    try {
      await _client.dio.delete<dynamic>('/eventi/$idEvento');
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

 @brief Repository eventi condiviso (default reale; sovrascrivibile nei test).

### File: `api\fleet_repository.dart`

### `abstract class`
@brief Contratto di accesso allo stato della flotta (OP.01/03/20, AP.03/10).

### `class FleetRepository`
@brief Elenca i mezzi della flotta, opzionalmente filtrati per stato.
   @param stato Filtro opzionale su stato operativo (es. "guasto" per OP.03).
   @return Lista di mezzi (documenti grezzi della API).
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> elenco({String? stato});

   @brief Elenca i mezzi in stato "Guasto" da ritirare (OP.03).
   @return Lista di mezzi guasti.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> mezziGuasti();

   @brief Report giornaliero dei mezzi per stato e batteria scarica (OP.13).
   @return Mappa `{per_stato, batteria_scarica, totale}`.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<Map<String, dynamic>> reportGiornaliero();

   @brief Valuta le soglie configurate e restituisce le allerte attive (OP.02/OP.22).
   @return Lista di allerte attive.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> soglieAllerte();

   @brief Imposta la soglia minima di mezzi per un'area (OP.02).
   @param idArea Id dell'area.
   @param minimo Numero minimo di mezzi richiesti.
   @return Id della soglia creata.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<String> impostaSogliaArea({
    required String idArea,
    required int minimo,
  });

   @brief Imposta la soglia di allerta batteria (OP.22).
   @param percentuale Percentuale di allerta.
   @param tipoMezzo Tipologia di mezzo (opzionale).
   @return Id della soglia creata.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<String> impostaSogliaBatteria({
    required int percentuale,
    String? tipoMezzo,
  });

   @brief Registro telemetrico di un mezzo (sblocchi, urti, anomalie, GPS) (OP.07/14).
   @param codice Codice identificativo del mezzo.
   @return Lista di eventi telemetrici.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> telemetria(String codice);

   @brief Invia il blocco motore remoto anti-spostamento a un mezzo (OP.11).
   @param codice Codice identificativo del mezzo da immobilizzare.
   @return Mappa con l'esito del comando.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<Map<String, dynamic>> bloccoMotore(String codice);

   @brief Revoca il blocco motore remoto e riabilita un mezzo (OP.11).
   @param codice Codice identificativo del mezzo da riabilitare.
   @return Mappa con l'esito del comando.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<Map<String, dynamic>> sbloccoMotore(String codice);
}

 @brief Implementazione di [FlottaApi] su `/api/v1/flotta` via Dio (Bearer OP/PA).

### `final FleetRepository`
@brief Crea il repository; il client API è iniettabile nei test.
  FleetRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<List<Map<String, dynamic>>> elenco({String? stato}) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/flotta',
        queryParameters: {'stato': ?stato},
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
  Future<List<Map<String, dynamic>>> mezziGuasti() async {
    try {
      final risposta = await _client.dio.get<dynamic>('/mezzi-guasti');
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
  Future<Map<String, dynamic>> reportGiornaliero() async {
    try {
      final risposta = await _client.dio.get<dynamic>('/flotta/report');
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> soglieAllerte() async {
    try {
      final risposta = await _client.dio.get<dynamic>('/soglie/allerte');
      final dati = ApiClient.payload(risposta);
      final allerte = (dati['allerte'] as List?) ?? const [];
      return allerte
          .map((a) => Map<String, dynamic>.from(a as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<String> impostaSogliaArea({
    required String idArea,
    required int minimo,
  }) async {
    try {
      final risposta = await _client.dio.post<dynamic>(
        '/soglie/area',
        data: {'id_area': idArea, 'minimo': minimo},
      );
      return ApiClient.payload(risposta)['id_soglia']?.toString() ?? '';
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<String> impostaSogliaBatteria({
    required int percentuale,
    String? tipoMezzo,
  }) async {
    try {
      final risposta = await _client.dio.post<dynamic>(
        '/soglie/batteria',
        data: {'percentuale': percentuale, 'tipo_mezzo': tipoMezzo},
      );
      return ApiClient.payload(risposta)['id_soglia']?.toString() ?? '';
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> telemetria(String codice) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/mezzi/$codice/telemetria',
      );
      final dati = ApiClient.payload(risposta);
      final eventi = (dati['eventi'] as List?) ?? const [];
      return eventi
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<Map<String, dynamic>> bloccoMotore(String codice) async {
    try {
      final risposta = await _client.dio.post<dynamic>(
        '/mezzi/$codice/blocco-motore',
      );
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<Map<String, dynamic>> sbloccoMotore(String codice) async {
    try {
      final risposta = await _client.dio.post<dynamic>(
        '/mezzi/$codice/sblocco-motore',
      );
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

 @brief Repository flotta condiviso (default reale; sovrascrivibile nei test).

### File: `api\maintenance_repository.dart`

### `abstract class`
@brief Contratto dei ticket di manutenzione veicoli (OP.16/OP.19).

### `class MaintenanceRepository`
@brief Elenca i ticket di manutenzione, opzionalmente filtrati per stato.
   @param stato Filtro opzionale (aperto/assegnato/chiuso).
   @return Lista di ticket di manutenzione.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> elenco({String? stato});

   @brief Elenca i tecnici manutentori assegnabili (OP.16).
   @return Lista di tecnici.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> elencoTecnici();

   @brief Crea un ticket di manutenzione per un mezzo guasto (OP.16/OP.19).
   @param idMezzo Id del mezzo guasto.
   @param descrizione Descrizione del guasto/intervento.
   @param priorita Priorità: bassa | media | alta.
   @return Id del ticket creato.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<String> crea({
    required String idMezzo,
    required String descrizione,
    String priorita = 'media',
  });

   @brief Assegna un ticket a un tecnico registrato (OP.16).
   @param idTicket Id del ticket.
   @param idTecnico Id del tecnico assegnatario.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<void> assegna(String idTicket, String idTecnico);

   @brief Chiude un ticket a intervento concluso (OP.19).
   @param idTicket Id del ticket.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<void> chiudi(String idTicket);
}

 @brief Implementazione di [ManutenzioneApi] su `/api/v1` via Dio (Bearer OP).

### `final MaintenanceRepository`
@brief Crea il repository; il client API è iniettabile nei test.
  MaintenanceRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<List<Map<String, dynamic>>> elenco({String? stato}) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/manutenzione',
        queryParameters: {'stato': ?stato},
      );
      final dati = ApiClient.payload(risposta);
      final ticket = (dati['ticket'] as List?) ?? const [];
      return ticket
          .map((t) => Map<String, dynamic>.from(t as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> elencoTecnici() async {
    try {
      final risposta = await _client.dio.get<dynamic>('/tecnici');
      final dati = ApiClient.payload(risposta);
      final tecnici = (dati['tecnici'] as List?) ?? const [];
      return tecnici
          .map((t) => Map<String, dynamic>.from(t as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<String> crea({
    required String idMezzo,
    required String descrizione,
    String priorita = 'media',
  }) async {
    try {
      final risposta = await _client.dio.post<dynamic>(
        '/manutenzione',
        data: {
          'id_mezzo': idMezzo,
          'descrizione': descrizione,
          'priorita': priorita,
        },
      );
      return ApiClient.payload(risposta)['id_ticket'].toString();
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<void> assegna(String idTicket, String idTecnico) async {
    try {
      await _client.dio.put<dynamic>(
        '/manutenzione/$idTicket/assegna',
        data: {'id_tecnico': idTecnico},
      );
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<void> chiudi(String idTicket) async {
    try {
      await _client.dio.put<dynamic>('/manutenzione/$idTicket/chiudi');
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

 @brief Repository manutenzione condiviso (default reale; sovrascrivibile nei test).

### File: `api\notifications_repository.dart`

### `abstract class`
@brief Contratto di accesso alle notifiche (UT.15/UT.19, IIN-19).

### `class NotificationsRepository`
@brief Elenca le notifiche dell'account autenticato e broadcast.
   @param soloNonLette Se true, restituisce solo le notifiche non lette.
   @return Lista di notifiche (documenti grezzi della API).
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> elenco({bool soloNonLette = false});

   @brief Marca una notifica come letta (UT.15/UT.19).
   @param idNotifica Id della notifica.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<void> segnaLetta(String idNotifica);

   @brief Pubblica una notifica broadcast di servizio (UT.19, OP/PA).
   @param titolo Titolo della notifica.
   @param messaggio Corpo della notifica.
   @param tipo Tipo della notifica (default "servizio").
   @return Id della notifica creata.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<String> crea({
    required String titolo,
    required String messaggio,
    String tipo = 'servizio',
  });
}

 @brief Implementazione di [NotificheApi] su `/api/v1/notifiche` via Dio (Bearer).

### `final NotificationsRepository`
@brief Crea il repository; il client API è iniettabile nei test.
  NotificationsRepository({ApiClient? client}) : _client = client ?? apiClient;

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

  @override
  Future<String> crea({
    required String titolo,
    required String messaggio,
    String tipo = 'servizio',
  }) async {
    try {
      final risposta = await _client.dio.post<dynamic>(
        '/notifiche',
        data: {'titolo': titolo, 'messaggio': messaggio, 'tipo': tipo},
      );
      return ApiClient.payload(risposta)['id_notifica']?.toString() ?? '';
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

 @brief Repository notifiche condiviso (default reale; sovrascrivibile nei test).

### File: `api\prenotazioni_repository.dart`

### `abstract class`
@brief Contratto delle prenotazioni lato operatore (OP.12), iniettabile nei test.

### `class PrenotazioniOpRepository`
@brief Elenca tutte le prenotazioni attive della flotta (OP.12).
   @return Lista delle prenotazioni attive (con etichetta utente risolta lato server).
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> attive();

   @brief Forza l'annullamento di una prenotazione attiva (OP.12).
   @param idPrenotazione Id della prenotazione da annullare.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<void> annulla(String idPrenotazione);
}

 @brief Implementazione di [PrenotazioniOpApi] su `/api/v1` via Dio (Bearer OP).

### `final PrenotazioniOpRepository`
@brief Crea il repository; il client API è iniettabile nei test.
  PrenotazioniOpRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<List<Map<String, dynamic>>> attive() async {
    try {
      final risposta = await _client.dio.get<dynamic>('/prenotazioni/attive');
      final dati = ApiClient.payload(risposta);
      final pren = (dati['prenotazioni'] as List?) ?? const [];
      return pren
          .map((p) => Map<String, dynamic>.from(p as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<void> annulla(String idPrenotazione) async {
    try {
      await _client.dio.post<dynamic>('/prenotazioni/$idPrenotazione/annulla-op');
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

 @brief Repository prenotazioni OP condiviso (default reale; sovrascrivibile nei test).

### File: `api\profilo_repository.dart`

### `abstract class`
@brief Contratto di accesso al profilo dell'account OP/PA autenticato (UT.21 lato dashboard).

### `class ProfiloRepository`
@brief Recupera i dati del profilo dell'account autenticato.
   @return Vista profilo (mai contenente la password hash).
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<Map<String, dynamic>> profilo();

   @brief Aggiorna i dati anagrafici del profilo (whitelist server-side).
   @param modifiche Coppie campo→valore da aggiornare (nome, cognome, telefono).
   @return Vista profilo aggiornata.
   @throws LeafApiException Su errore di rete o conflitto.
  Future<Map<String, dynamic>> aggiorna(Map<String, dynamic> modifiche);
}

 @brief Implementazione di [ProfiloApi] su `/api/v1/profilo` via Dio (Bearer).

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
}

 @brief Repository profilo condiviso (default reale; sovrascrivibile nei test).

### File: `api\promotions_repository.dart`

### `abstract class`
@brief Contratto delle promozioni e incentivi geografici (OP.09/OP.15).

### `class PromotionsRepository`
@brief Elenca le promozioni configurate, opzionalmente solo le attive.
   @param soloAttive Se true, restituisce solo le promozioni attive.
   @return Lista di promozioni.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> elenco({bool soloAttive = false});

   @brief Configura una promozione/incentivo geografico (OP.09/OP.15).
   @param tipo Tipo (sconto_percentuale/credito_bonus_parcheggio/sconto_geografico/tariffa_evento).
   @param descrizione Descrizione leggibile della promozione.
   @param valore Valore numerico opzionale (es. percentuale di sconto).
   @param idArea Id dell'area che circoscrive l'ambito geografico (opzionale).
   @return Id della promozione creata.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<String> crea({
    required String tipo,
    required String descrizione,
    num? valore,
    String? idArea,
  });

   @brief Disattiva una promozione configurata (OP.15).
   @param idPromozione Id della promozione da disattivare.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<void> disattiva(String idPromozione);
}

 @brief Implementazione di [PromozioniApi] su `/api/v1` via Dio (Bearer OP).

### `final PromotionsRepository`
@brief Crea il repository; il client API è iniettabile nei test.
  PromotionsRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<List<Map<String, dynamic>>> elenco({bool soloAttive = false}) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/promozioni',
        queryParameters: {'solo_attive': soloAttive},
      );
      final dati = ApiClient.payload(risposta);
      final promozioni = (dati['promozioni'] as List?) ?? const [];
      return promozioni
          .map((p) => Map<String, dynamic>.from(p as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<String> crea({
    required String tipo,
    required String descrizione,
    num? valore,
    String? idArea,
  }) async {
    try {
      final risposta = await _client.dio.post<dynamic>(
        '/promozioni',
        data: {
          'tipo': tipo,
          'descrizione': descrizione,
          'valore': ?valore,
          'id_area': ?idArea,
        },
      );
      return ApiClient.payload(risposta)['id_promozione'].toString();
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<void> disattiva(String idPromozione) async {
    try {
      await _client.dio.delete<dynamic>('/promozioni/$idPromozione');
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

 @brief Repository promozioni condiviso (default reale; sovrascrivibile nei test).

### File: `api\sos_repository.dart`

### `abstract class`
@brief Contratto della coda SOS lato operatore (OP.08, UT.20/IIN-18), iniettabile nei test.

### `class SosRepository`
@brief Elenca le segnalazioni SOS in coda, opzionalmente filtrate per stato.
   @param stato Filtro opzionale (inoltrata/presa_in_carico/chiusa); null = tutte.
   @return Lista delle segnalazioni (con etichetta utente già risolta lato server).
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> coda({String? stato});

   @brief Aggiorna lo stato di una segnalazione SOS (presa in carico/chiusura, OP.08).
   @param idSegnalazione Id della segnalazione.
   @param stato Nuovo stato: inoltrata | presa_in_carico | chiusa.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<void> aggiornaStato(String idSegnalazione, String stato);
}

 @brief Implementazione di [SosApi] su `/api/v1` via Dio (Bearer OP).

### `final SosRepository`
@brief Crea il repository; il client API è iniettabile nei test.
  SosRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<List<Map<String, dynamic>>> coda({String? stato}) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/sos',
        queryParameters: {'stato': ?stato},
      );
      final dati = ApiClient.payload(risposta);
      final sos = (dati['sos'] as List?) ?? const [];
      return sos
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<void> aggiornaStato(String idSegnalazione, String stato) async {
    try {
      await _client.dio.put<dynamic>(
        '/sos/$idSegnalazione/stato',
        data: {'stato': stato},
      );
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

 @brief Repository SOS condiviso (default reale; sovrascrivibile nei test).

### File: `api\users_admin_repository.dart`

### `abstract class`
@brief Contratto di gestione account per l'operatore (OP.10/OP.17/OP.18).

### `class UsersAdminRepository`
@brief Elenca gli account, opzionalmente filtrati per ruolo RBAC.
   @param ruolo Filtro opzionale (UT/OP/PA); null = tutti.
   @return Lista di account (campi riservati già redatti lato server).
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<List<Map<String, dynamic>>> elencoAccount({String? ruolo});

   @brief Sospende o riattiva un account utente (OP.10 sospendi / OP.18 sblocca).
   @param idAccount Id dell'account su cui agire.
   @param stato Nuovo stato: "attivo" oppure "sospeso".
   @return Vista account aggiornata.
   @throws LeafApiException Su errore di rete o servizio non disponibile.
  Future<Map<String, dynamic>> impostaStato(String idAccount, String stato);

   @brief Provisiona un account Amministrazione Pubblica (OP.17, IIN-12).
   @param email Email di accesso univoca.
   @param username Username univoco.
   @param ente Nome dell'ente.
   @param emailIstituzionale Email istituzionale per il reset (AP.12).
   @return {id_account, password_temporanea} — la temporanea va mostrata una volta.
   @throws LeafApiException Su errore di rete o conflitto (email/username in uso).
  Future<Map<String, dynamic>> provisionaPa({
    required String email,
    required String username,
    required String ente,
    required String emailIstituzionale,
  });
}

 @brief Implementazione di [GestioneUtentiApi] su `/api/v1` via Dio (Bearer OP).

### `final UsersAdminRepository`
@brief Crea il repository; il client API è iniettabile nei test.
  UsersAdminRepository({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  @override
  Future<List<Map<String, dynamic>>> elencoAccount({String? ruolo}) async {
    try {
      final risposta = await _client.dio.get<dynamic>(
        '/utenti',
        queryParameters: {'ruolo': ?ruolo},
      );
      final dati = ApiClient.payload(risposta);
      final account = (dati['account'] as List?) ?? const [];
      return account
          .map((a) => Map<String, dynamic>.from(a as Map))
          .toList(growable: false);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<Map<String, dynamic>> impostaStato(
    String idAccount,
    String stato,
  ) async {
    try {
      final risposta = await _client.dio.put<dynamic>(
        '/utenti/$idAccount/stato',
        data: {'stato': stato},
      );
      final dati = ApiClient.payload(risposta);
      return Map<String, dynamic>.from(dati['account'] as Map);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }

  @override
  Future<Map<String, dynamic>> provisionaPa({
    required String email,
    required String username,
    required String ente,
    required String emailIstituzionale,
  }) async {
    try {
      final risposta = await _client.dio.post<dynamic>(
        '/amministrazioni',
        data: {
          'email': email,
          'username': username,
          'ente': ente,
          'email_istituzionale': emailIstituzionale,
        },
      );
      return ApiClient.payload(risposta);
    } on DioException catch (errore) {
      throw ApiClient.erroreDa(errore);
    }
  }
}

 @brief Repository gestione utenti condiviso (default reale; sovrascrivibile nei test).

### File: `data\alerts_store.dart`

### `class FleetAlert`
@brief Allerta operativa derivata dalle soglie configurate (OP.02/OP.22).

 Due forme, distinte dal discriminante [tipo]:
 - `mezzi_area`: un'area è scesa sotto il minimo di mezzi richiesto (OP.02);
 - `batteria`: un mezzo è sotto la percentuale di batteria di allerta (OP.22).
 I campi non pertinenti alla forma restano `null`.

### `class AlertsStore`
@brief Costruisce un'allerta tipizzata della flotta.
  const FleetAlert({
    required this.tipo,
    this.area,
    this.presenti,
    this.minimo,
    this.mezzo,
    this.batteria,
    this.soglia,
  });

   Discriminante della forma: `mezzi_area` oppure `batteria`.
  final String tipo;

  // ── Forma `mezzi_area` (OP.02) ─────────────────────────────────────────────
   Nome (o id) dell'area sotto soglia.
  final String? area;

   Mezzi attualmente presenti nell'area.
  final int? presenti;

   Minimo di mezzi richiesto per l'area.
  final int? minimo;

  // ── Forma `batteria` (OP.22) ───────────────────────────────────────────────
   Codice identificativo del mezzo sotto soglia batteria.
  final String? mezzo;

   Percentuale di batteria attuale del mezzo.
  final int? batteria;

   Percentuale di allerta configurata.
  final int? soglia;

   @brief Costruisce un'allerta dal documento grezzo della API.
   @param doc Documento allerta (`/soglie/allerte`).
   @return L'allerta tipizzata, o `null` se il `tipo` non è riconosciuto.
  static FleetAlert? daApi(Map<String, dynamic> doc) {
    final tipo = '${doc['tipo'] ?? ''}';
    switch (tipo) {
      case 'mezzi_area':
        return FleetAlert(
          tipo: tipo,
          area: doc['area']?.toString(),
          presenti: (doc['presenti'] as num?)?.toInt(),
          minimo: (doc['minimo'] as num?)?.toInt(),
        );
      case 'batteria':
        return FleetAlert(
          tipo: tipo,
          mezzo: doc['mezzo']?.toString(),
          batteria: (doc['batteria'] as num?)?.toInt(),
          soglia: (doc['soglia'] as num?)?.toInt(),
        );
      default:
        return null;
    }
  }
}

 @brief Stato osservabile delle allerte di soglia alimentato da `/api/v1/soglie/allerte`.

 La home dell'Operatore osserva [allerte] tramite [ValueListenableBuilder] per
 alimentare la coda allarmi real-time (OP.02/OP.22), senza pattern MVC (stesso
 approccio di [FleetStore]). In assenza di rete (IIN-6) la lista resta vuota e
 [offline] passa a true: la vista ricade sui propri dati di riserva statici.

### File: `data\discount_data.dart`

### `enum DiscountType`
@brief Tipo di incentivo configurabile dall'Operatore (OP.09 / OP.15).

### `class DiscountRule`
@brief Regola di sconto/incentivo geografico.

### `class DiscountData`
@brief Crea una regola di sconto.
  DiscountRule({
    required this.id,
    required this.type,
    required this.name,
    required this.area,
    required this.value,
    required this.period,
    this.active = true,
  });

   @brief Costruisce una [DiscountRule] da un documento promozione della API.
   @param doc Documento promozione (`/api/v1/promozioni`).
   @return La regola mappata, o null se priva di identificativo.
  static DiscountRule? daApi(Map<String, dynamic> doc) {
    final id = doc['_id']?.toString();
    if (id == null || id.isEmpty) return null;
    final tipo = doc['tipo']?.toString();
    final geo = tipo != 'credito_bonus_parcheggio';
    final valore = doc['valore'];
    return DiscountRule(
      id: id,
      type: geo ? DiscountType.geoDiscount : DiscountType.parkingBonus,
      name: doc['descrizione']?.toString() ?? id,
      area: doc['id_area']?.toString() ?? '—',
      value: valore == null
          ? '—'
          : (geo ? '-$valore% corsa' : '+$valore € credito'),
      period: '—',
      active: doc['stato'] != 'sospesa',
    );
  }

   @brief Identificativo della regola.
  final String id;

   @brief Tipo di incentivo (bonus parcheggio / sconto geografico).
  final DiscountType type;

   @brief Nome/descrizione della regola.
  String name;

   @brief Area geografica di applicazione.
  final String area;

   @brief Valore leggibile dell'incentivo.
  final String value;

   @brief Periodo di validità leggibile.
  final String period;

   @brief Stato attivo/sospeso della regola.
  bool active;
}

 @brief Dati di riserva della Gestione Sconti (mock storici, lista stabile).

### File: `data\discount_store.dart`

### `class DiscountStore`
@brief Stato osservabile della Gestione Sconti da `/api/v1/promozioni` (OP.09/15).

 La schermata osserva [rules] tramite [ValueListenableBuilder] (nessun MVC,
 stesso pattern di `FleetStore`). Valore iniziale = dati di riserva
 [DiscountData]: senza rete (IIN-6) resta sui mock con [offline] a true. Le
 mutazioni sono ottimistiche (aggiornano subito lo store) con sync best-effort
 verso il backend.

### File: `data\event_data.dart`

### `enum CityEventType`
@brief Tipologia di evento cittadino segnalabile dall'Amministrazione Pubblica.

### `class CityEvent`
@brief Evento cittadino segnalato a sistema.

### `class EventData`
@brief Crea un evento cittadino.
  CityEvent({
    required this.id,
    required this.name,
    required this.type,
    required this.date,
    required this.area,
    this.location,
    this.note = '',
    this.serverId,
  });

   @brief Mappa la categoria del documento server sull'enum di vista.
   @param categoria Discriminante `categoria` dell'area di tipo "evento".
   @return Il [CityEventType] corrispondente (default grande evento).
  static CityEventType tipoDaCategoria(String categoria) {
    switch (categoria) {
      case 'cantiere':
        return CityEventType.cantiere;
      case 'interruzione':
        return CityEventType.interruzione;
      default:
        return CityEventType.grandeEvento;
    }
  }

   @brief Categoria server corrispondente a un [CityEventType] (per il POST).
   @param t Tipo di evento di vista.
   @return La stringa `categoria` attesa dal backend.
  static String categoriaApi(CityEventType t) {
    switch (t) {
      case CityEventType.cantiere:
        return 'cantiere';
      case CityEventType.interruzione:
        return 'interruzione';
      case CityEventType.grandeEvento:
        return 'grande_evento';
    }
  }

   @brief Costruisce un [CityEvent] da un documento evento della API (AP.09).
   @param doc Documento area di tipo "evento" (`/api/v1/eventi`).
   @return L'evento mappato, o null se privo di identificativo.
  static CityEvent? daApi(Map<String, dynamic> doc) {
    final id = doc['_id']?.toString();
    if (id == null || id.isEmpty) return null;
    LatLng? location;
    final geometria = doc['geometria'];
    if (geometria is List && geometria.isNotEmpty) {
      final p = geometria.first;
      if (p is Map && p['lat'] != null && p['lon'] != null) {
        location = LatLng(
          (p['lat'] as num).toDouble(),
          (p['lon'] as num).toDouble(),
        );
      }
    }
    return CityEvent(
      id: id,
      serverId: id,
      name: doc['nome']?.toString() ?? id,
      type: tipoDaCategoria(doc['categoria']?.toString() ?? ''),
      date:
          DateTime.tryParse(doc['data_inizio']?.toString() ?? '') ??
          DateTime.now(),
      area: doc['area']?.toString() ?? '—',
      location: location,
    );
  }

   @brief Identificativo dell'evento.
  final String id;

   @brief Nome dell'evento.
  String name;

   @brief Tipo di evento (grande evento / cantiere / interruzione).
  final CityEventType type;

   @brief Data dell'evento.
  final DateTime date;

   @brief Area/quartiere interessato.
  final String area;

   @brief Posizione sulla mappa (opzionale).
  final LatLng? location;

   @brief Nota descrittiva opzionale.
  final String note;

   @brief Id lato server per la cancellazione (null se solo locale/di riserva).
  
   Valorizzato dal mapper [daApi] per gli eventi caricati dal backend e
   dallo store dopo una creazione persistita; resta null per i dati di
   riserva mock, che non esistono sul server e non vanno eliminati via API.
  String? serverId;
}

 @brief Dati di riserva della schermata Segnala Eventi (mock storici, lista stabile).

### File: `data\event_store.dart`

### `class EventStore`
@brief Stato osservabile della schermata Segnala Eventi da `/api/v1/eventi` (AP.09).

 La schermata osserva [events] tramite [ValueListenableBuilder] (nessun MVC,
 stesso pattern di `FleetStore`). Valore iniziale = dati di riserva [EventData]:
 senza rete (IIN-6) resta sui mock con [offline] a true. Le mutazioni sono
 ottimistiche con sync best-effort: solo i grandi eventi (AP.09) sono persistiti
 su `/eventi`; cantieri e interruzioni restano locali (domini AP.04 di altri blocchi).

### File: `data\fleet_data.dart`

### `enum VehicleType`
Tipologia di veicolo condivisa (allineata ai filtri di AppMobileUtente).

### `enum VehicleStatus`
Stato operativo del mezzo visibile nelle dashboard OP. OP.20.

### `class Vehicle`
@brief Veicolo della flotta condivisa LEAF Mobility.

 Le coordinate replicano 1:1 quelle mostrate sulla mappa di
 [AppMobileUtente] (map_tab.dart): la vista di OP/AP coincide cosi' con la
 vista utente, come richiesto. UT.01 / OP.01 / AP.10.
@immutable

### `class ChargingStation`
@brief Costruisce un [Vehicle] da un documento `mezzi` della API (OP.01/OP.20).
  
   Mappa i campi snake_case del server (`codice_identificativo`, `tipo_mezzo`,
   `posizione{lat,lon}`, `livello_batteria_pct`, `stato_operativo`) sul modello
   di vista. Ritorna null se il mezzo non ha una posizione valida.
  
   @param d Documento mezzo grezzo da `/api/v1/flotta`.
   @return Il [Vehicle] corrispondente, o null se senza coordinate.
  static Vehicle? daApi(Map<String, dynamic> d) {
    final pos = d['posizione'];
    if (pos is! Map || pos['lat'] == null || pos['lon'] == null) return null;
    return Vehicle(
      '${d['codice_identificativo'] ?? d['_id'] ?? ''}',
      _tipoDaApi('${d['tipo_mezzo'] ?? ''}'),
      (pos['lat'] as num).toDouble(),
      (pos['lon'] as num).toDouble(),
      (d['livello_batteria_pct'] ?? 0) as int,
      _statoDaApi('${d['stato_operativo'] ?? ''}'),
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

   Mappa `stato_operativo` del server sullo stato operativo di vista.
  static VehicleStatus _statoDaApi(String stato) {
    switch (stato) {
      case 'in_uso':
        return VehicleStatus.inUse;
      case 'manutenzione':
      case 'guasto':
        return VehicleStatus.maintenance;
      case 'scarico':
      case 'batteria_scarica':
        return VehicleStatus.lowBattery;
      default:
        return VehicleStatus.available;
    }
  }
}

 @brief Stazione di ricarica condivisa. UT.14 / OP.22.
@immutable

### `class TplStop`
@brief Fermata del sistema TPL (trasporto pubblico locale).

 Integrata nativamente nei dati mappa (vincolo architetturale: sistemaTPL
 non e' un modulo separato).
@immutable

### `class MapBounds`
@brief Riquadro geografico per la proiezione lat/lng → coordinate schermo.

 Bounds centrati su Bari, scelti per contenere l'intera flotta mostrata in
 [AppMobileUtente]. La proiezione e' equirettangolare (sufficiente alla
 scala cittadina) con il nord in alto.

### `class FleetData`
@brief Proietta una coordinata geografica in frazioni [0,1] dell'area.
   @param lat Latitudine.
   @param lng Longitudine.
   @return Offset con dx/dy in [0,1] (origine in alto a sinistra).
  static Offset project(double lat, double lng) {
    final fx = ((lng - minLng) / (maxLng - minLng)).clamp(0.0, 1.0);
    final fy = ((maxLat - lat) / (maxLat - minLat)).clamp(0.0, 1.0);
    return Offset(fx, fy);
  }
}

 @brief Sorgente dati condivisa della flotta (mock pre-backend).

 Finche' il Business Tier (`gestore_flotta`) non sara' disponibile, queste
 strutture statiche alimentano sia la mappa che le metriche. Le posizioni
 coincidono con quelle di [AppMobileUtente]; gli stati operativi sono
 aggiunti per le viste OP. OP.01 / OP.03 / OP.20 / AP.03 / AP.10.

### `Color vehicleTypeColor`
Veicoli — posizioni identiche a map_tab.dart di AppMobileUtente.
  static const List<Vehicle> vehicles = [
    // Scooter
    Vehicle('SC-001', VehicleType.scooter, 41.1171, 16.8715, 78,
        VehicleStatus.inUse),
    Vehicle('SC-009', VehicleType.scooter, 41.1188, 16.8742, 52,
        VehicleStatus.available),
    Vehicle('SC-012', VehicleType.scooter, 41.1258, 16.8702, 90,
        VehicleStatus.available),
    Vehicle('SC-014', VehicleType.scooter, 41.1205, 16.8655, 67,
        VehicleStatus.available),
    Vehicle('SC-017', VehicleType.scooter, 41.1232, 16.8688, 83,
        VehicleStatus.inUse),
    Vehicle('SC-021', VehicleType.scooter, 41.1148, 16.8665, 41,
        VehicleStatus.maintenance),
    Vehicle('SC-024', VehicleType.scooter, 41.1108, 16.8702, 95,
        VehicleStatus.available),
    Vehicle('SC-028', VehicleType.scooter, 41.1300, 16.8682, 58,
        VehicleStatus.available),
    Vehicle('SC-031', VehicleType.scooter, 41.1045, 16.8628, 73,
        VehicleStatus.available),
    Vehicle('SC-034', VehicleType.scooter, 41.1170, 16.8600, 64,
        VehicleStatus.available),
    Vehicle('SC-037', VehicleType.scooter, 41.1085, 16.8585, 9,
        VehicleStatus.lowBattery),
    // Bici
    Vehicle('BK-003', VehicleType.bike, 41.1278, 16.8665, 91,
        VehicleStatus.inUse),
    Vehicle('BK-007', VehicleType.bike, 41.1060, 16.8560, 74,
        VehicleStatus.available),
    Vehicle('BK-011', VehicleType.bike, 41.1242, 16.8718, 88,
        VehicleStatus.inUse),
    Vehicle('BK-015', VehicleType.bike, 41.0840, 16.8612, 55,
        VehicleStatus.available),
    Vehicle('BK-018', VehicleType.bike, 41.1162, 16.8718, 67,
        VehicleStatus.available),
    Vehicle('BK-022', VehicleType.bike, 41.1318, 16.8612, 80,
        VehicleStatus.available),
    Vehicle('BK-026', VehicleType.bike, 41.1185, 16.8730, 12,
        VehicleStatus.lowBattery),
    Vehicle('BK-029', VehicleType.bike, 41.1098, 16.8665, 77,
        VehicleStatus.available),
    Vehicle('BK-033', VehicleType.bike, 41.1212, 16.8625, 60,
        VehicleStatus.available),
    // Auto
    Vehicle('CA-007', VehicleType.car, 41.1157, 16.8705, 65,
        VehicleStatus.inUse),
    Vehicle('CA-011', VehicleType.car, 41.1005, 16.8742, 82,
        VehicleStatus.available),
    Vehicle('CA-015', VehicleType.car, 41.0838, 16.8688, 48,
        VehicleStatus.maintenance),
    Vehicle('CA-019', VehicleType.car, 41.1278, 16.8568, 91,
        VehicleStatus.available),
    Vehicle('CA-023', VehicleType.car, 41.1068, 16.8712, 70,
        VehicleStatus.available),
    Vehicle('CA-027', VehicleType.car, 41.1135, 16.8638, 55,
        VehicleStatus.available),
    Vehicle('CA-031', VehicleType.car, 41.1225, 16.8662, 88,
        VehicleStatus.available),
    // E-Moto
    Vehicle('EM-002', VehicleType.emoto, 41.1052, 16.8702, 85,
        VehicleStatus.inUse),
    Vehicle('EM-005', VehicleType.emoto, 41.0855, 16.8628, 60,
        VehicleStatus.available),
    Vehicle('EM-008', VehicleType.emoto, 41.1378, 16.7720, 72,
        VehicleStatus.available),
    Vehicle('EM-012', VehicleType.emoto, 41.1190, 16.8640, 88,
        VehicleStatus.available),
    Vehicle('EM-015', VehicleType.emoto, 41.1238, 16.8695, 8,
        VehicleStatus.lowBattery),
    Vehicle('EM-018', VehicleType.emoto, 41.1118, 16.8602, 79,
        VehicleStatus.available),
  ];

   Stazioni di ricarica — posizioni identiche a map_tab.dart.
  static const List<ChargingStation> charging = [
    ChargingStation('CHG-01', 41.1262, 16.8698, 4, 'Piazza Ferrarese'),
    ChargingStation('CHG-02', 41.1072, 16.8608, 2, 'Via Amendola'),
    ChargingStation('CHG-03', 41.0958, 16.8718, 6, 'Japigia'),
    ChargingStation('CHG-04', 41.1275, 16.8718, 3, 'Lungomare'),
    ChargingStation('CHG-05', 41.1200, 16.8678, 5, 'Piazza Umberto'),
    ChargingStation('CHG-06', 41.1142, 16.8728, 4, 'Murat'),
    ChargingStation('CHG-07', 41.0892, 16.8742, 2, 'Japigia Sud'),
    ChargingStation('CHG-08', 41.1325, 16.8530, 3, 'San Cataldo'),
    ChargingStation('CHG-09', 41.1162, 16.8632, 4, 'Quartiere Libertà'),
    ChargingStation('CHG-10', 41.1085, 16.8628, 3, 'Carrassi'),
    ChargingStation('CHG-11', 41.1248, 16.8648, 5, 'Corso Cavour'),
    ChargingStation('CHG-12', 41.1300, 16.8505, 6, 'Fiera del Levante'),
    ChargingStation('CHG-13', 41.1042, 16.8552, 2, 'Poggiofranco'),
    ChargingStation('CHG-14', 41.0845, 16.8662, 3, 'Carbonara'),
  ];

   Fermate TPL — posizioni identiche a map_tab.dart (sistemaTPL integrato).
  static const List<TplStop> tplStops = [
    TplStop('TPL-FS', 41.1157, 16.8711, 'Stazione FS Bari Centrale'),
    TplStop('TPL-FIERA', 41.1000, 16.8500, 'Fiera del Levante – Bus Hub'),
    TplStop('TPL-PETRUZZELLI', 41.1236, 16.8719, 'Teatro Petruzzelli'),
    TplStop('TPL-POLICLINICO', 41.1095, 16.8780, 'Policlinico – Bus'),
    TplStop('TPL-AEROPORTO', 41.1389, 16.7606, 'Aeroporto K. Wojtyła'),
  ];

  // ── Aggregati per le metriche dashboard ──────────────────────────────────
  static int get total => vehicles.length;

  static int countByStatus(VehicleStatus s) =>
      vehicles.where((v) => v.status == s).length;

  static int countByType(VehicleType t) =>
      vehicles.where((v) => v.type == t).length;

   Mezzi operativi (disponibili o in uso) = "Attivi" delle dashboard. AP.03.
  static int get activeCount =>
      countByStatus(VehicleStatus.available) +
      countByStatus(VehicleStatus.inUse);

   Percentuale di mezzi attivi sul totale, arrotondata.
  static int get activePct => (activeCount * 100 / total).round();

  static int get lowBatteryPct =>
      (countByStatus(VehicleStatus.lowBattery) * 100 / total).round();

  static int get maintenancePct =>
      (countByStatus(VehicleStatus.maintenance) * 100 / total).round();
}

// ── Helper di presentazione (colori, icone, etichette) ──────────────────────

 @brief Colore associato alla tipologia di mezzo (coerente con i marker).

### `IconData vehicleTypeIcon`
@brief Icona Material associata alla tipologia di mezzo.

### `String vehicleTypeLabel`
@brief Etichetta (chiave i18n) della tipologia di mezzo.

### `Color vehicleStatusColor`
@brief Colore associato allo stato operativo del mezzo.

### `String vehicleStatusLabel`
@brief Etichetta (chiave i18n) dello stato operativo del mezzo.

### `VehicleType vehicleTypeFromApi`
@brief Mappa il discriminante `tipo_mezzo` del server sull'enum di vista.
 @param tipo Valore `tipo_mezzo` del documento mezzo (es. "ebike").
 @return Il [VehicleType] corrispondente (scooter per valori ignoti).

### `VehicleStatus vehicleStatusFromApi`
@brief Mappa `stato_operativo` del server sullo stato operativo di vista.
 @param stato Valore `stato_operativo` del documento mezzo (es. "manutenzione").
 @return Il [VehicleStatus] corrispondente (disponibile per valori ignoti).

### File: `data\fleet_store.dart`

### `class FleetStore`
@brief Stato osservabile della flotta alimentato da `/api/v1/flotta` (FASE 2.C).

 Le viste OP/PA (mappa e metriche) osservano [vehicles] tramite
 [ValueListenableBuilder], senza introdurre pattern MVC (stesso pattern degli
 store statici esistenti). Il valore iniziale sono i dati di riserva
 [FleetData.vehicles]: così la mappa non è mai vuota e, in assenza di rete
 (IIN-6), resta sui dati di riserva con [offline] a true. OP.01/OP.20/AP.03/AP.10.

### File: `data\notifications_store.dart`

### `enum NotifLevel`
Severita' visiva della notifica.

### `class DashNotification`
@brief Voce del centro notifiche.

### `class NotificationsStore`
Id del backend (per segna-letta via API), null se mock.
  final String? remoteId;
  bool read;

  DashNotification({
    required this.icon,
    required this.level,
    required this.title,
    required this.body,
    required this.time,
    this.remoteId,
    this.read = false,
  });

   @brief Costruisce una [DashNotification] da un documento `/api/v1/notifiche`.
   @param d Documento notifica grezzo.
   @return La notifica mappata.
  static DashNotification daApi(Map<String, dynamic> d) {
    final tipo = '${d['tipo'] ?? 'info'}';
    final level = switch (tipo) {
      'emergenza' || 'sos' => NotifLevel.critical,
      'allerta' || 'warning' => NotifLevel.warning,
      _ => NotifLevel.info,
    };
    final icon = switch (tipo) {
      'emergenza' || 'sos' => Icons.sos,
      'allerta' || 'warning' => Icons.warning_amber,
      'manutenzione' => Icons.build_outlined,
      _ => Icons.notifications_outlined,
    };
    return DashNotification(
      icon: icon,
      level: level,
      title: '${d['titolo'] ?? ''}',
      body: '${d['messaggio'] ?? ''}',
      time: _formattaData(d['timestamp']?.toString()),
      remoteId: d['_id']?.toString(),
      read: d['letta'] == true,
    );
  }

   Formatta un timestamp ISO-8601 in una stringa leggibile breve.
  static String _formattaData(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min fa';
    if (diff.inHours < 24) return '${diff.inHours} h fa';
    if (diff.inDays == 1) return 'Ieri';
    return '${diff.inDays} g fa';
  }
}

 @brief Sorgente osservabile condivisa delle notifiche con backend reale (IIN-19).

 Stesso pattern osservabile di [appLanguage]: un solo elenco e un contatore
 di revisione condivisi tra la campana della top bar (badge "non lette") e il
 centro notifiche, cosi' che leggere una notifica aggiorni subito il badge —
 niente MVC. Il caricamento reale avviene via [NotificationsRepository]; in
 caso di errore di rete (IIN-6) si resta sui dati di riserva mock.

### File: `data\sos_store.dart`

### `class SosSegnalazione`
@brief Segnalazione di emergenza SOS in coda per l'operatore (UT.20/IIN-18, OP.08).

 Mappa il documento di `/api/v1/sos`: l'etichetta [utente] è già risolta lato
 server (nominativo o `@username`), così la coda non mostra l'id grezzo.

### `class SosStore`
@brief Costruisce una segnalazione SOS della coda operatore.
  const SosSegnalazione({
    required this.id,
    required this.utente,
    required this.stato,
    this.zona,
    this.idCorsa,
    this.timestamp,
  });

   @brief Costruisce una [SosSegnalazione] dal documento della API.
   @param doc Documento segnalazione (`/api/v1/sos`).
   @return La segnalazione mappata, o null se priva di identificativo.
  static SosSegnalazione? daApi(Map<String, dynamic> doc) {
    final id = doc['_id']?.toString();
    if (id == null || id.isEmpty) return null;
    final nominativo = doc['nominativo']?.toString();
    final username = doc['username']?.toString();
    final etichetta = (nominativo != null && nominativo.isNotEmpty)
        ? nominativo
        : (username != null && username.isNotEmpty)
        ? '@$username'
        : (doc['id_utente']?.toString() ?? '—');
    final lat = (doc['lat'] as num?)?.toDouble();
    final lon = (doc['lon'] as num?)?.toDouble();
    final zona = (lat != null && lon != null)
        ? '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}'
        : null;
    return SosSegnalazione(
      id: id,
      utente: etichetta,
      stato: doc['stato']?.toString() ?? 'inoltrata',
      zona: zona,
      idCorsa: doc['id_corsa']?.toString(),
      timestamp: doc['timestamp']?.toString(),
    );
  }

   @brief Identificativo della segnalazione.
  final String id;

   @brief Etichetta leggibile dell'utente che ha attivato l'SOS.
  final String utente;

   @brief Stato corrente (inoltrata / presa_in_carico / chiusa).
  final String stato;

   @brief Posizione "lat, lon" della segnalazione (null se assente).
  final String? zona;

   @brief Corsa correlata, se l'SOS è partito durante un noleggio.
  final String? idCorsa;

   @brief Timestamp ISO-8601 della segnalazione.
  final String? timestamp;
}

 @brief Stato osservabile della coda SOS alimentato da `/api/v1/sos` (OP.08, UT.20).

 La home dell'Operatore osserva [sos] tramite [ValueListenableBuilder] per
 alimentare la coda allarmi SOS in tempo reale (stesso approccio di
 [AlertsStore], nessun MVC). In assenza di rete (IIN-6) la lista resta vuota e
 [offline] passa a true.

### File: `data\users_admin_data.dart`

### `enum UserStatus`
@brief Stato dell'account di un utente del servizio. OP.10 / OP.18.

### `enum ApStatus`
@brief Stato dell'account di un Amministratore Pubblico. OP.17 (provisioning).

### `class ManagedUser`
@brief Account utente gestibile dall'Operatore.

### `class ApAccount`
@brief Crea un account utente gestibile.
  ManagedUser({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    this.username = '',
    this.note = '',
  });

   @brief Costruisce un [ManagedUser] da un documento account della API.
   @param doc Documento account (`/api/v1/utenti`).
   @return L'account mappato, o null se privo di identificativo.
  static ManagedUser? daApi(Map<String, dynamic> doc) {
    final id = doc['_id']?.toString();
    if (id == null || id.isEmpty) return null;
    final etichetta = doc['nominativo']?.toString();
    return ManagedUser(
      id: id,
      name: (etichetta != null && etichetta.isNotEmpty)
          ? etichetta
          : (doc['username']?.toString() ?? doc['email']?.toString() ?? id),
      username: doc['username']?.toString() ?? '',
      email: doc['email']?.toString() ?? '',
      status: doc['stato_account'] == 'sospeso'
          ? UserStatus.sospeso
          : UserStatus.attivo,
    );
  }

   @brief Identificativo dell'account.
  final String id;

   @brief Etichetta leggibile (nominativo dal profilo o username).
  final String name;

   @brief Username scelto dall'utente in registrazione (UT.22.1), mostrato all'OP.
  final String username;

   @brief Email di accesso.
  final String email;

   @brief Stato corrente dell'account (attivo/sospeso).
  UserStatus status;

   @brief Nota opzionale (motivo della sospensione).
  final String note;
}

 @brief Account di Amministrazione Pubblica creato dall'Operatore.

### File: `data\users_admin_store.dart`

### `class UsersAdminStore`
@brief Stato osservabile della Gestione Utenti/AP da `/api/v1/utenti` (OP.10/17/18).

 La schermata osserva [users]/[apAccounts] tramite [ValueListenableBuilder] (nessun
 MVC, stesso pattern di `FleetStore`). I dati provengono esclusivamente dal server:
 l'elenco parte vuoto e, senza rete, resta vuoto con [offline] a true (nessun dato
 fabbricato — dipendenza dal server).

### File: `screens\active_bookings.dart`

### `class _Booking`
@brief Prenotazione attiva mostrata nella console operatore (OP.12).

### `class ActiveBookings`
@brief Costruisce una [_Booking] dal documento di `/api/v1/prenotazioni/attive`.
   @param d Documento prenotazione (con etichetta utente risolta lato server).
   @return La prenotazione mappata, o null se priva di identificativo.
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

 @brief Prenotazioni attive con annullamento forzato dall'operatore (OP.12).

 L'Operatore vede le prenotazioni attive sull'intera flotta (con l'utente che
 trattiene il mezzo) e può forzarne l'annullamento per rimettere a disposizione
 della community un mezzo trattenuto in modo anomalo, senza l'avvio della corsa.
 I dati arrivano da `/api/v1/prenotazioni/attive`; senza rete (IIN-6) si mostra
 lo stato vuoto con banner offline, mai dati fabbricati.

### `class _ActiveBookingsState`
@brief Se true (default), carica i dati reali all'apertura; i test lo disattivano.
  final bool autoload;

   @brief Repository iniettabile (default singleton reale; fake nei test).
  final PrenotazioniOpApi? repo;

  @override
  State<ActiveBookings> createState() => _ActiveBookingsState();
}

### File: `screens\ap_dashboard.dart`

### `class ApDashboard`
@brief Console dell'Amministrazione Pubblica (AP).

 Vista orientata alla pianificazione: metriche aggregate e anonime
 (IIN-15), heatmap di utilizzo (AP.05), distribuzione flotta in tempo reale
 (AP.10), strumenti di geofencing/eventi e reportistica. I dati di mobilita'
 mostrati sono gia' aggregati: nessun dato riconducibile al singolo cittadino.

### `class _ApHome`
Home dell'Amministrazione Pubblica.

### File: `screens\change_password_screen.dart`

### `class ChangePasswordScreen`
@brief Schermata di cambio password obbligatorio al primo accesso OP/PA (IIN-12).

 Mostrata dopo login + MFA quando il backend segnala `richiede_cambio_password`.
 Richiede una nuova password e la sua conferma, ne valida i requisiti IIN-5
 (≥8 caratteri, almeno una maiuscola, una cifra e un carattere speciale) e chiama
 l'endpoint autenticato `/auth/password/primo-accesso`. Al successo chiude tornando
 `true` al chiamante (la login screen completa quindi l'ingresso nella console).

### `class _ChangePasswordScreenState`
Repository di autenticazione (default reale; fittizio nei test).
  final AuthApi _auth;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

### File: `screens\discount_management.dart`

### `bool _createRequested`
Richiesta "pendente" di aprire il form di creazione all'ingresso nella
 schermata: usata dal pannello rapido dell'Operatore ("Configura Nuovo
 Sconto") che naviga qui e fa aprire subito il dialog di creazione.

### `void requestDiscountCreateOnOpen`
@brief Segnala alla [DiscountManagement] di aprire il form di creazione
 non appena viene montata (consumata una sola volta).

### `class DiscountManagement`
@brief Gestione Sconti dell'Operatore (OP.09 / OP.15).

 Configura crediti bonus per i rilasci nelle aree di parcheggio designate
 (OP.09) e sconti percentuali programmati su perimetri geografici per
 incentivare la domanda nelle zone meno redditizie (OP.15). I dati sono
 alimentati da `/api/v1/promozioni` tramite [DiscountStore] (fallback ai dati
 di riserva senza rete, IIN-6; propagazione ai mezzi entro 30s, IIN-21).

### `class _DiscountManagementState`
@brief Se true (default), carica i dati reali all'apertura; i test lo disattivano.
  final bool autoload;

   @brief Repository promozioni iniettabile (default singleton reale; fake nei test).
  final PromozioniApi? repo;

  @override
  State<DiscountManagement> createState() => _DiscountManagementState();
}

### `class _CreateDiscountForm`
Genera il prossimo identificativo regola progressivo (es. `SC-05`).
  String _nextId() => 'SC-${(++_seq).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return ValueListenableBuilder<List<DiscountRule>>(
        valueListenable: DiscountStore.rules,
        builder: (context, rules, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: SectionHeader(
                      title: 'Gestione Sconti',
                      subtitle: 'Incentivi al parcheggio e sconti geografici',
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _openCreateDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(tr('Nuova Regola')),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _summary(rules),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: rules.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _ruleCard(rules[i]),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _summary(List<DiscountRule> rules) {
    final activeCount = rules.where((r) => r.active).length;
    int countType(DiscountType t) => rules.where((r) => r.type == t).length;
    Widget pill(String label, int n, Color c) => Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: c.withAlpha(18),
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: c, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$n',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: c,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tr(label),
                  style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
                ),
              ],
            ),
          ),
        );

    return Row(
      children: [
        pill('Regole attive', activeCount, AppTheme.statusAvailable),
        pill('Bonus parcheggio', countType(DiscountType.parkingBonus),
            AppTheme.primaryGreen),
        pill('Sconti geografici', countType(DiscountType.geoDiscount),
            AppTheme.opAccent),
      ],
    );
  }

  ({IconData icon, String label, Color color}) _typeMeta(DiscountType t) {
    switch (t) {
      case DiscountType.parkingBonus:
        return (
          icon: Icons.local_parking,
          label: 'Bonus parcheggio',
          color: AppTheme.primaryGreen,
        );
      case DiscountType.geoDiscount:
        return (
          icon: Icons.percent,
          label: 'Sconto geografico',
          color: AppTheme.opAccent,
        );
    }
  }

  Widget _ruleCard(DiscountRule r) {
    final meta = _typeMeta(r.type);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: meta.color.withAlpha(28),
              child: Icon(meta.icon, color: meta.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        r.id,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textGrey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _typeBadge(meta.label, meta.color),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr(r.name),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      _meta(Icons.place_outlined, r.area),
                      _meta(Icons.savings_outlined, tr(r.value)),
                      _meta(Icons.schedule, tr(r.period)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Switch(
                  value: r.active,
                  activeThumbColor: AppTheme.opAccent,
                  onChanged: (v) =>
                      DiscountStore.imposta(r.id, attiva: v, repo: widget.repo),
                ),
                Text(
                  tr(r.active ? 'Attiva' : 'Sospesa'),
                  style: TextStyle(
                    fontSize: 11,
                    color: r.active
                        ? AppTheme.statusAvailable
                        : AppTheme.textGrey,
                  ),
                ),
              ],
            ),
            IconButton(
              tooltip: tr('Elimina'),
              icon: const Icon(Icons.delete_outline, size: 18),
              color: AppTheme.alarmCritical,
              onPressed: () => DiscountStore.rimuovi(r.id, repo: widget.repo),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tr(label),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textGrey),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
      ],
    );
  }

   @brief Apre il form di creazione di una nuova regola di agevolazione.
  
   Il form vive in un widget dedicato ([_CreateDiscountForm]) che possiede e
   dispone i propri controller nel suo `dispose()`: questo evita di liberare i
   `TextEditingController` mentre il dialog e' ancora in chiusura (animazione),
   che lascerebbe i campi agganciati a controller distrutti. Al salvataggio la
   regola viene aggiunta alla lista in memoria; la persistenza reale passera'
   per `gestore_corse` / `gestore_geofencing`.
  Future<void> _openCreateDialog() async {
    final created = await showDialog<DiscountRule>(
      context: context,
      builder: (context) => _CreateDiscountForm(id: _nextId()),
    );

    if (created != null && mounted) {
      DiscountStore.aggiungi(created, repo: widget.repo);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.statusAvailable,
          content: Text(
            '${tr('Regola creata')} — ${tr('propagazione ai mezzi entro 30s')}',
          ),
        ),
      );
    }
  }
}

 @brief Dialog di creazione di una regola di sconto (OP.09 / OP.15).

 Widget con stato dedicato: possiede i controller dei campi e li dispone in
 [dispose] (eseguito quando la route e' realmente rimossa), evitando il
 rilascio anticipato che corrompeva l'albero alla chiusura del dialog.
 Ritorna la [DiscountRule] creata via `Navigator.pop`, oppure null se annullato.

### File: `screens\event_reporting_screen.dart`

### `class EventReportingScreen`
@brief Schermata "Segnala Eventi" dell'Amministrazione Pubblica.

 Consente di inserire a sistema le date e le coordinate dei grandi eventi
 cittadini, dei cantieri/lavori temporanei e delle interruzioni di servizio,
 così da notificare gli operatori sulle aree che richiederanno un
 potenziamento o una limitazione della flotta. Si tocca la mappa per
 posizionare l'evento. I grandi eventi (AP.09) sono persistiti su
 `/api/v1/eventi` tramite [EventStore] (fallback ai dati di riserva senza
 rete, IIN-6); cantieri e interruzioni restano locali (domini AP.04).

### `class _EventReportingScreenState`
@brief Se true (default), carica i dati reali all'apertura; i test lo disattivano.
  final bool autoload;

   @brief Repository eventi iniettabile (default singleton reale; fake nei test).
  final EventiApi? repo;

  @override
  State<EventReportingScreen> createState() => _EventReportingScreenState();
}

### File: `screens\fleet_diagnostics.dart`

### `class FleetDiagnostics`
@brief Schermata "Diagnostica Flotta" dell'Operatore (OP.03 + OP.13).

 Riunisce due viste di stato della flotta utili alla squadra di recupero:
 il **report giornaliero** (conteggio mezzi per stato operativo e batteria
 scarica, OP.13) e l'**elenco dei mezzi guasti** da ritirare (OP.03). I dati
 arrivano da `/api/v1/flotta/report` e `/api/v1/mezzi-guasti`; in assenza di
 rete (IIN-6) la vista ricade sui mezzi già noti allo [FleetStore].

### `class _FleetDiagnosticsState`
@brief Se true (default), carica i dati reali all'apertura; i test lo disattivano.
  final bool autoload;

   @brief Repository flotta iniettabile (default singleton reale; fake nei test).
  final FlottaApi? repo;

  @override
  State<FleetDiagnostics> createState() => _FleetDiagnosticsState();
}

### File: `screens\geofencing_screen.dart`

### `enum GeoAreaType`
Tipologia di area di geofencing tracciabile dall'Amministrazione Pubblica.
 AP.04 (cantiere), AP.06 (interdizione totale), AP.08 (slow-zone).

### `String tipoAreaApi`
@brief Stringa `tipo` lato server per una tipologia di area di vista.

### `GeoAreaType tipoAreaDaApi`
@brief Tipologia di vista a partire dalla stringa `tipo` del server.

### `class GeoArea`
@brief Area di geofencing disegnata sulla mappa.

### `class GeofencingScreen`
Limite di velocita' in km/h (solo per [GeoAreaType.slowZone]).
  final int? speedLimit;

  GeoArea({
    required this.id,
    required this.name,
    required this.type,
    required this.points,
    this.speedLimit,
  });

   @brief Costruisce una [GeoArea] da un documento `aree_limitate` della API.
  
   Accetta sia il poligono come `poligono` (`[[lat,lon], …]`) sia come
   `geometria` (`[{lat,lon}, …]`). Ritorna null se i vertici sono < 3.
  
   @param d Documento area grezzo da `/api/v1/aree`.
   @return La [GeoArea] corrispondente, o null se poligono non valido.
  static GeoArea? daApi(Map<String, dynamic> d) {
    final punti = _puntiDa(d);
    if (punti.length < 3) return null;
    return GeoArea(
      id: '${d['_id'] ?? ''}',
      name: '${d['nome'] ?? '—'}',
      type: tipoAreaDaApi('${d['tipo'] ?? ''}'),
      points: punti,
      speedLimit: (d['limite_velocita_kmh'] as num?)?.toInt(),
    );
  }

   Estrae i vertici dal documento, supportando `poligono` o `geometria`.
  static List<LatLng> _puntiDa(Map<String, dynamic> d) {
    final poligono = d['poligono'];
    if (poligono is List) {
      return [
        for (final p in poligono)
          if (p is List && p.length >= 2)
            LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()),
      ];
    }
    final geometria = d['geometria'];
    if (geometria is List) {
      return [
        for (final p in geometria)
          if (p is Map && p['lat'] != null && p['lon'] != null)
            LatLng((p['lat'] as num).toDouble(), (p['lon'] as num).toDouble()),
      ];
    }
    return const [];
  }
}

 @brief Schermata di geofencing dell'Amministrazione Pubblica.

 Permette di disegnare sulla mappa Google aree operative e non operative,
 perimetri di interdizione totale (AP.06), slow-zone con limite di velocita'
 (AP.08) e cantieri/lavori temporanei (AP.04). Si tocca la mappa per aggiungere
 i vertici e si completa il poligono. Pre-backend le aree restano in memoria
 locale; il salvataggio reale passera' per `gestore_geofencing` e sara'
 propagato ai mezzi entro 30s (IIN-21).

### `class _GeofencingScreenState`
Repository aree iniettabile (default reale; fittizio nei test).
  final AreeApi? _aree;

  @override
  State<GeofencingScreen> createState() => _GeofencingScreenState();
}

### File: `screens\home_router.dart`

### `class HomeRouter`
@brief Instrada alla console corretta in base al ruolo di [Session].

 Stessa pagina di login per OP e AP; dopo l'accesso la dashboard di lavoro
 differisce: OP → [OpDashboard], AP → [ApDashboard]. RBAC (IIN-5). All'ingresso
 avvia il caricamento dello stato flotta dal backend (FASE 2.C): unico punto di
 innesco, così le viste mappa restano testabili senza rete.

### File: `screens\login_screen.dart`

### `class LoginScreen`
@brief Schermata di accesso unica per OP e PA, cablata su `/api/v1/auth`.

 L'accesso è a due passi (IIN-9): credenziali → secondo fattore OTP, sempre
 obbligatorio per le figure della dashboard. Il ruolo effettivo è quello
 restituito dal backend (RBAC, IIN-5); il selettore resta come indicazione
 dell'utente. Il token di sessione è custodito cifrato e usato come Bearer.

### `enum _Fase`
Repository di autenticazione iniettabile (default reale; fittizio nei test).
  final AuthApi? _auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

 Passo corrente del flusso di accesso.

### `class _Spinner`
Esegue una chiamata di rete gestendo in modo uniforme caricamento ed errori.
  Future<void> _conRete(Future<void> Function() azione) async {
    setState(() {
      _caricamento = true;
      _errore = null;
    });
    try {
      await azione();
    } on LeafApiException catch (e) {
      if (mounted) setState(() => _errore = e.messaggio);
    } finally {
      if (mounted) setState(() => _caricamento = false);
    }
  }

   Primo passo: invio credenziali (IIN-1) → attesa OTP per OP/PA (IIN-9).
  Future<void> _accedi() async {
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _errore = tr('Inserisci email e password.'));
      return;
    }
    await _conRete(() async {
      final esito = await _auth.accedi(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
      if (!mounted) return;
      switch (esito.stato) {
        case StatoAccesso.mfaRichiesta:
          setState(() {
            _idAccount = esito.idAccount;
            _fase = _Fase.otp;
            _otpError = null;
          });
          if (esito.otpSimulato != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(
                  tr('Sviluppo: usa l\'OTP simulato: ${esito.otpSimulato}'),
                ),
                duration: const Duration(seconds: 15),
              ),
            );
          }
        case StatoAccesso.ok:
          _entra(esito.ruolo);
        case StatoAccesso.cambioPasswordRichiesto:
          await _cambioPassword(esito.ruolo);
      }
    });
  }

   Reindirizza al cambio password obbligatorio (IIN-12) e, al successo, entra.
   @param ruolo Ruolo restituito dal backend, usato per instradare dopo il cambio.
  Future<void> _cambioPassword(String? ruolo) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ChangePasswordScreen(auth: _auth),
      ),
    );
    if (ok == true && mounted) _entra(ruolo);
  }

   Secondo passo: verifica del codice OTP (IIN-9) → token e ingresso.
  Future<void> _verifica() async {
    if (_otpCtrl.text.trim().length != 6) {
      setState(() => _otpError = tr('Inserisci un codice OTP a 6 cifre.'));
      return;
    }
    final id = _idAccount;
    if (id == null) return;
    await _conRete(() async {
      final esito = await _auth.verificaMfa(id, _otpCtrl.text.trim());
      if (!mounted) return;
      switch (esito.stato) {
        case StatoAccesso.ok:
          _entra(esito.ruolo);
        case StatoAccesso.cambioPasswordRichiesto:
          await _cambioPassword(esito.ruolo);
        case StatoAccesso.mfaRichiesta:
          setState(() => _otpError = tr('Codice OTP non valido.'));
      }
    });
  }

   Imposta il ruolo dalla risposta del backend e apre la console (RBAC, IIN-5).
   @param ruolo Ruolo restituito dal backend ("OP"/"PA"); altri ruoli sono respinti.
  void _entra(String? ruolo) {
    final DashboardRole? effettivo = switch (ruolo) {
      'PA' => DashboardRole.publicAdmin,
      'OP' => DashboardRole.operator,
      _ => null,
    };
    if (effettivo == null) {
      setState(
        () => _errore = tr('Accesso riservato a operatori e amministrazioni.'),
      );
      return;
    }
    Session.role = effettivo;
    Session.email = _emailCtrl.text.trim();
    Navigator.pushReplacementNamed(context, '/home');
  }

   Naviga alla schermata di reset password completa (IIN-11/AP.12).
  void _reset() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResetPasswordScreen(auth: _auth),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: _BrandBackground()),
            Positioned(top: 20, right: 24, child: LangToggle()),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: LeafLogo(size: 64)),
                          const SizedBox(height: 16),
                          Text(
                            tr('Accesso Operatori e PA'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkGreen,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tr('Console di gestione LEAF Mobility'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textGrey,
                            ),
                          ),
                          const SizedBox(height: 28),
                          if (_errore != null) _bannerErrore(_errore!),
                          if (_fase == _Fase.credenziali)
                            ..._campiCredenziali()
                          else
                            ..._campiOtp(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

   Campi e azioni del passo credenziali.
  List<Widget> _campiCredenziali() {
    return [
      _roleSelector(),
      const SizedBox(height: 20),
      TextField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => _accedi(),
        decoration: InputDecoration(
          labelText: tr('Email'),
          prefixIcon: const Icon(Icons.email_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _passwordCtrl,
        obscureText: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _accedi(),
        decoration: InputDecoration(
          labelText: tr('Password'),
          prefixIcon: const Icon(Icons.lock_outline),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: _caricamento ? null : _accedi,
        child: _caricamento
            ? const _Spinner()
            : Text(tr('Accedi')),
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: _caricamento ? null : _reset,
          child: Text(
            tr('Password dimenticata?'),
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
          ),
        ),
      ),
    ];
  }

   Campi e azioni del passo OTP (secondo fattore).
  List<Widget> _campiOtp() {
    return [
      Text(
        tr('Inserisci il codice a 6 cifre inviato via email'),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _otpCtrl,
        keyboardType: TextInputType.number,
        maxLength: 6,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _verifica(),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (_) {
          if (_otpError != null) setState(() => _otpError = null);
        },
        decoration: InputDecoration(
          labelText: tr('Codice OTP'),
          counterText: '',
          errorText: _otpError,
          prefixIcon: const Icon(Icons.shield_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: _caricamento ? null : _verifica,
        child: _caricamento ? const _Spinner() : Text(tr('Verifica')),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: _caricamento
            ? null
            : () => setState(() {
                _fase = _Fase.credenziali;
                _otpCtrl.clear();
                _otpError = null;
              }),
        child: Text(tr('Indietro')),
      ),
    ];
  }

   Banner d'errore inline ad alto contrasto (IIN-2).
  Widget _bannerErrore(String messaggio) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC62828)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFC62828), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              messaggio,
              style: const TextStyle(color: Color(0xFFC62828), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleSelector() {
    Widget option(DashboardRole role, IconData icon, String label, Color c) {
      final selected = _role == role;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _role = role),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: selected ? c.withAlpha(20) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? c : Colors.black12,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: selected ? c : AppTheme.textGrey, size: 26),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.2,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    color: selected ? c : AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('Ruolo'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textGrey,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            option(
              DashboardRole.operator,
              Icons.headset_mic_outlined,
              tr('Operatore del Servizio'),
              AppTheme.opAccent,
            ),
            const SizedBox(width: 12),
            option(
              DashboardRole.publicAdmin,
              Icons.account_balance_outlined,
              tr('Amministrazione Pubblica'),
              AppTheme.apAccent,
            ),
          ],
        ),
      ],
    );
  }
}

 Indicatore di caricamento compatto per i pulsanti d'azione.

### `class _BrandBackground`
Sfondo decorativo della pagina di login (gradiente verde tenue).

### File: `screens\notifications_screen.dart`

### `class NotificationsScreen`
@brief Centro notifiche per OP e AP.

 Raggiunto dalla campana in alto a destra. Elenca gli eventi rilevanti per il
 ruolo con filtro "tutte / non lette" e azione "segna tutte come lette". I
 dati e lo stato di lettura vivono in [NotificationsStore] (osservabile),
 condiviso con il badge della campana: leggere qui azzera subito il badge.
 Pre-backend i dati sono mock; gli eventi reali arriveranno via push (IIN-19).

### `class _NotificationsScreenState`
Colore di accento del ruolo attivo (OP blu / AP teal).
  final Color accent;

  const NotificationsScreen({super.key, required this.accent});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

### File: `screens\op_dashboard.dart`

### `class OpDashboard`
@brief Console dell'Operatore del Servizio (OP).

 Vista operativa/tattica: coda allarmi real-time (SOS, fuori area, logistica),
 mappa flotta Google con stato telemetrico per mezzo (OP.01/OP.20), filtri
 rapidi e azioni operative (sblocco/blocco remoto, ticket, sospensione utente,
 sconti). Gestione ticket, profilo e notifiche in sezioni dedicate.

### `class _OpHome`
Home dell'Operatore (Centro Operativo).

### `class OpFleetMap`
@brief Stato neutro della coda allarmi quando non ci sono SOS né allerte reali.
   @return La tessera informativa "Nessun allarme attivo".
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

   @brief Tessera di una segnalazione SOS reale, azionabile dall'operatore (OP.08).
   @param context Contesto per il dialog delle azioni.
   @param s Segnalazione SOS da rappresentare.
   @return La [AlarmTile] critica con tocco per la presa in carico/chiusura.
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

   @brief Dialog delle azioni su una segnalazione SOS: presa in carico/chiusura (OP.08).
   @param context Contesto per il dialog e gli avvisi.
   @param s Segnalazione SOS su cui agire.
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

   @brief Converte un'allerta di soglia reale nella relativa tessera allarme.
  
   @param a Allerta tipizzata (`mezzi_area` per OP.02, `batteria` per OP.22).
   @return La [AlarmTile] corrispondente, con colore/icona coerenti al tipo.
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

 @brief Dialog di sblocco/blocco motore remoto di un mezzo (OP.11).

 Self-contained: seleziona un mezzo dalla flotta e invia il comando. Blocco e
 sblocco motore sono cablati agli endpoint reali
 `/api/v1/mezzi/{codice}/blocco-motore` e `/sblocco-motore` (che inoltrano a
 `gateway_iot`).
 @param context Contesto per il dialog e i feedback.
 @param repo Repository flotta iniettabile (default reale; fittizio nei test).
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

 @brief Mappa flotta Google con filtri di stato rapidi (OP.01 / OP.20).

 Estratta come widget riusabile: usata sia nella home (Centro Operativo) che
 nella sezione "Mappa Flotta Live". Cartografia reale via [GoogleCityMap].

### File: `screens\profile_screen.dart`

### `class ProfileScreen`
@brief Schermata di gestione profilo per OP e AP, cablata su `/api/v1/profilo`.

 Raggiunta dalla tendina del profilo in alto a destra. Carica l'anagrafica
 dell'account dal backend e ne salva le modifiche (whitelist nome/cognome/
 telefono); in assenza di rete resta sui dati locali (IIN-6). Sicurezza (MFA,
 cambio password) resta informativa. UT.21 lato dashboard.

### `class _ProfileScreenState`
Colore di accento del ruolo attivo (OP blu / AP teal).
  final Color accent;

   Repository profilo iniettabile (default reale; fittizio nei test).
  final ProfiloApi? profilo;

  const ProfileScreen({super.key, required this.accent, this.profilo});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

### File: `screens\reports_screen.dart`

### `enum ReportPeriod`
Periodo di aggregazione dei report.

### `class ReportsScreen`
@brief Schermata "Reportistica" dell'Amministrazione Pubblica.

 Presenta report periodici aggregati e anonimi sulla mobilita' urbana:
 noleggi per tipologia di mezzo, flussi orari, quota di flotta operativa vs
 manutenzione e impatto ecologico (CO₂ risparmiata). I dati mostrati sono
 gia' aggregati e non riconducibili al singolo cittadino. Pre-backend i
 valori provengono da sorgenti statiche/derivate; l'estrazione reale e
 l'export passeranno per `motore_analitica`.

### `class _ReportsScreenState`
Repository analitiche iniettabile (default reale; fittizio nei test).
  final AnalyticsApi? _analytics;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

### File: `screens\reset_password_screen.dart`

### `class ResetPasswordScreen`
@brief Schermata di recupero password per OP/PA (IIN-11/AP.12/UT.24).

 Flusso a due fasi:
 1. Inserimento email → richiesta codice di reset al backend.
 2. Inserimento codice + nuova password → conferma reset, auto-accesso alla
    home in base al ruolo e notifica SnackBar di cambiare password.

 Il codice via email è monouso, valido 15 min (IIN-11). Il backend emette un
 token di sessione al successo del conferma_reset (il codice email funge da
 secondo fattore, bypassando l'OTP MFA, IIN-9).

### `enum _FaseReset`
Repository di autenticazione iniettabile (default reale; fittizio nei test).
  final AuthApi? _auth;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

 Fase corrente del flusso di reset.

### `class _Spinner`
Fase 1: richiedi il codice di reset (IIN-11).
  Future<void> _inviaRichiesta() async {
    final identita = _emailCtrl.text.trim();
    if (identita.isEmpty) {
      setState(() => _errore = tr('Inserisci email e password.'));
      return;
    }
    setState(() {
      _caricamento = true;
      _errore = null;
    });
    try {
      await _auth.richiediReset(identita);
      if (!mounted) return;
      setState(() {
        _fase = _FaseReset.codice;
        _errore = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.accentBrown,
          content: Text(tr('Codice inviato! Controlla la tua email.')),
        ),
      );
    } on LeafApiException catch (e) {
      if (mounted) setState(() => _errore = e.messaggio);
    } finally {
      if (mounted) setState(() => _caricamento = false);
    }
  }

   Fase 2: conferma il codice e auto-accesso (IIN-11/IIN-9).
  Future<void> _confermaReset() async {
    final codice = _codiceCtrl.text.trim();
    final nuovaPassword = _passwordCtrl.text;

    if (codice.length != 6) {
      setState(() => _errore = tr('Inserisci un codice OTP a 6 cifre.'));
      return;
    }
    final pwdRegex = RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~_.-]).{8,}$');
    if (!pwdRegex.hasMatch(nuovaPassword)) {
      setState(() => _errore = tr(
        'La password deve avere almeno 8 caratteri, con maiuscola, cifra e simbolo.',
      ));
      return;
    }

    setState(() {
      _caricamento = true;
      _errore = null;
    });
    try {
      final esito = await _auth.confermaReset(
        _emailCtrl.text.trim(),
        codice,
        nuovaPassword,
      );
      if (!mounted) return;
      switch (esito.stato) {
        case StatoAccesso.ok:
          _entra(esito.ruolo);
        case StatoAccesso.mfaRichiesta:
          // Codice errato o scaduto (il backend risponde reimpostata=false).
          setState(
            () => _errore = tr('Il codice non è valido o è scaduto.'),
          );
        case StatoAccesso.cambioPasswordRichiesto:
          // Non dovrebbe accadere dopo conferma_reset, ma gestiamo per sicurezza.
          _entra(esito.ruolo);
      }
    } on LeafApiException catch (e) {
      if (mounted) setState(() => _errore = e.messaggio);
    } finally {
      if (mounted) setState(() => _caricamento = false);
    }
  }

   Imposta il ruolo e naviga alla home con notifica di cambiare password.
   @param ruolo Ruolo restituito dal backend ("OP"/"PA").
  void _entra(String? ruolo) {
    final DashboardRole? effettivo = switch (ruolo) {
      'PA' => DashboardRole.publicAdmin,
      'OP' => DashboardRole.operator,
      _ => null,
    };
    if (effettivo == null) {
      setState(
        () => _errore = tr('Accesso riservato a operatori e amministrazioni.'),
      );
      return;
    }
    Session.role = effettivo;
    Session.email = _emailCtrl.text.trim();
    
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pushReplacementNamed(context, '/home');
    // Notifica persistente (IIN-12): consiglio di cambiare la password.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 30),
          backgroundColor: AppTheme.darkGreen,
          content: Text(
            tr(
              'Per sicurezza ti consigliamo di cambiare la password '
              'dalle impostazioni.',
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: _BrandBackground()),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: LeafLogo(size: 64)),
                          const SizedBox(height: 16),
                          Text(
                            tr('Recupero password'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkGreen,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _fase == _FaseReset.email
                                ? tr(
                                    'Inserisci la tua email per ricevere il '
                                    'codice di reset.',
                                  )
                                : tr(
                                    'Inserisci il codice ricevuto e scegli '
                                    'la nuova password.',
                                  ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textGrey,
                            ),
                          ),
                          const SizedBox(height: 28),
                          if (_errore != null) _bannerErrore(_errore!),
                          if (_fase == _FaseReset.email)
                            ..._campiEmail()
                          else
                            ..._campiCodice(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

   Campi della fase 1: inserimento email.
  List<Widget> _campiEmail() {
    return [
      TextField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _inviaRichiesta(),
        decoration: InputDecoration(
          labelText: tr('Email'),
          prefixIcon: const Icon(Icons.email_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: _caricamento ? null : _inviaRichiesta,
        child: _caricamento
            ? const _Spinner()
            : Text(tr('Invia codice')),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed:
            _caricamento ? null : () => Navigator.pop(context),
        child: Text(tr('Torna al login')),
      ),
    ];
  }

   Campi della fase 2: solo codice OTP.
  List<Widget> _campiCodice() {
    return [
      TextField(
        controller: _codiceCtrl,
        keyboardType: TextInputType.number,
        maxLength: 6,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _confermaReset(),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: tr('Codice di reset'),
          counterText: '',
          prefixIcon: const Icon(Icons.shield_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _passwordCtrl,
        obscureText: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _confermaReset(),
        decoration: InputDecoration(
          labelText: tr('Nuova password'),
          prefixIcon: const Icon(Icons.lock_outline),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: _caricamento ? null : _confermaReset,
        child: _caricamento
            ? const _Spinner()
            : Text(tr('Verifica')),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: _caricamento
            ? null
            : () => setState(() {
                _fase = _FaseReset.email;
                _codiceCtrl.clear();
                _errore = null;
              }),
        child: Text(tr('Indietro')),
      ),
    ];
  }

   Banner d'errore inline ad alto contrasto (IIN-2).
  Widget _bannerErrore(String messaggio) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC62828)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFC62828), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              messaggio,
              style: const TextStyle(color: Color(0xFFC62828), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

 Indicatore di caricamento compatto per i pulsanti d'azione.

### `class _BrandBackground`
Sfondo decorativo della pagina di reset (stesso gradiente del login).

### File: `screens\settings_screen.dart`

### `class SettingsScreen`
@brief Schermata Impostazioni per OP e AP.

 Raggiunta dalla tendina del profilo in alto a destra. Raccoglie le
 preferenze utili alla console: lingua, accessibilita' (testo ingrandito),
 preferenze di notifica, cadenza di aggiornamento delle dashboard e
 privacy/GDPR. La modifica del tema/colori non e' consentita. Le preferenze
 sono persistite localmente con `shared_preferences` (localStorage su web) e
 ricaricate all'avvio; la persistenza lato server passera' per
 `gestore_profili_ekyc` / `api_gateway_sicurezza`.

### `class _SettingsScreenState`
Colore di accento del ruolo attivo (OP blu / AP teal).
  final Color accent;

  const SettingsScreen({super.key, required this.accent});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

### File: `screens\support_queue.dart`

### `enum SupportChannel`
Canale da cui proviene la richiesta di assistenza.

### `enum SupportStatus`
Stato di lavorazione della richiesta. OP.08.

### `class SupportRequest`
@brief Richiesta di assistenza utente in coda.

### `class SupportQueue`
@brief Costruisce una richiesta dalla forma del documento ticket della API.
  
   Mappa `stato` (aperto/in_lavorazione/chiuso) sullo stato di vista; il canale
   non è modellato lato server (default chat); l'ultimo messaggio è la risposta
   se presente, altrimenti il messaggio dell'utente. OP.08.
  
   @param d Documento ticket grezzo da `/api/v1/assistenza`.
   @return La [SupportRequest] corrispondente.
  factory SupportRequest.daApi(Map<String, dynamic> d) {
    final stato = '${d['stato'] ?? 'aperto'}';
    final risposta = d['risposta'];
    return SupportRequest(
      id: '${d['_id'] ?? ''}',
      user: '${d['id_utente'] ?? '—'}',
      channel: SupportChannel.chat,
      subject: '${d['oggetto'] ?? ''}',
      lastMessage: '${risposta ?? d['messaggio'] ?? ''}',
      time: '${d['data_ora'] ?? ''}',
      status: _statoDaApi(stato),
      operator: d['id_operatore']?.toString(),
    );
  }

   Mappa lo `stato` del ticket server sullo stato di vista.
  static SupportStatus _statoDaApi(String stato) {
    switch (stato) {
      case 'in_lavorazione':
        return SupportStatus.inCarico;
      case 'chiuso':
        return SupportStatus.risolta;
      default:
        return SupportStatus.nuova;
    }
  }
}

 @brief Coda centralizzata delle richieste di assistenza (OP.08).

 L'Operatore vede le richieste in entrata dai diversi canali, le prende in
 carico, risponde e le chiude. Filtro per stato (nuove / in carico / risolte).
 I dati provengono esclusivamente da `/api/v1/assistenza` (gestore_assistenza_ticket):
 nessun dato di riserva fabbricato, a backend non raggiungibile la coda resta vuota.

### `class _SupportQueueState`
Repository assistenza iniettabile (default reale; fittizio nei test).
  final AssistenzaApi? _assistenza;

  @override
  State<SupportQueue> createState() => _SupportQueueState();
}

### File: `screens\telemetry_viewer.dart`

### `class TelemetryViewer`
@brief Schermata "Telemetria" dell'Operatore (OP.07 + OP.14).

 Consulta il **registro telemetrico** di un mezzo per codice univoco
 (`GET /api/v1/mezzi/{cod}/telemetria`): sblocchi, blocchi, urti, anomalie,
 rilevazioni GPS e batteria, con timestamp e posizione — i dati oggettivi
 utili in caso di istruttoria per sinistri o anomalie (OP.07/OP.14). In
 assenza di rete (IIN-6) mostra un avviso con possibilità di riprovare.

### `class _TelemetryViewerState`
@brief Repository flotta iniettabile (default singleton reale; fake nei test).
  final FlottaApi? repo;

   @brief Codice mezzo precompilato (per i test); altrimenti dal [FleetStore].
  final String? codiceIniziale;

  @override
  State<TelemetryViewer> createState() => _TelemetryViewerState();
}

### File: `screens\threshold_config.dart`

### `class ThresholdConfig`
@brief Schermata "Config Soglie" dell'Operatore (OP.02 + OP.22).

 Due form di configurazione delle soglie di allerta della flotta:
 la **soglia minima di mezzi per area** (OP.02, `POST /soglie/area`) e la
 **soglia di allerta batteria** (OP.22, `POST /soglie/batteria`). L'elenco
 delle aree per il primo form arriva da `/api/v1/aree`; in assenza di rete
 (IIN-6) il form area resta inattivo con avviso, quello batteria è sempre
 utilizzabile. Le allerte risultanti compaiono nella coda del Centro Operativo.

### `class _ThresholdConfigState`
@brief Se true (default), carica le aree reali all'apertura; i test lo disattivano.
  final bool autoload;

   @brief Repository flotta iniettabile (default singleton reale; fake nei test).
  final FlottaApi? fleetRepo;

   @brief Repository aree iniettabile (default singleton reale; fake nei test).
  final AreeApi? areeRepo;

  @override
  State<ThresholdConfig> createState() => _ThresholdConfigState();
}

### File: `screens\ticket_management.dart`

### `enum TicketType`
Tipo di ticket: guasto mezzo o richiesta di assistenza utente. OP.06/OP.19.

### `enum TicketStatus`
Stato di lavorazione del ticket. OP.16/OP.19.

### `enum TicketPriority`
Priorita' dell'intervento.

### `class Ticket`
@brief Ticket di intervento/assistenza (mock pre-backend).

### `enum _DateRange`
@brief Costruisce un [Ticket] di guasto da un documento di `/api/v1/manutenzione`.
   @param doc Documento ticket di manutenzione.
   @return Il ticket mappato, o null se privo di identificativo.
  static Ticket? daApi(Map<String, dynamic> doc) {
    final id = doc['_id']?.toString();
    if (id == null || id.isEmpty) return null;
    final priority = switch (doc['priorita']) {
      'alta' => TicketPriority.alta,
      'bassa' => TicketPriority.bassa,
      _ => TicketPriority.media,
    };
    final status = switch (doc['stato']) {
      'assegnato' => TicketStatus.inCorso,
      'chiuso' => TicketStatus.terminato,
      _ => TicketStatus.daAssegnare,
    };
    return Ticket(
      id: id,
      type: TicketType.guasto,
      vehicleId: (doc['codice_identificativo_mezzo'] ?? doc['id_mezzo'] ?? '—')
          .toString(),
      subject: doc['descrizione_guasto']?.toString() ?? '',
      priority: priority,
      date:
          DateTime.tryParse(doc['data_apertura']?.toString() ?? '') ??
          DateTime.now(),
      status: status,
      technician: doc['id_tecnico']?.toString(),
    );
  }
}

 Finestra temporale per il filtro per data.

### `class TicketManagement`
@brief Schermata di gestione ticket dell'Operatore.

 Elenco filtrabile per tipo (guasto/assistenza), data e stato
 (da assegnare / in corso / terminato). Consente l'assegnazione a un tecnico
 e la chiusura. Copre OP.03 (lista guasti), OP.06 (lista filtrabile),
 OP.16/OP.19 (compila, assegna e traccia i ticket). Pre-backend i dati sono
 mock; le operazioni reali passeranno per `gestore_assistenza_ticket`.

### `class _TicketManagementState`
@brief Se true (default), carica i ticket reali all'apertura; i test lo disattivano.
  final bool autoload;

   @brief Repository manutenzione iniettabile (default singleton reale; fake nei test).
  final ManutenzioneApi? repo;

  @override
  State<TicketManagement> createState() => _TicketManagementState();
}

### File: `screens\ticket_management_form.dart`

### `class _CreateTicketForm`
@brief Dialog di compilazione di un nuovo ticket di intervento/assistenza.

 Copre OP.16 / OP.19: l'Operatore seleziona il tipo (guasto mezzo o assistenza
 utente), indica il codice del mezzo e l'oggetto, imposta la priorita' e puo'
 assegnare subito un tecnico. Se un tecnico viene scelto il ticket nasce
 "In corso", altrimenti "Da assegnare". Widget con stato dedicato: possiede i
 controller dei campi e li dispone in [dispose] (eseguito quando la route e'
 realmente rimossa), evitando il rilascio anticipato che corromperebbe
 l'albero alla chiusura del dialog. Ritorna il [Ticket] creato via
 `Navigator.pop`, oppure null se annullato.

### File: `screens\user_admin.dart`

### `class UserAdmin`
@brief Gestione Utenti e Amministratori Pubblici (OP.10 / OP.17 / OP.18).

 Due viste commutabili: gli account utente (sospensione per violazioni — OP.10
 — e riattivazione manuale — OP.18) e gli account di Amministrazione Pubblica,
 creati esclusivamente dall'Operatore tramite provisioning (OP.17, niente
 registrazioni pubbliche; primo accesso con cambio password obbligatorio,
 IIN-12). I dati sono alimentati da `/api/v1/utenti` tramite [UsersAdminStore]
 (fallback ai dati di riserva senza rete, IIN-6).

### `class _UserAdminState`
@brief Se true (default), carica i dati reali all'apertura; i test lo disattivano.
  final bool autoload;

  @override
  State<UserAdmin> createState() => _UserAdminState();
}

### File: `widgets\city_map.dart`

### `class CityMap`
@brief Mappa schematica interattiva della citta' (Bari).

 Resa con [CustomPaint] (terra/mare/quartieri + eventuale heatmap) e marker
 posizionati come widget sovrapposti: non richiede chiavi API esterne e si
 visualizza in qualunque browser. Le coordinate dei mezzi, delle ricariche e
 delle fermate TPL coincidono con quelle di [AppMobileUtente].
 OP.01 (flotta live), AP.05/AP.10 (heatmap/concentrazione), UT.14 (ricariche).

### `class _CityPainter`
Tipologia di mezzo da mostrare; null = tutte.
  final VehicleType? typeFilter;

   Stati operativi da mostrare; null = tutti.
  final Set<VehicleStatus>? statusFilter;

  final bool showVehicles;
  final bool showCharging;
  final bool showTpl;

   Mostra l'overlay heatmap di utilizzo/concentrazione (vista AP).
  final bool showHeatmap;

   Mostra la legenda in basso a sinistra.
  final bool showLegend;

  const CityMap({
    super.key,
    this.typeFilter,
    this.statusFilter,
    this.showVehicles = true,
    this.showCharging = true,
    this.showTpl = true,
    this.showHeatmap = false,
    this.showLegend = true,
  });

  bool _vehiclePasses(Vehicle v) {
    if (typeFilter != null && v.type != typeFilter) return false;
    if (statusFilter != null && !statusFilter!.contains(v.status)) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final vehicles = showVehicles
                ? FleetData.vehicles.where(_vehiclePasses).toList()
                : const <Vehicle>[];

            return Stack(
              children: [
                // Sfondo cartografico + heatmap.
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CityPainter(
                      heatmap: showHeatmap,
                      heatPoints: showHeatmap
                          ? FleetData.vehicles
                              .map((v) => MapBounds.project(v.lat, v.lng))
                              .toList()
                          : const [],
                    ),
                  ),
                ),
                // Fermate TPL (sistemaTPL integrato nella mappa).
                if (showTpl)
                  for (final s in FleetData.tplStops)
                    _marker(
                      w,
                      h,
                      s.lat,
                      s.lng,
                      tooltip: '${s.name}\n${tr('Trasporto Pubblico (TPL)')}',
                      color: const Color(0xFF0288D1),
                      icon: Icons.directions_bus,
                      size: 22,
                    ),
                // Stazioni di ricarica.
                if (showCharging)
                  for (final c in FleetData.charging)
                    _marker(
                      w,
                      h,
                      c.lat,
                      c.lng,
                      tooltip:
                          '${tr('Ricarica')} – ${c.area}\n${c.slots} ${tr('posti')}',
                      color: AppTheme.statusLowBattery,
                      icon: Icons.bolt,
                      size: 22,
                    ),
                // Veicoli.
                if (showVehicles)
                  for (final v in vehicles)
                    _marker(
                      w,
                      h,
                      v.lat,
                      v.lng,
                      tooltip:
                          '${v.id} · ${tr(vehicleTypeLabel(v.type))}\n'
                          '${tr('Batteria')}: ${v.battery}%\n'
                          '${tr('Stato')}: ${tr(vehicleStatusLabel(v.status))}',
                      color: vehicleStatusColor(v.status),
                      icon: vehicleTypeIcon(v.type),
                      size: 24,
                    ),
                if (showLegend)
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: _legend(),
                  ),
                if (showVehicles)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: _counter(vehicles.length),
                  ),
              ],
            );
          },
        ),
      );
    });
  }

  Widget _marker(
    double w,
    double h,
    double lat,
    double lng, {
    required String tooltip,
    required Color color,
    required IconData icon,
    required double size,
  }) {
    final p = MapBounds.project(lat, lng);
    return Positioned(
      left: p.dx * w - size / 2,
      top: p.dy * h - size / 2,
      child: Tooltip(
        message: tooltip,
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
        decoration: BoxDecoration(
          color: AppTheme.textDark.withAlpha(235),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(icon, size: size * 0.55, color: color),
        ),
      ),
    );
  }

  Widget _counter(int n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(235),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 6),
        ],
      ),
      child: Text(
        '$n ${tr('mezzi visualizzati')}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textDark,
        ),
      ),
    );
  }

  Widget _legend() {
    Widget row(Color c, String label) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: c, width: 2.5),
                ),
              ),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 11)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(235),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tr('Legenda'),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textGrey,
            ),
          ),
          const SizedBox(height: 4),
          row(AppTheme.statusAvailable, tr('Disponibile')),
          row(AppTheme.statusInUse, tr('In uso')),
          row(AppTheme.statusMaintenance, tr('In manutenzione')),
          row(AppTheme.statusLowBattery, tr('Ricarica')),
          row(const Color(0xFF0288D1), tr('Trasporto Pubblico (TPL)')),
        ],
      ),
    );
  }
}

 @brief Painter dello sfondo cartografico schematico + heatmap.

### File: `widgets\common.dart`

### `class QuickActionButton`
@brief Pulsante azione rapida dei pannelli laterali OP/AP.

 Se [onPressed] e' fornito esegue l'azione collegata (apertura dialog o
 navigazione a una sezione); altrimenti mostra un feedback "in sviluppo": il
 comando reale passera' per l'`api_gateway_sicurezza` quando il server sara'
 disponibile.

### `class AlarmTile`
Azione collegata; se null il pulsante mostra il feedback pre-backend.
  final VoidCallback? onPressed;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.accent,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: accent,
            side: BorderSide(color: accent.withAlpha(90)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            alignment: Alignment.centerLeft,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: Icon(icon, size: 18),
          label: Text(
            tr(label),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          onPressed: onPressed ??
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppTheme.accentBrown,
                    content: Text(
                      '${tr(label)} — ${tr('Funzione disponibile con il backend')}',
                    ),
                  ),
                );
              },
        ),
      ),
    );
  }
}

 @brief Tile di un allarme/notifica nella coda real-time dell'Operatore.

### `class SectionHeader`
@brief Azione opzionale al tocco della tessera (es. presa in carico SOS, OP.08).
  final VoidCallback? onTap;

  const AlarmTile({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final contenuto = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right, color: AppTheme.textGrey, size: 20),
        ],
      ),
    );
    if (onTap == null) return contenuto;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: contenuto,
    );
  }
}

 @brief Intestazione di sezione (titolo + sottotitolo opzionale).

### `class PanelCard`
@brief Card pannello generica con titolo e contenuto.

### File: `widgets\dashboard_shell.dart`

### `class DashboardSection`
@brief Voce del menu laterale: icona, etichetta (chiave i18n) e contenuto.
@immutable

### `enum _TopView`
Viste raggiungibili dalla top bar (fuori dal menu laterale).

### `class DashboardScope`
@brief Accesso alla navigazione dello [DashboardShell] dai discendenti.

 Espone alla sottostante gerarchia (es. i pannelli rapidi nella home) il
 cambio di sezione del menu laterale, senza introdurre pattern MVC: e' un
 semplice [InheritedWidget]. Usare [jumpTo] con l'indice o, piu' comodo,
 [indexOfLabel] per risolvere l'indice dalla chiave i18n della voce di menu.

### `class DashboardShell`
Apre la sezione del menu laterale all'indice indicato.
  final void Function(int index) jumpTo;

   Indice della sezione con la [label] data, o -1 se assente.
  final int Function(String label) indexOfLabel;

  const DashboardScope({
    super.key,
    required this.jumpTo,
    required this.indexOfLabel,
    required super.child,
  });

  static DashboardScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DashboardScope>();

   Risolve [label] e, se presente, apre la relativa sezione.
  void jumpToLabel(String label) {
    final i = indexOfLabel(label);
    if (i >= 0) jumpTo(i);
  }

  @override
  bool updateShouldNotify(DashboardScope oldWidget) => false;
}

 @brief Telaio comune delle console OP/AP: top navigation bar + side menu.

 La stessa impalcatura serve entrambi i ruoli; cambiano [sections], colore
 [accent] e profilo. La tendina del profilo (in alto a destra) apre gestione
 profilo o impostazioni; la campana apre il centro notifiche con badge "non
 lette" alimentato live da [NotificationsStore]. Refresh metriche dichiarato a
 5s in barra (IIN-20).

### `class _DashboardShellState`
Contenuto della schermata "Gestione Profilo" (tendina in alto a destra).
  final WidgetBuilder profileBuilder;

   Contenuto del centro notifiche (campana in alto a destra).
  final WidgetBuilder notificationsBuilder;

   Contenuto della schermata "Impostazioni" (tendina in alto a destra).
  final WidgetBuilder settingsBuilder;

   Repository di autenticazione per il logout (default reale; fittizio nei test).
  final AuthApi? auth;

  const DashboardShell({
    super.key,
    required this.accent,
    required this.sections,
    required this.profileLabel,
    required this.profileBuilder,
    required this.notificationsBuilder,
    required this.settingsBuilder,
    this.auth,
  });

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

### `class SectionPlaceholder`
Indice della prima sezione con la chiave i18n [label], o -1 se assente.
  int _indexOfLabel(String label) =>
      widget.sections.indexWhere((s) => s.label == label);

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return DashboardScope(
        jumpTo: _openSection,
        indexOfLabel: _indexOfLabel,
        child: Scaffold(
          backgroundColor: AppTheme.backgroundBeige,
          body: Column(
            children: [
              _topBar(context),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sideMenu(),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: _content(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _content(BuildContext context) {
    switch (_topView) {
      case _TopView.profile:
        return widget.profileBuilder(context);
      case _TopView.notifications:
        return widget.notificationsBuilder(context);
      case _TopView.settings:
        return widget.settingsBuilder(context);
      case _TopView.none:
        return widget.sections[_selected].builder(context);
    }
  }

  Widget _topBar(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            const LeafLogo(size: 34, showWordmark: true),
            const Spacer(),
            const LangToggle(),
            const SizedBox(width: 16),
            _mfaBadge(),
            const SizedBox(width: 16),
            _alarmsBell(),
            const SizedBox(width: 16),
            _profileMenu(context),
          ],
        ),
      ),
    );
  }

  Widget _mfaBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield, size: 15, color: AppTheme.darkGreen),
          const SizedBox(width: 6),
          Text(
            tr('MFA: Attivo'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _alarmsBell() {
    final selected = _topView == _TopView.notifications;
    // Badge "non lette" live dallo store condiviso: leggere nel centro
    // notifiche lo azzera immediatamente (fix campana "sempre 3").
    return Tooltip(
      message: tr('Notifiche'),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _topView = _TopView.notifications),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: ValueListenableBuilder<int>(
            valueListenable: NotificationsStore.revision,
            builder: (context, _, _) {
              final unread = NotificationsStore.unreadCount;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: selected ? widget.accent : AppTheme.textDark,
                  ),
                  if (unread > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.alarmCritical,
                          shape: BoxShape.circle,
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$unread',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

   @brief Esegue il logout reale e torna alla schermata di login.
  
   Chiama `AuthApi.esci()` (POST `/auth/logout` + cancellazione del token
   custodito): best-effort sulla rete, ma il token locale è sempre rimosso.
   La navigazione verso `/login` avviene comunque al termine.
  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    await (widget.auth ?? authRepository).esci();
    if (!mounted) return;
    navigator.pushReplacementNamed('/login');
  }

  Widget _profileMenu(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: widget.profileLabel,
      onSelected: (v) {
        switch (v) {
          case 'profile':
            setState(() => _topView = _TopView.profile);
          case 'settings':
            setState(() => _topView = _TopView.settings);
          case 'logout':
            _logout(context);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              const Icon(Icons.manage_accounts_outlined,
                  size: 18, color: AppTheme.textDark),
              const SizedBox(width: 10),
              Text(tr('Gestione Profilo')),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              const Icon(Icons.settings_outlined,
                  size: 18, color: AppTheme.textDark),
              const SizedBox(width: 10),
              Text(tr('Impostazioni')),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout, size: 18, color: AppTheme.textDark),
              const SizedBox(width: 10),
              Text(tr('Logout')),
            ],
          ),
        ),
      ],
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: widget.accent.withAlpha(40),
            child: Icon(Icons.person, size: 18, color: widget.accent),
          ),
          const SizedBox(width: 8),
          Text(
            widget.profileLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: AppTheme.textGrey),
        ],
      ),
    );
  }

  Widget _sideMenu() {
    return Container(
      width: 248,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: widget.sections.length,
              itemBuilder: (context, i) {
                final s = widget.sections[i];
                final selected = i == _selected && _topView == _TopView.none;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Material(
                    color: selected
                        ? widget.accent.withAlpha(24)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _openSection(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              s.icon,
                              size: 20,
                              color: selected
                                  ? widget.accent
                                  : AppTheme.textGrey,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                tr(s.label),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: selected
                                      ? widget.accent
                                      : AppTheme.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  tr('Aggiornamento ogni 5s'),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

 @brief Segnaposto per le sezioni non ancora collegate al backend.

### File: `widgets\google_city_map.dart`

### `const Color`
Colore del layer ricarica (coerente con i marker e la legenda).

### `const Color`
Colore del layer trasporto pubblico (sistemaTPL integrato).

### `class GoogleCityMap`
@brief Mappa Google reale della citta' (Bari) per le console OP/AP.

 Sostituisce la mappa schematica dove e' richiesta la cartografia reale: usa
 `google_maps_flutter` (ServizioMappa / MapInterface) con la stessa API key
 di [AppMobileUtente]. I marker di flotta, ricariche e fermate TPL sono
 alimentati da [FleetData] (sistemaTPL integrato nativamente nella mappa,
 vincolo architetturale) e disegnati con le **stesse icone dell'app utente**
 (cerchio bianco + glifo del tipo di mezzo) per renderli facilmente
 riconoscibili; il colore del marker codifica lo stato operativo del mezzo.
 Supporta overlay heatmap (cerchi di concentrazione) e disegno di poligoni di
 geofencing.

### `class _GoogleCityMapState`
Stati operativi da mostrare; null = tutti. OP.01 / OP.20.
  final Set<VehicleStatus>? statusFilter;

   Tipologie da mostrare; null = tutte. OP.01 / OP.20 / UT.05.
  final Set<VehicleType>? typeFilters;

  final bool showVehicles;
  final bool showCharging;
  final bool showTpl;

   Cerchi traslucidi di concentrazione (approssimazione heatmap per AP).
  final bool showHeatCircles;

   Mostra la legenda in basso a sinistra.
  final bool showLegend;

   Poligoni di geofencing da disegnare sopra la mappa.
  final Set<Polygon> polygons;

   Polilinee aggiuntive (es. perimetro in corso di disegno).
  final Set<Polyline> polylines;

   Marker aggiuntivi (es. vertici dell'area in disegno).
  final Set<Marker> extraMarkers;

   Callback al tocco sulla mappa (usata per disegnare le aree). null = mappa
   in sola consultazione.
  final void Function(LatLng position)? onTap;

  const GoogleCityMap({
    super.key,
    this.statusFilter,
    this.typeFilters,
    this.showVehicles = true,
    this.showCharging = true,
    this.showTpl = true,
    this.showHeatCircles = false,
    this.showLegend = true,
    this.polygons = const {},
    this.polylines = const {},
    this.extraMarkers = const {},
    this.onTap,
  });

   Centro cartografico (coincide col fallback di [AppMobileUtente]).
  static const LatLng _center = LatLng(41.1172, 16.8726);
  static const double _initialZoom = 12.5;

  @override
  State<GoogleCityMap> createState() => _GoogleCityMapState();
}

### File: `widgets\lang_toggle.dart`

### `class LangToggle`
@brief Selettore lingua ITA/ENG. IIN-7.

 Aggiorna [appLanguage]: tutte le viste avvolte in [Translated] si
 ridisegnano live nella lingua scelta.

### File: `widgets\leaf_logo.dart`

### `class LeafLogo`
@brief Logo ufficiale LEAF Mobility.

 Renderizza l'asset vettoriale `fulllogoSVG.svg` — lo stesso identico file
 usato da [AppMobileUtente] (splash, login, drawer) — per garantire piena
 coerenza di brand tra i due client. Reso via [flutter_svg], nitido a
 qualunque dimensione.

### File: `widgets\metric_card.dart`

### `class MetricCard`
@brief Card metrica della dashboard (titolo + righe valore/etichetta).

 Blocco visivo riusato dalle home di OP e AP per le metriche in tempo reale
 (refresh ≤ 5s, IIN-20). Niente logica di business: pura presentazione.

### `class MetricRow`
@brief Riga "pallino colorato + etichetta + valore" per le card metrica.

### `class BigStat`
@brief Grande numero con etichetta sottostante (KPI singolo).

### File: `widgets\stato_vista.dart`

### `class VistaCaricamento`
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

### `class VistaVuota`
@brief Crea lo stato di errore.
   @param messaggio Messaggio di errore leggibile.
   @param onRiprova Callback del pulsante "Riprova" (null = pulsante assente).
   @param offline true per mostrare icona/copy di assenza connessione.
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
      messaggio: offline
          ? tr('Sei offline. Controlla la connessione.')
          : messaggio,
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
              offline
                  ? tr('Sei offline. Controlla la connessione.')
                  : tr('Qualcosa è andato storto'),
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
 schermate cablate ai repository non duplichino la stessa logica.

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

