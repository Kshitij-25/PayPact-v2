import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/design_system/components/paypact_card.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/spacing.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/widgets/pp_atoms.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const _newItems = [
    _Notif(Icons.handshake_outlined, _Tone.positive, 'Priya settled with you',
        '₹1,200 in cash · cleared 3 open balances', '2h ago', 'View'),
    _Notif(Icons.notifications_none_rounded, _Tone.accent, 'Smart nudge ready',
        "Rohan hasn't settled ₹340 in 12 days · Goa Trip", '5h ago', 'Nudge'),
    _Notif(Icons.group_add_outlined, _Tone.neutral, 'Maya invited you',
        'Tokyo summer trip · 4 members already in', 'Yesterday', 'Join'),
  ];

  static const _earlier = [
    _Earlier(Icons.receipt_long_outlined, 'Hotel Taj receipt scanned',
        'Auto-saved to Goa Trip · ₹4,000', '1d'),
    _Earlier(Icons.trending_up_rounded, "You've been added to Outings",
        'Ankit added you · 3 expenses to catch up on', '3d'),
    _Earlier(Icons.circle_outlined, 'Pact created — Tokyo summer',
        'You and 4 others · enjoy the trip', '1w'),
  ];

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Scaffold(
      backgroundColor: pt.bg,
      body: Stack(
        children: [
          const PpBackdropGlow(intensity: 0.06),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                  child: Row(children: [
                    PpGlassIconButton(icon: Icons.arrow_back_rounded, onTap: () => context.pop()),
                    const Spacer(),
                    Text('Notifications',
                      style: PayPactTypography.bodyMd.copyWith(
                          color: pt.ink, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('Mark all read',
                      style: PayPactTypography.bodySm.copyWith(
                          color: pt.accent, fontWeight: FontWeight.w600)),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 14, 28, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('The quiet inbox.',
                        style: PayPactTypography.displayLg.copyWith(color: pt.ink)),
                      const SizedBox(height: 6),
                      Text("We only ping you when it actually matters.",
                        style: PayPactTypography.bodyMd.copyWith(color: pt.ink2)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                        PayPactSpacing.s6, 0, PayPactSpacing.s6, 120),
                    children: [
                      Text('NEW · 3',
                        style: PayPactTypography.label.copyWith(
                            color: pt.ink3, letterSpacing: 1.5)),
                      const SizedBox(height: 10),
                      PayPactCard(
                        padding: EdgeInsets.zero,
                        child: Column(children: [
                          for (var i = 0; i < _newItems.length; i++) ...[
                            if (i > 0) Divider(color: pt.border, height: 1),
                            _NewTile(n: _newItems[i]),
                          ],
                        ]),
                      ),
                      const SizedBox(height: 14),
                      Text('EARLIER',
                        style: PayPactTypography.label.copyWith(
                            color: pt.ink3, letterSpacing: 1.5)),
                      const SizedBox(height: 10),
                      Opacity(
                        opacity: 0.86,
                        child: PayPactCard(
                          padding: EdgeInsets.zero,
                          child: Column(children: [
                            for (var i = 0; i < _earlier.length; i++) ...[
                              if (i > 0) Divider(color: pt.border, height: 1),
                              _EarlierTile(e: _earlier[i]),
                            ],
                          ]),
                        ),
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

enum _Tone { positive, accent, neutral }

class _Notif {
  final IconData icon; final _Tone tone; final String title;
  final String sub; final String when; final String action;
  const _Notif(this.icon, this.tone, this.title, this.sub, this.when, this.action);
}

class _Earlier {
  final IconData icon; final String title; final String sub; final String when;
  const _Earlier(this.icon, this.title, this.sub, this.when);
}

class _NewTile extends StatelessWidget {
  const _NewTile({required this.n});
  final _Notif n;
  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final tone = switch (n.tone) {
      _Tone.positive => [pt.positiveSoft, pt.positive],
      _Tone.accent   => [pt.accentSoft, pt.accent],
      _Tone.neutral  => [pt.surfaceAlt, pt.ink2],
    };
    final chipTone = switch (n.tone) {
      _Tone.positive => PpChipTone.positive,
      _Tone.accent   => PpChipTone.accent,
      _Tone.neutral  => PpChipTone.neutral,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6, height: 6,
            margin: const EdgeInsets.only(top: 4, right: 4),
            decoration: BoxDecoration(
                color: pt.accent, shape: BoxShape.circle),
          ),
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: tone[0], shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(n.icon, size: 18, color: tone[1]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.title,
                  style: PayPactTypography.bodyMd.copyWith(
                      color: pt.ink, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(n.sub,
                  style: PayPactTypography.bodySm.copyWith(
                      color: pt.ink2, height: 1.5)),
                const SizedBox(height: 8),
                Row(children: [
                  PpChip(label: n.action, tone: chipTone),
                  const SizedBox(width: 10),
                  Text(n.when,
                    style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EarlierTile extends StatelessWidget {
  const _EarlierTile({required this.e});
  final _Earlier e;
  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
              color: pt.surfaceAlt, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(e.icon, size: 16, color: pt.ink2),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e.title, style: PayPactTypography.bodyMd.copyWith(
                color: pt.ink2, fontWeight: FontWeight.w600)),
            Text(e.sub, style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
          ],
        )),
        Text(e.when,
          style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
      ]),
    );
  }
}
