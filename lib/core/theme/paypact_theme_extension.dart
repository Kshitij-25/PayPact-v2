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
    primary: Color(0xFFB05A3C), // clay
    primaryLight: Color(0xFFEDD9CF),
    primaryDark: Color(0xFF7A3A24),
    secondary: Color(0xFF5C7B5B), // sage
    danger: Color(0xFF9B4736), // muted terracotta
    warning: Color(0xFF9A7530), // olive
    textPrimary: Color(0xFF1F1B16),
    textSecondary: Color(0xFF6B6357),
    divider: Color(0xFFE2DACA),
    surface: Color(0xFFF5F2EC), // bone
    cardBg: Color(0xFFFAF7F1), // paper
    inputFill: Color(0xFFFAF7F1),
  );

  static const dark = PaypactThemeExtension(
    primary: Color(0xFFC77556),
    primaryLight: Color(0xFF3A2218),
    primaryDark: Color(0xFFE6A48A),
    secondary: Color(0xFF7DA37C),
    danger: Color(0xFFC46B59),
    warning: Color(0xFFC29A4F),
    textPrimary: Color(0xFFECE4D2),
    textSecondary: Color(0xFF9C9385),
    divider: Color(0xFF2E2820),
    surface: Color(0xFF100D09),
    cardBg: Color(0xFF1A1612),
    inputFill: Color(0xFF1A1612),
  );
}

/// Shorthand: `context.pt.primary` instead of
/// `Theme.of(context).extension<PaypactThemeExtension>()!.primary`
extension PaypactThemeContext on BuildContext {
  PaypactThemeExtension get pt =>
      Theme.of(this).extension<PaypactThemeExtension>()!;
}
