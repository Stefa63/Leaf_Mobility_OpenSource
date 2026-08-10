# LEAF Mobility — Server

Runtime operativo a **tre tier** (FastAPI/async) + **console operativa** da terminale.
Progettazione completa in [`Report/architettura_server.md`](../Report/architettura_server.md).
Direttive di canone: [`wiki/DIRECTIVES.md`](../wiki/DIRECTIVES.md) (§4–§7).

> **⚠️ Database = Cloud Firestore (NoSQL document store), accesso server-mediato via `firebase-admin`
> nel `DataAccessManager` (Integration Tier).** I client passano **solo** da `/api/v1`. **NON** si usa
> SQL/SQLAlchemy/PostgreSQL (il target relazionale originario è stato superato il 22/06/2026 — vedi
> `wiki/DIRECTIVES.md` §6): l'accesso dati è esclusivamente CRUD/query a documenti. Cifratura AES-256
> applicativa sui campi sensibili (IIN-4).

> **Stato (Sprint 3):** tre tier con persistenza **Cloud Firestore reale** (DataAccessManager +
> cifratura AES-256), **API pubblica `/api/v1`** cablata Presentation→Business→Integration (auth/MFA,
> ciclo corsa, geofencing, flotta/soglie/telemetria, analitica anonima, profilo/KYC/pagamenti,
> notifiche, SOS). Test offline su client fake + verifica live su emulatore Firestore.

## Installazione (un solo comando)

```bash
python -m pip install -r server/requirements.txt
```

Richiede **Python 3.11+** (testato su 3.14). Nessun database necessario in questa fase.

## Avvio del server

Eseguire **dalla radice del repository** (`C:\Leaf_Mobility`), in due passi:

```bash
python -m server.console_operativa     # 1) apre la console operativa (stile Claude Code)
```
poi, al prompt `🍃 leaf >`:
```
start                                  # 2) avvia il runtime (uvicorn su 127.0.0.1:8770)
```

`start` lancia il runtime come **processo indipendente**: continua a girare anche dopo
`exit` dalla console, e altre console possono agganciarsi. Per fermarlo: `stop`.

### Avvio manuale diretto (senza console)

In alternativa alla console, il runtime si avvia **in foreground** in un terminale dedicato
(log strutturati a video, `ctrl-C` per arrestarlo):

```bash
python -m server.runtime                # avvio diretto (host/porta da env: LEAF_HOST/LEAF_PORT)
```

Equivalente, esplicitando il target uvicorn:

```bash
python -m uvicorn server.runtime.app_factory:app --host 127.0.0.1 --port 8770
```

Health check: `GET http://127.0.0.1:8770/__admin__/salute` → `{"stato":"ok",…}`.
La console è un *client* del runtime ed è una **TUI a schermo intero** (prompt_toolkit)
fedele al design handoff: in alto una **barra telemetria snella sempre visibile** coi soli
gauge hardware live (RUNTIME · CPU · RAM · IO · NET); il brand con mascotte a foglia
**allungata** e **stato sotto la mascotte**; i riquadri dei comandi **in alto** a destra e,
**sotto di essi**, un pannello **"Stato runtime"** coi parametri del runtime in tempo reale
(**dispositivi collegati**, thread, uptime, richieste/errori, req/s, concorrenza, tempi di
risposta, traffico). A sinistra la **chat scrollabile** (storico e caricamenti restano
visibili) col prompt `🍃 leaf >` in basso. L'**uptime** è quello del runtime e si **azzera a
ogni restart**. Scorri lo storico con `PagSu`/`PagGiù`, `Maiusc+Frecce` o `Inizio`/`Fine`.

Il brand (wordmark, benvenuto e server card) è **affiancato alla mascotte** così la chat
resta ampia e le operazioni ben visibili. All'avvio la console **ripristina da disco le
ultime operazioni** eseguite (sopravvivono alla chiusura, anche imprevista) mostrandole nello
stesso flusso dei caricamenti. I comandi `start`/`backup`/`exit` mostrano i **passi intermedi
uno per riga** (`▸ <passo>`) con la **percentuale di completamento**, seguiti dal messaggio
finale dell'operazione.

### Comandi principali

