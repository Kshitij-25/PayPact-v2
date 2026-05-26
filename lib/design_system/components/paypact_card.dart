import 'package:flutter/material.dart';

import '../theme/paypact_theme_extension.dart';
import '../tokens/radius.dart';

/// Warm-minimal card: paper surface, hairline border, no shadow by default.
class PayPactCard extends StatelessWidget {
  const PayPactCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.raised = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool raised;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Container(
      decoration: BoxDecoration(
        color: pt.surface,
        border: Border.all(color: pt.border),
        borderRadius: PayPactRadius.lg,
        boxShadow: raised ? pt.shadowSm : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: PayPactRadius.lg,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
