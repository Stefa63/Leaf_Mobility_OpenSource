import 'package:flutter/foundation.dart';

import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/sos_repository.dart';

/// @brief Segnalazione di emergenza SOS in coda per l'operatore (UT.20/IIN-18, OP.08).
///
/// Mappa il documento di `/api/v1/sos`: l'etichetta [utente] è già risolta lato
/// server (nominativo o `@username`), così la coda non mostra l'id grezzo.
class SosSegnalazione {
  /// @brief Costruisce una segnalazione SOS della coda operatore.
  const SosSegnalazione({
    required this.id,
    required this.utente,
    required this.stato,
    this.zona,
    this.idCorsa,
    this.timestamp,
  });

  /// @brief Costruisce una [SosSegnalazione] dal documento della API.
  /// @param doc Documento segnalazione (`/api/v1/sos`).
  /// @return La segnalazione mappata, o null se priva di identificativo.
  static SosSegnalazione? daApi(Map<String, dynamic> doc) {
    final id = doc['_id']?.toString();
    if (id == null || id.isEmpty) return null;
    final nominativo = doc['nominativo']?.toString();
    final username = doc['username']?.toString();
    final etichetta = (nominativo != null && nominativo.isNotEmpty)
        ? nominativo
        : (username != null && username.isNotEmpty)
        ? '@$username'
        : (doc['id_utente']?.toString() ?? '—');
    final lat = (doc['lat'] as num?)?.toDouble();
    final lon = (doc['lon'] as num?)?.toDouble();
    final zona = (lat != null && lon != null)
        ? '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}'
        : null;
    return SosSegnalazione(
      id: id,
      utente: etichetta,
      stato: doc['stato']?.toString() ?? 'inoltrata',
      zona: zona,
      idCorsa: doc['id_corsa']?.toString(),
      timestamp: doc['timestamp']?.toString(),
    );
  }

  /// @brief Identificativo della segnalazione.
  final String id;

  /// @brief Etichetta leggibile dell'utente che ha attivato l'SOS.
  final String utente;

  /// @brief Stato corrente (inoltrata / presa_in_carico / chiusa).
  final String stato;

  /// @brief Posizione "lat, lon" della segnalazione (null se assente).
  final String? zona;

  /// @brief Corsa correlata, se l'SOS è partito durante un noleggio.
  final String? idCorsa;

  /// @brief Timestamp ISO-8601 della segnalazione.
  final String? timestamp;
}

/// @brief Stato osservabile della coda SOS alimentato da `/api/v1/sos` (OP.08, UT.20).
///
/// La home dell'Operatore osserva [sos] tramite [ValueListenableBuilder] per
/// alimentare la coda allarmi SOS in tempo reale (stesso approccio di
/// [AlertsStore], nessun MVC). In assenza di rete (IIN-6) la lista resta vuota e
/// [offline] passa a true.
class SosStore {
  SosStore._();

  /// Segnalazioni SOS ancora aperte (vuota finché non caricate o offline).
  static final ValueNotifier<List<SosSegnalazione>> sos =
      ValueNotifier<List<SosSegnalazione>>(const []);

  /// True quando l'ultimo caricamento è fallito (backend non raggiungibile).
  static final ValueNotifier<bool> offline = ValueNotifier<bool>(false);

  /// Caricamento in corso, per evitare richieste sovrapposte.
  static bool _inCorso = false;

  /// @brief Carica la coda SOS dal backend (solo segnalazioni non chiuse).
  /// @param repo Repository da usare (iniettabile nei test).
  static Future<void> carica({SosApi? repo}) async {
    if (_inCorso) return;
    _inCorso = true;
    try {
      final docs = await (repo ?? sosRepository).coda();
      sos.value = docs
          .map(SosSegnalazione.daApi)
          .whereType<SosSegnalazione>()
          .where((s) => s.stato != 'chiusa')
          .toList(growable: false);
      offline.value = false;
    } on LeafApiException {
      sos.value = const [];
      offline.value = true;
    } finally {
      _inCorso = false;
    }
  }

  /// @brief Aggiorna lo stato di una segnalazione e ricarica la coda (OP.08).
  /// @param id Id della segnalazione.
  /// @param stato Nuovo stato (presa_in_carico/chiusa).
  /// @param repo Repository da usare (iniettabile nei test).
  static Future<void> aggiornaStato(
    String id,
    String stato, {
    SosApi? repo,
  }) async {
    await (repo ?? sosRepository).aggiornaStato(id, stato);
    await carica(repo: repo);
  }
}
