import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/core/utils/currency_utils.dart';
import 'package:paypact/core/utils/responsive.dart';
import 'package:paypact/design_system/components/paypact_button.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/widgets/pp_atoms.dart';

class SettleSuccessScreen extends StatelessWidget {
  const SettleSuccessScreen({
    super.key,
    required this.groupId,
    required this.fromUserName,
    required this.toUserName,
    required this.amount,
    required this.receiptId,
    this.groupName = '',
    this.currency = '₹',
  });

  final String groupId;
  final String groupName;
  final String fromUserName;
  final String toUserName;
  final double amount;
  final String receiptId;
  final String currency;

  String get _sym => currencyOf(currency).symbol;

  String get _amountStr {
    final formatted = amount.truncateToDouble() == amount
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    return '$_sym$formatted';
  }

  String get _dateStr =>
      DateFormat('MMM d, yyyy · h:mm a').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstName = toUserName.split(' ').first;

    if (context.isDesktop) {
      return _buildWebModal(context, pt, isDark, firstName);
    }

    return Scaffold(
      backgroundColor: pt.bg,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 380,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
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
                  Center(
                    child: Text('SETTLED',
                        style: PayPactTypography.label.copyWith(
                            color: pt.positive, letterSpacing: 1.6)),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      'You and $firstName\nare square.',
                      textAlign: TextAlign.center,
                      style:
                          PayPactTypography.displayLg.copyWith(color: pt.ink),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: SizedBox(
                      width: 300,
                      child: Text(
                        '$_amountStr recorded as cash. $firstName will get a notification.',
                        textAlign: TextAlign.center,
                        style: PayPactTypography.bodyLg
                            .copyWith(color: pt.ink2, height: 1.55),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  PpGlassCard(
                    padding: const EdgeInsets.all(20),
                    opacity: 0.85,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('RECEIPT',
                                    style: PayPactTypography.label.copyWith(
                                        color: pt.ink3, letterSpacing: 1.6)),
                                const SizedBox(height: 3),
                                Text(receiptId,
                                    style: PayPactTypography.amountMd
                                        .copyWith(color: pt.ink)),
                              ],
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                                color: pt.surface,
                                borderRadius: PayPactRadius.sm,
                                border: Border.all(color: pt.border)),
                            alignment: Alignment.center,
                            child: Icon(Icons.qr_code_2_rounded,
                                color: pt.ink2),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        const PpDashedDivider(),
                        const SizedBox(height: 14),
                        _RKv(label: 'From', value: fromUserName),
                        const SizedBox(height: 8),
                        _RKv(label: 'To', value: toUserName),
                        const SizedBox(height: 8),
                        _RKv(label: 'Method', value: 'Cash · marked paid'),
                        const SizedBox(height: 8),
                        _RKv(label: 'Date', value: _dateStr),
                        const SizedBox(height: 14),
                        const PpDashedDivider(),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(
                            child: Text('Total',
                                style: PayPactTypography.headingMd
                                    .copyWith(color: pt.ink)),
                          ),
                          Text(_amountStr,
                              style: PayPactTypography.amountLg
                                  .copyWith(color: pt.positive)),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  PayPactButton(
                    onPressed: () => context.go(AppRoutes.home),
                    label: 'Done',
                    variant: PayPactButtonVariant.accent,
                    size: PayPactButtonSize.large,
                    isFullWidth: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────
  // Web modal (desktop only)
  // ───────────────────────────────────────────────────────────────────

  String _handle(String name) =>
      '@${name.split(' ').first.toLowerCase()}';

  Widget _buildWebModal(BuildContext context, PayPactThemeExtension pt,
      bool isDark, String firstName) {
    final timeStr = DateFormat('h:mm a').format(DateTime.now());
    final totalStr = '$_sym${NumberFormat('#,##0.00').format(amount)}';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(color: Colors.black.withValues(alpha: 0.18)),
            ),
          ),
          Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 440,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.92,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [pt.positiveSoft, pt.bg],
                    stops: const [0, 0.42],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 80,
                      offset: const Offset(0, 24),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 36, 28, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(child: _CheckRing(isDark: isDark)),
                        const SizedBox(height: 28),
                        Center(
                          child: Text('SETTLED · $timeStr',
                              style: PayPactTypography.label.copyWith(
                                  color: pt.positive, letterSpacing: 1.6)),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text('You and $firstName\nare square.',
                              textAlign: TextAlign.center,
                              style: PayPactTypography.displayLg
                                  .copyWith(color: pt.ink, fontSize: 30)),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: SizedBox(
                            width: 320,
                            child: Text(
                              '$_amountStr recorded as cash. $firstName will get a calm notification — no follow-up needed.',
                              textAlign: TextAlign.center,
                              style: PayPactTypography.bodyMd
                                  .copyWith(color: pt.ink2, height: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: pt.surface,
                            borderRadius: PayPactRadius.lg,
                            border: Border.all(color: pt.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('RECEIPT',
                                          style: PayPactTypography.label
                                              .copyWith(
                                                  color: pt.ink3,
                                                  letterSpacing: 1.6,
                                                  fontSize: 10)),
                                      const SizedBox(height: 3),
                                      Text(receiptId,
                                          style: PayPactTypography.amountMd
                                              .copyWith(color: pt.ink)),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                      color: pt.surfaceAlt,
                                      borderRadius: PayPactRadius.sm,
                                      border: Border.all(color: pt.border)),
                                  alignment: Alignment.center,
                                  child: Icon(Icons.qr_code_2_rounded,
                                      color: pt.ink2, size: 20),
                                ),
                              ]),
                              const SizedBox(height: 16),
                              _RKv(
                                  label: 'From',
                                  value:
                                      '$fromUserName · ${_handle(fromUserName)}'),
                              const SizedBox(height: 9),
                              _RKv(
                                  label: 'To',
                                  value:
                                      '$toUserName · ${_handle(toUserName)}'),
                              if (groupName.isNotEmpty) ...[
                                const SizedBox(height: 9),
                                _RKv(label: 'Group', value: groupName),
                              ],
                              const SizedBox(height: 9),
                              _RKv(
                                  label: 'Method',
                                  value: 'Cash · marked paid'),
                              const SizedBox(height: 14),
                              const PpDashedDivider(),
                              const SizedBox(height: 14),
                              Row(children: [
                                Expanded(
                                  child: Text('Total settled',
                                      style: PayPactTypography.bodyMd.copyWith(
                                          color: pt.ink,
                                          fontWeight: FontWeight.w700)),
                                ),
                                Text(totalStr,
                                    style: PayPactTypography.amountLg
                                        .copyWith(color: pt.ink)),
                              ]),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: PayPactButton(
                                onPressed: () =>
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Share receipt — coming soon'))),
                                label: 'Share receipt',
                                variant: PayPactButtonVariant.secondary,
                                size: PayPactButtonSize.large,
                                leftIcon: Icons.ios_share_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: PayPactButton(
                                onPressed: () => context.canPop()
                                    ? context.pop()
                                    : context.go(AppRoutes.home),
                                label: 'Done',
                                variant: PayPactButtonVariant.accent,
                                size: PayPactButtonSize.large,
                                isFullWidth: true,
                                leftIcon: Icons.check_rounded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
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
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Row(children: [
      Expanded(
          child: Text(label,
              style: PayPactTypography.bodyMd.copyWith(color: pt.ink2))),
      Text(value,
          style: PayPactTypography.bodyMd
              .copyWith(color: pt.ink, fontWeight: FontWeight.w600)),
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
      width: 160,
      height: 160,
      child: Stack(children: [
        Center(
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: pt.positiveSoft,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: pt.positive
                        .withValues(alpha: isDark ? 0.30 : 0.25),
                    blurRadius: 60),
              ],
            ),
          ),
        ),
        Center(
          child: Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              color: pt.surface,
              shape: BoxShape.circle,
              border: Border.all(color: pt.border),
            ),
          ),
        ),
        Center(
          child: SizedBox(
            width: 60,
            height: 60,
            child: CustomPaint(painter: _CheckPainter(pt.positive)),
          ),
        ),
      ]),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.c);
  final Color c;

  @override
  void paint(Canvas canvas, Size s) {
    final ring = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(s.width / 2, s.height / 2), 26, ring);
    final p = Path()
      ..moveTo(s.width * 0.30, s.height * 0.52)
      ..lineTo(s.width * 0.43, s.height * 0.65)
      ..lineTo(s.width * 0.70, s.height * 0.37);
    final check = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(p, check);
  }

  @override
  bool shouldRepaint(_) => false;
}
