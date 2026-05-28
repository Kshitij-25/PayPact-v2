import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/utils/responsive.dart';
import 'package:paypact/design_system/components/paypact_button.dart';
import 'package:paypact/design_system/components/paypact_card.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/spacing.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/expense/presentation/cubit/expense_detail_cubit.dart';
import 'package:paypact/widgets/pp_atoms.dart';

class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen(
      {super.key, required this.expenseId, required this.groupId});

  final String expenseId;
  final String groupId;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final userId =
        authState is AuthAuthenticated ? authState.user.id : '';

    return BlocProvider(
      create: (_) => ExpenseDetailCubit(
        locator<ExpenseRepository>(),
        groupId,
        expenseId,
        userId,
      )..load(),
      child: _ExpenseDetailBody(groupId: groupId, expenseId: expenseId),
    );
  }
}

class _ExpenseDetailBody extends StatelessWidget {
  const _ExpenseDetailBody(
      {required this.groupId, required this.expenseId});

  final String groupId;
  final String expenseId;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;

    return BlocBuilder<ExpenseDetailCubit, ExpenseDetailState>(
      builder: (context, state) {
        if (state is ExpenseDetailLoading || state is ExpenseDetailInitial) {
          return Scaffold(
            backgroundColor: pt.bg,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (state is ExpenseDetailError) {
          return Scaffold(
            backgroundColor: pt.bg,
            body: Center(child: Text(state.message)),
          );
        }

        final loaded = state as ExpenseDetailLoaded;
        final expense = loaded.expense;
        final currentUserId = loaded.currentUserId;
        final cat = _catFromString(expense.category);
        final catTone = PpCategoryDisc.tone(context, cat);
        final iPaid = expense.paidById == currentUserId;
        final myShare = expense.splitAmountFor(currentUserId);
        final myNet = iPaid ? expense.amount - myShare : -myShare;

        return Scaffold(
          backgroundColor: pt.bg,
          body: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: context.sh(280),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [catTone[0], pt.bg],
                      stops: const [0, 0.95],
                    ),
                  ),
                  child: Stack(clipBehavior: Clip.none, children: [
                    Positioned(
                      top: 30,
                      right: -30,
                      child: Opacity(
                        opacity: 0.18,
                        child: Text(
                          _emojiForCategory(cat),
                          style: TextStyle(fontSize: context.sp(200)),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Row(children: [
                          PpGlassIconButton(
                              icon: Icons.arrow_back_rounded,
                              onTap: () => context.pop()),
                          const Spacer(),
                          PpGlassIconButton(
                            icon: Icons.edit_outlined,
                            onTap: () => context.push(
                                '/group/$groupId/expense/$expenseId/edit'),
                          ),
                          const SizedBox(width: 10),
                          PpGlassIconButton(
                              icon: Icons.more_horiz_rounded, onTap: () {}),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 26, 28, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PpChip(
                              label:
                                  '${_emojiForCategory(cat)}  ${_capitalize(expense.category)} · ${expense.splits.length} people',
                              tone: PpChipTone.neutral,
                            ),
                            const SizedBox(height: 14),
                            Text(expense.title,
                                style: PayPactTypography.headingXl
                                    .copyWith(color: pt.ink)),
                            const SizedBox(height: 8),
                            Text(
                              '₹${expense.amount.toStringAsFixed(expense.amount.truncateToDouble() == expense.amount ? 0 : 2)}',
                              style: PayPactTypography.amountHero
                                  .copyWith(color: pt.ink, fontSize: context.sp(56)),
                            ),
                            const SizedBox(height: 8),
                            Text.rich(
                              TextSpan(
                                style: PayPactTypography.bodyMd
                                    .copyWith(color: pt.ink2),
                                children: [
                                  TextSpan(
                                    text: iPaid
                                        ? 'You paid · split equally · '
                                        : '${expense.paidByName} paid · your share · ',
                                  ),
                                  TextSpan(
                                    text: myNet >= 0
                                        ? '+₹${myNet.abs().toStringAsFixed(0)} to you'
                                        : '−₹${myNet.abs().toStringAsFixed(0)} you owe',
                                    style: TextStyle(
                                      color: myNet >= 0
                                          ? pt.positive
                                          : pt.negative,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: PayPactSpacing.s6),
                        child: PpSectionLabel(
                          label:
                              'SPLIT · ${expense.splits.length} PEOPLE',
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: PayPactSpacing.s6),
                        child: PayPactCard(
                          padding: EdgeInsets.zero,
                          child: Column(children: [
                            for (var i = 0;
                                i < expense.splits.length;
                                i++) ...[
                              if (i > 0) Divider(color: pt.border, height: 1),
                              _SplitTile(
                                split: expense.splits[i],
                                paidById: expense.paidById,
                                currentUserId: currentUserId,
                              ),
                            ],
                          ]),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: PayPactSpacing.s6),
                        child: PayPactCard(
                          padding: EdgeInsets.zero,
                          child: Column(children: [
                            _MetaRow(
                              icon: Icons.calendar_today_outlined,
                              label: 'Date',
                              value: DateFormat('MMM d, yyyy · h:mm a')
                                  .format(expense.createdAt),
                            ),
                          ]),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            PayPactSpacing.s6, 12, PayPactSpacing.s6, 0),
                        child: Row(children: [
                          Expanded(
                            child: PayPactButton(
                              onPressed: () {},
                              label:
                                  'Remind ${expense.splits.where((s) => s.userId != expense.paidById).length} people',
                              variant: PayPactButtonVariant.secondary,
                              isFullWidth: true,
                              leftIcon: Icons.notifications_none_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          PayPactButton(
                            onPressed: () =>
                                _confirmDelete(context, expense.id),
                            label: '',
                            variant: PayPactButtonVariant.danger,
                            leftIcon: Icons.delete_outline_rounded,
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String expenseId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete expense?'),
        content: const Text(
            'This will remove the expense and update all balances.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<ExpenseDetailCubit>().delete();
              if (context.mounted) context.pop();
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SplitTile extends StatelessWidget {
  const _SplitTile({
    required this.split,
    required this.paidById,
    required this.currentUserId,
  });

  final ExpenseSplitEntity split;
  final String paidById;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final isPayer = split.userId == paidById;
    final isCurrentUser = split.userId == currentUserId;
    final displayName = isCurrentUser ? 'You' : split.userName;
    final subLabel = isPayer
        ? 'paid · ₹${split.amount.toStringAsFixed(0)}'
        : 'owes · ₹${split.amount.toStringAsFixed(0)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        PpAvatar(name: split.userName, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName,
                  style: PayPactTypography.bodyMd.copyWith(
                      color: pt.ink, fontWeight: FontWeight.w600)),
              Text(subLabel,
                  style:
                      PayPactTypography.bodySm.copyWith(color: pt.ink3)),
            ],
          ),
        ),
        if (isPayer) ...[
          PpChip(label: 'PAID', tone: PpChipTone.positive),
          const SizedBox(width: 8),
        ],
        Text(
          '₹${split.amount.toStringAsFixed(0)}',
          style: PayPactTypography.amountLg.copyWith(
              color: pt.ink, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ]),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: pt.surfaceAlt, borderRadius: PayPactRadius.sm),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: pt.ink2),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      PayPactTypography.bodySm.copyWith(color: pt.ink3)),
              Text(value,
                  style: PayPactTypography.bodyMd.copyWith(color: pt.ink)),
            ],
          ),
        ),
      ]),
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

String _emojiForCategory(PpCategory cat) {
  switch (cat) {
    case PpCategory.food:
      return '🍔';
    case PpCategory.stay:
      return '🏨';
    case PpCategory.transport:
      return '🚗';
    case PpCategory.shopping:
      return '🛍️';
    case PpCategory.trip:
      return '✈️';
    case PpCategory.home:
      return '🏠';
    case PpCategory.friends:
      return '👥';
    case PpCategory.couple:
      return '💑';
    default:
      return '🧾';
  }
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
