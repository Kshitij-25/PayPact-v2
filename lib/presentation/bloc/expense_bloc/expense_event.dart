part of 'expense_bloc.dart';

abstract class ExpenseEvent {}

class ExpenseLoadRequested extends ExpenseEvent {
  ExpenseLoadRequested(this.groupId);
  final String groupId;
}

class ExpenseCreateRequested extends ExpenseEvent {
  ExpenseCreateRequested(this.params);
  final CreateExpenseParams params;
}

class ExpenseDeleteRequested extends ExpenseEvent {
  ExpenseDeleteRequested(this.expenseId);
  final String expenseId;
}

class ExpenseDebtsRequested extends ExpenseEvent {
  ExpenseDebtsRequested(this.groupId);
  final String groupId;
}

class ActivityLoadRequested extends ExpenseEvent {
  ActivityLoadRequested(this.groupIds);
  final List<String> groupIds;
}

class ExpenseSettlementRequested extends ExpenseEvent {
  ExpenseSettlementRequested(this.params);
  final RecordSettlementParams params;
}

class _ExpenseListUpdated extends ExpenseEvent {
  _ExpenseListUpdated(this.expenses);
  final List<ExpenseEntity> expenses;
}

class _SettlementListUpdated extends ExpenseEvent {
  _SettlementListUpdated(this.settlements);
  final List<SettlementEntity> settlements;
}

class _ActivityExpensesUpdated extends ExpenseEvent {
  _ActivityExpensesUpdated(this.expenses);
  final List<ExpenseEntity> expenses;
}

class _ActivitySettlementsUpdated extends ExpenseEvent {
  _ActivitySettlementsUpdated(this.settlements);
  final List<SettlementEntity> settlements;
}
