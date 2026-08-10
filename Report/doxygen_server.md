# Documentazione Doxygen — Server

**Progetto:** LEAF Mobility — Server
**Percorso sorgente:** `server/`
**Generata il:** 04/08/2026

## 1. `__init__.py`

## 2. `business_tier\__init__.py`

## 3. `business_tier\gestore_assistenza_ticket\__init__.py`

### `class GestoreAssistenzaTicket`
! @brief Gestisce supporto utenti e ticket di intervento (UT.09, OP.08/16/19).

Responsabilita': coda centralizzata delle richieste in entrata, creazione e
assegnazione ticket ai tecnici, tracciamento dello stato fino a chiusura. La
persistenza Ã¨ delegata al @ref DataAccessManager (Integration Tier, tier
adiacente Â§4); il `codice_identificativo_mezzo` Ã¨ denormalizzato alla create (Â§6.6).

@param dao DataAccessManager opzionale; se None risolto dall'ambiente
           (@ref ottieni_dao_opzionale).

#### `__init__()`
! @brief Costruisce il gestore, opzionalmente con un DAO/gateway iniettati (test).
@param dao DataAccessManager da usare; se None risolto dall'ambiente.
@param email Gateway email per le notifiche di assistenza; default @ref GatewayEmail
             (disattivato finchÃ© non configurato via ambiente).

#### `_dao_o_errore()`
! @brief Restituisce il DAO disponibile o segnala la persistenza in sviluppo.
@return DataAccessManager pronto.
@throws NotImplementedError Se la persistenza non e' configurata (slice "in sviluppo", Â§9).

#### `apri_assistenza()`
! @brief Apre una richiesta di assistenza in coda per un utente (UT.09).
@param id_utente Id dell'utente richiedente (FK â†’ utenti, Â§6.9).
@param oggetto Oggetto sintetico della richiesta.
@param messaggio Testo della richiesta di supporto.
@param id_corsa Id della corsa correlata (opzionale, FK â†’ corse).
@return Identificativo del ticket di assistenza creato.
@throws NotImplementedError Se la persistenza non e' configurata.
@throws ErroreIntegrita Se l'utente non esiste (integritÃ  referenziale).

#### `_notifica_apertura()`
! @brief Invio email best-effort all'apertura di un ticket di assistenza (UT.09).

Avvisa la casella di supporto (`support@leafmobility.example.com`) della nuova richiesta e
conferma la ricezione all'utente sul suo indirizzo registrato. Ãˆ un effetto
accessorio: se il gateway Ã¨ disattivato o l'invio fallisce, non altera l'esito
dell'apertura del ticket (nessuna eccezione propagata).

@param dao DataAccessManager connesso (per risolvere l'email dell'utente).
@param id_utente Id dell'utente richiedente.
@param id_ticket Id del ticket appena creato.
@param oggetto Oggetto della richiesta.
@param messaggio Testo della richiesta.
@return Nessuno.

#### `elenca_assistenza()`
! @brief Coda centralizzata delle richieste di assistenza in entrata (OP.08).
@param stato Filtro opzionale su `stato` (es. "aperto" per le sole pendenti).
@return Lista dei ticket di assistenza per la dashboard operatore.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `rispondi_assistenza()`
! @brief Prende in carico e risponde a una richiesta di assistenza (OP.08).
@param id_ticket Id del ticket di assistenza.
@param id_operatore Id dell'operatore che risponde (FK â†’ operatori).
@param risposta Testo della risposta all'utente.
@param stato Nuovo stato del ticket (default "in_lavorazione"; "chiuso" per concludere).
@return Nessuno.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `crea_ticket()`
! @brief Crea un ticket di manutenzione per un veicolo (OP.16/19).
@param id_mezzo Id del mezzo guasto (FK obbligatoria â†’ mezzi, Â§6.3).
@param id_operatore_creatore Id dell'operatore che apre il ticket (FK â†’ operatori).
@param descrizione Descrizione del guasto/intervento richiesto.
@param priorita PrioritÃ : bassa | media | alta.
@return Identificativo del ticket creato.
@throws ValueError Se la prioritÃ  non e' ammessa.
@throws NotImplementedError Se la persistenza non e' configurata.
@throws ErroreIntegrita Se mezzo/operatore non esistono (integritÃ  referenziale).

#### `assegna_tecnico()`
! @brief Assegna un ticket di manutenzione a un tecnico (OP.16).
@param id_ticket Id del ticket di manutenzione.
@param id_tecnico Id del tecnico assegnatario.
@return Nessuno.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `elenca_manutenzione()`
! @brief Elenca i ticket di manutenzione per la dashboard operatore (OP.19).
@param stato Filtro opzionale su `stato` (es. "aperto"/"assegnato"/"chiuso").
@return Lista dei ticket di manutenzione (con codice_identificativo_mezzo denormalizzato).
@throws NotImplementedError Se la persistenza non e' configurata.

#### `elenca_tecnici()`
! @brief Elenca i tecnici manutentori assegnabili ai ticket (OP.16).
@return Lista dei tecnici (id, nome, specializzazione, stato).
@throws NotImplementedError Se la persistenza non e' configurata.

#### `chiudi_manutenzione()`
! @brief Chiude un ticket di manutenzione a intervento concluso (OP.19).

Segna il ticket come `chiuso` con timestamp; il rientro in servizio del mezzo Ã¨
gestito separatamente dal @ref GestoreFlotta (aggiornamento `stato_operativo`).

@param id_ticket Id del ticket di manutenzione.
@return Nessuno.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `segnala_sos()`
! @brief Registra una segnalazione di emergenza SOS con la posizione (UT.20, IIN-18).

Inoltra ai soccorsi le coordinate dell'utente in pericolo: la segnalazione Ã¨
persistita in `segnalazioni_emergenza` con timestamp e stato iniziale "inoltrata"
(il recapito reale ai soccorsi Ã¨ esterno, Â§13). La posizione Ã¨ normalizzata/cifrata
at-rest dal @ref DataAccessManager (IIN-4).

@param id_utente Id dell'utente che attiva l'SOS.
@param lat Latitudine corrente dell'utente.
@param lon Longitudine corrente dell'utente.
@param id_corsa Id della corsa in atto (opzionale).
@return {id_segnalazione, stato}.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `elenca_sos()`
! @brief Coda live delle segnalazioni di emergenza per l'operatore (UT.20/OP.08).

Alimenta la coda SOS della console operatore (in precedenza hardcoded): elenca le
segnalazioni persistite da @ref segnala_sos, dalla piÃ¹ recente, arricchendole con
l'etichetta leggibile dell'utente (username/nominativo) cosÃ¬ l'operatore identifica
chi ha chiesto aiuto senza esporre l'id grezzo.

@param stato Filtro opzionale su `stato` (inoltrata/presa_in_carico/chiusa).
@return Lista delle segnalazioni SOS, ordinate per timestamp decrescente.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `aggiorna_stato_sos()`
! @brief Aggiorna lo stato di una segnalazione SOS (presa in carico/chiusura, OP.08).
@param id_segnalazione Id della segnalazione su cui agire.
@param stato Nuovo stato (@ref STATI_SOS).
@param id_operatore Id dell'operatore che prende in carico (opzionale).
@return {id_segnalazione, stato}.
@throws ValueError Se lo stato non e' ammesso.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `_etichetta_utente()`
! @brief Etichetta leggibile dell'utente di una SOS (username + nominativo).
@param dao DataAccessManager connesso.
@param id_utente Id dell'account che ha attivato l'SOS.
@return {username, nominativo} (vuoti/ripiego se l'account non e' risolvibile).

## 4. `business_tier\gestore_corse\__init__.py`

### `class GestoreCorse`
! @brief Gestisce prenotazioni e corse (UT.02, UT.03, UT.04, UT.10, UT.12).

Responsabilita': disponibilita' esclusiva del mezzo (blocco in transazione),
stima preventiva del costo (tariffa locale deterministica), avvio/pausa/termine
corsa e calcolo dell'importo finale. La persistenza e i vincoli sono delegati al
@ref DataAccessManager (Integration Tier, tier adiacente §4).

@param dao DataAccessManager opzionale; se None risolto dall'ambiente
           (@ref ottieni_dao_opzionale).

#### `__init__()`
! @brief Costruisce il gestore con DAO e gateway esterni (simulazioni locali).
@param dao DataAccessManager da usare; se None risolto dall'ambiente.
@param iot Gateway IoT (comandi sblocco/blocco); default simulazione locale.
@param pagamenti Gateway pagamenti (addebito); default simulazione locale.
@param routing Gateway routing (percorsi/ETA); default simulazione locale.
@param email Gateway email per le notifiche transazionali; default @ref GatewayEmail
             (disattivato finché non configurato via ambiente).
@param geofencing Gestore geofencing per il perimetro operativo di fine-noleggio
             (OP.04, composizione intra-tier); default su stesso DAO.

#### `_notifica_utente()`
! @brief Email transazionale best-effort all'utente di una corsa/prenotazione.

Risolve l'email registrata dell'utente dal @ref DataAccessManager e invia il
messaggio. È un effetto accessorio (come per i ticket di assistenza): se il gateway
è disattivato (app password assente) o l'invio fallisce, non altera l'esito
dell'operazione di dominio (nessuna eccezione propagata).

@param dao DataAccessManager connesso (per risolvere l'email dell'utente).
@param id_utente Id dell'utente destinatario (FK → account).
@param oggetto Oggetto del messaggio.
@param corpo Corpo testuale del messaggio.
@return Nessuno.

#### `_dao_o_errore()`
! @brief Restituisce il DAO disponibile o segnala la persistenza in sviluppo.
@return DataAccessManager pronto.
@throws NotImplementedError Se la persistenza non e' configurata (slice "in sviluppo", §9).

#### `costo_cent()`
! @brief Calcola il costo di una corsa in centesimi (tariffa locale, UT.03/UT.04).
@param tipo_mezzo Tipo del mezzo (ebike/monopattino/ecar/emotorbike).
@param durata_min Durata in minuti (>= 0).
@return Costo in centesimi: sblocco + al_minuto * durata.

#### `dettaglio_costo()`
! @brief Scompone il costo in sblocco + corsa + totale (UT.03/UT.04, punto 8).

Restituisce le tre voci separate richieste dalla UI per gli utenti **senza
abbonamento** (sblocco + corsa mostrati distintamente, poi la somma). Per gli
abbonati a pagamento lo sblocco è gratuito e la corsa è coperta dai token: il
chiamante (@ref stima_dettaglio / @ref termina) azzera le voci di conseguenza.

@param tipo_mezzo Tipo del mezzo (ebike/monopattino/ecar/emotorbike).
@param durata_min Durata in minuti (>= 0).
@return {sblocco_cent, corsa_cent, totale_cent}.

#### `_ha_patente_caricata()`
! @brief Indica se l'utente ha caricato almeno un documento patente (UT.22.2, punto 6).

Verifica l'esistenza di un documento `patente` in `documenti_ufficiali` (qualsiasi
stato di verifica): è il prerequisito per noleggiare auto/moto elettriche. Tollerante
ai problemi di persistenza (in caso di errore ritorna False, lato sicuro: senza prova
della patente il noleggio del mezzo a motore è inibito).

@param dao DataAccessManager connesso.
@param id_utente Id dell'utente.
@return True se esiste un documento patente caricato dall'utente.

#### `_verifica_patente_se_richiesta()`
! @brief Inibisce prenotazione/avvio di auto e moto elettriche senza patente (punto 6).
@param dao DataAccessManager connesso.
@param id_utente Id dell'utente.
@param tipo_mezzo Tipo del mezzo richiesto.
@return Nessuno.
@throws ValueError Se il mezzo richiede la patente e l'utente non l'ha caricata.

#### `stima_costo()`
! @brief Stima preventiva del costo di una corsa su un mezzo (UT.03).
@param id_mezzo Identificativo del mezzo selezionato.
@param durata_min Durata stimata in minuti (default 15).
@return Costo stimato in centesimi.
@throws NotImplementedError Se la persistenza non e' configurata.
@throws ValueError Se il mezzo non esiste.

#### `stima_dettaglio()`
! @brief Stima con voci separate e stato abbonamento (UT.03, punto 8).

Per gli utenti **senza abbonamento** restituisce sblocco + corsa + totale distinti
(mostrati separatamente in app). Per gli **abbonati a pagamento** lo sblocco è
gratuito e la corsa è coperta dai token: il totale è azzerato e si riportano token
inclusi/residui e la percentuale già utilizzata (la UI mostra % + token).

@param id_mezzo Identificativo del mezzo selezionato.
@param id_utente Id dell'utente (per risolvere l'abbonamento attivo).
@param durata_min Durata stimata in minuti (default 15).
@return {sblocco_cent, corsa_cent, totale_cent, costo_stimato_cent, ha_abbonamento,
         [token_inclusi, token_residui, percentuale_usata]}.
@throws NotImplementedError Se la persistenza non e' configurata.
@throws ValueError Se il mezzo non esiste.

#### `corsa_attiva()`
! @brief Corsa in corso o in pausa dell'utente, o None (UT.10/UT.12, punto 2).

Permette al client di **recuperare** la corsa in svolgimento dopo un riavvio
dell'app (lo stato locale è volatile): si interroga lo storico dell'utente e si
seleziona la prima corsa con stato `in_corso` o `in_pausa`. Riusa l'indice
composito id_utente+data_ora_inizio già definito per lo storico (UT.17).

@param id_utente Id dell'utente.
@return Documento corsa attiva (con id_mezzo, tipo_mezzo, stato…), o None.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `prenota()`
! @brief Prenota un mezzo con blocco esclusivo (UT.02).
@param id_utente Id dell'utente.
@param id_mezzo Id del mezzo.
@param scadenza Scadenza ISO 8601 della prenotazione (opzionale, UT.15).
@return Id della prenotazione creata.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `prenotazioni()`
! @brief Prenotazioni attive di un utente, dalla più recente (UT.02/UT.21).
@param id_utente Id dell'utente.
@param limite Numero massimo di prenotazioni restituite (default 50).
@return Lista delle prenotazioni con stato "attiva".
@throws NotImplementedError Se la persistenza non e' configurata.

#### `annulla_prenotazione()`
! @brief Annulla una prenotazione attiva dell'utente e libera il mezzo (UT.12).
@param id_prenotazione Id della prenotazione da annullare.
@param id_utente Id dell'utente richiedente (controllo di proprietà).
@return Esito {id_prenotazione, id_mezzo, annullata}.
@throws NotImplementedError Se la persistenza non e' configurata.
@throws ErroreIntegrita Se la prenotazione non esiste o non appartiene all'utente.
@throws MezzoNonDisponibile Se la prenotazione non è più attiva.

#### `prenotazioni_attive_tutte()`
! @brief Tutte le prenotazioni attive per la console operatore (OP.12).

Vista gestionale (≠ @ref prenotazioni, per-utente): elenca le prenotazioni con
stato "attiva" sull'intera flotta, dalla più recente, arricchite con l'etichetta
leggibile dell'utente (username/nominativo) per identificare chi trattiene il mezzo.

@param limite Numero massimo di prenotazioni restituite (default 100).
@return Lista delle prenotazioni attive con etichetta utente.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `annulla_prenotazione_op()`
! @brief Forza l'annullamento di una prenotazione attiva da parte dell'operatore (OP.12).

A differenza di @ref annulla_prenotazione (UT, con controllo di proprietà), salta la
verifica del titolare — è un'azione autorizzata dell'operatore per rimettere a
disposizione un mezzo trattenuto in modo anomalo — e libera il mezzo. Notifica
comunque l'utente titolare dell'annullamento operatore.

@param id_prenotazione Id della prenotazione da annullare.
@return Esito {id_prenotazione, id_mezzo, annullata}.
@throws NotImplementedError Se la persistenza non e' configurata.
@throws ErroreIntegrita Se la prenotazione non esiste.
@throws MezzoNonDisponibile Se la prenotazione non è più attiva.

#### `_etichetta_utente()`
! @brief Etichetta leggibile dell'utente di una prenotazione (username + nominativo).
@param dao DataAccessManager connesso.
@param id_utente Id dell'account titolare.
@return {username, nominativo} (vuoti/ripiego se l'account non e' risolvibile).

#### `avvia()`
! @brief Sblocca il mezzo e avvia la corsa (UT.10).
@param id_utente Id dell'utente.
@param id_mezzo Id del mezzo da sbloccare.
@param id_prenotazione Id della prenotazione da convertire (opzionale).
@param durata_stimata_min Durata stimata per la stima preventiva del costo.
@return Esito {id_corsa, costo_stimato_cent, sbloccato}.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `percorsi()`
! @brief Opzioni di percorso multimodali sharing+TPL (UT.07), via gateway routing.
@param origine Coordinate (lat, lon) di partenza.
@param destinazione Coordinate (lat, lon) di arrivo.
@return Percorsi ordinati per tempo (simulazione locale deterministica).

#### `suggerisci_luoghi()`
! @brief Suggerimenti di luogo per l'autocompletamento della ricerca (UT.07).
@param query Testo parziale digitato dall'utente.
@param limite Numero massimo di suggerimenti restituiti (default 8).
@return Elenco di {nome, lat, lon} dal gazetteer del @ref GatewayRouting.

#### `_arricchisci_percorso()`
! @brief Arricchisce un'opzione di percorso grezza con nome/descrizione/mezzo (UT.08).
@param percorso Opzione grezza del routing ({modalita, distanza_m, durata_min}).
@return Opzione con nome/descrizione/ha_tpl/tipo_consigliato/distanza_km aggiunti.

#### `pianifica_percorsi()`
! @brief Pianifica i percorsi tra due luoghi, per nome o coordinate (UT.07/UT.08).

