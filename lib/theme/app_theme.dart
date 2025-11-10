import 'package:flutter/material.dart';


ThemeData buildPastelTheme() {
  const pastelBg = Color(0xFFF5F7FB);
  const pastelPrimary = Color(0xFF9AD0EC);
  const pastelAccent = Color.fromARGB(255, 114, 203, 255);
  const pastelText = Color(0xFF274C77);

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: pastelPrimary,
      primary: pastelPrimary,
      secondary: const Color.fromARGB(244, 0, 157, 255),
      background: const Color.fromARGB(255, 255, 255, 255),
      surface: Colors.white,
      brightness: Brightness.light,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(height: 1.25),
    ).apply(
      bodyColor: pastelText,
      displayColor: pastelText,
    ),
    cardTheme: CardThemeData(
      elevation: 1.5,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Color.fromARGB(244, 0, 157, 255),
      foregroundColor: pastelText,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 22,
        letterSpacing: 0.3,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: pastelText.withOpacity(0.95),
      contentTextStyle: const TextStyle(color: Colors.white),
    ),
  );
}
