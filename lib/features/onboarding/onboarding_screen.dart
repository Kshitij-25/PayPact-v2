import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/core/utils/responsive.dart';
import 'package:paypact/design_system/components/paypact_button.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/spacing.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/widgets/pp_atoms.dart';

/// 3-page onboarding carousel: Quiet money · Settle in a tap · People who matter.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.onFinish});
  final VoidCallback? onFinish;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _i = 0;

  void _next() {
    if (_i < 2) {
      _pc.nextPage(
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic);
    } else {
      widget.onFinish?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;

    if (context.isDesktop) {
      return const _WebLandingPage();
    }

    return Scaffold(
      backgroundColor: pt.bg,
      body: Stack(
        children: [
          const PpBackdropGlow(intensity: 0.18),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(PayPactSpacing.s6,
                      PayPactSpacing.s3, PayPactSpacing.s6, 0),
                  child: Row(
                    children: [
                      _PactGlyph(),
                      const SizedBox(width: 8),
                      Text('PayPact',
                          style: PayPactTypography.headingMd
                              .copyWith(color: pt.ink)),
                      const Spacer(),
                      TextButton(
                        onPressed: widget.onFinish,
                        child: Text('Skip',
                            style: PayPactTypography.bodyMd
                                .copyWith(color: pt.ink2)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pc,
                    onPageChanged: (i) => setState(() => _i = i),
                    children: const [
                      _OnboardingPage1(),
                      _OnboardingPage2(),
                      _OnboardingPage3(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(PayPactSpacing.s6, 0,
                      PayPactSpacing.s6, PayPactSpacing.s7),
                  child: Row(
                    children: [
                      Row(
                        children: List.generate(
                          3,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            margin: const EdgeInsets.only(right: 6),
                            width: i == _i ? 24 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _i ? pt.accent : pt.border,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      PayPactButton(
                        onPressed: _next,
                        label: _i == 2 ? 'Get started' : 'Continue',
                        variant: PayPactButtonVariant.accent,
                        rightIcon: Icons.arrow_forward_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Web landing page ──────────────────────────────────────────────────────────

class _WebLandingPage extends StatelessWidget {
  const _WebLandingPage();

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final size = MediaQuery.sizeOf(context);
    final showNavLinks = size.width >= 1040;

    return Scaffold(
      backgroundColor: pt.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(pt.border.withValues(alpha: 0.5)),
            ),
          ),
          SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNav(context, pt, showNavLinks),
                      SizedBox(height: (size.height * 0.07).clamp(40, 84)),
                      _buildHero(context, pt, size.width),
                      const SizedBox(height: 64),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Nav ──────────────────────────────────────────────────────────────
  Widget _buildNav(
      BuildContext context, PayPactThemeExtension pt, bool showLinks) {
    return Row(
      children: [
        _PactGlyph(),
        const SizedBox(width: 9),
        Text('PayPact',
            style: PayPactTypography.headingMd
                .copyWith(color: pt.ink, fontWeight: FontWeight.w700)),
        const Spacer(),
        TextButton(
          onPressed: () => context.go(AppRoutes.signIn),
          child: Text('Sign in',
              style: PayPactTypography.bodyMd
                  .copyWith(color: pt.ink2, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 10),
        PayPactButton(
          onPressed: () => context.go(AppRoutes.signUp),
          label: 'Get started — free',
          variant: PayPactButtonVariant.accent,
          size: PayPactButtonSize.small,
        ),
      ],
    );
  }

  // ── Hero ─────────────────────────────────────────────────────────────
  Widget _buildHero(BuildContext context, PayPactThemeExtension pt, double w) {
    final heroFont = (w * 0.052).clamp(40.0, 62.0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBadge(pt),
              const SizedBox(height: 28),
              RichText(
                text: TextSpan(
                  style: PayPactTypography.displayXl.copyWith(
                    fontSize: heroFont,
                    height: 1.04,
                    letterSpacing: -0.032 * heroFont,
                    fontWeight: FontWeight.w700,
                    color: pt.ink,
                  ),
                  children: [
                    const TextSpan(text: 'Quiet money between '),
                    TextSpan(
                      text: 'people who matter.',
                      style: TextStyle(color: pt.accent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: 410,
                child: Text(
                  'Split, settle, and stay in sync — without the awkward '
                  'reminders. Editorial-grade money UX for friends, '
                  'roommates and trips.',
                  style: PayPactTypography.bodyLg.copyWith(
                    height: 1.6,
                    fontSize: 16,
                    color: pt.ink2,
                  ),
                ),
              ),
              const SizedBox(height: 34),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  PayPactButton(
                    onPressed: () => context.go(AppRoutes.signUp),
                    label: 'Start a free pact',
                    variant: PayPactButtonVariant.accent,
                    size: PayPactButtonSize.large,
                    leftIcon: Icons.arrow_forward_rounded,
                  ),
                  PayPactButton(
                    onPressed: () => context.go(AppRoutes.signUp),
                    label: 'Watch the 90-sec tour',
                    variant: PayPactButtonVariant.secondary,
                    size: PayPactButtonSize.large,
                    leftIcon: Icons.play_circle_outline_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildSocialProof(pt),
            ],
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          flex: 5,
          child: _buildHeroArt(pt),
        ),
      ],
    );
  }

  Widget _buildBadge(PayPactThemeExtension pt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: pt.surface,
        borderRadius: PayPactRadius.full,
        border: Border.all(color: pt.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: pt.accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text('v2 · Now with smart nudges',
              style: PayPactTypography.label.copyWith(color: pt.ink2)),
        ],
      ),
    );
  }

  Widget _buildSocialProof(PayPactThemeExtension pt) {
    return Row(
      children: [
        const _AvatarStack(['P', 'R', 'A', 'M', 'S']),
        const SizedBox(width: 14),
        Flexible(
          child: RichText(
            text: TextSpan(
              style: PayPactTypography.bodySm.copyWith(color: pt.ink2),
              children: [
                const TextSpan(text: 'Joining '),
                TextSpan(
                  text: '62,400+',
                  style: TextStyle(color: pt.ink, fontWeight: FontWeight.w600),
                ),
                const TextSpan(text: ' friends already settling calmly.'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Hero art (floating cards) ────────────────────────────────────────
  Widget _buildHeroArt(PayPactThemeExtension pt) {
    return SizedBox(
      height: 480,
      child: Stack(
        children: [
          // Dark net-balance card
          Positioned(
            top: 8,
            right: 0,
            child: Container(
              width: 252,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1B16),
                borderRadius: PayPactRadius.xl,
                boxShadow: pt.shadowLg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NET BALANCE',
                      style: PayPactTypography.label.copyWith(
                          color: Colors.white.withValues(alpha: 0.4),
                          letterSpacing: 1.6)),
                  const SizedBox(height: 12),
                  Text('+₹2,340',
                      style: PayPactTypography.amountXl.copyWith(
                          color: const Color(0xFFFAF7F1), fontSize: 34)),
                  const SizedBox(height: 8),
                  Text('Across 3 groups · ↑ ₹1,200 this week',
                      style: PayPactTypography.bodySm.copyWith(
                          color: Colors.white.withValues(alpha: 0.5))),
                ],
              ),
            ),
          ),
          // Beach shack chip
          Positioned(
            top: 152,
            left: 0,
            child: _pill(
              bg: pt.accentSoft,
              child: Text('🏖 Beach shack · ₹2,400',
                  style: PayPactTypography.bodySm.copyWith(
                      color: pt.accentInk, fontWeight: FontWeight.w600)),
            ),
          ),
          // Settled pill
          Positioned(
            top: 250,
            right: 28,
            child: _pill(
              bg: pt.positiveSoft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, size: 14, color: pt.positive),
                  const SizedBox(width: 6),
                  Text('₹1,200 settled',
                      style: PayPactTypography.bodySm.copyWith(
                          color: pt.positive, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          // Hotel Taj card
          Positioned(
            left: 0,
            right: 24,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: pt.surface,
                borderRadius: PayPactRadius.xl,
                border: Border.all(color: pt.border),
                boxShadow: pt.shadowLg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: pt.surfaceAlt,
                          borderRadius: PayPactRadius.sm,
                        ),
                        child:
                            Icon(Icons.bed_outlined, color: pt.ink2, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hotel Taj',
                              style: PayPactTypography.bodyMd.copyWith(
                                  color: pt.ink, fontWeight: FontWeight.w600)),
                          Text('Goa Trip · You paid',
                              style: PayPactTypography.bodySm
                                  .copyWith(color: pt.ink2)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Split 5 ways',
                          style: PayPactTypography.bodySm
                              .copyWith(color: pt.ink3)),
                      Text('+₹3,200',
                          style: PayPactTypography.amountLg
                              .copyWith(color: pt.accent, fontSize: 24)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill({required Color bg, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: PayPactRadius.full),
      child: child,
    );
  }
}

// ── Avatar stack (social proof) ─────────────────────────────────────────────────

class _AvatarStack extends StatelessWidget {
  const _AvatarStack(this.letters);
  final List<String> letters;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    const d = 30.0;
    const overlap = 20.0;
    return SizedBox(
      width: overlap * (letters.length - 1) + d,
      height: d,
      child: Stack(
        children: [
          for (var i = 0; i < letters.length; i++)
            Positioned(
              left: i * overlap,
              child: Container(
                width: d,
                height: d,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i.isEven ? pt.accentSoft : pt.surfaceAlt,
                  shape: BoxShape.circle,
                  border: Border.all(color: pt.bg, width: 2),
                ),
                child: Text(letters[i],
                    style: PayPactTypography.micro
                        .copyWith(color: pt.ink, fontSize: 11)),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Background grid ─────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  _GridPainter(this.color);
  final Color color;
  static const _step = 56.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = 0; x <= size.width; x += _step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += _step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) =>
      old is! _GridPainter || old.color != color;
}

class _PactGlyph extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GlyphPainter(pt.accent, pt.ink)),
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
    canvas.drawCircle(Offset(size.width * 0.375, size.height / 2),
        size.width * 0.27, p..color = a);
    canvas.drawCircle(Offset(size.width * 0.625, size.height / 2),
        size.width * 0.27, p..color = b);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────── Page 1 — Quiet money ───────────────────
class _OnboardingPage1 extends StatelessWidget {
  const _OnboardingPage1();

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PayPactSpacing.s7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          SizedBox(
            height: 320,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Background chips
                Positioned(
                    top: 30,
                    left: 8,
                    child: Transform.rotate(
                        angle: -0.1,
                        child: _chip(
                            context, '🍕 Dinner · ₹2,400', pt.ink, pt.surface,
                            border: true))),
                Positioned(
                    top: 140,
                    right: 6,
                    child: Transform.rotate(
                        angle: 0.07,
                        child: _chip(context, '+₹1,200 settled', pt.accentInk,
                            pt.accentSoft))),
                Positioned(
                    bottom: 30,
                    left: 18,
                    child: Transform.rotate(
                        angle: -0.05,
                        child: _chip(context, "You'll get ₹820 back",
                            pt.positive, pt.positiveSoft))),
                // Center charcoal card
                Positioned(
                  left: 0,
                  right: 0,
                  top: 60,
                  child: Center(
                    child: Container(
                      width: 220,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F1B16),
                        borderRadius: PayPactRadius.xl,
                        boxShadow: pt.shadowLg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NET BALANCE',
                              style: PayPactTypography.label.copyWith(
                                color: Colors.white.withValues(alpha: 0.4),
                                letterSpacing: 1.6,
                              )),
                          const SizedBox(height: 14),
                          Text('+₹2,340',
                              style: PayPactTypography.displayLg.copyWith(
                                color: const Color(0xFFFAF7F1),
                                letterSpacing: -0.035 * 28,
                              )),
                          const SizedBox(height: 6),
                          Text('across 3 groups',
                              style: PayPactTypography.bodySm.copyWith(
                                color: Colors.white.withValues(alpha: 0.5),
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 42),
          Text('01 · 03',
              style: PayPactTypography.label
                  .copyWith(color: pt.accent, letterSpacing: 1.6)),
          const SizedBox(height: 14),
          Text('Money between\nfriends, finally quiet.',
              style: PayPactTypography.displayLg.copyWith(color: pt.ink)),
          const SizedBox(height: 14),
          SizedBox(
            width: 300,
            child: Text(
              'Split, settle, and stay in sync — without the awkward reminders.',
              style: PayPactTypography.bodyLg
                  .copyWith(color: pt.ink2, height: 1.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext c, String text, Color fg, Color bg,
      {bool border = false}) {
    final pt = c.pt;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: PayPactRadius.full,
        border: border ? Border.all(color: pt.border) : null,
        boxShadow: pt.shadowSm,
      ),
      child: Text(text,
          style: PayPactTypography.bodySm
              .copyWith(color: fg, fontWeight: FontWeight.w600)),
    );
  }
}

// ─────────────────── Page 2 — Settle in a tap ───────────────────
class _OnboardingPage2 extends StatelessWidget {
  const _OnboardingPage2();

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final receipts = [
      _Receipt(amount: 540, who: 'Maya → You · wallet', positive: false),
      _Receipt(amount: 820, who: 'You → Ankit · UPI', positive: false),
      _Receipt(amount: 1200, who: 'Priya → You · cash', positive: true),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PayPactSpacing.s7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          SizedBox(
            height: 320,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Background chips
                Positioned(
                    top: 24,
                    right: 12,
                    child: Transform.rotate(
                      angle: 0.07,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: pt.warnSoft,
                          borderRadius: PayPactRadius.full,
                          boxShadow: pt.shadowSm,
                        ),
                        child: Text('Nudge · gentle',
                            style: PayPactTypography.bodySm.copyWith(
                                color: pt.warn, fontWeight: FontWeight.w600)),
                      ),
                    )),
                Positioned(
                    bottom: 46,
                    right: 10,
                    child: Transform.rotate(
                      angle: -0.04,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: pt.positiveSoft,
                          borderRadius: PayPactRadius.full,
                          boxShadow: pt.shadowSm,
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.check_rounded,
                              size: 12, color: pt.positive),
                          const SizedBox(width: 6),
                          Text('Settled',
                              style: PayPactTypography.bodySm.copyWith(
                                  color: pt.positive,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    )),
                Positioned(
                    bottom: 28,
                    left: 6,
                    child: Transform.rotate(
                      angle: -0.09,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: pt.surface,
                          borderRadius: PayPactRadius.full,
                          border: Border.all(color: pt.border),
                          boxShadow: pt.shadowSm,
                        ),
                        child: Text('1 tap to clear',
                            style: PayPactTypography.bodySm.copyWith(
                                color: pt.ink, fontWeight: FontWeight.w600)),
                      ),
                    )),
                // Receipt stack
                for (var i = 0; i < receipts.length; i++)
                  Positioned(
                    top: 50.0 - (2 - i) * 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Transform.rotate(
                        angle: ((2 - i) - 1) * 0.05,
                        child: Opacity(
                          opacity: i == receipts.length - 1
                              ? 1
                              : 0.85 - (receipts.length - 1 - i) * 0.18,
                          child: _ReceiptCard(
                              r: receipts[i],
                              topMost: i == receipts.length - 1),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 42),
          Text('02 · 03',
              style: PayPactTypography.label
                  .copyWith(color: pt.accent, letterSpacing: 1.6)),
          const SizedBox(height: 14),
          Text('Settle in a tap.\nOr just a soft nudge.',
              style: PayPactTypography.displayLg.copyWith(color: pt.ink)),
          const SizedBox(height: 14),
          SizedBox(
            width: 300,
            child: Text(
              'Smart reminders that respect the room — no late-fee energy, ever.',
              style: PayPactTypography.bodyLg
                  .copyWith(color: pt.ink2, height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _Receipt {
  final int amount;
  final String who;
  final bool positive;
  _Receipt({required this.amount, required this.who, required this.positive});
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.r, required this.topMost});
  final _Receipt r;
  final bool topMost;
  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pt.surface,
        border: Border.all(color: pt.border),
        borderRadius: PayPactRadius.lg,
        boxShadow: pt.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('RECEIPT · PP-2026',
                style: PayPactTypography.label
                    .copyWith(color: pt.ink3, fontSize: 9, letterSpacing: 1.2)),
            const Spacer(),
            if (topMost)
              Container(
                width: 24,
                height: 24,
                decoration:
                    BoxDecoration(color: pt.positive, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.check_rounded,
                    size: 14, color: Colors.white),
              ),
          ]),
          const SizedBox(height: 10),
          Text('₹${PpAmount.format(r.amount).replaceAll('₹', '')}',
              style: PayPactTypography.amountLg.copyWith(
                  color: r.positive ? pt.positive : pt.ink, fontSize: 22)),
          const SizedBox(height: 4),
          Text(r.who, style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
        ],
      ),
    );
  }
}

// ─────────────────── Page 3 — People who matter ───────────────────
class _OnboardingPage3 extends StatelessWidget {
  const _OnboardingPage3();

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    const people = [
      'Priya Shah',
      'Rohan Khan',
      'Ankit Rai',
      'Maya Sen',
      'Sam Lee',
      'Tara Iyer'
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PayPactSpacing.s7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          SizedBox(
            height: 320,
            child: Stack(
              children: [
                // Outer dashed ring
                Center(
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: pt.borderStrong,
                          width: 1.5,
                          style: BorderStyle.solid),
                    ),
                  ),
                ),
                // Inner accent ring + glow
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          pt.accentSoft,
                          pt.accentSoft.withValues(alpha: 0)
                        ],
                        stops: const [0, 0.7],
                      ),
                      border: Border.all(color: pt.border),
                    ),
                  ),
                ),
                // Center pact mark
                Center(
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1F1B16),
                      boxShadow: [
                        BoxShadow(
                            color: pt.accent.withValues(alpha: 0.35),
                            offset: const Offset(0, 12),
                            blurRadius: 30),
                        BoxShadow(
                          color: pt.bg.withValues(alpha: 0.6),
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: CustomPaint(
                          painter: _GlyphPainter(
                              pt.accent, const Color(0xFFFAF7F1))),
                    ),
                  ),
                ),
                // Avatars on the ring
                for (var i = 0; i < people.length; i++) ...[
                  Builder(builder: (_) {
                    final angle =
                        (i / people.length) * math.pi * 2 - math.pi / 2;
                    final x = math.cos(angle) * 130;
                    final y = math.sin(angle) * 130;
                    return Positioned(
                      left: 0,
                      right: 0,
                      top: 160 + y - 22,
                      child: Transform.translate(
                        offset: Offset(x, 0),
                        child: Center(
                          child: PpAvatar(
                              name: people[i], size: 44, border: pt.bg),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          const SizedBox(height: 42),
          Text('03 · 03',
              style: PayPactTypography.label
                  .copyWith(color: pt.accent, letterSpacing: 1.6)),
          const SizedBox(height: 14),
          Text('Just the people\nwho matter.',
              style: PayPactTypography.displayLg.copyWith(color: pt.ink)),
          const SizedBox(height: 14),
          SizedBox(
            width: 300,
            child: Text(
              'End-to-end encrypted. No social feed, no ads, no public history.',
              style: PayPactTypography.bodyLg
                  .copyWith(color: pt.ink2, height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
