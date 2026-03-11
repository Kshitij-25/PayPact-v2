import 'package:dartz/dartz.dart';
import 'package:paypact/core/failures/faliures.dart';
import 'package:paypact/core/services/expense_split_service.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:uuid/uuid.dart';

class CreateExpenseParams {
  const CreateExpenseParams({
    required this.groupId,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.splitType,
    required this.memberIds,
    required this.createdBy,
    this.description,
    this.category = ExpenseCategory.other,
    this.currency = 'USD',
    this.exactAmounts,
    this.percentages,
    this.shares,
  });

  final String groupId;
  final String title;
  final double amount;
  final Map<String, double> paidBy;
  final SplitType splitType;
  final List<String> memberIds;
  final String createdBy;
  final String? description;
  final ExpenseCategory category;
  final String currency;
  final Map<String, double>? exactAmounts;
  final Map<String, double>? percentages;
  final Map<String, int>? shares;
}

class CreateExpenseUseCase {
  const CreateExpenseUseCase(this._repository, this._splitService);

  final ExpenseRepository _repository;
  final ExpenseSplitService _splitService;

  Future<Either<Failure, ExpenseEntity>> call(CreateExpenseParams params) {
    final splits = _splitService.computeSplits(
      splitType: params.splitType,
      totalAmount: params.amount,
      memberIds: params.memberIds,
      exactAmounts: params.exactAmounts,
      percentages: params.percentages,
      shares: params.shares,
    );

    final expense = ExpenseEntity(
      id: const Uuid().v4(),
      groupId: params.groupId,
      title: params.title,
      amount: params.amount,
      paidBy: params.paidBy,
      splits: splits,
      createdAt: DateTime.now(),
      createdBy: params.createdBy,
      description: params.description,
      category: params.category,
      splitType: params.splitType,
      currency: params.currency,
    );

    return _repository.createExpense(expense);
  }
}
