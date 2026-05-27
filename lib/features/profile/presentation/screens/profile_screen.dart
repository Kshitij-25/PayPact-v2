import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/design_system/components/paypact_bottom_nav.dart';
import 'package:paypact/design_system/components/paypact_card.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/spacing.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:paypact/features/profile/cubit/profile_cubit.dart';
import 'package:paypact/widgets/pp_atoms.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final userId =
        authState is AuthAuthenticated ? authState.user.id : null;

    return BlocProvider(
      create: (_) {
        final cubit = locator<ProfileCubit>();
        if (userId != null) cubit.load(userId);
        return cubit;
      },
      child: const _ProfileBody(),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody();

  void _showEditName(BuildContext context, String currentName) {
    final ctrl = TextEditingController(text: currentName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final pt = sheetCtx.pt;
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: pt.surface,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit name',
                    style: PayPactTypography.headingMd
                        .copyWith(color: pt.ink)),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  style: PayPactTypography.bodyMd.copyWith(color: pt.ink),
                  decoration: InputDecoration(
                    hintText: 'Your name',
                    hintStyle: PayPactTypography.bodyMd.copyWith(color: pt.ink3),
                    filled: true,
                    fillColor: pt.bg,
                    border: OutlineInputBorder(
                      borderRadius: PayPactRadius.md,
                      borderSide: BorderSide(color: pt.borderStrong),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: PayPactRadius.md,
                      borderSide: BorderSide(color: pt.borderStrong),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: PayPactRadius.md,
                      borderSide: BorderSide(color: pt.accent, width: 1.4),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pt.accent,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: PayPactRadius.md),
                    ),
                    onPressed: () {
                      final name = ctrl.text.trim();
                      if (name.isEmpty) return;
                      Navigator.pop(sheetCtx);
                      context
                          .read<ProfileCubit>()
                          .updateName(name);
                    },
                    child: Text('Save',
                        style: PayPactTypography.bodyMd.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;

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
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final userName = switch (state) {
            ProfileLoaded s => s.user.name,
            ProfileSaving s => s.user.name,
            _ => (context.watch<AuthCubit>().state is AuthAuthenticated
                ? (context.watch<AuthCubit>().state as AuthAuthenticated)
                    .user
                    .name
                : 'User'),
          };
          final userEmail = switch (state) {
            ProfileLoaded s => s.user.email,
            _ => (context.watch<AuthCubit>().state is AuthAuthenticated
                ? (context.watch<AuthCubit>().state as AuthAuthenticated)
                    .user
                    .email
                : ''),
          };
          final groupCount =
              state is ProfileLoaded ? state.groupCount : null;
          final saving = state is ProfileSaving;

          return Stack(
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
                              onTap: () =>
                                  context.push(AppRoutes.profileSettings)),
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
                        child: GestureDetector(
                          onTap: saving
                              ? null
                              : () => _showEditName(context, userName),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: pt.surface, width: 3),
                                  boxShadow: pt.shadowMd,
                                ),
                                child: PpAvatar(name: userName, size: 92),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: pt.accent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: pt.surface, width: 2),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.edit_rounded,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: saving
                            ? const SizedBox(
                                height: 28,
                                width: 28,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2))
                            : GestureDetector(
                                onTap: () =>
                                    _showEditName(context, userName),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(userName,
                                        style: PayPactTypography.headingXl
                                            .copyWith(color: pt.ink)),
                                    const SizedBox(width: 6),
                                    Icon(Icons.edit_outlined,
                                        size: 16, color: pt.ink3),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(userEmail,
                            style: PayPactTypography.amountMd
                                .copyWith(color: pt.ink3)),
                      ),
                      if (groupCount != null) ...[
                        const SizedBox(height: 20),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: pt.surface,
                              borderRadius: PayPactRadius.full,
                              border: Border.all(color: pt.border),
                            ),
                            child: Text(
                              '$groupCount group${groupCount == 1 ? '' : 's'}',
                              style: PayPactTypography.bodySm.copyWith(
                                  color: pt.ink2,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
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
                                  label: 'Edit name',
                                  sub: userName,
                                  onTap: () =>
                                      _showEditName(context, userName),
                                ),
                                Divider(color: pt.border, height: 1),
                                _Row(
                                    icon: Icons.payments_outlined,
                                    label: 'Payment methods',
                                    sub: 'UPI · Wallet'),
                              ]),
                            ),
                            const SizedBox(height: 18),
                            PpSectionLabel(
                                label: 'MORE',
                                padding: EdgeInsets.zero),
                            const SizedBox(height: 10),
                            PayPactCard(
                              padding: EdgeInsets.zero,
                              child: Column(children: [
                                _Row(
                                  icon: Icons.tune_rounded,
                                  label: 'Settings',
                                  onTap: () =>
                                      context.push(AppRoutes.profileSettings),
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
          );
        },
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
    final iconBg = negative ? pt.negativeSoft : pt.surfaceAlt;
    final iconFg = negative ? pt.negative : pt.ink2;
    final labelColor = negative ? pt.negative : pt.ink;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: sub == null ? 32 : 36,
            height: sub == null ? 32 : 36,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: PayPactRadius.sm),
            alignment: Alignment.center,
            child: Icon(icon, size: sub == null ? 16 : 18, color: iconFg),
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
