import 'package:flutter/material.dart';
import 'package:app_mobile_utente/theme.dart';
import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/api/api_client.dart';
import 'package:app_mobile_utente/api/auth_repository.dart';

/// @brief Registrazione di un nuovo utente UT cablata su `/api/v1/auth/registrazione` (UT.22.1).
///
/// Raccoglie le credenziali di base (email, username, password) e le invia al backend,
/// che applica la politica password IIN-5 e l'unicità di email/username. Gestisce gli
/// stati di caricamento ed errore; al successo riporta al login per l'accesso (UT.23).
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key, AuthApi? auth}) : _auth = auth;

  /// Repository di autenticazione iniettabile (default reale; fittizio nei test).
  final AuthApi? _auth;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  /// Dati anagrafici richiesti per la creazione account completa (UT.22.1).
  final TextEditingController _nomeCtrl = TextEditingController();
  final TextEditingController _cognomeCtrl = TextEditingController();
  final TextEditingController _residenzaCtrl = TextEditingController();

  /// Campo di sola lettura che mostra la data di nascita selezionata (UT.22.1).
  final TextEditingController _dataNascitaCtrl = TextEditingController();

  /// Data di nascita scelta dal date picker (obbligatoria, UT.22.1).
  DateTime? _dataNascita;

  late final AuthApi _auth = widget._auth ?? authRepository;

  bool _caricamento = false;
  String? _errore;

  /// Toggle di visibilità della password (icona occhio, IIN-2).
  bool _mostraPassword = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _nomeCtrl.dispose();
    _cognomeCtrl.dispose();
    _residenzaCtrl.dispose();
    _dataNascitaCtrl.dispose();
    super.dispose();
  }

  /// Apre il date picker per scegliere la data di nascita (UT.22.1).
  Future<void> _selezionaData() async {
    final ora = DateTime.now();
    final scelta = await showDatePicker(
      context: context,
      initialDate: _dataNascita ?? DateTime(ora.year - 25, ora.month, ora.day),
      firstDate: DateTime(1900),
      lastDate: ora,
    );
    if (scelta != null) {
      setState(() {
        _dataNascita = scelta;
        _dataNascitaCtrl.text = _formattaData(scelta);
      });
    }
  }

  /// Formato di visualizzazione gg/mm/aaaa.
  String _formattaData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// Formato ISO-8601 (aaaa-mm-gg) atteso dal backend.
  String _isoData(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Invia la registrazione al backend (UT.22.1); al successo torna al login.
  Future<void> _registra() async {
    final email = _emailCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    final nome = _nomeCtrl.text.trim();
    final cognome = _cognomeCtrl.text.trim();
    final residenza = _residenzaCtrl.text.trim();
    if (email.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        nome.isEmpty ||
        cognome.isEmpty ||
        residenza.isEmpty ||
        _dataNascita == null) {
      setState(
        () => _errore = tr('Compila tutti i campi, inclusa la data di nascita.'),
      );
      return;
    }
    setState(() {
      _caricamento = true;
      _errore = null;
    });
    try {
      await _auth.registra(
        email,
        username,
        password,
        dataNascita: _isoData(_dataNascita!),
        nome: nome,
        cognome: cognome,
        residenza: residenza,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('Registrazione completata. Ora puoi accedere.')),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.pop(context);
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
        title: Text(
          tr('Registrazione'),
          style: const TextStyle(color: AppTheme.darkGreen),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr('Completa il tuo profilo'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGreen,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                tr('Inserisci i tuoi dati per iniziare ad usare Leaf Mobility'),
                style: const TextStyle(color: AppTheme.textGrey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_errore != null) _bannerErrore(_errore!),
              _buildTextField(
                tr('Email'),
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildTextField(tr('Username'), controller: _usernameCtrl),
              const SizedBox(height: 16),
              _buildTextField(
                tr('Nome'),
                controller: _nomeCtrl,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                tr('Cognome'),
                controller: _cognomeCtrl,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                tr('Residenza (via di fatturazione)'),
                controller: _residenzaCtrl,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _dataNascitaCtrl,
                readOnly: true,
                enabled: !_caricamento,
                onTap: _caricamento ? null : _selezionaData,
                decoration: InputDecoration(
                  labelText: tr('Data di nascita'),
                  suffixIcon: const Icon(
                    Icons.calendar_today,
                    color: AppTheme.textGrey,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordCtrl,
                enabled: !_caricamento,
                obscureText: !_mostraPassword,
                decoration: InputDecoration(
                  labelText: tr('Password'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _mostraPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppTheme.textGrey,
                    ),
                    onPressed: () =>
                        setState(() => _mostraPassword = !_mostraPassword),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr('Minimo 8 caratteri, con una maiuscola, un numero e un simbolo.'),
                style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _caricamento ? null : _registra,
                child: _caricamento
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(tr('Registrati')),
              ),
            ],
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

  Widget _buildTextField(
    String label, {
    required TextEditingController controller,
    bool isObscure = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      enabled: !_caricamento,
      obscureText: isObscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
