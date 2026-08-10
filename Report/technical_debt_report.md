# LEAF Mobility — Technical Debt Report

> Registro del debito tecnico (metodo SQALE). Aggiornare a ogni sprint.
> **Soglia di allarme:** debt ratio > 20% → sospendere nuove feature e rientrare.
> Ratio = costo di remediation / costo di sviluppo del codice esistente.

> **Open Source Note:** This technical debt report was maintained throughout the development of LEAF Mobility using the SQALE method. External contributors should refer to this document to understand the project's quality standards, how technical debt was measured, and the historical decisions made regarding refactoring and architectural alignment.

## Sintesi

| Data | Componenti misurati | LOC | Remediation stimata | Debt ratio | Rating |
|---|---|---|---|---|---|
| 07/06/2026 | app_mobile_utente (1.0.0+15) · web_dashboard (alpha.18) | ~16.400 | ~84h | ~24% | **D** |
| 08/06/2026 | app_mobile_utente (1.0.0+15) · web_dashboard (alpha.18) | ~16.400 | ~62h | ~20% | **C** (borderline D) |
| 10/06/2026 | app_mobile_utente (1.0.0+15) · web_dashboard (alpha.18) | ~16.400 (+~1.400 di test) | ~51h | ~16% | **C** |
| 18/06/2026 (000027) | app_mobile_utente (alpha.15) · web_dashboard (alpha.18) | ~16.400 (+~1.400 di test) | ~50h | ~15% | **C** |
| 18/06/2026 (000028) | app_mobile_utente (alpha.15) · web_dashboard (alpha.18) | ~16.400 (+test) | ~42h | ~13% | **C** |
| 22/06/2026 (000034) | app_mobile_utente (alpha.15) · web_dashboard (alpha.18) | ~16.400 (+test) | ~27h | ~8% | **B** |
| 26/06/2026 (000059) | app_mobile_utente (alpha.18) · web_dashboard (alpha.21) | ~17.300 (+test) | ~27h | ~7,8% | **B** |
| 27/06/2026 (cleanup) | app_mobile_utente (alpha.18) · web_dashboard (alpha.21) | ~17.300 (+test) | ~27h | ~7,8% | **B** |
| 28/06/2026 (Sprint 3 concluso) | app_mobile_utente (alpha.31) · web_dashboard (alpha.22) · server | ~17.300 client (+server, +test) | ~27h | ~7,8% | **B** |
| 04/08/2026 (CI/CD check) | app_mobile_utente · web_dashboard · server | ~17.300 client (+server, +test) | ~13h | ~3,8% | **A** |

**Scala SQALE:** A ≤5% · B 6–10% · C 11–20% · D 21–50% · E >50%.

> **Verifica 04/08/2026.** Ricalcolo del debito tecnico dopo l'allineamento alle direttive: le voci TD-06 (ValueNotifier sancito dalle direttive) e TD-10 (Cifratura at-rest IIN-4 implementata lato server/Firestore) sono definitivamente CHIUSE. Il debito scende a 13h (3,8%), portando il rating complessivo ad **A**.

> **Chiusura Sprint 3 (28/06/2026, progetto consegnato 29/06/2026).** Sprint 3 concluso con
> **rating B (~7,8%)** stabile. Backend implementato end-to-end (tre tier + `runtime/` +
> `console_operativa/` + `/api/v1`), persistenza Cloud Firestore server-mediata e cifratura
> AES-256-GCM at-rest; clients cablati al backend reale (mobile `1.0.0-alpha.31`, web
> `1.0.0-alpha.22`). Gate finali verdi: server `ruff`/`ruff format`/`mypy --strict` 0 · `pytest`
> **211** (runtime ~91–92% cov) · mobile `flutter analyze` 0 / `flutter test` **75** · web
> `flutter analyze` 0 / `flutter test` **90**. Voci residue (TD-05/06/10) e integration backlog
> (TD-02/03) restano aperte/tracciate come da milestone di rientro verso rating A; non concorrono
> a una soglia d'allarme (B « 20%). Le righe di test non concorrono al denominatore.

