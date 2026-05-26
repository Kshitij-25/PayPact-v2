import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'paypact_theme_extension.dart';

/// Warm-minimal palette — same tokens as
/// `lib/design_system/tokens/colors.dart`. Re-exported here so legacy widgets
/// that import `core/theme/app_theme.dart` keep working without churn.
class PaypactColors {
  // Brand — clay accent
  static const primary = Color(0xFFB05A3C);
  static const primaryLight = Color(0xFFEDD9CF);
  static const primaryDark = Color(0xFF7A3A24);

  // Semantic — quiet earth tones
  static const secondary = Color(0xFF5C7B5B); // sage
  static const danger = Color(0xFF9B4736); // muted terracotta
  static const warning = Color(0xFF9A7530); // olive/amber

  // Light surfaces & ink
  static const surface = Color(0xFFF5F2EC); // bone
  static const cardBg = Color(0xFFFAF7F1); // paper
  static const textPrimary = Color(0xFF1F1B16);
  static const textSecondary = Color(0xFF6B6357);
  static const divider = Color(0xFFE2DACA);

  // Dark surfaces & ink
  static const darkBg = Color(0xFF100D09);
  static const darkSurface = Color(0xFF1A1612);
  static const darkCard = Color(0xFF221D17);
  static const darkDivider = Color(0xFF2E2820);
  static const darkTextPrimary = Color(0xFFECE4D2);
  static const darkTextSecondary = Color(0xFF9C9385);
  static const darkInputFill = Color(0xFF1A1612);
}

/// NOTE: the live theme used by the app is `PayPactTheme` in
/// `lib/design_system/theme/paypact_theme.dart`. This class is kept for any
/// legacy callers and mirrors the same warm-minimal palette.
class AppTheme {
  // ── Light ──────────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: PaypactColors.surface,
        colorScheme: const ColorScheme.light(
          primary: PaypactColors.primary,
          onPrimary: Colors.white,
          secondary: PaypactColors.secondary,
          onSecondary: Colors.white,
          error: PaypactColors.danger,
          onError: Colors.white,
          surface: PaypactColors.cardBg,
          onSurface: PaypactColors.textPrimary,
          onSurfaceVariant: PaypactColors.textSecondary,
          outline: PaypactColors.divider,
          outlineVariant: PaypactColors.divider,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: PaypactColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          iconTheme: IconThemeData(color: PaypactColors.textPrimary),
          actionsIconTheme: IconThemeData(color: PaypactColors.textPrimary),
        ),
        dividerTheme: const DividerThemeData(
            color: PaypactColors.divider, thickness: 1),
        extensions: const [PaypactThemeExtension.light],
      );

  // ── Dark ──────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: PaypactColors.darkBg,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC77556),
          onPrimary: Colors.white,
          secondary: Color(0xFF7DA37C),
          onSecondary: Colors.white,
          error: Color(0xFFC46B59),
          onError: Colors.white,
          surface: PaypactColors.darkSurface,
          onSurface: PaypactColors.darkTextPrimary,
          onSurfaceVariant: PaypactColors.darkTextSecondary,
          outline: PaypactColors.darkDivider,
          outlineVariant: PaypactColors.darkDivider,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: PaypactColors.darkTextPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          iconTheme: IconThemeData(color: PaypactColors.darkTextPrimary),
          actionsIconTheme: IconThemeData(color: PaypactColors.darkTextPrimary),
        ),
        dividerTheme: const DividerThemeData(
            color: PaypactColors.darkDivider, thickness: 1),
        extensions: const [PaypactThemeExtension.dark],
      );
}
