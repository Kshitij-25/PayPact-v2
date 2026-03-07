import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paypact/core/theme/app_theme.dart';
import 'package:paypact/domain/entities/expense_entity.dart';
import 'package:paypact/domain/entities/group_entity.dart';
import 'package:paypact/domain/entities/settlement_entity.dart';
import 'package:paypact/domain/use_cases/record_settlement_use_case.dart';
import 'package:paypact/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:paypact/presentation/bloc/expense_bloc/expense_bloc.dart';
import 'package:paypact/presentation/bloc/group_bloc/group_bloc.dart';
import 'package:paypact/presentation/widgets/common/empty_states.dart';
import 'package:paypact/presentation/widgets/expense/expense_list_item.dart';
import 'package:paypact/presentation/widgets/group/debt_card.dart';
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
                  onPressed: () => _showAddMemberSheet(ctx),
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => _shareInviteLink(ctx),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _showEditSheet(ctx, group);
                    if (v == 'settle') _confirmSettleAll(ctx);
                    if (v == 'delete') _confirmDelete(ctx, group);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit', child: Text('Edit Group')),
                    const PopupMenuItem(
                        value: 'settle', child: Text('Settle All')),
                    PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete Group',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error))),
                  ],
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: PaypactColors.textSecondary,
                indicatorColor: Theme.of(context).colorScheme.primary,
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
              foregroundColor: Colors.white,
            ),
          );
        },
      ),
    );
  }

  void _shareInviteLink(BuildContext ctx) {
    ctx.read<GroupBloc>().add(GroupInviteLinkRequested(widget.groupId));
    final link = ctx.read<GroupBloc>().state.inviteLink;
    if (link != null) Share.share('Join my group on Paypact: $link');
  }

  void _showAddMemberSheet(BuildContext ctx) {
    ctx.read<GroupBloc>().add(GroupMemberSearchCleared());
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: ctx.read<GroupBloc>(),
        child: _AddMemberSheet(groupId: widget.groupId),
      ),
    );
  }

  void _showEditSheet(BuildContext ctx, GroupEntity? group) {
    if (group == null) return;
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: ctx.read<GroupBloc>(),
        child: _EditGroupSheet(group: group),
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
                backgroundColor: Theme.of(context).colorScheme.secondary),
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

  void _confirmDelete(BuildContext ctx, GroupEntity? group) {
    if (group == null) return;
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text(
            'Delete "${group.name}"? All data will be permanently removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              Navigator.pop(dCtx);
              ctx.read<GroupBloc>().add(GroupDeleteRequested(widget.groupId));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
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
            _SectionLabel('Group Info'),
            const SizedBox(height: 10),
            _GroupInfoCard(group: group),
            const SizedBox(height: 24),
            _SectionLabel('Members (${group.memberCount})'),
            const SizedBox(height: 10),
            ...group.members.map((m) => _MemberTile(
                  member: m,
                  currency: group.currency,
                  isMe: m.userId == currentUserId,
                )),
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
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: PaypactColors.textSecondary,
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
    final Color balColor = myBalance > 0
        ? Theme.of(context).colorScheme.secondary
        : myBalance < 0
            ? Theme.of(context).colorScheme.error
            : PaypactColors.textSecondary;
    final String balLabel = myBalance > 0
        ? 'you get back'
        : myBalance < 0
            ? 'you owe'
            : 'all settled';

    return Row(children: [
      Expanded(
        child: _StatCard(
          icon: Icons.receipt_long_outlined,
          iconColor: Theme.of(context).colorScheme.primary,
          label: 'Total Spent',
          value: '$c ${group.totalExpenses.toStringAsFixed(2)}',
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
          value: '$c ${myBalance.abs().toStringAsFixed(2)}',
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
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: PaypactColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: valueColor ??
                          Theme.of(context).colorScheme.onPrimary),
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

  static String _label(ExpenseCategory c) => switch (c) {
        ExpenseCategory.food => 'Food',
        ExpenseCategory.transport => 'Transport',
        ExpenseCategory.accommodation => 'Stay',
        ExpenseCategory.entertainment => 'Fun',
        ExpenseCategory.shopping => 'Shop',
        ExpenseCategory.utilities => 'Bills',
        ExpenseCategory.health => 'Health',
        ExpenseCategory.education => 'Study',
        ExpenseCategory.other => 'Other',
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
                  '${_emoji(cat)} ${_label(cat)} ${widget.currency} ${amt.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 11, color: PaypactColors.textSecondary),
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
                            style: const TextStyle(
                                fontSize: 10,
                                color: PaypactColors.textSecondary)),
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
                      style: const TextStyle(
                          fontSize: 9, color: PaypactColors.textSecondary),
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
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: PaypactColors.divider, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, gi, rod, ri) {
                    final m = nonZero[group.x];
                    return BarTooltipItem(
                      '${m.displayName}\n$currency ${rod.toY.abs().toStringAsFixed(2)}',
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

// ── Group info card ───────────────────────────────────────────────────────────

class _GroupInfoCard extends StatelessWidget {
  const _GroupInfoCard({required this.group});
  final GroupEntity group;

  static String _catLabel(GroupCategory c) => switch (c) {
        GroupCategory.home => '🏠 Home',
        GroupCategory.trip => '✈️ Trip',
        GroupCategory.couple => '❤️ Couple',
        GroupCategory.friends => '👯 Friends',
        GroupCategory.work => '💼 Work',
        GroupCategory.other => '📂 Other',
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(children: [
          _InfoRow(
              Icons.category_outlined, 'Category', _catLabel(group.category)),
          const Divider(height: 18),
          _InfoRow(Icons.currency_exchange, 'Currency', group.currency),
          const Divider(height: 18),
          _InfoRow(Icons.calendar_today_outlined, 'Created',
              DateFormat('MMM d, yyyy').format(group.createdAt)),
          if (group.inviteCode != null) ...[
            const Divider(height: 18),
            _InfoRow(
              Icons.qr_code_outlined,
              'Invite code',
              group.inviteCode!,
              trailing: IconButton(
                icon: const Icon(Icons.copy_outlined, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: group.inviteCode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invite code copied')));
                },
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value, {this.trailing});
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 16, color: PaypactColors.textSecondary),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: PaypactColors.textSecondary)),
        const Spacer(),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        if (trailing != null) ...[const SizedBox(width: 4), trailing!],
      ]);
}

// ── Member tile ───────────────────────────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  const _MemberTile(
      {required this.member, required this.currency, required this.isMe});
  final dynamic member;
  final String currency;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final bal = member.balance as double;
    final Color c = bal > 0
        ? Theme.of(context).colorScheme.secondary
        : bal < 0
            ? Theme.of(context).colorScheme.error
            : PaypactColors.textSecondary;
    final isAdmin = member.role.toString().contains('admin');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
          backgroundImage: (member.photoUrl as String?) != null
              ? NetworkImage(member.photoUrl as String)
              : null,
          child: (member.photoUrl as String?) == null
              ? Text(
                  (member.displayName as String).substring(0, 1).toUpperCase(),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600))
              : null,
        ),
        title: Row(children: [
          Flexible(
              child: Text(member.displayName as String,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14))),
          if (isMe) _Badge('You', Theme.of(context).colorScheme.primary),
          if (isAdmin) _Badge('admin', PaypactColors.warning),
        ]),
        subtitle: Text(member.email as String,
            style: const TextStyle(
                fontSize: 11, color: PaypactColors.textSecondary)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$currency ${bal.abs().toStringAsFixed(2)}',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13, color: c)),
            Text(
                bal > 0
                    ? 'gets back'
                    : bal < 0
                        ? 'owes'
                        : 'settled',
                style: TextStyle(fontSize: 10, color: c)),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(left: 5),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4)),
        child: Text(text,
            style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w700, color: color)),
      );
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
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: const Center(
                  child: Text('🤝', style: TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$fromName paid $toName',
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 15)),
                    const SizedBox(height: 3),
                    Row(children: [
                      Text(DateFormat('MMM d').format(settlement.createdAt),
                          style: const TextStyle(
                              fontSize: 12,
                              color: PaypactColors.textSecondary)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4)),
                        child: Text('Settlement',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color:
                                    Theme.of(context).colorScheme.secondary)),
                      ),
                    ]),
                  ]),
            ),
            Text(
              '${settlement.currency} ${settlement.amount.toStringAsFixed(2)}',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.secondary),
            ),
          ]),
        ),
      );
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
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
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
                        '${group.currency} ${group.totalExpenses.toStringAsFixed(2)}',
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
              Text('${group.currency} ${outstanding.toStringAsFixed(2)}',
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
              ? PaypactColors.textSecondary
              : m.isOwed
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.error;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                  backgroundColor: c.withOpacity(0.1),
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
                      '${group.currency} ${m.balance.abs().toStringAsFixed(2)}',
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
      builder: (_, state) {
        if (state.simplifiedDebts.isEmpty) {
          return const EmptyState(
              icon: Icons.check_circle_outline,
              title: 'All settled!',
              subtitle: 'Everyone is even. No outstanding debts.');
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                  color: PaypactColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: PaypactColors.warning.withOpacity(0.3))),
              child: Row(children: [
                const Icon(Icons.info_outline,
                    color: PaypactColors.warning, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Simplified to ${state.simplifiedDebts.length} transaction${state.simplifiedDebts.length > 1 ? 's' : ''} to settle all debts.',
                    style: const TextStyle(
                        fontSize: 13, color: PaypactColors.warning),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            ...state.simplifiedDebts.map(
              (debt) => DebtCard(
                debt: debt,
                members: group?.members ?? [],
                currentUserId: context.read<AuthBloc>().state.user?.id ?? '',
                onSettle: () =>
                    context.read<ExpenseBloc>().add(ExpenseSettlementRequested(
                          RecordSettlementParams(
                            groupId: groupId,
                            fromUserId: debt.debtorId,
                            toUserId: debt.creditorId,
                            amount: debt.amount,
                            currency: debt.currency,
                          ),
                        )),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Group Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _EditGroupSheet extends StatefulWidget {
  const _EditGroupSheet({required this.group});
  final GroupEntity group;

  @override
  State<_EditGroupSheet> createState() => _EditGroupSheetState();
}

class _EditGroupSheetState extends State<_EditGroupSheet> {
  late final TextEditingController _nameCtrl;
  late GroupCategory _category;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.group.name);
    _category = widget.group.category;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    context.read<GroupBloc>().add(GroupUpdateRequested(
        widget.group.copyWith(name: name, category: _category)));
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Group updated')));
  }

  static String _catLabel(GroupCategory c) => switch (c) {
        GroupCategory.home => '🏠 Home',
        GroupCategory.trip => '✈️ Trip',
        GroupCategory.couple => '❤️ Couple',
        GroupCategory.friends => '👯 Friends',
        GroupCategory.work => '💼 Work',
        GroupCategory.other => '📂 Other',
      };

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            const Text('Edit Group',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                  labelText: 'Group name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 16),
            const Text('Category',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: GroupCategory.values.map((cat) {
                final sel = cat == _category;
                return ChoiceChip(
                  label: Text(_catLabel(cat)),
                  selected: sel,
                  selectedColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  labelStyle: TextStyle(
                      color: sel
                          ? Theme.of(context).colorScheme.primary
                          : PaypactColors.textPrimary,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.normal),
                  onSelected: (_) => setState(() => _category = cat),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Save Changes',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Member Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddMemberSheet extends StatefulWidget {
  const _AddMemberSheet({required this.groupId});
  final String groupId;

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _search() {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    context
        .read<GroupBloc>()
        .add(GroupMemberSearchRequested(email: email, groupId: widget.groupId));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            const Text('Add Member',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Search by email to add someone.',
                style: TextStyle(
                    fontSize: 13, color: PaypactColors.textSecondary)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  onSubmitted: (_) => _search(),
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
                  final searching =
                      state.memberSearchStatus == MemberSearchStatus.searching;
                  return ElevatedButton(
                    onPressed: searching ? null : _search,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
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
              builder: (ctx, state) => switch (state.memberSearchStatus) {
                MemberSearchStatus.idle => const SizedBox.shrink(),
                MemberSearchStatus.searching => const Center(
                    child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator())),
                MemberSearchStatus.notFound => _pill(
                    Icons.search_off,
                    Theme.of(context).colorScheme.error,
                    'No user found with that email.'),
                MemberSearchStatus.alreadyMember => _pill(
                    Icons.check_circle_outline,
                    PaypactColors.textSecondary,
                    '${state.foundUser?.displayName ?? 'This user'} is already in the group.'),
                MemberSearchStatus.found => _FoundUserCard(
                    user: state.foundUser!,
                    onAdd: () => ctx.read<GroupBloc>().add(
                        GroupMemberAddRequested(
                            groupId: widget.groupId, user: state.foundUser!))),
                MemberSearchStatus.adding => _FoundUserCard(
                    user: state.foundUser!, loading: true, onAdd: () {}),
                MemberSearchStatus.added => const SizedBox.shrink(),
                MemberSearchStatus.addFailure => _pill(
                    Icons.error_outline,
                    Theme.of(context).colorScheme.error,
                    state.memberSearchError ?? 'Failed to add member.'),
              },
            ),
          ]),
    );
  }

  Widget _pill(IconData icon, Color color, String text) => Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: TextStyle(color: color, fontWeight: FontWeight.w500))),
      ]);
}

class _FoundUserCard extends StatelessWidget {
  const _FoundUserCard(
      {required this.user, required this.onAdd, this.loading = false});
  final dynamic user;
  final VoidCallback onAdd;
  final bool loading;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
            backgroundImage: (user.photoUrl as String?) != null
                ? NetworkImage(user.photoUrl as String)
                : null,
            child: (user.photoUrl as String?) == null
                ? Text(
                    (user.displayName as String).substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user.displayName as String,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
              Text(user.email as String,
                  style: const TextStyle(
                      fontSize: 12, color: PaypactColors.textSecondary)),
            ]),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: loading ? null : onAdd,
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Add'),
          ),
        ]),
      );
}
