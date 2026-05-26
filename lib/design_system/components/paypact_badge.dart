import 'package:flutter/material.dart';

import '../theme/paypact_theme_extension.dart';
import '../tokens/radius.dart';

enum PayPactBadgeVariant { positive, negative, pending, neutral, accent }

class PayPactBadge extends StatelessWidget {
  const PayPactBadge({
    super.key,
    required this.label,
    this.variant = PayPactBadgeVariant.neutral,
  });

  final String label;
  final PayPactBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;

    Color bg;
    Color fg;
    switch (variant) {
      case PayPactBadgeVariant.positive:
        bg = pt.positiveSoft;
        fg = pt.positive;
        break;
      case PayPactBadgeVariant.negative:
        bg = pt.negativeSoft;
        fg = pt.negative;
        break;
      case PayPactBadgeVariant.pending:
        bg = pt.warnSoft;
        fg = pt.warn;
        break;
      case PayPactBadgeVariant.accent:
        bg = pt.accentSoft;
        fg = pt.accentInk;
        break;
      case PayPactBadgeVariant.neutral:
        bg = pt.surfaceAlt;
        fg = pt.ink2;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: PayPactRadius.full,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.005 * 11,
          color: fg,
        ),
      ),
    );
  }
}
