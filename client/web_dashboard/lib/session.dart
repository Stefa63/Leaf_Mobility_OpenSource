/// Ruoli con accesso alla WebDashboard (RBAC). IIN-5.
enum DashboardRole { operator, publicAdmin }

/// @brief Stato di sessione della dashboard (mock pre-backend).
///
/// Conserva ruolo ed email scelti in fase di login. Finche' l'`api_gateway_
/// sicurezza` non sara' disponibile, l'autenticazione e' simulata: nessun
/// token JWT reale viene emesso. Semplice contenitore osservabile, niente MVC.
class Session {
  Session._();

  static DashboardRole role = DashboardRole.operator;
  static String email = '';

  /// True quando il ruolo attivo e' Amministrazione Pubblica.
  static bool get isPublicAdmin => role == DashboardRole.publicAdmin;
}
