import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/design_system/components/paypact_card.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/spacing.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/widgets/pp_atoms.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    Text('Settings',
                      style: PayPactTypography.bodyMd.copyWith(
                          color: pt.ink, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Make it yours.',
                        style: PayPactTypography.displayLg.copyWith(color: pt.ink)),
                      const SizedBox(height: 6),
                      Text('Tune the calm — sounds, prompts, theme.',
                        style: PayPactTypography.bodyMd.copyWith(color: pt.ink2)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                        PayPactSpacing.s6, 0, PayPactSpacing.s6, 32),
                    children: [
                      // Appearance
                      PpSectionLabel(label: 'APPEARANCE', padding: EdgeInsets.zero),
                      const SizedBox(height: 10),
                      PayPactCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Theme',
                              style: PayPactTypography.bodyMd.copyWith(
                                  color: pt.ink, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(child: _ThemeOption(
                                label: 'Bone', selected: !isDark,
                                bgGradient: null,
                                color: const Color(0xFFF5F2EC),
                                accent: const Color(0xFFB05A3C),
                              )),
                              const SizedBox(width: 10),
                              Expanded(child: _ThemeOption(
                                label: 'Charcoal', selected: isDark,
                                bgGradient: null,
                                color: const Color(0xFF100D09),
                                accent: const Color(0xFFC77556),
                              )),
                              const SizedBox(width: 10),
                              Expanded(child: _ThemeOption(
                                label: 'System', selected: false,
                                bgGradient: const LinearGradient(
                                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFF5F2EC), Color(0xFFF5F2EC),
                                    Color(0xFF100D09), Color(0xFF100D09),
                                  ],
                                  stops: [0, 0.5, 0.5, 1],
                                ),
                                color: const Color(0xFFF5F2EC),
                                accent: const Color(0xFFB05A3C),
                              )),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Notifications
                      PpSectionLabel(label: 'NOTIFICATIONS', padding: EdgeInsets.zero),
                      const SizedBox(height: 10),
                      PayPactCard(
                        padding: EdgeInsets.zero,
                        child: Column(children: [
                          _ToggleRow(label: 'Settlement requests',
                              sub: 'Someone settles up with you', on: true),
                          Divider(color: pt.border, height: 1),
                          _ToggleRow(label: 'Smart nudges',
                              sub: 'Gentle reminders about open balances', on: true),
                          Divider(color: pt.border, height: 1),
                          _ToggleRow(label: 'New expenses',
                              sub: 'When others add to your groups', on: true),
                          Divider(color: pt.border, height: 1),
                          _ToggleRow(label: 'Weekly digest',
                              sub: 'Sundays · 8 PM', on: false),
                        ]),
                      ),
                      const SizedBox(height: 18),
                      // Privacy
                      PpSectionLabel(label: 'PRIVACY & DATA', padding: EdgeInsets.zero),
                      const SizedBox(height: 10),
                      PayPactCard(
                        padding: EdgeInsets.zero,
                        child: Column(children: [
                          _RowControl(icon: Icons.lock_outline_rounded,
                              label: 'App lock', trailing: _ValueChevron('Face ID')),
                          Divider(color: pt.border, height: 1),
                          _RowControl(icon: Icons.donut_small_rounded,
                              label: 'Anonymous usage data',
                              trailing: const _Toggle(on: false)),
                          Divider(color: pt.border, height: 1),
                          _RowControl(icon: Icons.mail_outline_rounded,
                              label: 'Export all data',
                              trailing: Icon(Icons.chevron_right_rounded,
                                  color: pt.ink3)),
                          Divider(color: pt.border, height: 1),
                          _RowControl(icon: Icons.delete_outline_rounded,
                              label: 'Delete account', negative: true,
                              trailing: Icon(Icons.chevron_right_rounded,
                                  color: pt.ink3)),
                        ]),
                      ),
                      const SizedBox(height: 24),
                      Center(child: Text('PAYPACT · v2.0.1 (build 248)',
                        style: PayPactTypography.label.copyWith(
                            color: pt.ink3, letterSpacing: 1.5))),
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

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label, required this.selected,
    required this.color, required this.accent, this.bgGradient,
  });
  final String label; final bool selected;
  final Color color; final Color accent; final Gradient? bgGradient;
  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: pt.surface,
        border: Border.all(
          color: selected ? pt.accent : pt.border,
          width: selected ? 2 : 1,
        ),
        borderRadius: PayPactRadius.md,
        boxShadow: selected
          ? [BoxShadow(color: pt.accentSoft, spreadRadius: 3, blurRadius: 0)]
          : null,
      ),
      child: Column(children: [
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: bgGradient == null ? color : null,
            gradient: bgGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(children: [
            Positioned(left: 6, bottom: 6,
              child: Container(
                width: 18, height: 6,
                decoration: BoxDecoration(
                  color: accent, borderRadius: BorderRadius.circular(99)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Text(label, style: PayPactTypography.bodySm.copyWith(
            color: pt.ink, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.label, required this.sub, required this.on});
  final String label; final String sub; final bool on;
  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: PayPactTypography.bodyMd.copyWith(
                color: pt.ink, fontWeight: FontWeight.w600)),
            Text(sub, style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
          ],
        )),
        _Toggle(on: on),
      ]),
    );
  }
}

class _RowControl extends StatelessWidget {
  const _RowControl({required this.icon, required this.label,
    required this.trailing, this.negative = false});
  final IconData icon; final String label; final Widget trailing;
  final bool negative;
  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: negative ? pt.negativeSoft : pt.surfaceAlt,
            borderRadius: PayPactRadius.sm,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16,
              color: negative ? pt.negative : pt.ink2),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(label,
          style: PayPactTypography.bodyMd.copyWith(
            color: negative ? pt.negative : pt.ink,
            fontWeight: FontWeight.w600))),
        trailing,
      ]),
    );
  }
}

class _ValueChevron extends StatelessWidget {
  const _ValueChevron(this.value);
  final String value;
  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(value,
          style: PayPactTypography.bodyMd.copyWith(color: pt.ink3)),
      Icon(Icons.chevron_right_rounded, color: pt.ink3),
    ]);
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.on});
  final bool on;
  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Container(
      width: 42, height: 24,
      decoration: BoxDecoration(
        color: on ? pt.accent : pt.surfaceAlt,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: on ? pt.accent : pt.border),
      ),
      child: AnimatedAlign(
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        duration: const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.all(2),
          width: 18, height: 18,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              offset: const Offset(0, 2), blurRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}
