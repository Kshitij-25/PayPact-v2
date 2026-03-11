part of 'expense_bloc.dart';

enum ExpenseStatus { initial, loading, success, failure }

class ExpenseState extends Equatable {
  const ExpenseState({
    this.status = ExpenseStatus.initial,
    this.expenses = const [],
    this.settlements = const [],
    this.activityExpenses = const [],
    this.activitySettlements = const [],
    this.simplifiedDebts = const [],
    this.errorMessage,
  });

  final ExpenseStatus status;
  final List<ExpenseEntity> expenses;
  final List<SettlementEntity> settlements;
  final List<ExpenseEntity> activityExpenses;
  final List<SettlementEntity> activitySettlements;
  final List<DebtEntity> simplifiedDebts;
  final String? errorMessage;

  double get totalAmount => expenses.fold(0.0, (sum, e) => sum + e.amount);

  ExpenseState copyWith({
    ExpenseStatus? status,
    List<ExpenseEntity>? expenses,
    List<SettlementEntity>? settlements,
    List<ExpenseEntity>? activityExpenses,
    List<SettlementEntity>? activitySettlements,
    List<DebtEntity>? simplifiedDebts,
    String? errorMessage,
  }) =>
      ExpenseState(
        status: status ?? this.status,
        expenses: expenses ?? this.expenses,
        settlements: settlements ?? this.settlements,
        activityExpenses: activityExpenses ?? this.activityExpenses,
        activitySettlements: activitySettlements ?? this.activitySettlements,
        simplifiedDebts: simplifiedDebts ?? this.simplifiedDebts,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [
        status,
        expenses,
        settlements,
        activityExpenses,
        activitySettlements,
        simplifiedDebts,
        errorMessage,
      ];
}
