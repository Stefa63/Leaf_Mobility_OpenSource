import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app_mobile_utente/theme.dart';
import 'package:app_mobile_utente/screens/registration_screen.dart';
import 'package:app_mobile_utente/screens/reset_password_screen.dart';
import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/api/api_client.dart';
import 'package:app_mobile_utente/api/auth_repository.dart';

/// @brief Schermata di accesso cablata al backend `/api/v1/auth` (IIN-1/IIN-9/UT.24).
///
/// Gestisce l'intero flusso di autenticazione reale: credenziali (IIN-1), secondo
/// fattore OTP per gli utenti con MFA (IIN-9), reset password via email (UT.24) e
/// rimando alla registrazione (UT.22). Espone stati di caricamento ed errore: la UI
/// non assume mai un esito positivo prima della risposta del server.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, AuthApi? auth}) : _auth = auth;

  /// Repository di autenticazione iniettabile (default reale; fittizio nei test).
  final AuthApi? _auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _identitaCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _otpCtrl = TextEditingController();

  late final AuthApi _auth = widget._auth ?? authRepository;

  /// True mentre è in corso una chiamata di rete (blocca i pulsanti, mostra spinner).
  bool _caricamento = false;

  /// Messaggio d'errore leggibile dell'ultimo tentativo, o null.
  String? _errore;

  /// Toggle di visibilità della password (icona occhio, IIN-2).
  bool _mostraPassword = false;

  /// Id account in attesa di OTP (IIN-9): se valorizzato si mostra il passo MFA.
  String? _idAccountMfa;

  /// OTP restituito dal backend in simulazione (provider OTP fittizio, IIN-9).
  String? _otpSimulato;

  @override
  void dispose() {
    _identitaCtrl.dispose();
    _passwordCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  /// Esegue una chiamata di rete gestendo caricamento ed errori in modo uniforme.
  ///
  /// Intercetta i codici HTTP per fornire messaggi differenziati (IIN-10/IIN-14):
  /// 401 = credenziali errate, 423 = account bloccato, 403 = account sospeso o
  /// limite dispositivi raggiunto (distinto dal dettaglio del backend).
  Future<void> _esegui(Future<void> Function() azione) async {
    setState(() {
      _caricamento = true;
      _errore = null;
    });
    try {
      await azione();
    } on LeafApiException catch (e) {
      if (mounted) {
        setState(() => _errore = _messaggioPerCodice(e));
      }
    } finally {
      if (mounted) setState(() => _caricamento = false);
    }
  }

  /// Restituisce un messaggio d'errore localizzato in base al codice HTTP.
  String _messaggioPerCodice(LeafApiException e) {
    switch (e.codice) {
      case 401:
        return tr('Credenziali non valide. Controlla email e password.');
      case 423:
        return tr(
          'Account bloccato per troppi tentativi. '
          'Riprova tra qualche minuto.',
        );
      case 403:
        if (e.messaggio == 'limite_dispositivi_superato') {
          return tr(
            'Limite dispositivi raggiunto. '
            'Disconnetti un altro dispositivo per continuare.',
          );
        }
        return tr('Account sospeso. Contatta l\'assistenza.');
      case 409:
        return tr('Account già esistente con questa email o username.');
      case 503:
        return tr('Servizio temporaneamente non disponibile. Riprova.');
      default:
        return e.messaggio;
    }
  }

  /// Avvia il login con identità e password (IIN-1); instrada verso MFA o home.
  Future<void> _accedi() async {
    if (_identitaCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _errore = tr('Inserisci email e password.'));
      return;
    }
    await _esegui(() async {
      final esito = await _auth.accedi(
        _identitaCtrl.text.trim(),
        _passwordCtrl.text,
      );
      if (!mounted) return;
      switch (esito.stato) {
        case StatoAccesso.ok:
          Navigator.pushReplacementNamed(context, '/home');
        case StatoAccesso.mfaRichiesta:
          setState(() {
            _idAccountMfa = esito.idAccount;
            _otpSimulato = esito.otpSimulato;
          });
        case StatoAccesso.cambioPasswordRichiesto:
          setState(
            () => _errore = tr(
              'Devi cambiare la password temporanea. '
              'Contatta l\'operatore.',
            ),
          );
      }
    });
  }

  /// Completa il login col secondo fattore OTP (IIN-9).
  Future<void> _verificaOtp() async {
    final id = _idAccountMfa;
    if (id == null || _otpCtrl.text.trim().isEmpty) return;
    await _esegui(() async {
      final esito = await _auth.verificaMfa(id, _otpCtrl.text.trim());
      if (mounted && esito.stato == StatoAccesso.ok) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  /// Naviga alla schermata di reset password completa (IIN-11/UT.24).
  void _reset() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResetPasswordScreen(auth: _auth),
      ),
    );
  }

  /// Abbandona il passo MFA e torna all'inserimento credenziali.
  void _annullaMfa() {
    setState(() {
      _idAccountMfa = null;
      _otpSimulato = null;
      _otpCtrl.clear();
      _errore = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  width: 80,
                  height: 80,
                  placeholderBuilder: (_) => Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  tr('Benvenuto in Leaf Mobility'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _idAccountMfa == null
                      ? tr('Accedi o registrati per iniziare')
                      : tr('Inserisci il codice OTP ricevuto'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textGrey,
                  ),
                ),
                const SizedBox(height: 32),
                if (_errore != null) _bannerErrore(_errore!),
                if (_idAccountMfa == null)
                  ..._campiCredenziali()
                else
                  ..._campiOtp(),
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

  /// Campi e azioni del passo credenziali (email/password, reset, registrazione).
  List<Widget> _campiCredenziali() {
    return [
      TextField(
        controller: _identitaCtrl,
        enabled: !_caricamento,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: tr('Email'),
          prefixIcon: const Icon(Icons.email),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _passwordCtrl,
        enabled: !_caricamento,
        obscureText: !_mostraPassword,
        onSubmitted: (_) => _accedi(),
        decoration: InputDecoration(
          labelText: tr('Password'),
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
      const SizedBox(height: 32),
      ElevatedButton(
        onPressed: _caricamento ? null : _accedi,
        child: _caricamento
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(tr('Accedi')),
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: _caricamento ? null : _reset,
          child: Text(
            tr('Password dimenticata?'),
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
          ),
        ),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: _caricamento
            ? null
            : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RegistrationScreen(),
                ),
              ),
        child: Text(
          tr('Nuovo utente? Registrati'),
          style: const TextStyle(color: AppTheme.accentBrown),
        ),
      ),
    ];
  }

  /// Campi e azioni del passo MFA (OTP), con hint dell'OTP simulato in sviluppo.
  List<Widget> _campiOtp() {
    return [
      TextField(
        controller: _otpCtrl,
        enabled: !_caricamento,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        onSubmitted: (_) => _verificaOtp(),
        decoration: InputDecoration(
          labelText: tr('Codice OTP'),
          prefixIcon: const Icon(Icons.shield_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      if (_otpSimulato != null) ...[
        const SizedBox(height: 8),
        Text(
          '${tr('OTP di prova')}: $_otpSimulato',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
        ),
      ],
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: _caricamento ? null : _verificaOtp,
        child: _caricamento
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(tr('Verifica codice')),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: _caricamento ? null : _annullaMfa,
        child: Text(
          tr('Annulla'),
          style: const TextStyle(color: AppTheme.textGrey),
        ),
      ),
    ];
  }
}
