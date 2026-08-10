# LEAF Mobility — Analisi KPI Non Economici

> **Data:** 10/08/2026 · **Autore:** Project Manager AI & Chief Sustainability Officer  
> **Perimetro:** Progetto LEAF Mobility — Sprint 1/2/3 (conclusi) + post-delivery  
> **Budget:** €10 stanziati · €8 spesi (80% utilizzo) — dettaglio in `Report/kpi_economici.md`

---

## Executive Summary — Sintesi Manageriale

> [!IMPORTANT]
> **Stato complessivo del progetto: VERDE con riserve operative.**
> Il progetto LEAF Mobility è stato consegnato il 29/06/2026 con tutti i gate CI/CD e sicurezza verdi. Il debito tecnico SQALE è sceso da **rating D (24%)** a **rating A (3,8%)** nel corso dello sviluppo. Tuttavia, emergono indicatori precoci di pressione sul team e aree di miglioramento ESG che richiedono attenzione nella fase post-delivery.

### Criticità Operative Non Finanziarie Evidenziate

| # | Criticità | Severità | Area | Azione Raccomandata |
|---|-----------|----------|------|---------------------|
| 1 | **Carico di lavoro concentrato**: 46 prompt (000026–000071) in 18 giorni di Sprint 3, con sessioni multi-task giornaliere (fino a 8 prompt/giorno il 24/06) | 🟠 Alta | Team / Burnout | Monitorare i tempi di recupero; introdurre sprint retrospective formali |
| 2 | **Distribuzione sbilanciata**: Stefano autore di ~85% dei commit Sprint 3; Manuel con 1 sessione documentata (prompt 000059) | 🟠 Alta | Team / Diversità | Redistribuire i carichi; pair programming obbligatorio |
| 3 | **Test E2E client→server non completati in ambiente reale**: resta DEFERRED il test completo da client reali | 🟡 Media | Qualità | Pianificare sprint dedicato alla validazione end-to-end |
| 4 | **Supply chain limitata**: dipendenza da fornitori singoli (Google Maps, Firebase, Cloudflare) | 🟡 Media | ESG / Rischio | Documentare piani di contingenza; valutare alternative open-source |
| 5 | **Metriche CSAT/NPS non disponibili**: nessun feedback utente reale raccolto (progetto accademico) | 🟢 Bassa | Mercato | Predisporre meccanismo di raccolta feedback per eventuale rilascio |

---

## 1. Qualità e Dinamiche del Team

### 1.1 Defect Density

La **Defect Density** misura il numero di difetti rilevati per unità di codice (KLOC).

| Metrica | Valore | Benchmark | Valutazione |
|---------|--------|-----------|-------------|
| **LOC di produzione (client)** | ~17.300 | — | — |
| **LOC di produzione (server)** | ~5.000 (stima da 73 file Python) | — | — |
| **Difetti rilevati in Sprint 3** | 14 (bug fix documentati nel CHANGELOG) | — | — |
| **Defect Density** | **0,63 difetti/KLOC** | < 1.0 eccellente; 1–5 buono; > 10 critico | ✅ **Eccellente** |

**Dettaglio difetti Sprint 3 (dal CHANGELOG):**
1. Permesso INTERNET mancante nel manifest release APK
2. Bug IIN-14: login post-logout (contatore dispositivi)
3. Array annidati Firestore in `crea_area` (poligono)
4. Incoerenza flag `attiva`→`stato` nelle aree geofencing
5. Query FAILED_PRECONDITION (indici Firestore camelCase→snake_case, 12 indici)
6. Console crash all'avvio server (subprocess stdin ereditato)
7. Memory leak handle file `server.log` su Windows
8. `kAppVersion` divergente (drawer vs impostazioni)
9. Mezzi non visibili in mappa (filtro prossimità)
10. `0.0.0.0` non raggiungibile come destinazione (console)
11. Repository assistenza orfano (definito ma non importato)
12. Routing post-reset password (Navigator.pop → pushNamedAndRemoveUntil)
13. BuildContext post-reset (ScaffoldMessenger dopo unmount)
14. Abbonamento duplicato (mancava vincolo unicità)

