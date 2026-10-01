part of 'expense_detail_cubit.dart';

abstract class ExpenseDetailState {}

class ExpenseDetailInitial extends ExpenseDetailState {}

class ExpenseDetailLoading extends ExpenseDetailState {}

class ExpenseDetailLoaded extends ExpenseDetailState {
  final ExpenseEntity expense;
  final String currentUserId;

  /// Currency code of the group (the unit of `expense.amount` and the splits).
  final String currency;
  final String groupName;

  /// Display name / emoji when the expense uses one of the group's own
  /// categories (otherwise null and the built-in category is shown).
  final String? customCategoryName;
  final String? customCategoryEmoji;

  /// People in the split who still owe money in this group (not the payer).
  /// Where the group has a balance summary this is exact; otherwise it's every
  /// other person in the split.
  final List<ExpenseSplitEntity> remindable;

  ExpenseDetailLoaded({
    required this.expense,
    required this.currentUserId,
    this.currency = kDefaultCurrency,
    this.groupName = '',
    this.customCategoryName,
    this.customCategoryEmoji,
    this.remindable = const [],
  });
}

class ExpenseDetailError extends ExpenseDetailState {
  final String message;
  ExpenseDetailError(this.message);
}
