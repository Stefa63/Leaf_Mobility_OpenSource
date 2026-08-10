import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/auth_repository.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/screens/change_password_screen.dart';
import 'package:web_dashboard/screens/reset_password_screen.dart';
import 'package:web_dashboard/session.dart';
import 'package:web_dashboard/theme.dart';
import 'package:web_dashboard/widgets/lang_toggle.dart';
import 'package:web_dashboard/widgets/leaf_logo.dart';

/// @brief Schermata di accesso unica per OP e PA, cablata su `/api/v1/auth`.
///
/// L'accesso è a due passi (IIN-9): credenziali → secondo fattore OTP, sempre
/// obbligatorio per le figure della dashboard. Il ruolo effettivo è quello
/// restituito dal backend (RBAC, IIN-5); il selettore resta come indicazione
/// dell'utente. Il token di sessione è custodito cifrato e usato come Bearer.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, AuthApi? auth}) : _auth = auth;

  /// Repository di autenticazione iniettabile (default reale; fittizio nei test).
  final AuthApi? _auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// Passo corrente del flusso di accesso.
enum _Fase { credenziali, otp }

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  DashboardRole _role = DashboardRole.operator;

  late final AuthApi _auth = widget._auth ?? authRepository;

  _Fase _fase = _Fase.credenziali;
  String? _idAccount;
  bool _caricamento = false;
  String? _errore;
  String? _otpError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  /// Esegue una chiamata di rete gestendo in modo uniforme caricamento ed errori.
  Future<void> _conRete(Future<void> Function() azione) async {
    setState(() {
      _caricamento = true;
      _errore = null;
    });
    try {
      await azione();
    } on LeafApiException catch (e) {
      if (mounted) setState(() => _errore = e.messaggio);
    } finally {
      if (mounted) setState(() => _caricamento = false);
    }
  }

  /// Primo passo: invio credenziali (IIN-1) → attesa OTP per OP/PA (IIN-9).
  Future<void> _accedi() async {
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _errore = tr('Inserisci email e password.'));
      return;
    }
    await _conRete(() async {
      final esito = await _auth.accedi(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
      if (!mounted) return;
      switch (esito.stato) {
        case StatoAccesso.mfaRichiesta:
          setState(() {
            _idAccount = esito.idAccount;
            _fase = _Fase.otp;
            _otpError = null;
          });
          if (esito.otpSimulato != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(
                  tr('Sviluppo: usa l\'OTP simulato: ${esito.otpSimulato}'),
                ),
                duration: const Duration(seconds: 15),
              ),
            );
          }
        case StatoAccesso.ok:
          _entra(esito.ruolo);
        case StatoAccesso.cambioPasswordRichiesto:
          await _cambioPassword(esito.ruolo);
      }
    });
  }

  /// Reindirizza al cambio password obbligatorio (IIN-12) e, al successo, entra.
  /// @param ruolo Ruolo restituito dal backend, usato per instradare dopo il cambio.
  Future<void> _cambioPassword(String? ruolo) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ChangePasswordScreen(auth: _auth),
      ),
    );
    if (ok == true && mounted) _entra(ruolo);
  }

  /// Secondo passo: verifica del codice OTP (IIN-9) → token e ingresso.
  Future<void> _verifica() async {
    if (_otpCtrl.text.trim().length != 6) {
      setState(() => _otpError = tr('Inserisci un codice OTP a 6 cifre.'));
      return;
    }
    final id = _idAccount;
    if (id == null) return;
    await _conRete(() async {
      final esito = await _auth.verificaMfa(id, _otpCtrl.text.trim());
      if (!mounted) return;
      switch (esito.stato) {
        case StatoAccesso.ok:
          _entra(esito.ruolo);
        case StatoAccesso.cambioPasswordRichiesto:
          await _cambioPassword(esito.ruolo);
        case StatoAccesso.mfaRichiesta:
          setState(() => _otpError = tr('Codice OTP non valido.'));
      }
    });
  }

  /// Imposta il ruolo dalla risposta del backend e apre la console (RBAC, IIN-5).
  /// @param ruolo Ruolo restituito dal backend ("OP"/"PA"); altri ruoli sono respinti.
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
    Navigator.pushReplacementNamed(context, '/home');
  }

  /// Naviga alla schermata di reset password completa (IIN-11/AP.12).
  void _reset() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResetPasswordScreen(auth: _auth),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: _BrandBackground()),
            Positioned(top: 20, right: 24, child: LangToggle()),
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
                            tr('Accesso Operatori e PA'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkGreen,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tr('Console di gestione LEAF Mobility'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textGrey,
                            ),
                          ),
                          const SizedBox(height: 28),
                          if (_errore != null) _bannerErrore(_errore!),
                          if (_fase == _Fase.credenziali)
                            ..._campiCredenziali()
                          else
                            ..._campiOtp(),
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

  /// Campi e azioni del passo credenziali.
  List<Widget> _campiCredenziali() {
    return [
      _roleSelector(),
      const SizedBox(height: 20),
      TextField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => _accedi(),
        decoration: InputDecoration(
          labelText: tr('Email'),
          prefixIcon: const Icon(Icons.email_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _passwordCtrl,
        obscureText: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _accedi(),
        decoration: InputDecoration(
          labelText: tr('Password'),
          prefixIcon: const Icon(Icons.lock_outline),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: _caricamento ? null : _accedi,
        child: _caricamento
            ? const _Spinner()
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
    ];
  }

  /// Campi e azioni del passo OTP (secondo fattore).
  List<Widget> _campiOtp() {
    return [
      Text(
        tr('Inserisci il codice a 6 cifre inviato via email'),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _otpCtrl,
        keyboardType: TextInputType.number,
        maxLength: 6,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _verifica(),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (_) {
          if (_otpError != null) setState(() => _otpError = null);
        },
        decoration: InputDecoration(
          labelText: tr('Codice OTP'),
          counterText: '',
          errorText: _otpError,
          prefixIcon: const Icon(Icons.shield_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: _caricamento ? null : _verifica,
        child: _caricamento ? const _Spinner() : Text(tr('Verifica')),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: _caricamento
            ? null
            : () => setState(() {
                _fase = _Fase.credenziali;
                _otpCtrl.clear();
                _otpError = null;
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

  Widget _roleSelector() {
    Widget option(DashboardRole role, IconData icon, String label, Color c) {
      final selected = _role == role;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _role = role),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: selected ? c.withAlpha(20) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? c : Colors.black12,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: selected ? c : AppTheme.textGrey, size: 26),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.2,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    color: selected ? c : AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('Ruolo'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textGrey,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            option(
              DashboardRole.operator,
              Icons.headset_mic_outlined,
              tr('Operatore del Servizio'),
              AppTheme.opAccent,
            ),
            const SizedBox(width: 12),
            option(
              DashboardRole.publicAdmin,
              Icons.account_balance_outlined,
              tr('Amministrazione Pubblica'),
              AppTheme.apAccent,
            ),
          ],
        ),
      ],
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

/// Sfondo decorativo della pagina di login (gradiente verde tenue).
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