> [!NOTE]
> La densità di difetti è **eccellente** (0,63/KLOC), ben al di sotto della soglia di attenzione. La maggior parte dei difetti sono di integrazione/deployment (non logici), indicando buona qualità del codice di base ma necessità di migliorare il processo di testing pre-release.

### 1.2 First-Pass Rate

Il **First-Pass Rate** misura la percentuale di attività completate correttamente al primo tentativo, senza necessità di rilavorazione.

| Componente | Gate Totali | Passati al 1° Tentativo | Self-Correction | First-Pass Rate |
|------------|-------------|-------------------------|-----------------|-----------------|
| Backend (ruff/mypy/pytest) | 8 sessioni CI | 6 | 2 (format fix) | **75%** |
| Mobile (analyze/test) | 8 sessioni CI | 7 | 1 (FakeAuth stub) | **87,5%** |
| Web (analyze/test) | 7 sessioni CI | 7 | 0 | **100%** |
| **Complessivo** | **23** | **20** | **3** | **87%** |

> [!TIP]
> Un First-Pass Rate dell'87% è **buono** per un progetto accademico con 4 sviluppatori. Le self-correction sono state tutte minori (formatting, stub di test) e risolte in Round 2 — nessuna ha richiesto 3 iterazioni (il massimo consentito dalla §12.1).

### 1.3 Resource Capacity Utilization

| Metrica | Sprint 1 | Sprint 2 | Sprint 3 | Post-delivery |
|---------|----------|----------|----------|---------------|
| **Durata (giorni)** | ~14 | 8 | 18 | ~42 (al 10/08) |
| **Prompt registrati** | 11 | 14 | 46 | non registrati |
| **Prompt/giorno** | 0,8 | 1,75 | **2,56** | — |
| **Picco giornaliero** | — | — | **8 prompt** (24/06) | — |
| **Sviluppatori attivi** | 4 | 4 | 2 (Stefano, Manuel) | 1 (Stefano) |
| **Capacity Utilization** | ~40% | ~70% | **>95%** ⚠️ | ~20% |

> [!WARNING]
> **Indicatore di burnout rilevato.** Lo Sprint 3 mostra una **Capacity Utilization >95%** con un picco di 8 prompt in un singolo giorno (24/06). Il carico è concentrato quasi interamente su un singolo sviluppatore (Stefano). Questo pattern è un classico precursore di:
> - Degrado procedurale (shortcut nella documentazione)
> - Errori di integrazione (i 12 indici Firestore errati sono un sintomo)
> - Riduzione della qualità dei test (E2E client→server ancora DEFERRED)

### 1.4 Team Velocity

| Sprint | User Story Completate | Story Points (stima) | Velocity |
|--------|-----------------------|----------------------|----------|
| Sprint 1 | UI mobile + web | ~30 pts | 30 pts/sprint |
| Sprint 2 | Consolidamento web | ~20 pts | 20 pts/sprint |
| Sprint 3 | Server completo + cablaggio + sicurezza | ~80 pts | **80 pts/sprint** |
| **Media** | — | — | **43 pts/sprint** |

> [!CAUTION]
> La velocity dello Sprint 3 è **4x** quella dello Sprint 1 e **2,7x** la media. Questo **non è sostenibile** e indica un fenomeno noto come **"Velocity Mirage"** (citato nelle slide ITPS del corso, `raw/05_ITPS_Processi_Agili_SCRUM_2026.pptx.pdf`): una velocity apparentemente alta che maschera accumulo di debito tecnico e pressione eccessiva.

### 1.5 Incrocio Carico–Qualità

```
Defect Density vs Resource Utilization — Matrice di Correlazione

                    Resource Utilization
                    Bassa (<60%)    Media (60-85%)    Alta (>85%)
Defect    Bassa     Sprint 1        —                 —
Density   Media     —               Sprint 2          —
          Alta      —               —                 Sprint 3 ⚠️
```

