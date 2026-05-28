import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';

part 'groups_state.dart';

class GroupsCubit extends Cubit<GroupsState> {
  final GroupRepository _groupRepo;
  final ExpenseRepository _expenseRepo;
  final String _userId;
  StreamSubscription<List<GroupEntity>>? _sub;

  GroupsCubit(this._groupRepo, this._expenseRepo, this._userId)
      : super(GroupsInitial());

  void loadGroups() {
    emit(GroupsLoading());
    _sub = _groupRepo.watchUserGroups(_userId).listen(
      (groups) async {
        final results = await Future.wait(
          groups.map((g) async {
            final expenses = await _expenseRepo.getGroupExpenses(g.id);
            final settlements = await _expenseRepo.getGroupSettlements(g.id);
            g.netBalance = _computeBalance(expenses, settlements, _userId);
            return (g, expenses, settlements);
          }),
        );

        final total = groups.fold<double>(0, (sum, g) => sum + g.netBalance);

        final now = DateTime.now();
        final weekStart = DateTime(now.year, now.month, now.day - (now.weekday - 1));

        double weeklyDelta = 0;

        // Per-member tracking for smart nudge
        final Map<String, double> memberBalance = {};
        final Map<String, DateTime> memberLastActivity = {};
        final Map<String, String> memberNames = {};
        final Map<String, String> memberGroupNames = {};
        final Map<String, String> memberGroupIds = {};
        final Map<String, String> memberGroupCurrency = {};

        final List<RecentExpenseItem> allExpenses = [];

        for (final (group, expenses, settlements) in results) {
          for (final e in expenses) {
            allExpenses.add(RecentExpenseItem(
              expenseId: e.id,
              groupId: group.id,
              title: e.title,
              groupName: group.name,
              groupEmoji: group.emoji,
              amount: e.amount,
              isPaidByCurrentUser: e.paidById == _userId,
              paidByName: e.paidByName,
              createdAt: e.createdAt,
              category: e.category,
              currency: group.currency,
            ));

            // Weekly delta
            if (!e.createdAt.isBefore(weekStart)) {
              final myShare = e.splitAmountFor(_userId);
              if (e.paidById == _userId) {
                weeklyDelta += (e.amount - myShare);
              } else {
                weeklyDelta -= myShare;
              }
            }

            // Track what each member owes me
            if (e.paidById == _userId) {
              for (final split in e.splits) {
                if (split.userId != _userId && split.amount > 0) {
                  memberBalance[split.userId] =
                      (memberBalance[split.userId] ?? 0) + split.amount;
                  memberNames[split.userId] ??= split.userName;
                  memberGroupNames[split.userId] ??= group.name;
                  memberGroupIds[split.userId] ??= group.id;
                  memberGroupCurrency[split.userId] ??= group.currency;
                  final prev = memberLastActivity[split.userId];
                  if (prev == null || e.createdAt.isAfter(prev)) {
                    memberLastActivity[split.userId] = e.createdAt;
                  }
                }
              }
            }
          }

          for (final s in settlements) {
            final fromId = s['fromUserId'] as String? ?? '';
            final toId = s['toUserId'] as String? ?? '';
            final amount = (s['amount'] as num?)?.toDouble() ?? 0.0;
            final settledAt = s['createdAt'] as DateTime?;

            // Weekly delta for settlements
            if (settledAt != null && !settledAt.isBefore(weekStart)) {
              if (toId == _userId) {
                weeklyDelta -= amount;
              } else if (fromId == _userId) {
                weeklyDelta += amount;
              }
            }

            // Reduce member balance
            if (toId == _userId && memberBalance.containsKey(fromId)) {
              memberBalance[fromId] =
                  math.max(0, (memberBalance[fromId]! - amount));
            }

            // Update last activity for nudge
            if (toId == _userId && fromId.isNotEmpty && settledAt != null) {
              final prev = memberLastActivity[fromId];
              if (prev == null || settledAt.isAfter(prev)) {
                memberLastActivity[fromId] = settledAt;
              }
            }
          }
        }

        // Recent expenses — most recent first, top 5
        allExpenses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final recentExpenses = allExpenses.take(5).toList();

        // Smart nudge — pick person with longest silence who still owes ≥ ₹10
        SmartNudgeData? smartNudge;
        const minDaysSilent = 5;
        int longestSilence = 0;

        memberBalance.forEach((uid, owed) {
          if (owed < 10) return;
          final lastActivity = memberLastActivity[uid];
          final daysSilent = lastActivity != null
              ? now.difference(lastActivity).inDays
              : 0;
          if (daysSilent >= minDaysSilent && daysSilent > longestSilence) {
            longestSilence = daysSilent;
            smartNudge = SmartNudgeData(
              memberName: memberNames[uid] ?? 'Member',
              groupName: memberGroupNames[uid] ?? '',
              groupId: memberGroupIds[uid] ?? '',
              fromUserId: uid,
              amountOwed: owed,
              daysSilent: daysSilent,
              currency: memberGroupCurrency[uid] ?? 'INR',
            );
          }
        });

        emit(GroupsLoaded(
          groups: groups,
          totalNetBalance: total,
          weeklyDelta: weeklyDelta,
          smartNudge: smartNudge,
          recentExpenses: recentExpenses,
        ));
      },
      onError: (e) => emit(GroupsError(e.toString())),
    );
  }

  double _computeBalance(List expenses, List<Map<String, dynamic>> settlements,
      String userId) {
    double balance = 0;
    for (final e in expenses) {
      final myShare = e.splitAmountFor(userId);
      if (e.paidById == userId) {
        balance += (e.amount - myShare);
      } else {
        balance -= myShare;
      }
    }
    for (final s in settlements) {
      if (s['fromUserId'] == userId) {
        balance += (s['amount'] as num).toDouble();
      } else if (s['toUserId'] == userId) {
        balance -= (s['amount'] as num).toDouble();
      }
    }
    return balance;
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