> **Revisione 08/06/2026 — applicazione coerente della §17.** La baseline del 07/06
> contava TD‑02 (mock nei widget) e TD‑03 (assenza `dio`) come debito. La §17 di
> `wiki/DIRECTIVES.md` stabilisce però che i dati mock UI non ancora cablati al backend sono
> **integration backlog, NON debito**, finché l'endpoint corrispondente non esiste.
> Riclassificandoli (‑22h ≈ TD‑02 16h + quota TD‑03), il debito reale scende a ~62h
> e il ratio rientra a ~20% (**rating C, sotto la soglia d'allarme**). Il debito
> residuo non è dominato dal volume ma da **un solo elemento critico** (chiave API
> Google Maps web ancora esposta, TD‑01) e dalla **copertura test ~nulla** (TD‑04).

> Nota di scope: il `server/` (tre tier) è ancora non implementato → il diagramma
> delle classi è realizzato ~0%. Questo è *completamento*, non debito: il debito
> qui misurato riguarda solo il codice client effettivamente consegnato.

## Legenda

### Termini SQALE
- **Debt ratio** — costo di remediation / costo di sviluppo del codice esistente (convenzione: ~50 LOC/h sul solo codice di produzione; il codice di test non concorre al denominatore).
- **Remediation (stima)** — ore di lavoro stimate per estinguere la voce di debito.
- **Rating** — A ≤5% · B 6–10% · C 11–20% · D 21–50% · E >50%; soglia d'allarme >20% (AG-CI-08, §17: halt delle nuove feature).
- **Severità** — 🔴 Critico · 🟠 Alto · 🟡 Medio · 🟢 Basso.
- **Stati** — *Aperto*: debito attivo, concorre al ratio · *Aperto (ridotto)*: parzialmente rimediato, concorre con la stima residua · *Mitigato*: rischio abbattuto, resta un'azione residua · *Backlog (§17)*: integration backlog, NON concorre al ratio finché il backend non esiste · *Chiuso*: estinto, non concorre.
- **Tipi** — Sicurezza / Architettura / Affidabilità / Manutenibilità / Documentazione / Processo.
- **LOC** — Lines Of Code del solo codice di produzione (`lib/`, `server/`); convenzione di produttività ~50 LOC/h per stimare il costo di sviluppo al denominatore del ratio.

### Metriche di verifica (gate di qualità §12.2)

| Metrica | Definizione | Target | Stato attuale |
|---|---|---|---|
| **Coverage lcov** | Copertura di linea prodotta da `flutter test --coverage` nel formato LCOV (`coverage/lcov.info`): % = LH/LF, cioè *lines hit* (righe eseguite da almeno un test) / *lines found* (righe eseguibili strumentate). **Caveat:** lcov conteggia solo i file caricati (importati) da almeno un test; i file mai importati non compaiono, quindi la % è ottimistica rispetto all'intero `lib/`. | **≥ 80%** (TD-04; stesso target che AG-CI-04 impone al backend) — 100% non è un obiettivo cost-effective | **app 89,8% · web 82,7%** (18/06/2026, sui file caricati) ✅ |
| **AG-CI-05** | `flutter analyze` — analisi statica Dart (lint set `flutter_lints` da `analysis_options.yaml`) | **0 issues** | 0 + 0 ✅ |
| **AG-CI-06** | `flutter test` — esito delle suite widget/unit | **100% pass** | **75/75 app** + **90/90 web** ✅ (28/06, stato finale Sprint 3) |
| **AG-CI-08** | Debt ratio SQALE confrontato con questo report | **< 20%** (rating ≤ C); oltre → halt feature (§17) | ~8% (**rating B**) ✅ |
| **AG-CI-09** | Scansione mock-in-UI: dataset `static const` cablati nei widget anziché in un layer dati | dati in `data/`/repository | migliorato (22/06: dato estratto in file `*_data.dart` dedicati per le 3 schermate piu' grandi, TD-08); 24/06: card mock della reportistica web (`_hourlyFlows`/`_co2Trend`) marcate con badge «dato stimato» per trasparenza; il layer repository reale resta backlog §17 (TD-02) |
| **AG-CI-01** | `ruff check server` — lint del tier runtime | 0 issues | **0** ✅ (21/06) |
| **AG-CI-02** | `mypy --strict server` — analisi statica dei tipi | 0 errori | **0** su 42 file ✅ (21/06; +`types-psutil`/`types-passlib`) |
| **AG-CI-03** | `ruff format --check server` — formato | conforme | **conforme** ✅ (21/06) |
| **AG-CI-04** | `pytest server/tests` — test + copertura tier runtime | ≥80% | **211 pass** + 35 subtest, runtime ~**91–92%** ✅ (28/06, stato finale Sprint 3) |
| AG-SEC-01 | Validazione formato KYC (solo PDF/JPG/PNG, IIN-6) | reject altre estensioni | **VERDE** (24/06, `tests/security/test_kyc_format.py`) ✅ |
| AG-SEC-02 | Cifratura AES-256 at-rest dei campi 🔒 e documenti KYC (IIN-4) | campi sensibili cifrati a riposo | **VERDE** (24/06, `tests/security/test_encryption.py`, AES-256-GCM reale) ✅ |
| AG-SEC-03 | MFA obbligatorio OP/PA (IIN-9) | login impossibile senza OTP valido | **VERDE** (24/06, `tests/security/test_mfa.py`) ✅ |
| AG-SEC-04 | Anonimizzazione dati PA (IIN-15) | output dashboard non re-identificabile | **VERDE** (24/06, `tests/security/test_anonymization.py`) ✅ |
| AG-SEC (E2E live) | Verifica dei gate sicurezza contro l'emulatore Firestore live | 9/9 controlli | **VERDE** (24/06, `tests/verifica_emulatore_live.py` su emulatore `firebase-tools` 15.22.1: cifratura AES-256 at-rest, MFA OP/PA, anonimizzazione e formato KYC su Firestore vero) ✅ |
| AG-SEC (E2E client→server) | Verifica E2E completa dai client reali via `/api/v1` | — | **DEFERRED** (dipende dal cablaggio client, FASE 2) |

### Strumenti white-box di test (remediation TD-04, Sprint 3)
Elementi che vivono **esclusivamente in `client/*/test/`**: non fanno parte del prodotto,
non sono modellati nella progettazione (class diagram) e **non entrano negli artefatti di
rilascio** — `flutter build apk`/`flutter build web` compila solo `lib/`, e le
`dev_dependencies` non vengono incluse nei build di release. Nessun impatto su TD-11.

| Strumento | Dove | Cosa fa |
|---|---|---|
| **Fake del ServizioMappa** (`FakeGoogleMapsPlatform`, `installFakeGoogleMapsPlatform`) | `web_dashboard/test/helpers/fake_maps_platform.dart` | Sostituisce l'istanza di piattaforma di `google_maps_flutter` con una vista inerte (`SizedBox`): le dashboard OP/AP che montano `GoogleCityMap` diventano testabili in `flutter test`, dove la platform view nativa non esiste. Richiede la dichiarazione dev di `google_maps_flutter_platform_interface` (già transitiva, nessun pacchetto nuovo). |
| **Stub del canale permessi** (`stubLocationGranted`) | `app_mobile_utente/test/sos_screen_test.dart` | Risponde "granted" sul method channel di `permission_handler` con gli strumenti integrati di flutter_test: la SOSScreen legge lo stato del permesso GPS senza piattaforma reale. |
| **Mock delle preferenze** (`SharedPreferences.setMockInitialValues`) | `app_mobile_utente/test/profile_store_test.dart` | Archivio in-memory fornito dal plugin stesso: ProfileStore persiste/rilegge senza storage reale. |
| **Helper di montaggio** (`buildLoginApp`, `pumpOpDashboard`, `pumpTicketScreen`, …) | entrambi i client, `test/*.dart` | Montano la schermata sotto test in una `MaterialApp` minimale con route `/home` fittizie (evitano di costruire schermate con mappa/geolocalizzazione fuori dal perimetro del test). |
| **Reset degli store statici** (`resetProfileStore`, azzeramento `bookingStore`/`Session` in `setUp`) | entrambi i client, `test/*.dart` | Riportano gli store osservabili (ValueNotifier statici) allo stato di fabbrica tra un test e l'altro, evitando contaminazione di stato. |
| **`textScaler` 0.8 nei test dashboard** | `web_dashboard/test/op_dashboard_test.dart`, `ap_dashboard_test.dart` | Compensa il font di test "Ahem" (ogni glifo largo un em pieno) che farebbe traboccare di pochi px etichette compatte del telaio; a runtime, con i font reali, l'overflow non esiste. |

> **Nota di rilascio:** trattandosi di *test double* e utility interne al processo di
> verifica (AG-CI-06), questi elementi sono assimilabili all'infrastruttura di CI: vanno
> versionati (servono a rieseguire i controlli) ma esclusi da APK/bundle web finali, dal
> class diagram di prodotto e dal conteggio LOC del denominatore SQALE.

## Registro voci

| ID | Voce | Severità | Tipo | File chiave | Stima | Stato |
|---|---|---|---|---|---|---|
| TD-01 | API key Google Maps in chiaro — **Android risolto** (placeholder `${MAPS_API_KEY}` + `secrets.properties.example`), **web mitigato** (commit `435eaee`: chiave letta a runtime da `web/maps_config.js` gitignorato, template `.example` versionato). La rotazione della chiave presente nella history git è **rischio accettato**: repository privato, nessuna esposizione pubblica → non necessaria | 🔴 Critico | Sicurezza | `client/web_dashboard/web/index.html` | — | Chiuso (rischio accettato 18/06: repo privato, nessuna esposizione; rotazione non necessaria) |
| TD-02 | Dati mock cablati dentro i widget (no layer dati) — **cablati a backend reale**: mobile (login/MFA, mappa, home, cronologia, prenotazione/avvio, profilo, assistenza UT.09, ricerca percorsi UT.07; **+ Task 3: SOS UT.20, notifiche UT.15/19, stima/valutazione UT.03/16, abbonamenti UT.18, pagamenti UT.11, KYC UT.22.2, pausa/riprendi UT.12**) e web (login OP/PA, flotta, analitiche, geofencing, assistenza, profilo, gestione utenti/AP, manutenzione, sconti, eventi, soglie, telemetria — Task 2 chiusa). **+ UT.14 stazioni di ricarica 26/06**: `map_tab` cablata a `GET /stazioni` con fallback offline). **Residuo mock mobile azzerato**: tutte le schermate dei due client sono ora cablate al backend reale | 🟠 Alto | Integration backlog (§17) | — | — | Chiuso per costruzione (tutte le schermate cablate, 26/06) |
| TD-03 | Nessun layer di rete (`dio` assente, richiesto da §6) | 🟠 Alto | Integration backlog (§17) | client (entrambe) | — | Chiuso (layer `dio` implementato in entrambi i client e cablato) |
| TD-04 | Copertura test — **chiuso (Sprint 3, 18/06)**: da 61 a **76 test deterministici** (39 app + 37 web); aggiunti dettaglio corsa/percorso (UT.17/UT.07/UT.08/UT.09/UT.25) lato app e reportistica, segnala eventi (AP.09), geofencing con fake ServizioMappa (OP.04), gestione utenti/AP, coda assistenza (OP.08), impostazioni e profilo OP/AP lato web. Coverage lcov sui file caricati: **app 89,8%, web 82,7%** — target ≥80% raggiunto su entrambi i client. Restano fuori dal lcov solo screen non importati da alcun test (MapTab/home_tab: richiedono fake geolocator) — completamento incrementale, non debito | 🟠 Alto | Affidabilità | `client/*/test/` | — | Chiuso (target ≥80% raggiunto 18/06) |
| TD-05 | Dizionari i18n duplicati (393+356 righe) | 🟡 Medio | Manutenibilità | `client/app_mobile_utente/lib/l10n.dart`, `client/web_dashboard/lib/l10n.dart` | 8h | Aperto |
| TD-06 | Stato globale mutabile statico (`ValueNotifier`) — l'approccio è ora sancito da §6 (18/06) | 🟡 Medio | Manutenibilità | `profile_store.dart`, `booking_store.dart`, `web_dashboard/lib/session.dart` | — | Chiuso (approccio sancito definitivamente dalle direttive) |
| TD-07 | Doxygen §7.1 parziale sui metodi widget — **ridotto (Sprint 3, 22/06)**: completato il Doxygen (`@param`/`@return`/`@brief`) sui metodi e widget di supporto delle tre schermate piu' dense (`search_screen`, `map_tab`, `ticket_management` e relativi part). Residuo sulle schermate minori | 🟡 Medio | Documentazione | client (screens minori residui) | 3h | Aperto (ridotto) |
| TD-08 | File widget grandi (dati+UI+logica) — **ridotto (Sprint 3, 22/06)**: separato il dato dalla UI con file `part`/`part of` (identificatori privati e siti d'uso invariati, nessun rename §3). `search_screen.dart` 589→**498** (+ `search_screen_data.dart`), `map_tab.dart` 708→**431** (+ `map_tab_data.dart`), `ticket_management.dart` 774→**505** (+ `ticket_management_data.dart` + `ticket_management_form.dart`). Residuo: file ancora ~500 righe (UI+logica insieme) | 🟡 Medio | Manutenibilità | `*_data.dart`, `ticket_management_form.dart` | 2h | Aperto (ridotto) |
| TD-09 | CI/CD §12 non eseguibile (nessun workflow, gate manuale) | 🟡 Medio | Processo | `.github/workflows/` | 6h | Chiuso (`ci.yml` copre AG‑CI‑05/06) |
| TD-10 | KYC/documenti on-device senza cifratura (IIN-4 AES-256) | 🟢 Basso | Sicurezza | `client/app_mobile_utente/lib/screens/sensitive_data_screen.dart` | — | Chiuso (IIN-4 risolto dal backend che gestisce la cifratura in Firestore, sul client sono file temporanei) |
| TD-11 | Disallineamento class diagram ↔ client implementato | 🟡 Medio | Documentazione | `wiki/raw/assets/Leaf_Mobility_Classi.jpg` | — | Chiuso (decisione team 22/06: i diagrammi riportano le funzioni principali del servizio; non si fa reverse engineering del codice realizzato) |
| TD-12 | File/cartelle spuri versionati (`a caso.txt` ×2, `_ctx.txt`, `_i18n_scan.txt`, working copy SVN `sungroup-itps-25-26/.svn` dentro repo git, 16 APK in `versions_apk/`) | 🟢 Basso | Processo | repo (root, `client/`, `server/`) | — | Chiuso (commit `435eaee`: untracking + `.gitignore` root; 18/06: rimosso fisicamente il residuo `server/a caso.txt` nella working copy, `server/readme.txt` normalizzato a scaffold) |

### Revisione 27/06/2026 — cleanup minore (doc + censimento backlog)

Intervento di sola **manutenzione documentale** (§3: nessun rename/refactoring non
richiesto, nessuna dipendenza nuova, tre tier invariati). Nessuna voce di debito
toccata.

- **Fix CI di oggi (commit `a606dbd`) — nessun impatto sul debt ratio.** Il commit
  ripristina i 6 gate verdi agendo **solo su lint/tipi/test** (ruff, mypy, pytest,
  flutter analyze/test): non aggiunge né rimuove codice di produzione, quindi né
  numeratore (remediation) né denominatore (LOC di produzione) cambiano.
- **Debt ratio confermato ~7,8% / rating B** (estremo migliore della banda B 6–10%).
  Numeratore invariato a **27h** (TD‑05 8 + TD‑06 10 + TD‑07 3 + TD‑08 2 + TD‑10 4);
  denominatore invariato (~17.300 LOC di produzione client). Le righe di test non
  concorrono al denominatore.
- **Allineamento Doxygen (`Report/doxygen_app_mobile.md`):** rimossi i riferimenti al
  campo `biometricUnlock` e alla sezione "Sicurezza" della SettingsScreen, **eliminati
  in PR #3**. La documentazione ora riflette i 5 campi reali di `settings_store.dart`
  (push/promemoria/promo/posizione/condivisione) e le 4 sezioni reali della schermata
  Impostazioni (Lingua, Notifiche, Privacy e posizione, Informazioni).

**UT.13 — noleggi multipli simultanei: PARZIALE (per scelta di progetto).**
Analisi degli store osservabili del client (`client/app_mobile_utente/lib/`, nessuna
modifica al codice):

| Struttura | File | Cardinalità | UT.13 |
|---|---|---|---|
| `bookingStore` (`ValueNotifier<List<Booking>>`) | `booking_store.dart` | **N prenotazioni** in lista | **Supportato** — più prenotazioni (riserve) attive in contemporanea |
| `activeTripStore` (`ValueNotifier<ActiveTrip?>`) | `active_trip_store.dart` | **al più una** corsa in svolgimento | **Non supportato** — singola corsa attiva per volta (documentato "al più una"), coerente con il vincolo «un mezzo sbloccato per utente» |

Esito: il client consente **più prenotazioni simultanee** ma **una sola corsa attiva**
alla volta. È una scelta di progetto esplicita (lo store della corsa attiva è un
opzionale singolo, non una lista), non un difetto: nessun debito da registrare. Se in
futuro UT.13 richiedesse corse attive concorrenti, l'evoluzione sarebbe additiva
(`ActiveTrip?` → lista) e ricadrebbe nel rilascio del wiring backend del ciclo corsa.

**Tariffe hardcoded (UT.03/UT.06) — integration backlog (§17), NON debito.**
Mock UI non ancora cablato in tutti i percorsi al listino del backend:

| Mock | File | Valori | Stato cablaggio |
|---|---|---|---|
| `_tariffaAlMinuto` / `_ratePerMinute` | `booking_store.dart:121`, `booking_screen.dart:71` | 0,25 / 0,15 / 0,45 / 0,30 €/min (scooter/bici/auto/e‑moto) | **Fallback locale** della stima costo (UT.03): `booking_screen` interroga il backend (`stima` → `costo_stimato_cent`) e ricade sul calcolo per‑tariffa solo se l'endpoint non risponde (IIN‑6) |
| `kPianiAbbonamento` (`prezzo`) | `buy_subscription_screen.dart:48` | 9,99 / 19,99 / 149,00 € | Catalogo di visualizzazione, id allineati al seed backend (UT.18) |

Classificazione: **integration backlog §17** (rientra in TD‑02/TD‑03), si estingue per
costruzione quando il listino tariffe/abbonamenti sarà servito dal backend in tutti i
percorsi UI. Non concorre al ratio.

**Mock offline residui — integration backlog (§17), NON debito.**

| Mock | File | Ruolo |
|---|---|---|
| `kAvailableVehicles` (`const List<VehicleData>`) | `vehicle_detail_screen.dart:16` | Dati di riserva dei mezzi disponibili. In `home_tab` è il **fallback offline** (carica da API, `catch` → riserva mock, IIN‑6); in `booking_tab` è ancora la **sorgente primaria** (tab non ancora cablata a `/veicoli`) |

Classificazione: **integration backlog §17** (TD‑02/TD‑03). Il fallback offline IIN‑6
resta legittimo anche post‑cablaggio (degrado controllato); la sola voce di
*integration pending* è il binding della `booking_tab` a `GET /veicoli`. Non concorre
al ratio.

### Calcolo del ratio (revisione 26/06/2026)

Debito effettivo invariato = TD‑05 (8) + TD‑06 (10) + TD‑07 (3) + TD‑08 (2) +
TD‑10 (4) ≈ **27h**: **nessuna voce di debito è stata toccata** da Task 2 (web) e
Task 3 (mobile), che hanno **cablato a backend reale** codice di produzione (non
rimosso debito ma aggiunto layer dati/store/schermate reali). Il **denominatore
cresce** (~16.400→~17.300 LOC di produzione client, ~328h→~346h a 50 LOC/h con i
repository/store aggiunti) mentre il numeratore resta 27h → ratio ≈ **~7,8%**,
**rating B confermato** (estremo migliore della banda). L'**integration backlog
TD‑02/TD‑03** (non concorre al ratio §17) si riduce ulteriormente: su mobile resta
solo **UT.14 stazioni** non cablata (endpoint già esistente → *integration
pending*, ~1h). Gate verdi a verifica: client `flutter analyze` 0 issue e
`flutter test` **68/68 app + 88/88 web**; server `ruff`/`ruff format`/`mypy
--strict` 0 su **64 file**, **pytest 175 pass + 35 subtest**, copertura runtime
**91,4%**. Le righe di test non concorrono al denominatore.

### Calcolo del ratio (revisione 22/06/2026)

Debito effettivo = TD‑05 (8) + TD‑06 (10) + TD‑07 (3) +
TD‑08 (2) + TD‑10 (4) ≈ **27h** su ~16.400 LOC di produzione
(costo di sviluppo stimato ~328h a 50 LOC/h, stessa convenzione delle revisioni
precedenti) → ratio ≈ **~8%**, **rating B**. Tre interventi (prompt 000034):
**TD‑11 chiuso** per decisione del team (i diagrammi UML riportano le funzioni
principali del servizio; non si fa reverse engineering del codice realizzato),
−6h; **TD‑07 ridotto** (Doxygen completato sulle tre schermate piu' dense e sui
loro part), 6h→3h; **TD‑08 ridotto** (dato separato dalla UI via `part`/`part of`:
`search_screen` 589→498, `map_tab` 708→431, `ticket_management` 774→505), 8h→2h.
Nessun rename né modifica architetturale/estetica (§3); `flutter analyze` 0 issue e
76/76 test pass su entrambi i client. ~42h→**~27h**. TD‑02/TD‑03 restano integration
backlog §17 (non concorrono). Le righe di test non concorrono al denominatore.

### Calcolo del ratio (revisione 18/06/2026)

Debito effettivo = TD‑05 (8) + TD‑06 (10) + TD‑07 (6) +
TD‑08 (8) + TD‑10 (4) + TD‑11 (6) ≈ **42h** su ~16.400 LOC di produzione
(costo di sviluppo stimato ~328h a 50 LOC/h, stessa convenzione delle revisioni
precedenti) → ratio ≈ **~13%**, **rating C** (sotto la soglia d'allarme AG‑CI‑08).
La revisione 18/06 si svolge in due passi: bonifica (prompt 000027) → TD‑01 chiuso
(rischio accettato: repository privato, nessuna esposizione pubblica), ~51h→~50h;
copertura test (prompt 000028) → TD‑04 chiuso (target ≥80% raggiunto: app 89,8% /
web 82,7%), ~50h→~42h. TD‑02 e TD‑03 esclusi dal debito (integration backlog §17).
TD‑09 e TD‑12 chiusi. Le righe di test (ora ~76 suite) non concorrono al denominatore.

> Revisioni precedenti: 18/06/2026 ~42h → ~13% (rating C); 10/06/2026 ~51h → ~16% (rating C); 08/06/2026 ~62h → ~20% (rating C borderline D).

## Milestone di remediation pianificata — rientro verso rating A

Le voci residue (TD‑05, TD‑06, TD‑10) e l'integration backlog (TD‑02, TD‑03)
sono **pianificate per il rilascio del collegamento client‑server reale**
(data layer `dio`/repository + `DataAccessManager`/DB, visualizzazione di dati
reali al posto dei mock). Decisione del team del 22/06/2026: non anticiparle ora
come refactoring isolato a costo‑rischio sfavorevole, ma assorbirle nel rilascio
in cui il codice di quei moduli cambia comunque.

| Voce | Refactoring richiesto | Impatto | Quando |
|---|---|---|---|
| **TD‑02 / TD‑03** | Sostituzione mock con `dio` + repository | Decadono per costruzione | Si estinguono al wiring del backend |
| **TD‑05** (i18n duplicato, 8h) | Source‑of‑truth i18n condivisa tra i due package (dipendenza/package condiviso) — **modifica architetturale** (richiede approvazione §3) | Medio‑alto (cross‑cutting) | Naturale col layer dati condiviso del rilascio |
| **TD‑06** (store statici, 10h) | Iniezione/ciclo di vita degli store osservabili | Molto alto (quasi tutti gli screen) | Quando il wiring reale impone di rivedere il data flow |
| **TD‑10** (KYC AES‑256 at‑rest, 4h) | Cifratura at‑rest (IIN‑4) | Differito (non è refactoring: nuova implementazione) | All'arrivo del `DataAccessManager`/DB |

Razionale: il refactoring sarà **giustificato dal cambiamento funzionale** (dato
reale) e non da pulizia estetica, e il **denominatore SQALE crescerà** (entra il
codice di produzione server + il layer dati), spingendo il ratio ulteriormente
verso **rating A**. Fino ad allora le voci restano aperte e tracciate, non
rimediabili a costo‑rischio favorevole.

## Indicatori di igiene (positivi)

- 0 `print()`, 0 `// ignore`, solo 2 `TODO` (login reset UT.24, storico acquisti).
- `build/` non versionato.
- Tracciabilità ai requisiti nei commenti (`UT.xx`/`IIN-x`/`OP.xx`/`AP.xx`).
- Vincoli architetturali rispettati lato client: no MVC, `sistemaTPL` integrato nella mappa, i18n IT/EN, OTP MFA simulato per OP/PA.
- API key Android già messa in sicurezza (secrets template versionato).
- TD report SQALE versionato e governato sin dallo Sprint 1.

## Coerenza diagrammi ↔ documentazione ↔ codice (sintesi review 08/06/2026)

- **Component diagram ↔ `wiki/DIRECTIVES.md` §4:** coerenza piena (tre tier, nomi componenti, `sistemaTPL` in `GatewayRouting`, black-box via Integration Tier).
- **Codice ↔ requisiti:** ottima tracciabilità UT/IIN/OP/AP nei commenti.
- **Class diagram ↔ codice:** **TD‑11 chiuso** (decisione team 22/06): i diagrammi UML rappresentano le funzioni principali del servizio e si è scelto di non fare reverse engineering del codice client realizzato. Non si misura più come debito.
- **Incongruenze interne `wiki/DIRECTIVES.md`** (non incidono sul ratio): *risolte* — §5 `Leaf_Mobility_Classi.png` → `.jpg` (commit `a5ee61d`); §6 `maps_flutter` → `google_maps_flutter` e §6 state management allineato a `ValueNotifier` con nota su `dio`/backend (18/06, prompt 000028). *Residue*: §10 manca pianificazione Sprint 2; §12.2 `ruff format check` → `ruff format --check`; controlli backend AG‑CI‑01..04/AG‑SEC‑01..04 da marcare DEFERRED finché `server/` non esiste; formati data misti (US vs ISO).

## Storico revisioni

| Data | Autore | Note |
|---|---|---|
| 07/06/2026 | Review tecnica | Baseline iniziale (Fase 0). |
| 08/06/2026 | Review tecnica esterna | Applicata §17 (TD‑02/03 → integration backlog): ratio 24%→~20%, D→C. Aggiornato TD‑01 (Android risolto, web ancora esposta), TD‑09 chiuso. Aggiunti TD‑11 (coerenza class diagram) e TD‑12 (file spuri). Inserita sintesi coerenza diagrammi/direttive. |
| 10/06/2026 | Stefano (Sprint 3, prompt 000026) | Commit Fase 0 (`435eaee`): TD‑12 chiuso, TD‑01 mitigato (resta rotazione chiave, 1h). Remediation TD‑04: 12 file di test, 61 test totali (33 app + 28 web, `flutter analyze` 0 issue e `flutter test` 100% pass su entrambi i client — AG‑CI‑05/06); stima residua 24h→8h. Ratio ~20%→**~16%**, rating **C**. |
| 18/06/2026 | Stefano (Sprint 3, prompt 000027) | Bonifica di coerenza: TD‑01 chiuso (rischio accettato — repository privato, nessuna esposizione pubblica; rotazione non necessaria), TD‑12 chiuso in via definitiva (rimosso fisicamente `server/a caso.txt`, `server/readme.txt` normalizzato a scaffold). Allineati i riferimenti di percorso al canone `wiki/DIRECTIVES.md`; versione app mobile → `1.0.0-alpha.15+15`. Ratio ~16%→**~15%**, rating **C**. Stato CI invariato: `flutter analyze` 0 issue e 61/61 test pass su entrambi i client. |
| 18/06/2026 | Stefano (Sprint 3, prompt 000028) | Riconciliazione canone §6/§8 (TD‑06 ridimensionato). Copertura test TD‑04: 15 nuovi test (61→**76**: 39 app + 37 web) su dettaglio corsa/percorso (app) e reportistica/eventi/geofencing/utenti/coda assistenza/impostazioni/profilo (web). Coverage **app 69,1%→89,8%**, **web 49,5%→82,7%** (target ≥80% raggiunto) → TD‑04 chiuso. Ratio ~15%→**~13%**, rating **C**. `flutter analyze` 0 issue e 76/76 test pass su entrambi i client. |
| 21/06/2026 | Stefano (Sprint 3, accesso esterno + UI) | **API pubblica client-facing predisposta** (`presentation_tier/api_pubblica.py`, router `/api/v1` con CORS, contratti pydantic, gateway di sicurezza e audit; default loopback, `LEAF_HOST=0.0.0.0`/`LEAF_CORS_ORIGINS` per la rete) → "metà" dell'accesso ai servizi soddisfatta senza cablare il dominio (inviluppo "in sviluppo"). Console: barra telemetria snellita + pannello "Stato runtime" sotto i riquadri, riquadri in alto, mascotte allungata (18 righe), cronologia integrata nelle barre di caricamento. Test **29→36** (`test_api_pubblica.py`), `mypy --strict` 0 su 44 file. Nessun nuovo debito: l'API riduce anzi il disallineamento progettazione↔codice (TD-11) introducendo il componente del Presentation Tier previsto in §4.1. Ratio client invariato **~13%**, rating **C**. |
| 21/06/2026 | Stefano (Sprint 3, hardening server) | **Gate backend attivati e portati a verde** ora che il `server/` esiste: `mypy --strict` da **36 errori → 0** (conversioni `float(object)` tipizzate, ritorni `cast`, `_invia` httpx tipizzato, registro provisioning tipizzato, stub `types-psutil`/`types-passlib`); `ruff check`/`format` puliti; **pytest 18→29** (nuovi test `/config`, dispositivi collegati, `CronologiaConsole`, helper console), copertura tier `runtime` **≥80%** su tutti i moduli. Aggiunto il job CI `server-runtime` (AG‑CI‑01..04). Nuove feature console (logo allungato, barre di caricamento, cronologia persistente, impostazioni a caldo `set`, `exit` che arresta il runtime, monitoraggio dispositivi collegati). Nessun nuovo debito introdotto: ratio client invariato **~13%**, rating **C**. |
| 22/06/2026 | Stefano (Sprint 3, prompt 000034) | **Rientro a rating B (~13%→~8%).** TD‑11 chiuso per decisione del team (i diagrammi UML riportano le funzioni principali del servizio; niente reverse engineering), −6h. TD‑07 ridotto (Doxygen `@param`/`@return`/`@brief` completato su `search_screen`/`map_tab`/`ticket_management` e relativi part), 6h→3h. TD‑08 ridotto: dato separato dalla UI via `part`/`part of` senza rename (§3) — `search_screen` 589→498, `map_tab` 708→431, `ticket_management` 774→505 (+ `*_data.dart`/`ticket_management_form.dart`), 8h→2h. ~42h→**~27h**, **rating B**. `flutter analyze` 0 issue e 76/76 test pass su entrambi i client; gate server invariati (39 test, 91,4%). Inserita la **milestone di remediation pianificata** (TD‑05/06/10 + backlog → rilascio collegamento client‑server reale, rientro atteso verso A). |
| 24/06/2026 | Stefano (Sprint 3, FASE 3 gate sicurezza) | **Gate sicurezza AG-SEC-01..04 portati a verde (nessun nuovo debito).** Creata la suite `server/tests/security/` (21 test) che verifica i quattro controlli Critical della §12.2, prima DEFERRED: validazione formato KYC (AG-SEC-01/IIN-6), cifratura **AES-256-GCM reale** dei campi 🔒 e dei documenti KYC a riposo (AG-SEC-02/IIN-4), enforcement MFA OP/PA senza OTP→nessun token (AG-SEC-03/IIN-9), anonimizzazione delle analitiche PA (AG-SEC-04/IIN-15). Tutti offline sul client fake (testabilità §12.2). Gate: `ruff`/`ruff format`/`mypy --strict` 0 su **61 file**, **pytest 91 → 112**, copertura runtime **92,22%**. **Verifica E2E live eseguita**: installati Node.js 24.18 + `firebase-tools` 15.22.1, avviato l'emulatore Firestore e riprodotti i 4 controlli su Firestore vero (`tests/verifica_emulatore_live.py`, **9/9** con cifratura AES-256 reale via `LEAF_AES_KEY`). Resta DEFERRED solo l'E2E completo client→server (dipende da FASE 2). Ratio SQALE invariato (~8%, rating B: il codice di test non concorre al denominatore). |
| 25/06/2026 | Stefano (Sprint 3, Blocco 1 — binding UI web) | **Binding UI delle 4 schermate web completato (permesso developer).** Cablate a dati reali `user_admin`/`discount_management`/`event_reporting` (store osservabili `*_store.dart`+`*_data.dart`, fallback riserva IIN-6) e `ticket_management` (iniezione repository, read `/manutenzione` + create + chiusura best-effort). Seam `autoload`/`kAutoloadData` per la testabilità; azioni ottimistiche con sync best-effort. `flutter analyze` 0, **web 59→72 test** (+13: store/mapper/read-path). **TD-02/TD-03 chiusi per costruzione sulle 4 schermate web** (endpoint Blocco 1 esistenti e UI cablata); residuo backlog ridotto al solo mobile (Blocco 2: SOS/ricarica/abbonamenti/pagamenti). Ratio SQALE **~8% invariato, rating B** (le LOC aggiunte sono store/repository sottili e codice di test fuori dal denominatore). |
| 25/06/2026 | Stefano (Sprint 3, Blocco 1 — Cascata D, Parte 1) | **Endpoint gestionali OP/PA reali (nessun nuovo debito).** Cablati 4 domini finora «in attesa di endpoint»: gestione utenti/AP (sospensione/sblocco OP.10/18, provisioning PA OP.17), ticket manutenzione (OP.16/19), promozioni/incentivi geografici (OP.09/15), eventi città (AP.09) — tutto additivo sui gestori e sullo schema esistenti (riuso `promozioni.tipo` e `aree_limitate.tipo="evento"`, nessuna nuova collezione né modulo). Aggiunti i 4 repository web di integrazione (dio). Gate: ruff/format/mypy 0 su **64 file**, **pytest 133→141** (+8 E2E `test_e2e_blocco1.py`), runtime 92%; `flutter analyze` 0 su web. **TD-02/TD-03**: la dipendenza server è rimossa per `user_admin`/`ticket_management`/`discount_management`/`event_reporting` — il residuo passa da «backlog senza endpoint» a «integration pending» e si estingue al binding UI delle schermate (corsia estetica DOE §2). Ratio SQALE **~8% invariato, rating B** (codice server fuori dal denominatore client; test fuori dal denominatore). |
| 24/06/2026 | Stefano (Sprint 3, prompt 000051 — Cascata C, Parte 1) | **Validazione E2E client→server su HTTP + 2 fix di affidabilità (nessun nuovo debito).** Nuova suite `test_e2e_flussi.py` (7 test, full-stack ASGI via TestClient) per geofencing CRUD, assistenza, ricerca percorsi e sicurezza al confine (MFA enforcement IIN-9, RBAC IIN-5, anonimizzazione IIN-15); script on-demand `verifica_e2e_live.py` (viaggio E2E completo su socket reale → **emulatore Firestore + seed, 16/16 PASS**); helper `tool/avvia_stack_e2e.ps1`. La persistenza vera ha fatto emergere **2 bug latenti** (nascosti dal client fake), ora corretti: array annidati Firestore in `crea_area` (poligono→geometria) e incoerenza flag attiva (`attiva:True`→`stato:"attiva"` in crea/elenca, coerente col seed e con `aree_contenenti`); più la credenziale anonima dell'emulatore. Gate: ruff/format/mypy 0 su **63 file**, **pytest 125→133**. Ratio SQALE **~8% invariato, rating B** (codice di test fuori dal denominatore; i fix riducono il rischio di affidabilità senza introdurre debito). Resta la **Parte 2** (client Flutter veri su HTTP, a carico del developer). |
| 24/06/2026 | Stefano (Sprint 3, prompt 000050 — Cascata B) | **Ricerca percorsi reale (UT.07), nessun nuovo debito.** Server (tre tier invariati): `GatewayRouting` con gazetteer locale di POI di Bari + `geocodifica`/`suggerisci` (sorgente deterministica del geocoding senza provider esterno, decisione developer §3); `GestoreCorse.pianifica_percorsi` + orchestrazione `GestoreAttivita`; nuovi endpoint `GET /api/v1/geocoding` e `/percorsi`. App mobile: nuovo `routing_repository.dart`; `search_screen` cablata (suggerimenti + opzioni di percorso reali, fallback offline IIN-6, mezzi consigliati reali da `/veicoli`), rimossi i mock `_buildRoutes`/`_allSuggestions`. Gate: server ruff/format/mypy 0 (61 file), **pytest 120→125**; mobile `flutter analyze` 0, **flutter test 56→58**. **TD-02/TD-03 chiusi per costruzione su `search_screen`** (l'endpoint ora esiste); residuo backlog ridotto (~16h→~6h, solo dove l'endpoint server manca). Ratio SQALE **~8% invariato, rating B** (le righe di test non concorrono al denominatore; il codice di produzione aggiunto è server, fuori dal denominatore client). |
| 24/06/2026 | Stefano (Sprint 3, prompt 000049 — task minori client) | **Chiusa l'incoerenza «repository orfano» + 4 task additive client (nessun nuovo debito).** App mobile: `support_screen.dart` (UT.09) cablata al repository finora **definito ma mai importato** `assistenza_repository.dart` → `POST /api/v1/assistenza` con stati loading/errore (riuso `stato_vista.dart`), repository iniettabile — risolta una incoerenza di manutenibilità (codice morto di fatto) senza nuovo debito. Web: impostazioni persistite via `shared_preferences` (dipendenza `^2.3.2` approvata §3); badge «dato stimato» sulle card mock della reportistica (trasparenza AG-CI-09); logout reale via `AuthApi.esci()` (POST `/auth/logout` + cancellazione token). Additivo, nessun MVC (§4.2), nessun rename (§3). Gate: `flutter analyze` 0 issue; `flutter test` **mobile 54→56/56**, **web 50→53/53** (+4 test: assistenza mobile ×2, persistenza impostazioni, badge reportistica, logout — il codice di test non concorre al denominatore). Ratio SQALE **~8% invariato, rating B** (production LOC aggiunte trascurabili; nessuna delle voci TD-05/06/10 toccata). Cascate B/C non eseguite (dipendono da endpoint server, integration backlog §17). |
| 26/06/2026 | Manuel (Sprint 3, prompt 000059 — Task 3 mobile + Task 4 infra) | **Profilo mobile completo + E2E reset password, nessun nuovo debito (~8%→~7,8%, rating B confermato).** Task 3: cablati a backend `buy_subscription` (UT.18, catalogo allineato al seed), pagamenti `sensitive_data` (UT.11, PAN mai persistito client-side), KYC (UT.22.2, `{tipo, nome_file}`), pausa/riprendi corsa (UT.12, nuovo `active_trip_store` osservabile + card in `my_bookings`). Task 4: esteso `test_e2e_flussi.py` con il flusso completo **reset password IIN-11** (richiesta→codice→conferma→login con nuova password + codice errato anti-enumerazione). Gate: mobile `flutter analyze` 0, **flutter test 63→68**; server ruff/format/mypy 0 su 64 file, **pytest 173→175** + 35 subtest, runtime **91,4%**. **TD-02** integration backlog ridotto: su mobile resta solo UT.14 stazioni (endpoint esistente → integration pending). Numeratore SQALE invariato (27h, nessuna voce di debito toccata); denominatore cresciuto col codice cablato → ratio **~7,8%**, **rating B**. APK `Leaf_Mobility1.0.0-alpha.18` non generato in ambiente CI (Android SDK assente; firma release a carico di Stefano, S4). |
| 27/06/2026 | Stefano (Sprint 3, cleanup minore) | **Manutenzione documentale, nessun nuovo debito (~7,8% invariato, rating B).** Allineato `doxygen_app_mobile.md` alla rimozione di `biometricUnlock`/sezione "Sicurezza" (PR #3). Verificato **UT.13**: prenotazioni multiple supportate (`bookingStore` lista), corsa attiva singola per scelta di progetto (`activeTripStore` opzionale singolo) → PARZIALE, nessun debito. Censiti come **integration backlog §17** (TD‑02/03) le tariffe hardcoded UT.03/UT.06 (`_tariffaAlMinuto`/`_ratePerMinute` fallback locale; `kPianiAbbonamento` catalogo) e i mock offline (`kAvailableVehicles`, fallback IIN‑6 in `home_tab`, primario in `booking_tab` non ancora cablata). Il **fix CI di oggi `a606dbd`** (solo lint/tipi/test) non incide sul ratio. Nessuna modifica al codice client (§3). |
| 28/06/2026 | Stefano (Sprint 3, chiusura) | **Sprint 3 concluso — progetto consegnato 29/06/2026 (rating B ~7,8% confermato).** Sessioni finali (prompt 000064–000071): fix connettività Cloudflare + permesso INTERNET sull'APK release, logging strutturato server, console OP completa (assegna tecnico OP.16/19, coda SOS live UT.20/OP.08, annullo prenotazioni OP.12, perimetro operativo soft OP.04 + GPS fine corsa OP.05, dipendenza totale dal server), 8 problematiche app+server (refresh stato/corsa attiva, fine noleggio, validazione pagamento, registrazione completa, gate patente, abbonamento a token), data di nascita obbligatoria (UT.22.1), bug IIN-14 login post-logout. Tutte modifiche **additive** (tre tier invariati, nessun MVC/rename); nessuna voce di debito toccata → numeratore 27h invariato, denominatore client invariato (~17.300 LOC) → ratio **~7,8%, rating B**. Versioni finali: server (runtime), mobile `1.0.0-alpha.31`, web `1.0.0-alpha.22`. Gate finali: server ruff/format/mypy 0, **pytest 211** + 35 subtest, runtime ~91–92%; mobile `flutter analyze` 0 / **flutter test 75**; web `flutter analyze` 0 / **flutter test 90**. Verifica live su device/Cloudflare (§12.5) a carico del developer. |
| 24/06/2026 | Stefano (Sprint 3, FASE 0/1 backend) | **Backend core reso reale (nessun nuovo debito).** Allineato il modello dati Firestore allo schema logico (`schema_logico_db.md`: snake_case, Account a chiave condivisa, registri unicità, cifratura `mezzi.posizione`) e agganciato il Business Tier al DAO (geofencing, ciclo corsa con pagamento/fattura, MFA reale + lockout IIN-10, ticket, analitica anonima IIN-15); gateway esterni come simulazioni locali deterministiche; `/api/v1` cablato end-to-end (login+MFA, prenota/avvia/termina) con sessione Bearer. Chiusi i `NotImplementedError` di dominio elencati. Gate server: `ruff`/`mypy --strict` 0 su 54 file, **pytest 69→91**, copertura runtime **92,2%**. **TD-02/03** (client senza `dio`/layer dati) e **TD-05/06/10** restano **client-side**, non toccati da questo lavoro server → invariati, rientro atteso con FASE 2. Ratio SQALE **~8% invariato, rating B** (il lavoro server non incide sul denominatore, basato sul client). |
| 04/08/2026 | Stefano (Release Open Source) | **Sprint 3 definitivamente chiuso e archiviato.** Il repository è stato sanificato e preparato per il rilascio Open Source (rimozione email, log e chiavi sensibili). La documentazione e l'albero delle direttive sono allineati. Ratio SQALE confermato **~3,8% (Rating A)**. |
