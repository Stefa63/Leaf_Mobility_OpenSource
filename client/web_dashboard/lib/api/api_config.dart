/// Configurazione dell'endpoint del backend LEAF (Presentation Tier `/api/v1`).
///
/// La WebDashboard punta al backend esposto via tunnel Cloudflare sul dominio
/// del progetto (`api.leafmobility.org`). Sovrascrivibile a compile-time:
/// `flutter run -d chrome --dart-define=LEAF_API_BASE=...`
/// (es. `http://localhost:8770/api/v1` per il runtime in locale).
library;

/// @brief Base URL delle API client-facing del backend LEAF Mobility.
const String kLeafApiBase = String.fromEnvironment(
  'LEAF_API_BASE',
  defaultValue: 'https://api.leafmobility.org/api/v1',
);

/// @brief Abilita il caricamento automatico dei dati all'apertura delle schermate.
///
/// True in produzione. I widget test che montano una dashboard intera (la quale
/// costruisce le schermate con `autoload` di default) lo impostano a false per
/// evitare chiamate di rete reali (timer pendenti); i test mirati iniettano un
/// repository fittizio e lo lasciano a true.
bool kAutoloadData = true;
