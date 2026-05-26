import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/design_system/components/paypact_button.dart';
import 'package:paypact/design_system/components/paypact_card.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/spacing.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/widgets/pp_atoms.dart';

class AddMembersScreen extends StatefulWidget {
  const AddMembersScreen({super.key});

  @override
  State<AddMembersScreen> createState() => _AddMembersScreenState();
}

class _AddMembersScreenState extends State<AddMembersScreen> {
  static const _circle = [
    _Person('Priya Shah', 'PS', '@priya', 'In 3 groups with you', 5.0,
        true, false),
    _Person('Rohan Khan', 'RK', '@rohan', 'Last group: Goa Trip', 4.0,
        true, false),
    _Person('Ankit Rai', 'AR', '@ankit', 'Settled with you in 1.4d', 5.0,
        false, true),
    _Person('Tara Iyer', 'TI', '@tara_i', 'New to PayPact · invite', 3.0,
        false, false, isInvite: true),
  ];

  final Set<String> _selected = {'Ankit Rai'};

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final memberCount = _selected.length + 1; // +1 for "You"

    final selectedNames = [
      'You',
      ..._circle
          .where((p) => _selected.contains(p.name) && p.name != 'Tara Iyer')
          .map((p) => p.name.split(' ').first),
      if (_selected.contains('Tara Iyer')) 'Sam',
    ];

