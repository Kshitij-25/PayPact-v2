import 'package:flutter/material.dart';

/// Custom theme colors accessible via:
///   Theme.of(context).extension PaypactThemeExtension()!
///   or the shorthand: context.pt  (see BuildContext extension below)
@immutable
class PaypactThemeExtension extends ThemeExtension<PaypactThemeExtension> {
  const PaypactThemeExtension({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.secondary,
    required this.danger,
    required this.warning,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.surface,
    required this.cardBg,
    required this.inputFill,
  });

  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color secondary;
  final Color danger;
  final Color warning;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color surface;
  final Color cardBg;
  final Color inputFill;

  @override
  PaypactThemeExtension copyWith({
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    Color? secondary,
    Color? danger,
    Color? warning,
    Color? textPrimary,
    Color? textSecondary,
    Color? divider,
    Color? surface,
    Color? cardBg,
    Color? inputFill,
  }) {
    return PaypactThemeExtension(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryDark: primaryDark ?? this.primaryDark,
      secondary: secondary ?? this.secondary,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      divider: divider ?? this.divider,
      surface: surface ?? this.surface,
      cardBg: cardBg ?? this.cardBg,
      inputFill: inputFill ?? this.inputFill,
    );
  }

  @override
  PaypactThemeExtension lerp(PaypactThemeExtension? other, double t) {
    if (other == null) return this;
    return PaypactThemeExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
    );
  }

  // ── Convenience presets ───────────────────────────────────────────────────

  static const light = PaypactThemeExtension(
    primary: Color(0xFF4F46E5),
    primaryLight: Color(0xFF818CF8),
    primaryDark: Color(0xFF3730A3),
    secondary: Color(0xFF10B981),
    danger: Color(0xFFEF4444),
    warning: Color(0xFFF59E0B),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF6B7280),
    divider: Color(0xFFE5E7EB),
    surface: Color(0xFFF9FAFB),
    cardBg: Color(0xFFFFFFFF),
    inputFill: Color(0xFFFFFFFF),
  );

  static const dark = PaypactThemeExtension(
    primary: Color(0xFF818CF8),
    primaryLight: Color(0xFF818CF8),
    primaryDark: Color(0xFF3730A3),
    secondary: Color(0xFF10B981),
    danger: Color(0xFFEF4444),
    warning: Color(0xFFF59E0B),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    divider: Color(0xFF334155),
    surface: Color(0xFF0F172A),
    cardBg: Color(0xFF1E293B),
    inputFill: Color(0xFF1E293B),
  );
}

/// Shorthand: `context.pt.primary` instead of
/// `Theme.of(context).extension<PaypactThemeExtension>()!.primary`
extension PaypactThemeContext on BuildContext {
  PaypactThemeExtension get pt =>
      Theme.of(this).extension<PaypactThemeExtension>()!;
}
