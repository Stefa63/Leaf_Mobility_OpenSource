// Fake del ServizioMappa per i widget test delle console OP/AP.
//
// Il widget GoogleMap richiede una platform view nativa non disponibile in
// `flutter test`: questo fake sostituisce l'istanza di piattaforma con una
// vista inerte, cosi' le dashboard che montano GoogleCityMap restano
// testabili in modo deterministico. Nessuna nuova dipendenza scaricata:
// google_maps_flutter_platform_interface e' gia' transitiva di
// google_maps_flutter (dichiarata nelle dev_dependencies).

import 'package:flutter/services.dart' show PlatformViewCreatedCallback;
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

/// @brief Piattaforma Google Maps fittizia per l'ambiente di test.
///
/// Estende [GoogleMapsFlutterPlatform] sovrascrivendo la sola costruzione
/// della vista: restituisce un [SizedBox] al posto della platform view
/// nativa. Non completando mai la creazione della vista, il controller della
/// mappa non viene istanziato e nessun'altra chiamata di piattaforma viene
/// emessa.
class FakeGoogleMapsPlatform extends GoogleMapsFlutterPlatform {
  /// @brief Costruisce la vista mappa fittizia.
  /// @param creationId identificativo progressivo della vista richiesta.
  /// @param onPlatformViewCreated callback di creazione (mai invocata: il
  ///        controller della mappa non viene cosi' mai istanziato).
  /// @param widgetConfiguration configurazione richiesta dal widget GoogleMap.
  /// @param mapConfiguration opzioni della mappa (ignorate).
  /// @param mapObjects marker/poligoni/cerchi richiesti (ignorati).
  /// @return un [SizedBox.expand] inerte al posto della platform view.
  @override
  Widget buildViewWithConfiguration(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required MapWidgetConfiguration widgetConfiguration,
    MapConfiguration mapConfiguration = const MapConfiguration(),
    MapObjects mapObjects = const MapObjects(),
  }) {
    return const SizedBox.expand();
  }
}

/// @brief Installa il fake come istanza di piattaforma corrente.
///
/// Da invocare in `setUp`/`setUpAll` dei test che montano widget contenenti
/// [GoogleCityMap]/GoogleMap.
void installFakeGoogleMapsPlatform() {
  GoogleMapsFlutterPlatform.instance = FakeGoogleMapsPlatform();
}
