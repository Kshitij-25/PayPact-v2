import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/design_system/components/paypact_bottom_nav.dart';
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

        return Scaffold(
          backgroundColor: pt.bg,
          bottomNavigationBar: PayPactBottomNav(
            currentIndex: 1,
            onTap: (i) => [
              () => context.go(AppRoutes.home),
              () => context.go(AppRoutes.groups),
              () => context.go(AppRoutes.activity),
              () => context.go('/profile'),
            ][i](),
            onFabTap: () =>
                context.push('/group/$groupId/expense/add'),
          ),
          body: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 300,
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
                              style: const TextStyle(fontSize: 200)),
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
                                    onPressed: () {
                                      // Find the member with the most negative
                                      // balance (person you owe the most to)
                                      final balances = loaded.memberBalances;
                                      String? toUserId;
                                      String? toUserName;
                                      double worstBalance = 0;
                                      balances.forEach((uid, bal) {
                                        if (bal < worstBalance) {
                                          worstBalance = bal;
                                          toUserId = uid;
                                          toUserName =
                                              group.memberNames[uid] ??
                                                  'Member';
                                        }
                                      });
                                      // Fall back to member with largest
                                      // absolute balance if no negative found
                                      if (toUserId == null &&
                                          balances.isNotEmpty) {
                                        balances.forEach((uid, bal) {
                                          if (bal.abs() > worstBalance.abs()) {
                                            worstBalance = bal;
                                            toUserId = uid;
                                            toUserName =
                                                group.memberNames[uid] ??
                                                    'Member';
                                          }
                                        });
                                        toUserId ??= balances.keys.first;
                                        toUserName ??=
                                            group.memberNames[toUserId!] ??
                                                'Member';
                                      }
                                      context.push(
                                        '/group/$groupId/settle',
                                        extra: {
                                          'toUserId': toUserId ?? '',
                                          'toUserName': toUserName ?? '',
                                          'suggestedAmount':
                                              worstBalance.abs(),
                                          'currency': group.currency,
                                          'groupName': group.name,
                                        },
                                      );
                                    },
                                    label: 'Settle up',
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
