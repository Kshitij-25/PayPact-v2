part of 'expense_detail_cubit.dart';

abstract class ExpenseDetailState {}

class ExpenseDetailInitial extends ExpenseDetailState {}

class ExpenseDetailLoading extends ExpenseDetailState {}

class ExpenseDetailLoaded extends ExpenseDetailState {
  final ExpenseEntity expense;
  final String currentUserId;

  ExpenseDetailLoaded({required this.expense, required this.currentUserId});
}

class ExpenseDetailError extends ExpenseDetailState {
  final String message;
  ExpenseDetailError(this.message);
}
