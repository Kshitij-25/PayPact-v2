import 'package:paypact/domain/entities/expense_entity.dart';
import 'package:paypact/domain/entities/settlement_entity.dart';
import 'package:paypact/domain/repositories/expense_repository.dart';

class WatchUserActivityUseCase {
  const WatchUserActivityUseCase(this._repository);
  final ExpenseRepository _repository;

  Stream<List<ExpenseEntity>> expenses(List<String> groupIds) =>
      _repository.watchUserExpenses(groupIds);

  Stream<List<SettlementEntity>> settlements(List<String> groupIds) =>
      _repository.watchUserSettlements(groupIds);
}
