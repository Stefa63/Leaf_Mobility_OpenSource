import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// @brief Store osservabile dei dati di profilo e dei dati sensibili dell'utente.
///
/// Segue lo stesso pattern di [appLanguage] / [bookingStore] / [AppSettings]:
/// un gruppo di [ValueNotifier] consultabili dalle viste tramite
/// [ValueListenableBuilder], senza introdurre pattern MVC. A differenza degli
/// altri store (volatili), questo persiste i dati **localmente sul dispositivo**
/// (UT.21, UT.22.2): i campi testuali via [SharedPreferences] e i file
/// (foto profilo, documenti KYC) copiati nella sandbox dell'app
/// ([getApplicationDocumentsDirectory]). Nessun dato lascia il dispositivo:
/// la sincronizzazione cifrata (AES-256, IIN-4) sara' a carico del Business
/// Tier `gestore_profili_ekyc` quando disponibile.
class ProfileStore {
  ProfileStore._();

  // ── Dati anagrafici (UT.21) ───────────────────────────────────────────────

  /// Nome dell'utente (vuoto finché non sincronizzato dal backend, UT.21).
  static final ValueNotifier<String> firstName = ValueNotifier<String>('');

  /// Cognome dell'utente (vuoto finché non sincronizzato dal backend, UT.21).
  static final ValueNotifier<String> lastName = ValueNotifier<String>('');

  /// Indirizzo email di accesso. IIN-1.
  static final ValueNotifier<String> email = ValueNotifier<String>('');

  /// Residenza completa dell'utente.
  static final ValueNotifier<String> address = ValueNotifier<String>('');

  /// Numero telefonico dell'utente.
  static final ValueNotifier<String> phone = ValueNotifier<String>('');

  /// Percorso locale della foto profilo (file nella sandbox dell'app), o null.
  static final ValueNotifier<String?> photoPath = ValueNotifier<String?>(null);

  // ── Dati sensibili: documenti KYC (UT.22.2, IIN-6) ────────────────────────

  /// Percorso locale della scansione/foto della carta d'identita', o null.
  static final ValueNotifier<String?> idCardPath = ValueNotifier<String?>(null);

  /// Percorso locale della scansione/foto della patente, o null.
  static final ValueNotifier<String?> licensePath = ValueNotifier<String?>(
    null,
  );

  // ── Dati sensibili: metodo di pagamento (UT.11) ───────────────────────────

  /// Intestatario della carta registrata.
  static final ValueNotifier<String> cardHolder = ValueNotifier<String>('');

  /// Numero della carta (memorizzato in chiaro solo localmente; in produzione
  /// sara' tokenizzato dal `gateway_pagamenti`). Mostrato sempre mascherato.
  static final ValueNotifier<String> cardNumber = ValueNotifier<String>('');

  /// Scadenza della carta in formato MM/AA.
  static final ValueNotifier<String> cardExpiry = ValueNotifier<String>('');

  // ── Persistenza locale ────────────────────────────────────────────────────

  static const String _kFirstName = 'profile.firstName';
  static const String _kLastName = 'profile.lastName';
  static const String _kEmail = 'profile.email';
  static const String _kAddress = 'profile.address';
  static const String _kPhone = 'profile.phone';
  static const String _kPhotoPath = 'profile.photoPath';
  static const String _kIdCardPath = 'profile.idCardPath';
  static const String _kLicensePath = 'profile.licensePath';
  static const String _kCardHolder = 'profile.cardHolder';
  static const String _kCardNumber = 'profile.cardNumber';
  static const String _kCardExpiry = 'profile.cardExpiry';

