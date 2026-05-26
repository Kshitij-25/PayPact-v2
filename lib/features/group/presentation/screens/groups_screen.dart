import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/design_system/components/paypact_bottom_nav.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/spacing.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/features/group/presentation/cubit/groups_cubit.dart';
import 'package:paypact/widgets/pp_atoms.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

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
      child: const _GroupsBody(),
    );
  }
}

class _GroupsBody extends StatelessWidget {
  const _GroupsBody();

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;

    return Scaffold(
      backgroundColor: pt.bg,
      bottomNavigationBar: PayPactBottomNav(
        currentIndex: 1,
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
            child: BlocBuilder<GroupsCubit, GroupsState>(
              builder: (context, state) {
                final groups = state is GroupsLoaded
                    ? state.groups
                    : <GroupEntity>[];
                final loading = state is GroupsLoading;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(PayPactSpacing.s6,
                          PayPactSpacing.s1, PayPactSpacing.s6, PayPactSpacing.s4),
                      child: Row(children: [
                        Text('${groups.length} GROUPS',
                            style: PayPactTypography.label.copyWith(
                                color: pt.ink3, letterSpacing: 1.6)),
                        const Spacer(),
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
                          Text('Your groups.',
                              style: PayPactTypography.displayLg
                                  .copyWith(color: pt.ink)),
                          const SizedBox(height: 14),
                          const Wrap(
                            spacing: 8,
                            children: [
                              PpChip(label: 'All', tone: PpChipTone.accent),
                              PpChip(
                                  label: 'Active', tone: PpChipTone.ghost),
                              PpChip(
                                  label: 'You owe', tone: PpChipTone.ghost),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (loading)
                      const Expanded(
                          child: Center(child: CircularProgressIndicator()))
                    else if (groups.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.group_outlined,
                                  size: 48, color: pt.ink3),
                              const SizedBox(height: 12),
                              Text('No groups yet',
                                  style: PayPactTypography.headingMd
                                      .copyWith(color: pt.ink2)),
                              const SizedBox(height: 6),
                              Text('Tap + to create your first group',
                                  style: PayPactTypography.bodyMd
                                      .copyWith(color: pt.ink3)),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                              PayPactSpacing.s6, 0, PayPactSpacing.s6, 120),
                          itemCount: groups.length,
                          separatorBuilder: (_, __) =>
                              Divider(color: pt.border, height: 1),
                          itemBuilder: (context, i) => GestureDetector(
                            onTap: () =>
                                context.push('/group/${groups[i].id}'),
                            child: _GroupListItem(g: groups[i]),
                          ),
                        ),
                      ),
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

class _GroupListItem extends StatelessWidget {
  const _GroupListItem({required this.g});
  final GroupEntity g;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final cat = _catFromString(g.category);
    final tones = PpCategoryDisc.tone(context, cat);
    final settled = g.netBalance == 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                color: tones[0], borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: Text(g.emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(g.name,
                      style: PayPactTypography.headingMd
                          .copyWith(color: pt.ink)),
                  if (settled) ...[
                    const SizedBox(width: 8),
                    const PpChip(
                        label: 'SETTLED', tone: PpChipTone.ghost),
                  ],
                ]),
                const SizedBox(height: 3),
                Text('${g.memberIds.length} members',
                    style: PayPactTypography.bodySm
                        .copyWith(color: pt.ink3)),
                const SizedBox(height: 6),
                PpAvatarStack(
                  names: g.memberNames.values.toList(),
                  size: 20,
                  max: 4,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!settled)
                Text(g.netBalance > 0 ? 'YOU GET' : 'YOU OWE',
                    style: PayPactTypography.label.copyWith(
                        color: pt.ink3,
                        fontSize: 9,
                        letterSpacing: 1.2)),
              const SizedBox(height: 2),
              Text(
                settled
                    ? '—'
                    : PpAmount.format(g.netBalance.abs().round()),
                style: PayPactTypography.amountLg.copyWith(
                    fontSize: 20,
                    color: settled
                        ? pt.ink3
                        : (g.netBalance > 0
                            ? pt.positive
                            : pt.negative)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

PpCategory _catFromString(String cat) {
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
