import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/core/utils/currency_utils.dart';
import 'package:paypact/core/utils/responsive.dart';
import 'package:paypact/design_system/components/adaptive_nav_scaffold.dart';
import 'package:paypact/design_system/components/paypact_button.dart';
import 'package:paypact/design_system/components/paypact_card.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/spacing.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/features/group/presentation/cubit/group_detail_cubit.dart';
import 'package:paypact/features/settle/domain/debt_simplifier.dart';
import 'package:paypact/widgets/pp_atoms.dart';

class GroupDetailScreen extends StatelessWidget {
  const GroupDetailScreen({super.key, required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final userId =
        authState is AuthAuthenticated ? authState.user.id : '';

    return BlocProvider(
      create: (_) => GroupDetailCubit(
        locator<GroupRepository>(),
        locator<ExpenseRepository>(),
        groupId,
        userId,
      )..load(),
      child: _GroupDetailBody(groupId: groupId),
    );
  }
}

class _GroupDetailBody extends StatelessWidget {
  const _GroupDetailBody({required this.groupId});
  final String groupId;

  void _showSettlePicker(
    BuildContext context,
    GroupDetailLoaded loaded,
    dynamic group,
    String gid,
  ) {
    final authState = context.read<AuthCubit>().state;
    final currentUserId =
        authState is AuthAuthenticated ? authState.user.id : '';
    final currentUserName =
        authState is AuthAuthenticated ? authState.user.name : 'You';
    final pt = context.pt;

    final nonZero = loaded.memberBalances.entries
        .where((e) => e.value.abs() > 0.01)
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    if (nonZero.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You're all settled up in this group.")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: pt.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: pt.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Who are you settling with?',
                  style: PayPactTypography.headingMd.copyWith(color: pt.ink)),
              const SizedBox(height: 6),
              Text('Select a member to settle your balance.',
                  style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
              const SizedBox(height: 20),
              ...nonZero.map((entry) {
                final memberId = entry.key;
                final balance = entry.value;
                final memberName =
                    group.memberNames[memberId] as String? ?? 'Member';
                // balance > 0 → they owe you; balance < 0 → you owe them
                final youOwe = balance < 0;
                final absAmount = balance.abs();
                final amtStr =
                    '${group.currency}${absAmount.toStringAsFixed(absAmount.truncateToDouble() == absAmount ? 0 : 2)}';

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.pop(context);
                    final fromId = youOwe ? currentUserId : memberId;
                    final fromName = youOwe ? currentUserName : memberName;
                    final toId = youOwe ? memberId : currentUserId;
                    final toName = youOwe ? memberName : currentUserName;
                    context.push(
                      '/group/$gid/settle',
                      extra: {
                        'fromUserId': fromId,
                        'fromUserName': fromName,
                        'toUserId': toId,
                        'toUserName': toName,
                        'suggestedAmount': absAmount,
                        'currency': group.currency as String? ?? '₹',
                        'groupName': group.name as String? ?? '',
                      },
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(children: [
                      PpAvatar(name: memberName, size: 44),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(memberName,
                                style: PayPactTypography.bodyMd.copyWith(
                                    color: pt.ink,
                                    fontWeight: FontWeight.w600)),
                            Text(
                              youOwe
                                  ? 'You owe $amtStr'
                                  : '$amtStr owed to you',
                              style: PayPactTypography.bodySm.copyWith(
                                  color: youOwe ? pt.negative : pt.positive),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: youOwe ? pt.negativeSoft : pt.positiveSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          youOwe ? 'Pay' : 'Received',
                          style: PayPactTypography.label.copyWith(
                              color: youOwe ? pt.negative : pt.positive,
                              letterSpacing: 0.8),
                        ),
                      ),
                    ]),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;

    return BlocBuilder<GroupDetailCubit, GroupDetailState>(
      builder: (context, state) {
        if (state is GroupDetailLoading || state is GroupDetailInitial) {
          return Scaffold(
            backgroundColor: pt.bg,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (state is GroupDetailError) {
          return Scaffold(
            backgroundColor: pt.bg,
            body: Center(child: Text(state.message)),
          );
        }

        final loaded = state as GroupDetailLoaded;
        final group = loaded.group;
        final expenses = loaded.expenses;
        final netBalance = loaded.netBalance;
        final cat = _catFromString(group.category);
        final tripTone = PpCategoryDisc.tone(context, cat);

        return AdaptiveNavScaffold(
          currentIndex: 1,
          onNavTap: (i) => [
            () => context.go(AppRoutes.home),
            () => context.go(AppRoutes.groups),
            () => context.go(AppRoutes.activity),
            () => context.go('/profile'),
          ][i](),
          onFabTap: () =>
              context.push('/group/$groupId/expense/add'),
          body: context.isDesktop
              ? _WebGroupDetailBody(loaded: loaded, groupId: groupId)
              : Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: context.sh(300),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [tripTone[0], pt.bg],
                      stops: const [0, 0.8],
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: -40,
                        right: -30,
                        child: Opacity(
                          opacity: 0.18,
                          child: Text(group.emoji,
                              style: TextStyle(fontSize: context.sp(200))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 10, 20, 0),
                        child: Row(children: [
                          PpGlassIconButton(
                              icon: Icons.arrow_back_rounded,
                              onTap: () => context.pop()),
                          const Spacer(),
                          PpGlassIconButton(
                              icon: Icons.more_horiz_rounded,
                              onTap: () => context
                                  .push('/group/$groupId/settings')),
                        ]),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(28, 24, 28, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PpChip(
                              label:
                                  '${group.emoji}  ${_capitalize(group.category)} · ${group.memberIds.length} members',
                              tone: PpChipTone.neutral,
                            ),
                            const SizedBox(height: 14),
                            Text(group.name,
                                style: PayPactTypography.displayLg
                                    .copyWith(color: pt.ink)),
                            const SizedBox(height: 6),
                            Text(
                              '${expenses.length} expenses · '
                              '₹${_totalAmount(expenses).toStringAsFixed(0)} tracked',
                              style: PayPactTypography.bodyLg
                                  .copyWith(color: pt.ink2),
                            ),
                            const SizedBox(height: 18),
                            PpAvatarStack(
                              names: group.memberNames.values.toList(),
                              size: 28,
                              max: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(24, 8, 24, 20),
                        child: PayPactCard(
                          raised: true,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('YOUR BALANCE',
                                            style: PayPactTypography
                                                .label
                                                .copyWith(
                                                    color: pt.ink3,
                                                    letterSpacing: 1.6)),
                                        const SizedBox(height: 6),
                                        Text(
                                          PpAmount.format(
                                              netBalance.round(),
                                              signed: true),
                                          style: PayPactTypography
                                              .amountXl
                                              .copyWith(
                                                  color: netBalance >= 0
                                                      ? pt.positive
                                                      : pt.negative),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          netBalance > 0
                                              ? 'People owe you'
                                              : netBalance < 0
                                                  ? 'You owe'
                                                  : 'All settled',
                                          style: PayPactTypography
                                              .bodySm
                                              .copyWith(color: pt.ink3),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: netBalance >= 0
                                          ? pt.positiveSoft
                                          : pt.negativeSoft,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      netBalance >= 0
                                          ? Icons.trending_up_rounded
                                          : Icons.trending_down_rounded,
                                      color: netBalance >= 0
                                          ? pt.positive
                                          : pt.negative,
                                      size: 22,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(children: [
                                Expanded(
                                  child: PayPactButton(
                                    onPressed: loaded.memberBalances.values.any((v) => v.abs() > 0.01)
                                        ? () => _showSettlePicker(
                                              context,
                                              loaded,
                                              group,
                                              groupId,
                                            )
                                        : null,
                                    label: loaded.memberBalances.values.any((v) => v.abs() > 0.01)
                                        ? 'Settle up'
                                        : "You're settled up",
                                    variant: PayPactButtonVariant.accent,
                                    isFullWidth: true,
                                    leftIcon: Icons.handshake_rounded,
                                  ),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _SimplifiedDebtsSection(
                        loaded: loaded,
                        groupId: groupId,
                        currency: group.currency,
                        groupName: group.name,
                        currentUserId: (context.read<AuthCubit>().state
                                is AuthAuthenticated)
                            ? (context.read<AuthCubit>().state
                                    as AuthAuthenticated)
                                .user
                                .id
                            : '',
                        currentUserName: (context.read<AuthCubit>().state
                                is AuthAuthenticated)
                            ? (context.read<AuthCubit>().state
                                    as AuthAuthenticated)
                                .user
                                .name
                            : 'You',
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: PayPactSpacing.s6),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                                bottom:
                                    BorderSide(color: pt.border)),
                          ),
                          child: Row(
                            children: [
                              _Tab(label: 'Expenses', active: true),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (expenses.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long_outlined,
                                    size: 40, color: pt.ink3),
                                const SizedBox(height: 10),
                                Text('No expenses yet',
                                    style: PayPactTypography.bodyMd
                                        .copyWith(color: pt.ink3)),
                                const SizedBox(height: 4),
                                Text('Tap + to add the first one',
                                    style: PayPactTypography.bodySm
                                        .copyWith(color: pt.ink3)),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final e = expenses[i];
                            final authState =
                                context.read<AuthCubit>().state;
                            final userId = authState
                                    is AuthAuthenticated
                                ? authState.user.id
                                : '';
                            final myShare =
                                e.splitAmountFor(userId);
                            final sharePos = e.paidById == userId;
                            final shareAmt = sharePos
                                ? e.amount - myShare
                                : -myShare;

                            return GestureDetector(
                              onTap: () => context.push(
                                '/expense/${e.id}',
                                extra: {'groupId': groupId},
                              ),
                              child: _ExpenseRow(
                                expense: e,
                                shareAmount: shareAmt,
                                sharePositive: sharePos,
                              ),
                            );
                          },
                          childCount: expenses.length,
                        ),
                      ),
                    const SliverToBoxAdapter(
                        child: SizedBox(height: 120)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _totalAmount(List<ExpenseEntity> expenses) =>
      expenses.fold(0, (sum, e) => sum + e.amount);
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.active});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: active
            ? Border(bottom: BorderSide(color: pt.accent, width: 2))
            : null,
      ),
      child: Text(label,
          style: PayPactTypography.bodyMd.copyWith(
            color: active ? pt.accent : pt.ink3,
            fontWeight: FontWeight.w600,
          )),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.expense,
    required this.shareAmount,
    required this.sharePositive,
  });
  final ExpenseEntity expense;
  final double shareAmount;
  final bool sharePositive;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final cat = _catFromString(expense.category);
    final dateStr = _formatDate(expense.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: PayPactSpacing.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 8),
            child: Text(dateStr,
                style: PayPactTypography.label
                    .copyWith(color: pt.ink3, letterSpacing: 1.5)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(children: [
              PpCategoryDisc(
                  category: cat,
                  icon: _iconForCategory(cat),
                  size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.title,
                        style: PayPactTypography.bodyMd.copyWith(
                            color: pt.ink,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      '${expense.paidByName} paid · split ${expense.splits.length} ways',
                      style: PayPactTypography.bodySm
                          .copyWith(color: pt.ink3),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${expense.amount.toStringAsFixed(0)}',
                    style: PayPactTypography.amountLg
                        .copyWith(color: pt.ink, fontSize: 17),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sharePositive
                        ? '+₹${shareAmount.abs().toStringAsFixed(0)}'
                        : '−₹${shareAmount.abs().toStringAsFixed(0)}',
                    style: PayPactTypography.bodySm.copyWith(
                      color:
                          sharePositive ? pt.positive : pt.negative,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ]),
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

IconData _iconForCategory(PpCategory cat) {
  switch (cat) {
    case PpCategory.food:
      return Icons.restaurant_outlined;
    case PpCategory.stay:
      return Icons.hotel_outlined;
    case PpCategory.transport:
      return Icons.directions_car_outlined;
    case PpCategory.shopping:
      return Icons.shopping_bag_outlined;
    case PpCategory.trip:
      return Icons.flight_outlined;
    case PpCategory.home:
      return Icons.home_outlined;
    default:
      return Icons.receipt_outlined;
  }
}

String _formatDate(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final d = DateTime(dt.year, dt.month, dt.day);
  if (d == today) return 'TODAY';
  if (d == yesterday) return 'YESTERDAY';
  return DateFormat('MMM d').format(dt).toUpperCase();
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

// ── Debt simplification ────────────────────────────────────────────────────────
// The minimization algorithm lives in the domain layer (decimal-safe, tested):
// lib/features/settle/domain/debt_simplifier.dart. Screens just render its output.

class _SimplifiedDebtsSection extends StatelessWidget {
  const _SimplifiedDebtsSection({
    required this.loaded,
    required this.groupId,
    required this.currency,
    required this.groupName,
    required this.currentUserId,
    required this.currentUserName,
  });

  final GroupDetailLoaded loaded;
  final String groupId;
  final String currency;
  final String groupName;
  final String currentUserId;
  final String currentUserName;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final debts = simplifyDebtsFromBalances(
      loaded.globalMemberBalances,
      Map<String, String>.from(loaded.group.memberNames),
    );

    if (debts.isEmpty) return const SizedBox.shrink();

    String fmtAmt(double v) =>
        '$currency${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: pt.accentSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.auto_awesome_rounded,
                  size: 15, color: pt.accentInk),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SUGGESTED REPAYMENTS',
                      style: PayPactTypography.label.copyWith(
                          color: pt.ink, letterSpacing: 1.4)),
                  Text(
                    'Simplified to ${debts.length} payment${debts.length == 1 ? '' : 's'}',
                    style: PayPactTypography.micro.copyWith(color: pt.ink3),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 12),
          PayPactCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < debts.length; i++) ...[
                  if (i > 0)
                    Divider(color: pt.border, height: 1, indent: 16, endIndent: 16),
                  _DebtRow(
                    debt: debts[i],
                    currency: currency,
                    groupId: groupId,
                    groupName: groupName,
                    currentUserId: currentUserId,
                    currentUserName: currentUserName,
                    fmt: fmtAmt,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtRow extends StatelessWidget {
  const _DebtRow({
    required this.debt,
    required this.currency,
    required this.groupId,
    required this.groupName,
    required this.currentUserId,
    required this.currentUserName,
    required this.fmt,
  });

  final SimplifiedDebt debt;
  final String currency;
  final String groupId;
  final String groupName;
  final String currentUserId;
  final String currentUserName;
  final String Function(double) fmt;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final isMyDebt = debt.fromUserId == currentUserId;
    final isMyCredit = debt.toUserId == currentUserId;
    final highlight = isMyDebt || isMyCredit;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        PpAvatar(name: debt.fromUserName, size: 36),
        const SizedBox(width: 8),
        Icon(Icons.arrow_forward_rounded, size: 14, color: pt.ink3),
        const SizedBox(width: 8),
        PpAvatar(name: debt.toUserName, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${debt.fromUserName.split(' ').first} → ${debt.toUserName.split(' ').first}',
                style: PayPactTypography.bodyMd.copyWith(
                  color: pt.ink,
                  fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              Text(
                isMyDebt
                    ? 'You owe this'
                    : isMyCredit
                        ? 'Owed to you'
                        : '',
                style: PayPactTypography.micro.copyWith(
                  color: isMyDebt ? pt.negative : pt.positive,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(fmt(debt.amount),
            style: PayPactTypography.amountMd.copyWith(
                color: isMyDebt
                    ? pt.negative
                    : isMyCredit
                        ? pt.positive
                        : pt.ink,
                fontWeight: FontWeight.w700,
                fontSize: 15)),
        if (isMyDebt) ...[
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => context.push(
              '/group/$groupId/settle',
              extra: {
                'fromUserId': currentUserId,
                'fromUserName': currentUserName,
                'toUserId': debt.toUserId,
                'toUserName': debt.toUserName,
                'suggestedAmount': debt.amount,
                'currency': currency,
                'groupName': groupName,
              },
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: pt.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Pay',
                  style: PayPactTypography.label.copyWith(
                      color: Colors.white, letterSpacing: 0.8)),
            ),
          ),
        ],
      ]),
    );
  }
}

/// Naive count of distinct (debtor → creditor) relationships before
/// simplification — derived from raw expense splits.
int _naivePairwiseCount(List<ExpenseEntity> expenses) {
  final Map<String, double> pair = {};
  for (final e in expenses) {
    for (final s in e.splits) {
      if (s.userId != e.paidById && s.amount > 0.01) {
        final key = '${s.userId}>${e.paidById}';
        pair[key] = (pair[key] ?? 0) + s.amount;
      }
    }
  }
  final seen = <String>{};
  var count = 0;
  for (final key in pair.keys) {
    if (seen.contains(key)) continue;
    final parts = key.split('>');
    final rev = '${parts[1]}>${parts[0]}';
    final net = ((pair[key] ?? 0) - (pair[rev] ?? 0)).abs();
    seen..add(key)..add(rev);
    if (net > 0.01) count++;
  }
  return count;
}

// ─────────────────────────────────────────────────────────────────────
// Web group detail (desktop only)
// ─────────────────────────────────────────────────────────────────────

class _WebGroupDetailBody extends StatefulWidget {
  const _WebGroupDetailBody({required this.loaded, required this.groupId});
  final GroupDetailLoaded loaded;
  final String groupId;

  @override
  State<_WebGroupDetailBody> createState() => _WebGroupDetailBodyState();
}

class _WebGroupDetailBodyState extends State<_WebGroupDetailBody> {
  String? _filterCategory; // null = all
  bool _sortDesc = true;
  String _activeTab = 'expenses';

  GroupDetailLoaded get loaded => widget.loaded;
  dynamic get group => widget.loaded.group;
  String get groupId => widget.groupId;

  String get _uid {
    final s = context.read<AuthCubit>().state;
    return s is AuthAuthenticated ? s.user.id : '';
  }

  String get _uname {
    final s = context.read<AuthCubit>().state;
    return s is AuthAuthenticated ? s.user.name : 'You';
  }

  String _dateRange(List<ExpenseEntity> ex) {
    if (ex.isEmpty) return '';
    var lo = ex.first.createdAt, hi = ex.first.createdAt;
    for (final e in ex) {
      if (e.createdAt.isBefore(lo)) lo = e.createdAt;
      if (e.createdAt.isAfter(hi)) hi = e.createdAt;
    }
    final f = DateFormat('MMM d');
    return lo == hi ? f.format(lo) : '${f.format(lo)} — ${f.format(hi)}';
  }

  Map<String, DateTime> _lastActivity() {
    final m = <String, DateTime>{};
    for (final e in loaded.expenses) {
      void touch(String id) {
        final p = m[id];
        if (p == null || e.createdAt.isAfter(p)) m[id] = e.createdAt;
      }

      touch(e.paidById);
      for (final s in e.splits) {
        touch(s.userId);
      }
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final tones = PpCategoryDisc.tone(context, _catFromString(group.category));
    final sym = currencyOf(group.currency).symbol;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _coverHeader(context, pt, tones, sym),
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 0, 40, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _tabBar(context, pt),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _leftColumn(context, pt, sym)),
                    const SizedBox(width: 28),
                    SizedBox(
                        width: 340,
                        child: _rightColumn(context, pt, sym)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverHeader(BuildContext context, PayPactThemeExtension pt,
      List<Color> tones, String sym) {
    final ex = loaded.expenses;
    final total = ex.fold<double>(0, (s, e) => s + e.amount);
    final range = _dateRange(ex);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tones[0], pt.bg],
        ),
      ),
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              top: -56,
              right: 24,
              child: Opacity(
                opacity: 0.45,
                child: Text(group.emoji,
                    style: const TextStyle(fontSize: 170)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 22, 40, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.groups),
                      child: Text('Groups',
                          style: PayPactTypography.bodySm
                              .copyWith(color: pt.ink3)),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7),
                      child: Icon(Icons.chevron_right_rounded,
                          size: 15, color: pt.ink3),
                    ),
                    Text(group.name,
                        style: PayPactTypography.bodySm.copyWith(
                            color: pt.ink2, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                PpChip(
                                    label:
                                        '${group.emoji} ${_capitalize(group.category)}',
                                    tone: PpChipTone.ghost),
                                if (range.isNotEmpty)
                                  PpChip(
                                      label: range,
                                      tone: PpChipTone.ghost),
                                PpChip(
                                    label: group.currency,
                                    tone: PpChipTone.ghost),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(group.name,
                                style: PayPactTypography.displayLg.copyWith(
                                    color: pt.ink,
                                    fontSize: 42,
                                    height: 1.05)),
                            const SizedBox(height: 8),
                            Text(
                              '${group.memberIds.length} members · ${ex.length} expenses · $sym${total.toStringAsFixed(0)} tracked',
                              style: PayPactTypography.bodyLg
                                  .copyWith(color: pt.ink2),
                            ),
                            const SizedBox(height: 16),
                            PpAvatarStack(
                              names: group.memberNames.values
                                  .toList()
                                  .cast<String>(),
                              size: 30,
                              max: 5,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Row(
                        children: [
                          PayPactButton(
                            onPressed: () =>
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Share — coming soon'))),
                            label: 'Share',
                            variant: PayPactButtonVariant.secondary,
                            leftIcon: Icons.ios_share_rounded,
                          ),
                          const SizedBox(width: 10),
                          PayPactButton(
                            onPressed: () => context
                                .push('/group/$groupId/settings'),
                            label: 'Settings',
                            variant: PayPactButtonVariant.secondary,
                            leftIcon: Icons.settings_outlined,
                          ),
                          const SizedBox(width: 10),
                          PayPactButton(
                            onPressed: () => context
                                .push('/group/$groupId/expense/add'),
                            label: 'Add expense',
                            variant: PayPactButtonVariant.accent,
                            leftIcon: Icons.add_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabBar(BuildContext context, PayPactThemeExtension pt) {
    final tabs = <List<String>>[
      ['expenses', 'Expenses · ${loaded.expenses.length}'],
      ['balances', 'Balances'],
      ['activity', 'Activity'],
      ['settle', 'Settle map'],
      ['members', 'Members'],
    ];
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: pt.border)),
      ),
      child: Row(
        children: [
          for (final t in tabs)
            Padding(
              padding: const EdgeInsets.only(right: 28),
              child: _WebTab(
                label: t[1],
                active: _activeTab == t[0],
                onTap: () => setState(() => _activeTab = t[0]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _leftColumn(
      BuildContext context, PayPactThemeExtension pt, String sym) {
    switch (_activeTab) {
      case 'expenses':
        return _expensesView(context, pt, sym);
      case 'settle':
        return _settlePlanView(context, pt, sym);
      default:
        return _placeholder(context, pt);
    }
  }

  Widget _expensesView(
      BuildContext context, PayPactThemeExtension pt, String sym) {
    final all = loaded.expenses;
    final cats = <String>[];
    for (final e in all) {
      if (!cats.contains(e.category)) cats.add(e.category);
    }
    var list = _filterCategory == null
        ? [...all]
        : all.where((e) => e.category == _filterCategory).toList();
    list.sort((a, b) => _sortDesc
        ? b.createdAt.compareTo(a.createdAt)
        : a.createdAt.compareTo(b.createdAt));

    final groups = <String, List<ExpenseEntity>>{};
    for (final e in list) {
      groups.putIfAbsent(_formatDate(e.createdAt), () => []).add(e);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _filterChip(pt, 'All categories', _filterCategory == null,
                      () => setState(() => _filterCategory = null)),
                  for (final c in cats)
                    _filterChip(pt, _capitalize(c), _filterCategory == c,
                        () => setState(() => _filterCategory = c)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => setState(() => _sortDesc = !_sortDesc),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Sort: Date',
                      style: PayPactTypography.bodySm
                          .copyWith(color: pt.ink3)),
                  const SizedBox(width: 3),
                  Icon(
                      _sortDesc
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      size: 14,
                      color: pt.ink3),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (list.isEmpty)
          _placeholderInline(pt, Icons.receipt_long_outlined,
              'No expenses in this filter')
        else
          for (final entry in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 2),
              child: Row(
                children: [
                  Text(entry.key,
                      style: PayPactTypography.label.copyWith(
                          color: pt.ink3, letterSpacing: 1.4, fontSize: 10)),
                  const Spacer(),
                  Text(
                      '${entry.value.length} EXPENSE${entry.value.length == 1 ? '' : 'S'}',
                      style: PayPactTypography.label.copyWith(
                          color: pt.ink3, letterSpacing: 1.4, fontSize: 10)),
                ],
              ),
            ),
            for (var i = 0; i < entry.value.length; i++) ...[
              if (i > 0) Divider(height: 1, color: pt.border),
              _WebExpenseRow(
                expense: entry.value[i],
                uid: _uid,
                sym: sym,
                onTap: () => context.push('/expense/${entry.value[i].id}',
                    extra: {'groupId': groupId}),
              ),
            ],
          ],
      ],
    );
  }

  Widget _settlePlanView(
      BuildContext context, PayPactThemeExtension pt, String sym) {
    final debts = simplifyDebtsFromBalances(
      loaded.globalMemberBalances,
      Map<String, String>.from(group.memberNames),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Settle map',
            style: PayPactTypography.headingLg.copyWith(color: pt.ink)),
        const SizedBox(height: 4),
        Text('The fewest payments to square everyone up.',
            style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
        const SizedBox(height: 16),
        if (debts.isEmpty)
          _placeholderInline(
              pt, Icons.check_circle_outline_rounded, 'Everyone is settled up')
        else
          PayPactCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < debts.length; i++) ...[
                  if (i > 0)
                    Divider(
                        color: pt.border,
                        height: 1,
                        indent: 16,
                        endIndent: 16),
                  _DebtRow(
                    debt: debts[i],
                    currency: group.currency,
                    groupId: groupId,
                    groupName: group.name,
                    currentUserId: _uid,
                    currentUserName: _uname,
                    fmt: (v) => '$sym${v.toStringAsFixed(
                        v.truncateToDouble() == v ? 0 : 2)}',
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _placeholder(BuildContext context, PayPactThemeExtension pt) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.construction_rounded, size: 36, color: pt.ink3),
          const SizedBox(height: 10),
          Text('This view is coming soon',
              style: PayPactTypography.bodyMd.copyWith(color: pt.ink3)),
        ],
      ),
    );
  }

  Widget _placeholderInline(
      PayPactThemeExtension pt, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(icon, size: 32, color: pt.ink3),
          const SizedBox(height: 8),
          Text(label,
              style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
        ],
      ),
    );
  }

  Widget _filterChip(PayPactThemeExtension pt, String label, bool active,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: active ? pt.accentSoft : pt.surface,
          borderRadius: PayPactRadius.full,
          border: Border.all(color: active ? pt.accent : pt.border),
        ),
        child: Text(label,
            style: PayPactTypography.bodySm.copyWith(
                color: active ? pt.accentInk : pt.ink2,
                fontWeight: FontWeight.w600,
                fontSize: 12)),
      ),
    );
  }

  Widget _rightColumn(
      BuildContext context, PayPactThemeExtension pt, String sym) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _balanceCard(context, pt, sym),
        const SizedBox(height: 16),
        _whoOwesCard(context, pt, sym),
        const SizedBox(height: 16),
        _autoSimplifiedCard(context, pt, sym),
      ],
    );
  }

  void _openSettleTopMember(BuildContext context) {
    final entries = loaded.memberBalances.entries
        .where((e) => e.value.abs() > 0.01)
        .toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("You're all settled up in this group.")));
      return;
    }
    final memberId = entries.first.key;
    final balance = entries.first.value;
    final memberName = (group.memberNames[memberId] as String?) ?? 'Member';
    final youOwe = balance < 0; // < 0 → I owe them
    context.push('/group/$groupId/settle', extra: {
      'fromUserId': youOwe ? _uid : memberId,
      'fromUserName': youOwe ? _uname : memberName,
      'toUserId': youOwe ? memberId : _uid,
      'toUserName': youOwe ? memberName : _uname,
      'suggestedAmount': balance.abs(),
      'currency': group.currency,
      'groupName': group.name,
    });
  }

  Widget _balanceCard(
      BuildContext context, PayPactThemeExtension pt, String sym) {
    final net = loaded.netBalance;
    final oweYou =
        loaded.memberBalances.values.where((v) => v > 0.01).length;
    final youOwe =
        loaded.memberBalances.values.where((v) => v < -0.01).length;
    final hasBalance =
        loaded.memberBalances.values.any((v) => v.abs() > 0.01);
    final settled = net.abs() <= 0.5;
    final owe = net < 0;
    final dirColor = settled ? pt.ink2 : (owe ? pt.negative : pt.positive);
    return PayPactCard(
      raised: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              settled
                  ? 'YOUR BALANCE HERE'
                  : (owe ? 'YOU OWE OVERALL' : "YOU'RE OWED OVERALL"),
              style: PayPactTypography.label.copyWith(
                  color: settled ? pt.ink3 : dirColor,
                  letterSpacing: 1.6,
                  fontSize: 10)),
          const SizedBox(height: 10),
          Text(
            settled ? 'Settled up' : '$sym${net.abs().toStringAsFixed(0)}',
            style: PayPactTypography.amountHero
                .copyWith(color: dirColor, fontSize: settled ? 30 : 38),
          ),
          const SizedBox(height: 4),
          Text(
            settled
                ? "Everyone's square in this group"
                : '$oweYou ${oweYou == 1 ? 'person owes' : 'people owe'} you · $youOwe you owe',
            style: PayPactTypography.bodySm.copyWith(color: pt.ink3),
          ),
          const SizedBox(height: 16),
          PayPactButton(
            onPressed: hasBalance ? () => _openSettleTopMember(context) : null,
            label: hasBalance ? 'Settle up' : "You're settled up",
            variant: PayPactButtonVariant.accent,
            isFullWidth: true,
            leftIcon: Icons.handshake_rounded,
          ),
        ],
      ),
    );
  }

  Widget _whoOwesCard(
      BuildContext context, PayPactThemeExtension pt, String sym) {
    final entries = loaded.memberBalances.entries
        .where((e) => e.value.abs() > 0.01)
        .toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    final last = _lastActivity();
    final now = DateTime.now();

    if (entries.isEmpty) return const SizedBox.shrink();

    return PayPactCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('WHO OWES WHO',
                style: PayPactTypography.label.copyWith(
                    color: pt.ink3, letterSpacing: 1.6, fontSize: 10)),
          ),
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0)
              Divider(
                  color: pt.border, height: 1, indent: 16, endIndent: 16),
            Builder(builder: (_) {
              final id = entries[i].key;
              final v = entries[i].value;
              final name =
                  (group.memberNames[id] as String?) ?? 'Member';
              final la = last[id];
              final quietDays =
                  la != null ? now.difference(la).inDays : 0;
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                child: Row(children: [
                  PpAvatar(name: name, size: 34),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: PayPactTypography.bodyMd.copyWith(
                                color: pt.ink,
                                fontWeight: FontWeight.w600)),
                        if (quietDays >= 7)
                          Text('quiet for $quietDays days',
                              style: PayPactTypography.micro
                                  .copyWith(color: pt.warn)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(v >= 0 ? 'OWES YOU' : 'YOU OWE',
                          style: PayPactTypography.label.copyWith(
                              color: pt.ink3,
                              fontSize: 8,
                              letterSpacing: 1.0)),
                      const SizedBox(height: 1),
                      Text(
                        '$sym${v.abs().toStringAsFixed(0)}',
                        style: PayPactTypography.amountMd.copyWith(
                            color: v >= 0 ? pt.positive : pt.negative,
                            fontWeight: FontWeight.w700,
                            fontSize: 14),
                      ),
                    ],
                  ),
                ]),
              );
            }),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _autoSimplifiedCard(
      BuildContext context, PayPactThemeExtension pt, String sym) {
    final debts = simplifyDebtsFromBalances(
      loaded.globalMemberBalances,
      Map<String, String>.from(group.memberNames),
    );
    if (debts.isEmpty) return const SizedBox.shrink();
    final naive = _naivePairwiseCount(loaded.expenses);
    final body = naive > debts.length
        ? '${debts.length} payment${debts.length == 1 ? '' : 's'} instead of $naive will square the group.'
        : 'Settle the group in ${debts.length} payment${debts.length == 1 ? '' : 's'}.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pt.accentSoft,
        borderRadius: PayPactRadius.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.bolt_rounded, size: 14, color: pt.accentInk),
            const SizedBox(width: 6),
            Text('AUTO-SIMPLIFIED',
                style: PayPactTypography.label.copyWith(
                    color: pt.accentInk,
                    letterSpacing: 1.4,
                    fontSize: 10)),
          ]),
          const SizedBox(height: 8),
          Text(body,
              style: PayPactTypography.bodySm
                  .copyWith(color: pt.ink2, height: 1.45)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _activeTab = 'settle'),
            child: Text('Show plan →',
                style: PayPactTypography.bodySm.copyWith(
                    color: pt.accentInk, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _WebTab extends StatelessWidget {
  const _WebTab(
      {required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.only(bottom: 12, top: 2),
        decoration: BoxDecoration(
          border: active
              ? Border(bottom: BorderSide(color: pt.accent, width: 2))
              : null,
        ),
        child: Text(label,
            style: PayPactTypography.bodyMd.copyWith(
              color: active ? pt.accent : pt.ink3,
              fontWeight: FontWeight.w600,
            )),
      ),
    );
  }
}

class _WebExpenseRow extends StatelessWidget {
  const _WebExpenseRow({
    required this.expense,
    required this.uid,
    required this.sym,
    required this.onTap,
  });
  final ExpenseEntity expense;
  final String uid;
  final String sym;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final cat = _catFromString(expense.category);
    final paidByMe = expense.paidById == uid;
    final myShare = expense.splitAmountFor(uid);
    final shareAmt = paidByMe ? expense.amount - myShare : -myShare;
    final payer = paidByMe ? 'You' : expense.paidByName.split(' ').first;
    final time = DateFormat('h:mm a').format(expense.createdAt);

    return InkWell(
      onTap: onTap,
      borderRadius: PayPactRadius.md,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            PpCategoryDisc(
                category: cat, icon: _iconForCategory(cat), size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.title,
                      style: PayPactTypography.bodyMd.copyWith(
                          color: pt.ink, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    '$payer paid · split ${expense.splits.length} ways',
                    style:
                        PayPactTypography.bodySm.copyWith(color: pt.ink3),
                  ),
                ],
              ),
            ),
            Text(time,
                style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$sym${expense.amount.toStringAsFixed(0)}',
                    style: PayPactTypography.amountLg
                        .copyWith(color: pt.ink, fontSize: 16)),
                const SizedBox(height: 2),
                Text(
                  shareAmt.abs() <= 0.5
                      ? 'settled'
                      : '${paidByMe ? 'you get' : 'you owe'} $sym${shareAmt.abs().toStringAsFixed(0)}',
                  style: PayPactTypography.bodySm.copyWith(
                    color: shareAmt.abs() <= 0.5
                        ? pt.ink3
                        : (paidByMe ? pt.positive : pt.negative),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
