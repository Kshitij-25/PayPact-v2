import 'package:dartz/dartz.dart';
import 'package:paypact/core/failures/faliures.dart';
import 'package:paypact/domain/repositories/expense_repository.dart';

class DeleteExpenseUseCase {
  const DeleteExpenseUseCase(this._repository);
  final ExpenseRepository _repository;
  Future<Either<Failure, Unit>> call(String expenseId) =>
      _repository.deleteExpense(expenseId);
}
