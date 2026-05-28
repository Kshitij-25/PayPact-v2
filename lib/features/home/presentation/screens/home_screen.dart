import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/core/utils/currency_utils.dart';
import 'package:paypact/core/utils/responsive.dart';
import 'package:paypact/design_system/components/adaptive_nav_scaffold.dart';
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

String _fmtAmt(double amount, String symbol) {
  final n = amount.round().abs();
  final s = n.toString();
  final String grouped;
  if (s.length <= 3) {
    grouped = s;
  } else {
    final last3 = s.substring(s.length - 3);
    final rest = s.substring(0, s.length - 3);
    final buf = StringBuffer();
    for (var i = 0; i < rest.length; i++) {
      buf.write(rest[i]);
      final remaining = rest.length - 1 - i;
      if (remaining > 0 && remaining % 2 == 0) buf.write(',');
    }
    grouped = '${buf.toString()},$last3';
  }
  return '$symbol$grouped';
}

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

// ── Body ──────────────────────────────────────────────────────────────────────

class _HomeBody extends StatefulWidget {
  const _HomeBody();
  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  bool _nudgeDismissed = false;

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final userName =
        authState is AuthAuthenticated ? authState.user.name : 'there';

    return BlocBuilder<GroupsCubit, GroupsState>(
      builder: (context, state) {
        final groups =
            state is GroupsLoaded ? state.groups : <GroupEntity>[];
        final totalBalance =
            state is GroupsLoaded ? state.totalNetBalance : 0.0;
        final weeklyDelta =
            state is GroupsLoaded ? state.weeklyDelta : 0.0;
        final nudge =
            state is GroupsLoaded ? state.smartNudge : null;
        final recentExpenses =
            state is GroupsLoaded ? state.recentExpenses : <RecentExpenseItem>[];
        final loading = state is GroupsLoading;

        final webTitle = loading
            ? null
            : totalBalance >= 0
                ? '${PpAmount.format(totalBalance.round(), signed: true)} in your favour.'
                : '${PpAmount.format(totalBalance.round(), signed: true)} to settle.';

        return AdaptiveNavScaffold(
          currentIndex: 0,
          onNavTap: (i) => [
            () => context.go(AppRoutes.home),
            () => context.go(AppRoutes.groups),
            () => context.go(AppRoutes.activity),
            () => context.go(AppRoutes.profile),
          ][i](),
          onFabTap: () => context.push('/group/create'),
          webEyebrow: 'DASHBOARD',
          webTitle: webTitle,
          webSubtitle: groups.isEmpty
              ? 'Create your first group to get started.'
              : 'Across ${groups.length} group${groups.length == 1 ? '' : 's'} · Stay on top of your splits.',
          webActionLabel: 'Add expense',
          webActionOnTap: () => context.push('/group/create'),
          webUserName: userName,
          webBalance: PpAmount.format(totalBalance.round(), signed: true),
          webBalancePositive: totalBalance >= 0,
          body: context.isDesktop
              ? _WebHomeBody(
                  groups: groups,
                  totalBalance: totalBalance,
                  weeklyDelta: weeklyDelta,
                  nudge: nudge,
                  recentExpenses: recentExpenses,
                  loading: loading,
                  nudgeDismissed: _nudgeDismissed,
                  onDismissNudge: () => setState(() => _nudgeDismissed = true),
                  relativeTime: _relativeTime,
                )
              : _MobileHomeBody(
                  userName: userName,
                  groups: groups,
                  totalBalance: totalBalance,
                  weeklyDelta: weeklyDelta,
                  nudge: nudge,
                  recentExpenses: recentExpenses,
                  loading: loading,
                  nudgeDismissed: _nudgeDismissed,
                  onDismissNudge: () => setState(() => _nudgeDismissed = true),
                  relativeTime: _relativeTime,
                ),
        );
      },
    );
  }
}

// ── Mobile body ───────────────────────────────────────────────────────────────

