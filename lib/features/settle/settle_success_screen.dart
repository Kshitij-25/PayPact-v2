import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/design_system/components/paypact_button.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/widgets/pp_atoms.dart';

class SettleSuccessScreen extends StatelessWidget {
  const SettleSuccessScreen({super.key, required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: pt.bg,
      body: Stack(
        children: [
          // Sage glow wash from top
          Positioned(
            top: 0, left: 0, right: 0, height: 380,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [pt.positiveSoft, pt.bg],
                  stops: const [0, 0.6],
                ),
              ),
            ),
          ),
          const PpBackdropGlow(tone: PpGlowTone.sage, intensity: 0.06),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 60, 32, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: _CheckRing(isDark: isDark)),
                  const SizedBox(height: 36),
                  Center(child: Text('SETTLED',
                    style: PayPactTypography.label.copyWith(
                        color: pt.positive, letterSpacing: 1.6))),
                  const SizedBox(height: 14),
                  Center(child: Text('You and Priya\nare square.',
                    textAlign: TextAlign.center,
                    style: PayPactTypography.displayLg.copyWith(color: pt.ink))),
                  const SizedBox(height: 14),
                  Center(child: SizedBox(
                    width: 300,
                    child: Text(
                      '₹1,200 recorded as cash. Priya will get a calm notification.',
                      textAlign: TextAlign.center,
                      style: PayPactTypography.bodyLg.copyWith(
                          color: pt.ink2, height: 1.55),
                    ),
                  )),
                  const SizedBox(height: 30),
                  // Receipt
                  PpGlassCard(
                    padding: const EdgeInsets.all(20),
                    opacity: 0.85,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('RECEIPT',
                                style: PayPactTypography.label.copyWith(
                                    color: pt.ink3, letterSpacing: 1.6)),
                              const SizedBox(height: 3),
                              Text('PP-2026-04-22-A91',
                                style: PayPactTypography.amountMd.copyWith(
                                    color: pt.ink)),
                            ],
                          )),
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                                color: pt.surface,
                                borderRadius: PayPactRadius.sm,
                                border: Border.all(color: pt.border)),
                            alignment: Alignment.center,
                            child: Icon(Icons.qr_code_2_rounded, color: pt.ink2),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        const PpDashedDivider(),
                        const SizedBox(height: 14),
                        _RKv(label: 'From', value: 'Kshitij Rana'),
                        const SizedBox(height: 8),
                        _RKv(label: 'To', value: 'Priya Shah'),
                        const SizedBox(height: 8),
                        _RKv(label: 'Method', value: 'Cash · marked paid'),
                        const SizedBox(height: 14),
                        const PpDashedDivider(),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(child: Text('Total',
                            style: PayPactTypography.headingMd.copyWith(color: pt.ink))),
                          Text('₹1,200.00',
                            style: PayPactTypography.amountLg.copyWith(
                                color: pt.positive)),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(child: PayPactButton(
                      onPressed: () {}, label: 'Share receipt',
                      variant: PayPactButtonVariant.secondary,
                      size: PayPactButtonSize.large,
                      isFullWidth: true,
                      leftIcon: Icons.ios_share_rounded,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: PayPactButton(
                      onPressed: () => context.go(AppRoutes.home), label: 'Done',
                      variant: PayPactButtonVariant.accent,
                      size: PayPactButtonSize.large,
                      isFullWidth: true,
                    )),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RKv extends StatelessWidget {
  const _RKv({required this.label, required this.value});
  final String label; final String value;
  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Row(children: [
      Expanded(child: Text(label,
        style: PayPactTypography.bodyMd.copyWith(color: pt.ink2))),
      Text(value, style: PayPactTypography.bodyMd.copyWith(
          color: pt.ink, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _CheckRing extends StatelessWidget {
  const _CheckRing({required this.isDark});
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return SizedBox(
      width: 160, height: 160,
      child: Stack(children: [
        // outer soft disc + glow
        Center(child: Container(
          width: 160, height: 160,
          decoration: BoxDecoration(
            color: pt.positiveSoft, shape: BoxShape.circle,
            boxShadow: [BoxShadow(
              color: pt.positive.withValues(alpha: isDark ? 0.30 : 0.25),
              blurRadius: 60),
            ],
          ),
        )),
        // inner paper disc
        Center(child: Container(
          width: 132, height: 132,
          decoration: BoxDecoration(
            color: pt.surface, shape: BoxShape.circle,
            border: Border.all(color: pt.border),
          ),
        )),
        // check
        Center(child: SizedBox(
          width: 60, height: 60,
          child: CustomPaint(painter: _CheckPainter(pt.positive)),
        )),
      ]),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.c);
  final Color c;
  @override
  void paint(Canvas canvas, Size s) {
    final ring = Paint()..color = c..style = PaintingStyle.stroke
      ..strokeWidth = 2.5..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(s.width / 2, s.height / 2), 26, ring);
    final p = Path()
      ..moveTo(s.width * 0.30, s.height * 0.52)
      ..lineTo(s.width * 0.43, s.height * 0.65)
      ..lineTo(s.width * 0.70, s.height * 0.37);
    final check = Paint()..color = c..style = PaintingStyle.stroke
      ..strokeWidth = 3.5..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    canvas.drawPath(p, check);
  }
  @override
  bool shouldRepaint(_) => false;
}
