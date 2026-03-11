import 'package:dartz/dartz.dart';
import 'package:paypact/core/failures/faliures.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/entities/settlement_entity.dart';
import 'package:paypact/features/group/domain/entities/debt_entity.dart';

abstract class ExpenseRepository {
  Stream<List<ExpenseEntity>> watchGroupExpenses(String groupId);

  /// Streams recent expenses across multiple groups (for activity feed).
  Stream<List<ExpenseEntity>> watchUserExpenses(List<String> groupIds);

  /// Streams recent settlements across multiple groups (for activity feed).
  Stream<List<SettlementEntity>> watchUserSettlements(List<String> groupIds);

  Future<Either<Failure, ExpenseEntity>> getExpenseById(String expenseId);

  Future<Either<Failure, ExpenseEntity>> createExpense(ExpenseEntity expense);

  Future<Either<Failure, ExpenseEntity>> updateExpense(ExpenseEntity expense);

  Future<Either<Failure, Unit>> deleteExpense(String expenseId);

  Future<Either<Failure, List<ExpenseEntity>>> getExpensesByUser(
    String groupId,
    String userId,
  );

  Future<Either<Failure, SettlementEntity>> recordSettlement(
      SettlementEntity settlement);

  Stream<List<SettlementEntity>> watchGroupSettlements(String groupId);

  Future<Either<Failure, List<DebtEntity>>> getSimplifiedDebts(String groupId);

  Future<Either<Failure, Map<String, double>>> getUserBalances(String groupId);
}
