part of 'group_detail_cubit.dart';

abstract class GroupDetailState {}

class GroupDetailInitial extends GroupDetailState {}

class GroupDetailLoading extends GroupDetailState {}

class GroupDetailLoaded extends GroupDetailState {
  final GroupEntity group;
  final List<ExpenseEntity> expenses;
  final double netBalance;
  final Map<String, double> memberBalances;

  GroupDetailLoaded({
    required this.group,
    required this.expenses,
    required this.netBalance,
    required this.memberBalances,
  });
}

class GroupDetailError extends GroupDetailState {
  final String message;
  GroupDetailError(this.message);
}