    return Scaffold(
      backgroundColor: pt.bg,
      body: Stack(
        children: [
          const PpBackdropGlow(intensity: 0.08),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                  child: Row(children: [
                    PpGlassIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => context.pop(),
                    ),
                    const Spacer(),
                    Text('Add members',
                        style: PayPactTypography.bodyMd.copyWith(
                            color: pt.ink, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('2 of 2',
                        style: PayPactTypography.bodyMd
                            .copyWith(color: pt.ink3)),
                  ]),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                        PayPactSpacing.s6, 4, PayPactSpacing.s6, 160),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Group name chip
                        Text('TOKYO SUMMER TRIP',
                            style: PayPactTypography.label.copyWith(
                                color: pt.accent, letterSpacing: 1.6)),
                        const SizedBox(height: 14),
                        Text("Who's in?",
                            style: PayPactTypography.displayLg
                                .copyWith(color: pt.ink)),
                        const SizedBox(height: 8),
                        Text(
                            'Pick from your circle, or share a link — PayPact will keep it warm.',
                            style: PayPactTypography.bodyLg
                                .copyWith(color: pt.ink2)),
                        const SizedBox(height: 22),

                        // Selected members row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // You chip (always first)
                              _YouChip(),
                              const SizedBox(width: 8),
                              for (final name in selectedNames.skip(1)) ...[
                                _SelectedChip(
                                  name: name,
                                  initials: name
                                      .substring(0, 2)
                                      .toUpperCase(),
                                  onRemove: () => setState(() =>
                                      _selected.removeWhere((s) =>
                                          s.startsWith(name))),
                                ),
                                const SizedBox(width: 8),
                              ],
                              _AddChip(onTap: () {}),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Search field
                        Container(
                          height: 52,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: pt.surface,
                            borderRadius: PayPactRadius.md,
                            border: Border.all(color: pt.border),
                            boxShadow: pt.shadowSm,
                          ),
                          child: Row(children: [
                            Icon(Icons.search_rounded,
                                color: pt.ink3, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Search by name, phone, @handle…',
                                style: PayPactTypography.bodyMd
                                    .copyWith(color: pt.ink3),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: pt.surfaceAlt,
                                borderRadius: PayPactRadius.sm,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.qr_code_scanner_rounded,
                                      color: pt.ink2, size: 14),
                                  const SizedBox(width: 4),
                                  Text('QR',
                                      style: PayPactTypography.label
                                          .copyWith(
                                              color: pt.ink2,
                                              letterSpacing: 1)),
                                ],
                              ),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 12),

                        // Invite link card
                        PayPactCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: pt.accentSoft,
                                borderRadius: PayPactRadius.sm,
                              ),
                              alignment: Alignment.center,
                              child: Icon(Icons.link_rounded,
                                  color: pt.accent, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Share an invite link',
                                      style: PayPactTypography.bodyMd
                                          .copyWith(
                                              color: pt.ink,
                                              fontWeight: FontWeight.w600)),
                                  Text(
                                    'paypact.link/tokyo-summer-4…',
                                    style: PayPactTypography.bodySm
                                        .copyWith(color: pt.ink3),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: pt.accentSoft,
                                borderRadius: PayPactRadius.sm,
                              ),
                              child: Text('Copy',
                                  style: PayPactTypography.bodyMd.copyWith(
                                      color: pt.accent,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 22),

                        // From your circle
                        Text('FROM YOUR CIRCLE',
                            style: PayPactTypography.label.copyWith(
                                color: pt.ink3, letterSpacing: 1.5)),
                        const SizedBox(height: 10),
                        PayPactCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (int i = 0; i < _circle.length; i++) ...[
                                if (i > 0) Divider(color: pt.border, height: 1),
                                _PersonRow(
                                  person: _circle[i],
                                  selected:
                                      _selected.contains(_circle[i].name),
                                  onToggle: () => setState(() {
                                    if (_selected.contains(_circle[i].name)) {
                                      _selected.remove(_circle[i].name);
                                    } else {
                                      _selected.add(_circle[i].name);
                                    }
                                  }),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Sticky CTA
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [pt.bg, pt.bg.withValues(alpha: 0)],
                  stops: const [0.7, 1.0],
                ),
              ),
              child: PayPactButton(
                onPressed: () => context.go(AppRoutes.home),
                label: 'Create group · $memberCount members',
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

class _YouChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: pt.ink,
        borderRadius: PayPactRadius.full,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: pt.accent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text('KR',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
          const SizedBox(width: 7),
          Text('You',
              style: PayPactTypography.bodyMd.copyWith(
                  color: pt.bg, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _SelectedChip extends StatelessWidget {
  const _SelectedChip(
      {required this.name,
      required this.initials,
      required this.onRemove});
  final String name;
  final String initials;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: pt.surface,
        borderRadius: PayPactRadius.full,
        border: Border.all(color: pt.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PpAvatar(name: name, size: 22),
          const SizedBox(width: 7),
          Text(name,
              style: PayPactTypography.bodyMd.copyWith(
                  color: pt.ink, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child:
                Icon(Icons.close_rounded, size: 14, color: pt.ink3),
          ),
        ],
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  const _AddChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: pt.surface,
          borderRadius: PayPactRadius.full,
          border: Border.all(color: pt.border, width: 1.5),
        ),
        child: Text('+ Add',
            style: PayPactTypography.bodyMd.copyWith(
                color: pt.ink2, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}

class _Person {
  final String name;
  final String initials;
  final String handle;
  final String sub;
  final double trust;
  final bool isRecent;
  final bool isAdded;
  final bool isInvite;
  const _Person(this.name, this.initials, this.handle, this.sub, this.trust,
      this.isRecent, this.isAdded,
      {this.isInvite = false});
}

class _PersonRow extends StatelessWidget {
  const _PersonRow(
      {required this.person,
      required this.selected,
      required this.onToggle});
  final _Person person;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;

    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            PpAvatar(name: person.name, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(person.name,
                          style: PayPactTypography.bodyMd.copyWith(
                              color: pt.ink,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      if (person.isRecent)
                        _Badge(label: 'RECENT', color: pt.accentSoft,
                            textColor: pt.accent),
                      if (person.isInvite)
                        _Badge(label: 'INVITE', color: pt.surfaceAlt,
                            textColor: pt.ink2),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${person.handle} · ${person.sub}',
                      style: PayPactTypography.bodySm
                          .copyWith(color: pt.ink3)),
                ],
              ),
            ),
            // Trust rating
            Row(
              children: [
                Icon(Icons.star_rounded, color: pt.accent, size: 13),
                const SizedBox(width: 3),
                Text(person.trust.toStringAsFixed(1),
                    style: PayPactTypography.bodyMd.copyWith(
                        color: pt.ink2, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(width: 12),
            // Add/check button
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: selected ? pt.accent : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? pt.accent : pt.border,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  selected ? Icons.check_rounded : Icons.add_rounded,
                  color: selected ? Colors.white : pt.ink3,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(
      {required this.label,
      required this.color,
      required this.textColor});
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.8)),
    );
  }
}