class _MobileHomeBody extends StatelessWidget {
  const _MobileHomeBody({
    required this.userName,
    required this.groups,
    required this.totalBalance,
    required this.weeklyDelta,
    required this.nudge,
    required this.recentExpenses,
    required this.loading,
    required this.nudgeDismissed,
    required this.onDismissNudge,
    required this.relativeTime,
  });

  final String userName;
  final List<GroupEntity> groups;
  final double totalBalance;
  final double weeklyDelta;
  final SmartNudgeData? nudge;
  final List<RecentExpenseItem> recentExpenses;
  final bool loading;
  final bool nudgeDismissed;
  final VoidCallback onDismissNudge;
  final String Function(DateTime) relativeTime;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final firstName = userName.split(' ').first;

    return Stack(
      children: [
        const PpBackdropGlow(intensity: 0.12),
        SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    PayPactSpacing.s6,
                    PayPactSpacing.s2,
                    PayPactSpacing.s6,
                    PayPactSpacing.s4),
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
                      icon: Icons.search_rounded,
                      onTap: () {},
                      badge: false,
                    ),
                    const SizedBox(width: 8),
                    PpGlassIconButton(
                      icon: Icons.notifications_none_rounded,
                      onTap: () => context.push(AppRoutes.notifications),
                      badge: false,
                    ),
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
                        style: PayPactTypography.label.copyWith(
                            color: pt.ink3, letterSpacing: 1.6)),
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
                                fontSize: context.sp(64),
                                letterSpacing:
                                    -0.045 * context.sp(64)),
                          ),
                    const SizedBox(height: 8),
                    loading
                        ? const SizedBox.shrink()
                        : groups.isEmpty
                            ? Text('No active groups yet',
                                style: PayPactTypography.bodyMd
                                    .copyWith(color: pt.ink2))
                            : _BalanceSubtitle(
                                groups: groups,
                                totalBalance: totalBalance,
                                weeklyDelta: weeklyDelta,
                              ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        PayPactButton(
                          onPressed: groups.isEmpty
                              ? null
                              : () {
                                  final owing = groups
                                      .where((g) => g.netBalance < 0)
                                      .toList()
                                    ..sort((a, b) => a.netBalance
                                        .compareTo(b.netBalance));
                                  final target = owing.isNotEmpty
                                      ? owing.first
                                      : groups.first;
                                  context.push('/group/${target.id}');
                                },
                          label: 'Settle up',
                          variant: PayPactButtonVariant.accent,
                          leftIcon: Icons.handshake_rounded,
                        ),
                        const SizedBox(width: 10),
                        PayPactButton(
                          onPressed: () => context.push('/insights'),
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
                height: context.sh(160),
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: PayPactSpacing.s6),
                        children: [
                          for (final g in groups.take(5)) ...[
                            GestureDetector(
                              onTap: () => context.push('/group/${g.id}'),
                              child: _GroupTile(group: g),
                            ),
                            const SizedBox(width: 12),
                          ],
                          GestureDetector(
                            onTap: () => context.push('/group/create'),
                            child: _AddGroupTile(),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),
              if (!nudgeDismissed && nudge != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      PayPactSpacing.s6, 0, PayPactSpacing.s6, 20),
                  child: _SmartNudgeCard(
                    nudge: nudge!,
                    onLater: onDismissNudge,
                    onNudge: () {
                      onDismissNudge();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Nudge sent to ${nudge!.memberName}!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (recentExpenses.isNotEmpty) ...[
                PpSectionLabel(
                  label: 'RECENT',
                  action: 'Activity →',
                  onAction: () => context.go(AppRoutes.activity),
                ),
                const SizedBox(height: 8),
                for (final item in recentExpenses)
                  _RecentRow(
                    item: item,
                    relativeTime: relativeTime(item.createdAt),
                    onTap: () => context.push(
                      '/expense/${item.expenseId}',
                      extra: {'groupId': item.groupId},
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Web body ──────────────────────────────────────────────────────────────────

class _WebHomeBody extends StatelessWidget {
  const _WebHomeBody({
    required this.groups,
    required this.totalBalance,
    required this.weeklyDelta,
    required this.nudge,
    required this.recentExpenses,
    required this.loading,
    required this.nudgeDismissed,
    required this.onDismissNudge,
    required this.relativeTime,
  });

  final List<GroupEntity> groups;
  final double totalBalance;
  final double weeklyDelta;
  final SmartNudgeData? nudge;
  final List<RecentExpenseItem> recentExpenses;
  final bool loading;
  final bool nudgeDismissed;
  final VoidCallback onDismissNudge;
  final String Function(DateTime) relativeTime;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left column ──────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance hero card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: pt.ink,
                    borderRadius: PayPactRadius.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NET BALANCE',
                          style: PayPactTypography.label.copyWith(
                              color: Colors.white54, letterSpacing: 1.6)),
                      const SizedBox(height: 12),
                      loading
                          ? Container(
                              height: 56,
                              width: 200,
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: PayPactRadius.sm,
                              ),
                            )
                          : Text(
                              PpAmount.format(totalBalance.round(),
                                  signed: true),
                              style: PayPactTypography.amountHero.copyWith(
                                color: Colors.white,
                                fontSize: 56,
                                letterSpacing: -0.045 * 56,
                              ),
                            ),
                      const SizedBox(height: 8),
                      if (!loading && groups.isNotEmpty)
                        Text(
                          'Across ${groups.length} group${groups.length == 1 ? '' : 's'}',
                          style: PayPactTypography.bodyMd
                              .copyWith(color: Colors.white54),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Groups grid header
                Row(
                  children: [
                    Text('YOUR GROUPS',
                        style: PayPactTypography.label.copyWith(
                            color: pt.ink3, letterSpacing: 1.6)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.groups),
                      child: Text('See all →',
                          style: PayPactTypography.bodySm
                              .copyWith(color: pt.accent)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Groups grid — 4 columns
                loading
                    ? const SizedBox(
                        height: 120,
                        child: Center(child: CircularProgressIndicator()))
                    : groups.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: pt.surface,
                              borderRadius: PayPactRadius.lg,
                              border: Border.all(color: pt.border),
                            ),
                            child: Center(
                              child: Text('No groups yet — create one!',
                                  style: PayPactTypography.bodyMd
                                      .copyWith(color: pt.ink3)),
                            ),
                          )
                        : GridView.count(
                            crossAxisCount: 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              for (final g in groups.take(7))
                                GestureDetector(
                                  onTap: () =>
                                      context.push('/group/${g.id}'),
                                  child: _GroupTile(group: g),
                                ),
                              GestureDetector(
                                onTap: () =>
                                    context.push('/group/create'),
                                child: _AddGroupTile(),
                              ),
                            ],
                          ),
                const SizedBox(height: 32),

                // Recent activity
                if (recentExpenses.isNotEmpty) ...[
                  Row(
                    children: [
                      Text('RECENT ACTIVITY',
                          style: PayPactTypography.label.copyWith(
                              color: pt.ink3, letterSpacing: 1.6)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.activity),
                        child: Text('View all →',
                            style: PayPactTypography.bodySm
                                .copyWith(color: pt.accent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: pt.surface,
                      borderRadius: PayPactRadius.lg,
                      border: Border.all(color: pt.border),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0;
                            i < recentExpenses.length;
                            i++) ...[
                          if (i > 0)
                            Divider(color: pt.border, height: 1),
                          _WebRecentRow(
                            item: recentExpenses[i],
                            relativeTime:
                                relativeTime(recentExpenses[i].createdAt),
                            onTap: () => context.push(
                              '/expense/${recentExpenses[i].expenseId}',
                              extra: {
                                'groupId': recentExpenses[i].groupId
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Divider
        VerticalDivider(width: 1, color: pt.border),

        // ── Right column ─────────────────────────────────────────────────────
        SizedBox(
          width: 360,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Smart nudge
                if (!nudgeDismissed && nudge != null) ...[
                  _SmartNudgeCard(
                    nudge: nudge!,
                    onLater: onDismissNudge,
                    onNudge: () {
                      onDismissNudge();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Nudge sent to ${nudge!.memberName}!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Quick actions
                Text('QUICK ACTIONS',
                    style: PayPactTypography.label.copyWith(
                        color: pt.ink3, letterSpacing: 1.6)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _QuickAction(
                      icon: Icons.add_rounded,
                      label: 'Add expense',
                      onTap: () => context.push('/group/create'),
                      pt: pt,
                    ),
                    _QuickAction(
                      icon: Icons.handshake_rounded,
                      label: 'Settle up',
                      onTap: () {
                        if (groups.isNotEmpty) {
                          final owing = groups
                              .where((g) => g.netBalance < 0)
                              .toList()
                            ..sort((a, b) =>
                                a.netBalance.compareTo(b.netBalance));
                          final target = owing.isNotEmpty
                              ? owing.first
                              : groups.first;
                          context.push('/group/${target.id}');
                        }
                      },
                      pt: pt,
                    ),
                    _QuickAction(
                      icon: Icons.donut_small_rounded,
                      label: 'Insights',
                      onTap: () => context.push('/insights'),
                      pt: pt,
                    ),
                    _QuickAction(
                      icon: Icons.group_add_rounded,
                      label: 'New group',
                      onTap: () => context.push('/group/create'),
                      pt: pt,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Open balances
                if (groups.any((g) => g.netBalance != 0)) ...[
                  Text('OPEN BALANCES',
                      style: PayPactTypography.label.copyWith(
                          color: pt.ink3, letterSpacing: 1.6)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: pt.surface,
                      borderRadius: PayPactRadius.lg,
                      border: Border.all(color: pt.border),
                    ),
                    child: Column(
                      children: [
                        for (final g in groups
                            .where((g) => g.netBalance != 0)
                            .take(5)
                            .toList()
                          ..sort((a, b) => a.netBalance
                              .abs()
                              .compareTo(b.netBalance.abs()) * -1)) ...[
                          if (g !=
                              groups
                                  .where((g) => g.netBalance != 0)
                                  .first)
                            Divider(color: pt.border, height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Text(g.emoji,
                                    style:
                                        const TextStyle(fontSize: 20)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(g.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: PayPactTypography.bodyMd
                                          .copyWith(color: pt.ink)),
                                ),
                                Text(
                                  PpAmount.format(
                                      g.netBalance.round(),
                                      signed: true),
                                  style: PayPactTypography.amountMd
                                      .copyWith(
                                    color: g.netBalance >= 0
                                        ? pt.positive
                                        : pt.negative,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WebRecentRow extends StatelessWidget {
  const _WebRecentRow({
    required this.item,
    required this.relativeTime,
    required this.onTap,
  });

  final RecentExpenseItem item;
  final String relativeTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final sym = currencySymbol(item.currency);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Text(item.groupEmoji,
                style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PayPactTypography.bodyMd.copyWith(
                          color: pt.ink, fontWeight: FontWeight.w500)),
                  Text('${item.groupName} · $relativeTime',
                      style: PayPactTypography.bodySm
                          .copyWith(color: pt.ink3)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(
              _fmtAmt(item.amount, sym),
              style:
                  PayPactTypography.amountMd.copyWith(color: pt.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.pt,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final PayPactThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: pt.surface,
          borderRadius: PayPactRadius.lg,
          border: Border.all(color: pt.border),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: pt.accent, size: 20),
            Text(label,
                style: PayPactTypography.bodyMd.copyWith(
                    color: pt.ink, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Balance subtitle ──────────────────────────────────────────────────────────

class _BalanceSubtitle extends StatelessWidget {
  const _BalanceSubtitle({
    required this.groups,
    required this.totalBalance,
    required this.weeklyDelta,
  });

  final List<GroupEntity> groups;
  final double totalBalance;
  final double weeklyDelta;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final gLabel =
        '${groups.length} group${groups.length == 1 ? '' : 's'}';
    final prefix = totalBalance >= 0
        ? "You'll get back across "
        : "You owe across ";

    final showTrend = weeklyDelta.abs() >= 1;
    final trendColor =
        weeklyDelta > 0 ? pt.positive : pt.negative;
    final trendArrow = weeklyDelta > 0 ? '↑' : '↓';
    final trendAmt = PpAmount.format(weeklyDelta.abs().round());

    return RichText(
      text: TextSpan(
        style: PayPactTypography.bodyMd.copyWith(color: pt.ink2),
        children: [
          TextSpan(text: prefix),
          TextSpan(
            text: gLabel,
            style: PayPactTypography.bodyMd.copyWith(
                color: pt.ink, fontWeight: FontWeight.w600),
          ),
          if (showTrend) ...[
            const TextSpan(text: ' · '),
            TextSpan(
              text: '$trendArrow $trendAmt this week',
              style: PayPactTypography.bodyMd.copyWith(color: trendColor),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Smart Nudge card ──────────────────────────────────────────────────────────

class _SmartNudgeCard extends StatelessWidget {
  const _SmartNudgeCard({
    required this.nudge,
    required this.onNudge,
    required this.onLater,
  });

  final SmartNudgeData nudge;
  final VoidCallback onNudge;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const amber = Color(0xFFE8963A);
    final bgColor =
        isDark ? const Color(0xFF2A1F0E) : const Color(0xFFFFF5EA);
    final borderColor =
        isDark ? const Color(0xFF4A3010) : const Color(0xFFFFD9A0);

    final sym = currencySymbol(nudge.currency);
    final amtStr = _fmtAmt(nudge.amountOwed, sym);
    final message = nudge.daysSilent > 0
        ? '${nudge.memberName} still owes $amtStr from the ${nudge.groupName}. It\'s been quiet for ${nudge.daysSilent} days.'
        : '${nudge.memberName} still owes $amtStr from the ${nudge.groupName}. No settlements yet.';

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: PayPactRadius.lg,
      ),
      padding: const EdgeInsets.all(PayPactSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: amber.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child:
                    const Icon(Icons.bolt_rounded, size: 16, color: amber),
              ),
              const SizedBox(width: 8),
              Text(
                'SMART NUDGE',
                style: PayPactTypography.label
                    .copyWith(color: amber, letterSpacing: 1.6),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: PayPactTypography.bodyMd.copyWith(color: pt.ink),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              GestureDetector(
                onTap: onNudge,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: pt.ink),
                    borderRadius: PayPactRadius.md,
                  ),
                  child: Text(
                    'Send a soft nudge',
                    style: PayPactTypography.bodySm.copyWith(
                        color: pt.ink, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onLater,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                  child: Text(
                    'Later',
                    style: PayPactTypography.bodySm.copyWith(
                        color: pt.ink2, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Recent expense row ────────────────────────────────────────────────────────

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.item,
    required this.relativeTime,
    required this.onTap,
  });

  final RecentExpenseItem item;
  final String relativeTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final sym = currencySymbol(item.currency);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            PayPactSpacing.s6, 0, PayPactSpacing.s6, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: pt.border, width: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: pt.surface,
                  borderRadius: PayPactRadius.md,
                  border: Border.all(color: pt.border),
                ),
                alignment: Alignment.center,
                child:
                    Text(item.groupEmoji, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PayPactTypography.bodyMd
                          .copyWith(color: pt.ink, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.groupName} · $relativeTime',
                      style: PayPactTypography.bodySm
                          .copyWith(color: pt.ink3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _fmtAmt(item.amount, sym),
                    style: PayPactTypography.amountMd.copyWith(color: pt.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.isPaidByCurrentUser ? 'You paid' : '${item.paidByName} paid',
                    style: PayPactTypography.micro.copyWith(color: pt.ink3),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Group tile ────────────────────────────────────────────────────────────────

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
            decoration:
                BoxDecoration(color: tones[0], shape: BoxShape.circle),
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
              color: group.netBalance >= 0 ? pt.positive : pt.negative,
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
        border:
            Border.all(color: pt.borderStrong, style: BorderStyle.solid),
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