  /// @brief Carica i dati persistiti localmente. Da invocare una sola volta
  ///        all'avvio (in `main`) prima di costruire l'app.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    firstName.value = prefs.getString(_kFirstName) ?? firstName.value;
    lastName.value = prefs.getString(_kLastName) ?? lastName.value;
    email.value = prefs.getString(_kEmail) ?? email.value;
    address.value = prefs.getString(_kAddress) ?? address.value;
    phone.value = prefs.getString(_kPhone) ?? phone.value;
    photoPath.value = prefs.getString(_kPhotoPath);
    idCardPath.value = prefs.getString(_kIdCardPath);
    licensePath.value = prefs.getString(_kLicensePath);
    cardHolder.value = prefs.getString(_kCardHolder) ?? '';
    cardNumber.value = prefs.getString(_kCardNumber) ?? '';
    cardExpiry.value = prefs.getString(_kCardExpiry) ?? '';
  }

  /// @brief Salva i dati anagrafici modificati nell'archivio locale. UT.21.
  static Future<void> savePersonalData({
    required String firstNameValue,
    required String lastNameValue,
    required String emailValue,
    required String addressValue,
    required String phoneValue,
  }) async {
    firstName.value = firstNameValue;
    lastName.value = lastNameValue;
    email.value = emailValue;
    address.value = addressValue;
    phone.value = phoneValue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFirstName, firstNameValue);
    await prefs.setString(_kLastName, lastNameValue);
    await prefs.setString(_kEmail, emailValue);
    await prefs.setString(_kAddress, addressValue);
    await prefs.setString(_kPhone, phoneValue);
  }

  /// @brief Salva il metodo di pagamento nell'archivio locale. UT.11.
  static Future<void> savePaymentMethod({
    required String holder,
    required String number,
    required String expiry,
  }) async {
    cardHolder.value = holder;
    cardNumber.value = number;
    cardExpiry.value = expiry;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCardHolder, holder);
    await prefs.setString(_kCardNumber, number);
    await prefs.setString(_kCardExpiry, expiry);
  }

  /// @brief Imposta (o azzera) la foto profilo persistendone il percorso. UT.21.
  static Future<void> setPhotoPath(String? path) async {
    photoPath.value = path;
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_kPhotoPath);
    } else {
      await prefs.setString(_kPhotoPath, path);
    }
  }

  /// @brief Imposta (o azzera) il documento carta d'identita'. UT.22.2.
  static Future<void> setIdCardPath(String? path) async {
    idCardPath.value = path;
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_kIdCardPath);
    } else {
      await prefs.setString(_kIdCardPath, path);
    }
  }

  /// @brief Imposta (o azzera) il documento patente. UT.22.2.
  static Future<void> setLicensePath(String? path) async {
    licensePath.value = path;
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_kLicensePath);
    } else {
      await prefs.setString(_kLicensePath, path);
    }
  }
}

/// @brief Esito della selezione di un'immagine locale.
/// @param file il file selezionato e copiato nella sandbox, o null.
/// @param permissionDenied true se l'utente ha negato il permesso richiesto.
typedef PickResult = ({File? file, bool permissionDenied});

/// @brief Seleziona un'immagine da galleria o fotocamera e la copia nella
///        sandbox dell'app (resta locale sul dispositivo).
///
/// Richiede esplicitamente il permesso di accesso a fotocamera/galleria
/// (IIN-16, GDPR) tramite `permission_handler` prima di aprire il picker.
/// Le immagini sono JPG/PNG, conformi ai formati KYC ammessi (IIN-6).
///
/// @param source origine dell'immagine (galleria o fotocamera).
/// @param basename nome-base del file di destinazione nella sandbox.
/// @return [PickResult] con il file copiato oppure il flag di permesso negato.
Future<PickResult> pickAndStoreImage({
  required ImageSource source,
  required String basename,
}) async {
  // Richiesta permesso coerente con la sorgente e la piattaforma.
  if (source == ImageSource.camera) {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      return (file: null, permissionDenied: true);
    }
  } else if (Platform.isIOS) {
    // Su Android 13+ la galleria usa il Photo Picker di sistema (nessun
    // permesso runtime). Su iOS serve il consenso alla libreria foto.
    final status = await Permission.photos.request();
    if (!status.isGranted && !status.isLimited) {
      return (file: null, permissionDenied: true);
    }
  }

  final picker = ImagePicker();
  // `requestFullMetadata: false` evita la lettura dei metadati EXIF/posizione
  // (più veloce e meno permessi); dimensione/qualità ridotte per un caricamento
  // rapido dei documenti dalla galleria senza perdere leggibilità (punto 7).
  final XFile? picked = await picker.pickImage(
    source: source,
    imageQuality: 80,
    maxWidth: 1280,
    requestFullMetadata: false,
  );
  if (picked == null) {
    return (file: null, permissionDenied: false);
  }

  final dir = await getApplicationDocumentsDirectory();
  final ext = picked.path.contains('.')
      ? picked.path.split('.').last.toLowerCase()
      : 'jpg';
  final dest = File('${dir.path}/$basename.$ext');
  await File(picked.path).copy(dest.path);
  return (file: dest, permissionDenied: false);
}
