/// @file app_version.dart
/// @brief Versione logica unica dell'app mobile (§8 DIRECTIVES — schema
///        `1.0.0.0-alpha.N`).
///
/// Sorgente **unica** del numero di versione mostrato in UI (drawer e
/// impostazioni): evita la deriva tra punti hard-coded indipendenti. Va tenuta
/// allineata al campo `version:` di `pubspec.yaml` ad ogni bump (§8).
library;

/// Versione logica corrente dell'app (formato a 4 segmenti, §8).
/// Mapping pubspec: `1.0.0.0-alpha.31` → `version: 1.0.0-alpha.31+31`.
const String kAppVersion = '1.0.0.0-alpha.31';
