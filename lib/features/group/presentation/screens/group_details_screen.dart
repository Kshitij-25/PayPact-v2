import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paypact/core/theme/app_theme.dart';
import 'package:paypact/core/utils/currency_formatter.dart';
import 'package:paypact/features/auth/domain/entities/user_entity.dart';
import 'package:paypact/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/entities/settlement_entity.dart';
import 'package:paypact/features/expense/domain/use_cases/record_settlement_use_case.dart';
import 'package:paypact/features/expense/presentation/bloc/expense_bloc.dart';
import 'package:paypact/features/expense/presentation/widgets/expense_list_item.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/group/presentation/bloc/group_bloc.dart';
import 'package:paypact/features/group/presentation/screens/qr_invite_sheet.dart';
import 'package:paypact/features/group/presentation/widgets/debt_card.dart';
import 'package:paypact/widgets/empty_states.dart';
import 'package:share_plus/share_plus.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

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
    _tabController = TabController(length: 4, vsync: this);
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
    return BlocListener<GroupBloc, GroupState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (ctx, state) {
        // If group was deleted it will no longer appear in the list
        if (state.status == GroupStatus.success &&
            state.groups.every((g) => g.id != widget.groupId)) {
          ctx.go('/');
        }
      },
      child: BlocBuilder<GroupBloc, GroupState>(
        buildWhen: (p, c) => p.groups != c.groups,
        builder: (ctx, groupState) {
          final group = groupState.groups
              .where((g) => g.id == widget.groupId)
              .firstOrNull;
          return Scaffold(
            appBar: AppBar(
              title: Text(group?.name ?? 'Group'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_add_outlined),
                  tooltip: 'Add member',
                  onPressed: () => _showAddMemberPicker(ctx),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Group settings',
                  onPressed: () =>
                      ctx.push('/group/${widget.groupId}/settings'),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'settle') _confirmSettleAll(ctx);
                    if (v == 'share') _shareInviteLink(ctx);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'settle', child: Text('Settle All')),
                    const PopupMenuItem(
                        value: 'share', child: Text('Share Invite Link')),
                  ],
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Expenses'),
                  Tab(text: 'Balances'),
                  Tab(text: 'Settle Up'),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(groupId: widget.groupId),
                _ExpensesTab(groupId: widget.groupId),
                _BalancesTab(groupId: widget.groupId),
                _SettleUpTab(groupId: widget.groupId),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () =>
                  context.push('/group/${widget.groupId}/expense/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          );
        },
      ),
    );
  }

  void _shareInviteLink(BuildContext ctx) {
    ctx.read<GroupBloc>().add(GroupInviteLinkRequested(widget.groupId));
    final link = ctx.read<GroupBloc>().state.inviteLink;
    if (link != null) {
      SharePlus.instance
          .share(ShareParams(title: 'Join my group on Paypact:', text: link));
    }
  }

  void _showAddMemberPicker(BuildContext ctx) {
    final group = ctx
        .read<GroupBloc>()
        .state
        .groups
        .where((g) => g.id == widget.groupId)
        .firstOrNull;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMemberPickerSheet(
        groupId: widget.groupId,
        groupName: group?.name ?? 'Group',
        groupBloc: ctx.read<GroupBloc>(),
      ),
    );
  }

  void _confirmSettleAll(BuildContext ctx) {
    final debts = ctx.read<ExpenseBloc>().state.simplifiedDebts;
    if (debts.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('No outstanding debts to settle')));
      return;
    }
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('Settle All Debts'),
        content: Text(
            'This will record ${debts.length} settlement${debts.length > 1 ? 's' : ''} and clear all outstanding balances. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: ctx.findAncestorStateOfType<State>() != null
                    ? Theme.of(ctx).colorScheme.secondary
                    : null),
            onPressed: () {
              Navigator.pop(dCtx);
              for (final debt in debts) {
                ctx.read<ExpenseBloc>().add(ExpenseSettlementRequested(
                      RecordSettlementParams(
                        groupId: widget.groupId,
                        fromUserId: debt.debtorId,
                        toUserId: debt.creditorId,
                        amount: debt.amount,
                        currency: debt.currency,
                      ),
                    ));
              }
              ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('All debts settled!')));
            },
            child:
                const Text('Settle All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overview Tab
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.groupId});
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

    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (ctx, expState) {
        final currentUserId = ctx.read<AuthBloc>().state.user?.id ?? '';
        final myMember = group.getMember(currentUserId);
        final myBalance = myMember?.balance ?? 0.0;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _StatsRow(group: group, myBalance: myBalance),
            const SizedBox(height: 24),
            if (expState.expenses.isNotEmpty) ...[
              _SectionLabel('Spending by Category'),
              const SizedBox(height: 10),
              _CategoryDonutChart(
                  expenses: expState.expenses, currency: group.currency),
              const SizedBox(height: 24),
            ],
            if (group.members.any((m) => m.balance != 0)) ...[
              _SectionLabel('Member Balances'),
              const SizedBox(height: 10),
              _MemberBalanceChart(
                  members: group.members, currency: group.currency),
              const SizedBox(height: 24),
            ],
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.8),
      );
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.group, required this.myBalance});
  final GroupEntity group;
  final double myBalance;

  @override
  Widget build(BuildContext context) {
    final c = group.currency;
    final cs = Theme.of(context).colorScheme;
    final Color balColor = myBalance > 0
        ? cs.secondary
        : myBalance < 0
            ? cs.error
            : cs.onSurfaceVariant;
    final String balLabel = myBalance > 0
        ? 'you get back'
        : myBalance < 0
            ? 'you owe'
            : 'all settled';

    return Row(children: [
      Expanded(
        child: _StatCard(
          icon: Icons.receipt_long_outlined,
          iconColor: cs.primary,
          label: 'Total Spent',
          value: CurrencyFormatter.format(group.totalExpenses, c),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _StatCard(
          icon: Icons.people_outline,
          iconColor: PaypactColors.warning,
          label: 'Members',
          value: '${group.memberCount}',
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _StatCard(
          icon: myBalance >= 0 ? Icons.arrow_downward : Icons.arrow_upward,
          iconColor: balColor,
          label: balLabel,
          value: CurrencyFormatter.format(myBalance.abs(), c),
          valueColor: balColor,
        ),
      ),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: valueColor ??
                          Theme.of(context).colorScheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      );
}

// ── Category donut chart ──────────────────────────────────────────────────────

class _CategoryDonutChart extends StatefulWidget {
  const _CategoryDonutChart({required this.expenses, required this.currency});
  final List<ExpenseEntity> expenses;
  final String currency;

  @override
  State<_CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<_CategoryDonutChart> {
  int _touchedIndex = -1;

  static const _catColors = [
    Color(0xFF4F46E5),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
    Color(0xFF84CC16),
    Color(0xFF6B7280),
  ];

  static String _emoji(ExpenseCategory c) => switch (c) {
        ExpenseCategory.food => '🍕',
        ExpenseCategory.transport => '🚗',
        ExpenseCategory.accommodation => '🏨',
        ExpenseCategory.entertainment => '🎬',
        ExpenseCategory.shopping => '🛍️',
        ExpenseCategory.utilities => '💡',
        ExpenseCategory.health => '💊',
        ExpenseCategory.education => '📚',
        ExpenseCategory.other => '📦',
      };

  @override
  Widget build(BuildContext context) {
    final Map<ExpenseCategory, double> totals = {};
    for (final e in widget.expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold(0.0, (s, e) => s + e.value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: sorted.asMap().entries.map((e) {
                  final i = e.key;
                  final amt = e.value.value;
                  final touched = i == _touchedIndex;
                  return PieChartSectionData(
                    value: amt,
                    color: _catColors[i % _catColors.length],
                    radius: touched ? 70 : 58,
                    title: touched
                        ? '${(amt / total * 100).toStringAsFixed(0)}%'
                        : '',
                    titleStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                    borderSide: touched
                        ? const BorderSide(color: Colors.white, width: 2)
                        : BorderSide.none,
                  );
                }).toList(),
                centerSpaceRadius: 44,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  touchCallback: (event, resp) => setState(() {
                    _touchedIndex =
                        resp?.touchedSection?.touchedSectionIndex ?? -1;
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: sorted.asMap().entries.map((e) {
              final i = e.key;
              final cat = e.value.key;
              final amt = e.value.value;
              return Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: _catColors[i % _catColors.length],
                        shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(
                  '${_emoji(cat)} ${CurrencyFormatter.format(amt, widget.currency)}',
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ]);
            }).toList(),
          ),
        ]),
      ),
    );
  }
}

// ── Member balance bar chart ──────────────────────────────────────────────────

class _MemberBalanceChart extends StatelessWidget {
  const _MemberBalanceChart({required this.members, required this.currency});
  final List<dynamic> members;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final nonZero = members.where((m) => (m.balance as double) != 0).toList();
    if (nonZero.isEmpty) return const SizedBox.shrink();

    final maxAbs = nonZero
        .map((m) => (m.balance as double).abs())
        .reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: maxAbs * 1.4,
              minY: -maxAbs * 1.4,
              barGroups: nonZero.asMap().entries.map((e) {
                final i = e.key;
                final bal = e.value.balance as double;
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: bal,
                    fromY: 0,
                    color: bal >= 0
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.error,
                    width: 24,
                    borderRadius: bal >= 0
                        ? const BorderRadius.vertical(top: Radius.circular(5))
                        : const BorderRadius.vertical(
                            bottom: Radius.circular(5)),
                  ),
                ]);
              }).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    getTitlesWidget: (val, _) {
                      final i = val.toInt();
                      if (i < 0 || i >= nonZero.length) return const SizedBox();
                      final name = nonZero[i].displayName as String;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(name.split(' ').first,
                            style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    getTitlesWidget: (val, _) => Text(
                      val.abs().toStringAsFixed(0),
                      style: TextStyle(
                          fontSize: 9,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: maxAbs / 2,
                getDrawingHorizontalLine: (_) => FlLine(
                    color: Theme.of(context).colorScheme.outline,
                    strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, gi, rod, ri) {
                    final m = nonZero[group.x];
                    return BarTooltipItem(
                      // '${m.displayName}\n$currency ${rod.toY.abs().toStringAsFixed(2)}',
                      '${m.displayName}\n${CurrencyFormatter.format(rod.toY.abs(), currency)}',
                      const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expenses Tab
// ─────────────────────────────────────────────────────────────────────────────

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

class _ExpensesTab extends StatelessWidget {
  const _ExpensesTab({required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (ctx, state) {
        final feed = <_FeedItem>[
          ...state.expenses.map(_ExpenseFeedItem.new),
          ...state.settlements.map(_SettlementFeedItem.new),
        ]..sort((a, b) => b.date.compareTo(a.date));

        if (feed.isEmpty) {
          return const EmptyState(
              icon: Icons.receipt_outlined,
              title: 'No expenses yet',
              subtitle: 'Add your first expense to start splitting');
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
            }
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
            return _SettlementTile(
                settlement: s, fromName: fromName, toName: toName);
          },
        );
      },
    );
  }
}

class _SettlementTile extends StatelessWidget {
  const _SettlementTile(
      {required this.settlement, required this.fromName, required this.toName});
  final SettlementEntity settlement;
  final String fromName;
  final String toName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: cs.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child:
                const Center(child: Text('🤝', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$fromName paid $toName',
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: cs.onSurface)),
              const SizedBox(height: 3),
              Row(children: [
                Text(DateFormat('MMM d').format(settlement.createdAt),
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                      color: cs.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text('Settlement',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: cs.secondary)),
                ),
              ]),
            ]),
          ),
          Text(
            CurrencyFormatter.format(settlement.amount, settlement.currency),
            style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 15, color: cs.secondary),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Balances Tab
// ─────────────────────────────────────────────────────────────────────────────

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

    final outstanding = group.members
        .where((m) => m.balance > 0)
        .fold(0.0, (s, m) => s + m.balance);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Spending',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                        CurrencyFormatter.format(
                            group.totalExpenses, group.currency),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700)),
                  ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('Outstanding',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text(CurrencyFormatter.format(outstanding, group.currency),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        ...group.members.map((m) {
          final Color c = m.isSettled
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : m.isOwed
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.error;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                  backgroundColor: c.withValues(alpha: 0.1),
                  child: Text(m.displayName.substring(0, 1).toUpperCase(),
                      style: TextStyle(color: c, fontWeight: FontWeight.w600))),
              title: Text(m.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(
                  m.isSettled
                      ? 'Settled up'
                      : m.isOwed
                          ? 'Gets back'
                          : 'Owes',
                  style: TextStyle(color: c)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                      CurrencyFormatter.format(m.balance.abs(), group.currency),
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15, color: c)),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 80,
                    height: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: group.totalExpenses > 0
                            ? (m.balance.abs() / group.totalExpenses)
                                .clamp(0.0, 1.0)
                            : 0,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(c),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settle Up Tab
// ─────────────────────────────────────────────────────────────────────────────

class _SettleUpTab extends StatelessWidget {
  const _SettleUpTab({required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (ctx, state) {
        final group = context
            .read<GroupBloc>()
            .state
            .groups
            .where((g) => g.id == groupId)
            .firstOrNull;
        final currentUserId = ctx.read<AuthBloc>().state.user?.id ?? '';

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // ── Simplify / Settle All action row ─────────────────────
            Row(children: [
              Expanded(
                child: _ActionChip(
                  icon: Icons.auto_fix_high_outlined,
                  label: 'Simplify Debts',
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () => ctx
                      .read<ExpenseBloc>()
                      .add(ExpenseDebtsRequested(groupId)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionChip(
                  icon: Icons.check_circle_outline,
                  label: 'Settle All',
                  color: Theme.of(context).colorScheme.secondary,
                  onTap: () => _confirmSettleAll(ctx, state, group),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            if (state.simplifiedDebts.isEmpty) ...[
              const SizedBox(height: 40),
              const EmptyState(
                icon: Icons.check_circle_outline,
                title: 'All settled!',
                subtitle: 'Everyone is even. No outstanding debts.',
              ),
            ] else ...[
              // Info banner
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3))),
                child: Row(children: [
                  const Icon(Icons.info_outline,
                      color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Simplified to ${state.simplifiedDebts.length} transaction${state.simplifiedDebts.length > 1 ? 's' : ''} · tap Simplify to recalculate',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFFF59E0B)),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              ...state.simplifiedDebts.map(
                (debt) => DebtCard(
                  debt: debt,
                  members: group?.members ?? [],
                  currentUserId: currentUserId,
                  onSettle: () => ctx
                      .read<ExpenseBloc>()
                      .add(ExpenseSettlementRequested(RecordSettlementParams(
                        groupId: groupId,
                        fromUserId: debt.debtorId,
                        toUserId: debt.creditorId,
                        amount: debt.amount,
                        currency: debt.currency,
                      ))),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _confirmSettleAll(
      BuildContext ctx, ExpenseState state, GroupEntity? group) {
    final debts = state.simplifiedDebts;
    if (debts.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('No outstanding debts to settle')));
      return;
    }
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('Settle All Debts'),
        content: Text(
            'Record ${debts.length} settlement${debts.length > 1 ? 's' : ''} and clear all outstanding balances?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.secondary,
                foregroundColor: Theme.of(ctx).colorScheme.onSecondary),
            onPressed: () {
              Navigator.pop(dCtx);
              for (final debt in debts) {
                ctx.read<ExpenseBloc>().add(ExpenseSettlementRequested(
                      RecordSettlementParams(
                        groupId: groupId,
                        fromUserId: debt.debtorId,
                        toUserId: debt.creditorId,
                        amount: debt.amount,
                        currency: debt.currency,
                      ),
                    ));
              }
              ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('All debts settled!')));
            },
            child:
                const Text('Settle All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Group Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddMemberSheet extends StatefulWidget {
  const _AddMemberSheet({required this.groupId});
  final String groupId;

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final emailCtrl = TextEditingController();

  @override
  void dispose() {
    emailCtrl.dispose();
    super.dispose();
  }

  void search() {
    final email = emailCtrl.text.trim();
    if (email.isEmpty) return;
    // Dismiss keyboard so the result card is visible without scrolling
    FocusScope.of(context).unfocus();
    context
        .read<GroupBloc>()
        .add(GroupMemberSearchRequested(email: email, groupId: widget.groupId));
  }

  @override
  Widget build(BuildContext context) {
    // Use viewInsets to shift up when keyboard is open
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        // SingleChildScrollView prevents overflow when result card + keyboard
        // are both visible at the same time
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Add Member',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Search by email address to add someone.',
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 20),
              // Search row
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.search,
                    autofocus: true,
                    onSubmitted: (_) => search(),
                    decoration: InputDecoration(
                      hintText: 'Enter email address',
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                BlocBuilder<GroupBloc, GroupState>(
                  buildWhen: (p, c) =>
                      p.memberSearchStatus != c.memberSearchStatus,
                  builder: (_, state) {
                    final searching = state.memberSearchStatus ==
                        MemberSearchStatus.searching;
                    return ElevatedButton(
                      onPressed: searching ? null : search,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: searching
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Search'),
                    );
                  },
                ),
              ]),
              const SizedBox(height: 20),
              // Result area
              BlocConsumer<GroupBloc, GroupState>(
                listenWhen: (p, c) =>
                    p.memberSearchStatus != c.memberSearchStatus,
                listener: (ctx, state) {
                  if (state.memberSearchStatus == MemberSearchStatus.added) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content: Text('Member added successfully')));
                  }
                },
                buildWhen: (p, c) =>
                    p.memberSearchStatus != c.memberSearchStatus ||
                    p.foundUser != c.foundUser,
                builder: (ctx, state) {
                  return switch (state.memberSearchStatus) {
                    MemberSearchStatus.idle => const SizedBox.shrink(),
                    MemberSearchStatus.searching => const Center(
                        child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: CircularProgressIndicator())),
                    MemberSearchStatus.notFound => _StatusPill(
                        icon: Icons.search_off,
                        color: Theme.of(context).colorScheme.error,
                        text: 'No user found with that email address.'),
                    MemberSearchStatus.alreadyMember => _StatusPill(
                        icon: Icons.check_circle_outline,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        text:
                            '${state.foundUser?.displayName ?? 'This user'} is already in the group.'),
                    MemberSearchStatus.addFailure => _StatusPill(
                        icon: Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                        text: state.memberSearchError ??
                            'Failed to add member. Please try again.'),
                    MemberSearchStatus.found => _FoundUserCard(
                        user: state.foundUser!,
                        onAdd: () => ctx.read<GroupBloc>().add(
                            GroupMemberAddRequested(
                                groupId: widget.groupId,
                                user: state.foundUser!))),
                    MemberSearchStatus.adding => _FoundUserCard(
                        user: state.foundUser!, loading: true, onAdd: () {}),
                    MemberSearchStatus.added => const SizedBox.shrink(),
                  };
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.color,
    required this.text,
  });
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ),
      ]);
}

class _FoundUserCard extends StatelessWidget {
  const _FoundUserCard({
    required this.user,
    required this.onAdd,
    this.loading = false,
  });

  // Typed as UserEntity — no more unsafe dynamic casts
  final UserEntity user;
  final VoidCallback onAdd;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.05),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: cs.primaryContainer,
          backgroundImage:
              user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
          child: user.photoUrl == null
              ? Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w600))
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.displayName,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: cs.onSurface)),
              Text(user.email,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: loading ? null : onAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: loading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: cs.onPrimary))
              : const Text('Add'),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Member — Method Picker
