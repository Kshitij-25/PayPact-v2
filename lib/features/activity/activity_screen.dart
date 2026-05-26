import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/design_system/components/paypact_bottom_nav.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/spacing.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/widgets/pp_atoms.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  static const _days = <_Day>[
    _Day('TODAY', [
      _Item(
          who: 'You',
          verb: 'added',
          what: 'Beach shack dinner',
          where: 'Goa Trip',
          amount: 2400,
          tone: _Tone.neutral,
          icon: Icons.restaurant_outlined,
          cat: PpCategory.food,
          when: '2:14 PM',
          expenseId: 'beach-shack',
          groupId: 'goa-trip'),
      _Item(
          who: 'Priya',
          verb: 'settled with',
          what: 'you',
          sub: 'cleared 3 open balances',
          amount: 1200,
          tone: _Tone.positive,
          icon: Icons.handshake_outlined,
          cat: PpCategory.home,
          when: '11:02 AM',
          expenseId: 'priya-settled',
          groupId: null),
    ]),
    _Day('YESTERDAY', [
      _Item(
          who: 'You',
          verb: 'paid for',
          what: 'Hotel Taj — 2 nights',
          where: 'Goa Trip',
          amount: 4000,
          tone: _Tone.neutral,
          icon: Icons.hotel_outlined,
          cat: PpCategory.stay,
          when: '9:30 PM',
          expenseId: 'hotel-taj',
          groupId: 'goa-trip'),
      _Item(
          who: 'Ankit',
          verb: 'added',
          what: 'Coffee',
          where: 'Outings',
          sub: 'you owe ₹180',
          amount: 540,
          tone: _Tone.negative,
          icon: Icons.local_cafe_outlined,
          cat: PpCategory.food,
          when: '5:45 PM',
          expenseId: 'coffee',
          groupId: 'outings'),
      _Item(
          who: 'You',
          verb: 'joined',
          what: 'Tokyo summer trip',
          sub: 'via invite from Maya',
          tone: _Tone.neutral,
          icon: Icons.group_add_outlined,
          cat: PpCategory.trip,
          when: '3:00 PM',
          expenseId: null,
          groupId: 'tokyo-summer-trip'),
    ]),
    _Day('APR 16', [
      _Item(
          who: 'Maya',
          verb: 'reminded',
          what: 'you to settle',
          sub: '₹820 in Outings',
          tone: _Tone.pending,
          icon: Icons.notifications_none_rounded,
          cat: PpCategory.home,
          when: '10:21 AM',
          expenseId: null,
          groupId: null),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Scaffold(
      backgroundColor: pt.bg,
      bottomNavigationBar: PayPactBottomNav(
        currentIndex: 2,
        onTap: (i) => [
          () => context.go(AppRoutes.home),
          () => context.go(AppRoutes.groups),
          () => context.go(AppRoutes.activity),
          () => context.go(AppRoutes.profile),
        ][i](),
        onFabTap: () => context.push('/group/create'),
      ),
      body: Stack(
        children: [
          const PpBackdropGlow(intensity: 0.06),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(PayPactSpacing.s6,
                      PayPactSpacing.s1, PayPactSpacing.s6, PayPactSpacing.s4),
                  child: Row(children: [
                    Text('RECENT',
                        style: PayPactTypography.label
                            .copyWith(color: pt.ink3, letterSpacing: 1.6)),
                    const Spacer(),
                    PpGlassIconButton(
                        icon: Icons.tune_rounded, onTap: () {}),
                    const SizedBox(width: 10),
                    PpGlassIconButton(
                        icon: Icons.search_rounded, onTap: () {}),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      PayPactSpacing.s6, 0, PayPactSpacing.s6, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Activity.',
                          style: PayPactTypography.displayLg
                              .copyWith(color: pt.ink)),
                      const SizedBox(height: 6),
                      Text.rich(
                        TextSpan(
                          style:
                              PayPactTypography.bodyMd.copyWith(color: pt.ink2),
                          children: [
                            const TextSpan(text: '14 events this week · '),
                            TextSpan(
                                text: '3 need your attention',
                                style: TextStyle(
                                    color: pt.accent,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      PayPactSpacing.s6, 0, PayPactSpacing.s6, 14),
                  child: const Wrap(spacing: 8, children: [
                    PpChip(label: 'All', tone: PpChipTone.accent),
                    PpChip(label: 'Expenses', tone: PpChipTone.ghost),
                    PpChip(label: 'Settlements', tone: PpChipTone.ghost),
                    PpChip(label: 'People', tone: PpChipTone.ghost),
                  ]),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                        PayPactSpacing.s6, 0, PayPactSpacing.s6, 120),
                    itemCount: _days.length,
                    itemBuilder: (_, di) => _DaySection(d: _days[di]),
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

enum _Tone { neutral, positive, negative, pending }

class _Item {
  final String who;
  final String verb;
  final String what;
  final String? where;
  final String? sub;
  final int? amount;
  final _Tone tone;
  final IconData icon;
  final PpCategory cat;
  final String when;
  final String? expenseId;
  final String? groupId;
  const _Item(
      {required this.who,
      required this.verb,
      required this.what,
      this.where,
      this.sub,
      this.amount,
      required this.tone,
      required this.icon,
      required this.cat,
      required this.when,
      required this.expenseId,
      required this.groupId});
}

class _Day {
  final String date;
  final List<_Item> items;
  const _Day(this.date, this.items);
}

class _DaySection extends StatelessWidget {
  const _DaySection({required this.d});
  final _Day d;
  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 14, 0, 6),
          child: Text(d.date,
              style: PayPactTypography.label
                  .copyWith(color: pt.ink3, letterSpacing: 1.5)),
        ),
        Stack(children: [
          Positioned(
            left: 19,
            top: 6,
            bottom: 6,
            child: Container(width: 1.5, color: pt.border),
          ),
          Column(
            children: [
              for (final it in d.items) _Tile(item: it),
            ],
          ),
        ]),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item});
  final _Item item;
  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final amountColor = switch (item.tone) {
      _Tone.positive => pt.positive,
      _Tone.negative => pt.negative,
      _Tone.pending => pt.warn,
      _Tone.neutral => pt.ink2,
    };

    final tappable = item.expenseId != null;

    return GestureDetector(
      onTap: tappable
          ? () => context.push(
                '/expense/${item.expenseId}',
                extra: item.groupId != null ? {'groupId': item.groupId} : null,
              )
          : item.groupId != null
              ? () => context.push('/group/${item.groupId}')
              : null,
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PpCategoryDisc(category: item.cat, icon: item.icon, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      style: PayPactTypography.bodyMd
                          .copyWith(color: pt.ink, height: 1.45),
                      children: [
                        TextSpan(
                            text: item.who,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        TextSpan(
                            text: ' ${item.verb} ',
                            style: TextStyle(color: pt.ink2)),
                        TextSpan(
                            text: item.what,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        if (item.where != null)
                          TextSpan(
                              text: ' in ${item.where}',
                              style: TextStyle(color: pt.ink2)),
                      ],
                    ),
                  ),
                  if (item.sub != null) ...[
                    const SizedBox(height: 2),
                    Text(item.sub!,
                        style: PayPactTypography.bodySm
                            .copyWith(color: pt.ink3)),
                  ],
                  const SizedBox(height: 6),
                  Row(children: [
                    Text(item.when,
                        style: PayPactTypography.label
                            .copyWith(color: pt.ink3, fontSize: 9.5)),
                    if (item.amount != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        '${item.tone == _Tone.positive ? '+' : ''}${item.tone == _Tone.negative ? '−' : ''}₹${PpAmount.format(item.amount!).replaceAll('₹', '')}',
                        style: PayPactTypography.amountSm.copyWith(
                            color: amountColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
