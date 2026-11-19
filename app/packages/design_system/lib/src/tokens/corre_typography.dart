import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Escala tipográfica. Fonte: Plus Jakarta Sans.
abstract final class CorreTypography {
  static const fontFamilyFallback = ['Roboto', 'Arial', 'sans-serif'];

  static TextTheme textTheme(Color ink, Color ink2, {bool useGoogleFonts = true}) {
    final base = TextTheme(
      displaySmall: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, height: 1.15, color: ink),
      headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.2, color: ink),
      headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.25, color: ink),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.3, color: ink),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.35, color: ink),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.35, color: ink),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: ink),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.45, color: ink2),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4, color: ink2),
      labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.2, color: ink),
      labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.2, color: ink2),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: .4, color: ink2),
    );
    return useGoogleFonts ? GoogleFonts.plusJakartaSansTextTheme(base) : base;
  }
}
