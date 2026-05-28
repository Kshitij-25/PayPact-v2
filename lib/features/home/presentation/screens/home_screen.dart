import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/core/utils/currency_utils.dart';
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
    final pt = context.pt;
    final authState = context.watch<AuthCubit>().state;
    final userName =
        authState is AuthAuthenticated ? authState.user.name : 'there';
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

                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // ── Header ──────────────────────────────────────────────
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
                            onTap: () =>
                                context.push(AppRoutes.notifications),
                            badge: false,
                          ),
                        ],
                      ),
                    ),

                    // ── Balance ──────────────────────────────────────────────
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
                                  style: PayPactTypography.amountHero
                                      .copyWith(
                                          color: pt.ink,
                                          fontSize: 64,
                                          letterSpacing: -0.045 * 64),
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
                                onPressed: () =>
                                    context.push('/insights'),
                                label: 'Insights',
                                variant: PayPactButtonVariant.secondary,
                                leftIcon: Icons.donut_small_rounded,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Your Groups ──────────────────────────────────────────
                    PpSectionLabel(
                      label: 'YOUR GROUPS · ${groups.length}',
                      action: 'See all',
                      onAction: () => context.go(AppRoutes.groups),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 160,
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
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

                    // ── Smart Nudge ──────────────────────────────────────────
                    if (!_nudgeDismissed && nudge != null) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            PayPactSpacing.s6, 0, PayPactSpacing.s6, 20),
                        child: _SmartNudgeCard(
                          nudge: nudge,
                          onLater: () =>
                              setState(() => _nudgeDismissed = true),
                          onNudge: () {
                            setState(() => _nudgeDismissed = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Nudge sent to ${nudge.memberName}!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    // ── Recent ───────────────────────────────────────────────
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
                          relativeTime: _relativeTime(item.createdAt),
                          onTap: () => context.push(
                            '/expense/${item.expenseId}',
                            extra: {'groupId': item.groupId},
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
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