Le coordinate esplicite (es. posizione corrente) prevalgono; altrimenti il nome
è geocodificato sul gazetteer locale. Calcola le opzioni multimodali via gateway
routing e le arricchisce con nome/descrizione/mezzo consigliato.

@param da Nome del luogo di partenza (geocodificato se @p origine è assente).
@param a Nome del luogo di arrivo (geocodificato se @p destinazione è assente).
@param origine Coordinate (lat, lon) di partenza che prevalgono sul nome.
@param destinazione Coordinate (lat, lon) di arrivo che prevalgono sul nome.
@return {origine, destinazione, percorsi, totale} con opzioni ordinate per tempo.
@throws ValueError Se un luogo indicato per nome non è nel gazetteer.

#### `storico()`
! @brief Storico delle corse di un utente, dalla più recente (UT.17).
@param id_utente Id dell'utente.
@param limite Numero massimo di corse restituite (default 50).
@return Lista di corse dell'utente ordinate per inizio decrescente.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `fatture()`
! @brief Elenco delle fatture di un utente, per copia digitale (UT.25).

Le Fatture non referenziano l'utente direttamente (FK → pagamenti, §6.9): si
risolvono i pagamenti dell'utente e si selezionano le fatture collegate.

@param id_utente Id dell'utente.
@param limite Numero massimo di fatture restituite (default 50).
@return Lista di fatture dell'utente.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `pausa()`
! @brief Mette in pausa una corsa in corso (UT.12).
@param id_corsa Id della corsa.
@return Esito {id_corsa, stato}.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `riprendi()`
! @brief Riprende una corsa precedentemente messa in pausa (UT.12).
@param id_corsa Id della corsa.
@return Esito {id_corsa, stato}.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `valuta()`
! @brief Registra la valutazione a stelle di una corsa conclusa (UT.16).

Salva sul documento corsa il feedback dell'utente (1-5 stelle) sulla qualità
del noleggio appena concluso.

@param id_corsa Id della corsa da valutare.
@param stelle Valutazione da 1 a 5.
@return Esito {id_corsa, valutazione}.
@throws ValueError Se le stelle sono fuori dall'intervallo 1-5 o la corsa non esiste.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `_abbonamento_con_token()`
! @brief Abbonamento attivo (non scaduto) con token residui da scalare, o None (punto 7).

Tollerante a errori/assenza dati: in caso di problemi ritorna None, cosi' il termine
corsa ripiega sempre sull'addebito monetario standard (UT.04) senza mai fallire.

@param dao DataAccessManager connesso.
@param id_utente Id dell'utente della corsa.
@return L'abbonamento da scalare, oppure None se non applicabile.

#### `termina()`
! @brief Conclude la corsa, blocca il mezzo, addebita e fattura (UT.04/UT.25).

Sequenza: conclude la corsa (durata + mezzo liberato), calcola l'importo finale
(tariffa locale), blocca il mezzo (gateway IoT), addebita l'utente (gateway
pagamenti, sim. locale), registra il Pagamento (XOR su id_corsa) ed emette la
Fattura con scorporo IVA. Il PDF della fattura va su Cloud Storage (stub
`storage_path_pdf`, §4 schema): qui non generato.

OP.05/OP.04: se sono fornite le coordinate di chiusura le registra (cifrate
at-rest, IIN-4) e valuta il perimetro operativo in **modalità soft** — segnala
`fuori_area_operativa` senza inibire il rilascio (enforcement hard separato).

@param id_corsa Id della corsa.
@param km_percorsi Chilometri percorsi (IIN-24).
@param lat Latitudine GPS di chiusura (opzionale, OP.05).
@param lon Longitudine GPS di chiusura (opzionale, OP.05).
@return Esito {id_corsa, durata_min, costo_finale_cent, id_pagamento, id_fattura,
    fuori_area_operativa}.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `crea_promozione()`
! @brief Configura una promozione/incentivo geografico o di parcheggio (OP.09/OP.15).

OP.09: credito bonus per i rilasci in aree di parcheggio designate. OP.15: sconto
percentuale per i noleggi avviati entro perimetri configurabili. La promozione può
legarsi a un'area (`id_area` → aree_limitate) per circoscriverne l'ambito geografico.

@param dati Campi della promozione (tipo, descrizione, valore, id_area opz., date opz.).
@param creata_da Id dell'operatore che configura la promozione (FK → operatori, §6.9).
@return Id della promozione creata.
@throws ValueError Se il tipo di promozione non e' ammesso.
@throws NotImplementedError Se la persistenza non e' configurata.
@throws ErroreIntegrita Se `creata_da`/`id_area` non esistono (integrità referenziale).

#### `elenca_promozioni()`
! @brief Elenca le promozioni configurate per la dashboard operatore (OP.09/OP.15).
@param solo_attive Se True, restituisce solo le promozioni con `stato` == "attiva".
@return Lista delle promozioni (sconti, incentivi parcheggio, tariffe evento).
@throws NotImplementedError Se la persistenza non e' configurata.

#### `disattiva_promozione()`
! @brief Disattiva una promozione (la rende non più applicabile, OP.15).
@param id_promozione Id della promozione da disattivare.
@return Nessuno.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `_emetti_fattura()`
! @brief Emette una Fattura per un pagamento, con scorporo IVA (UT.25).
@param dao DataAccessManager connesso.
@param id_pagamento Id del pagamento fatturato (FK → pagamenti).
@param totale_cent Totale lordo in centesimi.
@return Id della fattura creata.

## 5. `business_tier\gestore_flotta\__init__.py`

### `class GestoreFlotta`
! @brief Gestisce stato, distribuzione e soglie della flotta (OP.01/02/03/20/22).

Responsabilita': stato in tempo reale di ogni mezzo (disponibile, in uso, in
manutenzione, scarico), soglie minime per area con alert, liste mezzi guasti,
report giornalieri per stato operativo, ricerca dei mezzi disponibili per gli
utenti (UT.01/UT.05). La persistenza e' delegata al @ref DataAccessManager
(Integration Tier, tier adiacente §4); la telemetria proviene dal GatewayIoT.

@param dao DataAccessManager opzionale; se None risolto dall'ambiente
           (@ref ottieni_dao_opzionale).

#### `__init__()`
! @brief Costruisce il gestore, opzionalmente con un DAO iniettato (test).
@param dao DataAccessManager da usare; se None risolto dall'ambiente.

#### `conteggio_per_stato()`
! @brief Conta i mezzi raggruppati per stato operativo (OP.13/20).
@return Mappa stato -> numero di mezzi.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `elenco()`
! @brief Elenca i mezzi della flotta per la dashboard OP (AP.03/OP.03/OP.20).

Vista operativa completa dello stato dei mezzi (disponibile, in uso, in
manutenzione, scarico). A differenza di @ref mezzi_disponibili (vista utente
ristretta ai disponibili nei pressi), questa è la vista gestionale dell'operatore.

@param stato Filtro opzionale su `stato_operativo` (es. "guasto" per OP.03).
@param limite Numero massimo di mezzi restituiti (None = tutti).
@return Lista di mezzi (con stato operativo) per la dashboard.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `mezzi_disponibili()`
! @brief Elenca i mezzi disponibili nei pressi di una posizione (UT.01/UT.05).
@param lat Latitudine del centro di ricerca (opzionale).
@param lon Longitudine del centro di ricerca (opzionale).
@param raggio_m Raggio di ricerca in metri (default 2000).
@param tipo Filtro opzionale per tipo di mezzo.
@return Lista di mezzi disponibili (ordinati per distanza se lat/lon presenti).
@throws NotImplementedError Se la persistenza non e' configurata (slice "in sviluppo", §9).

#### `_dao_o_errore()`
! @brief Restituisce il DAO disponibile o segnala la persistenza in sviluppo.
@return DataAccessManager pronto.
@throws NotImplementedError Se la persistenza non e' configurata (slice "in sviluppo", §9).

#### `mezzi_guasti()`
! @brief Elenca i mezzi in stato "Guasto" da ritirare per manutenzione (OP.03).
@return Lista dei mezzi con `stato_operativo == "guasto"`.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `stazioni_ricarica()`
! @brief Elenca le stazioni di ricarica attive sulla mappa (UT.14).
@return Lista delle stazioni con `stato == "attiva"` (posizione + colonnine).
@throws NotImplementedError Se la persistenza non e' configurata.

#### `imposta_soglia_area()`
! @brief Imposta la soglia minima di mezzi per un'area (OP.02).

Registra una soglia che, al di sotto del numero minimo di mezzi presenti
nell'area, genera un'allerta (@ref verifica_soglie) per programmare il
ricollocamento della flotta.

@param id_area Id dell'area di geofencing monitorata.
@param minimo Numero minimo di mezzi richiesto nell'area.
@param id_operatore Id dell'operatore che configura la soglia (FK → account).
@return Id della soglia creata.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `imposta_soglia_batteria()`
! @brief Imposta la soglia di allerta batteria (OP.22).
@param percentuale Percentuale di batteria sotto la quale scatta l'allerta.
@param id_operatore Id dell'operatore che configura la soglia (FK → account).
@param tipo_mezzo Limita la soglia a una tipologia di mezzo (opzionale).
@return Id della soglia creata.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `verifica_soglie()`
! @brief Valuta le soglie configurate e produce le allerte attive (OP.02/OP.22).

Per le soglie `mezzi_area` conta i mezzi nel poligono dell'area (delega geo al
@ref DataAccessManager) e segnala se sotto il minimo; per le soglie `batteria`
segnala i mezzi sotto la percentuale, eventualmente filtrati per tipologia.

@return Elenco di allerte (area sotto soglia o mezzi con batteria insufficiente).
@throws NotImplementedError Se la persistenza non e' configurata.

#### `report_giornaliero()`
! @brief Report giornaliero del conteggio mezzi per stato e batteria scarica (OP.13).

Fornisce alla squadra di recupero il quadro della giornata: conteggi per stato
operativo, numero di mezzi a batteria scarica (< @ref BATTERIA_SCARICA_PCT) e totale.

@return `{per_stato, batteria_scarica, totale}`.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `_mezzo_o_errore()`
! @brief Recupera un mezzo per codice o segnala l'inesistenza.
@param codice_mezzo Codice identificativo del mezzo (id documento).
@return Documento del mezzo.
@throws ValueError Se il mezzo non esiste.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `registra_evento_telemetria()`
! @brief Registra un evento telemetrico nel log del mezzo (OP.07/OP.14).

Scrive nella subcollezione `eventi_telemetria` del mezzo (sblocco, urto,
anomalia, GPS, …). La posizione è serializzata JSON e cifrata at-rest dal
@ref DataAccessManager (campo 🔒 `posizione`, IIN-4).

@param codice_mezzo Codice del mezzo (id documento padre).
@param tipo Tipo di evento (@ref TIPI_TELEMETRIA).
@param lat Latitudine rilevata (opzionale).
@param lon Longitudine rilevata (opzionale).
@param velocita Velocità rilevata (opzionale).
@param batteria Livello batteria rilevato (opzionale).
@param dettagli Note aggiuntive (opzionale).
@return Id dell'evento telemetrico creato.
@throws ValueError Se il tipo non è ammesso o il mezzo non esiste.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `log_telemetrico()`
! @brief Registro degli eventi telemetrici di un mezzo (OP.14).
@param codice_mezzo Codice del mezzo.
@return Elenco degli eventi telemetrici del mezzo (posizione decifrata).
@throws ValueError Se il mezzo non esiste.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `blocca_motore_remoto()`
! @brief Invia il blocco motore remoto a un mezzo e ne traccia l'evento (OP.11).

Immobilizza un mezzo privo di noleggi attivi (anti-spostamento in area non
autorizzata) via @ref GatewayIot e registra un evento telemetrico "blocco"
(OP.14) per la tracciabilità dell'azione.

@param codice_mezzo Codice del mezzo da immobilizzare.
@return True se il comando è stato accettato dal gateway IoT.
@throws ValueError Se il mezzo non esiste.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `sblocca_motore_remoto()`
! @brief Revoca il blocco motore remoto di un mezzo e ne traccia l'evento (OP.11).

Operazione inversa di @ref blocca_motore_remoto: riabilita la movimentazione
di un mezzo precedentemente immobilizzato via @ref GatewayIot e registra un
evento telemetrico "sblocco" (OP.14) per la tracciabilità dell'azione.

@param codice_mezzo Codice del mezzo da riabilitare.
@return True se il comando è stato accettato dal gateway IoT.
@throws ValueError Se il mezzo non esiste.
@throws NotImplementedError Se la persistenza non e' configurata.

## 6. `business_tier\gestore_geofencing\__init__.py`

### `class GestoreGeofencing`
! @brief Gestisce i perimetri geografici e le relative regole (AP.04/06/08, OP.04/09).

Responsabilita': aree di interdizione totale, slow-zone con limite di
velocita', perimetri di fine-noleggio, aree di parcheggio incentivato.
La verifica spaziale (point-in-polygon sul `geohash`/poligono in chiaro, §6.7) è
delegata al @ref DataAccessManager (Integration Tier, tier adiacente §4).

@param dao DataAccessManager opzionale; se None risolto dall'ambiente
           (@ref ottieni_dao_opzionale).

#### `__init__()`
! @brief Costruisce il gestore, opzionalmente con un DAO iniettato (test).
@param dao DataAccessManager da usare; se None risolto dall'ambiente.

#### `_dao_o_errore()`
! @brief Restituisce il DAO disponibile o segnala la persistenza in sviluppo.
@return DataAccessManager pronto.
@throws NotImplementedError Se la persistenza non e' configurata (slice "in sviluppo", §9).

#### `elenca_aree()`
! @brief Elenca le aree limitate configurate (AP.04/06/08, dashboard PA).
@param solo_attive Se True, restituisce solo le aree con `attiva` == True.
@return Lista delle aree limitate (interdizioni, slow-zone, parcheggi).
@throws NotImplementedError Se la persistenza non e' configurata.

#### `crea_area()`
! @brief Crea un'area limitata sulla mappa (cantiere/interdizione/slow-zone).
@param dati Campi dell'area (tipo, nome, poligono/geohash, limite_velocita_kmh, …).
@param creata_da Id dell'account (PA/OP) che traccia l'area (FK → account, §6.9).
@return Id dell'area creata.
@throws NotImplementedError Se la persistenza non e' configurata.
@throws ErroreIntegrita Se `creata_da` non esiste (integrità referenziale).

#### `elimina_area()`
! @brief Rimuove un'area limitata (riapertura al transito, AP.04).
@param id_area Id dell'area da eliminare.
@return Nessuno.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `crea_evento()`
! @brief Inserisce un grande evento cittadino su mappa con date e coordinate (AP.09).

Un evento è modellato come area limitata di tipo "evento" (riconosciuta da
@ref TIPI_LIMITE_VELOCITA): porta il perimetro geografico più le date di
validità, così gli operatori sono informati delle zone che richiederanno il
potenziamento preventivo della flotta. La `categoria` (@ref CATEGORIE_EVENTO)
classifica l'evento (grande evento/cantiere/interruzione) ed è distinta dal
`tipo` d'area; l'etichetta `area` indica il quartiere/zona interessata. Riusa
@ref crea_area per la normalizzazione del poligono e l'integrità referenziale
di `creata_da`.

@param dati Campi dell'evento (nome, categoria, area, poligono/geohash, date, …).
@param creata_da Id dell'account PA che inserisce l'evento (FK → account, §6.9).
@return Id dell'evento (area_limitata) creato.
@throws ValueError Se `categoria` non è tra @ref CATEGORIE_EVENTO.
@throws NotImplementedError Se la persistenza non e' configurata.
@throws ErroreIntegrita Se `creata_da` non esiste (integrità referenziale).

#### `elenca_eventi()`
! @brief Elenca i grandi eventi cittadini configurati (AP.09).
@return Lista delle aree limitate di tipo "evento" (con date e perimetro).
@throws NotImplementedError Se la persistenza non e' configurata.

#### `elimina_evento()`
! @brief Rimuove un grande evento cittadino dalla mappa (AP.09).

Un evento è un'area limitata di tipo "evento" (@ref crea_evento): la rimozione
riusa @ref elimina_area sulla stessa collezione, riaprendo la zona al normale
esercizio una volta concluso o annullato l'evento.

@param id_evento Id dell'evento (area_limitata) da eliminare.
@return Nessuno.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `aree_per_punto()`
! @brief Aree limitate attive che contengono un punto (AP.06/OP.04).
@param lat Latitudine del punto.
@param lon Longitudine del punto.
@return Aree attive il cui poligono contiene il punto.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `dentro_area_operativa()`
! @brief Verifica se un punto è entro il perimetro operativo di fine-noleggio (OP.04).

OP.04: l'operatore definisce uno o più perimetri `area_operativa` entro cui è
consentito il rilascio dei mezzi. Se **nessun** perimetro operativo è configurato
non c'è restrizione (ritorna True). Se ne esiste almeno uno, il punto è valido solo
se cade dentro uno di essi.

@param lat Latitudine del punto di rilascio.
@param lon Longitudine del punto di rilascio.
@return True se il rilascio è consentito (dentro perimetro o nessun perimetro).
@throws NotImplementedError Se la persistenza non e' configurata.

#### `punto_in_area_vietata()`
! @brief Verifica se una coordinata cade in un'area interdetta (AP.06).
@param lat Latitudine del punto.
@param lon Longitudine del punto.
@return True se il punto e' in un perimetro di interdizione/cantiere.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `limite_velocita()`
! @brief Limite di velocita' piu' restrittivo applicabile a un punto (AP.08).

Considera le aree attive contenenti il punto di tipo slow-zone/evento con
`limite_velocita_kmh` valorizzato e restituisce il minimo.

@param lat Latitudine del punto.
@param lon Longitudine del punto.
@return Limite in km/h piu' basso applicabile, o None se nessun limite.
@throws NotImplementedError Se la persistenza non e' configurata.