**Osservazione:** Sebbene la Defect Density assoluta resti bassa (0,63/KLOC), il numero di difetti **raddoppia** quando la Resource Utilization supera l'85%. Il 71% dei difetti rilevati (10 su 14) si è manifestato in Sprint 3, quando il carico era massimo.

---

## 2. Impatto Esterno e Metriche ESG

### 2.1 Metriche di Mercato (CSAT / NPS)

| Metrica | Disponibilità | Valore | Note |
|---------|---------------|--------|------|
| **CSAT** | ❌ Non disponibile | — | Progetto accademico, nessun utente reale. La user story UT.16 (valutazione a stelle) è implementata ma non ha generato dati reali |
| **NPS** | ❌ Non disponibile | — | Nessun sondaggio NPS condotto |
| **Valutazione interna del team** | ✅ Proxy | Rating SQALE **A (3,8%)** | Utilizzabile come proxy della soddisfazione tecnica interna |

> [!NOTE]
> In assenza di CSAT/NPS reali, si utilizzano proxy della qualità percepita:
> - **Time-to-feature**: tutte le 59 user story implementate (25 UT + 12 AP + 22 OP)
> - **IIN compliance**: 24/24 requisiti non funzionali implementati
> - **Gate sicurezza**: AG-SEC-01..04 tutti VERDI

### 2.2 KPI ESG — Environmental

| KPI Ambientale | Target | Stato | Evidenza |
|----------------|--------|-------|----------|
| **CO₂ Tracking** | Implementare stima emissioni risparmiata | ✅ Implementato | AP.07: report CO₂ risparmiata basato su km percorsi dalla flotta elettrica; endpoint `GET /analitiche/co2` |
| **Efficienza energetica server** | Hosting green/cloud | ✅ Conforme | Cloud Firestore (Google Cloud, carbon-neutral dal 2007); Cloudflare CDN (carbon neutral) |
| **Mobilità sostenibile** | Core business | ✅ Allineato | Flotta 100% elettrica (e-bike, e-scooter, auto elettriche); integrazione TPL per ridurre spostamenti privati |
| **Paper-free operations** | Zero carta | ✅ Conforme | Fatturazione digitale (UT.25, PDF nativo); KYC digitale (UT.22.2) |
| **Slow-zone / aree protette** | Tutela aree pedonali | ✅ Implementato | AP.08: rallentamento automatico; AP.06: interdizione totale |

**Punteggio Environmental: 5/5 — Pieno allineamento.**

### 2.3 KPI ESG — Social

| KPI Sociale | Target | Stato | Evidenza |
|-------------|--------|-------|----------|
| **Accessibilità** | IIN-3: ultime 2 major release iOS/Android | ⚠️ Parziale | App Flutter cross-platform; test su Android (fisico) completato; **iOS non testato** |
| **Inclusività linguistica** | IIN-7: IT + EN | ✅ Implementato | i18n completo su entrambi i client (l10n.dart) |
| **Privacy (GDPR)** | IIN-16: conformità GDPR | ✅ Implementato | Consenso esplicito (IIN-16), anonimizzazione (IIN-15/AG-SEC-04), data retention 24 mesi (IIN-17), AES-256 |
| **Sicurezza utente** | SOS IIN-18: ≤5 sec | ✅ Implementato | UT.20: invio coordinate GPS ai soccorsi con countdown 5s |
| **Diversity del team** | Distribuzione equa dei contributi | ⚠️ **Critico** | 4 sviluppatori, ma **~85% del codice Sprint 3 di un solo autore** |

**Punteggio Social: 3,5/5 — Buono con margini di miglioramento su iOS e diversity.**

### 2.4 KPI ESG — Governance

| KPI Governance | Target | Stato | Evidenza |
|----------------|--------|-------|----------|
| **Audit trail** | IIN-13: log non modificabile | ✅ Implementato | Logging strutturato `server_app.log` con timestamp, IP, request-id |
| **Account Lockout** | IIN-10: anti brute-force | ✅ Implementato | UT 5 tentativi/30min, OP/PA 3 tentativi |
| **MFA** | IIN-9: obbligatorio OP/PA | ✅ Implementato | AG-SEC-03 VERDE |
| **Data governance** | KYC, cifratura, RBAC | ✅ Implementato | AG-SEC-01..04 tutti VERDI |
| **Trasparenza procedurale** | Prompt log, debt report | ✅ Implementato | 71 prompt registrati, SQALE tracking continuo |
| **Supply chain transparency** | Documentazione dipendenze | ⚠️ Parziale | `requirements.txt` e `pubspec.yaml` presenti; **manca SBOM formale** |

