import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/auth_repository.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/session.dart';
import 'package:web_dashboard/theme.dart';
import 'package:web_dashboard/widgets/leaf_logo.dart';

/// @brief Schermata di recupero password per OP/PA (IIN-11/AP.12/UT.24).
///
/// Flusso a due fasi:
/// 1. Inserimento email → richiesta codice di reset al backend.
/// 2. Inserimento codice + nuova password → conferma reset, auto-accesso alla
///    home in base al ruolo e notifica SnackBar di cambiare password.
///
/// Il codice via email è monouso, valido 15 min (IIN-11). Il backend emette un
/// token di sessione al successo del conferma_reset (il codice email funge da
/// secondo fattore, bypassando l'OTP MFA, IIN-9).
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, AuthApi? auth}) : _auth = auth;

  /// Repository di autenticazione iniettabile (default reale; fittizio nei test).
  final AuthApi? _auth;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

/// Fase corrente del flusso di reset.
enum _FaseReset { email, codice }

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _codiceCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  late final AuthApi _auth = widget._auth ?? authRepository;

  _FaseReset _fase = _FaseReset.email;
  bool _caricamento = false;
  String? _errore;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codiceCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }



  /// Fase 1: richiedi il codice di reset (IIN-11).
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

  /// Fase 2: conferma il codice e auto-accesso (IIN-11/IIN-9).
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

  /// Imposta il ruolo e naviga alla home con notifica di cambiare password.
  /// @param ruolo Ruolo restituito dal backend ("OP"/"PA").
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

  /// Campi della fase 1: inserimento email.
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

  /// Campi della fase 2: solo codice OTP.
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

/// Indicatore di caricamento compatto per i pulsanti d'azione.
class _Spinner extends StatelessWidget {
  const _Spinner();
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 20,
    height: 20,
    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
  );
}

/// Sfondo decorativo della pagina di reset (stesso gradiente del login).
class _BrandBackground extends StatelessWidget {
  const _BrandBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceColor,
            AppTheme.backgroundBeige,
            AppTheme.surfaceColor,
          ],
        ),
      ),
    );
  }
}
