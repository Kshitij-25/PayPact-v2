import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/utils/responsive.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/design_system/components/adaptive_nav_scaffold.dart';
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

    return BlocBuilder<GroupsCubit, GroupsState>(
      builder: (context, state) {
        final groups =
            state is GroupsLoaded ? state.groups : <GroupEntity>[];
        final loading = state is GroupsLoading;

        return AdaptiveNavScaffold(
          currentIndex: 1,
          onNavTap: (i) => [
            () => context.go(AppRoutes.home),
            () => context.go(AppRoutes.groups),
            () => context.go(AppRoutes.activity),
            () => context.go(AppRoutes.profile),
          ][i](),
          onFabTap: () => context.push('/group/create'),
          webEyebrow: 'GROUPS',
          webTitle: 'Your groups.',
          webSubtitle: loading
              ? null
              : '${groups.length} group${groups.length == 1 ? '' : 's'} · Manage shared expenses.',
          webActionLabel: 'New group',
          webActionOnTap: () => context.push('/group/create'),
          body: context.isDesktop
              ? _WebGroupsBody(groups: groups, loading: loading)
              : Stack(
                  children: [
                    const PpBackdropGlow(intensity: 0.06),
                    SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                                PayPactSpacing.s6,
                                PayPactSpacing.s1,
                                PayPactSpacing.s6,
                                PayPactSpacing.s4),
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
                                    PpChip(
                                        label: 'All',
                                        tone: PpChipTone.accent),
                                    PpChip(
                                        label: 'Active',
                                        tone: PpChipTone.ghost),
                                    PpChip(
                                        label: 'You owe',
                                        tone: PpChipTone.ghost),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (loading)
                            const Expanded(
                                child:
                                    Center(child: CircularProgressIndicator()))
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
                                    PayPactSpacing.s6,
                                    0,
                                    PayPactSpacing.s6,
                                    120),
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
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

// ── Web groups body ───────────────────────────────────────────────────────────

class _WebGroupsBody extends StatelessWidget {
  const _WebGroupsBody({required this.groups, required this.loading});

  final List<GroupEntity> groups;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips + sort
          Row(
            children: [
              const Wrap(
                spacing: 8,
                children: [
                  PpChip(label: 'All', tone: PpChipTone.accent),
                  PpChip(label: 'Active', tone: PpChipTone.ghost),
                  PpChip(label: 'You owe', tone: PpChipTone.ghost),
                  PpChip(label: 'Settled', tone: PpChipTone.ghost),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.sort_rounded, size: 16, color: pt.ink3),
                  const SizedBox(width: 4),
                  Text('Sort',
                      style: PayPactTypography.bodySm
                          .copyWith(color: pt.ink3)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (groups.isEmpty)
            Container(
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: pt.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: pt.border),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.group_outlined, size: 48, color: pt.ink3),
                    const SizedBox(height: 12),
                    Text('No groups yet',
                        style: PayPactTypography.headingMd
                            .copyWith(color: pt.ink2)),
                  ],
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: pt.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: pt.border),
              ),
              child: Column(
                children: [
                  // Header row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text('GROUP',
                              style: PayPactTypography.label.copyWith(
                                  color: pt.ink3, letterSpacing: 1.4)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('MEMBERS',
                              style: PayPactTypography.label.copyWith(
                                  color: pt.ink3, letterSpacing: 1.4)),
                        ),
                        SizedBox(
                          width: 120,
                          child: Text('BALANCE',
                              textAlign: TextAlign.end,
                              style: PayPactTypography.label.copyWith(
                                  color: pt.ink3, letterSpacing: 1.4)),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: pt.border, height: 1),
                  for (int i = 0; i < groups.length; i++) ...[
                    if (i > 0) Divider(color: pt.border, height: 1),
                    _WebGroupRow(g: groups[i]),
                  ],
                ],
              ),
            ),

          // New group dashed card
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push('/group/create'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: pt.borderStrong, style: BorderStyle.solid),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 16, color: pt.ink3),
                  const SizedBox(width: 6),
                  Text('New group',
                      style: PayPactTypography.bodyMd
                          .copyWith(color: pt.ink3)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WebGroupRow extends StatelessWidget {
  const _WebGroupRow({required this.g});
  final GroupEntity g;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final cat = _catFromString(g.category);
    final tones = PpCategoryDisc.tone(context, cat);
    final settled = g.netBalance == 0;

    return GestureDetector(
      onTap: () => context.push('/group/${g.id}'),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: tones[0],
                        borderRadius: BorderRadius.circular(10)),
                    alignment: Alignment.center,
                    child: Text(g.emoji,
                        style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(g.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PayPactTypography.bodyMd
                            .copyWith(color: pt.ink, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  PpAvatarStack(
                      names: g.memberNames.values.toList(),
                      size: 22,
                      max: 4),
                  const SizedBox(width: 8),
                  Text('${g.memberIds.length}',
                      style: PayPactTypography.bodySm
                          .copyWith(color: pt.ink3)),
                ],
              ),
            ),
            SizedBox(
              width: 120,
              child: Text(
                settled
                    ? 'Settled'
                    : PpAmount.format(g.netBalance.round(), signed: true),
                textAlign: TextAlign.end,
                style: PayPactTypography.amountMd.copyWith(
                  color: settled
                      ? pt.ink3
                      : (g.netBalance >= 0 ? pt.positive : pt.negative),
                ),
              ),
            ),
          ],
        ),
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
