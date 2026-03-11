import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'paypact_theme_extension.dart';

class PaypactColors {
  // Brand
  static const primary = Color(0xFF4F46E5); // Indigo 600
  static const primaryLight = Color(0xFF818CF8); // Indigo 400
  static const primaryDark = Color(0xFF3730A3); // Indigo 800
  static const secondary = Color(0xFF10B981); // Emerald 500
  static const danger = Color(0xFFEF4444); // Red 500
  static const warning = Color(0xFFF59E0B); // Amber 500

  // Light
  static const surface = Color(0xFFF9FAFB); // Gray 50
  static const cardBg = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF111827); // Gray 900
  static const textSecondary = Color(0xFF6B7280); // Gray 500
  static const divider = Color(0xFFE5E7EB); // Gray 200

  // Dark
  static const darkBg = Color(0xFF0F172A); // Slate 900
  static const darkSurface = Color(0xFF1E293B); // Slate 800
  static const darkCard = Color(0xFF334155); // Slate 700
  static const darkDivider = Color(0xFF334155); // Slate 700
  static const darkTextPrimary = Color(0xFFF1F5F9); // Slate 100
  static const darkTextSecondary = Color(0xFF94A3B8); // Slate 400
  static const darkInputFill = Color(0xFF1E293B); // Slate 800
}

