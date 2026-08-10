import 'package:flutter/material.dart';
import 'package:app_mobile_utente/theme.dart';
import 'package:app_mobile_utente/l10n.dart';

/// @brief Coppia domanda/risposta delle FAQ (chiavi in italiano, tradotte a UI).
class _Faq {
  /// Chiave della domanda (lingua sorgente italiana, tradotta via [tr]).
  final String question;

  /// Chiave della risposta (lingua sorgente italiana, tradotta via [tr]).
  final String answer;

  const _Faq(this.question, this.answer);
}

/// Elenco delle domande più comuni. Le stringhe sono chiavi tradotte in [tr].
const List<_Faq> _kFaqs = [
  _Faq(
    'Come sblocco un mezzo?',
    'Inquadra il QR code del mezzo o usa il pulsante "Sblocca" nella scheda del veicolo.',
  ),
  _Faq(
    'Come prenoto un mezzo?',
    'Apri la sezione "Prenota", scegli un veicolo disponibile e conferma la durata della riserva.',
  ),
  _Faq(
    'Come annullo una prenotazione?',
    'Vai in "Mie Prenotazioni" dal menu e premi "Annulla prenotazione".',
  ),
  _Faq(
    'Come funziona la fatturazione?',
    'Il costo è calcolato al minuto in base alla tariffa del mezzo; ricevi un riepilogo a fine corsa.',
  ),
  _Faq(
    'Come metto in pausa una corsa?',
    'Durante la corsa attiva la "pausa corsa": il mezzo resta bloccato e riservato a te senza terminare il noleggio.',
  ),
  _Faq(
    'Come ottengo la fattura della corsa?',
    'Apri la corsa dalla cronologia e premi "Esporta fattura" per ottenere una copia digitale stampabile.',
  ),
  _Faq(
    'Come cambio la lingua dell\'app?',
    'Vai in "Impostazioni" dal menu laterale e scegli la lingua preferita nella sezione "Lingua".',
  ),
  _Faq(
    'Come funziona il tasto SOS?',
    'In caso di emergenza premi il tasto SOS: la tua posizione GPS viene inviata ai soccorsi entro 5 secondi.',
  ),
  _Faq(
    'Quali metodi di pagamento posso usare?',
    'Puoi registrare un metodo di pagamento verificato dal tuo profilo per l\'addebito automatico a fine noleggio.',
  ),
  _Faq(
    'Come recupero la password?',
    'Nella schermata di accesso premi "Password dimenticata?": riceverai un link di reset via email.',
  ),
];

/// @brief Schermata FAQ dedicata: barra di ricerca + domande più comuni. UT.09.
///
/// Filtra in tempo reale le domande e le risposte in base al testo digitato e
/// mostra l'elenco come pannelli espandibili. Si ritraduce live al cambio
/// lingua tramite [Translated]. IIN-7.
class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  /// Controller della barra di ricerca.
  final TextEditingController _searchController = TextEditingController();

  /// Testo di ricerca corrente (minuscolo) usato per filtrare le FAQ.
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// FAQ che soddisfano la ricerca corrente (su domanda e risposta tradotte).
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

  /// Stato vuoto mostrato quando la ricerca non produce risultati.
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

/// Pannello FAQ espandibile (domanda/risposta).
class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Colors.black12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: AppTheme.primaryGreen,
          collapsedIconColor: AppTheme.textGrey,
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
