/// Configurazione dell'endpoint del backend LEAF (Presentation Tier `/api/v1`).
///
/// Il valore di default punta al backend esposto via tunnel Cloudflare sul
/// dominio del progetto (`api.leafmobility.org`), raggiungibile da internet.
/// Sovrascrivibile a compile-time: `flutter run --dart-define=LEAF_API_BASE=...`
/// (es. `http://10.0.2.2:8770/api/v1` per l'emulatore Android in locale).
library;

/// @brief Base URL delle API client-facing del backend LEAF Mobility.
const String kLeafApiBase = String.fromEnvironment(
  'LEAF_API_BASE',
  defaultValue: 'https://api.leafmobility.org/api/v1',
);
