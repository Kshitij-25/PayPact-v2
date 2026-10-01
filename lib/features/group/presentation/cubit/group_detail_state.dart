part of 'group_detail_cubit.dart';

abstract class GroupDetailState {}

class GroupDetailInitial extends GroupDetailState {}

class GroupDetailLoading extends GroupDetailState {}

class GroupDetailLoaded extends GroupDetailState {
  final GroupEntity group;
  final List<ExpenseEntity> expenses;
  final double netBalance;
  final Map<String, double> memberBalances;
  /// Net balance for every member globally (positive = creditor, negative = debtor).
  final Map<String, double> globalMemberBalances;

  /// Recorded settle-up payments (newest first), for the activity timeline.
  final List<Map<String, dynamic>> settlements;

  /// Older expenses exist beyond the loaded page.
  final bool canLoadMore;

  GroupDetailLoaded({
    required this.group,
    required this.expenses,
    required this.netBalance,
    required this.memberBalances,
    required this.globalMemberBalances,
    this.settlements = const [],
    this.canLoadMore = false,
  });
}

class GroupDetailError extends GroupDetailState {
  final String message;
  GroupDetailError(this.message);
}