## 7. `business_tier\gestore_profili_ekyc\__init__.py`

### `class GestoreProfiliEkyc`
! @brief Gestisce profili e onboarding documentale (UT.22.1/UT.22.2, IIN-6).

Responsabilita': creazione profilo, validazione formato KYC (solo PDF/JPG/PNG,
blocco server-side delle altre estensioni), stato di idoneita' alla guida,
autenticazione delle credenziali (IIN-1/IIN-5). La persistenza cifrata (AES-256)
e' delegata al @ref DataAccessManager (Integration Tier, tier adiacente Â§4).

@param dao DataAccessManager opzionale; se None viene risolto dall'ambiente
           (@ref ottieni_dao_opzionale) â€” None finche' la persistenza non e' configurata.

#### `__init__()`
! @brief Costruisce il gestore, opzionalmente con DAO e gateway iniettati (test).
@param dao DataAccessManager da usare; se None risolto dall'ambiente.
@param pagamenti Gateway pagamenti per la validazione carta (default sim. locale).
@param email Gateway email per gli invii transazionali (default sim. locale,
    no-op senza app password).

#### `formato_kyc_valido()`
! @brief Verifica che l'estensione del documento KYC sia ammessa (IIN-6).
@param nome_file Nome o percorso del file caricato.
@return True se l'estensione e' PDF/JPG/PNG, False altrimenti.

#### `autentica()`
! @brief Autentica un soggetto verificando le credenziali su Firestore (IIN-1/IIN-5).

Legge l'account per email tramite il DataAccessManager e verifica la password
contro l'hash Passlib, applicando il lockout per tentativi falliti (IIN-10). Per
OP/PA segnala che serve il secondo fattore MFA (IIN-9): la verifica OTP e
l'emissione del token di sessione sono gestite da @ref ApiGatewaySicurezza.

@param email Email/username di accesso.
@param password Password in chiaro.
@return Esito {autenticato, bloccato?, ruolo?, idAccount?, mfaRichiesto?}.
@throws NotImplementedError Se la persistenza non e' configurata (slice "in sviluppo", Â§9).

#### `_notifica_accesso()`
! @brief Email best-effort di avviso "nuovo accesso" all'utente UT (IIN-13).

Avvisa l'utente di un nuovo accesso riuscito al proprio account sull'indirizzo
registrato. Best-effort: senza app password Ã¨ un no-op (gateway disattivato) e non
interrompe il login; eventuali errori SMTP sono assorbiti dal @ref GatewayEmail.

@param email Indirizzo email registrato dell'utente.
@return Nessuno.

#### `invia_otp()`
! @brief Invia via email l'OTP di accesso MFA (IIN-9, punto 15), best-effort e asincrono.

Recapita l'OTP fuori banda all'indirizzo registrato. Il gateway di sicurezza
(Presentation) genera l'OTP e delega qui l'invio per non importare l'Integration
Tier (vincolo Â§4). L'invio Ã¨ **non bloccante** (thread daemon): il login OP/PA
risponde subito senza attendere la connessione SMTP (~1-3s), che altrimenti
rallenterebbe l'accesso alla dashboard bloccando l'event loop. Best-effort: senza
app password Ã¨ un no-op e non interrompe mai il login.

@param email Indirizzo email del destinatario.
@param otp Codice OTP generato dal gateway di sicurezza.
@return Nessuno (invio delegato in background; l'esito Ã¨ tracciato nei log).

#### `_dao_o_errore()`
! @brief Restituisce il DAO disponibile o segnala la persistenza in sviluppo.
@return DataAccessManager pronto.
@throws NotImplementedError Se la persistenza non e' configurata (slice "in sviluppo", Â§9).

#### `registra()`
! @brief Registra un nuovo utente finale UT con credenziali (UT.22.1, IIN-5).

Valida la robustezza della password (IIN-5), ne calcola l'hash Passlib (mai in
chiaro) e crea l'Account UT e il profilo a chiave condivisa in transazione tramite
@ref DataAccessManager.crea_account. Email e username sono univoci (registri Â§6.4):
un duplicato solleva @c ViolazioneUnicita (mappata a 409 dalla Presentation).

@param email Email di accesso univoca (IIN-1).
@param username Username univoco scelto dall'utente.
@param password Password in chiaro (validata IIN-5, mai persistita).
@param data_nascita Data di nascita ISO-8601 (opzionale, UT.22.1; etÃ  â†’ verifica documenti).
@param nome Nome anagrafico (opzionale, UT.22.1; campo ðŸ”’).
@param cognome Cognome anagrafico (opzionale, UT.22.1; campo ðŸ”’).
@param residenza Indirizzo di residenza, usato anche come indirizzo di fatturazione
                 (opzionale, UT.22.1; coincide con la via di fatturazione, punto 4/5).
@return Id dell'account creato (= id del profilo).
@throws ValueError Se la password non rispetta la politica IIN-5.
@throws NotImplementedError Se la persistenza non e' configurata.
@throws ViolazioneUnicita Se email o username sono gia' registrati.

#### `cambia_password()`
! @brief Cambia la password dell'account, obbligatoria al primo accesso (IIN-12).

Valida la robustezza (IIN-5), ricalcola l'hash Passlib e azzera il flag
`password_temporanea` (per AP/OP provisionati, OP.17): completato il cambio,
l'account non Ã¨ piÃ¹ in stato di primo accesso forzato.

@param id_account Id dell'account autenticato.
@param nuova_password Nuova password in chiaro (validata IIN-5).
@return {id_account, password_aggiornata}.
@throws ValueError Se la password non rispetta IIN-5 o l'account non esiste.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `richiede_cambio_password()`
! @brief Indica se l'account deve cambiare la password al primo accesso (IIN-12).

Legge il flag `password_temporanea` dell'account (impostato da @ref provisiona_operatore
/ @ref provisiona_amministrazione per OP/PA, azzerato da @ref cambia_password): finchÃ© Ã¨
attivo l'accesso alla dashboard Ã¨ in stato di primo accesso forzato.

@param id_account Id dell'account autenticato.
@return True se Ã¨ richiesto il cambio password obbligatorio, False altrimenti.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `registra_dispositivo()`
! @brief Registra un dispositivo attivo applicando il limite di 3 (IIN-14).

Delega all'Integration Tier (@ref DataAccessManager.registra_dispositivo) il vincolo
transazionale: il Business Tier media l'accesso ai dati per il gateway di sicurezza,
che non tocca mai direttamente l'Integration Tier (Â§4).

@param id_utente Id dell'utente (= id_account) che accede.
@param device_id Identificativo stabile del dispositivo.
@return Id del documento dispositivo registrato.
@throws LimiteDispositivi Se l'utente ha giÃ  3 dispositivi attivi (IIN-14).
@throws NotImplementedError Se la persistenza non e' configurata.

#### `rimuovi_dispositivo()`
! @brief Libera lo slot di un dispositivo al logout (IIN-14).
@param id_utente Id dell'utente (= id_account).
@param device_id Identificativo del dispositivo da disattivare.
@return True se uno slot Ã¨ stato liberato, False se non c'era nulla da liberare.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `richiedi_reset()`
! @brief Avvia il reset della password via email registrata (UT.24/AP.12, IIN-11).

Per non rivelare l'esistenza di un account (anti-enumerazione), restituisce sempre
un esito positivo. Se l'account esiste, genera un codice monouso a validitÃ  limitata
(@ref RESET_TTL_MINUTI). Non essendo cablato un gateway email (Â§3, simulazione locale),
il codice Ã¨ restituito nel campo `codice_simulato` solo in questa modalitÃ  di sviluppo:
in produzione sarebbe recapitato fuori banda all'indirizzo registrato.

@param identita Email/username dichiarato dall'utente.
@return Esito {inviato: True, scadenza_minuti, codice_simulato?}.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `conferma_reset()`
! @brief Conferma il reset password con codice monouso e imposta la nuova (IIN-11).

Verifica il token emesso da @ref richiedi_reset: deve esistere, non essere scaduto
(@ref RESET_TTL_MINUTI) e il codice deve combaciare con l'hash memorizzato. Al successo
aggiorna l'hash password (IIN-5), azzera il flag `password_temporanea` e consuma il
token (monouso). Mantiene la semantica anti-enumerazione: un esito negativo non rivela
se a fallire e' l'identita', il codice o la scadenza. Se `nuova_password` Ã¨ omessa,
viene generata una password casuale temporanea.

@param identita Email/username dichiarato dall'utente (UT.24/AP.12).
@param codice Codice monouso ricevuto fuori banda.
@param nuova_password Nuova password in chiaro (validata IIN-5). Opzionale.
@return Esito {reimpostata: bool, requires_password_change: bool, id_account, ruolo}.
@throws ValueError Se la nuova password non rispetta la politica IIN-5.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `profilo()`
! @brief Vista profilo dell'utente autenticato, con dati riservati redatti (UT.21).

Compone i dati di account (esclusi i campi riservati: hash password, lockout) con
il documento di profilo a chiave condivisa (utenti/operatori/amministrazioni).

@param id_account Id dell'account autenticato.
@return Vista pubblica del profilo (mai contenente `password_hash`).
@throws NotImplementedError Se la persistenza non e' configurata.
@throws ValueError Se l'account non esiste.

#### `aggiorna_profilo()`
! @brief Aggiorna i dati anagrafici del profilo utente (UT.21).

Applica solo i campi della whitelist @ref CAMPI_PROFILO_MODIFICABILI sul documento
di profilo a chiave condivisa; ignora qualsiasi altro campo (no privilege escalation).

@param id_account Id dell'account autenticato.
@param modifiche Coppie campoâ†’valore proposte dal client.
@return Vista profilo aggiornata (@ref profilo).
@throws NotImplementedError Se la persistenza non e' configurata.
@throws ValueError Se l'account non esiste o nessun campo Ã¨ aggiornabile.

#### `elenca_account()`
! @brief Elenca gli account per la gestione operatore, campi riservati redatti (OP.10).

Vista gestionale (â‰  @ref profilo, che Ã¨ la self-view dell'utente): restituisce gli
account con stato_account e ruolo per consentire all'operatore sospensione/sblocco;
i campi segreti (@ref _CAMPI_ACCOUNT_RISERVATI) non sono mai esposti.

@param ruolo Filtro opzionale sul ruolo RBAC (UT/OP/PA); None = tutti.
@return Lista di account con campi non riservati (mai `password_hash`).
@throws NotImplementedError Se la persistenza non e' configurata.

#### `_nominativo()`
! @brief Ricava un'etichetta leggibile dell'account dal profilo a chiave condivisa.

Per UT/OP compone "Nome Cognome"; per PA usa l'ente. In assenza del profilo (o dei
campi) ripiega su username/email, cosÃ¬ la vista gestionale non resta mai senza
etichetta. I campi ðŸ”’ (nome/cognome) sono giÃ  decifrati da @ref DataAccessManager.leggi.

@param dao DataAccessManager connesso.
@param account Documento account (con `_id` e `ruolo`).
@return Etichetta leggibile del titolare dell'account.

#### `imposta_stato_account()`
! @brief Sospende o riattiva un account utente (OP.10 sospendi / OP.18 sblocca).

OP.10: sospendere inibisce l'accesso ai servizi di prenotazione/noleggio (il check Ã¨ in
@ref autentica). OP.18: riattivare ripristina l'accesso. Lo stato "eliminato" non Ã¨
impostabile da qui (lifecycle/retention separato, IIN-17).

@param id_account Id dell'account su cui agire.
@param stato Nuovo stato: "attivo" oppure "sospeso".
@return Vista account aggiornata (campi riservati redatti).
@throws ValueError Se lo stato non e' gestibile o l'account non esiste.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `provisiona_amministrazione()`
! @brief Crea un account Amministrazione Pubblica con password temporanea (OP.17/IIN-12).

L'operatore provisiona l'accesso PA (no registrazione pubblica): genera una password
temporanea robusta (IIN-5), ne salva solo l'hash, marca l'account `password_temporanea`
(cambio obbligatorio al primo accesso, IIN-12) e abilita l'MFA (IIN-9, giÃ  imposto da
@ref DataAccessManager.crea_account per ruolo PA). Email/username univoci (registri Â§6.4).

@param email Email di accesso istituzionale univoca (IIN-1).
@param username Username univoco dell'account PA.
@param ente Nome dell'ente di Amministrazione Pubblica.
@param email_istituzionale Email istituzionale per il reset credenziali (AP.12).
@return {id_account, password_temporanea} â€” la password va mostrata una sola volta.
@throws NotImplementedError Se la persistenza non e' configurata.
@throws ViolazioneUnicita Se email o username sono gia' registrati.

#### `provisiona_operatore()`
! @brief Crea un account Operatore con password temporanea (OP.17/IIN-12).

Simmetrico a @ref provisiona_amministrazione: genera una password temporanea
robusta (IIN-5), ne salva solo l'hash, marca l'account `password_temporanea`
(cambio obbligatorio al primo accesso, IIN-12) e abilita l'MFA (IIN-9).
Email/username univoci (registri Â§6.4): un duplicato solleva @c ViolazioneUnicita.

@param email Email di accesso univoca (IIN-1).
@param username Username univoco dell'operatore.
@param nome Nome completo dell'operatore (campo del profilo).
@return {id_account, email, nome, password_temporanea}.
@throws NotImplementedError Se la persistenza non e' configurata.
@throws ViolazioneUnicita Se email o username sono gia' registrati.

#### `registra_metodo_pagamento()`
! @brief Registra un metodo di pagamento verificato nel profilo (UT.11, punto 4).

Tokenizza la carta tramite il gateway pagamenti (simulazione locale Â§13): il PAN
in chiaro NON Ã¨ mai persistito (PCI) â€” si salva solo il PAN mascherato e un token
provider ðŸ”’ (cifrato at-rest, IIN-4) nella subcollezione `metodi_pagamento`. Il
**CVV (codice di sicurezza a 3 cifre)** Ã¨ verificato ma **mai persistito** (PCI). L'
**indirizzo di fatturazione** Ã¨ obbligatorio e deve **coincidere con la residenza**
del profilo (punto 4/5): se differisce la registrazione Ã¨ rifiutata.

@param id_utente Id dell'utente proprietario.
@param numero Numero della carta (solo le ultime 4 cifre vengono conservate).
@param mese Mese di scadenza (1-12).
@param anno Anno di scadenza.
@param titolare Intestatario della carta (campo ðŸ”’).
@param cvv Codice di sicurezza a 3 cifre (verificato, mai persistito â€” PCI).
@param indirizzo_fatturazione Via di fatturazione; deve coincidere con la residenza.
@return {id_metodo, pan_mascherato}.
@throws ValueError Se la carta, il CVV o l'indirizzo di fatturazione non sono validi.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `_abbonamento_attivo()`
! @brief Restituisce l'abbonamento attivo (non scaduto) dell'utente, o None (punto 8).
@param dao DataAccessManager connesso.
@param id_utente Id dell'utente.
@return L'abbonamento attivo non scaduto, oppure None se non presente.

#### `sottoscrivi_abbonamento()`
! @brief Sottoscrive un piano di abbonamento periodico (UT.18).

