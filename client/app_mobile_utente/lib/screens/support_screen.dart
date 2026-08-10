import 'package:flutter/material.dart';
import 'package:app_mobile_utente/theme.dart';
import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/screens/faq_screen.dart';
import 'package:app_mobile_utente/api/api_client.dart';
import 'package:app_mobile_utente/api/assistenza_repository.dart';
import 'package:app_mobile_utente/widgets/stato_vista.dart';

/// @brief Schermata di assistenza utente con invio feedback/segnalazioni. UT.09.
///
/// Raccoglie tre blocchi coerenti con l'estetica minimalista dell'app:
///   1. contatti diretti (email/telefono, mock in attesa del Business Tier);
///   2. domande frequenti (FAQ) come pannelli espandibili;
///   3. modulo di invio feedback/segnalazione con tipo richiesta, valutazione
///      a stelle e messaggio.
///
/// L'invio della segnalazione Ã¨ cablato al Business Tier: chiama
/// `POST /api/v1/assistenza` tramite [AssistenzaApi] con stati loading/errore
/// (riusa `stato_vista.dart`). Il repository Ã¨ iniettabile per i test.
class SupportScreen extends StatefulWidget {
  /// @brief Crea la schermata di assistenza.
  /// @param assistenza Repository di assistenza iniettabile (default reale).
  const SupportScreen({super.key, this.assistenza});

  /// Repository di assistenza usato per inviare la segnalazione (UT.09).
  /// Se null si usa l'istanza condivisa [assistenzaRepository]; fittizio nei test.
  final AssistenzaApi? assistenza;

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

/// Tipologia della richiesta inviata dall'utente.
enum _RequestType { feedback, report, suggestion }

class _SupportScreenState extends State<SupportScreen> {
  /// Tipo di richiesta attualmente selezionato.
  _RequestType _type = _RequestType.feedback;

  /// Valutazione a stelle (0â€“5) dell'esperienza.
  int _rating = 0;

  /// Controller del messaggio della segnalazione.
  final TextEditingController _messageController = TextEditingController();

  /// Stato dell'invio della segnalazione (loading/pronto), riusa [StatoCaricamento].
  StatoCaricamento _statoInvio = StatoCaricamento.pronto;

  /// Repository di assistenza effettivo (iniettabile nei test).
  AssistenzaApi get _assistenza => widget.assistenza ?? assistenzaRepository;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  /// Etichetta localizzata del tipo di richiesta.
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

  /// @brief Mostra uno snackbar coerente con l'estetica minimalista.
  /// @param testo Messaggio da mostrare.
  /// @param colore Colore di sfondo (verde = successo, marrone = avviso/errore).
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

  /// @brief Valida il messaggio e invia la segnalazione al Business Tier. UT.09.
  ///
  /// Costruisce oggetto (dal tipo richiesta) e messaggio (con eventuale
  /// valutazione a stelle) e chiama `POST /api/v1/assistenza`. Durante l'invio
  /// il pulsante mostra lo stato di caricamento; in caso di errore mostra il
  /// messaggio di dominio del backend ([LeafApiException]).
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

/// Etichetta di sezione in maiuscoletto, coerente con le altre schermate.
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AppTheme.textGrey,
      letterSpacing: 0.7,
    ),
  );
}

/// Riga di contatto diretto (telefono / email), mock in attesa del server.
class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryGreen.withAlpha(28),
            child: Icon(icon, color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
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

/// Riga di navigazione verso una sezione dedicata (es. FAQ).
class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryGreen.withAlpha(28),
                child: Icon(icon, color: AppTheme.primaryGreen),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textGrey),
            ],
          ),
        ),
      ),
    );
  }
}
