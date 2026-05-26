import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tokens/colors.dart';
import '../tokens/radius.dart';
import '../tokens/shadows.dart';
import '../tokens/typography.dart';
import 'paypact_theme_extension.dart';

/// PayPact app theme — warm minimal, light + dark.
class PayPactTheme {
  // ── Light ──────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    const bg = PayPactColors.bgLight;
    const surface = PayPactColors.surfaceLight;
    const surfaceAlt = PayPactColors.surface2Light;
    const border = PayPactColors.borderLight;
    const ink = PayPactColors.textPrimaryLight;
    const ink2 = PayPactColors.textSecondaryLight;
    const ink3 = PayPactColors.textTertiaryLight;

    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      colorScheme: const ColorScheme.light(
        primary: PayPactColors.accent,
        onPrimary: Colors.white,
        primaryContainer: PayPactColors.accentSoft,
        onPrimaryContainer: PayPactColors.accentInk,
        secondary: PayPactColors.positive,
        onSecondary: Colors.white,
        secondaryContainer: PayPactColors.positiveLt,
        onSecondaryContainer: PayPactColors.positive,
        error: PayPactColors.negative,
        onError: Colors.white,
        surface: surface,
        onSurface: ink,
        onSurfaceVariant: ink2,
        outline: border,
        outlineVariant: border,
        surfaceContainerHighest: surfaceAlt,
        surfaceContainerHigh: surface,
        surfaceContainer: surface,
        surfaceContainerLow: bg,
        surfaceContainerLowest: bg,
      ),
      textTheme: _textTheme(ink, ink2, ink3),
      primaryTextTheme: _textTheme(ink, ink2, ink3),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: true,
        iconTheme: const IconThemeData(color: ink),
        actionsIconTheme: const IconThemeData(color: ink),
        titleTextStyle: PayPactTypography.headingMd.copyWith(color: ink),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: PayPactRadius.lg,
          side: const BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: PayPactTypography.bodyMd.copyWith(color: ink3),
        labelStyle: PayPactTypography.bodySm.copyWith(color: ink2),
        floatingLabelStyle:
            PayPactTypography.bodySm.copyWith(color: PayPactColors.accent),
        border: OutlineInputBorder(
          borderRadius: PayPactRadius.md,
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: PayPactRadius.md,
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: PayPactRadius.md,
          borderSide: const BorderSide(color: PayPactColors.accent, width: 1.4),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: bg,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: PayPactRadius.md),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: PayPactTypography.bodyMd
              .copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: PayPactColors.borderStrongLight),
          shape: RoundedRectangleBorder(borderRadius: PayPactRadius.md),
          textStyle: PayPactTypography.bodyMd
              .copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ink,
          textStyle: PayPactTypography.bodyMd
              .copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bg,
        selectedItemColor: ink,
        unselectedItemColor: ink3,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        labelStyle: PayPactTypography.bodySm.copyWith(color: ink),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: PayPactRadius.full),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: ink2,
        textColor: ink,
      ),
      iconTheme: const IconThemeData(color: ink, size: 20),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? ink : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(bg),
        side: const BorderSide(
            color: PayPactColors.borderStrongLight, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: PayPactRadius.sm),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: ink,
        unselectedLabelColor: ink2,
        indicatorColor: ink,
        dividerColor: border,
        labelStyle:
            PayPactTypography.bodyMd.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: PayPactTypography.bodyMd,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: PayPactTypography.headingLg.copyWith(color: ink),
        contentTextStyle: PayPactTypography.bodyMd.copyWith(color: ink2),
        shape: RoundedRectangleBorder(borderRadius: PayPactRadius.lg),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: PayPactTypography.bodySm.copyWith(color: bg),
        shape: RoundedRectangleBorder(borderRadius: PayPactRadius.md),
        behavior: SnackBarBehavior.floating,
      ),
      extensions: const [_lightExtension],
    );
  }

  // ── Dark ──────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    const bg = PayPactColors.bgDark;
    const surface = PayPactColors.surfaceDark;
    const surfaceAlt = PayPactColors.surface2Dark;
    const border = PayPactColors.borderDark;
    const ink = PayPactColors.textPrimaryDark;
    const ink2 = PayPactColors.textSecondaryDark;
    const ink3 = PayPactColors.textTertiaryDark;

    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: PayPactColors.accentDarkMode,
        onPrimary: Colors.white,
        primaryContainer: PayPactColors.accentSoftDark,
        onPrimaryContainer: PayPactColors.accentInkDark,
        secondary: PayPactColors.positiveDark,
        onSecondary: Colors.white,
        secondaryContainer: PayPactColors.positiveDarkLt,
        onSecondaryContainer: PayPactColors.positiveDark,
        error: PayPactColors.negativeDark,
        onError: Colors.white,
        surface: surface,
        onSurface: ink,
        onSurfaceVariant: ink2,
        outline: border,
        outlineVariant: border,
        surfaceContainerHighest: surfaceAlt,
        surfaceContainerHigh: surface,
        surfaceContainer: surface,
        surfaceContainerLow: bg,
        surfaceContainerLowest: bg,
      ),
      textTheme: _textTheme(ink, ink2, ink3),
      primaryTextTheme: _textTheme(ink, ink2, ink3),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        centerTitle: true,
        iconTheme: const IconThemeData(color: ink),
        actionsIconTheme: const IconThemeData(color: ink),
        titleTextStyle: PayPactTypography.headingMd.copyWith(color: ink),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: PayPactRadius.lg,
          side: const BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: PayPactTypography.bodyMd.copyWith(color: ink3),
        labelStyle: PayPactTypography.bodySm.copyWith(color: ink2),
        floatingLabelStyle: PayPactTypography.bodySm
            .copyWith(color: PayPactColors.accentDarkMode),
        border: OutlineInputBorder(
          borderRadius: PayPactRadius.md,
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: PayPactRadius.md,
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: PayPactRadius.md,
          borderSide: const BorderSide(
              color: PayPactColors.accentDarkMode, width: 1.4),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: bg,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: PayPactRadius.md),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: PayPactTypography.bodyMd
              .copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: PayPactColors.borderStrongDark),
          shape: RoundedRectangleBorder(borderRadius: PayPactRadius.md),
          textStyle: PayPactTypography.bodyMd
              .copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ink,
          textStyle: PayPactTypography.bodyMd
              .copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bg,
        selectedItemColor: ink,
        unselectedItemColor: ink3,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        labelStyle: PayPactTypography.bodySm.copyWith(color: ink),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: PayPactRadius.full),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: ink2,
        textColor: ink,
      ),
      iconTheme: const IconThemeData(color: ink, size: 20),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? ink : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(bg),
        side: const BorderSide(
            color: PayPactColors.borderStrongDark, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: PayPactRadius.sm),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: ink,
        unselectedLabelColor: ink2,
        indicatorColor: ink,
        dividerColor: border,
        labelStyle:
            PayPactTypography.bodyMd.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: PayPactTypography.bodyMd,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: PayPactTypography.headingLg.copyWith(color: ink),
        contentTextStyle: PayPactTypography.bodyMd.copyWith(color: ink2),
        shape: RoundedRectangleBorder(borderRadius: PayPactRadius.lg),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: PayPactTypography.bodySm.copyWith(color: bg),
        shape: RoundedRectangleBorder(borderRadius: PayPactRadius.md),
        behavior: SnackBarBehavior.floating,
      ),
      extensions: const [_darkExtension],
    );
  }

  static TextTheme _textTheme(Color ink, Color ink2, Color ink3) {
    final base = GoogleFonts.geistTextTheme();
    return base.copyWith(
      displayLarge: PayPactTypography.displayXl.copyWith(color: ink),
      displayMedium: PayPactTypography.displayLg.copyWith(color: ink),
      displaySmall: PayPactTypography.headingXl.copyWith(color: ink),
      headlineLarge: PayPactTypography.headingXl.copyWith(color: ink),
      headlineMedium: PayPactTypography.headingLg.copyWith(color: ink),
      headlineSmall: PayPactTypography.headingMd.copyWith(color: ink),
      titleLarge: PayPactTypography.headingLg.copyWith(color: ink),
      titleMedium: PayPactTypography.headingMd.copyWith(color: ink),
      titleSmall:
          PayPactTypography.bodyMd.copyWith(color: ink, fontWeight: FontWeight.w600),
      bodyLarge: PayPactTypography.bodyLg.copyWith(color: ink),
      bodyMedium: PayPactTypography.bodyMd.copyWith(color: ink),
      bodySmall: PayPactTypography.bodySm.copyWith(color: ink2),
      labelLarge:
          PayPactTypography.bodyMd.copyWith(color: ink, fontWeight: FontWeight.w500),
      labelMedium: PayPactTypography.label.copyWith(color: ink3),
      labelSmall: PayPactTypography.micro.copyWith(color: ink3),
    );
  }

  // ── Theme extension presets ───────────────────────────────────────
  static const _lightExtension = PayPactThemeExtension(
    bg: PayPactColors.bgLight,
    surface: PayPactColors.surfaceLight,
    surfaceAlt: PayPactColors.surface2Light,
    surface3: PayPactColors.surface3Light,
    border: PayPactColors.borderLight,
    borderStrong: PayPactColors.borderStrongLight,
    ink: PayPactColors.textPrimaryLight,
    ink2: PayPactColors.textSecondaryLight,
    ink3: PayPactColors.textTertiaryLight,
    ink4: PayPactColors.textDisabledLight,
    accent: PayPactColors.accent,
    accentSoft: PayPactColors.accentSoft,
    accentInk: PayPactColors.accentInk,
    positive: PayPactColors.positive,
    positiveSoft: PayPactColors.positiveLt,
    negative: PayPactColors.negative,
    negativeSoft: PayPactColors.negativeLt,
    warn: PayPactColors.pending,
    warnSoft: PayPactColors.pendingLt,
    shadowSm: PayPactShadows.sm,
    shadowMd: PayPactShadows.md,
    shadowLg: PayPactShadows.lg,
    shadowAccent: PayPactShadows.accent,
  );

  static const _darkExtension = PayPactThemeExtension(
    bg: PayPactColors.bgDark,
    surface: PayPactColors.surfaceDark,
    surfaceAlt: PayPactColors.surface2Dark,
    surface3: PayPactColors.surface3Dark,
    border: PayPactColors.borderDark,
    borderStrong: PayPactColors.borderStrongDark,
    ink: PayPactColors.textPrimaryDark,
    ink2: PayPactColors.textSecondaryDark,
    ink3: PayPactColors.textTertiaryDark,
    ink4: PayPactColors.textDisabledDark,
    accent: PayPactColors.accentDarkMode,
    accentSoft: PayPactColors.accentSoftDark,
    accentInk: PayPactColors.accentInkDark,
    positive: PayPactColors.positiveDark,
    positiveSoft: PayPactColors.positiveDarkLt,
    negative: PayPactColors.negativeDark,
    negativeSoft: PayPactColors.negativeDarkLt,
    warn: PayPactColors.pendingDark,
    warnSoft: PayPactColors.pendingDarkLt,
    shadowSm: PayPactShadows.smDark,
    shadowMd: PayPactShadows.mdDark,
    shadowLg: PayPactShadows.lgDark,
    shadowAccent: PayPactShadows.accent,
  );
}
