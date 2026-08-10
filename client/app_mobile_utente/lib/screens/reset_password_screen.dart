import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app_mobile_utente/theme.dart';
import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/api/api_client.dart';
import 'package:app_mobile_utente/api/auth_repository.dart';

/// @brief Schermata di recupero password per utenti UT (IIN-11/UT.24).
///
/// Flusso a due fasi:
/// 1. Inserimento email → richiesta codice di reset al backend.
/// 2. Inserimento codice ricevuto via email + nuova password → conferma reset
///    e ritorno alla schermata di login con notifica di successo.
///
/// Il codice via email è monouso, valido 15 min (IIN-11). La nuova password
/// viene salvata come password definitiva dell'account (non temporanea).
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
  bool _mostraPassword = false;

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
      setState(() => _errore = tr('Inserisci la tua email.'));
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
          content: Text(tr('Codice inviato! Controlla la tua email.')),
          duration: const Duration(seconds: 3),
          backgroundColor: AppTheme.accentBrown,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } on LeafApiException catch (e) {
      if (mounted) setState(() => _errore = e.messaggio);
    } finally {
      if (mounted) setState(() => _caricamento = false);
    }
  }

  /// Fase 2: conferma il codice con la nuova password (IIN-11).
  Future<void> _confermaReset() async {
    final codice = _codiceCtrl.text.trim();
    final nuovaPassword = _passwordCtrl.text;

    if (codice.length != 6) {
      setState(() => _errore = tr('Inserisci un codice a 6 cifre.'));
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
          final messenger = ScaffoldMessenger.of(context);
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(tr('Password reimpostata con successo! Accesso automatico effettuato.')),
                duration: const Duration(seconds: 4),
                backgroundColor: AppTheme.primaryGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          });
        case StatoAccesso.mfaRichiesta:
          // Codice errato o scaduto (il backend risponde reimpostata=false).
          setState(
            () => _errore = tr('Il codice non è valido o è scaduto.'),
          );
        case StatoAccesso.cambioPasswordRichiesto:
          // Non dovrebbe accadere dopo conferma_reset, ma gestiamo per sicurezza.
          Navigator.pop(context);
      }
    } on LeafApiException catch (e) {
      if (mounted) setState(() => _errore = e.messaggio);
    } finally {
      if (mounted) setState(() => _caricamento = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Recupero password')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.darkGreen,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SvgPicture.asset(
                  'assets/images/fulllogoSVG.svg',
                  width: 64,
                  height: 64,
                  placeholderBuilder: (_) => Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
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
                const SizedBox(height: 8),
                Text(
                  _fase == _FaseReset.email
                      ? tr('Inserisci la tua email per ricevere il codice di reset.')
                      : tr('Inserisci il codice ricevuto e scegli la nuova password.'),
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
    );
  }

  /// Banner d'errore inline ad alto contrasto (IIN-2).
  Widget _bannerErrore(String messaggio) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE57373)),
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

  /// Campi della fase 1: inserimento email.
  List<Widget> _campiEmail() {
    return [
      TextField(
        controller: _emailCtrl,
        enabled: !_caricamento,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _inviaRichiesta(),
        decoration: InputDecoration(
          labelText: tr('Email'),
          prefixIcon: const Icon(Icons.email),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: _caricamento ? null : _inviaRichiesta,
        child: _caricamento
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(tr('Invia codice')),
      ),
    ];
  }

  /// Campi della fase 2: codice + nuova password.
  List<Widget> _campiCodice() {
    return [
      TextField(
        controller: _codiceCtrl,
        enabled: !_caricamento,
        keyboardType: TextInputType.number,
        maxLength: 6,
        autofocus: true,
        textInputAction: TextInputAction.next,
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
        enabled: !_caricamento,
        obscureText: !_mostraPassword,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _confermaReset(),
        decoration: InputDecoration(
          labelText: tr('Nuova password'),
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: IconButton(
            icon: Icon(
              _mostraPassword ? Icons.visibility_off : Icons.visibility,
              color: AppTheme.textGrey,
            ),
            onPressed: () => setState(() => _mostraPassword = !_mostraPassword),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: _caricamento ? null : _confermaReset,
        child: _caricamento
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(tr('Reimposta password')),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: _caricamento
            ? null
            : () => setState(() {
                _fase = _FaseReset.email;
                _codiceCtrl.clear();
                _passwordCtrl.clear();
                _errore = null;
              }),
        child: Text(
          tr('Indietro'),
          style: const TextStyle(color: AppTheme.textGrey),
        ),
      ),
    ];
  }
}
