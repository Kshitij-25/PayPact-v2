import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
                  center: const Alignment(-0.4, -0.7),
                  radius: 1.1,
                  colors: [
                    pt.accent.withValues(alpha: 0.20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 44, 56, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Logo ───────────────────────────────────────────────────
                Row(children: [
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: CustomPaint(
                      painter: _GlyphPainter(pt.accent, Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('PayPact',
                      style: PayPactTypography.headingLg.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ]),
                const Spacer(),
                // ── Editorial quote ────────────────────────────────────────
                Text('VOL. 02 · MONEY, QUIETED',
                    style: GoogleFonts.geistMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.6,
                      color: Colors.white.withValues(alpha: 0.45),
                    )),
                const SizedBox(height: 20),
                Text.rich(
                  TextSpan(
                    style: GoogleFonts.geist(
                      fontSize: 46,
                      fontWeight: FontWeight.w600,
                      height: 1.06,
                      letterSpacing: -0.03 * 46,
                      color: Colors.white,
                    ),
                    children: [
                      const TextSpan(
                          text: '"The reminder\nyou never had\nto '),
                      TextSpan(text: 'send', style: TextStyle(color: pt.accent)),
                      const TextSpan(text: '."'),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: 360,
                  child: Text(
                    'Settle in a tap. Soft-nudge with grace. Stay friends, stay even.',
                    style: PayPactTypography.bodyLg.copyWith(
                      color: Colors.white.withValues(alpha: 0.55),
                      height: 1.55,
                    ),
                  ),
                ),
                const Spacer(),
                // ── Activity proof card ────────────────────────────────────
                const _ActivityCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard();

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: PayPactRadius.lg,
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: pt.positive,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('2h ago',
                    style: PayPactTypography.bodySm.copyWith(
                        color: Colors.white.withValues(alpha: 0.40))),
                const SizedBox(height: 2),
                Text('Priya settled with you · ₹1,200',
                    style: PayPactTypography.bodyMd.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('PP-A91',
              style: GoogleFonts.geistMono(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.6,
                color: Colors.white.withValues(alpha: 0.30),
              )),
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
