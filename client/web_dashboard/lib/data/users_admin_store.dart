import 'package:flutter/foundation.dart';

import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/users_admin_repository.dart';
import 'package:web_dashboard/data/users_admin_data.dart';

/// @brief Stato osservabile della Gestione Utenti/AP da `/api/v1/utenti` (OP.10/17/18).
///
/// La schermata osserva [users]/[apAccounts] tramite [ValueListenableBuilder] (nessun
/// MVC, stesso pattern di `FleetStore`). I dati provengono esclusivamente dal server:
/// l'elenco parte vuoto e, senza rete, resta vuoto con [offline] a true (nessun dato
/// fabbricato — dipendenza dal server).
class UsersAdminStore {
  UsersAdminStore._();

  /// Account utente correnti (solo dati reali dal server; vuoto se non caricati/offline).
  static final ValueNotifier<List<ManagedUser>> users =
      ValueNotifier<List<ManagedUser>>(const []);

  /// Account di Amministrazione Pubblica correnti (solo dati reali dal server).
  static final ValueNotifier<List<ApAccount>> apAccounts =
      ValueNotifier<List<ApAccount>>(const []);

  /// True quando l'ultimo caricamento è fallito (lista vuota + banner offline).
  static final ValueNotifier<bool> offline = ValueNotifier<bool>(false);

  static bool _inCorso = false;

  /// @brief Carica account UT e PA dal backend e aggiorna gli store.
  /// @param repo Repository da usare (iniettabile nei test).
  static Future<void> carica({GestioneUtentiApi? repo}) async {
    if (_inCorso) return;
    _inCorso = true;
    final api = repo ?? usersAdminRepository;
    try {
      final ut = await api.elencoAccount(ruolo: 'UT');
      final pa = await api.elencoAccount(ruolo: 'PA');
      users.value = ut
          .map(ManagedUser.daApi)
          .whereType<ManagedUser>()
          .toList(growable: false);
      apAccounts.value = pa
          .map(ApAccount.daApi)
          .whereType<ApAccount>()
          .toList(growable: false);
      offline.value = false;
    } on LeafApiException {
      offline.value = true; // resta sui dati di riserva
    } finally {
      _inCorso = false;
    }
  }

  /// @brief Sospende o riattiva un account utente e aggiorna lo store (OP.10/OP.18).
  /// @param idAccount Id dell'account.
  /// @param sospendi True per sospendere, false per riattivare.
  /// @param repo Repository da usare (iniettabile nei test).
  /// @throws LeafApiException Se l'operazione remota fallisce.
  static Future<void> impostaStato(
    String idAccount, {
    required bool sospendi,
    GestioneUtentiApi? repo,
  }) async {
    final api = repo ?? usersAdminRepository;
    final aggiornato = await api.impostaStato(
      idAccount,
      sospendi ? 'sospeso' : 'attivo',
    );
    final nuovoStato = aggiornato['stato_account'] == 'sospeso'
        ? UserStatus.sospeso
        : UserStatus.attivo;
    users.value = users.value
        .map((u) {
          if (u.id != idAccount) return u;
          return ManagedUser(
            id: u.id,
            name: u.name,
            username: u.username,
            email: u.email,
            status: nuovoStato,
            note: u.note,
          );
        })
        .toList(growable: false);
  }

  /// @brief Provisiona un account PA e ricarica l'elenco (OP.17).
  /// @param email Email di accesso.
  /// @param username Username univoco.
  /// @param ente Nome dell'ente.
  /// @param emailIstituzionale Email istituzionale per il reset (AP.12).
  /// @param repo Repository da usare (iniettabile nei test).
  /// @return La password temporanea generata, da mostrare una sola volta (IIN-12).
  /// @throws LeafApiException Se la creazione fallisce (es. email/username in uso).
  static Future<String> provisionaPa({
    required String email,
    required String username,
    required String ente,
    required String emailIstituzionale,
    GestioneUtentiApi? repo,
  }) async {
    final api = repo ?? usersAdminRepository;
    final esito = await api.provisionaPa(
      email: email,
      username: username,
      ente: ente,
      emailIstituzionale: emailIstituzionale,
    );
    await carica(repo: api);
    return esito['password_temporanea']?.toString() ?? '';
  }
}
