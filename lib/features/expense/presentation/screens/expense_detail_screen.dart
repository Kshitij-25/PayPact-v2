import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/design_system/components/paypact_button.dart';
import 'package:paypact/design_system/components/paypact_card.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/spacing.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/widgets/pp_atoms.dart';

class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({super.key, required this.expenseId, this.groupId});
  final String expenseId;
  final String? groupId;

  static const _splits = [
    _SplitRow('You', 'paid · ₹4,000', 800, _SplitTag.paid),
    _SplitRow('Priya', 'owes you', 800, _SplitTag.none),
    _SplitRow('Rohan', 'owes you', 800, _SplitTag.none),
    _SplitRow('Ankit', 'paid in cash', 800, _SplitTag.settled),
    _SplitRow('Maya', 'owes you', 800, _SplitTag.none),
  ];

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final stayTone = PpCategoryDisc.tone(context, PpCategory.stay);

    return Scaffold(
      backgroundColor: pt.bg,
      body: Stack(
        children: [
          // Hero band
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [stayTone[0], pt.bg],
                  stops: const [0, 0.95],
                ),
              ),
              child: Stack(clipBehavior: Clip.none, children: [
                Positioned(top: 30, right: -30,
                  child: Opacity(opacity: 0.18,
                    child: const Text('🏨', style: TextStyle(fontSize: 200)))),
              ]),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Row(children: [
                      PpGlassIconButton(icon: Icons.arrow_back_rounded, onTap: () => context.pop()),
                      const Spacer(),
                      PpGlassIconButton(
                        icon: Icons.edit_outlined,
                        onTap: groupId != null
                          ? () => context.push('/group/$groupId/expense/$expenseId/edit')
                          : null,
                      ),
                      const SizedBox(width: 10),
                      PpGlassIconButton(icon: Icons.more_horiz_rounded, onTap: () {}),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 26, 28, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const PpChip(label: '🛏  Stay · Goa Trip', tone: PpChipTone.neutral),
                        const SizedBox(height: 14),
                        Text('Hotel Taj — 2 nights',
                          style: PayPactTypography.headingXl.copyWith(color: pt.ink)),
                        const SizedBox(height: 8),
                        Text('₹4,000',
                          style: PayPactTypography.amountHero.copyWith(
                              color: pt.ink, fontSize: 56)),
                        const SizedBox(height: 8),
                        Text.rich(
                          TextSpan(
                            style: PayPactTypography.bodyMd.copyWith(color: pt.ink2),
                            children: [
                              const TextSpan(text: 'You paid · split equally · '),
                              TextSpan(text: '+₹3,200 to you',
                                style: TextStyle(
                                  color: pt.positive, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Split list
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: PayPactSpacing.s6),
                    child: PpSectionLabel(
                      label: 'SPLIT · 5 PEOPLE',
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: PayPactSpacing.s6),
                    child: PayPactCard(
                      padding: EdgeInsets.zero,
                      child: Column(children: [
                        for (var i = 0; i < _splits.length; i++) ...[
                          if (i > 0) Divider(color: pt.border, height: 1),
                          _SplitTile(s: _splits[i]),
                        ],
                      ]),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Meta
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: PayPactSpacing.s6),
                    child: PayPactCard(
                      padding: EdgeInsets.zero,
                      child: Column(children: [
                        _MetaRow(icon: Icons.calendar_today_outlined,
                          label: 'Date', value: 'Apr 17, 2026 · 7:42 PM'),
                        Divider(color: pt.border, height: 1),
                        _MetaRow(icon: Icons.receipt_long_outlined,
                          label: 'Receipt', value: 'IMG_2031.jpg', accent: true),
                        Divider(color: pt.border, height: 1),
                        _MetaRow(icon: Icons.edit_outlined,
                          label: 'Notes', value: 'Booked direct, no breakfast.'),
                      ]),
                    ),
                  ),
                  // Actions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        PayPactSpacing.s6, 12, PayPactSpacing.s6, 0),
                    child: Row(children: [
                      Expanded(child: PayPactButton(
                        onPressed: () {}, label: 'Remind 3 people',
                        variant: PayPactButtonVariant.secondary,
                        isFullWidth: true,
                        leftIcon: Icons.notifications_none_rounded,
                      )),
                      const SizedBox(width: 10),
                      PayPactButton(
                        onPressed: () {}, label: '',
                        variant: PayPactButtonVariant.danger,
                        leftIcon: Icons.delete_outline_rounded,
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _SplitTag { none, paid, settled }

class _SplitRow {
  final String name; final String sub; final int amount; final _SplitTag tag;
  const _SplitRow(this.name, this.sub, this.amount, this.tag);
}

class _SplitTile extends StatelessWidget {
  const _SplitTile({required this.s});
  final _SplitRow s;
  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        PpAvatar(name: s.name, size: 36),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.name, style: PayPactTypography.bodyMd.copyWith(
                color: pt.ink, fontWeight: FontWeight.w600)),
            Text(s.sub, style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
          ],
        )),
        if (s.tag != _SplitTag.none) ...[
          PpChip(
            label: s.tag == _SplitTag.paid ? 'PAID' : 'SETTLED',
            tone: PpChipTone.positive,
          ),
          const SizedBox(width: 8),
        ],
        Text('₹${s.amount}',
          style: PayPactTypography.amountLg.copyWith(
              color: pt.ink, fontSize: 15, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label,
    required this.value, this.accent = false});
  final IconData icon; final String label; final String value; final bool accent;
  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
              color: pt.surfaceAlt, borderRadius: PayPactRadius.sm),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: pt.ink2),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
              style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
            Text(value,
              style: PayPactTypography.bodyMd.copyWith(
                  color: accent ? pt.accent : pt.ink,
                  fontWeight: accent ? FontWeight.w600 : FontWeight.w400)),
          ],
        )),
        if (accent) Icon(Icons.chevron_right_rounded, color: pt.ink3),
      ]),
    );
  }
}