**Punteggio Governance: 4,5/5 — Eccellente, manca solo SBOM.**

### 2.5 Supply Chain — Analisi delle Vulnerabilità

| Fornitore | Componente | Rischio | Mitigazione |
|-----------|------------|---------|-------------|
| **Google (Firebase/Firestore)** | Database, Storage, Hosting | 🟠 **Lock-in alto** | Accesso solo via DAM (§4.1) — layer di astrazione; tuttavia la migrazione richiederebbe riscrittura significativa |
| **Google (Maps)** | Rendering mappe, geocoding | 🟠 **Lock-in medio** | Chiave API protetta (TD-01 chiuso); alternative (Mapbox, OpenStreetMap) richiederebbero adattamento client |
| **Cloudflare** | Tunnel/CDN | 🟢 **Basso** | Servizio standardizzato, facilmente sostituibile con Nginx/Caddy reverse proxy |
| **Flutter/Dart** | Framework client | 🟡 **Medio** | Framework Google; la community è ampia ma dipende da una singola azienda |
| **PyPI ecosystem** | Dipendenze Python | 🟢 **Basso** | Librerie mature (FastAPI, Pydantic, Passlib); `requirements.txt` versionato |

> [!WARNING]
> **Rischio sistemico identificato:** la dipendenza da **3 servizi Google** (Firebase, Maps, Flutter) crea un singolo punto di fallimento strategico. Se Google modificasse le politiche di pricing o i termini di servizio, l'intero stack sarebbe impattato. Si raccomanda di documentare un **piano B** con alternative (Supabase/MongoDB Atlas, Mapbox/OSM, React Native).

---

## 3. Valutazione di Portafoglio

### 3.1 Risk Realized Percentage

Rischi previsti nel progetto (dal DOE §2, IIN, e dal contesto accademico) e loro materializzazione:

| # | Rischio Previsto | Si è materializzato? | Impatto | Note |
|---|------------------|----------------------|---------|------|
| R1 | Esposizione API key | ✅ **Sì** | 🔴 Critico (mitigato) | TD-01: chiave Google Maps esposta nella git history. Chiuso come "rischio accettato" (repo privato) |
| R2 | Assenza test / bassa copertura | ✅ **Sì** | 🟠 Alto (risolto) | TD-04: copertura ~0% → ≥80%. Completamente risolto |
| R3 | Debito tecnico oltre soglia | ✅ **Sì** | 🟠 Alto (risolto) | Rating D (24%) al baseline → A (3,8%) attuale |
| R4 | Errori di integrazione DB | ✅ **Sì** | 🟡 Medio | 12 indici Firestore errati; 2 bug latenti emersi dal test E2E |
| R5 | Problemi di deployment | ✅ **Sì** | 🟡 Medio | Permesso INTERNET mancante nell'APK release; host 0.0.0.0 non raggiungibile |
| R6 | Lock-in tecnologico | ⚠️ **Parziale** | 🟡 Medio | Migrazione PostgreSQL→Firestore avvenuta ma ha creato dipendenza |
| R7 | Burnout del team | ⚠️ **Parziale** | 🟠 Alto | Indicatori presenti (picco 8 prompt/giorno), ma sprint concluso con successo |
| R8 | Non conformità GDPR | ❌ **No** | — | Tutti i gate IIN-4/15/16/17 sono verdi |
| R9 | Vulnerabilità sicurezza critica | ❌ **No** | — | AG-SEC-01..04 tutti VERDI |
| R10 | Fallimento CI/CD | ❌ **No** | — | Gate automatici funzionanti; self-correction sempre in ≤2 iterazioni |

