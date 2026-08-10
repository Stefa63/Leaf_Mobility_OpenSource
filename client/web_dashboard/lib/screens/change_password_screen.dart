import 'package:flutter/material.dart';
import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/auth_repository.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/theme.dart';
import 'package:web_dashboard/widgets/leaf_logo.dart';

/// @brief Schermata di cambio password obbligatorio al primo accesso OP/PA (IIN-12).
///
/// Mostrata dopo login + MFA quando il backend segnala `richiede_cambio_password`.
/// Richiede una nuova password e la sua conferma, ne valida i requisiti IIN-5
/// (≥8 caratteri, almeno una maiuscola, una cifra e un carattere speciale) e chiama
/// l'endpoint autenticato `/auth/password/primo-accesso`. Al successo chiude tornando
/// `true` al chiamante (la login screen completa quindi l'ingresso nella console).
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, required AuthApi auth}) : _auth = auth;

  /// Repository di autenticazione (default reale; fittizio nei test).
  final AuthApi _auth;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _nuovaCtrl = TextEditingController();
  final _confermaCtrl = TextEditingController();

  bool _caricamento = false;
  String? _errore;

  @override
  void dispose() {
    _nuovaCtrl.dispose();
    _confermaCtrl.dispose();
    super.dispose();
  }

  /// Verifica i requisiti di robustezza IIN-5 (≥8, maiuscola, cifra, speciale).
  /// @param password Password da validare.
  /// @return True se la password rispetta la politica IIN-5.
  static bool _conformeIin5(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'\d')) &&
        password.contains(RegExp(r'[^A-Za-z0-9]'));
  }

  /// Valida i campi e invia il cambio password; chiude con `true` al successo.
  Future<void> _conferma() async {
    final nuova = _nuovaCtrl.text;
    final conferma = _confermaCtrl.text;
    if (!_conformeIin5(nuova)) {
      setState(
        () => _errore = tr(
          'La password deve avere almeno 8 caratteri, '
          'una maiuscola, un numero e un carattere speciale.',
        ),
      );
      return;
    }
    if (nuova != conferma) {
      setState(() => _errore = tr('Le due password non coincidono.'));
      return;
    }
    setState(() {
      _caricamento = true;
      _errore = null;
    });
    try {
      await widget._auth.cambiaPasswordPrimoAccesso(nuova);
      if (mounted) Navigator.pop(context, true);
    } on LeafApiException catch (e) {
      if (mounted) setState(() => _errore = e.messaggio);
    } finally {
      if (mounted) setState(() => _caricamento = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return Scaffold(
        body: Center(
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
                        tr('Primo accesso: cambia la password'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tr(
                          'Per motivi di sicurezza imposta una nuova password '
                          'al posto di quella temporanea.',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textGrey,
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (_errore != null) _bannerErrore(_errore!),
                      TextField(
                        controller: _nuovaCtrl,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: tr('Nuova password'),
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _confermaCtrl,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _conferma(),
                        decoration: InputDecoration(
                          labelText: tr('Conferma password'),
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _caricamento ? null : _conferma,
                        child: _caricamento
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(tr('Imposta password')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  /// Banner d'errore inline ad alto contrasto (IIN-2).
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
