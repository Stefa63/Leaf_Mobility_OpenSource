import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// @brief Palette e tema della WebDashboard LEAF Mobility.
///
/// Riusa la stessa identita' cromatica di [AppMobileUtente] (verde minimalista
/// su beige) per coerenza visiva tra i client, estendendola con gli accenti di
/// ruolo (OP / AP) e i colori di stato della flotta usati dalle dashboard
/// operative. IIN-2 (usabilita', alto contrasto).
class AppTheme {
  // ── Palette base (allineata ad AppMobileUtente) ───────────────────────────
  static const Color backgroundBeige = Color(0xFFFCFBF7);
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color darkGreen = Color(0xFF2E7D32);
  static const Color accentBrown = Color(0xFF795548);
  static const Color textDark = Color(0xFF333333);
  static const Color textGrey = Color(0xFF6E6E6E);
  static const Color surfaceColor = Color(0xFFF1F8F1);

  // ── Accenti di ruolo ──────────────────────────────────────────────────────
  /// Operatore del Servizio (OP): blu operativo / tattico.
  static const Color opAccent = Color(0xFF1565C0);

  /// Amministrazione Pubblica (AP): teal istituzionale.
  static const Color apAccent = Color(0xFF00897B);

  // ── Colori di stato flotta (condivisi OP) ────────────────────────────────
  static const Color statusAvailable = Color(0xFF43A047);
  static const Color statusInUse = Color(0xFF1E88E5);
  static const Color statusMaintenance = Color(0xFFE53935);
  static const Color statusLowBattery = Color(0xFFF9A825);

  // ── Colori semantici allarmi ──────────────────────────────────────────────
  static const Color alarmCritical = Color(0xFFD32F2F);
  static const Color alarmWarning = Color(0xFFF57C00);
  static const Color alarmInfo = Color(0xFFFBC02D);

  // ── Mappa schematica ──────────────────────────────────────────────────────
  static const Color mapLand = Color(0xFFEDEFE9);
  static const Color mapSea = Color(0xFFD9E8EC);
  static const Color mapRoad = Color(0xFFFFFFFF);
  static const Color mapDistrict = Color(0xFFE3E7DD);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: backgroundBeige,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        surface: backgroundBeige,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        bodyLarge: GoogleFonts.inter(color: textDark),
        bodyMedium: GoogleFonts.inter(color: textDark),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        titleTextStyle: GoogleFonts.inter(
          color: textDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 1,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withAlpha(18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
