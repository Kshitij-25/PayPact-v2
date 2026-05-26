import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/design_system/components/paypact_bottom_nav.dart';
import 'package:paypact/design_system/components/paypact_card.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/spacing.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:paypact/widgets/pp_atoms.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final authState = context.watch<AuthCubit>().state;
    final user =
        authState is AuthAuthenticated ? authState.user : null;
    final userName = user?.name ?? 'User';
    final userEmail = user?.email ?? '';

    return Scaffold(
      backgroundColor: pt.bg,
      bottomNavigationBar: PayPactBottomNav(
        currentIndex: 3,
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
                  colors: [pt.accentSoft, pt.bg],
                  stops: const [0, 0.8],
                ),
              ),
            ),
          ),
          const PpBackdropGlow(intensity: 0.06),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Row(children: [
                      PpGlassIconButton(
                          icon: Icons.settings_outlined,
                          onTap: () => context
                              .push(AppRoutes.profileSettings)),
                      const Spacer(),
                      Text('You',
                          style: PayPactTypography.bodyMd.copyWith(
                              color: pt.ink2,
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      PpGlassIconButton(
                          icon: Icons.qr_code_2_rounded,
                          onTap: () {}),
                    ]),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: pt.surface, width: 3),
                        boxShadow: pt.shadowMd,
                      ),
                      child: PpAvatar(name: userName, size: 92),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(userName,
                        style: PayPactTypography.headingXl
                            .copyWith(color: pt.ink)),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(userEmail,
                        style: PayPactTypography.amountMd
                            .copyWith(color: pt.ink3)),
                  ),
                  const SizedBox(height: 26),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: PayPactSpacing.s6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PpSectionLabel(
                            label: 'ACCOUNT',
                            padding: EdgeInsets.zero),
                        const SizedBox(height: 10),
                        PayPactCard(
                          padding: EdgeInsets.zero,
                          child: Column(children: [
                            _Row(
                                icon: Icons.person_outline_rounded,
                                label: 'Personal info',
                                sub: 'Name, email, photo'),
                            Divider(color: pt.border, height: 1),
                            _Row(
                                icon: Icons.payments_outlined,
                                label: 'Payment methods',
                                sub: 'UPI · Wallet'),
                          ]),
                        ),
                        const SizedBox(height: 18),
                        PpSectionLabel(
                            label: 'MORE', padding: EdgeInsets.zero),
                        const SizedBox(height: 10),
                        PayPactCard(
                          padding: EdgeInsets.zero,
                          child: Column(children: [
                            _Row(
                              icon: Icons.tune_rounded,
                              label: 'Settings',
                              onTap: () => context
                                  .push(AppRoutes.profileSettings),
                            ),
                            Divider(color: pt.border, height: 1),
                            _Row(
                              icon: Icons.logout_rounded,
                              label: 'Sign out',
                              negative: true,
                              onTap: () async {
                                await context
                                    .read<AuthCubit>()
                                    .signOut();
                                if (context.mounted) {
                                  context.go(AppRoutes.signIn);
                                }
                              },
                            ),
                          ]),
                        ),
                      ],
                    ),
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

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    this.sub,
    this.negative = false,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String? sub;
  final bool negative;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final iconBg =
        negative ? pt.negativeSoft : pt.surfaceAlt;
    final iconFg = negative ? pt.negative : pt.ink2;
    final labelColor = negative ? pt.negative : pt.ink;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: sub == null ? 32 : 36,
            height: sub == null ? 32 : 36,
            decoration: BoxDecoration(
                color: iconBg,
                borderRadius: PayPactRadius.sm),
            alignment: Alignment.center,
            child: Icon(icon,
                size: sub == null ? 16 : 18,
                color: iconFg),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: PayPactTypography.bodyMd.copyWith(
                        color: labelColor,
                        fontWeight: FontWeight.w600)),
                if (sub != null)
                  Text(sub!,
                      style: PayPactTypography.bodySm
                          .copyWith(color: pt.ink3)),
              ],
            ),
          ),
          if (!negative)
            Icon(Icons.chevron_right_rounded, color: pt.ink3),
        ]),
      ),
    );
  }
}
