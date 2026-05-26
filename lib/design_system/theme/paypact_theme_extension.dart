import 'package:flutter/material.dart';

/// Design-system theme extension: holds the semantic + surface tokens that
/// don't live in [ColorScheme]. Access via `Theme.of(context).extension<…>()`
/// or the `context.pt` shorthand below.
@immutable
class PayPactThemeExtension extends ThemeExtension<PayPactThemeExtension> {
  const PayPactThemeExtension({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.surface3,
    required this.border,
    required this.borderStrong,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.ink4,
    required this.accent,
    required this.accentSoft,
    required this.accentInk,
    required this.positive,
    required this.positiveSoft,
    required this.negative,
    required this.negativeSoft,
    required this.warn,
    required this.warnSoft,
    required this.shadowSm,
    required this.shadowMd,
    required this.shadowLg,
    required this.shadowAccent,
  });

  // Surfaces
  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color surface3;
  final Color border;
  final Color borderStrong;

  // Ink
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color ink4;

  // Accent (clay)
  final Color accent;
  final Color accentSoft;
  final Color accentInk;

  // Semantic — quiet earth tones
  final Color positive;
  final Color positiveSoft;
  final Color negative;
  final Color negativeSoft;
  final Color warn;
  final Color warnSoft;

  // Shadows
  final List<BoxShadow> shadowSm;
  final List<BoxShadow> shadowMd;
  final List<BoxShadow> shadowLg;
  final List<BoxShadow> shadowAccent;

  // ── Back-compat shims ────────────────────────────────────────────────
  // Legacy widgets used these names; keep them mapped to the closest token.
  Color get positiveLt => positiveSoft;
  Color get negativeLt => negativeSoft;
  Color get pending => warn;
  Color get pendingLt => warnSoft;
  Color get info => ink2;
  Color get accentLight => accentSoft;
  Color get accentDark => accentInk;

  @override
  PayPactThemeExtension copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceAlt,
    Color? surface3,
    Color? border,
    Color? borderStrong,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? ink4,
    Color? accent,
    Color? accentSoft,
    Color? accentInk,
    Color? positive,
    Color? positiveSoft,
    Color? negative,
    Color? negativeSoft,
    Color? warn,
    Color? warnSoft,
    List<BoxShadow>? shadowSm,
    List<BoxShadow>? shadowMd,
    List<BoxShadow>? shadowLg,
    List<BoxShadow>? shadowAccent,
  }) {
    return PayPactThemeExtension(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      surface3: surface3 ?? this.surface3,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      ink4: ink4 ?? this.ink4,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      accentInk: accentInk ?? this.accentInk,
      positive: positive ?? this.positive,
      positiveSoft: positiveSoft ?? this.positiveSoft,
      negative: negative ?? this.negative,
      negativeSoft: negativeSoft ?? this.negativeSoft,
      warn: warn ?? this.warn,
      warnSoft: warnSoft ?? this.warnSoft,
      shadowSm: shadowSm ?? this.shadowSm,
      shadowMd: shadowMd ?? this.shadowMd,
      shadowLg: shadowLg ?? this.shadowLg,
      shadowAccent: shadowAccent ?? this.shadowAccent,
    );
  }

  @override
  PayPactThemeExtension lerp(PayPactThemeExtension? other, double t) {
    if (other == null) return this;
    return PayPactThemeExtension(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      surface3: Color.lerp(surface3, other.surface3, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      ink3: Color.lerp(ink3, other.ink3, t)!,
      ink4: Color.lerp(ink4, other.ink4, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      positiveSoft: Color.lerp(positiveSoft, other.positiveSoft, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      negativeSoft: Color.lerp(negativeSoft, other.negativeSoft, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      warnSoft: Color.lerp(warnSoft, other.warnSoft, t)!,
      shadowSm: BoxShadow.lerpList(shadowSm, other.shadowSm, t) ?? const [],
      shadowMd: BoxShadow.lerpList(shadowMd, other.shadowMd, t) ?? const [],
      shadowLg: BoxShadow.lerpList(shadowLg, other.shadowLg, t) ?? const [],
      shadowAccent:
          BoxShadow.lerpList(shadowAccent, other.shadowAccent, t) ?? const [],
    );
  }
}

extension PayPactThemeContext on BuildContext {
  PayPactThemeExtension get pt =>
      Theme.of(this).extension<PayPactThemeExtension>()!;
}
