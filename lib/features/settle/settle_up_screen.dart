import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/design_system/components/paypact_button.dart';
import 'package:paypact/design_system/components/paypact_card.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/widgets/pp_atoms.dart';

class SettleUpScreen extends StatelessWidget {
  const SettleUpScreen({super.key, required this.groupId});
  final String groupId;

  static const _methods = [
    _Method('Mark as paid in cash', 'No transfer · just record it',
        Icons.payments_outlined, true),
    _Method('PayPact wallet', 'Instant · zero fees',
        Icons.qr_code_rounded, false),
    _Method('External UPI', 'PhonePe, GPay, Paytm',
        Icons.link_rounded, false),
  ];

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Scaffold(
      backgroundColor: pt.bg,
      body: Stack(
        children: [
          const PpBackdropGlow(intensity: 0.12),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                  child: Row(children: [
                    PpGlassIconButton(icon: Icons.arrow_back_rounded, onTap: () => context.pop()),
                    const Spacer(),
                    Text('Settle up',
                      style: PayPactTypography.bodyMd.copyWith(
                          color: pt.ink, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('Step 1 / 2',
                      style: PayPactTypography.bodyMd.copyWith(color: pt.ink3)),
                  ]),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 18, 28, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WHO PAID WHO',
                          style: PayPactTypography.label.copyWith(
                              color: pt.accent, letterSpacing: 1.6)),
                        const SizedBox(height: 14),
                        Text("Just three taps —\nand you're square.",
                          style: PayPactTypography.displayLg.copyWith(color: pt.ink)),
                        const SizedBox(height: 24),
                        // From → To
                        Row(children: [
                          Expanded(child: Column(children: [
                            const PpAvatar(name: 'Kshitij', size: 68),
                            const SizedBox(height: 8),
                            Text('FROM',
                              style: PayPactTypography.label.copyWith(
                                  color: pt.ink3, letterSpacing: 1.5)),
                            const SizedBox(height: 2),
                            Text('You',
                              style: PayPactTypography.bodyMd.copyWith(
                                  color: pt.ink, fontWeight: FontWeight.w600)),
                          ])),
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: pt.surface, shape: BoxShape.circle,
                              border: Border.all(color: pt.border),
                              boxShadow: pt.shadowSm,
                            ),
                            alignment: Alignment.center,
                            child: Icon(Icons.arrow_forward_rounded,
                                color: pt.accent, size: 22),
                          ),
                          Expanded(child: Column(children: [
                            const PpAvatar(name: 'Priya Shah', size: 68),
                            const SizedBox(height: 8),
                            Text('TO',
                              style: PayPactTypography.label.copyWith(
                                  color: pt.ink3, letterSpacing: 1.5)),
                            const SizedBox(height: 2),
                            Text('Priya',
                              style: PayPactTypography.bodyMd.copyWith(
                                  color: pt.ink, fontWeight: FontWeight.w600)),
                          ])),
                        ]),
                        const SizedBox(height: 30),
                        // Amount picker
                        Center(child: Column(children: [
                          Text('AMOUNT',
                            style: PayPactTypography.label.copyWith(
                                color: pt.ink3, letterSpacing: 1.6)),
                          const SizedBox(height: 10),
                          Text('₹1,200',
                            style: PayPactTypography.amountHero.copyWith(
                                color: pt.accent, fontSize: 60)),
                          const SizedBox(height: 6),
                          Text("Suggested · clears all open balances with Priya",
                            style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
                        ])),
                        const SizedBox(height: 24),
                        Center(child: Wrap(
                          spacing: 8,
                          children: [
                            _AmtChip(label: '₹500', selected: false),
                            _AmtChip(label: '₹1,200', selected: true),
                            _AmtChip(label: 'Custom', selected: false),
                          ],
                        )),
                        const SizedBox(height: 24),
                        Text('METHOD',
                          style: PayPactTypography.label.copyWith(
                              color: pt.ink3, letterSpacing: 1.5)),
                        const SizedBox(height: 8),
                        PayPactCard(
                          padding: EdgeInsets.zero,
                          child: Column(children: [
                            for (var i = 0; i < _methods.length; i++) ...[
                              if (i > 0) Divider(color: pt.border, height: 1),
                              _MethodTile(m: _methods[i]),
                            ],
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [pt.bg, pt.bg.withValues(alpha: 0)],
                  stops: const [0.7, 1.0],
                ),
              ),
              child: PayPactButton(
                onPressed: () => context.push('/group/$groupId/settle-success'),
                label: 'Confirm — ₹1,200 to Priya',
                variant: PayPactButtonVariant.accent,
                size: PayPactButtonSize.large,
                isFullWidth: true,
                leftIcon: Icons.check_rounded,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmtChip extends StatelessWidget {
  const _AmtChip({required this.label, required this.selected});
  final String label; final bool selected;
  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? pt.accent : pt.surface,
        borderRadius: PayPactRadius.full,
        border: Border.all(color: selected ? pt.accent : pt.border),
      ),
      child: Text(label,
        style: PayPactTypography.bodyMd.copyWith(
          color: selected ? Colors.white : pt.ink,
          fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}

class _Method {
  final String label; final String sub; final IconData icon; final bool selected;
  const _Method(this.label, this.sub, this.icon, this.selected);
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({required this.m});
  final _Method m;
  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: m.selected ? pt.accentSoft : pt.surfaceAlt,
            borderRadius: PayPactRadius.sm,
          ),
          alignment: Alignment.center,
          child: Icon(m.icon, size: 18,
              color: m.selected ? pt.accentInk : pt.ink2),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.label, style: PayPactTypography.bodyMd.copyWith(
                color: pt.ink, fontWeight: FontWeight.w600)),
            Text(m.sub, style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
          ],
        )),
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            color: m.selected ? pt.accent : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: m.selected ? pt.accent : pt.border, width: 2),
          ),
          alignment: Alignment.center,
          child: m.selected
            ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
            : null,
        ),
      ]),
    );
  }
}
