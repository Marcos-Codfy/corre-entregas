import 'package:flutter/material.dart';

/// Paleta base do Corre. Valores brutos; use pelo tema ([CorrePalette]).
abstract final class CorreRawColors {
  static const brand = Color(0xFF0E7C66);
  static const brandDark = Color(0xFF0A5C4C);
  static const brandLight = Color(0xFFE3F4EF);
  static const accent = Color(0xFFF2A93B);
  static const accentLight = Color(0xFFFDF1DC);

  static const ink = Color(0xFF16202A);
  static const ink2 = Color(0xFF4A5866);
  static const ink3 = Color(0xFF8695A3);
  static const background = Color(0xFFEEF1F4);
  static const surface = Color(0xFFFFFFFF);
  static const line = Color(0xFFE2E7EC);

  static const success = Color(0xFF1F9D55);
  static const warning = Color(0xFFD98E04);
  static const error = Color(0xFFD64545);
  static const info = Color(0xFF2F6FDE);

  // Modo escuro
  static const darkBackground = Color(0xFF0F151B);
  static const darkSurface = Color(0xFF18212A);
  static const darkLine = Color(0xFF2A3541);
  static const darkInk = Color(0xFFE8EDF2);
  static const darkInk2 = Color(0xFFAAB6C2);
  static const darkInk3 = Color(0xFF75838F);
  static const darkBrand = Color(0xFF2BB394);
  static const darkBrandLight = Color(0xFF123A32);
  static const darkAccentLight = Color(0xFF3A2C12);
}

/// Cores semânticas extras que o Material não cobre (status, texto secundário etc.).
@immutable
class CorrePalette extends ThemeExtension<CorrePalette> {
  const CorrePalette({
    required this.brand,
    required this.brandLight,
    required this.accent,
    required this.accentLight,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.line,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
  });

  final Color brand, brandLight, accent, accentLight;
  final Color ink, ink2, ink3, line;
  final Color success, warning, error, info;

  static const light = CorrePalette(
    brand: CorreRawColors.brand,
    brandLight: CorreRawColors.brandLight,
    accent: CorreRawColors.accent,
    accentLight: CorreRawColors.accentLight,
    ink: CorreRawColors.ink,
    ink2: CorreRawColors.ink2,
    ink3: CorreRawColors.ink3,
    line: CorreRawColors.line,
    success: CorreRawColors.success,
    warning: CorreRawColors.warning,
    error: CorreRawColors.error,
    info: CorreRawColors.info,
  );

  static const dark = CorrePalette(
    brand: CorreRawColors.darkBrand,
    brandLight: CorreRawColors.darkBrandLight,
    accent: CorreRawColors.accent,
    accentLight: CorreRawColors.darkAccentLight,
    ink: CorreRawColors.darkInk,
    ink2: CorreRawColors.darkInk2,
    ink3: CorreRawColors.darkInk3,
    line: CorreRawColors.darkLine,
    success: Color(0xFF3CC57A),
    warning: Color(0xFFF0B13A),
    error: Color(0xFFF06A6A),
    info: Color(0xFF6A9BF0),
  );

  @override
  CorrePalette copyWith({Color? brand, Color? accent}) => CorrePalette(
        brand: brand ?? this.brand,
        brandLight: brandLight,
        accent: accent ?? this.accent,
        accentLight: accentLight,
        ink: ink,
        ink2: ink2,
        ink3: ink3,
        line: line,
        success: success,
        warning: warning,
        error: error,
        info: info,
      );

  @override
  CorrePalette lerp(ThemeExtension<CorrePalette>? other, double t) {
    if (other is! CorrePalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return CorrePalette(
      brand: l(brand, other.brand),
      brandLight: l(brandLight, other.brandLight),
      accent: l(accent, other.accent),
      accentLight: l(accentLight, other.accentLight),
      ink: l(ink, other.ink),
      ink2: l(ink2, other.ink2),
      ink3: l(ink3, other.ink3),
      line: l(line, other.line),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      error: l(error, other.error),
      info: l(info, other.info),
    );
  }
}