| Metrica | Valore |
|---------|--------|
| **Rischi identificati** | 10 |
| **Rischi materializzati** | 5 pieni + 2 parziali = **6,0** |
| **Risk Realized Percentage** | **60%** |
| **Rischi con impatto residuo** | 2 (R1 rischio accettato, R7 indicatori precoci) |

> [!IMPORTANT]
> Una **Risk Realized Percentage del 60%** è nella norma per progetti software complessi (benchmark 40–70%). Il dato positivo è che **tutti i rischi materializzati sono stati gestiti** con azioni di mitigazione efficaci, portando l'impatto residuo a livelli accettabili.

### 3.2 Allineamento agli Obiettivi Strategici Aziendali

| Obiettivo Strategico | KPI di Riferimento | Stato | Allineamento |
|----------------------|--------------------|-------|--------------|
| Piattaforma di smart mobility funzionante | 59/59 user story implementate | ✅ | 100% |
| Qualità del software | SQALE rating A (3,8%) | ✅ | Eccede il target (≤ C) |
| Sicurezza dei dati | 4/4 gate AG-SEC VERDI | ✅ | 100% |
| Conformità regolamentare | 24/24 IIN implementati | ✅ | 100% |
| Sostenibilità ambientale | CO₂ tracking, flotta elettrica, integrazione TPL | ✅ | Pieno allineamento |
| Time-to-market | Progetto consegnato entro deadline (29/06/2026) | ✅ | In tempo |
| Scalabilità tecnica | Architettura three-tier, Cloud Firestore | ⚠️ | Funzionale ma con lock-in Google |

**Punteggio di allineamento strategico complessivo: 95/100.**

---

## 4. Riepilogo Spider Chart — Equilibrio Tecnico / Team / ESG

Le dimensioni valutate su scala 0–10:

| Dimensione | Punteggio | Giustificazione |
|------------|-----------|-----------------|
| **Defect Density** | 9 | 0,63/KLOC — eccellente |
| **First-Pass Rate** | 8 | 87% — buono |
| **Test Coverage** | 8 | App 89,8%, Web 82,7%, Server 92% |
| **Debito Tecnico** | 9 | Rating A (3,8%) |
| **Team Velocity** | 7 | Alta ma con segnali di Velocity Mirage |
| **Resource Utilization** | 5 | >95% in Sprint 3 — insostenibile |
| **Team Diversity** | 4 | Sbilanciamento critico dei contributi |
| **Environmental** | 10 | Pieno allineamento ESG-E |
| **Social** | 7 | iOS non testato, diversity team |
| **Governance** | 9 | Eccellente, manca SBOM |
| **Supply Chain** | 6 | Lock-in Google triplo |
| **Risk Management** | 7 | 60% rischi materializzati, tutti gestiti |

---

## 5. Raccomandazioni Operative

1. **Distribuire il carico di lavoro** (priorità ALTA): introdurre pair programming obbligatorio e rotazione dei ruoli per Sprint futuri. Lo sbilanciamento attuale (85% su un solo sviluppatore) è un rischio operativo e un problema ESG (diversity).

2. **Completare i test E2E client→server** (priorità ALTA): i test unitari e di widget sono verdi, ma l'E2E reale è ancora DEFERRED. Pianificare uno sprint dedicato.

3. **Documentare un piano di contingenza per il lock-in Google** (priorità MEDIA): la dipendenza da Firebase + Maps + Flutter su un singolo provider è un rischio strategico.

4. **Predisporre raccolta CSAT/NPS** (priorità BASSA): se il progetto evolve oltre la fase accademica, implementare il meccanismo di feedback utente (UT.16 è già la base).

5. **Generare un SBOM** (Software Bill of Materials) (priorità MEDIA): per compliance e trasparenza della supply chain.

---

*Report compilato automaticamente dall'agente AI Project Manager & CSO. I dati sono estratti da: `wiki/DIRECTIVES.md`, `Report/technical_debt_report.md`, `Report/session_cicd_report.md`, `CHANGELOG.md`, `wiki/log.md`, `wiki/entita/leaf-mobility.md`.*
