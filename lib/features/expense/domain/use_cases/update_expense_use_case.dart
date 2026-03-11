import 'package:dartz/dartz.dart';
import 'package:paypact/core/failures/faliures.dart';
import 'package:paypact/core/services/expense_split_service.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';

class UpdateExpenseParams {
  const UpdateExpenseParams({
    required this.expense,
    required this.splitType,
    required this.memberIds,
    this.exactAmounts,
    this.percentages,
    this.shares,
  });

  final ExpenseEntity expense;
  final SplitType splitType;
  final List<String> memberIds;
  final Map<String, double>? exactAmounts;
  final Map<String, double>? percentages;
  final Map<String, int>? shares;
}

class UpdateExpenseUseCase {
  const UpdateExpenseUseCase(this._repository, this._splitService);

  final ExpenseRepository _repository;
  final ExpenseSplitService _splitService;

  Future<Either<Failure, ExpenseEntity>> call(UpdateExpenseParams params) {
    final splits = _splitService.computeSplits(
      splitType: params.splitType,
      totalAmount: params.expense.amount,
      memberIds: params.memberIds,
      exactAmounts: params.exactAmounts,
      percentages: params.percentages,
      shares: params.shares,
    );

    final updated = params.expense.copyWith(
      splitType: params.splitType,
      splits: splits,
    );

    return _repository.updateExpense(updated);
  }
}
