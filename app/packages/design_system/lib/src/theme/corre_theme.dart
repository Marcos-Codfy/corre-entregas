import 'package:flutter/material.dart';

import '../tokens/corre_colors.dart';
import '../tokens/corre_tokens.dart';
import '../tokens/corre_typography.dart';

/// Tom semântico usado por badges, alertas e marcadores.
enum CorreTone { neutral, brand, accent, success, warning, error, info }

/// Gera os temas claro e escuro a partir dos tokens.
abstract final class CorreTheme {
  static ThemeData light({bool useGoogleFonts = true}) => _build(
    brightness: Brightness.light,
    palette: CorrePalette.light,
    background: CorreRawColors.background,
    surface: CorreRawColors.surface,
    useGoogleFonts: useGoogleFonts,
  );

  static ThemeData dark({bool useGoogleFonts = true}) => _build(
    brightness: Brightness.dark,
    palette: CorrePalette.dark,
    background: CorreRawColors.darkBackground,
    surface: CorreRawColors.darkSurface,
    useGoogleFonts: useGoogleFonts,
  );

  static ThemeData _build({
    required Brightness brightness,
    required CorrePalette palette,
    required Color background,
    required Color surface,
    required bool useGoogleFonts,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: palette.brand,
      onPrimary: Colors.white,
      primaryContainer: palette.brandLight,
      onPrimaryContainer: palette.ink,
      secondary: palette.accent,
      onSecondary: CorreRawColors.ink,
      secondaryContainer: palette.accentLight,
      onSecondaryContainer: palette.ink,
      error: palette.error,
      onError: Colors.white,
      surface: surface,
      onSurface: palette.ink,
      onSurfaceVariant: palette.ink2,
      outline: palette.line,
      outlineVariant: palette.line,
      surfaceContainerLowest: background,
      surfaceContainerLow: background,
      surfaceContainer: surface,
      surfaceContainerHigh: surface,
      surfaceContainerHighest: palette.line,
    );
    final text = CorreTypography.textTheme(palette.ink, palette.ink2, useGoogleFonts: useGoogleFonts);
    final inputBorder = OutlineInputBorder(
      borderRadius: CorreRadius.mdAll,
      borderSide: BorderSide(color: palette.line, width: 1.5),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: text,
      extensions: [palette],
      dividerTheme: DividerThemeData(color: palette.line, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: palette.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: CorreRadius.mdAll,
          side: BorderSide(color: palette.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: CorreSpace.lg, vertical: CorreSpace.md),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(borderSide: BorderSide(color: palette.brand, width: 2)),
        errorBorder: inputBorder.copyWith(borderSide: BorderSide(color: palette.error, width: 1.5)),
        focusedErrorBorder: inputBorder.copyWith(borderSide: BorderSide(color: palette.error, width: 2)),
        labelStyle: text.bodyMedium,
        hintStyle: text.bodyMedium?.copyWith(color: palette.ink3),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: CorreRadius.pillAll),
        side: BorderSide(color: palette.line),
        backgroundColor: surface,
        selectedColor: palette.brandLight,
        labelStyle: text.labelMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: CorreRadius.mdAll),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(CorreRadius.lg))),
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: CorreRadius.lgAll),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: palette.brandLight,
        labelTextStyle: WidgetStatePropertyAll(text.labelSmall),
      ),
      navigationRailTheme: NavigationRailThemeData(backgroundColor: surface, indicatorColor: palette.brandLight),
    );
  }
}

/// Atalhos de acesso ao tema.
extension CorreThemeX on BuildContext {
  CorrePalette get palette => Theme.of(this).extension<CorrePalette>() ?? CorrePalette.light;
  TextTheme get text => Theme.of(this).textTheme;

  /// Cor de primeiro plano e de fundo para um [CorreTone].
  (Color fg, Color bg) toneColors(CorreTone tone) {
    final p = palette;
    return switch (tone) {
      CorreTone.neutral => (p.ink2, p.line),
      CorreTone.brand => (p.brand, p.brandLight),
      CorreTone.accent => (p.ink, p.accentLight),
      CorreTone.success => (p.success, p.success.withValues(alpha: .14)),
      CorreTone.warning => (p.warning, p.warning.withValues(alpha: .16)),
      CorreTone.error => (p.error, p.error.withValues(alpha: .14)),
      CorreTone.info => (p.info, p.info.withValues(alpha: .14)),
    };
  }
}
