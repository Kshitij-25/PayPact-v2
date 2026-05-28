import 'package:flutter/material.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/typography.dart';

class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;

    return Container(
      color: pt.ink,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.3),
                  radius: 1.0,
                  colors: [
                    pt.accent.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CustomPaint(
                    painter: _GlyphPainter(pt.accent, const Color(0xFFFAF7F1)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('PayPact',
                    style: PayPactTypography.displayLg.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                SizedBox(
                  width: 280,
                  child: Text(
                    'Money between friends,\nfinally quiet.',
                    textAlign: TextAlign.center,
                    style: PayPactTypography.bodyLg
                        .copyWith(color: Colors.white38, height: 1.55),
                  ),
                ),
                const SizedBox(height: 48),
                _StatCard(
                  label: 'NET BALANCE',
                  value: '+₹2,340',
                  sub: 'across 3 groups',
                  positive: true,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    _SmallStatCard(label: 'Settled this month', value: '₹4,200'),
                    SizedBox(width: 12),
                    _SmallStatCard(label: 'Active groups', value: '3'),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'End-to-end encrypted · No ads · No social feed',
                style: PayPactTypography.bodySm.copyWith(color: Colors.white24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.a, this.b);
  final Color a;
  final Color b;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(
        Offset(size.width * 0.375, size.height / 2), size.width * 0.27, p..color = a);
    canvas.drawCircle(
        Offset(size.width * 0.625, size.height / 2), size.width * 0.27, p..color = b);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.positive,
  });
  final String label;
  final String value;
  final String sub;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: PayPactRadius.lg,
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: PayPactTypography.label
                  .copyWith(color: Colors.white38, letterSpacing: 1.4)),
          const SizedBox(height: 8),
          Text(value,
              style: PayPactTypography.amountLg.copyWith(
                color: positive
                    ? const Color(0xFF7EC8A4)
                    : const Color(0xFFE07B6A),
                fontSize: 28,
              )),
          const SizedBox(height: 4),
          Text(sub,
              style: PayPactTypography.bodySm.copyWith(color: Colors.white38)),
        ],
      ),
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  const _SmallStatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 114,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: PayPactRadius.md,
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: PayPactTypography.headingLg.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label,
              style: PayPactTypography.micro.copyWith(color: Colors.white38)),
        ],
      ),
    );
  }
}

class AuthLogoRow extends StatelessWidget {
  const AuthLogoRow({super.key});

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Row(children: [
      SizedBox(
        width: 22,
        height: 22,
        child: CustomPaint(painter: _GlyphPainter(pt.accent, pt.ink)),
      ),
      const SizedBox(width: 8),
      Text('PayPact',
          style: PayPactTypography.headingMd
              .copyWith(color: pt.ink, fontWeight: FontWeight.w700)),
    ]);
  }
}
