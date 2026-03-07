import 'package:paypact/domain/entities/settlement_entity.dart';
import 'package:paypact/domain/repositories/expense_repository.dart';

class WatchGroupSettlementsUseCase {
  const WatchGroupSettlementsUseCase(this._repository);
  final ExpenseRepository _repository;

  Stream<List<SettlementEntity>> call(String groupId) =>
      _repository.watchGroupSettlements(groupId);
}