Punto 8: e' ammesso **un solo abbonamento attivo alla volta** â€” se ne esiste gia'
uno non scaduto la sottoscrizione e' rifiutata. Punto 7: l'abbonamento include un
bucket di token (consumati dalle corse al posto dell'addebito monetario).

@param id_utente Id dell'utente sottoscrittore.
@param id_piano Id del piano (deve esistere in `piani_abbonamento`).
@return {id_abbonamento, id_piano, data_fine, token_residui}.
@throws ValueError Se il piano non esiste.
@throws ErrorePersistenza Se l'utente ha gia' un abbonamento attivo (punto 8).
@throws NotImplementedError Se la persistenza non e' configurata.

#### `abbonamenti()`
! @brief Elenca gli abbonamenti dell'utente, dal piÃ¹ recente (UT.18/UT.21).
@param id_utente Id dell'utente di cui elencare gli abbonamenti.
@return Lista degli abbonamenti (documenti con id_piano, stato, date, prezzo).
@throws NotImplementedError Se la persistenza non e' configurata.

#### `registra_consenso()`
! @brief Registra un consenso GDPR esplicito nel profilo utente (IIN-16).

Mantiene l'ultimo stato per ciascun tipo di consenso in un campo `consensi` sul
documento di profilo (no nuova collezione, additivo). Sostituisce l'eventuale
consenso precedente dello stesso tipo, conservando timestamp e versione informativa.

@param id_utente Id dell'utente.
@param tipo Tipo di consenso (@ref TIPI_CONSENSO).
@param concesso True se concesso, False se revocato.
@param versione_privacy Versione dell'informativa accettata.
@return {tipo, concesso}.
@throws ValueError Se il tipo non Ã¨ ammesso o il profilo non esiste.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `carica_documento_kyc()`
! @brief Carica un documento KYC con validazione del formato (UT.22.2, IIN-6/AG-SEC-01).

Blocca server-side ogni estensione diversa da PDF/JPG/PNG (@ref formato_kyc_valido).
Il binario va su Cloud Storage (stub `storage_path` ðŸ”’); su Firestore si conserva solo
il riferimento e lo stato di verifica (in attesa di revisione operatore).

@param id_utente Id dell'utente proprietario.
@param tipo Tipo di documento (@ref TIPI_DOCUMENTO_KYC).
@param nome_file Nome del file caricato (estensione validata).
@return {id_documento, stato_verifica}.
@throws ValueError Se il tipo o il formato non sono ammessi.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `crea_notifica()`
! @brief Crea una notifica per un destinatario o in broadcast (UT.15/UT.19, IIN-19).
@param id_destinatario Id dell'account destinatario; None = broadcast a tutti.
@param tipo Categoria (es. "prenotazione"/"servizio").
@param titolo Titolo breve.
@param messaggio Corpo del messaggio.
@return Id della notifica creata.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `notifiche()`
! @brief Notifiche di un account piÃ¹ i broadcast, dalla piÃ¹ recente (UT.15/19, IIN-19).
@param id_account Id dell'account destinatario.
@param solo_non_lette Se True restituisce solo le notifiche non lette.
@return Elenco di notifiche ordinate per timestamp decrescente.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `segna_notifica_letta()`
! @brief Marca una notifica come letta (UT.15/UT.19).
@param id_notifica Id della notifica.
@return {id_notifica, letta}.
@throws NotImplementedError Se la persistenza non e' configurata.

## 8. `business_tier\motore_analitica\__init__.py`

### `class MotoreAnalitica`
! @brief Calcola metriche di mobilita' aggregate e anonime (AP.01/02/05/07, IIN-15).

Responsabilita': report periodici aggregati per tipo di mezzo, stima CO2 risparmiata.
Tutti i dati AP sono **aggregati e completamente anonimi** (nessun riferimento al
singolo cittadino, IIN-15 / AG-SEC-04): l'output non contiene mai id utente/mezzo.
Opera sui dati del @ref DataAccessManager (Integration Tier, tier adiacente §4).

@param dao DataAccessManager opzionale; se None risolto dall'ambiente
           (@ref ottieni_dao_opzionale).

#### `__init__()`
! @brief Costruisce il motore, opzionalmente con un DAO iniettato (test).
@param dao DataAccessManager da usare; se None risolto dall'ambiente.

#### `_dao_o_errore()`
! @brief Restituisce il DAO disponibile o segnala la persistenza in sviluppo.
@return DataAccessManager pronto.
@throws NotImplementedError Se la persistenza non e' configurata (slice "in sviluppo", §9).

#### `aggrega_uso()`
! @brief Aggrega le corse concluse per tipo di mezzo, in forma anonima (AP.02/AP.07).

Per ogni `tipo_mezzo` calcola numero corse, km totali, durata media e CO2
risparmiata stimata, senza alcun riferimento al singolo utente o mezzo (IIN-15).
Il filtro temporale è opzionale e si applica su `data_ora_inizio` (ISO-8601).

@param dalla_data Inizio intervallo incluso (ISO-8601), o None per nessun limite.
@param alla_data Fine intervallo incluso (ISO-8601), o None per nessun limite.
@return Lista di aggregati anonimi, uno per tipo di mezzo.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `_corse_concluse_periodo()`
! @brief Corse concluse nell'intervallo, base anonima dei report PA (IIN-15).

Filtra le corse con `stato == "conclusa"` su `data_ora_inizio` (ISO-8601). Helper
condiviso dai report granulari (noleggi/flussi/CO2) senza toccare @ref aggrega_uso.

@param dalla_data Inizio intervallo incluso (ISO-8601), o None per nessun limite.
@param alla_data Fine intervallo incluso (ISO-8601), o None per nessun limite.
@return Documenti delle corse concluse nell'intervallo.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `report_noleggi_per_tipo()`
! @brief Conteggio dei noleggi (corse concluse) per tipologia di mezzo (AP.01).

Quantifica il volume di utilizzo di ciascuna categoria di mezzo, in forma
aggregata e anonima (nessun id utente/mezzo, IIN-15).

@param dalla_data Inizio intervallo (ISO-8601) opzionale.
@param alla_data Fine intervallo (ISO-8601) opzionale.
@return Mappa `tipo_mezzo -> numero di corse concluse`.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `flussi_per_ora()`
! @brief Distribuzione dei noleggi per fascia oraria 0-23 (AP.02).

Individua le ore più attive per la pianificazione della viabilità, in forma
aggregata e anonima (IIN-15). L'ora è ricavata da `data_ora_inizio` (ISO-8601).

@param dalla_data Inizio intervallo (ISO-8601) opzionale.
@param alla_data Fine intervallo (ISO-8601) opzionale.
@return Mappa `ora (0-23) -> numero di corse avviate`.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `percentuale_operativi()`
! @brief Percentuale di mezzi operativi vs manutenzione vs scarico (AP.03).

Verifica il rispetto delle soglie minime di servizio. Legge lo `stato_operativo`
dei mezzi (valore della @ref StatoMezzo): operativi = disponibile/in uso/prenotato.

@return Mappa con percentuali `operativi`, `manutenzione`, `scarico`.
@throws NotImplementedError Se la persistenza non e' configurata.

#### `co2_risparmiata()`
! @brief Stima la CO2 risparmiata dai km della flotta elettrica (AP.07).

Quantifica l'impatto ecologico positivo confrontando i km percorsi a zero
emissioni con un'auto termica equivalente (@ref CO2_KG_PER_KM). Aggregato e
anonimo (IIN-15), con dettaglio per tipologia di mezzo.

@param dalla_data Inizio intervallo (ISO-8601) opzionale.
@param alla_data Fine intervallo (ISO-8601) opzionale.
@return `{km_totali, co2_risparmiata_kg, km_per_tipo}`.
@throws NotImplementedError Se la persistenza non e' configurata.

## 9. `console_operativa\client_controllo.py`

### `class ErroreControllo`
! @brief Errore di comunicazione o applicativo verso l'endpoint di controllo.

### `class ClientControllo`
! @brief Client sincrono verso gli endpoint di controllo loopback.

Usa httpx (strumento standard, HTTP/JSON) per dialogare col runtime. Essendo
un semplice client, piu' console possono interrogare lo stesso server in
concorrenza.

@param base_url URL base del runtime (es. http://127.0.0.1:8770).
@param admin_token Token admin opzionale per le interrogazioni riservate.
@param timeout Timeout delle richieste in secondi.

#### `__init__()`
! @brief Inizializza il client.
@param base_url URL base del runtime.
@param admin_token Token admin opzionale (header X-Admin-Token).
@param timeout Timeout richieste in secondi.

#### `_get()`
! @brief Esegue una GET sull'endpoint di controllo.
@param percorso Sotto-percorso (es. "/metriche").
@param params Parametri di query opzionali.
@return Corpo JSON della risposta.
@throws ErroreControllo In caso di errore di rete o status non 2xx.

#### `_post()`
! @brief Esegue una POST sull'endpoint di controllo.
@param percorso Sotto-percorso (es. "/op").
@param corpo Corpo JSON della richiesta.
@return Corpo JSON della risposta.
@throws ErroreControllo In caso di errore di rete o status non 2xx.

#### `_invia()`
! @brief Inoltra una richiesta HTTP e normalizza gli errori.
@param metodo Metodo HTTP.
@param percorso Sotto-percorso dell'endpoint.
@param params Parametri di query opzionali (GET).
@param corpo Corpo JSON opzionale (POST).
@return Corpo JSON della risposta.
@throws ErroreControllo Su errori di trasporto o status >= 400.

#### `raggiungibile()`
! @brief Verifica se il runtime risponde all'health check.
@return True se l'endpoint /salute risponde correttamente.

#### `metriche()`
! @brief Recupera le metriche di carico.
@return Snapshot delle metriche.

#### `hardware()`
! @brief Recupera lo sforzo hardware corrente.
@return Snapshot hardware con soglie.

#### `elenco_op()`
! @brief Elenca gli account OP provvisori.
@return Lista degli OP.

#### `crea_op()`
! @brief Crea un OP con password temporanea.
@param username Username da creare.
@return Esito con username e password temporanea.

#### `query()`
! @brief Esegue un'interrogazione amministrativa (solo admin).
@param sql Istruzione SQL.
@return Esito dell'interrogazione.

#### `backup_manuale()`
! @brief Avvia un backup manuale.
@return Metadati dell'archivio creato.

#### `elenco_backup()`
! @brief Elenca gli archivi di backup.
@return Archivi e stato del backup automatico.

#### `backup_auto()`
! @brief Attiva/disattiva il backup automatico.
@param attivo Stato desiderato.
@return Stato aggiornato del backup automatico.

#### `backup_restore()`
! @brief Ripristina i dati da un archivio.
@param nome Nome dell'archivio.
@return Metadati del ripristino.

#### `audit()`
! @brief Recupera le ultime voci di audit.
@param n Numero di voci.
@return Lista delle voci di audit.

#### `config()`
! @brief Recupera le impostazioni personalizzabili correnti.
@return Mappa delle impostazioni configurabili a caldo.

#### `aggiorna_config()`
! @brief Aggiorna a caldo una o piu' impostazioni personalizzabili.
@param modifiche Mappa parziale chiave -> nuovo valore.
@return Configurazione aggiornata.

## 10. `console_operativa\console.py`

### `class StatoTelemetria`
! @brief Stato condiviso delle metriche live mostrate nella barra in alto.

Aggiornato dal campionatore in un thread dedicato e letto dalla vista a ogni
ridisegno. I campi rispecchiano gli indicatori del design handoff.

#### `__init__()`
! @brief Inizializza lo stato a valori neutri (runtime non attivo).

### `class ConsoleOperativa`
! @brief Console interattiva a schermo intero per la gestione del runtime.

Riproduce il design handoff come TUI prompt_toolkit: barra telemetria fissa,
brand con mascotte e stato, box dei comandi e chat scrollabile con prompt.
Delega le operazioni al @ref Supervisore (start/stop) e al
@ref ClientControllo (metriche, hardware, OP, backup, query). Piu' istanze
possono girare in parallelo su terminali diversi.

#### `__init__()`
! @brief Inizializza console, client di controllo, vista e applicazione.

#### `_ripristina_cronologia()`
! @brief Ricarica in chat le ultime operazioni salvate su disco.

Soddisfa il requisito di conservazione: dopo una chiusura (anche
imprevista), all'avvio la console mostra le ultime attivita' eseguite.

@return Nessuno.

#### `_riga_operazione_storica()`
! @brief Rende una voce di cronologia integrata con l'estetica delle barre.

Le operazioni passate sono mostrate nello stesso flusso dei caricamenti
live, con una mini-barra completata colorata per esito (ok/errore).

@param voce Voce di cronologia (ts, comando, esito).
@return Frammenti formattati della riga.

#### `_crea_app()`
! @brief Assembla layout, stile e key binding dell'applicazione.
@return Istanza Application pronta per @ref esegui.

#### `_key_binding()`
! @brief Definisce uscita e scorrimento della chat.
@return Set di key binding dell'applicazione.

#### `_scorri()`
! @brief Aggiorna lo scorrimento della chat entro i limiti dello storico.
@param passi Righe da risalire (positivo) o scendere (negativo).
@return Nessuno.

#### `_prefisso_prompt()`
! @brief Prefisso del prompt: foglia 🍃 esistente + "leaf >".
@param numero_riga Indice di riga (ignorato, prompt monoriga).
@param conteggio_a_capo Conteggio di a-capo (ignorato).
@return Frammenti formattati del prefisso.

#### `_testo_chat()`
! @brief Costruisce il testo formattato dell'area chat (storico completo).
@return Frammenti delle righe accodate, separate da a-capo.

#### `_posizione_chat()`
! @brief Posizione "cursore" della chat: pilota lo scorrimento verticale.

Con scorrimento 0 punta all'ultima riga (la finestra resta ancorata in
basso e mostra le ultime operazioni); risalendo, segue lo storico.

@return Punto (colonna, riga) da mantenere visibile.

#### `_testo_telemetria()`
! @brief Barra telemetria snella sempre visibile (carico hardware live).

Tiene solo gli indicatori hardware in tempo reale (CPU/RAM/IO/NET) per
non andare a capo; i parametri del runtime (dispositivi, thread, uptime,
richieste...) vivono nel pannello "Stato runtime" sotto i riquadri.

@return Frammenti formattati della barra.

#### `_testo_stato_runtime()`
! @brief Pannello "Stato runtime" sotto i riquadri: parametri del runtime.

Raccoglie i parametri spostati dalla barra (dispositivi collegati, thread,
uptime) e altri indicatori standard utili letti dall'ultimo snapshot di
/metriche: richieste totali/errori, req/s, concorrenza, tempi di risposta,
traffico applicativo. Aggiornato dal campionatore ogni secondo.

@return Frammenti formattati del pannello (più righe).

#### `_gauge()`
! @brief Costruisce un gauge a blocchi (pieni/vuoti) come nel design.
@param pct Percentuale 0-100.
@param celle Numero di celle del gauge.
@return Frammenti formattati del gauge.

#### `_sparkline()`
! @brief Costruisce la sparkline della rete riscalando sul proprio massimo.
@param storia Campioni recenti (down+up).
@return Stringa di caratteri sparkline.

#### `_testo_stato()`
! @brief Riga di stato sotto la mascotte, aggiornata col runtime.
@return Frammenti formattati dello stato.

#### `_testo_wordmark()`
! @brief Wordmark "LEAF MOBILITY".
@return Frammenti formattati del wordmark.

#### `_testo_sottotitolo()`
! @brief Sottotitolo del brand con versione.
@return Frammenti formattati del sottotitolo.

#### `_testo_card()`
! @brief Server card: server, endpoint e stato (live).
@return Frammenti formattati della card.

#### `_testo_comandi()`
! @brief Contenuto del box "Comandi principali".
@return Frammenti formattati del box.

#### `_testo_suggerimenti()`
! @brief Contenuto del box "Suggerimenti".
@return Frammenti formattati del box.

#### `_aggiorna_ui()`
! @brief Esegue un'operazione sul thread della UI in modo sicuro.
@param operazione Callback da eseguire.
@return Nessuno.

#### `_scrivi()`
! @brief Accoda una riga formattata alla chat e ancora la vista al fondo.
@param frammenti Frammenti (classe_stile, testo) della riga.
@return Nessuno.

#### `_scrivi_testo()`
! @brief Accoda una riga di testo semplice con una classe di stile.
@param testo Contenuto della riga.
@param classe Classe di stile (es. "log.ok").
@return Nessuno.

#### `_eco()`
! @brief Riporta in chat il comando digitato (come nel prototipo).
@param riga Testo del comando.
@return Nessuno.

#### `_barra_caricamento()`
! @brief Mostra i passi di un'operazione, uno per riga, con percentuale.

Ogni sotto-passo intermedio resta **visibile** come riga a sé (marcatore
"▸ <passo>") con la barra e la percentuale di completamento cumulata: si
vede l'operazione in corso, l'avanzamento e — a cura del chiamante — il
messaggio finale "operazione avviata".

@param descrizione Etichetta generale dell'operazione (intestazione).
@param passi Sotto-passi; ognuno aggiunge una riga e avanza la percentuale.
@param durata_passo Pausa tra un passo e il successivo (secondi).
@return Nessuno.

#### `_svuota_rich()`
! @brief Travasa l'output rich accumulato nella chat (una riga per riga).
@return Nessuno.

#### `_invalida()`
! @brief Richiede un ridisegno dell'applicazione (thread-safe).
@return Nessuno.

#### `esegui()`
! @brief Avvia la TUI a schermo intero finche' l'utente non esce.
@return Nessuno.

#### `_ciclo_campionatore()`
! @brief Campiona ogni secondo metriche locali e stato/uptime del runtime.

CPU, RAM, I/O disco e rete sono lette localmente con psutil (sempre
disponibili); stato, thread e uptime provengono dal runtime quando attivo.
L'uptime e' quello del processo runtime: si azzera a ogni restart.

@return Nessuno.

#### `_accetta()`
! @brief Gestore Invio del prompt: interpreta o accoda il comando.

clear/exit sono gestiti sul thread della UI (azione immediata); gli altri
comandi vengono eseguiti in un thread dedicato per non bloccare la vista.

@param buff Buffer del prompt.
@return False per svuotare il prompt dopo l'invio.

#### `_pianifica_uscita()`
! @brief Richiede la chiusura della TUI in modo thread-safe.
@return Nessuno.

#### `_esegui_uscita()`
! @brief Arresta il runtime (se attivo) e poi chiude la console.

Soddisfa il requisito: digitando `exit` la console si assicura prima di
chiudere il server, evitando di lasciarlo orfano. Eseguito in un thread
dedicato per non bloccare la vista durante l'arresto.

@return Nessuno.

#### `_esegui_comando()`
! @brief Esegue un comando in background e travasa l'output in chat.
@param riga Testo del comando.
@return Nessuno.

#### `_dispatch()`
! @brief Interpreta ed esegue una riga di comando.
@param riga Testo immesso dall'utente.
@return Nessuno.

#### `_cmd_help()`
! @brief Mostra l'aiuto generale o di un singolo comando.
@param args Eventuale nome di comando di cui mostrare l'aiuto esteso.
@return Nessuno.

#### `_cmd_start()`
! @brief Avvia il runtime mostrando i passi di caricamento in chat.
@param args Ignorati.
@return Nessuno.

#### `_cmd_stop()`
! @brief Arresta il runtime.
@param args Ignorati.
@return Nessuno.

#### `_cmd_restart()`
! @brief Riavvia il runtime (azzera l'uptime mostrato in barra).
@param args Ignorati.
@return Nessuno.

#### `_cmd_status()`
! @brief Mostra lo stato sintetico del runtime.
@param args Ignorati.
@return Nessuno.

#### `_richiede_runtime()`
! @brief Verifica che il runtime sia attivo, altrimenti avvisa in chat.
@return True se attivo, False altrimenti (con messaggio).

#### `_cmd_monitor()`
! @brief Stampa uno snapshot delle metriche di carico in chat.
@param args Ignorati (le metriche live sono nella barra in alto).
@return Nessuno.

#### `_cmd_hw()`
! @brief Stampa uno snapshot dello sforzo hardware con barre colorate.
@param args Ignorati (i valori live sono nella barra in alto).
@return Nessuno.

#### `_cmd_op()`
! @brief Gestione account OP: create/list.
@param args Sottocomando ("create <username>" oppure "list").
@return Nessuno.

#### `_cmd_query()`
! @brief Esegue un'interrogazione amministrativa (solo admin).
@param args Token che compongono l'istruzione SQL.
@return Nessuno.

#### `_cmd_backup()`
! @brief Gestione backup: manuale, list, auto on|off, restore.
@param args Sottocomando opzionale.
@return Nessuno.

#### `_cmd_audit()`
! @brief Mostra le ultime voci del log di audit.
@param args Numero opzionale di voci.
@return Nessuno.

#### `_cmd_cronologia()`
! @brief Mostra le ultime operazioni eseguite dalla console (persistenti).
@param args Numero opzionale di voci (default 20).
@return Nessuno.

#### `_cmd_set()`
! @brief Mostra o modifica a caldo le impostazioni personalizzabili.
@param args "<chiave> <valore>" per modificare; vuoto per elencare.
@return Nessuno.

#### `_converti_valore()`
! @brief Converte il valore testuale di `set` nel tipo atteso.
@param tipo Tipo target ("bool", "int", "float").
@param grezzo Valore testuale immesso.
@return Valore convertito.
@throws ValueError Se la conversione fallisce.

#### `_mostra_config()`
! @brief Stampa le impostazioni personalizzabili correnti in tabella.
@param cfg Configurazione restituita dal runtime.
@return Nessuno.

#### `_cmd_selftest()`
! @brief Genera carico sintetico concorrente per esercitare i monitor.
@param args Numero di richieste opzionale (default 200).
@return Nessuno.

## 11. `console_operativa\cronologia.py`

### `class CronologiaConsole`
! @brief Registro persistente (JSON Lines) dei comandi eseguiti in console.

Salva su disco ogni operazione (comando + esito sintetico + timestamp) cosi'
che le ultime attivita' possano essere ripristinate al riavvio della console,
anche dopo una chiusura imprevista. E' indipendente dall'audit del runtime:
l'audit traccia le azioni lato server (IIN-13), questa traccia l'uso della
console e sopravvive anche a runtime spento.

@param percorso File di destinazione della cronologia (JSON Lines).
@param massimo Numero massimo di voci conservate (le piu' vecchie vengono potate).

#### `__init__()`
! @brief Inizializza la cronologia creando la cartella contenitore.
@param percorso Percorso del file di cronologia.
@param massimo Numero massimo di voci conservate.

#### `aggiungi()`
! @brief Aggiunge un'operazione alla cronologia e applica la potatura.
@param comando Riga di comando digitata dall'operatore.
@param esito Esito sintetico ("ok", "errore", "info").
@return Nessuno.

#### `ultime()`
! @brief Restituisce le ultime n operazioni registrate.
@param n Numero massimo di voci da restituire.
@return Lista di voci (ts, comando, esito) in ordine cronologico.

#### `_righe_grezze()`
! @brief Legge le righe non vuote del file di cronologia.
@return Lista delle righe grezze (vuota se il file non esiste).
@note Da invocare con il lock gia' acquisito.

## 12. `console_operativa\mascotte.py`

## 13. `console_operativa\supervisore.py`

### `class Supervisore`
! @brief Avvia e arresta il runtime come processo indipendente.

Lancia uvicorn in un processo separato che sopravvive alla console (cosi'
altre console possono agganciarsi) e lo arresta in modo controllato leggendo
il file PID scritto dal runtime. Garantisce che un solo runtime sia attivo.

@param impostazioni Configurazione del runtime (host/porta/worker).

#### `__init__()`
! @brief Inizializza il supervisore.
@param impostazioni Configurazione del runtime.

#### `_file_pid()`
! @brief Percorso del file PID del runtime.
@return Path di server.pid.

#### `in_esecuzione()`
! @brief Verifica se il runtime e' attivo e raggiungibile.
@return True se l'health check loopback risponde.

#### `avvia()`
! @brief Avvia il runtime se non gia' attivo.
@param attesa_s Secondi massimi di attesa che il server risponda.
@return True se al termine il runtime e' raggiungibile.
@throws RuntimeError Se il processo termina prematuramente.

#### `arresta()`
! @brief Arresta il runtime in modo controllato tramite il PID.
@param attesa_s Secondi massimi di attesa per la terminazione.
@return True se al termine il runtime non e' piu' attivo.

#### `avvia_tunnel()`
! @brief Constata lo stato del tunnel Cloudflare (servizio Windows).

A differenza del precedente tunnel in-process, cloudflared gira come
servizio Windows autonomo: il supervisore non lo avvia né lo arresta, ne
verifica solo lo stato (read-only) e restituisce l'URL pubblica del
Public Hostname instradato verso il runtime.
@return URL pubblica del tunnel (https://api.leafmobility.org).

#### `arresta_tunnel()`
! @brief Azzera lo stato locale del tunnel.

Non agisce sul servizio Windows cloudflared, che sopravvive all'arresto
del runtime (è infrastruttura di sistema indipendente).

#### `_servizio_cloudflared_attivo()`
! @brief Verifica (read-only) se cloudflared è in esecuzione.
@return True se un processo cloudflared risulta attivo sull'host.

#### `tunnel_attivo()`
! @brief Indica se il tunnel e' attivo.

#### `tunnel_url()`
! @brief URL pubblica del tunnel attivo.

## 14. `console_operativa\tema.py`

## 15. `console_operativa\__init__.py`

## 16. `console_operativa\__main__.py`

## 17. `integration_tier\__init__.py`

## 18. `integration_tier\data_access_manager\bootstrap_seed.py`

## 19. `integration_tier\data_access_manager\cifratura.py`

### `class CifrarioCampi`
! @brief Interfaccia di cifratura/decifratura simmetrica dei campi sensibili.

Implementata dalle strategie concrete usate dal @ref DataAccessManager per
proteggere i campi 🔒 (§10.4). Opera su stringhe: i valori non testuali vanno
serializzati a monte (es. JSON) dal chiamante.

#### `cifra()`
! @brief Cifra un valore testuale.
@param testo Valore in chiaro.
@return Token cifrato (testo, trasportabile in un documento Firestore).

#### `decifra()`
! @brief Decifra un valore prodotto da @ref cifra.
@param token Token cifrato.
@return Valore in chiaro originale.

### `class CifrarioNullo`
! @brief Strategia passthrough: non cifra (default in sviluppo/test).

Mantiene il contratto di @ref CifrarioCampi restituendo il valore invariato.
Usata finché la dipendenza `cryptography` non è approvata (§3) o contro
l'emulatore Firestore, dove la cifratura non è in prova.

#### `cifra()`
! @brief Restituisce il testo invariato (nessuna cifratura).
@param testo Valore in chiaro.
@return Lo stesso valore, non cifrato.

#### `decifra()`
! @brief Restituisce il token invariato (nessuna decifratura).
@param token Valore memorizzato.
@return Lo stesso valore, non decifrato.

### `class CifrarioAes256Gcm`
! @brief Cifratura AES-256-GCM dei campi 🔒 (IIN-4) basata su `cryptography`.

Ogni valore è cifrato con un nonce casuale a 96 bit; l'output è
base64(nonce ‖ ciphertext ‖ tag). GCM fornisce riservatezza e autenticità
(rilevamento di manomissioni). La chiave è a 256 bit (32 byte).

@param chiave Chiave AES-256 (esattamente 32 byte).
@throws ValueError Se la chiave non è di 32 byte.
@warning Richiede la dipendenza `cryptography` (in attesa di approvazione, §3):
         importata in modo pigro in @ref cifra/@ref decifra.

#### `__init__()`
! @brief Inizializza il cifrario con la chiave AES-256.
@param chiave Chiave simmetrica di 32 byte (256 bit).
@throws ValueError Se la chiave non è lunga 32 byte.

#### `da_base64()`
! @brief Costruisce il cifrario da una chiave codificata base64.
@param chiave_b64 Chiave AES-256 in base64 (es. dalla variabile d'ambiente).
@return Istanza di @ref CifrarioAes256Gcm.
@throws ValueError Se la chiave decodificata non è di 32 byte.

#### `_aesgcm()`
! @brief Importa pigramente `cryptography` e crea l'oggetto AESGCM.
@return Istanza di AESGCM legata alla chiave.
@throws RuntimeError Se la dipendenza `cryptography` non è installata (§3).

#### `cifra()`
! @brief Cifra un valore con AES-256-GCM e nonce casuale.
@param testo Valore in chiaro.
@return base64(nonce ‖ ciphertext ‖ tag).
@throws RuntimeError Se `cryptography` non è installata.

#### `decifra()`
! @brief Decifra un token prodotto da @ref cifra.
@param token base64(nonce ‖ ciphertext ‖ tag).
@return Valore in chiaro originale.
@throws RuntimeError Se `cryptography` non è installata.

## 20. `integration_tier\data_access_manager\cliente_falso.py`

### `class SnapshotFalso`
! @brief Istantanea di un documento (equivalente di DocumentSnapshot).
@param id_doc Identificativo del documento.
@param dati Contenuto del documento, o None se inesistente.

#### `__init__()`
! @brief Costruisce l'istantanea.
@param id_doc Identificativo del documento.
@param dati Contenuto (copia) o None se il documento non esiste.

#### `exists()`
! @brief Indica se il documento esiste.
@return True se il documento è presente.

#### `to_dict()`
! @brief Restituisce il contenuto del documento.
@return Copia del contenuto, o None se inesistente.

### `class _Documento`
! @brief Nodo di archiviazione: dati del documento + subcollezioni.

#### `__init__()`
! @brief Inizializza un nodo vuoto (nessun dato, nessuna subcollezione).

### `class CollezioneFalsa`
! @brief Collezione in-memory (equivalente di CollectionReference).

#### `__init__()`
! @brief Inizializza una collezione vuota.

#### `document()`
! @brief Riferimento a un documento (creandone l'id se assente).
@param id_doc Identificativo; se None viene generato un id casuale.
@return Riferimento al documento.

#### `_nodo()`
! @brief Recupera (o crea) il nodo di archiviazione di un documento.
@param id_doc Identificativo del documento.
@param crea Se True crea il nodo qualora assente.
@return Nodo del documento o None.

#### `where()`
! @brief Inizia una query filtrando per campo (API `filter=FieldFilter`).
@param campo Nome del campo (forma posizionale legacy).
@param operatore Operatore di confronto (==, >=, <=, >, <, in, array_contains).
@param valore Valore di confronto.
@param filter Filtro `FieldFilter` (API non deprecata di firebase-admin).
@return Query filtrata.

#### `order_by()`
! @brief Inizia una query ordinando per campo.
@param campo Campo di ordinamento.
@param direction "ASCENDING" o "DESCENDING".
@return Query ordinata.

#### `limit()`
! @brief Inizia una query limitando il numero di risultati.
@param numero Numero massimo di documenti.
@return Query limitata.

#### `stream()`
! @brief Itera su tutti i documenti della collezione.
@return Iteratore di istantanee dei documenti esistenti.

### `class DocumentRefFalso`
! @brief Riferimento a un documento (equivalente di DocumentReference).

#### `__init__()`
! @brief Costruisce il riferimento.
@param collezione Collezione contenitore.
@param id_doc Identificativo del documento.

#### `get()`
! @brief Legge l'istantanea del documento.
@param transaction Ignorato dal fake (compatibilità con il percorso reale).
@return Istantanea del documento.

#### `set()`
! @brief Scrive (o fonde) il contenuto del documento.
@param dati Contenuto da scrivere.
@param merge Se True fonde con il contenuto esistente, altrimenti lo sostituisce.
@return Nessuno.

#### `update()`
! @brief Aggiorna campi del documento (chiavi puntate = percorsi annidati).
@param dati Mappa campo→valore; le chiavi con punto indicano percorsi annidati.
@return Nessuno.
@throws KeyError Se il documento non esiste.

#### `delete()`
! @brief Elimina il documento (e le sue subcollezioni).
@return Nessuno.

#### `collection()`
! @brief Riferimento a una subcollezione del documento.
@param nome Nome della subcollezione.
@return Subcollezione (creata al volo se assente).

### `class QueryFalsa`
! @brief Query componibile su una collezione (where/order_by/limit/stream).

#### `__init__()`
! @brief Costruisce una query vuota sulla collezione.
@param collezione Collezione interrogata.

#### `where()`
! @brief Aggiunge un filtro alla query (API `filter=FieldFilter` o posizionale).
@param campo Campo filtrato (forma posizionale legacy).
@param operatore Operatore di confronto.
@param valore Valore di confronto.
@param filter Filtro `FieldFilter`: se presente, ne estrae campo/operatore/valore.
@return La query stessa (componibile).

#### `order_by()`
! @brief Imposta l'ordinamento della query.
@param campo Campo di ordinamento.
@param direction "ASCENDING" o "DESCENDING".
@return La query stessa (componibile).

#### `limit()`
! @brief Limita il numero di risultati.
@param numero Numero massimo di documenti restituiti.
@return La query stessa (componibile).

#### `stream()`
! @brief Esegue la query e itera i risultati.
@return Iteratore di istantanee filtrate, ordinate e limitate.

### `class TransazioneFalsa`
! @brief Transazione in-memory (equivalente minimale di Transaction).

Le scritture sono applicate immediatamente; la serializzazione tra transazioni
concorrenti è garantita dal lock del @ref ClienteFalsoFirestore acquisito dal
@ref DataAccessManager attorno all'intera operazione transazionale.

#### `set()`
! @brief Scrive un documento nel contesto della transazione.
@param ref Riferimento al documento.
@param dati Contenuto da scrivere.
@param merge Se True fonde con l'esistente.
@return Nessuno.

#### `update()`
! @brief Aggiorna un documento nel contesto della transazione.
@param ref Riferimento al documento.
@param dati Campi da aggiornare.
@return Nessuno.

#### `delete()`
! @brief Elimina un documento nel contesto della transazione.
@param ref Riferimento al documento.
@return Nessuno.

### `class ClienteFalsoFirestore`
! @brief Client Firestore in-memory per i test (equivalente di firestore.Client).

@note Espone @c _e_falso = True e @c _lock per il percorso transazionale del
      @ref DataAccessManager.

#### `__init__()`
! @brief Inizializza un archivio vuoto e il lock delle transazioni.

#### `collection()`
! @brief Riferimento a una collezione top-level.
@param nome Nome della collezione.
@return Collezione (creata al volo se assente).

#### `transaction()`
! @brief Crea una nuova transazione fittizia.
@return Istanza di @ref TransazioneFalsa.

## 21. `integration_tier\data_access_manager\cliente_firestore.py`

### `class ClienteFirestore`
! @brief Superficie minima del client Firestore usata dal DataAccessManager.

Soddisfatta sia dal client reale di `firebase-admin` sia dal
@ref ClienteFalsoFirestore dei test (duck typing).

#### `collection()`
! @brief Riferimento a una collezione top-level.
@param nome Nome della collezione.
@return Riferimento alla collezione.

#### `transaction()`
! @brief Crea una nuova transazione.
@return Oggetto transazione.

### `class _CredenzialeAnonima`
! @brief Credenziale firebase-admin che restituisce token anonimi (solo emulatore).

#### `get_credential()`
! @brief Restituisce la credenziale anonima di google-auth.
@return Istanza di `AnonymousCredentials`.

## 22. `integration_tier\data_access_manager\collezioni.py`

## 23. `integration_tier\data_access_manager\geo.py`

## 24. `integration_tier\data_access_manager\tipi.py`

### `class Ruolo`
! @brief Ruoli RBAC del sistema (IIN-5). `value` = codice persistito su Firestore.

### `class StatoAccount`
! @brief Stato di un account (OP.10/OP.18, IIN-17).

### `class TipoMezzo`
! @brief Tipologie di mezzo condiviso (UT.05). `value` = discriminante Firestore.

### `class StatoMezzo`
! @brief Stato operativo di un mezzo (OP.20). `value` = `stato_operativo` Firestore.

### `class StatoPrenotazione`
! @brief Ciclo di vita di una prenotazione (UT.02/UT.15, OP.12).

### `class StatoCorsa`
! @brief Ciclo di vita di una corsa (UT.10/UT.12/UT.04). `value` = `stato` Firestore.

### `class StatoTransazione`
! @brief Esito di una transazione di pagamento (UT.04/UT.11).

### `class StatoAbbonamento`
! @brief Stato di una sottoscrizione di abbonamento (UT.18/UT.21).

### `class TipoArea`
! @brief Tipologia di area di geofencing (AP.04/06/08, OP.04/09/15).

### `class StatoTicket`
! @brief Stato di un ticket di manutenzione (OP.03/06/16/19).

### `class StatoAssistenza`
! @brief Stato di una richiesta di assistenza utente (UT.09, OP.08).

### `class TipoConsenso`
! @brief Tipologia di consenso GDPR (IIN-16).

### `class TipoDocumento`
! @brief Tipo di documento ufficiale per il KYC (UT.22.2).

### `class StatoVerificaKyc`
! @brief Stato della verifica documentale KYC (UT.22.2).

### `class TipoTelemetria`
! @brief Tipo di evento telemetrico di un mezzo (OP.07/OP.14).

### `class TipoSoglia`
! @brief Tipo di soglia di allerta configurabile (OP.02/OP.22).

### `class ScopoOtp`
! @brief Scopo di un codice OTP (IIN-9).

### `class StatoSos`
! @brief Stato di una segnalazione di emergenza (UT.20, IIN-18).

### `class StatoManutenzione`
! @brief Stato di un intervento di manutenzione (OP.19).

### `class TipoNotifica`
! @brief Categoria di notifica push (IIN-19, UT.15/UT.19).

## 25. `integration_tier\data_access_manager\__init__.py`

### `class ErrorePersistenza`
! @brief Errore generico del layer di persistenza Firestore.

### `class ErroreIntegrita`
! @brief Violazione dell'integrità referenziale applicativa (reference inesistente).

### `class ViolazioneUnicita`
! @brief Violazione di una chiave univoca logica (email/username/codice, §6.4 / IIN-1).

### `class LimiteDispositivi`
! @brief Superato il limite di 3 dispositivi attivi per utente (IIN-14 / §6.1 #8).

### `class MezzoNonDisponibile`
! @brief Mezzo già prenotato/non disponibile: blocco esclusivo (UT.02 / §6.1 #24).

### `class ViolazioneXor`
! @brief Pagamento con XOR violato su id_corsa/id_abbonamento.

### `class DataAccessManager`
! @brief Unico punto di accesso alla base dati Cloud Firestore (§6/§13).

Responsabilita': persistenza di tutte le entita' dello schema logico, cifratura
AES-256 dei campi sensibili e dei log GPS (IIN-4 / AG-SEC-02), generalizzazione
Account a chiave condivisa, registri di unicità in transazione, integrita'
referenziale applicativa, vincoli (IIN-14, blocco esclusivo, XOR) e query
geospaziali (geohash + bounding-box). Nessun altro componente accede al DB.

@param cliente Client Firestore (reale firebase-admin o fake nei test); None lascia
               il manager non connesso (compatibilita' con lo scheletro storico).
@param cifrario Strategia di cifratura dei campi 🔒; default @ref CifrarioNullo
                (passthrough) finche' la chiave AES non e' configurata (IIN-4).

#### `__init__()`
! @brief Costruisce il manager legandolo a un client e a una strategia di cifratura.
@param cliente Client Firestore (reale o fake), o None.
@param cifrario Strategia di cifratura dei campi sensibili (default passthrough).

#### `connesso()`
! @brief Indica se la connessione al DB e' attiva.
@return True se un client Firestore e' stato iniettato.

#### `esegui_query()`
! @brief Non supportato su Firestore (document store schemaless, niente SQL).
@param sql Istruzione SQL (ignorata).
@param parametri Parametri di bind (ignorati).
@return Mai: solleva sempre.
@throws NotImplementedError Firestore non usa SQL; usare i metodi CRUD/query.

#### `_coll()`
! @brief Riferimento a una collezione top-level (con guardia di connessione).
@param nome Nome della collezione.
@return Riferimento di collezione Firestore.
@throws ErrorePersistenza Se il client non e' connesso.

#### `_client_o_errore()`
! @brief Restituisce il client connesso o solleva.
@return Client Firestore iniettato.
@throws ErrorePersistenza Se il client non e' connesso.

#### `_prepara_geo()`
! @brief Normalizza la posizione: lat/lon → `posizione` {lat,lon} + `geohash` (§6.7).

Accetta in ingresso lat/lon (o una `posizione` {lat,lon}); calcola il `geohash`
(in chiaro, grana di cella, campo di range-query per la prossimità) e materializza
`posizione`. Per le collezioni dove `posizione` è 🔒 (mezzi, §6.5) la serializza a
stringa JSON, così la cifratura AES-256 successiva la protegge come leaf testuale
(round-trip pulito); altrove resta una map leggibile.

@param collezione Collezione di destinazione.
@param dati Documento (modificato in-place): consuma lat/lon, imposta posizione/geohash.
@return Nessuno.

#### `_parse_geo()`
! @brief Ricostruisce `posizione` da stringa JSON a map dopo la decifratura.
@param collezione Collezione del documento letto.
@param dati Documento (modificato in-place).
@return Lo stesso documento con `posizione` come map {lat,lon}.

#### `_denormalizza_mezzo()`
! @brief Popola i campi 📎 copiati dal mezzo alla create (§6.6).

Per le collezioni che denormalizzano i dati del mezzo legge il mezzo referenziato
(`id_mezzo`) e copia `codice_identificativo` (e `tipo_mezzo` dove previsto).

@param collezione_o_sub Collezione o subcollezione ospite.
@param dati Documento (modificato in-place) con eventuale `id_mezzo`.
@return Nessuno.

#### `_verifica_riferimenti()`
! @brief Verifica che i reference id_X puntino a documenti esistenti (no FK del DBMS).
@param collezione Collezione del documento da scrivere.
@param dati Documento con eventuali campi reference.
@return Nessuno.
@throws ErroreIntegrita Se un reference valorizzato non esiste.

#### `_con_id()`
! @brief Converte un'istantanea in dizionario includendo l'id documento (_id).
@param snapshot Istantanea Firestore (DocumentSnapshot o fake).
@return Dizionario del documento con la chiave aggiuntiva "_id".

#### `crea()`
! @brief Crea un documento in una collezione top-level.
@param collezione Nome della collezione (deve essere prevista dallo schema §6.2).
@param dati Contenuto del documento (non modificato dall'esterno: ne usa una copia).
@param id_doc Id desiderato; se None Firestore ne genera uno.
@return Id del documento creato.
@throws ValueError Se la collezione non e' prevista dallo schema.
@throws ErroreIntegrita Se un reference valorizzato non esiste.

#### `leggi()`
! @brief Legge un documento per id, decifrando i campi 🔒.
@param collezione Nome della collezione.
@param id_doc Id del documento.
@return Documento (con "_id") o None se inesistente.

#### `aggiorna()`
! @brief Aggiorna campi di un documento (ricalcola il geohash se cambia lat/lon).
@param collezione Nome della collezione.
@param id_doc Id del documento.
@param modifiche Mappa campo→nuovo valore.
@return Nessuno.

#### `elimina()`
! @brief Elimina un documento per id.
@param collezione Nome della collezione.
@param id_doc Id del documento.
@return Nessuno.

#### `elenca()`
! @brief Interroga una collezione con filtri/ordinamento/limite.
@param collezione Nome della collezione.
@param filtri Lista di (campo, operatore, valore) (es. [("stato_operativo","==","x")]).
@param ordina Coppia (campo, direzione) con direzione "ASCENDING"/"DESCENDING".
@param limite Numero massimo di documenti.
@return Lista di documenti (ciascuno con "_id"), con i campi 🔒 decifrati.

#### `_ref_sub()`
! @brief Riferimento a una subcollezione di un documento padre.
@param collezione Collezione del padre.
@param id_padre Id del documento padre.
@param sub Nome della subcollezione.
@return Riferimento di subcollezione Firestore.
@throws ValueError Se la subcollezione non e' ammessa per il padre.

#### `crea_in_sub()`
! @brief Crea un documento in una subcollezione (es. utenti/{id}/metodi_pagamento).
@param collezione Collezione del padre (es. utenti).
@param id_padre Id del documento padre.
@param sub Nome della subcollezione (es. metodi_pagamento).
@param dati Contenuto del documento.
@param id_doc Id desiderato; se None ne viene generato uno.
@return Id del documento creato.

#### `leggi_sub()`
! @brief Legge un documento di una subcollezione, decifrando i campi 🔒.
@param collezione Collezione del padre.
@param id_padre Id del padre.
@param sub Nome della subcollezione.
@param id_doc Id del documento.
@return Documento (con "_id") o None se inesistente.

#### `elenca_sub()`
! @brief Elenca i documenti di una subcollezione, decifrando i campi 🔒.
@param collezione Collezione del padre.
@param id_padre Id del padre.
@param sub Nome della subcollezione.
@param filtri Lista di (campo, operatore, valore).
@return Lista di documenti (ciascuno con "_id").

#### `crea_account()`
! @brief Crea un Account (UT/OP/PA) e il profilo a chiave condivisa, in transazione.

Scrive in un'unica transazione (IIN-1): i registri di unicità `email_index`
(e `username_index` se `username` è dato), il documento `account` con i campi di
credenziali/lifecycle e il documento di profilo (`utenti`/`operatori`/
`amministrazioni_pubbliche`) con **document ID = id_account** (§6.1). I campi 🔒
del profilo (utenti: nome/cognome/…) sono cifrati prima della scrittura.

@param ruolo Ruolo RBAC: UT, OP o PA (discriminante §6.1).
@param email Email di accesso (univoca, §6.4 / IIN-1).
@param password_hash Hash Passlib della password (mai in chiaro).
@param profilo Campi della collezione di profilo (nome, cognome, ente, …).
@param username Username univoco opzionale (registro `username_index`).
@param extra Campi aggiuntivi di account (es. mfa_abilitato, lingua_preferita).
@param id_doc Id desiderato dell'account; se None ne viene generato uno.
@return Id dell'account creato (= id del profilo).
@throws ValueError Se il ruolo non e' ammesso.
@throws ViolazioneUnicita Se email o username sono gia' registrati.

#### `crea_mezzo()`
! @brief Crea un Mezzo (ebike/monopattino/ecar/emotorbike) e il registro codice.

Scrive in transazione (IIN-1) il mezzo (discriminante `tipo_mezzo` + map
`attributi_specifici`) e il registro di unicità `mezzo_index/{codice}` →
id_mezzo (§6.4). L'id documento è interno/auto (non enumerabile, ≠ codice §6.2)
se `id_doc` è None. Geo e cifratura della posizione/targa come da §6.5/§6.7.

@param tipo_mezzo Discriminante del tipo di mezzo (§3).
@param dati Campi comuni del mezzo (codice_identificativo, stato_operativo, lat/lon, …).
@param attributi Map dei campi specifici del sottotipo (targa, num_posti, …).
@param id_doc Id documento desiderato; se None ne viene generato uno (auto-ID interno).
@return Id del mezzo creato.
@throws ValueError Se il tipo di mezzo non e' ammesso.
@throws ViolazioneUnicita Se il codice_identificativo e' gia' usato.
@throws ErroreIntegrita Se un reference valorizzato non esiste.

#### `leggi_account_per_email()`
! @brief Recupera un Account dalla sua email via registro di unicità (§6.4).
@param email Email di accesso.
@return Account (con "_id") o None se inesistente.

#### `leggi_account_per_username()`
! @brief Recupera un Account dal suo username via registro di unicità (§6.4).
@param username Username di accesso.
@return Account (con "_id") o None se inesistente.

#### `leggi_profilo()`
! @brief Recupera il profilo a chiave condivisa di un account (§6.1).
@param account Documento account (con "ruolo" e "_id").
@return Documento di profilo (utenti/operatori/amministrazioni_pubbliche) o None.

#### `leggi_mezzo_per_codice()`
! @brief Recupera un Mezzo dal suo codice_identificativo via registro (§6.4).
@param codice Codice identificativo del mezzo (OP.14).
@return Mezzo (con "_id") o None se inesistente.

#### `verifica_credenziali()`
! @brief Verifica una password contro l'hash Passlib dell'account.
@param account Documento account (deve contenere "password_hash").
@param password Password in chiaro fornita dal client.
@return True se la password e' corretta e l'account e' attivo.

#### `account_bloccato()`
! @brief Indica se l'account e' attualmente bloccato per lockout (IIN-10).
@param account Documento account (con "bloccato_fino").
@return True se `bloccato_fino` e' un istante futuro.

#### `registra_accesso_riuscito()`
! @brief Azzera il contatore di lockout e registra l'ultimo accesso (IIN-10/IIN-17).
@param id_account Id dell'account.
@return Nessuno.

#### `registra_tentativo_fallito()`
! @brief Incrementa i tentativi falliti e blocca l'account oltre la soglia (IIN-10).
@param account Documento account (con "_id" e "tentativi_falliti").
@return Esito {tentativi_falliti, bloccato} dopo l'aggiornamento.

#### `memorizza_token_reset()`
! @brief Memorizza (o sostituisce) il token di reset password monouso (IIN-11).

Document ID = id_account: una nuova richiesta sovrascrive la precedente, così resta
valido solo l'ultimo codice emesso. Il codice arriva gia' hashato dal Business Tier
(mai in chiaro a riposo, IIN-4).

@param id_account Id dell'account proprietario del token.
@param codice_hash Hash Passlib del codice monouso.
@param scadenza_iso Istante di scadenza in ISO 8601 UTC (TTL di reset, IIN-11).
@return Nessuno.

#### `leggi_token_reset()`
! @brief Legge il token di reset password di un account (IIN-11).
@param id_account Id dell'account.
@return Documento token {codice_hash, scadenza, ...} o None se assente.

#### `elimina_token_reset()`
! @brief Elimina il token di reset (consumo monouso o invalidazione, IIN-11).
@param id_account Id dell'account.
@return Nessuno.

#### `mezzi_disponibili()`
! @brief Elenca i mezzi disponibili, opzionalmente nei pressi di un punto (UT.01/UT.05).

Legge da `mezzi` con filtro su `stato_operativo` (e tipo); se sono dati lat/lon
usa il `geohash` in chiaro per restringere i candidati (range-query di prossimità,
§6.7), poi raffina con la distanza esatta sulla `posizione` decifrata del solo set
ristretto e ordina per distanza crescente. La coordinata fine resta cifrata a riposo.

@param lat Latitudine del centro di ricerca (opzionale).
@param lon Longitudine del centro di ricerca (opzionale).
@param raggio_m Raggio di ricerca in metri (default 2000).
@param tipo Filtro opzionale per tipo di mezzo.
@return Lista di mezzi disponibili (ordinati per distanza se lat/lon presenti).

#### `aree_contenenti()`
! @brief Aree di geofencing attive che contengono un punto (point-in-polygon, §6.7).
@param lat Latitudine del punto.
@param lon Longitudine del punto.
@return Aree attive il cui poligono contiene il punto (AP.06/AP.08/OP.04).

#### `conta_mezzi_in_area()`
! @brief Conta i mezzi la cui posizione cade nel poligono di un'area (OP.02).

Usato dalla verifica delle soglie minime di mezzi per area: itera i mezzi,
decifra la `posizione` (§6.5/§6.7) e applica il point-in-polygon sulla
`geometria` dell'area. La posizione dei mezzi è già decifrata da @ref elenca.

@param area Documento area con `geometria` [{lat,lon}].
@return Numero di mezzi contenuti nell'area (0 se l'area non ha geometria).

#### `registra_dispositivo()`
! @brief Registra un dispositivo attivo applicando il limite di 3 (IIN-14 / §6.1 #8).

Transazione di compare-and-set sul contatore `dispositivi_attivi` del profilo utente:
se gia' a 3 rifiuta; altrimenti crea utenti/{id}/dispositivi/{device_id} e incrementa.

@param id_utente Id dell'utente (= id_account).
@param device_id Identificativo del dispositivo (usato come id documento).
@param ip Indirizzo IP del dispositivo (opzionale).
@param nome_dispositivo Nome leggibile del dispositivo (opzionale).
@return Id del documento dispositivo creato.
@throws ErroreIntegrita Se l'utente non esiste.
@throws LimiteDispositivi Se l'utente ha gia' 3 dispositivi attivi.

#### `rimuovi_dispositivo()`
! @brief Disattiva un dispositivo liberando uno slot del limite di 3 (IIN-14 / §6.1 #8).

Operazione inversa di @ref registra_dispositivo, invocata al logout: in transazione
marca il documento utenti/{id}/dispositivi/{device_id} come non attivo e decrementa il
contatore `dispositivi_attivi` del profilo (mai sotto zero). Idempotente: se il
dispositivo è assente o già inattivo non modifica nulla e restituisce False.

@param id_utente Id dell'utente (= id_account).
@param device_id Identificativo del dispositivo da disattivare.
@return True se uno slot è stato liberato, False se non c'era nulla da liberare.
@throws ErroreIntegrita Se l'utente non esiste.

#### `prenota_mezzo()`
! @brief Prenota un mezzo con blocco esclusivo in transazione (UT.02 / §6.1 #24).

Transazione: legge mezzi/{id}; se non `disponibile` rifiuta; altrimenti porta
`stato_operativo` a "prenotato" (il flag di stato è il lock: Firestore non blocca
range di query) e crea la prenotazione con i campi 📎 denormalizzati dal mezzo (§6.6).

@param id_utente Id dell'utente che prenota.
@param id_mezzo Id del mezzo da prenotare.
@param scadenza Scadenza della prenotazione in ISO 8601 (opzionale, UT.15).
@return Id della prenotazione creata.
@throws ErroreIntegrita Se il mezzo non esiste.
@throws MezzoNonDisponibile Se il mezzo non e' disponibile.

#### `elenca_prenotazioni_attive()`
! @brief Prenotazioni attive di un utente, dalla più recente (UT.02/UT.21).

Filtra le prenotazioni dell'utente con `stato` == "attiva" (esclude quelle
convertite in corsa o annullate) e le ordina per inizio decrescente. Il filtro di
stato e l'ordinamento sono applicati lato applicazione per non richiedere indici
compositi Firestore aggiuntivi.

@param id_utente Id dell'utente.
@param limite Numero massimo di prenotazioni restituite (default 50).
@return Lista delle prenotazioni attive (con campi 📎 denormalizzati dal mezzo).

#### `annulla_prenotazione()`
! @brief Annulla una prenotazione attiva e libera il mezzo (UT.12/OP.12).

Transazione: legge la prenotazione e il mezzo (tutte le letture prima delle
scritture, vincolo Firestore); se la prenotazione non è "attiva" rifiuta; se
`id_utente` è dato verifica la proprietà (un UT annulla solo le proprie); porta la
prenotazione a "annullata" e riporta il mezzo a "disponibile" se ancora "prenotato".

@param id_prenotazione Id della prenotazione da annullare.
@param id_utente Id dell'utente richiedente per il controllo di proprietà
                 (None = operatore OP.12, controllo saltato).
@return {id_prenotazione, id_mezzo, annullata: True}.
@throws ErroreIntegrita Se la prenotazione non esiste o non appartiene all'utente.
@throws MezzoNonDisponibile Se la prenotazione non è più attiva.

#### `avvia_corsa()`
! @brief Avvia una corsa sbloccando il mezzo in transazione (UT.10 / §6.1 #25).

Transazione: legge mezzi/{id}; ammette lo sblocco solo da `disponibile` o
`prenotato`; porta `stato_operativo` a "in_uso" e crea la corsa `in_corso` con i
campi 📎 denormalizzati dal mezzo. Se la corsa nasce da una prenotazione, questa
è marcata `convertita_in_corsa` (§6.1 #29). L'esistenza dell'utente è verificata
prima della transazione (integrità referenziale applicativa, §6.3).

@param id_utente Id dell'utente (= id_account) che avvia la corsa.
@param id_mezzo Id del mezzo da sbloccare.
@param id_prenotazione Id della prenotazione da convertire (opzionale).
@param costo_stimato_cent Stima preventiva del costo in centesimi (opzionale, UT.03).
@return Id della corsa creata.
@throws ErroreIntegrita Se l'utente o il mezzo non esistono.
@throws MezzoNonDisponibile Se il mezzo non e' sbloccabile.

#### `aggiorna_stato_corsa()`
! @brief Aggiorna lo stato di una corsa (es. pausa/ripresa, UT.12).
@param id_corsa Id della corsa.
@param stato Nuovo stato (in_corso | in_pausa | conclusa | interrotta).
@return Nessuno.

#### `termina_corsa()`
! @brief Conclude una corsa e libera il mezzo (UT.04 / OP.05).

Calcola la durata dall'inizio, registra km/costo finale, porta la corsa a
"conclusa" e riporta il mezzo a "disponibile". Compare-and-set su documenti
singoli (la corsa e il mezzo sono indipendenti: nessun blocco di range).

@param id_corsa Id della corsa da concludere.
@param km_percorsi Chilometri percorsi (IIN-24).
@param costo_finale_cent Importo finale in centesimi (se gia' calcolato a monte).
@return Documento della corsa conclusa (con durata e stato aggiornati).
@throws ErroreIntegrita Se la corsa non esiste.

#### `registra_pagamento()`
! @brief Registra un Pagamento applicando il vincolo XOR su corsa/abbonamento.

Per le causali "corsa"/"abbonamento" esattamente uno tra id_corsa e id_abbonamento
deve essere valorizzato (non entrambi, non nessuno).

@param dati Documento pagamento (tipo, importo_cent, id_utente, id_metodo, id_corsa?/…).
@return Id del pagamento creato.
@throws ViolazioneXor Se il vincolo XOR e' violato per le causali corsa/abbonamento.

## 26. `integration_tier\gateway_email\__init__.py`

### `class GatewayEmail`
! @brief Invio di email transazionali via SMTP (Gmail), Integration Tier (§13).

Black-box esterno: i client non accedono mai all'email, che è mediata
server-side dall'Integration Tier (vincolo tre tier §4). La configurazione è
letta dall'ambiente (`server/.env`): se mittente o app password mancano, il
gateway è **DISATTIVATO** e @ref invia è un no-op che ritorna False. Così lo
sviluppo/test resta offline e nessun invio reale avviene finché non si fornisce
la app password Gmail (segreto non versionato, come la chiave service account).

@note Usa la sola libreria standard (`smtplib`/`email`): nessuna nuova dipendenza.

#### `__init__()`
! @brief Costruisce il gateway leggendo la configurazione dall'ambiente.
@param host Host SMTP (default da @c LEAF_SMTP_HOST o "smtp.gmail.com").
@param porta Porta SMTP STARTTLS (default da @c LEAF_SMTP_PORT o 587).
@param mittente Indirizzo mittente / casella supporto (default @c LEAF_EMAIL_MITTENTE).
@param password App password SMTP (default da @c LEAF_EMAIL_APP_PASSWORD).

#### `mittente()`
! @brief Indirizzo mittente configurato (anche casella di supporto in entrata).
@return Indirizzo email del mittente (stringa vuota se non configurato).

#### `configurato()`
! @brief Indica se l'invio reale è abilitato (mittente e credenziale presenti).
@return True se mittente e app password sono valorizzati, False altrimenti.

#### `invia()`
! @brief Invia un'email di testo via SMTP STARTTLS (best-effort, UT.09).

Se il gateway non è configurato (mittente/app password assenti) o il
destinatario è vuoto non invia nulla e ritorna False (no-op sicuro). Gli
errori SMTP/rete sono assorbiti (ritorna False) per non interrompere il
flusso applicativo chiamante: l'invio email è accessorio rispetto
all'operazione di dominio (es. apertura ticket).

@param destinatario Indirizzo email del destinatario.
@param oggetto Oggetto del messaggio.
@param corpo Corpo testuale del messaggio.
@return True se l'email è stata inviata, False se saltata o fallita.

#### `invia_in_background()`
! @brief Recapita un'email best-effort senza bloccare il chiamante (invio asincrono).

L'invio SMTP reale (connessione + STARTTLS + login + send) costa ~1-3s e, se
eseguito in linea dentro un handler `async` (es. `/auth/login`), blocca l'event
loop e rallenta l'accesso. Per le email puramente accessorie (OTP, avvisi) si
delega l'invio a un thread daemon: la risposta torna subito e l'email parte in
parallelo. Gli errori sono già assorbiti da @ref invia (best-effort).

@note Thread daemon: non trattiene mai l'arresto del processo (riavvio pulito).
    Se il gateway non è configurato @ref invia è un no-op immediato (nessun thread utile),
    ma si delega comunque per uniformità del percorso.

@param destinatario Indirizzo email del destinatario.
@param oggetto Oggetto del messaggio.
@param corpo Corpo testuale del messaggio.
@return Nessuno (l'esito dell'invio è tracciato nei log del gateway).

## 27. `integration_tier\gateway_iot\__init__.py`

### `class GatewayIot`
! @brief Interfaccia bidirezionale coi veicoli fisici (UT.10, OP.07/11).

Responsabilita': invio comandi di sblocco/blocco motore, ricezione di
telemetria e tracciato GPS in tempo reale. L'hardware e' un black-box (§13).

@note **Simulazione locale deterministica** (§3): non essendo collegato hardware
      reale, i comandi sono simulati in modo deterministico (esito sempre positivo
      per un id mezzo valido); nessuna chiamata di rete. In produzione qui si
      dialogherebbe col provider IoT (MQTT/HTTP). La firma resta invariata per il
      cablaggio reale.

#### `invia_comando_sblocco()`
! @brief Invia il comando di sblocco a un mezzo (UT.10).
@param id_mezzo Identificativo del mezzo da sbloccare.
@return True (lo sblocco è sempre confermato nella simulazione locale).

#### `invia_comando_blocco()`
! @brief Invia il comando di blocco a un mezzo a fine corsa (UT.04).
@param id_mezzo Identificativo del mezzo da bloccare.
@return True (il blocco è sempre confermato nella simulazione locale).

#### `invia_comando_blocco_motore()`
! @brief Invia il blocco motore remoto anti-spostamento a un mezzo (OP.11).

Distinto dal blocco di fine corsa (@ref invia_comando_blocco): immobilizza un
mezzo privo di noleggi attivi rilevato in un'area non autorizzata. Simulazione
locale deterministica (§13): in produzione qui andrebbe il comando IoT reale.

@param id_mezzo Identificativo del mezzo da immobilizzare.
@return True (il blocco motore è sempre confermato nella simulazione locale).

#### `invia_comando_sblocco_motore()`
! @brief Revoca il blocco motore remoto e riabilita il mezzo (OP.11).

Operazione inversa di @ref invia_comando_blocco_motore: ripristina la
movimentazione di un mezzo precedentemente immobilizzato. Simulazione locale
deterministica (§13): in produzione qui andrebbe il comando IoT reale.

@param id_mezzo Identificativo del mezzo da riabilitare.
@return True (lo sblocco è sempre confermato nella simulazione locale).

## 28. `integration_tier\gateway_pagamenti\__init__.py`

### `class GatewayPagamenti`
! @brief Interfaccia il sistema di pagamento esterno (UT.04/UT.11).

Responsabilita': validazione carta, autorizzazione e addebito a fine
noleggio. Il provider e' un black-box (§13): si dialoga solo via SDK/API standard.

@note **Simulazione locale deterministica** (§3): senza credenziali del provider,
      l'autorizzazione è sempre concessa per un importo positivo e l'id transazione
      è derivato in modo deterministico dal riferimento (idempotenza per corsa);
      nessuna chiamata di rete. In produzione qui si chiamerebbe l'API del PSP.

#### `addebita()`
! @brief Addebita un importo all'utente a fine noleggio (UT.04).
@param id_utente Identificativo dell'utente con metodo di pagamento verificato.
@param importo_cent Importo in centesimi da addebitare (> 0).
@param riferimento Riferimento idempotente dell'addebito (es. id_corsa).
@return Identificativo deterministico della transazione simulata.
@throws ValueError Se l'importo non e' positivo (autorizzazione negata).

#### `_luhn_valido()`
! @brief Verifica il checksum di Luhn di un numero di carta (PAN).
@param cifre Numero della carta come sole cifre.
@return True se il checksum di Luhn e' valido.

#### `valida_carta()`
! @brief Valida la carta lato server: lunghezza, checksum Luhn e scadenza (UT.11).

Controllo deterministico locale (§3, nessuna chiamata al PSP): blocca PAN non
plausibili (Luhn) e carte gia' scadute, prima della tokenizzazione del metodo.

@param numero Numero della carta (le cifre vengono estratte).
@param mese Mese di scadenza (1-12).
@param anno Anno di scadenza (4 cifre).
@throws ValueError Se numero, mese o scadenza non sono validi.

## 29. `integration_tier\gateway_routing\__init__.py`

### `class GatewayRouting`
! @brief Calcolo percorsi multimodali e interrogazione del ServizioMappa (UT.07/UT.08).

Responsabilita': opzioni di percorso ordinate per tempo, integrazione
informativa col Trasporto Pubblico Locale (sistemaTPL) e dati per le heatmap.

@warning Il sistemaTPL e' INTEGRATO nativamente qui: NON deve mai diventare un
         modulo separato (§3 / §4.1).
@note **Simulazione locale deterministica** (§3): in assenza di provider mappa
      esterno, distanza e tempi derivano da formule pure (emisenoverso + velocità
      medie costanti); nessuna chiamata di rete. La firma resta invariata per il
      cablaggio reale del provider.

#### `percorsi_multimodali()`
! @brief Calcola percorsi multimodali (sharing + TPL) verso la destinazione (UT.07).
@param origine Coordinate (lat, lon) di partenza.
@param destinazione Coordinate (lat, lon) di arrivo.
@return Elenco di percorsi (modalità/distanza/durata) ordinati per tempo crescente.

#### `geocodifica()`
! @brief Risolve un nome di luogo in coordinate sul gazetteer locale (UT.07).

Strategia deterministica: corrispondenza esatta normalizzata, poi per
sottostringa (la query è contenuta in un nome canonico o viceversa).

@param nome Nome del luogo digitato o selezionato dai suggerimenti.
@return Coordinate (lat, lon) del luogo, o None se non riconosciuto.

#### `suggerisci()`
! @brief Suggerimenti di luogo per l'autocompletamento della ricerca (UT.07).

@param query Testo parziale digitato dall'utente.
@param limite Numero massimo di suggerimenti restituiti (default 8).
@return Elenco di {nome, lat, lon} dei luoghi che contengono la query;
        lista vuota se la query è vuota.

## 30. `presentation_tier\api_pubblica.py`

### `class LoginRichiesta`
! @brief Credenziali di accesso di un client (UT/OP/PA), contratto del layer dio.

### `class MfaRichiesta`
! @brief Secondo fattore (OTP) per OP/PA (IIN-9), contratto del layer dio.

### `class RegistrazioneRichiesta`
! @brief Dati di registrazione di un nuovo utente UT (UT.22.1).

### `class ResetRichiesta`
! @brief Richiesta di reset password via email registrata (UT.24/AP.12, IIN-11).

### `class ResetConfermaRichiesta`
! @brief Conferma reset password con codice monouso e nuova password (IIN-11).

### `class PrimoAccessoRichiesta`
! @brief Cambio password obbligatorio al primo accesso AP/OP (IIN-12).

### `class ProfiloAggiornaRichiesta`
! @brief Aggiornamento dei dati anagrafici del profilo (UT.21).

### `class AreaRichiesta`
! @brief Creazione di un'area limitata (cantiere/interdizione/slow-zone, AP.04/06/08).

### `class AssistenzaApriRichiesta`
! @brief Apertura di una richiesta di assistenza da parte dell'utente (UT.09).

### `class AssistenzaRispostaRichiesta`
! @brief Presa in carico / risposta a un ticket di assistenza (OP.08).

### `class PrenotaRichiesta`
! @brief Prenotazione di un mezzo (UT.02).

### `class CorsaRichiesta`
! @brief Avvio di una corsa su un mezzo (UT.10).

### `class TerminaRichiesta`
! @brief Conclusione di una corsa (UT.04); coordinate GPS di chiusura opzionali (OP.05).

### `class StimaRichiesta`
! @brief Stima preventiva del costo di una corsa su un mezzo (UT.03).

### `class ValutazioneRichiesta`
! @brief Valutazione a stelle di una corsa conclusa (UT.16).

### `class MetodoPagamentoRichiesta`
! @brief Registrazione di un metodo di pagamento verificato (UT.11).

### `class AbbonamentoRichiesta`
! @brief Sottoscrizione di un piano di abbonamento periodico (UT.18).

### `class ConsensoRichiesta`
! @brief Registrazione di un consenso GDPR esplicito (IIN-16).

### `class KycRichiesta`
! @brief Caricamento di un documento KYC (UT.22.2, IIN-6).

### `class SosRichiesta`
! @brief Segnalazione di emergenza SOS con la posizione (UT.20, IIN-18).

### `class SosStatoRichiesta`
! @brief Aggiornamento stato di una segnalazione SOS (presa in carico/chiusura, OP.08).

### `class NotificaRichiesta`
! @brief Notifica broadcast di interruzione/avviso di servizio (UT.19, OP/PA).

### `class StatoAccountRichiesta`
! @brief Sospensione/sblocco manuale di un account utente (OP.10/OP.18).

### `class ProvisioningPaRichiesta`
! @brief Provisioning di un account Amministrazione Pubblica da parte dell'OP (OP.17).

### `class ManutenzioneRichiesta`
! @brief Apertura di un ticket di manutenzione su un mezzo guasto (OP.16/OP.19).

### `class AssegnaTecnicoRichiesta`
! @brief Assegnazione di un ticket di manutenzione a un tecnico (OP.16).

### `class SogliaAreaRichiesta`
! @brief Soglia minima di mezzi per un'area con alert (OP.02).

### `class SogliaBatteriaRichiesta`
! @brief Soglia di allerta batteria, opzionalmente per tipologia (OP.22).

### `class PromozioneRichiesta`
! @brief Configurazione di una promozione/incentivo geografico (OP.09/OP.15).

### `class EventoRichiesta`
! @brief Inserimento di un grande evento cittadino su mappa (AP.09/AP.04).

## 31. `presentation_tier\__init__.py`

## 32. `presentation_tier\api_gateway_sicurezza\__init__.py`

### `class ApiGatewaySicurezza`
! @brief Punto di ingresso sicuro delle richieste client.

Responsabilita': terminazione delle richieste HTTP, autenticazione,
enforcement MFA per OP/AP (IIN-9), RBAC (IIN-5), account lockout (IIN-10),
audit logging degli accessi (IIN-13). Instrada verso il Business Tier
(@ref GestoreProfiliEkyc); NON accede direttamente all'Integration Tier (§4.1).

@note Il secondo fattore (OTP) è una **simulazione locale deterministica** (§3):
      non esiste un gateway SMS/email cablato, quindi l'OTP generato viene
      restituito nel campo `otp_simulato` della risposta di login — solo in questa
      modalità di sviluppo — e in produzione sarebbe recapitato fuori banda.

#### `__init__()`
! @brief Costruisce il gateway e gli store in-memory delle sessioni (MFA + token).

#### `_emetti_token()`
! @brief Emette e memorizza un token di sessione opaco (Bearer).
@param id_account Id dell'account autenticato.
@param ruolo Ruolo RBAC associato alla sessione.
@param device_id Dispositivo registrato all'accesso (IIN-14), da liberare al logout.
@return Token di sessione (opaco, da usare come Bearer).

#### `risolvi_sessione()`
! @brief Risolve un token di sessione nell'identità autenticata (RBAC).
@param token Token opaco fornito nell'header Authorization (Bearer).
@return {id_account, ruolo} se il token è valido e non scaduto, altrimenti None.

#### `revoca_sessione()`
! @brief Invalida un token di sessione attivo e libera il dispositivo (logout, IIN-14).

Oltre a rimuovere il token, se la sessione era legata a un dispositivo registrato al
login (UT) ne libera lo slot (@ref GestoreProfiliEkyc.rimuovi_dispositivo) così che un
nuovo accesso da un altro dispositivo rientri nel limite di 3. La liberazione è
best-effort: un errore di persistenza non rende il logout meno idempotente.

@param token Token opaco da revocare.
@return True se una sessione è stata rimossa, False se il token era già assente.

#### `autentica()`
! @brief Autentica un soggetto (UT/OP/AP) con credenziali (IIN-1/IIN-5/IIN-10/IIN-14).

Per UT, se le credenziali sono valide, registra il dispositivo applicando il limite di
3 accessi simultanei (IIN-14) e poi emette il **token di sessione**: se il limite è
superato solleva @c LimiteDispositivi e nessun token viene emesso. Per OP/AP apre invece
una **sessione MFA** pendente con un OTP a 6 cifre (simulazione locale) e la restituisce
per il secondo passo (@ref verifica_mfa); il token sarà emesso solo dopo la verifica
dell'OTP.

@param email Email/username di accesso (IIN-1).
@param password Password in chiaro, verificata contro l'hash a DB.
@param dispositivo Identificativo stabile del dispositivo (UT, IIN-14); se assente ne
                   viene generato uno una tantum.
@return Esito con autenticazione, ruolo RBAC, token (UT) o sessione/OTP MFA (OP/AP).
@throws NotImplementedError Se la persistenza non e' configurata (slice "in sviluppo", §9).
@throws LimiteDispositivi Se l'utente ha già 3 dispositivi attivi (IIN-14).

#### `verifica_mfa()`
! @brief Verifica l'OTP MFA obbligatorio per OP/AP ed emette il token (IIN-9).

Consuma la sessione MFA (uso singolo): se è scaduta, inesistente o l'OTP non
combacia restituisce {valido: False}; in caso di successo invalida la sessione MFA,
emette il token di sessione autenticato e segnala se l'account deve cambiare la
password al primo accesso (IIN-12).

@param sessione Identificativo di sessione in attesa di secondo fattore.
@param otp One-Time Password fornito dall'utente.
@return {valido, token?, richiede_cambio_password?}: presenti solo a verifica riuscita.

## 33. `presentation_tier\gestore_attivita\__init__.py`

### `class GestoreAttivita`
! @brief Coordina i casi d'uso applicativi tra Presentation e Business Tier.

Responsabilita': ricezione delle azioni utente gia' autenticate
(ricerca mezzi UT.01/UT.05, prenotazione UT.02, avvio/termine corsa
UT.10/UT.04, dashboard OP/AP) e loro inoltro ai gestori di dominio del
Business Tier (@ref GestoreFlotta), restituendo risposte gia' formattate.

#### `__init__()`
! @brief Costruisce il coordinatore collegandolo ai gestori del Business Tier.

#### `instrada()`
! @brief Instrada un'azione applicativa al gestore di dominio competente.
@param azione Identificativo del caso d'uso (es. "ricerca_mezzi", "avvia_corsa").
@param payload Parametri dell'azione gia' validati e autorizzati.
@return Risposta del Business Tier serializzabile per il client.
@throws NotImplementedError Per le azioni non cablate o con persistenza in sviluppo.

## 34. `runtime\app_factory.py`

## 35. `runtime\audit_log.py`

### `class AuditLog`
! @brief Registro append-only, non riscritto, delle azioni della console.

Ogni azione operativa (start/stop, creazione OP, query, backup) viene scritta
come riga JSON con timestamp UTC, allineandosi al requisito di audit logging
non modificabile (IIN-13). Le scritture sono serializzate da un lock.

@param percorso File di destinazione del log (JSON Lines).

#### `__init__()`
! @brief Inizializza il log creando la cartella contenitore.
@param percorso Percorso del file di audit.

#### `registra()`
! @brief Aggiunge una voce immutabile al log di audit.
@param azione Nome dell'azione (es. "op_create", "server_stop").
@param esito Esito sintetico (es. "ok", "errore").
@param dettagli Metadati aggiuntivi non sensibili (no PII in chiaro, §7.3).
@return Nessuno.

#### `ultime()`
! @brief Restituisce le ultime n voci di audit.
@param n Numero massimo di voci da restituire.
@return Lista delle voci piu' recenti (ordine cronologico).

## 36. `runtime\controllo_router.py`

### `class CreaOpRichiesta`
! @brief Corpo della richiesta di creazione di un account OP.

### `class QueryRichiesta`
! @brief Corpo di una interrogazione amministrativa.

### `class RestoreRichiesta`
! @brief Corpo della richiesta di ripristino da archivio.

### `class AutoBackupRichiesta`
! @brief Corpo del toggle del backup automatico.

### `class ConfigRichiesta`
! @brief Corpo dell'aggiornamento delle impostazioni personalizzabili a caldo.

## 37. `runtime\gestore_backup.py`

### `class GestoreBackup`
! @brief Gestisce backup manuali e automatici della cartella dati.

Crea archivi ZIP datati della cartella dati operativa (store OP, audit log,
eventuali snapshot), applica una politica di retention e consente il
ripristino. Il backup automatico e' guidato dal lifespan del runtime
(@ref server.runtime.app_factory) tramite @ref crea_archivio a intervalli.

@param dati_dir Cartella sorgente dei dati da archiviare.
@param backup_dir Cartella di destinazione degli archivi.
@param retention Numero massimo di archivi da conservare.

#### `__init__()`
! @brief Inizializza il gestore creando le cartelle necessarie.
@param dati_dir Cartella sorgente dei dati.
@param backup_dir Cartella di destinazione degli archivi.
@param retention Numero massimo di archivi conservati (>=1).

#### `crea_archivio()`
! @brief Crea un archivio ZIP dei dati correnti e applica la retention.
@param nota Etichetta dell'origine del backup (es. "manuale", "auto").
@return Metadati dell'archivio creato (nome, byte, file, timestamp).
@throws OSError In caso di errore di scrittura su disco.

#### `_applica_retention()`
! @brief Elimina gli archivi piu' vecchi oltre la soglia di retention.
@return Nessuno.

#### `elenco()`
! @brief Elenca gli archivi di backup disponibili.
@return Lista di archivi (nome, byte) ordinati dal piu' recente.

#### `ripristina()`
! @brief Ripristina i dati da un archivio esistente nella cartella dati.
@param nome_archivio Nome del file di archivio (es. "backup_20260620_101500.zip").
@return Metadati dell'operazione (archivio, file ripristinati).
@throws FileNotFoundError Se l'archivio non esiste.

## 38. `runtime\impostazioni.py`

### `class Impostazioni`
! @brief Parametri immutabili del runtime server.

@note Caricati una volta da .env / variabili d'ambiente tramite @ref carica().

#### `esposto_in_rete()`
! @brief Indica se il bind accetta connessioni da dispositivi esterni.
@return True se l'host non è il solo loopback (es. 0.0.0.0 o IP di LAN).

#### `base_url()`
! @brief URL base dell'endpoint di controllo, sempre via loopback.

Il controllo/health della console passa sempre per il loopback. Se il
bind è su un host jolly (`0.0.0.0`/`::`, usato per esporre la API pubblica
in LAN) NON ci si può connettere a quell'indirizzo come destinazione (su
Windows fallisce): va rimappato sull'indirizzo di loopback corrispondente,
altrimenti la console avvia il runtime ma non riesce a confermarlo
raggiungibile e lo dichiara erroneamente "non avviato".
@return URL nella forma http://host:porta verso il loopback.

#### `file_store_op()`
! @brief Percorso dello store provvisorio degli account OP.
@return Path del file JSON degli OP provvisori.

#### `file_audit()`
! @brief Percorso del log di audit append-only (IIN-13).
@return Path del file di audit (JSON Lines).

#### `file_config()`
! @brief Percorso del file delle impostazioni personalizzate (override a caldo).
@return Path di config.json nella cartella dati.

#### `file_cronologia_console()`
! @brief Percorso della cronologia persistente dei comandi di console.
@return Path del file di cronologia (JSON Lines) nella cartella dati.

#### `configurabili()`
! @brief Sottoinsieme delle impostazioni personalizzabili a caldo.
@return Mappa chiave -> valore corrente delle voci configurabili.

#### `salva_config()`
! @brief Persiste le impostazioni personalizzate in config.json.

Unisce le @p modifiche alla configurazione personalizzata gia' salvata e
riscrive config.json. Solo le chiavi in @ref CHIAVI_PERSONALIZZABILI sono
accettate; le altre vengono ignorate.

@param modifiche Mappa parziale chiave -> nuovo valore.
@return Configurazione personalizzata completa dopo l'aggiornamento.

#### `carica()`
! @brief Costruisce le impostazioni da .env, ambiente e config.json.

Precedenza: i default sicuri sono sovrascritti dalle variabili d'ambiente
(.env incluso) e, infine, dalle impostazioni personalizzate persistite in
config.json (scelte a caldo dall'operatore tramite il comando `set`).

@return Istanza di Impostazioni con i valori risolti (default sicuri).

## 39. `runtime\log_strutturato.py`

### `class FiltroContestoRichiesta`
! @brief Filtro che inietta IP client e request-id correnti in ogni record.

Garantisce che gli attributi `ip_client` e `request_id` siano sempre presenti
nel record (anche per i log esterni come quelli di uvicorn), così il formatter
non solleva mai un KeyError.

#### `filter()`
! @brief Aggiunge gli attributi di contesto al record.
@param record Record di log da arricchire.
@return Sempre True (il record non viene mai scartato).

## 40. `runtime\metriche_middleware.py`

### `class MiddlewareMetriche`
! @brief Middleware ASGI che misura byte, durata, concorrenza ed errori.

Avvolge receive/send per contare i byte effettivi del corpo di richiesta e
risposta e cronometrare il tempo di servizio, aggiornando il
@ref RegistroMetriche condiviso senza alterare la logica applicativa.

@param app Applicazione ASGI sottostante.
@param registro Registro metriche condiviso da aggiornare.
@param host_esclusi Host client da NON contare tra i dispositivi collegati (oltre al
    loopback, sempre escluso): tipicamente l'IP di bind del server, così la macchina
    che ospita il server non rientra mai nel conteggio dei dispositivi (IIN-14).

#### `__init__()`
! @brief Inizializza il middleware.
@param app Applicazione ASGI da avvolgere.
@param registro Registro metriche condiviso.
@param host_esclusi Host client esclusi dal conteggio dispositivi (uniti al loopback).

## 41. `runtime\middleware_log.py`

### `class MiddlewareLog`
! @brief Registra accessi ed errori HTTP con IP client, stato e durata.

@param app Applicazione ASGI sottostante.

#### `__init__()`
! @brief Inizializza il middleware di logging.
@param app Applicazione ASGI da avvolgere.

## 42. `runtime\middleware_sicurezza.py`

### `class LimitatoreRichieste`
! @brief Rate limiter a finestra fissa per host (thread-safe, in memoria).

Conta le richieste di ciascuna chiave (host del client) entro una finestra
temporale e nega quelle eccedenti. Un massimo <= 0 disabilita il limite.

@param massimo Numero massimo di richieste per finestra (<=0 => nessun limite).
@param finestra_s Ampiezza della finestra in secondi.

#### `__init__()`
! @brief Inizializza il limitatore.
@param massimo Numero massimo di richieste per finestra.
@param finestra_s Ampiezza della finestra in secondi.

#### `consenti()`
! @brief Verifica e contabilizza una richiesta della chiave indicata.
@param chiave Identificativo del chiamante (tipicamente l'host del client).
@return True se la richiesta è consentita, False se eccede il limite.

### `class MiddlewareSicurezza`
! @brief Aggiunge X-Request-ID e header di sicurezza a ogni risposta HTTP.

Genera (o propaga) un identificativo di correlazione per ogni richiesta e lo
rende disponibile nello scope ASGI (`scope["request_id"]`) e nell'header di
risposta `X-Request-ID`, utile per tracciare una richiesta end-to-end.

@param app Applicazione ASGI sottostante.

#### `__init__()`
! @brief Inizializza il middleware.
@param app Applicazione ASGI da avvolgere.

### `class MiddlewareRateLimit`
! @brief Applica un rate limit per host agli endpoint pubblici (`/api/v1`).

Le richieste eccedenti ricevono `429 Too Many Requests` con l'inviluppo
standard, senza raggiungere l'applicazione. Gli endpoint di controllo
loopback (`/__admin__`) e gli altri percorsi non sono limitati.

@param app Applicazione ASGI sottostante.
@param limitatore Rate limiter condiviso.
@param prefisso Prefisso dei percorsi soggetti a limite.

#### `__init__()`
! @brief Inizializza il middleware di rate limiting.
@param app Applicazione ASGI da avvolgere.
@param limitatore Rate limiter condiviso.
@param prefisso Prefisso dei percorsi pubblici da limitare.

## 43. `runtime\monitor_risorse.py`

### `class MonitorRisorse`
! @brief Campiona l'uso hardware del processo server e del sistema.

Si appoggia a psutil per CPU, memoria e contatori di I/O. Le misure di CPU
sono relative all'intervallo trascorso tra due chiamate a @ref istantanea
(la prima lettura, di innesco, vale 0).

@param pid PID del processo da monitorare; default = processo corrente.

#### `__init__()`
! @brief Inizializza il monitor e innesca le misure di CPU.
@param pid PID da monitorare; se None usa il processo corrente.

#### `istantanea()`
! @brief Restituisce una fotografia dello sforzo hardware corrente.
@return Dizionario con percentuali CPU, memoria (MB e %), I/O disco e rete.

## 44. `runtime\provisioning_op.py`

### `class ProvisioningOP`
! @brief Crea e cataloga account OP con password temporanea (OP.17, IIN-12).

Genera una password temporanea robusta (conforme a IIN-5), ne salva solo
l'hash in uno store JSON locale e marca l'account per cambio obbligatorio al
primo accesso (IIN-12). E' uno store PROVVISORIO che sostituisce il
DataAccessManager finche' il database e' in sviluppo: catalogato come
integration backlog (§17), non come debito tecnico.

@param percorso_store File JSON di persistenza degli account provvisori.
@param registro Registro metriche opzionale per contabilizzare l'I/O su store.

#### `__init__()`
! @brief Inizializza lo store creando la cartella contenitore.
@param percorso_store Percorso del file JSON degli OP provvisori.
@param registro Registro metriche opzionale (per @ref registra_io).

#### `genera_password_temporanea()`
! @brief Genera una password temporanea casuale conforme a IIN-5.
@param lunghezza Lunghezza totale (>= 8); garantisce maiuscola, cifra e speciale.
@return Password in chiaro (mostrata una sola volta all'operatore).

#### `_carica()`
! @brief Carica lo store dal file JSON.
@return Mappa username -> record account (vuota se il file non esiste).

#### `_salva()`
! @brief Persiste lo store sul file JSON.
@param dati Mappa completa degli account da scrivere.
@return Nessuno.

#### `esiste()`
! @brief Verifica l'esistenza di un account OP.
@param username Username da cercare.
@return True se l'account esiste gia'.

#### `crea_op()`
! @brief Crea un account OP con password temporanea.
@param username Username dell'operatore da creare (univoco).
@return Password temporanea in chiaro, da consegnare e mostrare una volta sola.
@throws ValueError Se l'username e' vuoto o gia' esistente.

#### `elenco()`
! @brief Elenca gli account OP provvisori (senza dati segreti).
@return Lista di record con username, stato e data di creazione (no hash).

## 45. `runtime\registro_metriche.py`

### `class RegistroMetriche`
! @brief Raccoglie in modo thread-safe le metriche di carico del server.

Traccia byte in/uscita, numero di richieste totali e concorrenti, dati
letti/scritti, errori e tempi di risposta (media e p95). E' condiviso tra
tutte le richieste concorrenti e tra le console connesse (lettura via
@ref snapshot).

@param max_campioni Numero massimo di tempi di risposta conservati per il p95.

#### `__init__()`
! @brief Inizializza il registro a zero.
@param max_campioni Dimensione della finestra scorrevole dei tempi di risposta.
@param finestra_dispositivi_s Secondi entro cui un client e' considerato "collegato".

#### `inizio_richiesta()`
! @brief Registra l'avvio di una richiesta (aggiorna concorrenza e totale).
@return Nessuno.

#### `fine_richiesta()`
! @brief Registra il completamento di una richiesta.
@param byte_in Byte ricevuti (corpo della richiesta).
@param byte_out Byte inviati (corpo della risposta).
@param durata_s Tempo di risposta in secondi.
@param errore True se la risposta e' un errore (status >= 400).
@return Nessuno.

#### `segna_dispositivo()`
! @brief Registra l'attivita' di un dispositivo client collegato.

Aggiorna l'istante di ultimo contatto del dispositivo (tipicamente l'host
del client) per il monitoraggio in tempo reale dei dispositivi collegati.

@param identificativo Chiave del dispositivo (es. host del client).
@return Nessuno.

#### `_dispositivi_collegati()`
! @brief Conta i dispositivi attivi entro la finestra ed elimina gli scaduti.
@param ora Istante monotonic corrente.
@return Numero di dispositivi collegati di recente.
@note Da invocare con il lock gia' acquisito.

#### `registra_io()`
! @brief Contabilizza dati applicativi letti/scritti (es. backup, store OP).
@param letti Byte letti da disco/store.
@param scritti Byte scritti su disco/store.
@return Nessuno.

#### `snapshot()`
! @brief Fotografia coerente delle metriche correnti.
@return Dizionario serializzabile con tutte le metriche di carico.

## 46. `runtime\servizi.py`

### `class ServiziRuntime`
! @brief Aggrega i servizi condivisi tra le richieste concorrenti.

Istanziato una sola volta per processo server e riferito da app.state, e'
l'unico stato condiviso dalle console connesse: i suoi componenti sono
thread-safe, cosi' piu' interfacce possono operare in concorrenza.

@param impostazioni Configurazione del runtime.

#### `__init__()`
! @brief Costruisce e collega i servizi condivisi.
@param impostazioni Configurazione del runtime.

#### `backup_retention()`
! @brief Retention corrente del backup (numero di archivi conservati).
@return Numero massimo di archivi conservati.

#### `aggiorna_config()`
! @brief Applica a caldo le impostazioni personalizzate e le persiste.

Aggiorna lo stato runtime (soglie, backup auto/intervallo/retention) e
scrive config.json cosi' che la scelta sopravviva al riavvio del runtime.

@param modifiche Mappa parziale chiave -> nuovo valore (chiavi configurabili).
@return Configurazione personalizzata completa dopo l'aggiornamento.

#### `configurazione()`
! @brief Istantanea delle impostazioni personalizzabili correnti.
@return Mappa chiave -> valore corrente (stato runtime, non i default immutabili).

## 47. `runtime\__init__.py`

## 48. `runtime\__main__.py`