| Comando | Azione |
|---|---|
| `start` / `stop` / `restart` / `status` | Ciclo di vita del runtime |
| `monitor` | Snapshot del carico: byte in/out, accessi concorrenti, dati letti/scritti, tempo di risposta medio e p95, req/s (le metriche live sono nella barra in alto) |
| `hw` | Snapshot dello sforzo hardware: CPU, RAM, I/O disco/rete (barre colorate per soglia) |
| `op create <username>` / `op list` | Crea OP con password temporanea / elenca OP |
| `query <sql>` | Interrogazione admin (DB in sviluppo: tracciata, non eseguita) |
| `backup` / `backup list` / `backup auto on\|off` / `backup restore <nome>` | Backup manuale/automatico e ripristino |
| `audit [n]` | Log di audit append-only (IIN-13) |
| `cronologia [n]` | Ultime operazioni della console, ripristinate da disco (sopravvivono al riavvio) |
| `set` / `set <chiave> <valore>` | Mostra o modifica **a caldo** le impostazioni (intervallo/retention backup, soglie CPU/RAM, backup auto); persistite in `config.json` |
| `selftest [n]` | Carico sintetico concorrente per esercitare i monitor |
| `help [comando]` | Aiuto generale o sul singolo comando |
| `clear` | Svuota la chat (la barra telemetria in alto resta) |
| `exit` | **Arresta il runtime** (se attivo) e chiude la console; `exit --keep` esce lasciandolo attivo |

> **Chiavi di `set`:** `backup-auto on\|off`, `backup-interval <sec>`, `backup-retention <n>`,
> `soglia-cpu <pct>`, `soglia-ram <pct>`. Esempio: `set backup-interval 300`.

> **Alias accettati:** `hardware`→`hw`, `load`→`selftest`, `cls`→`clear`, `quit`/`q`→`exit`,
> `history`→`cronologia`, `config`/`impostazioni`→`set`.
> Premi `Tab` al prompt per il completamento automatico dei comandi.

> **Più interfacce in concorrenza:** apri più terminali con `python -m server.console_operativa`;
> ognuno è un client del runtime e può lanciare comandi diversi in parallelo.

### Sessione tipica

```text
🍃 leaf > start                      # avvia il runtime (barra di caricamento)
🍃 leaf > status                     # uptime, dispositivi collegati, richieste
🍃 leaf > set backup-interval 300    # backup automatico ogni 5 minuti (persistito)
🍃 leaf > set backup-auto on         # attiva il backup automatico
🍃 leaf > op create mrossi           # crea un OP: mostra la password temporanea (una volta)
🍃 leaf > backup                     # backup manuale immediato
🍃 leaf > monitor                    # snapshot del carico; hw per lo sforzo hardware
🍃 leaf > cronologia                 # rivede le ultime operazioni (anche dopo un riavvio)
🍃 leaf > exit                       # arresta il runtime e chiude (exit --keep per lasciarlo attivo)
```

## Configurazione

Copia `server/.env.example` in `server/.env` (opzionale: i default sono sicuri e loopback).

| Variabile | Default | Significato |
|---|---|---|
| `LEAF_HOST` / `LEAF_PORT` | `127.0.0.1` / `8770` | Bind del server (`0.0.0.0` per accettare la rete) |
| `LEAF_WORKERS` | `1` | Numero di worker uvicorn |
| `LEAF_BACKUP_AUTO` | `false` | Backup automatico attivo all'avvio |
| `LEAF_BACKUP_INTERVAL_S` | `900` | Intervallo del backup automatico (s) |
| `LEAF_BACKUP_RETENTION` | `10` | Archivi di backup conservati |
| `LEAF_SOGLIA_CPU` / `LEAF_SOGLIA_RAM` | `85` / `85` | Soglie di allerta hardware (%) |
| `LEAF_ADMIN_TOKEN` | — | Token per le interrogazioni admin (`X-Admin-Token`) |
| `LEAF_CORS_ORIGINS` | `*` | Origini CORS consentite per `/api/v1` |
| `LEAF_RATE_LIMIT` / `LEAF_RATE_WINDOW_S` | `120` / `60` | Rate limit `/api/v1` (richieste/finestra per host) |

**Precedenza:** default sicuri → `.env`/ambiente → `dati/config.json`. Le scelte fatte a
caldo col comando `set` sono persistite in `config.json` (gitignored) e **sopravvivono al
riavvio** del runtime; il file di sola lettura è scritto solo dal comando `set`.

## Accesso da dispositivi esterni (app mobile / WebDashboard)

Il runtime espone una **API pubblica versionata `/api/v1`** per i client esterni, accanto
all'endpoint di controllo `/__admin__` (loopback, riservato alla console):

| Metodo | Percorso | Scopo |
|---|---|---|
| GET | `/api/v1/info` | Versione, capacità, stato DB, esposizione in rete |
| GET | `/api/v1/salute` | Health check pubblico (uptime, dispositivi) |
| POST | `/api/v1/auth/login` | Autenticazione client (UT/OP/AP) — IIN-1/IIN-5 |
| POST | `/api/v1/auth/mfa` | Secondo fattore OTP per OP/AP — IIN-9 |
| GET | `/api/v1/veicoli` | Mezzi disponibili nei pressi — UT.01/UT.05 |
| POST | `/api/v1/corse` | Avvio corsa su un mezzo (richiede token) — UT.10 |

