# Linee Guida per i Contributi

Grazie per il tuo interesse a contribuire a **Leaf Mobility**! Vogliamo rendere il processo di contribuzione il più semplice e trasparente possibile.

> **💡 Nota sullo Sviluppo e Prompt Engineering:**
> Questo ecosistema e gran parte del suo design sono stati realizzati tramite l'ausilio di Intelligenze Artificiali e tecniche avanzate di **Prompt Engineering**. Il codice è strutturato seguendo direttive specifiche per garantire un'alta manutenibilità, un'architettura a livelli pulita e l'isolamento dei dati sensibili. Quando contribuisci, cerca di mantenere l'aderenza a questo approccio architetturale logico e rigoroso.

## Come iniziare

1. **Forka il Repository**: Crea una copia personale sul tuo account GitHub.
2. **Clona in locale**:
   ```bash
   git clone https://github.com/<tuo-username>/Leaf_Mobility_OpenSource.git
   ```
3. **Crea un Branch per la tua modifica**:
   Usa un nome descrittivo (es. `feature/aggiungi-mappa`, `bugfix/crash-login`).
   ```bash
   git checkout -b feature/la-mia-feature
   ```

## Regole d'oro per le modifiche

- **Non versionare mai dati sensibili**: Assicurati di non committare file `.env`, chiavi JSON, o qualsiasi password.
- **Scrivi codice testabile**: Aggiungi test unitari per coprire le tue funzionalità (usa `pytest` per il server e `flutter test` per il client).
- **Verifica il tuo lavoro in locale**: Esegui la suite di test completa prima di aprire una PR.
- **Non modificare l'architettura base senza discussione**: Modifiche pesanti ai pattern architetturali (es. DataAccessManager, Dependency Injection) dovrebbero essere discusse preventivamente tramite una Issue.

## Segnalare Bug o Richiedere Funzionalità

Per segnalare problemi o richiedere nuove funzionalità, usa il sistema di **Issue** di GitHub, preferibilmente sfruttando i template che abbiamo messo a disposizione. Descrivi in modo chiaro i passaggi per riprodurre il problema.

## Apertura della Pull Request (PR)

- Assicurati che il tuo branch sia aggiornato con il branch `main` del repository ufficiale.
- Compila la descrizione della PR spiegando *cosa* hai fatto e *perché*.
- Dopo la sottomissione, la GitHub Action CI (Continuous Integration) verificherà automaticamente i tuoi test. Affinché la PR possa essere approvata, la CI deve passare con successo.
