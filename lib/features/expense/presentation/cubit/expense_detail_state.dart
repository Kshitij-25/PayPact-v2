part of 'expense_detail_cubit.dart';

abstract class ExpenseDetailState {}

class ExpenseDetailInitial extends ExpenseDetailState {}

class ExpenseDetailLoading extends ExpenseDetailState {}

class ExpenseDetailLoaded extends ExpenseDetailState {
  final ExpenseEntity expense;
  final String currentUserId;

  /// Currency code of the group (the unit of `expense.amount` and the splits).
  final String currency;

  ExpenseDetailLoaded({
    required this.expense,
    required this.currentUserId,
    this.currency = kDefaultCurrency,
  });
}

class ExpenseDetailError extends ExpenseDetailState {
  final String message;
  ExpenseDetailError(this.message);
}
