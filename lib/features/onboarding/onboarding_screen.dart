import 'dart:math' as math;
import 'package:flutter/material.dart';
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
      _pc.nextPage(duration: const Duration(milliseconds: 360), curve: Curves.easeOutCubic);
    } else {
      widget.onFinish?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;

    if (context.isDesktop) {
      return _WebLandingPage(onFinish: widget.onFinish);
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
                  padding: const EdgeInsets.fromLTRB(
                      PayPactSpacing.s6, PayPactSpacing.s3, PayPactSpacing.s6, 0),
                  child: Row(
                    children: [
                      _PactGlyph(),
                      const SizedBox(width: 8),
                      Text('PayPact',
                          style:
                              PayPactTypography.headingMd.copyWith(color: pt.ink)),
                      const Spacer(),
                      TextButton(
                        onPressed: widget.onFinish,
                        child: Text('Skip',
                            style:
                                PayPactTypography.bodyMd.copyWith(color: pt.ink2)),
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
                  padding: const EdgeInsets.fromLTRB(
                      PayPactSpacing.s6, 0, PayPactSpacing.s6, PayPactSpacing.s7),
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
  const _WebLandingPage({this.onFinish});
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;

    return Scaffold(
      backgroundColor: pt.bg,
      body: Stack(
        children: [
          const PpBackdropGlow(intensity: 0.15),
          Column(
            children: [
              // ── Nav bar ────────────────────────────────────────────────────
              Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 48),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: pt.border)),
                ),
                child: Row(
                  children: [
                    _PactGlyph(),
                    const SizedBox(width: 10),
                    Text('PayPact',
                        style: PayPactTypography.headingMd
                            .copyWith(color: pt.ink, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton(
                      onPressed: onFinish,
                      child: Text('Sign in',
                          style: PayPactTypography.bodyMd
                              .copyWith(color: pt.ink2, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 8),
                    PayPactButton(
                      onPressed: onFinish,
                      label: 'Get started',
                      variant: PayPactButtonVariant.accent,
                      rightIcon: Icons.arrow_forward_rounded,
                    ),
                  ],
                ),
              ),

              // ── Hero ───────────────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 80),
                      // Eyebrow chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: pt.accentSoft,
                          borderRadius: PayPactRadius.full,
                          border: Border.all(
                              color: pt.accent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  color: pt.accent, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Text('Quiet money between friends',
                                style: PayPactTypography.label.copyWith(
                                    color: pt.accent, letterSpacing: 1.4)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Headline
                      Text(
                        'Money between friends,\nfinally quiet.',
                        textAlign: TextAlign.center,
                        style: PayPactTypography.displayXl.copyWith(
                          color: pt.ink,
                          fontSize: 56,
                          height: 1.12,
                          letterSpacing: -0.035 * 56,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Subtitle
                      SizedBox(
                        width: 480,
                        child: Text(
                          'Split expenses, settle debts, and stay in sync with the people you share life with — without the awkward reminders.',
                          textAlign: TextAlign.center,
                          style: PayPactTypography.bodyLg.copyWith(
                              color: pt.ink2, height: 1.6, fontSize: 17),
                        ),
                      ),
                      const SizedBox(height: 36),
                      // CTAs
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PayPactButton(
                            onPressed: onFinish,
                            label: 'Create free account',
                            variant: PayPactButtonVariant.accent,
                            size: PayPactButtonSize.large,
                            rightIcon: Icons.arrow_forward_rounded,
                          ),
                          const SizedBox(width: 12),
                          PayPactButton(
                            onPressed: onFinish,
                            label: 'Sign in',
                            variant: PayPactButtonVariant.secondary,
                            size: PayPactButtonSize.large,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Free forever · No credit card needed',
                          style: PayPactTypography.bodySm
                              .copyWith(color: pt.ink3)),
                      const SizedBox(height: 72),

                      // ── Feature strip ──────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 80),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FeatureCard(
                              icon: Icons.account_balance_wallet_outlined,
                              title: 'Track every split',
                              body:
                                  'Add expenses in seconds. PayPact automatically calculates who owes what across all your groups.',
                              pt: pt,
                            ),
                            const SizedBox(width: 20),
                            _FeatureCard(
                              icon: Icons.handshake_outlined,
                              title: 'Settle in a tap',
                              body:
                                  'Smart reminders that respect the room. No late-fee energy — just a gentle nudge when it matters.',
                              pt: pt,
                            ),
                            const SizedBox(width: 20),
                            _FeatureCard(
                              icon: Icons.lock_outline_rounded,
                              title: 'Private by design',
                              body:
                                  'End-to-end encrypted. No social feed, no ads, no public expense history. Just your circle.',
                              pt: pt,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 72),

                      // ── Dashboard preview card ─────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 80),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: pt.ink,
                            borderRadius: PayPactRadius.xl,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('NET BALANCE',
                                        style: PayPactTypography.label.copyWith(
                                            color: Colors.white54,
                                            letterSpacing: 1.6)),
                                    const SizedBox(height: 12),
                                    Text('+₹2,340',
                                        style: PayPactTypography.amountHero
                                            .copyWith(
                                                color: Colors.white,
                                                fontSize: 48,
                                                letterSpacing: -0.045 * 48)),
                                    const SizedBox(height: 8),
                                    Text('across 3 groups · all on track',
                                        style: PayPactTypography.bodyMd
                                            .copyWith(
                                                color: Colors.white38)),
                                    const SizedBox(height: 24),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        _DarkChip('🏖️ Goa trip · ₹1,200', Colors.white70),
                                        _DarkChip('🍕 Friday dinners · ₹640', Colors.white70),
                                        _DarkChip('🏠 Flat rent · ₹500', Colors.white70),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 40),
                              Column(
                                children: [
                                  _MiniReceipt(
                                      label: 'Maya paid',
                                      amount: '₹1,200',
                                      positive: true,
                                      pt: pt),
                                  const SizedBox(height: 10),
                                  _MiniReceipt(
                                      label: 'You owe Rohan',
                                      amount: '₹540',
                                      positive: false,
                                      pt: pt),
                                  const SizedBox(height: 10),
                                  _MiniReceipt(
                                      label: 'Settled ✓',
                                      amount: '₹820',
                                      positive: true,
                                      pt: pt),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.pt,
  });
  final IconData icon;
  final String title;
  final String body;
  final PayPactThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: pt.surface,
          borderRadius: PayPactRadius.lg,
          border: Border.all(color: pt.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: pt.accentSoft, borderRadius: PayPactRadius.md),
              alignment: Alignment.center,
              child: Icon(icon, color: pt.accent, size: 20),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: PayPactTypography.headingMd
                    .copyWith(color: pt.ink, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(body,
                style: PayPactTypography.bodyMd
                    .copyWith(color: pt.ink2, height: 1.55)),
          ],
        ),
      ),
    );
  }
}

class _DarkChip extends StatelessWidget {
  const _DarkChip(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(label,
          style: PayPactTypography.bodySm
              .copyWith(color: color, fontWeight: FontWeight.w500)),
    );
  }
}

class _MiniReceipt extends StatelessWidget {
  const _MiniReceipt({
    required this.label,
    required this.amount,
    required this.positive,
    required this.pt,
  });
  final String label;
  final String amount;
  final bool positive;
  final PayPactThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: PayPactRadius.md,
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: PayPactTypography.bodySm
                    .copyWith(color: Colors.white60)),
          ),
          Text(amount,
              style: PayPactTypography.amountMd.copyWith(
                  color: positive
                      ? const Color(0xFF7EC8A4)
                      : const Color(0xFFE07B6A))),
        ],
      ),
    );
  }
}

