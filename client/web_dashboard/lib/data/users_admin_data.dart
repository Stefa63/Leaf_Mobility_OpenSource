// users_admin_data.dart
// Modelli della Gestione Utenti/AP (OP.10/OP.17/OP.18).
//
// I modelli ManagedUser/ApAccount e i mapper daApi traducono i documenti account
// di /api/v1/utenti. I dati provengono esclusivamente dal server (nessun mock di
// riserva): a backend non raggiungibile la vista resta vuota con banner offline.

/// @brief Stato dell'account di un utente del servizio. OP.10 / OP.18.
enum UserStatus { attivo, sospeso }

/// @brief Stato dell'account di un Amministratore Pubblico. OP.17 (provisioning).
enum ApStatus { attivo, primoAccesso }

/// @brief Account utente gestibile dall'Operatore.
class ManagedUser {
  /// @brief Crea un account utente gestibile.
  ManagedUser({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    this.username = '',
    this.note = '',
  });

  /// @brief Costruisce un [ManagedUser] da un documento account della API.
  /// @param doc Documento account (`/api/v1/utenti`).
  /// @return L'account mappato, o null se privo di identificativo.
  static ManagedUser? daApi(Map<String, dynamic> doc) {
    final id = doc['_id']?.toString();
    if (id == null || id.isEmpty) return null;
    final etichetta = doc['nominativo']?.toString();
    return ManagedUser(
      id: id,
      name: (etichetta != null && etichetta.isNotEmpty)
          ? etichetta
          : (doc['username']?.toString() ?? doc['email']?.toString() ?? id),
      username: doc['username']?.toString() ?? '',
      email: doc['email']?.toString() ?? '',
      status: doc['stato_account'] == 'sospeso'
          ? UserStatus.sospeso
          : UserStatus.attivo,
    );
  }

  /// @brief Identificativo dell'account.
  final String id;

  /// @brief Etichetta leggibile (nominativo dal profilo o username).
  final String name;

  /// @brief Username scelto dall'utente in registrazione (UT.22.1), mostrato all'OP.
  final String username;

  /// @brief Email di accesso.
  final String email;

  /// @brief Stato corrente dell'account (attivo/sospeso).
  UserStatus status;

  /// @brief Nota opzionale (motivo della sospensione).
  final String note;
}

/// @brief Account di Amministrazione Pubblica creato dall'Operatore.
class ApAccount {
  /// @brief Crea un account di Amministrazione Pubblica.
  ApAccount({
    required this.id,
    required this.ente,
    required this.email,
    required this.status,
  });

  /// @brief Costruisce un [ApAccount] da un documento account PA della API.
  /// @param doc Documento account con ruolo PA.
  /// @return L'account PA mappato, o null se privo di identificativo.
  static ApAccount? daApi(Map<String, dynamic> doc) {
    final id = doc['_id']?.toString();
    if (id == null || id.isEmpty) return null;
    final etichetta = doc['nominativo']?.toString();
    return ApAccount(
      id: id,
      ente: (etichetta != null && etichetta.isNotEmpty)
          ? etichetta
          : (doc['username']?.toString() ?? doc['email']?.toString() ?? id),
      email: doc['email']?.toString() ?? '',
      status: doc['password_temporanea'] == true
          ? ApStatus.primoAccesso
          : ApStatus.attivo,
    );
  }

  /// @brief Identificativo dell'account PA.
  final String id;

  /// @brief Nome dell'ente di Amministrazione Pubblica.
  final String ente;

  /// @brief Email istituzionale di accesso.
  final String email;

  /// @brief Stato corrente (attivo / primo accesso in attesa).
  ApStatus status;
}
