import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/utils/currency_utils.dart';
import 'package:paypact/core/utils/responsive.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/design_system/tokens/radius.dart';
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
        final metas =
            state is GroupsLoaded ? state.groupMetas : <String, GroupMeta>{};
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
          webTitle: 'Your groups.',
          webSubtitle: loading
              ? null
              : 'Active circles, side projects, and one-off pacts — sorted by last activity.',
          webActionLabel: 'Add expense',
          webActionOnTap: () => groups.isNotEmpty
              ? context.push('/group/${groups.first.id}/expense/add')
              : context.push('/group/create'),
          body: context.isDesktop
              ? _WebGroupsBody(groups: groups, metas: metas, loading: loading)
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

String _moneyWhole(double v, String currencyCode) {
  final sym = currencyOf(currencyCode).symbol;
  return '$sym${NumberFormat('#,##0').format(v.abs())}';
}

String _relativeDay(DateTime? dt) {
  if (dt == null) return '';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(dt.year, dt.month, dt.day);
  final diff = today.difference(d).inDays;
  if (diff <= 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return '${diff}d ago';
  if (diff < 14) return 'Last week';
  if (diff < 30) return '${(diff / 7).floor()} weeks ago';
  if (diff < 365) return '${(diff / 30).floor()}mo ago';
  return '${(diff / 365).floor()}y ago';
}

bool _isSettled(GroupEntity g) => g.netBalance.abs() <= 0.01;

class _WebGroupsBody extends StatefulWidget {
  const _WebGroupsBody({
    required this.groups,
    required this.metas,
    required this.loading,
  });

  final List<GroupEntity> groups;
  final Map<String, GroupMeta> metas;
  final bool loading;

  @override
  State<_WebGroupsBody> createState() => _WebGroupsBodyState();
}

class _WebGroupsBodyState extends State<_WebGroupsBody> {
  String _filter = 'all';

  List<GroupEntity> _apply(String f) {
    switch (f) {
      case 'active':
        return widget.groups.where((g) => !_isSettled(g)).toList();
      case 'owe':
        return widget.groups.where((g) => g.netBalance < -0.01).toList();
      case 'owed':
        return widget.groups.where((g) => g.netBalance > 0.01).toList();
      case 'settled':
        return widget.groups.where(_isSettled).toList();
      default:
        return widget.groups;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;

    if (widget.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _apply(_filter);

    final filters = <List<String>>[
      ['all', 'All', '${widget.groups.length}'],
      ['active', 'Active', '${_apply('active').length}'],
      ['owe', 'You owe', '${_apply('owe').length}'],
      ['owed', 'Owed to you', '${_apply('owed').length}'],
      ['settled', 'Settled', '${_apply('settled').length}'],
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 4, 40, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter pills + sort + new group
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final f in filters)
                      _FilterPill(
                        label: f[1],
                        count: f[2],
                        selected: _filter == f[0],
                        onTap: () => setState(() => _filter = f[0]),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_vert_rounded, size: 15, color: pt.ink3),
                  const SizedBox(width: 4),
                  Text('Sort: Last activity',
                      style:
                          PayPactTypography.bodySm.copyWith(color: pt.ink3)),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => context.push('/group/create'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: pt.accent,
                        borderRadius: PayPactRadius.full,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded,
                              size: 15, color: Colors.white),
                          const SizedBox(width: 5),
                          Text('New group',
                              style: PayPactTypography.bodySm.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (filtered.isEmpty)
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
                    Icon(Icons.group_outlined, size: 44, color: pt.ink3),
                    const SizedBox(height: 12),
                    Text(
                        widget.groups.isEmpty
                            ? 'No groups yet'
                            : 'Nothing in this filter',
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
                    padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text('GROUP',
                              style: PayPactTypography.label.copyWith(
                                  color: pt.ink3,
                                  letterSpacing: 1.4,
                                  fontSize: 10)),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text('MEMBERS',
                              style: PayPactTypography.label.copyWith(
                                  color: pt.ink3,
                                  letterSpacing: 1.4,
                                  fontSize: 10)),
                        ),
                        SizedBox(
                          width: 130,
                          child: Text('TOTAL SPENT',
                              textAlign: TextAlign.end,
                              style: PayPactTypography.label.copyWith(
                                  color: pt.ink3,
                                  letterSpacing: 1.4,
                                  fontSize: 10)),
                        ),
                        SizedBox(
                          width: 130,
                          child: Text('YOUR BALANCE',
                              textAlign: TextAlign.end,
                              style: PayPactTypography.label.copyWith(
                                  color: pt.ink3,
                                  letterSpacing: 1.4,
                                  fontSize: 10)),
                        ),
                        const SizedBox(width: 36),
                      ],
                    ),
                  ),
                  Divider(color: pt.border, height: 1),
                  for (int i = 0; i < filtered.length; i++) ...[
                    if (i > 0) Divider(color: pt.border, height: 1),
                    _WebGroupRow(
                        g: filtered[i], meta: widget.metas[filtered[i].id]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? pt.accentSoft : Colors.transparent,
          borderRadius: PayPactRadius.full,
          border:
              Border.all(color: selected ? pt.accent : pt.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: PayPactTypography.bodySm.copyWith(
                    color: selected ? pt.accentInk : pt.ink2,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5)),
            const SizedBox(width: 6),
            Text(count,
                style: PayPactTypography.bodySm.copyWith(
                    color: selected ? pt.accent : pt.ink3,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}

class _WebGroupRow extends StatelessWidget {
  const _WebGroupRow({required this.g, this.meta});
  final GroupEntity g;
  final GroupMeta? meta;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final cat = _catFromString(g.category);
    final tones = PpCategoryDisc.tone(context, cat);
    final settled = _isSettled(g);
    final when = _relativeDay(meta?.lastActivityAt);
    final subtitle = settled
        ? (when.isEmpty ? 'Settled' : 'Settled · $when')
        : [
            if (when.isNotEmpty) when,
            if ((meta?.lastExpenseTitle ?? '').isNotEmpty) meta!.lastExpenseTitle,
          ].join(' · ');

    return GestureDetector(
      onTap: () => context.push('/group/${g.id}'),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
        child: Row(
          children: [
            // GROUP
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: tones[0],
                        borderRadius: BorderRadius.circular(11)),
                    alignment: Alignment.center,
                    child:
                        Text(g.emoji, style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(g.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: PayPactTypography.bodyMd.copyWith(
                                      color: pt.ink,
                                      fontWeight: FontWeight.w600)),
                            ),
                            if (settled) ...[
                              const SizedBox(width: 8),
                              const PpChip(
                                  label: 'SETTLED', tone: PpChipTone.ghost),
                            ],
                          ],
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PayPactTypography.bodySm
                                  .copyWith(color: pt.ink3, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // MEMBERS
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  PpAvatarStack(
                      names: g.memberNames.values.toList(),
                      size: 24,
                      max: 4),
                  const SizedBox(width: 10),
                  Text('${g.memberIds.length} people',
                      style: PayPactTypography.bodySm
                          .copyWith(color: pt.ink3)),
                ],
              ),
            ),
            // TOTAL SPENT
            SizedBox(
              width: 130,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_moneyWhole(meta?.totalSpent ?? 0, g.currency),
                      style: PayPactTypography.amountMd.copyWith(
                          color: pt.ink, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${meta?.expenseCount ?? 0} expenses',
                      style: PayPactTypography.bodySm
                          .copyWith(color: pt.ink3, fontSize: 11)),
                ],
              ),
            ),
            // YOUR BALANCE
            SizedBox(
              width: 130,
              child: settled
                  ? Text('—',
                      textAlign: TextAlign.end,
                      style: PayPactTypography.amountLg
                          .copyWith(color: pt.ink3, fontSize: 18))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(g.netBalance > 0 ? 'YOU GET' : 'YOU OWE',
                            style: PayPactTypography.label.copyWith(
                                color: pt.ink3,
                                fontSize: 9,
                                letterSpacing: 1.2)),
                        const SizedBox(height: 2),
                        Text(_moneyWhole(g.netBalance, g.currency),
                            style: PayPactTypography.amountLg.copyWith(
                                fontSize: 19,
                                color: g.netBalance > 0
                                    ? pt.positive
                                    : pt.negative)),
                      ],
                    ),
            ),
            SizedBox(
              width: 36,
              child: Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.chevron_right_rounded,
                    size: 18, color: pt.ink3),
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
