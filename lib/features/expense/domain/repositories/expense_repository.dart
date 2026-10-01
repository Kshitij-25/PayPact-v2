import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/entities/expense_extras.dart';
import 'package:paypact/features/settle/domain/settlement_entity.dart';

abstract class ExpenseRepository {
  /// Newest first. [limit] bounds how many are loaded; the group screen
  /// raises it as the user scrolls ("load more").
  Stream<List<ExpenseEntity>> watchGroupExpenses(String groupId, {int? limit});

  /// Newest first. Pass [since] / [limit] whenever the caller doesn't need the
  /// whole history — most screens don't.
  Future<List<ExpenseEntity>> getGroupExpenses(String groupId,
      {DateTime? since, int? limit});
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
    DateTime? date,
    String? note,
    String? receiptUrl,
  });

  /// Overwrites the editable fields of an existing expense. The original
  /// `createdAt` / `createdById` are preserved.
  Future<void> updateExpense({
    required String groupId,
    required String expenseId,
    required String title,
    required double amount,
    required double originalAmount,
    required String originalCurrency,
    required double exchangeRate,
    required String category,
    required String paidById,
    required String paidByName,
    required List<ExpenseSplitEntity> splits,
    DateTime? date,
    String? note,
    String? receiptUrl,
  });
  Future<void> deleteExpense(String groupId, String expenseId);

  /// Puts back an expense that was just deleted (same id, original dates).
  Future<void> restoreExpense(ExpenseEntity expense,
      {required String restoredById});

  // ── Discussion & history ──────────────────────────────────────────────────
  Stream<List<ExpenseComment>> watchComments(String groupId, String expenseId);
  Future<void> addComment(String groupId, String expenseId,
      {required String authorId,
      required String authorName,
      required String text});
  Future<void> deleteComment(
      String groupId, String expenseId, String commentId);
  Stream<List<ExpenseHistoryEntry>> watchHistory(
      String groupId, String expenseId);
  Future<void> addHistory(String groupId, String expenseId,
      {required String by,
      required String byName,
      required List<String> changes});

  // ── Recurring expenses ────────────────────────────────────────────────────
  Stream<List<RecurringExpense>> watchRecurring(String groupId);
  Future<void> createRecurring(RecurringExpense template);
  Future<void> setRecurringActive(
      String groupId, String recurringId, bool active);
  Future<void> deleteRecurring(String groupId, String recurringId);
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
    String type,
    String? reversesId,
  });
  Future<List<Map<String, dynamic>>> getGroupSettlements(String groupId,
      {DateTime? since, int? limit});
}
