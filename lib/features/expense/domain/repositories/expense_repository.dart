import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/settle/domain/settlement_entity.dart';

abstract class ExpenseRepository {
  Stream<List<ExpenseEntity>> watchGroupExpenses(String groupId);
  Future<List<ExpenseEntity>> getGroupExpenses(String groupId);
  Future<ExpenseEntity?> getExpense(String groupId, String expenseId);
  Future<ExpenseEntity> createExpense({
    required String groupId,
    required String title,
    required double amount,
    required double originalAmount,
    required String originalCurrency,
    required double exchangeRate,
    required String category,
    required String paidById,
    required String paidByName,
    required List<ExpenseSplitEntity> splits,
    required String createdById,
  });
  Future<void> deleteExpense(String groupId, String expenseId);
  /// Records a settle-up payment. Idempotent: re-invoking with the same
  /// [idempotencyKey] returns the already-recorded settlement instead of
  /// creating a duplicate. Returns the persisted entity (including its receipt).
  Future<SettlementEntity> recordSettlement({
    required String groupId,
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    required String toUserName,
    required int amountPaise,
    required String currency,
    required String createdById,
    required String idempotencyKey,
    required String receiptId,
    String paymentMethod,
    String status,
    String? note,
    String? provider,
  });
  Future<List<Map<String, dynamic>>> getGroupSettlements(String groupId);
}
