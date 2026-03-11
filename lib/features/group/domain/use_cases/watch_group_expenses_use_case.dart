import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';

class WatchGroupExpensesUseCase {
  const WatchGroupExpensesUseCase(this._repository);
  final ExpenseRepository _repository;
  Stream<List<ExpenseEntity>> call(String groupId) =>
      _repository.watchGroupExpenses(groupId);
}