class AppTheme {
  // ── Light ──────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: PaypactColors.surface,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: PaypactColors.primary,
          onPrimary: Colors.white,
          secondary: PaypactColors.secondary,
          onSecondary: Colors.white,
          error: PaypactColors.danger,
          onError: Colors.white,
          surface: PaypactColors.surface,
          onSurface: PaypactColors.textPrimary,
          onSurfaceVariant: PaypactColors.textSecondary,
          outline: PaypactColors.divider,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: PaypactColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          iconTheme: IconThemeData(color: PaypactColors.textPrimary),
          actionsIconTheme: IconThemeData(color: PaypactColors.textPrimary),
          titleTextStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: PaypactColors.textPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: PaypactColors.cardBg,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: PaypactColors.divider),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge:
              TextStyle(color: PaypactColors.textPrimary, fontFamily: 'Inter'),
          displayMedium:
              TextStyle(color: PaypactColors.textPrimary, fontFamily: 'Inter'),
          displaySmall:
              TextStyle(color: PaypactColors.textPrimary, fontFamily: 'Inter'),
          headlineLarge:
              TextStyle(color: PaypactColors.textPrimary, fontFamily: 'Inter'),
          headlineMedium:
              TextStyle(color: PaypactColors.textPrimary, fontFamily: 'Inter'),
          headlineSmall:
              TextStyle(color: PaypactColors.textPrimary, fontFamily: 'Inter'),
          titleLarge: TextStyle(
              color: PaypactColors.textPrimary,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600),
          titleMedium: TextStyle(
              color: PaypactColors.textPrimary,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500),
          titleSmall: TextStyle(
              color: PaypactColors.textPrimary,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500),
          bodyLarge:
              TextStyle(color: PaypactColors.textPrimary, fontFamily: 'Inter'),
          bodyMedium:
              TextStyle(color: PaypactColors.textPrimary, fontFamily: 'Inter'),
          bodySmall: TextStyle(
              color: PaypactColors.textSecondary, fontFamily: 'Inter'),
          labelLarge: TextStyle(
              color: PaypactColors.textPrimary,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500),
          labelMedium: TextStyle(
              color: PaypactColors.textSecondary, fontFamily: 'Inter'),
          labelSmall: TextStyle(
              color: PaypactColors.textSecondary, fontFamily: 'Inter'),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: const TextStyle(
              color: PaypactColors.textSecondary, fontFamily: 'Inter'),
          labelStyle: const TextStyle(
              color: PaypactColors.textSecondary, fontFamily: 'Inter'),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: PaypactColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: PaypactColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: PaypactColors.primary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: PaypactColors.primary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
                fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: PaypactColors.textPrimary,
            side: const BorderSide(color: PaypactColors.divider, width: 1.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: PaypactColors.primary),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: PaypactColors.primary,
          unselectedItemColor: PaypactColors.textSecondary,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(
              fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 12),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF3F4F6),
          labelStyle: const TextStyle(
              color: PaypactColors.textSecondary, fontFamily: 'Inter'),
          side: const BorderSide(color: PaypactColors.divider),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: SegmentedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: PaypactColors.textSecondary,
            selectedForegroundColor: PaypactColors.primary,
            selectedBackgroundColor:
                PaypactColors.primary.withValues(alpha: 0.1),
            side: const BorderSide(color: PaypactColors.divider),
            textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13),
          ),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.white,
          textStyle: const TextStyle(
              color: PaypactColors.textPrimary, fontFamily: 'Inter'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: PaypactColors.divider),
          ),
          elevation: 4,
        ),
        dividerTheme:
            const DividerThemeData(color: PaypactColors.divider, thickness: 1),
        listTileTheme: const ListTileThemeData(
          iconColor: PaypactColors.textSecondary,
          textColor: PaypactColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: PaypactColors.textPrimary),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? PaypactColors.primary
                  : Colors.transparent),
          side: const BorderSide(color: PaypactColors.divider, width: 1.5),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: PaypactColors.primary,
          unselectedLabelColor: PaypactColors.textSecondary,
          indicatorColor: PaypactColors.primary,
          dividerColor: PaypactColors.divider,
          labelStyle: TextStyle(
              fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 14),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: const TextStyle(
              color: PaypactColors.textPrimary,
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600),
          contentTextStyle: const TextStyle(
              color: PaypactColors.textSecondary,
              fontFamily: 'Inter',
              fontSize: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: PaypactColors.textPrimary,
          contentTextStyle:
              const TextStyle(color: Colors.white, fontFamily: 'Inter'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          behavior: SnackBarBehavior.floating,
        ),
        extensions: const [PaypactThemeExtension.light],
      );

  // ── Dark ───────────────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: PaypactColors.darkBg,

        // Use ColorScheme.dark() so every unspecified role gets a sensible
        // dark-mode default. The low-level ColorScheme() constructor leaves
        // missing roles as opaque black, making text invisible in Material 3
        // widgets that read surfaceContainer, onSurfaceVariant, etc.
        colorScheme: ColorScheme.dark(
          primary: PaypactColors.primaryLight,
          onPrimary: Colors.white,
          primaryContainer: PaypactColors.primaryDark,
          onPrimaryContainer: PaypactColors.darkTextPrimary,
          secondary: PaypactColors.secondary,
          onSecondary: Colors.white,
          secondaryContainer: const Color(0xFF065F46), // Emerald 900
          onSecondaryContainer: const Color(0xFFD1FAE5), // Emerald 100
          error: PaypactColors.danger,
          onError: Colors.white,
          surface: PaypactColors.darkBg,
          onSurface: PaypactColors.darkTextPrimary,
          onSurfaceVariant: PaypactColors.darkTextSecondary,
          outline: PaypactColors.darkDivider,
          outlineVariant: const Color(0xFF1E293B),
          surfaceContainerHighest: PaypactColors.darkCard,
          surfaceContainerHigh: PaypactColors.darkSurface,
          surfaceContainer: PaypactColors.darkSurface,
          surfaceContainerLow: PaypactColors.darkBg,
          surfaceContainerLowest: PaypactColors.darkBg,
          inverseSurface: PaypactColors.darkTextPrimary,
          onInverseSurface: PaypactColors.darkBg,
          inversePrimary: PaypactColors.primary,
          scrim: Colors.black,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: PaypactColors.darkSurface,
          foregroundColor: PaypactColors.darkTextPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          iconTheme: IconThemeData(color: PaypactColors.darkTextPrimary),
          actionsIconTheme: IconThemeData(color: PaypactColors.darkTextPrimary),
          titleTextStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: PaypactColors.darkTextPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: PaypactColors.darkSurface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: PaypactColors.darkDivider),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              color: PaypactColors.darkTextPrimary, fontFamily: 'Inter'),
          displayMedium: TextStyle(
              color: PaypactColors.darkTextPrimary, fontFamily: 'Inter'),
          displaySmall: TextStyle(
              color: PaypactColors.darkTextPrimary, fontFamily: 'Inter'),
          headlineLarge: TextStyle(
              color: PaypactColors.darkTextPrimary, fontFamily: 'Inter'),
          headlineMedium: TextStyle(
              color: PaypactColors.darkTextPrimary, fontFamily: 'Inter'),
          headlineSmall: TextStyle(
              color: PaypactColors.darkTextPrimary, fontFamily: 'Inter'),
          titleLarge: TextStyle(
              color: PaypactColors.darkTextPrimary,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600),
          titleMedium: TextStyle(
              color: PaypactColors.darkTextPrimary,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500),
          titleSmall: TextStyle(
              color: PaypactColors.darkTextPrimary,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(
              color: PaypactColors.darkTextPrimary, fontFamily: 'Inter'),
          bodyMedium: TextStyle(
              color: PaypactColors.darkTextPrimary, fontFamily: 'Inter'),
          bodySmall: TextStyle(
              color: PaypactColors.darkTextSecondary, fontFamily: 'Inter'),
          labelLarge: TextStyle(
              color: PaypactColors.darkTextPrimary,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500),
          labelMedium: TextStyle(
              color: PaypactColors.darkTextSecondary, fontFamily: 'Inter'),
          labelSmall: TextStyle(
              color: PaypactColors.darkTextSecondary, fontFamily: 'Inter'),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: PaypactColors.darkInputFill,
          hintStyle: const TextStyle(
              color: PaypactColors.darkTextSecondary, fontFamily: 'Inter'),
          labelStyle: const TextStyle(
              color: PaypactColors.darkTextSecondary, fontFamily: 'Inter'),
          floatingLabelStyle: const TextStyle(
              color: PaypactColors.primaryLight, fontFamily: 'Inter'),
          prefixIconColor: PaypactColors.darkTextSecondary,
          suffixIconColor: PaypactColors.darkTextSecondary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: PaypactColors.darkDivider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: PaypactColors.darkDivider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: PaypactColors.primaryLight, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: PaypactColors.primaryLight,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
                fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: PaypactColors.darkTextPrimary,
            side:
                const BorderSide(color: PaypactColors.darkDivider, width: 1.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style:
              TextButton.styleFrom(foregroundColor: PaypactColors.primaryLight),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: PaypactColors.darkSurface,
          selectedItemColor: PaypactColors.primaryLight,
          unselectedItemColor: PaypactColors.darkTextSecondary,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(
              fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 12),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: PaypactColors.darkCard,
          labelStyle: const TextStyle(
              color: PaypactColors.darkTextSecondary, fontFamily: 'Inter'),
          side: const BorderSide(color: PaypactColors.darkDivider),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: SegmentedButton.styleFrom(
            backgroundColor: PaypactColors.darkSurface,
            foregroundColor: PaypactColors.darkTextSecondary,
            selectedForegroundColor: PaypactColors.primaryLight,
            selectedBackgroundColor:
                PaypactColors.primaryLight.withValues(alpha: 0.15),
            side: const BorderSide(color: PaypactColors.darkDivider),
            textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13),
          ),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: PaypactColors.darkSurface,
          textStyle: const TextStyle(
              color: PaypactColors.darkTextPrimary, fontFamily: 'Inter'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: PaypactColors.darkDivider),
          ),
          elevation: 4,
        ),
        dividerTheme: const DividerThemeData(
            color: PaypactColors.darkDivider, thickness: 1),
        listTileTheme: const ListTileThemeData(
          iconColor: PaypactColors.darkTextSecondary,
          textColor: PaypactColors.darkTextPrimary,
        ),
        iconTheme: const IconThemeData(color: PaypactColors.darkTextPrimary),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? PaypactColors.primaryLight
                  : Colors.transparent),
          side: const BorderSide(color: PaypactColors.darkDivider, width: 1.5),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: PaypactColors.primaryLight,
          unselectedLabelColor: PaypactColors.darkTextSecondary,
          indicatorColor: PaypactColors.primaryLight,
          dividerColor: PaypactColors.darkDivider,
          labelStyle: TextStyle(
              fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 14),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: PaypactColors.darkSurface,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: const TextStyle(
              color: PaypactColors.darkTextPrimary,
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600),
          contentTextStyle: const TextStyle(
              color: PaypactColors.darkTextSecondary,
              fontFamily: 'Inter',
              fontSize: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: PaypactColors.darkCard,
          contentTextStyle:
              const TextStyle(color: Colors.white, fontFamily: 'Inter'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          behavior: SnackBarBehavior.floating,
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          textStyle: const TextStyle(
              color: PaypactColors.darkTextPrimary, fontFamily: 'Inter'),
          menuStyle: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(PaypactColors.darkCard),
            surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
            side: WidgetStatePropertyAll(
              BorderSide(color: PaypactColors.darkDivider),
            ),
            shape: const WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
        ),
        extensions: const [PaypactThemeExtension.dark],
      );
}
