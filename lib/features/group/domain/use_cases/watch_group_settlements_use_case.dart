import 'package:paypact/features/expense/domain/entities/settlement_entity.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';

class WatchGroupSettlementsUseCase {
  const WatchGroupSettlementsUseCase(this._repository);
  final ExpenseRepository _repository;

  Stream<List<SettlementEntity>> call(String groupId) =>
      _repository.watchGroupSettlements(groupId);
}