Rotte, contratti (pydantic), CORS e gateway di sicurezza sono **pronti**; finché il
Business Tier e il DB sono in sviluppo, gli endpoint applicativi rispondono con un
inviluppo uniforme `{"disponibile": false, "messaggio": "...", "dati": null}`.

**Sicurezza perimetrale** (middleware ASGI): ogni risposta porta un `X-Request-ID` di
correlazione (propagato se fornito dal client) e gli header `X-Content-Type-Options`,
`X-Frame-Options`, `Referrer-Policy`. Gli endpoint pubblici `/api/v1` hanno un **rate
limit per host** (`LEAF_RATE_LIMIT` richieste / `LEAF_RATE_WINDOW_S` secondi; oltre il
limite → `429`); l'endpoint di controllo loopback `/__admin__` ne è esente.

**Abilitare l'accesso dalla rete** (per impostazione predefinita il server è solo loopback):

```bash
# in server/.env
LEAF_HOST=0.0.0.0                          # accetta connessioni da mobile/web in LAN
LEAF_CORS_ORIGINS=https://dashboard.local  # origini web consentite (default: *)
LEAF_ADMIN_TOKEN=...                        # raccomandato quando esposto in rete
```

> La server card della console indica se l'accesso è **loopback** o **rete (esterni)**; le
> chiamate dei client esterni alimentano il monitor **dispositivi collegati**.

## Test

```bash
python -m unittest discover -s server/tests   # stdlib, nessun download aggiuntivo
# oppure, se installato:  pytest
```

I gate di qualità del tier runtime (Controls Reference Matrix §12.2) si eseguono dalla
radice del repository — gli stessi della pipeline CI (`.github/workflows/ci.yml`):

```bash
python -m ruff check server                 # AG-CI-01 (lint)
python -m ruff format --check server        # AG-CI-03 (formato)
python -m mypy --strict server              # AG-CI-02 (tipi; richiede types-psutil/types-passlib)
python -m pytest server/tests --cov=server.runtime --cov-fail-under=80   # AG-CI-04 (test + copertura ≥80%)
```

Per eseguire automaticamente lint+tipi **prima di ogni commit** (stessi gate della CI):

```bash
python -m pip install pre-commit
pre-commit install                 # aggancia gli hook a git
pre-commit run --all-files         # esecuzione manuale su tutto il server
```

## Risoluzione problemi

| Sintomo | Causa probabile / rimedio |
|---|---|
| `start` segnala "Avvio non riuscito" | Vedi `server/dati/server.log`; porta `8770` occupata → cambia `LEAF_PORT`. |
| La barra mostra `RUNTIME fermo` dopo `start` | Il runtime non risponde sul loopback: controlla `server.log` e l'eventuale firewall locale. |
| Un client esterno non raggiunge `/api/v1` | Il server è loopback: imposta `LEAF_HOST=0.0.0.0` e riavvia; verifica firewall/LAN. |
| Il client web riceve errori CORS | Aggiungi l'origine a `LEAF_CORS_ORIGINS` (o `*` in sviluppo). |
| Le chiamate `/api/v1` ricevono `429` | Rate limit superato: alza `LEAF_RATE_LIMIT` o `LEAF_RATE_WINDOW_S` (0 = disattiva). |
| `mypy` segnala stub mancanti | Installa i requisiti: `types-psutil`/`types-passlib` sono in `requirements.txt`. |
| Un'impostazione `set` non "tiene" | È persistita in `dati/config.json`; ha precedenza su `.env`. Per tornare ai default elimina il file. |

## Struttura

```
server/
├── presentation_tier/   # tre tier (scheletri di dominio) + api_pubblica.py (router /api/v1)
│   business_tier/  integration_tier/
├── runtime/             # FastAPI, metriche, monitor, provisioning, backup, audit,
│                        #   middleware_sicurezza (request-id/header/rate limit), impostazioni
├── console_operativa/   # TUI di gestione (client del runtime): console, tema, mascotte,
│                        #   cronologia (operazioni persistenti), supervisore, client_controllo
├── tests/               # test runtime/console/API (unittest/pytest)
├── dati/  backups/      # dati di runtime (gitignored): config.json, audit.log, cronologia, pid, backup
└── requirements.txt  pyproject.toml  pytest.ini  .env.example
```

Manuale della sola console: [`console_operativa/README.md`](console_operativa/README.md).
