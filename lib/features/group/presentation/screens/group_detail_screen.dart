import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/core/utils/responsive.dart';
import 'package:paypact/design_system/components/adaptive_nav_scaffold.dart';
import 'package:paypact/design_system/components/paypact_button.dart';
import 'package:paypact/design_system/components/paypact_card.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/spacing.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/features/group/presentation/cubit/group_detail_cubit.dart';
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
          body: Stack(
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

class _SimplifiedDebt {
  final String fromId;
  final String fromName;
  final String toId;
  final String toName;
  final double amount;
  const _SimplifiedDebt({
    required this.fromId,
    required this.fromName,
    required this.toId,
    required this.toName,
    required this.amount,
  });
}

/// Greedy min-transaction algorithm (same as Splitwise).
/// Positive balance = creditor (owed money), negative = debtor (owes money).
List<_SimplifiedDebt> _simplifyDebts(
  Map<String, double> globalBal,
  Map<String, String> memberNames,
) {
  final bal = Map<String, double>.from(globalBal);
  final result = <_SimplifiedDebt>[];
  const threshold = 0.01;

  while (true) {
    String? creditorId;
    String? debtorId;
    double maxCredit = threshold;
    double maxDebt = threshold;

    for (final e in bal.entries) {
      if (e.value > maxCredit) {
        maxCredit = e.value;
        creditorId = e.key;
      }
      if (e.value < -maxDebt) {
        maxDebt = -e.value;
        debtorId = e.key;
      }
    }

    if (creditorId == null || debtorId == null) break;

    final amount = min(maxCredit, maxDebt);
    result.add(_SimplifiedDebt(
      fromId: debtorId,
      fromName: memberNames[debtorId] ?? 'Member',
      toId: creditorId,
      toName: memberNames[creditorId] ?? 'Member',
      amount: amount,
    ));
    bal[creditorId] = maxCredit - amount;
    bal[debtorId] = -maxDebt + amount;
  }

  return result;
}

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
    final debts = _simplifyDebts(
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

  final _SimplifiedDebt debt;
  final String currency;
  final String groupId;
  final String groupName;
  final String currentUserId;
  final String currentUserName;
  final String Function(double) fmt;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final isMyDebt = debt.fromId == currentUserId;
    final isMyCredit = debt.toId == currentUserId;
    final highlight = isMyDebt || isMyCredit;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        PpAvatar(name: debt.fromName, size: 36),
        const SizedBox(width: 8),
        Icon(Icons.arrow_forward_rounded, size: 14, color: pt.ink3),
        const SizedBox(width: 8),
        PpAvatar(name: debt.toName, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${debt.fromName.split(' ').first} → ${debt.toName.split(' ').first}',
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
                'toUserId': debt.toId,
                'toUserName': debt.toName,
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