// ─────────────────────────────────────────────────────────────────────────────

class _AddMemberPickerSheet extends StatelessWidget {
  const _AddMemberPickerSheet({
    required this.groupId,
    required this.groupName,
    required this.groupBloc,
  });

  final String groupId;
  final String groupName;
  final GroupBloc groupBloc;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ──────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Add Member',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose how to invite someone to $groupName',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),

          // ── Option 1: Search by email ────────────────────────────────
          _OptionTile(
            icon: Icons.email_outlined,
            iconColor: cs.primary,
            title: 'Search by Email',
            subtitle: 'Find and add a registered Paypact user',
            onTap: () {
              Navigator.pop(context);
              groupBloc.add(GroupMemberSearchCleared());
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => BlocProvider.value(
                  value: groupBloc,
                  child: _AddMemberSheet(groupId: groupId),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // ── Option 2: QR Code ────────────────────────────────────────
          _OptionTile(
            icon: Icons.qr_code_2_outlined,
            iconColor: const Color(0xFF8B5CF6),
            title: 'Show QR Code',
            subtitle: 'Let someone scan to join instantly',
            onTap: () {
              Navigator.pop(context);
              groupBloc.add(GroupInviteLinkRequested(groupId));
              Future.delayed(const Duration(milliseconds: 400), () {
                if (!context.mounted) return;
                final state = groupBloc.state;
                final group =
                    state.groups.where((g) => g.id == groupId).firstOrNull;
                final code = group?.inviteCode;
                if (code == null || code.isEmpty) return;
                final link = 'https://paypact-fec8e.web.app/invite/$code';
                QrInviteSheet.show(
                  context,
                  groupName: groupName,
                  inviteCode: code,
                  inviteLink: link,
                );
              });
            },
          ),
          const SizedBox(height: 10),

          // ── Option 3: Invite Link ────────────────────────────────────
          _OptionTile(
            icon: Icons.link_rounded,
            iconColor: cs.secondary,
            title: 'Share Invite Link',
            subtitle: 'Copy or share a link anyone can tap to join',
            onTap: () {
              Navigator.pop(context);
              groupBloc.add(GroupInviteLinkRequested(groupId));
              Future.delayed(const Duration(milliseconds: 400), () {
                if (!context.mounted) return;
                final link = groupBloc.state.inviteLink;
                if (link != null) {
                  SharePlus.instance.share(ShareParams(
                      title: 'Join my group "$groupName" on Paypact!',
                      text: link));
                }
              });
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable option tile for the picker sheet
// ─────────────────────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: cs.onSurface)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 20),
        ]),
      ),
    );
  }
}
