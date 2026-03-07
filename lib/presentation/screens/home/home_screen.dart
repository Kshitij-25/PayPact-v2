import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paypact/core/theme/app_theme.dart';
import 'package:paypact/domain/entities/expense_entity.dart';
import 'package:paypact/domain/entities/settlement_entity.dart';
import 'package:paypact/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:paypact/presentation/bloc/expense_bloc/expense_bloc.dart';
import 'package:paypact/presentation/bloc/group_bloc/group_bloc.dart';
import 'package:paypact/presentation/widgets/common/empty_states.dart';
import 'package:paypact/presentation/widgets/common/shimmer_loader.dart';
import 'package:paypact/presentation/widgets/group/group_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.pendingInviteCode});
  final String? pendingInviteCode;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<String> _lastGroupIds = [];

  @override
  void initState() {
    super.initState();
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId != null) {
      context.read<GroupBloc>().add(GroupLoadRequested(userId));
    }
    if (widget.pendingInviteCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleInviteCode(widget.pendingInviteCode!);
      });
    }
  }

  void _handleInviteCode(String code) {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;
    context.read<GroupBloc>().add(GroupJoinRequested(
          inviteCode: code,
          user: user,
        ));
  }

  void _maybeRefreshActivity(List<String> groupIds) {
    if (groupIds.isEmpty || groupIds == _lastGroupIds) return;
    _lastGroupIds = groupIds;
    context.read<ExpenseBloc>().add(ActivityLoadRequested(groupIds));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GroupBloc, GroupState>(
      listenWhen: (prev, curr) => prev.groups != curr.groups,
      listener: (_, state) {
        _maybeRefreshActivity(state.groups.map((g) => g.id).toList());
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Paypact'),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
            GestureDetector(
              onTap: () => context.push('/profile'),
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (_, state) => CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.4),
                    backgroundImage: state.user?.photoUrl != null
                        ? CachedNetworkImageProvider(state.user!.photoUrl!)
                        : null,
                    child: state.user?.photoUrl == null
                        ? Text(
                            state.user?.displayName
                                    .substring(0, 1)
                                    .toUpperCase() ??
                                'U',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: const [
            _GroupsTab(),
            _ActivityTab(),
          ],
        ),
        floatingActionButton: _selectedIndex == 0
            ? FloatingActionButton.extended(
                onPressed: () => context.push('/group/create'),
                icon: const Icon(Icons.add),
                label: const Text('New Group'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              )
            : null,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              activeIcon: Icon(Icons.group),
              label: 'Groups',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Activity',
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupsTab extends StatelessWidget {
  const _GroupsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupBloc, GroupState>(
      builder: (context, state) {
        if (state.status == GroupStatus.loading && state.groups.isEmpty) {
          return const ShimmerLoader();
        }
        if (state.groups.isEmpty) {
          return const EmptyState(
            icon: Icons.group_outlined,
            title: 'No groups yet',
            subtitle: 'Create a group to start splitting expenses with friends',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: state.groups.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => GroupCard(
            group: state.groups[index],
            currentUserId: context.read<AuthBloc>().state.user?.id ?? '',
            onTap: () => context.push(
              '/group/${state.groups[index].id}',
            ),
          ),
        );
      },
    );
  }
}

// ── Activity feed ──────────────────────────────────────────────────────────

sealed class _ActivityItem {
  DateTime get date;
}

class _ExpenseActivityItem extends _ActivityItem {
  _ExpenseActivityItem(this.expense);
  final ExpenseEntity expense;
  @override
  DateTime get date => expense.createdAt;
}

class _SettlementActivityItem extends _ActivityItem {
  _SettlementActivityItem(this.settlement);
  final SettlementEntity settlement;
  @override
  DateTime get date => settlement.createdAt;
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      buildWhen: (prev, curr) =>
          prev.activityExpenses != curr.activityExpenses ||
          prev.activitySettlements != curr.activitySettlements,
      builder: (ctx, state) {
        final feed = <_ActivityItem>[
          ...state.activityExpenses.map(_ExpenseActivityItem.new),
          ...state.activitySettlements.map(_SettlementActivityItem.new),
        ]..sort((a, b) => b.date.compareTo(a.date));

        if (feed.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No recent activity',
            subtitle:
                'Your expense activity across all groups will appear here',
          );
        }

        final groups = ctx.read<GroupBloc>().state.groups;

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: feed.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
          itemBuilder: (_, i) {
            final item = feed[i];
            if (item is _ExpenseActivityItem) {
              final e = item.expense;
              final groupName =
                  groups.where((g) => g.id == e.groupId).firstOrNull?.name ??
                      '';
              return _ActivityTile(
                emoji: _categoryEmoji(e.category),
                emojiColor: Theme.of(context).colorScheme.primary,
                title: e.title,
                subtitle: groupName.isNotEmpty
                    ? '$groupName · ${DateFormat('MMM d').format(e.createdAt)}'
                    : DateFormat('MMM d').format(e.createdAt),
                amount: '${e.currency} ${e.amount.toStringAsFixed(2)}',
                amountColor: Theme.of(context).colorScheme.onSurface,
              );
            } else {
              final s = (item as _SettlementActivityItem).settlement;
              final groupName =
                  groups.where((g) => g.id == s.groupId).firstOrNull?.name ??
                      '';
              return _ActivityTile(
                emoji: '🤝',
                emojiColor: PaypactColors.secondary,
                title: 'Settlement',
                subtitle: groupName.isNotEmpty
                    ? '$groupName · ${DateFormat('MMM d').format(s.createdAt)}'
                    : DateFormat('MMM d').format(s.createdAt),
                amount: '${s.currency} ${s.amount.toStringAsFixed(2)}',
                amountColor: PaypactColors.secondary,
                badge: 'Settled',
              );
            }
          },
        );
      },
    );
  }

  String _categoryEmoji(ExpenseCategory cat) => switch (cat) {
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
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.emoji,
    required this.emojiColor,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountColor,
    this.badge,
  });

  final String emoji;
  final Color emojiColor;
  final String title;
  final String subtitle;
  final String amount;
  final Color amountColor;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: emojiColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 14)),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color:
                              PaypactColors.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: PaypactColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: PaypactColors.textSecondary)),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14, color: amountColor),
          ),
        ],
      ),
    );
  }
}
