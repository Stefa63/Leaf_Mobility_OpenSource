import 'package:flutter/material.dart';

import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/theme.dart';

/// @brief Indicatore di caricamento centrato con messaggio opzionale (IIN-2).
class VistaCaricamento extends StatelessWidget {
  /// @brief Crea l'indicatore di caricamento.
  /// @param messaggio Testo opzionale sotto lo spinner.
  const VistaCaricamento({super.key, this.messaggio});

  /// Messaggio mostrato sotto lo spinner, o null per il default localizzato.
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

/// @brief Stato di errore ad alto contrasto con pulsante "Riprova" (IIN-2).
class VistaErrore extends StatelessWidget {
  /// @brief Crea lo stato di errore.
  /// @param messaggio Messaggio di errore leggibile.
  /// @param onRiprova Callback del pulsante "Riprova" (null = pulsante assente).
  /// @param offline true per mostrare icona/copy di assenza connessione.
  const VistaErrore({
    super.key,
    required this.messaggio,
    this.onRiprova,
    this.offline = false,
  });

  /// Messaggio di errore mostrato all'utente.
  final String messaggio;

  /// Azione di ripristino; se null, il pulsante non viene mostrato.
  final VoidCallback? onRiprova;

  /// Indica un errore di connettività (cambia icona e titolo).
  final bool offline;

  /// @brief Costruisce lo stato di errore a partire da un'eccezione.
  /// @param errore Eccezione catturata (tipicamente [LeafApiException]).
  /// @param onRiprova Callback del pulsante "Riprova".
  /// @return Un [VistaErrore] con messaggio e modalità offline derivati.
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

/// @brief Stato "nessun dato" neutro con icona, titolo e sottotitolo (IIN-2).
class VistaVuota extends StatelessWidget {
  /// @brief Crea lo stato vuoto.
  /// @param titolo Titolo principale.
  /// @param sottotitolo Testo esplicativo opzionale.
  /// @param icona Icona mostrata in cima (default: contenitore vuoto).
  const VistaVuota({
    super.key,
    required this.titolo,
    this.sottotitolo,
    this.icona = Icons.inbox_outlined,
  });

  /// Titolo principale dello stato vuoto.
  final String titolo;

  /// Sottotitolo esplicativo opzionale.
  final String? sottotitolo;

  /// Icona mostrata sopra il titolo.
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

/// @brief Carica un [Future] e ne rende lo stato in modo uniforme.
///
/// Centralizza il ciclo caricamento→errore(retry)→vuoto→dati così che le
/// schermate cablate ai repository non duplichino la stessa logica.
///
/// @tparam T Tipo del dato prodotto dalla chiamata.
class CaricatoreVista<T> extends StatefulWidget {
  /// @brief Crea il caricatore di vista.
  /// @param carica Funzione che avvia la chiamata e ritorna il dato.
  /// @param costruisci Builder del contenuto in caso di esito positivo.
  /// @param vuotoSe Predicato che indica quando il dato è "vuoto" (opzionale).
  /// @param vistaVuota Widget mostrato quando [vuotoSe] è vero (opzionale).
  /// @param messaggioCaricamento Testo opzionale durante il caricamento.
  const CaricatoreVista({
    super.key,
    required this.carica,
    required this.costruisci,
    this.vuotoSe,
    this.vistaVuota,
    this.messaggioCaricamento,
  });

  /// Funzione asincrona che produce il dato da mostrare.
  final Future<T> Function() carica;

  /// Builder del contenuto in caso di successo.
  final Widget Function(BuildContext context, T dati) costruisci;

  /// Predicato di "vuoto" sul dato ottenuto; se null, mai vuoto.
  final bool Function(T dati)? vuotoSe;

  /// Vista da mostrare quando il dato è vuoto; se null, usa [costruisci].
  final Widget? vistaVuota;

  /// Messaggio opzionale durante il caricamento.
  final String? messaggioCaricamento;

  @override
  State<CaricatoreVista<T>> createState() => _CaricatoreVistaState<T>();
}

class _CaricatoreVistaState<T> extends State<CaricatoreVista<T>> {
  late Future<T> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = widget.carica();
  }

  /// @brief Riavvia la chiamata (pulsante "Riprova").
  void _ricarica() {
    setState(() => _futuro = widget.carica());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _futuro,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return VistaCaricamento(messaggio: widget.messaggioCaricamento);
        }
        if (snapshot.hasError) {
          return VistaErrore.da(snapshot.error!, onRiprova: _ricarica);
        }
        final dati = snapshot.data as T;
        if (widget.vuotoSe != null && widget.vuotoSe!(dati)) {
          return widget.vistaVuota ?? widget.costruisci(context, dati);
        }
        return widget.costruisci(context, dati);
      },
    );
  }
}
