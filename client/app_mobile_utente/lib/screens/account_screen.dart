import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_mobile_utente/api/api_client.dart';
import 'package:app_mobile_utente/api/profilo_repository.dart';
import 'package:app_mobile_utente/theme.dart';
import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/profile_store.dart';

/// @brief Schermata dei dati anagrafici dell'utente, visualizzabili e
///        modificabili. UT.21.
///
/// Ogni campo e' di sola lettura finche' non si tocca la matita di fianco, che
/// lo abilita singolarmente alla modifica. La foto profilo puo' essere caricata
/// da galleria o fotocamera e resta **locale** sul dispositivo
/// ([ProfileStore]). Le modifiche sono persistite localmente al salvataggio.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, ProfiloApi? profilo}) : _profilo = profilo;

  /// Repository profilo iniettabile (default reale; fittizio nei test).
  final ProfiloApi? _profilo;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _phone;

  /// Repository risolto: quello iniettato (test) o il singleton reale.
  late final ProfiloApi _profilo = widget._profilo ?? profiloRepository;

  /// Insieme dei campi attualmente sbloccati per la modifica.
  final Set<String> _editing = <String>{};

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController(text: ProfileStore.firstName.value);
    _lastName = TextEditingController(text: ProfileStore.lastName.value);
    _email = TextEditingController(text: ProfileStore.email.value);
    _address = TextEditingController(text: ProfileStore.address.value);
    _phone = TextEditingController(text: ProfileStore.phone.value);
    _caricaProfilo(); // dati reali dal backend (UT.21), fallback ai dati locali
  }

  /// Carica il profilo dal backend e aggiorna i campi (UT.21).
  ///
  /// In caso di errore di rete mantiene i dati locali già mostrati (IIN-6): il
  /// profilo resta consultabile anche offline.
  Future<void> _caricaProfilo() async {
    try {
      final p = await _profilo.profilo();
      if (!mounted) return;
      String? leggi(Object? v) => v == null ? null : '$v';
      setState(() {
        final nome = leggi(p['nome']);
        final cognome = leggi(p['cognome']);
        final email = leggi(p['email']);
        final telefono = leggi(p['telefono']);
        if (nome != null) _firstName.text = nome;
        if (cognome != null) _lastName.text = cognome;
        if (email != null) _email.text = email;
        if (telefono != null) _phone.text = telefono;
      });
    } on LeafApiException {
      // Offline o non autenticato: si resta sui dati locali.
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  /// Persiste le modifiche dei dati anagrafici e le sincronizza col backend. UT.21.
  ///
  /// Il salvataggio locale avviene sempre (resilienza offline, IIN-6); la
  /// sincronizzazione server invia la sola whitelist (nome/cognome/telefono) e,
  /// se fallisce, lascia comunque i dati salvati in locale con avviso.
  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    await ProfileStore.savePersonalData(
      firstNameValue: _firstName.text.trim(),
      lastNameValue: _lastName.text.trim(),
      emailValue: _email.text.trim(),
      addressValue: _address.text.trim(),
      phoneValue: _phone.text.trim(),
    );
    String? errore;
    try {
      await _profilo.aggiorna({
        'nome': _firstName.text.trim(),
        'cognome': _lastName.text.trim(),
        'telefono': _phone.text.trim(),
      });
    } on LeafApiException catch (e) {
      errore = e.messaggio;
    }
    if (!mounted) return;
    setState(_editing.clear);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errore ?? tr('Modifiche salvate')),
        backgroundColor: errore == null
            ? AppTheme.primaryGreen
            : const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Mostra il foglio di scelta dell'origine immagine e aggiorna la foto. UT.21.
  Future<void> _changePhoto() async {
    final hasPhoto = ProfileStore.photoPath.value != null;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.backgroundBeige,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppTheme.primaryGreen,
              ),
              title: Text(tr('Scegli dalla galleria')),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: AppTheme.primaryGreen,
              ),
              title: Text(tr('Scatta una foto')),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  tr('Rimuovi foto'),
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;

    if (action == 'remove') {
      await ProfileStore.setPhotoPath(null);
      return;
    }

    final result = await pickAndStoreImage(
      source: action == 'camera' ? ImageSource.camera : ImageSource.gallery,
      basename: 'profile_photo',
    );
    if (!mounted) return;
    if (result.permissionDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('Permesso negato. Abilitalo nelle impostazioni.')),
          backgroundColor: AppTheme.accentBrown,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    if (result.file != null) {
      await ProfileStore.setPhotoPath(result.file!.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            tr('Dati Utente'),
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
                // ── Foto profilo (locale) ────────────────────────────────
                Center(child: _buildPhotoPicker()),
                const SizedBox(height: 28),
                _buildField('firstName', tr('Nome'), _firstName),
                const SizedBox(height: 16),
                _buildField('lastName', tr('Cognome'), _lastName),
                const SizedBox(height: 16),
                _buildField(
                  'email',
                  tr('Email'),
                  _email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildField('address', tr('Residenza completa'), _address),
                const SizedBox(height: 16),
                _buildField(
                  'phone',
                  tr('Numero telefonico'),
                  _phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _save,
                  child: Text(tr('Salva Modifiche')),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// Avatar circolare con badge fotocamera per cambiare la foto profilo.
  Widget _buildPhotoPicker() {
    return ValueListenableBuilder<String?>(
      valueListenable: ProfileStore.photoPath,
      builder: (context, path, _) {
        final hasPhoto = path != null && File(path).existsSync();
        return Stack(
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: AppTheme.primaryGreen,
              backgroundImage: hasPhoto ? FileImage(File(path)) : null,
              child: hasPhoto
                  ? null
                  : const Icon(Icons.person, color: Colors.white, size: 56),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Material(
                color: AppTheme.darkGreen,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _changePhoto,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Campo dati con matita: di sola lettura finche' non viene sbloccato. UT.21.
  Widget _buildField(
    String id,
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    final editable = _editing.contains(id);
    return TextField(
      controller: controller,
      readOnly: !editable,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: !editable,
        fillColor: Colors.black.withAlpha(8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          tooltip: editable ? tr('Blocca campo') : tr('Modifica campo'),
          icon: Icon(
            editable ? Icons.check : Icons.edit_outlined,
            color: AppTheme.primaryGreen,
          ),
          onPressed: () {
            setState(() {
              if (editable) {
                _editing.remove(id);
              } else {
                _editing.add(id);
              }
            });
          },
        ),
      ),
    );
  }
}
