import 'package:flutter/material.dart';

import '../theme/paypact_theme_extension.dart';
import '../tokens/radius.dart';
import '../tokens/typography.dart';

/// Warm-minimal button.
///   primary   — solid ink on bg (the canonical CTA)
///   secondary — outlined, no fill
///   ghost     — text only, transparent
///   accent    — clay accent fill
///   danger    — muted terracotta text on bordered surface
enum PayPactButtonVariant { primary, secondary, ghost, accent, danger }

enum PayPactButtonSize { small, medium, large }

class PayPactButton extends StatelessWidget {
  const PayPactButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.variant = PayPactButtonVariant.primary,
    this.size = PayPactButtonSize.medium,
    this.isFullWidth = false,
    this.leftIcon,
    this.rightIcon,
  });

  final VoidCallback? onPressed;
  final String label;
  final PayPactButtonVariant variant;
  final PayPactButtonSize size;
  final bool isFullWidth;
  final IconData? leftIcon;
  final IconData? rightIcon;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;

    Color background;
    Color foreground;
    Color borderColor;
    switch (variant) {
      case PayPactButtonVariant.primary:
        background = pt.ink;
        foreground = pt.bg;
        borderColor = pt.ink;
        break;
      case PayPactButtonVariant.secondary:
        background = Colors.transparent;
        foreground = pt.ink;
        borderColor = pt.borderStrong;
        break;
      case PayPactButtonVariant.ghost:
        background = Colors.transparent;
        foreground = pt.ink;
        borderColor = Colors.transparent;
        break;
      case PayPactButtonVariant.accent:
        background = pt.accent;
        foreground = Colors.white;
        borderColor = pt.accent;
        break;
      case PayPactButtonVariant.danger:
        background = Colors.transparent;
        foreground = pt.negative;
        borderColor = pt.border;
        break;
    }

    if (onPressed == null) {
      background = background == Colors.transparent
          ? Colors.transparent
          : pt.surfaceAlt;
      foreground = pt.ink3;
      borderColor =
          borderColor == Colors.transparent ? Colors.transparent : pt.border;
    }

    double height;
    double horizontal;
    double fontSize;
    switch (size) {
      case PayPactButtonSize.small:
        height = 32;
        horizontal = 12;
        fontSize = 13;
        break;
      case PayPactButtonSize.medium:
        height = 40;
        horizontal = 16;
        fontSize = 14;
        break;
      case PayPactButtonSize.large:
        height = 48;
        horizontal = 20;
        fontSize = 15;
        break;
    }

    final textStyle = PayPactTypography.bodyMd.copyWith(
      color: foreground,
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.01 * fontSize,
    );

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: PayPactRadius.md,
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: PayPactRadius.md,
        child: SizedBox(
          height: height,
          width: isFullWidth ? double.infinity : null,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontal),
            child: Row(
              mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leftIcon != null) ...[
                  Icon(leftIcon, size: 16, color: foreground),
                  const SizedBox(width: 8),
                ],
                Text(label, style: textStyle),
                if (rightIcon != null) ...[
                  const SizedBox(width: 8),
                  Icon(rightIcon, size: 16, color: foreground),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
