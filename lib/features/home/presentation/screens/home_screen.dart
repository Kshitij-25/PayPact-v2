import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/design_system/components/paypact_bottom_nav.dart';
import 'package:paypact/design_system/components/paypact_button.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/spacing.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/features/group/presentation/cubit/groups_cubit.dart';
import 'package:paypact/widgets/pp_atoms.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final userId =
        authState is AuthAuthenticated ? authState.user.id : '';

    return BlocProvider(
      create: (_) => GroupsCubit(
        locator<GroupRepository>(),
        locator<ExpenseRepository>(),
        userId,
      )..loadGroups(),
      child: const _HomeBody(),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final authState = context.watch<AuthCubit>().state;
    final userName = authState is AuthAuthenticated
        ? authState.user.name
        : 'there';
    final firstName = userName.split(' ').first;

    return Scaffold(
      backgroundColor: pt.bg,
      bottomNavigationBar: PayPactBottomNav(
        currentIndex: 0,
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
          const PpBackdropGlow(intensity: 0.12),
          SafeArea(
            child: BlocBuilder<GroupsCubit, GroupsState>(
              builder: (context, state) {
                final groups = state is GroupsLoaded ? state.groups : <GroupEntity>[];
                final totalBalance =
                    state is GroupsLoaded ? state.totalNetBalance : 0.0;
                final loading = state is GroupsLoading;

                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(PayPactSpacing.s6,
                          PayPactSpacing.s2, PayPactSpacing.s6, PayPactSpacing.s4),
                      child: Row(
                        children: [
                          PpAvatar(name: userName, size: 42),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Good morning,',
                                  style: PayPactTypography.bodySm
                                      .copyWith(color: pt.ink3)),
                              Text(firstName,
                                  style: PayPactTypography.headingMd
                                      .copyWith(color: pt.ink)),
                            ],
                          ),
                          const Spacer(),
                          PpGlassIconButton(
                              icon: Icons.notifications_none_rounded,
                              onTap: () =>
                                  context.push(AppRoutes.notifications),
                              badge: false),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(PayPactSpacing.s7,
                          PayPactSpacing.s5, PayPactSpacing.s7, PayPactSpacing.s6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NET BALANCE',
                              style: PayPactTypography.label
                                  .copyWith(color: pt.ink3, letterSpacing: 1.6)),
                          const SizedBox(height: 10),
                          loading
                              ? Container(
                                  height: 64,
                                  width: 180,
                                  decoration: BoxDecoration(
                                    color: pt.surface,
                                    borderRadius: PayPactRadius.md,
                                  ),
                                )
                              : Text(
                                  PpAmount.format(totalBalance.round(),
                                      signed: true),
                                  style: PayPactTypography.amountHero.copyWith(
                                      color: pt.ink,
                                      fontSize: 64,
                                      letterSpacing: -0.045 * 64),
                                ),
                          const SizedBox(height: 8),
                          Text(
                            groups.isEmpty
                                ? 'No active groups yet'
                                : '${groups.length} group${groups.length == 1 ? '' : 's'} · '
                                    '${groups.where((g) => g.netBalance > 0).length} owing you',
                            style: PayPactTypography.bodyMd
                                .copyWith(color: pt.ink2),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              PayPactButton(
                                onPressed: groups.isEmpty
                                    ? null
                                    : () => context.push(
                                        '/group/${groups.first.id}/settle'),
                                label: 'Settle up',
                                variant: PayPactButtonVariant.accent,
                                leftIcon: Icons.handshake_rounded,
                              ),
                              const SizedBox(width: 10),
                              PayPactButton(
                                onPressed: () {},
                                label: 'Insights',
                                variant: PayPactButtonVariant.secondary,
                                leftIcon: Icons.donut_small_rounded,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PpSectionLabel(
                      label: 'YOUR GROUPS · ${groups.length}',
                      action: 'See all',
                      onAction: () => context.go(AppRoutes.groups),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 160,
                      child: loading
                          ? const Center(
                              child: CircularProgressIndicator())
                          : ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: PayPactSpacing.s6),
                              children: [
                                for (final g in groups.take(5)) ...[
                                  GestureDetector(
                                    onTap: () =>
                                        context.push('/group/${g.id}'),
                                    child: _GroupTile(group: g),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                GestureDetector(
                                  onTap: () =>
                                      context.push('/group/create'),
                                  child: _AddGroupTile(),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group});
  final GroupEntity group;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final cat = _categoryFromString(group.category);
    final tones = PpCategoryDisc.tone(context, cat);

    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pt.surface,
        border: Border.all(color: pt.border),
        borderRadius: PayPactRadius.lg,
        boxShadow: pt.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: tones[0], shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(group.emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 14),
          Text(group.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PayPactTypography.bodyMd
                  .copyWith(color: pt.ink, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('${group.memberIds.length} members',
              style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
          const SizedBox(height: 10),
          Text(
            PpAmount.format(group.netBalance.round(), signed: true),
            style: PayPactTypography.amountLg.copyWith(
              fontSize: 18,
              color:
                  group.netBalance >= 0 ? pt.positive : pt.negative,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddGroupTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: pt.surfaceAlt,
        borderRadius: PayPactRadius.lg,
        border: Border.all(
            color: pt.borderStrong, style: BorderStyle.solid),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_rounded, color: pt.ink2, size: 18),
          const SizedBox(height: 4),
          Text('New',
              style: PayPactTypography.bodySm
                  .copyWith(color: pt.ink2, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

PpCategory _categoryFromString(String cat) {
  switch (cat) {
    case 'trip':
      return PpCategory.trip;
    case 'home':
      return PpCategory.home;
    case 'food':
      return PpCategory.food;
    case 'friends':
      return PpCategory.friends;
    case 'stay':
      return PpCategory.stay;
    case 'couple':
      return PpCategory.couple;
    case 'transport':
      return PpCategory.transport;
    case 'shopping':
      return PpCategory.shopping;
    default:
      return PpCategory.other;
  }
}