class _PactGlyph extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return SizedBox(
      width: 22, height: 22,
      child: CustomPaint(painter: _GlyphPainter(pt.accent, pt.ink)),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.a, this.b);
  final Color a; final Color b;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 2;
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
                Positioned(top: 30, left: 8, child: Transform.rotate(
                  angle: -0.1, child: _chip(context, '🍕 Dinner · ₹2,400', pt.ink, pt.surface, border: true))),
                Positioned(top: 140, right: 6, child: Transform.rotate(
                  angle: 0.07, child: _chip(context, '+₹1,200 settled', pt.accentInk, pt.accentSoft))),
                Positioned(bottom: 30, left: 18, child: Transform.rotate(
                  angle: -0.05, child: _chip(context, "You'll get ₹820 back", pt.positive, pt.positiveSoft))),
                // Center charcoal card
                Positioned(
                  left: 0, right: 0, top: 60,
                  child: Center(
                    child: Container(
                      width: 220, padding: const EdgeInsets.all(24),
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
            style: PayPactTypography.label.copyWith(color: pt.accent, letterSpacing: 1.6)),
          const SizedBox(height: 14),
          Text('Money between\nfriends, finally quiet.',
            style: PayPactTypography.displayLg.copyWith(color: pt.ink)),
          const SizedBox(height: 14),
          SizedBox(
            width: 300,
            child: Text(
              'Split, settle, and stay in sync — without the awkward reminders.',
              style: PayPactTypography.bodyLg.copyWith(color: pt.ink2, height: 1.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext c, String text, Color fg, Color bg, {bool border = false}) {
    final pt = c.pt;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: PayPactRadius.full,
        border: border ? Border.all(color: pt.border) : null,
        boxShadow: pt.shadowSm,
      ),
      child: Text(text, style: PayPactTypography.bodySm.copyWith(color: fg, fontWeight: FontWeight.w600)),
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
      _Receipt(amount: 540,  who: 'Maya → You · wallet',  positive: false),
      _Receipt(amount: 820,  who: 'You → Ankit · UPI',    positive: false),
      _Receipt(amount: 1200, who: 'Priya → You · cash',   positive: true),
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
                Positioned(top: 24, right: 12, child: Transform.rotate(
                  angle: 0.07,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: pt.warnSoft, borderRadius: PayPactRadius.full,
                      boxShadow: pt.shadowSm,
                    ),
                    child: Text('Nudge · gentle',
                      style: PayPactTypography.bodySm.copyWith(
                          color: pt.warn, fontWeight: FontWeight.w600)),
                  ),
                )),
                Positioned(bottom: 46, right: 10, child: Transform.rotate(
                  angle: -0.04,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: pt.positiveSoft, borderRadius: PayPactRadius.full,
                      boxShadow: pt.shadowSm,
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.check_rounded, size: 12, color: pt.positive),
                      const SizedBox(width: 6),
                      Text('Settled',
                        style: PayPactTypography.bodySm.copyWith(
                            color: pt.positive, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                )),
                Positioned(bottom: 28, left: 6, child: Transform.rotate(
                  angle: -0.09,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: pt.surface, borderRadius: PayPactRadius.full,
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
                    left: 0, right: 0,
                    child: Center(
                      child: Transform.rotate(
                        angle: ((2 - i) - 1) * 0.05,
                        child: Opacity(
                          opacity: i == receipts.length - 1 ? 1 : 0.85 - (receipts.length - 1 - i) * 0.18,
                          child: _ReceiptCard(r: receipts[i], topMost: i == receipts.length - 1),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 42),
          Text('02 · 03',
            style: PayPactTypography.label.copyWith(color: pt.accent, letterSpacing: 1.6)),
          const SizedBox(height: 14),
          Text('Settle in a tap.\nOr just a soft nudge.',
            style: PayPactTypography.displayLg.copyWith(color: pt.ink)),
          const SizedBox(height: 14),
          SizedBox(
            width: 300,
            child: Text(
              'Smart reminders that respect the room — no late-fee energy, ever.',
              style: PayPactTypography.bodyLg.copyWith(color: pt.ink2, height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _Receipt {
  final int amount; final String who; final bool positive;
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
      width: 220, padding: const EdgeInsets.all(18),
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
              style: PayPactTypography.label.copyWith(color: pt.ink3, fontSize: 9, letterSpacing: 1.2)),
            const Spacer(),
            if (topMost) Container(
              width: 24, height: 24,
              decoration: BoxDecoration(color: pt.positive, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
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
    const people = ['Priya Shah','Rohan Khan','Ankit Rai','Maya Sen','Sam Lee','Tara Iyer'];

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
                    width: 300, height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: pt.borderStrong, width: 1.5, style: BorderStyle.solid),
                    ),
                  ),
                ),
                // Inner accent ring + glow
                Center(
                  child: Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [pt.accentSoft, pt.accentSoft.withValues(alpha: 0)],
                        stops: const [0, 0.7],
                      ),
                      border: Border.all(color: pt.border),
                    ),
                  ),
                ),
                // Center pact mark
                Center(
                  child: Container(
                    width: 78, height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1F1B16),
                      boxShadow: [
                        BoxShadow(
                          color: pt.accent.withValues(alpha: 0.35),
                          offset: const Offset(0, 12), blurRadius: 30),
                        BoxShadow(
                          color: pt.bg.withValues(alpha: 0.6),
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 36, height: 36,
                      child: CustomPaint(painter: _GlyphPainter(pt.accent, const Color(0xFFFAF7F1))),
                    ),
                  ),
                ),
                // Avatars on the ring
                for (var i = 0; i < people.length; i++) ...[
                  Builder(builder: (_) {
                    final angle = (i / people.length) * math.pi * 2 - math.pi / 2;
                    final x = math.cos(angle) * 130;
                    final y = math.sin(angle) * 130;
                    return Positioned(
                      left: 0, right: 0,
                      top: 160 + y - 22,
                      child: Transform.translate(
                        offset: Offset(x, 0),
                        child: Center(
                          child: PpAvatar(name: people[i], size: 44, border: pt.bg),
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
            style: PayPactTypography.label.copyWith(color: pt.accent, letterSpacing: 1.6)),
          const SizedBox(height: 14),
          Text('Just the people\nwho matter.',
            style: PayPactTypography.displayLg.copyWith(color: pt.ink)),
          const SizedBox(height: 14),
          SizedBox(
            width: 300,
            child: Text(
              'End-to-end encrypted. No social feed, no ads, no public history.',
              style: PayPactTypography.bodyLg.copyWith(color: pt.ink2, height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
