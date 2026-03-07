import 'package:dartz/dartz.dart';
import 'package:paypact/core/failures/faliures.dart';
import 'package:paypact/domain/entities/debt_entity.dart';
import 'package:paypact/domain/repositories/expense_repository.dart';

class GetSimplifiedDebtsUseCase {
  const GetSimplifiedDebtsUseCase(this._repository);
  final ExpenseRepository _repository;
  Future<Either<Failure, List<DebtEntity>>> call(String groupId) =>
      _repository.getSimplifiedDebts(groupId);
}
