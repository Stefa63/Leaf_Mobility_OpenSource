import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_mobile_utente/api/api_config.dart';

/// @brief Impostazioni della "Modalità sviluppatore" dell'app utente.
///
/// Consente, in fase di sviluppo/debug, di puntare l'app a un server diverso da
/// quello di produzione (es. un'istanza in LAN `http://192.168.1.60:8770/api/v1`)
/// senza dover ricompilare con `--dart-define`. Segue lo stesso pattern
/// osservabile del resto dell'app ([AppSettings]/[appLanguage]): [ValueNotifier]
/// consultabili dalle viste, nessun nuovo pattern ne' dipendenza (usa
/// `shared_preferences`, gia' presente).
///
/// Lo stato e' persistito on-device, cosi' l'override sopravvive ai riavvii
/// dell'app durante una sessione di debug USB.
class DevSettings {
  DevSettings._();

  static const String _kAbilitata = 'dev_mode_enabled';
  static const String _kUrl = 'dev_mode_api_base';

  /// Abilitazione della modalita' sviluppatore (override URL + log verbosi).
  static final ValueNotifier<bool> abilitata = ValueNotifier<bool>(false);

  /// URL base personalizzato della API (`.../api/v1`); vuoto = usa il default.
  static final ValueNotifier<String> apiBasePersonalizzato =
      ValueNotifier<String>('');

  /// @brief URL base effettivamente usato dal client di rete.
  /// @return L'override se la modalita' e' attiva e l'URL e' valorizzato,
  ///         altrimenti il default di produzione [kLeafApiBase].
  static String get apiBaseEffettivo {
    final personalizzato = apiBasePersonalizzato.value.trim();
    if (abilitata.value && personalizzato.isNotEmpty) {
      return personalizzato;
    }
    return kLeafApiBase;
  }

  /// @brief Ripristina dal disco le preferenze di sviluppo persistite.
  /// @return Future completato quando i valori sono stati caricati.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    abilitata.value = prefs.getBool(_kAbilitata) ?? false;
    apiBasePersonalizzato.value = prefs.getString(_kUrl) ?? '';
  }

  /// @brief Persiste l'attuale configurazione di sviluppo su disco.
  /// @param attiva Nuovo stato di abilitazione della modalita' sviluppatore.
  /// @param apiBase Nuovo URL base personalizzato (puo' essere vuoto).
  /// @return Future completato a salvataggio avvenuto.
  static Future<void> save({required bool attiva, required String apiBase}) async {
    abilitata.value = attiva;
    apiBasePersonalizzato.value = apiBase.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAbilitata, abilitata.value);
    await prefs.setString(_kUrl, apiBasePersonalizzato.value);
  }
}
