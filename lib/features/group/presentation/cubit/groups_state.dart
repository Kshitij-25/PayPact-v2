part of 'groups_cubit.dart';

class MemberBalanceItem {
  const MemberBalanceItem({
    required this.userId,
    required this.name,
    required this.netBalance,
    required this.currency,
    required this.groupName,
    this.daysSilent = 0,
  });
  final String userId;
  final String name;
  final double netBalance; // positive = they owe me, negative = I owe them
  final String currency;
  final String groupName;
  final int daysSilent;
}

class SmartNudgeData {
  const SmartNudgeData({
    required this.memberName,
    required this.groupName,
    required this.groupId,
    required this.fromUserId,
    required this.amountOwed,
    required this.daysSilent,
    required this.currency,
  });
  final String memberName;
  final String groupName;
  final String groupId;
  final String fromUserId;
  final double amountOwed;
  final int daysSilent;
  final String currency; // ISO code e.g. 'INR'
}

class RecentExpenseItem {
  const RecentExpenseItem({
    required this.expenseId,
    required this.groupId,
    required this.title,
    required this.groupName,
    required this.groupEmoji,
    required this.amount,
    required this.isPaidByCurrentUser,
    required this.paidByName,
    required this.createdAt,
    required this.category,
    required this.currency,
  });
  final String expenseId;
  final String groupId;
  final String title;
  final String groupName;
  final String groupEmoji;
  final double amount;
  final bool isPaidByCurrentUser;
  final String paidByName;
  final DateTime createdAt;
  final String category;
  final String currency;
}

abstract class GroupsState {}

class GroupsInitial extends GroupsState {}

class GroupsLoading extends GroupsState {}

class GroupsLoaded extends GroupsState {
  GroupsLoaded({
    required this.groups,
    required this.totalNetBalance,
    this.weeklyDelta = 0,
    this.smartNudge,
    this.recentExpenses = const [],
    this.memberBalances = const [],
    this.avgSettleDays = 0,
  });
  final List<GroupEntity> groups;
  final double totalNetBalance;
  final double weeklyDelta;
  final SmartNudgeData? smartNudge;
  final List<RecentExpenseItem> recentExpenses;
  final List<MemberBalanceItem> memberBalances;
  final double avgSettleDays;
}

class GroupsError extends GroupsState {
  GroupsError(this.message);
  final String message;
}
