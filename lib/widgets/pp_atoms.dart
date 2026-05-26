// Shared atoms for the PayPact v2 redesign.
// Drop-in: import 'package:paypact/widgets/pp_atoms.dart';

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/spacing.dart';
import 'package:paypact/design_system/tokens/typography.dart';

// ─────────────────────────────────────────────────────────────────────
// PpAvatar — initials disc, deterministic palette from name hash.
// ─────────────────────────────────────────────────────────────────────
class PpAvatar extends StatelessWidget {
  const PpAvatar({
    super.key,
    required this.name,
    this.size = 36,
    this.border,
  });

  final String name;
  final double size;
  final Color? border;

  static const _palettes = <List<Color>>[
    [Color(0xFFEDD9CF), Color(0xFF7A3A24)], // clay
    [Color(0xFFDEE6D7), Color(0xFF3F5740)], // sage
    [Color(0xFFEDE3CC), Color(0xFF6B5224)], // amber
    [Color(0xFFEFD9D1), Color(0xFF823C2C)], // terracotta
    [Color(0xFFE0DACE), Color(0xFF5E5236)], // olive
  ];
  static const _palettesDark = <List<Color>>[
    [Color(0xFF3A2218), Color(0xFFE6A48A)],
    [Color(0xFF1F2A20), Color(0xFFA8C8A6)],
    [Color(0xFF2A2317), Color(0xFFD4B47E)],
    [Color(0xFF2C1A14), Color(0xFFD9988A)],
    [Color(0xFF262017), Color(0xFFC7B888)],
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palettes = isDark ? _palettesDark : _palettes;
    final hash = name.codeUnits.fold<int>(0, (a, c) => a + c);
    final p = palettes[hash % palettes.length];

    final initials = name
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: p[0],
        shape: BoxShape.circle,
        border: border == null ? null : Border.all(color: border!, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: PayPactTypography.headingMd.copyWith(
          color: p[1],
          fontSize: size * 0.38,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.02 * (size * 0.38),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// PpAvatarStack — overlapping avatars with a +N pill.
// ─────────────────────────────────────────────────────────────────────
class PpAvatarStack extends StatelessWidget {
  const PpAvatarStack({
    super.key,
    required this.names,
    this.size = 24,
    this.max = 3,
  });

  final List<String> names;
  final double size;
  final int max;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final shown = names.take(max).toList();
    final more = names.length - shown.length;
    final overlap = size * 0.35;

    return SizedBox(
      height: size,
      width: size + (shown.length - 1) * (size - overlap) +
          (more > 0 ? (size - overlap) : 0),
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * (size - overlap),
              child: PpAvatar(name: shown[i], size: size, border: pt.bg),
            ),
          if (more > 0)
            Positioned(
              left: shown.length * (size - overlap),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: pt.surfaceAlt,
                  shape: BoxShape.circle,
                  border: Border.all(color: pt.bg, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$more',
                  style: PayPactTypography.bodySm.copyWith(
                    color: pt.ink2,
                    fontWeight: FontWeight.w600,
                    fontSize: size * 0.36,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// PpGlassCard — translucent surface with backdrop blur.
// ─────────────────────────────────────────────────────────────────────
class PpGlassCard extends StatelessWidget {
  const PpGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius,
    this.opacity = 0.62,
    this.blur = 20,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? radius;
  final double opacity;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = radius ?? PayPactRadius.lg;
    final fill = isDark
        ? Color.fromRGBO(36, 30, 24, opacity * 0.85)
        : pt.surface.withValues(alpha: opacity);
    final borderC = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.7);

    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: r,
            border: Border.all(color: borderC, width: 1),
            boxShadow: pt.shadowSm,
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// PpGlassIconButton — circular glass disc with an icon.
// ─────────────────────────────────────────────────────────────────────
class PpGlassIconButton extends StatelessWidget {
  const PpGlassIconButton({
    super.key,
    required this.icon,
    this.size = 40,
    this.onTap,
    this.badge = false,
  });

  final IconData icon;
  final double size;
  final VoidCallback? onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Material(
              color: pt.surface.withValues(alpha: 0.65),
              shape: CircleBorder(
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.7),
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Icon(icon, color: pt.ink2, size: size * 0.45),
                ),
              ),
            ),
          ),
        ),
        if (badge)
          Positioned(
            top: size * 0.18,
            right: size * 0.22,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: pt.accent,
                shape: BoxShape.circle,
                border: Border.all(color: pt.bg, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// PpCategoryDisc — warm-tinted rounded square for category icons.
// ─────────────────────────────────────────────────────────────────────
enum PpCategory { food, stay, transport, entertainment, shopping, utilities,
                  groceries, health, other, trip, home, couple, friends }

class PpCategoryDisc extends StatelessWidget {
  const PpCategoryDisc({
    super.key,
    required this.category,
    required this.icon,
    this.size = 40,
  });

  final PpCategory category;
  final IconData icon;
  final double size;

  static const _toneLight = <PpCategory, List<Color>>{
    PpCategory.food:          [Color(0xFFF5E6D8), Color(0xFF8B4A23)],
    PpCategory.transport:     [Color(0xFFE3E8DF), Color(0xFF4F6849)],
    PpCategory.stay:          [Color(0xFFE8E0D2), Color(0xFF6B5736)],
    PpCategory.entertainment: [Color(0xFFECDDD7), Color(0xFF7E3F2A)],
    PpCategory.shopping:      [Color(0xFFEDE2D1), Color(0xFF8C6328)],
    PpCategory.utilities:     [Color(0xFFE5DECF), Color(0xFF5E5236)],
    PpCategory.groceries:     [Color(0xFFE2E6D6), Color(0xFF535C3A)],
    PpCategory.health:        [Color(0xFFEFD9D1), Color(0xFF823C2C)],
    PpCategory.other:         [Color(0xFFE6E0D2), Color(0xFF6B6357)],
    PpCategory.trip:          [Color(0xFFE0E8E2), Color(0xFF3F5740)],
    PpCategory.home:          [Color(0xFFEDE3CC), Color(0xFF6B5224)],
    PpCategory.couple:        [Color(0xFFEFD9D1), Color(0xFF823C2C)],
    PpCategory.friends:       [Color(0xFFEDD9CF), Color(0xFF7A3A24)],
  };
  static const _toneDark = <PpCategory, List<Color>>{
    PpCategory.food:          [Color(0xFF3A2A1A), Color(0xFFE8B891)],
    PpCategory.transport:     [Color(0xFF1F2A20), Color(0xFFA8C8A6)],
    PpCategory.stay:          [Color(0xFF2A2317), Color(0xFFD4B47E)],
    PpCategory.entertainment: [Color(0xFF2D1C18), Color(0xFFD89A85)],
    PpCategory.shopping:      [Color(0xFF2A2317), Color(0xFFD9B677)],
    PpCategory.utilities:     [Color(0xFF262017), Color(0xFFC7B888)],
    PpCategory.groceries:     [Color(0xFF1F231A), Color(0xFFB6BD90)],
    PpCategory.health:        [Color(0xFF2C1A14), Color(0xFFD9988A)],
    PpCategory.other:         [Color(0xFF241F18), Color(0xFFA8A090)],
    PpCategory.trip:          [Color(0xFF1F2A20), Color(0xFFA8C8A6)],
    PpCategory.home:          [Color(0xFF2A2317), Color(0xFFD4B47E)],
    PpCategory.couple:        [Color(0xFF2C1A14), Color(0xFFD9988A)],
    PpCategory.friends:       [Color(0xFF2A1A12), Color(0xFFE6A48A)],
  };

  static List<Color> tone(BuildContext c, PpCategory cat) {
    final dark = Theme.of(c).brightness == Brightness.dark;
    return (dark ? _toneDark : _toneLight)[cat]!;
  }

  @override
  Widget build(BuildContext context) {
    final t = tone(context, category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: t[0],
        borderRadius: PayPactRadius.md,
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: t[1], size: size * 0.5),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// PpSectionLabel — small uppercase header with optional action.
// ─────────────────────────────────────────────────────────────────────
class PpSectionLabel extends StatelessWidget {
  const PpSectionLabel({
    super.key,
    required this.label,
    this.action,
    this.onAction,
    this.padding = const EdgeInsets.symmetric(
        horizontal: PayPactSpacing.s6, vertical: 0),
  });

  final String label;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: PayPactTypography.label.copyWith(
                color: pt.ink3,
                fontSize: 10.5,
                letterSpacing: 1.5,
              ),
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: PayPactTypography.bodySm.copyWith(
                  color: pt.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// PpChip — colored pill with optional icon.
// ─────────────────────────────────────────────────────────────────────
enum PpChipTone { neutral, accent, positive, negative, pending, ghost }

class PpChip extends StatelessWidget {
  const PpChip({
    super.key,
    required this.label,
    this.tone = PpChipTone.neutral,
    this.icon,
    this.leading,
  });

  final String label;
  final PpChipTone tone;
  final IconData? icon;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    Color bg, fg, br;
    switch (tone) {
      case PpChipTone.accent:
        bg = pt.accentSoft; fg = pt.accentInk; br = Colors.transparent; break;
      case PpChipTone.positive:
        bg = pt.positiveSoft; fg = pt.positive; br = Colors.transparent; break;
      case PpChipTone.negative:
        bg = pt.negativeSoft; fg = pt.negative; br = Colors.transparent; break;
      case PpChipTone.pending:
        bg = pt.warnSoft; fg = pt.warn; br = Colors.transparent; break;
      case PpChipTone.ghost:
        bg = Colors.transparent; fg = pt.ink2; br = pt.border; break;
      case PpChipTone.neutral:
        bg = pt.surfaceAlt; fg = pt.ink2; br = pt.border; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: PayPactRadius.full,
        border: Border.all(color: br),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 6)],
          if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: 6)],
          Text(
            label,
            style: PayPactTypography.bodySm.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// PpBackdropGlow — warm radial wash behind a screen.
// ─────────────────────────────────────────────────────────────────────
enum PpGlowTone { accent, sage }

class PpBackdropGlow extends StatelessWidget {
  const PpBackdropGlow({
    super.key,
    this.tone = PpGlowTone.accent,
    this.intensity = 0.12,
  });

  final PpGlowTone tone;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = tone == PpGlowTone.sage
        ? (isDark ? const Color(0xFF7DA37C) : const Color(0xFF5C7B5B))
        : (isDark ? const Color(0xFFC77556) : const Color(0xFFB05A3C));

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -80,
            child: _Glow(color: base.withValues(alpha: intensity), size: 360),
          ),
          Positioned(
            top: 280,
            left: -100,
            child: _Glow(color: base.withValues(alpha: intensity * 0.66), size: 320),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0, 0.7],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// PpAmount — formatted INR amount with optional sign + tone.
// ─────────────────────────────────────────────────────────────────────
enum PpAmountTone { neutral, positive, negative, accent }

class PpAmount extends StatelessWidget {
  const PpAmount({
    super.key,
    required this.value,
    this.tone = PpAmountTone.neutral,
    this.style,
    this.signed = false,
  });

  final num value;
  final PpAmountTone tone;
  final TextStyle? style;
  final bool signed;

  static String format(num n, {bool signed = false, bool absolute = false}) {
    final v = absolute ? n.abs() : n;
    final abs = v.abs().round();
    final s = _withCommas(abs);
    if (signed) {
      if (v > 0) return '+₹$s';
      if (v < 0) return '−₹$s';
      return '₹$s';
    }
    return (v < 0 ? '−₹' : '₹') + s;
  }

  static String _withCommas(int n) {
    final s = n.toString();
    if (s.length <= 3) return s;
    // Indian comma grouping: last 3, then groups of 2.
    final last3 = s.substring(s.length - 3);
    final rest = s.substring(0, s.length - 3);
    final buf = StringBuffer();
    for (var i = 0; i < rest.length; i++) {
      buf.write(rest[i]);
      final remaining = rest.length - 1 - i;
      if (remaining > 0 && remaining % 2 == 0) buf.write(',');
    }
    return '${buf.toString()},$last3';
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    Color color;
    switch (tone) {
      case PpAmountTone.positive: color = pt.positive; break;
      case PpAmountTone.negative: color = pt.negative; break;
      case PpAmountTone.accent:   color = pt.accent;   break;
      case PpAmountTone.neutral:  color = pt.ink;      break;
    }
    final base = style ?? PayPactTypography.amountLg;
    return Text(
      format(value, signed: signed),
      style: base.copyWith(color: color),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// PpStatusBarSpacer — adds top safe-area padding under a transparent app bar.
// ─────────────────────────────────────────────────────────────────────
class PpStatusBarSpacer extends StatelessWidget {
  const PpStatusBarSpacer({super.key, this.extra = 0});
  final double extra;
  @override
  Widget build(BuildContext context) {
    return SizedBox(height: MediaQuery.paddingOf(context).top + extra);
  }
}

// ─────────────────────────────────────────────────────────────────────
// PpDashedDivider — thin dashed line, useful in receipts.
// ─────────────────────────────────────────────────────────────────────
class PpDashedDivider extends StatelessWidget {
  const PpDashedDivider({super.key, this.color});
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = color ?? context.pt.border;
    return LayoutBuilder(
      builder: (_, c2) {
        final width = c2.constrainWidth();
        const dashWidth = 4.0, dashSpace = 4.0;
        final count = (width / (dashWidth + dashSpace)).floor();
        return Flex(
          direction: Axis.horizontal,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(count, (_) =>
            SizedBox(width: dashWidth, height: 1,
              child: DecoratedBox(decoration: BoxDecoration(color: c)))),
        );
      },
    );
  }
}

/// Math.cos/sin convenience — used by some screens.
// (unused helpers removed)
