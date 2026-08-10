import 'package:flutter/foundation.dart';

/// @brief Preferenze applicative dell'utente per un servizio di noleggio mezzi.
///
/// Segue lo stesso pattern osservabile di [appLanguage] / [bookingStore]: un
/// gruppo di [ValueNotifier] consultabili dalle viste tramite
/// [ValueListenableBuilder], senza introdurre nuove dipendenze ne' pattern MVC.
/// Lo stato e' volatile (in-memory): sara' persistito/sincronizzato dal Business
/// Tier server. NB: non e' previsto alcun tema scuro (vincolo di progetto).
class AppSettings {
  AppSettings._();

  /// Abilitazione globale delle notifiche push. IIN-19.
  static final ValueNotifier<bool> pushNotifications = ValueNotifier<bool>(
    true,
  );

  /// Promemoria a schermo prima della scadenza della prenotazione. UT.15.
  static final ValueNotifier<bool> bookingReminders = ValueNotifier<bool>(true);

  /// Notifiche commerciali (promozioni e offerte). UT.18.
  static final ValueNotifier<bool> promoNotifications = ValueNotifier<bool>(
    false,
  );

  /// Consenso ai servizi di localizzazione (GPS). IIN-16 (GDPR).
  static final ValueNotifier<bool> locationServices = ValueNotifier<bool>(true);

  /// Condivisione di dati di utilizzo anonimi e aggregati. IIN-15.
  static final ValueNotifier<bool> usageDataSharing = ValueNotifier<bool>(
    false,
  );
}
