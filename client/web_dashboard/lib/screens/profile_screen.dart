import 'package:flutter/material.dart';
import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/profilo_repository.dart';
import 'package:web_dashboard/l10n.dart';
import 'package:web_dashboard/session.dart';
import 'package:web_dashboard/theme.dart';
import 'package:web_dashboard/widgets/common.dart';

/// @brief Schermata di gestione profilo per OP e AP, cablata su `/api/v1/profilo`.
///
/// Raggiunta dalla tendina del profilo in alto a destra. Carica l'anagrafica
/// dell'account dal backend e ne salva le modifiche (whitelist nome/cognome/
/// telefono); in assenza di rete resta sui dati locali (IIN-6). Sicurezza (MFA,
/// cambio password) resta informativa. UT.21 lato dashboard.
class ProfileScreen extends StatefulWidget {
  /// Colore di accento del ruolo attivo (OP blu / AP teal).
  final Color accent;

  /// Repository profilo iniettabile (default reale; fittizio nei test).
  final ProfiloApi? profilo;

  const ProfileScreen({super.key, required this.accent, this.profilo});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _orgCtrl;

  late final ProfiloApi _profilo = widget.profilo ?? profiloRepository;

  @override
  void initState() {
    super.initState();
    final isAp = Session.isPublicAdmin;
    _nameCtrl = TextEditingController(
      text: isAp ? 'Comune di Zootropolis' : 'Mario Rossi',
    );
    _emailCtrl = TextEditingController(
      text: Session.email.isNotEmpty
          ? Session.email
          : (isAp ? 'ufficio.mobilita@comune.zootropolis.it' : 'operatore@leaf.it'),
    );
    _phoneCtrl = TextEditingController(text: '+39 080 000 0000');
    _orgCtrl = TextEditingController(
      text: isAp ? 'Assessorato alla Mobilità' : 'Centro Operativo LEAF',
    );
    _caricaProfilo();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _orgCtrl.dispose();
    super.dispose();
  }

  /// Carica il profilo dal backend e popola i campi (UT.21 lato dashboard).
  /// In caso di errore mantiene i dati locali già mostrati (IIN-6).
  Future<void> _caricaProfilo() async {
    try {
      final p = await _profilo.profilo();
      if (!mounted) return;
      String? leggi(Object? v) => v == null ? null : '$v';
      final nome = leggi(p['nome']);
      final cognome = leggi(p['cognome']);
      final email = leggi(p['email']);
      final telefono = leggi(p['telefono']);
      setState(() {
        final completo = [nome, cognome].whereType<String>().join(' ').trim();
        if (completo.isNotEmpty) _nameCtrl.text = completo;
        if (email != null) _emailCtrl.text = email;
        if (telefono != null) _phoneCtrl.text = telefono;
      });
    } on LeafApiException {
      // Offline / non autenticato: si resta sui dati locali.
    }
  }

  /// Salva le modifiche anagrafiche sul backend (whitelist nome/cognome/telefono).
  Future<void> _salva() async {
    final parti = _nameCtrl.text.trim().split(RegExp(r'\s+'));
    final nome = parti.isNotEmpty ? parti.first : '';
    final cognome = parti.length > 1 ? parti.sublist(1).join(' ') : '';
    String? errore;
    try {
      await _profilo.aggiorna({
        'nome': nome,
        'cognome': cognome,
        'telefono': _phoneCtrl.text.trim(),
      });
    } on LeafApiException catch (e) {
      errore = e.messaggio;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: errore == null
            ? AppTheme.primaryGreen
            : const Color(0xFFC62828),
        content: Text(errore ?? tr('Modifiche salvate')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      final isAp = Session.isPublicAdmin;
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Gestione Profilo',
              subtitle:
                  isAp ? 'Profilo Amministrazione Pubblica' : 'Profilo Operatore',
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, c) {
                final narrow = c.maxWidth < 900;
                final left = _accountCard(isAp);
                final right = _securityCard();
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [left, const SizedBox(height: 18), right],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: left),
                    const SizedBox(width: 18),
                    Expanded(flex: 2, child: right),
                  ],
                );
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _accountCard(bool isAp) {
    return PanelCard(
      title: 'Dati Account',
      icon: Icons.badge_outlined,
      accent: widget.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: widget.accent.withAlpha(40),
                child: Icon(
                  isAp ? Icons.account_balance : Icons.support_agent,
                  color: widget.accent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  isAp
                      ? tr('Amministrazione Pubblica')
                      : tr('Operatore del Servizio'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _field(_nameCtrl, isAp ? 'Ente' : 'Nome e Cognome', Icons.person_outline),
          const SizedBox(height: 14),
          _field(_emailCtrl, 'Email', Icons.email_outlined),
          const SizedBox(height: 14),
          _field(_phoneCtrl, 'Telefono', Icons.phone_outlined),
          const SizedBox(height: 14),
          _field(_orgCtrl, isAp ? 'Dipartimento' : 'Reparto',
              Icons.apartment_outlined),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _salva,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: Text(tr('Salva Modifiche')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _securityCard() {
    return PanelCard(
      title: 'Sicurezza',
      icon: Icons.lock_outline,
      accent: widget.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield, color: AppTheme.darkGreen, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tr('Autenticazione a due fattori attiva (OTP via email)'),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.darkGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          QuickActionButton(
            icon: Icons.password,
            label: 'Cambia Password',
            accent: widget.accent,
          ),
          QuickActionButton(
            icon: Icons.history,
            label: 'Registro Accessi',
            accent: widget.accent,
          ),
          QuickActionButton(
            icon: Icons.devices_outlined,
            label: 'Dispositivi Collegati',
            accent: widget.accent,
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: tr(label),
        prefixIcon: Icon(icon, size: 20),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
