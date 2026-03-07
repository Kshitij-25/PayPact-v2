import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paypact/core/theme/app_theme.dart';
import 'package:paypact/domain/entities/expense_entity.dart';
import 'package:paypact/domain/entities/settlement_entity.dart';
import 'package:paypact/domain/use_cases/record_settlement_use_case.dart';
import 'package:paypact/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:paypact/presentation/bloc/expense_bloc/expense_bloc.dart';
import 'package:paypact/presentation/bloc/group_bloc/group_bloc.dart';
import 'package:paypact/presentation/widgets/common/empty_states.dart';
import 'package:paypact/presentation/widgets/expense/expense_list_item.dart';
import 'package:paypact/presentation/widgets/group/balance_summary_card.dart';
import 'package:paypact/presentation/widgets/group/debt_card.dart';
import 'package:share_plus/share_plus.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key, required this.groupId});
  final String groupId;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<ExpenseBloc>().add(ExpenseLoadRequested(widget.groupId));
    context.read<ExpenseBloc>().add(ExpenseDebtsRequested(widget.groupId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = context
        .read<GroupBloc>()
        .state
        .groups
        .where((g) => g.id == widget.groupId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(group?.name ?? 'Group'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _shareInviteLink(context),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {},
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit Group')),
              const PopupMenuItem(value: 'settle', child: Text('Settle All')),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete Group',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: PaypactColors.textSecondary,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Balances'),
            Tab(text: 'Settle Up'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ExpensesTab(groupId: widget.groupId),
          _BalancesTab(groupId: widget.groupId),
          _SettleUpTab(groupId: widget.groupId),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/group/${widget.groupId}/expense/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _shareInviteLink(BuildContext context) {
    context.read<GroupBloc>().add(GroupInviteLinkRequested(widget.groupId));
    final link = context.read<GroupBloc>().state.inviteLink;
    if (link != null) {
      SharePlus.instance
          .share(ShareParams(text: 'Join my group on Paypact: $link'));
    }
  }
}

// ── Feed item union ────────────────────────────────────────────────────────
sealed class _FeedItem {
  DateTime get date;
}

class _ExpenseFeedItem extends _FeedItem {
  _ExpenseFeedItem(this.expense);
  final ExpenseEntity expense;
  @override
  DateTime get date => expense.createdAt;
}

class _SettlementFeedItem extends _FeedItem {
  _SettlementFeedItem(this.settlement);
  final SettlementEntity settlement;
  @override
  DateTime get date => settlement.createdAt;
}

// ── Expenses Tab ───────────────────────────────────────────────────────────
class _ExpensesTab extends StatelessWidget {
  const _ExpensesTab({required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (ctx, state) {
        // Build a merged, date-sorted feed
        final feed = <_FeedItem>[
          ...state.expenses.map(_ExpenseFeedItem.new),
          ...state.settlements.map(_SettlementFeedItem.new),
        ]..sort((a, b) => b.date.compareTo(a.date));

        if (feed.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_outlined,
            title: 'No expenses yet',
            subtitle: 'Add your first expense to start splitting',
          );
        }

        final group = ctx
            .read<GroupBloc>()
            .state
            .groups
            .where((g) => g.id == groupId)
            .firstOrNull;
        final members = group?.members ?? [];

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: feed.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final item = feed[i];
            if (item is _ExpenseFeedItem) {
              return ExpenseListItem(
                expense: item.expense,
                currentUserId: ctx.read<AuthBloc>().state.user?.id ?? '',
                onTap: () => context.push('/expense/${item.expense.id}'),
                onDelete: () => ctx
                    .read<ExpenseBloc>()
                    .add(ExpenseDeleteRequested(item.expense.id)),
              );
            } else {
              final s = (item as _SettlementFeedItem).settlement;
              final fromName = members
                      .where((m) => m.userId == s.fromUserId)
                      .firstOrNull
                      ?.displayName ??
                  'Someone';
              final toName = members
                      .where((m) => m.userId == s.toUserId)
                      .firstOrNull
                      ?.displayName ??
                  'Someone';
              return _SettlementListItem(
                settlement: s,
                fromName: fromName,
                toName: toName,
              );
            }
          },
        );
      },
    );
  }
}

// ── Settlement list item ───────────────────────────────────────────────────
class _SettlementListItem extends StatelessWidget {
  const _SettlementListItem({
    required this.settlement,
    required this.fromName,
    required this.toName,
  });

  final SettlementEntity settlement;
  final String fromName;
  final String toName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: PaypactColors.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('🤝', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$fromName paid $toName',
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 15),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        DateFormat('MMM d').format(settlement.createdAt),
                        style: const TextStyle(
                            fontSize: 12, color: PaypactColors.textSecondary),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color:
                              PaypactColors.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Settlement',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: PaypactColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '${settlement.currency} ${settlement.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: PaypactColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalancesTab extends StatelessWidget {
  const _BalancesTab({required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context) {
    final group = context
        .read<GroupBloc>()
        .state
        .groups
        .where((g) => g.id == groupId)
        .firstOrNull;

    if (group == null) return const SizedBox();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        BalanceSummaryCard(
          totalExpenses: group.totalExpenses,
          currency: group.currency,
        ),
        const SizedBox(height: 16),
        ...group.members.map((m) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: m.isInDebt
                      ? Theme.of(context)
                          .colorScheme
                          .error
                          .withValues(alpha: 0.1)
                      : PaypactColors.secondary.withValues(alpha: 0.1),
                  child: Text(
                    m.displayName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: m.isInDebt
                          ? Theme.of(context).colorScheme.error
                          : PaypactColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                title: Text(m.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(
                  m.isSettled
                      ? 'Settled up'
                      : m.isOwed
                          ? 'Gets back'
                          : 'Owes',
                  style: TextStyle(
                    color: m.isSettled
                        ? PaypactColors.textSecondary
                        : m.isOwed
                            ? PaypactColors.secondary
                            : Theme.of(context).colorScheme.error,
                  ),
                ),
                trailing: Text(
                  '${group.currency} ${m.balance.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: m.isSettled
                        ? PaypactColors.textSecondary
                        : m.isOwed
                            ? PaypactColors.secondary
                            : Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            )),
      ],
    );
  }
}

class _SettleUpTab extends StatelessWidget {
  const _SettleUpTab({required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (_, state) {
        if (state.simplifiedDebts.isEmpty) {
          return const EmptyState(
            icon: Icons.check_circle_outline,
            title: 'All settled!',
            subtitle: 'Everyone is even. No outstanding debts.',
          );
        }
        final group = context
            .read<GroupBloc>()
            .state
            .groups
            .where((g) => g.id == groupId)
            .firstOrNull;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Simplified debts',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ...state.simplifiedDebts.map(
              (debt) => DebtCard(
                debt: debt,
                members: group?.members ?? [],
                currentUserId: context.read<AuthBloc>().state.user?.id ?? '',
                onSettle: () => context.read<ExpenseBloc>().add(
                      ExpenseSettlementRequested(
                        RecordSettlementParams(
                          groupId: groupId,
                          fromUserId: debt.debtorId,
                          toUserId: debt.creditorId,
                          amount: debt.amount,
                          currency: debt.currency,
                        ),
                      ),
                    ),
              ),
            ),
          ],
        );
      },
    );
  }
}
