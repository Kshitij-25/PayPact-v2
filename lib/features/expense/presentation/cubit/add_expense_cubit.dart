import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/core/services/exchange_rate_service.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/entities/expense_extras.dart';
import 'package:paypact/features/expense/domain/expense_changes.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/expense/domain/split_allocator.dart';
import 'package:paypact/features/notification/domain/repositories/notifications_repository.dart';

part 'add_expense_state.dart';

class AddExpenseCubit extends Cubit<AddExpenseState> {
  final ExpenseRepository _repo;
  final NotificationsRepository _notifRepo;
  final ExchangeRateService _rateService;

  AddExpenseCubit(this._repo, this._notifRepo, this._rateService)
      : super(AddExpenseInitial());

  Future<void> saveExpense({
    required String groupId,
    required String groupCurrency,
    String groupName = '',
    required String title,
    required double amount,
    required String originalCurrency,
    required String category,
    required String paidById,
    required String paidByName,
    required List<ExpenseSplitEntity> splits,
    required String currentUserId,
    DateTime? date,
    String? note,
    String? receiptUrl,
    RecurrenceInterval? repeat,
  }) async {
    if (title.trim().isEmpty) {
      emit(AddExpenseError('Please enter a description'));
      return;
    }
    if (amount <= 0) {
      emit(AddExpenseError('Amount must be greater than zero'));
      return;
    }
    emit(AddExpenseLoading());
    try {
      final exchangeRate =
          await _resolveRate(originalCurrency, groupCurrency, null);
      final baseMinor = toMinor(amount * exchangeRate);
      final baseAmount = fromMinor(baseMinor);
      final baseSplits = _toBaseSplits(splits, baseMinor);
      final spentOn = date ?? DateTime.now();

      await _repo.createExpense(
        groupId: groupId,
        title: title.trim(),
        amount: baseAmount,
        originalAmount: amount,
        originalCurrency: originalCurrency,
        exchangeRate: exchangeRate,
        category: category,
        paidById: paidById,
        paidByName: paidByName,
        splits: baseSplits,
        createdById: currentUserId,
        date: spentOn,
        note: note,
        receiptUrl: receiptUrl,
      );

      // "Repeat": the expense above is the first occurrence; the template makes
      // a daily job create the following ones.
      if (repeat != null) {
        await _repo.createRecurring(RecurringExpense(
          id: '',
          groupId: groupId,
          title: title.trim(),
          amount: baseAmount,
          originalAmount: amount,
          originalCurrency: originalCurrency,
          exchangeRate: exchangeRate,
          category: category,
          paidById: paidById,
          paidByName: paidByName,
          splits: baseSplits,
          interval: repeat,
          nextRunAt: nextRecurrence(spentOn, repeat),
          active: true,
          createdById: currentUserId,
          createdByName: paidById == currentUserId ? paidByName : '',
          note: note,
        ));
      }

      final others = splits.where((s) => s.userId != currentUserId).toList();
      await Future.wait(others.map((s) => _notifRepo.push(
            targetUserId: s.userId,
            type: 'expense_added',
            title: '$paidByName added an expense',
            body:
                '"${title.trim()}" · ${originalCurrency != groupCurrency ? '$originalCurrency $amount → ' : ''}$groupCurrency ${baseAmount.toStringAsFixed(0)}',
            groupId: groupId,
            actorId: currentUserId,
            actorName: paidByName,
          )));

      emit(AddExpenseSuccess());
    } catch (e) {
      emit(AddExpenseError(e.toString()));
    }
  }

  /// Saves edits to [existing]. If the currency is unchanged the originally
  /// recorded exchange rate is kept, so editing a title doesn't silently
  /// revalue a historical foreign-currency expense.
  Future<void> updateExpense({
    required ExpenseEntity existing,
    required String groupCurrency,
    required String groupName,
    required String title,
    required double amount,
    required String originalCurrency,
    required String category,
    required String paidById,
    required String paidByName,
    required List<ExpenseSplitEntity> splits,
    required String currentUserId,
    required String currentUserName,
    DateTime? date,
    String? note,
    String? receiptUrl,
  }) async {
    if (title.trim().isEmpty) {
      emit(AddExpenseError('Please enter a description'));
      return;
    }
    if (amount <= 0) {
      emit(AddExpenseError('Amount must be greater than zero'));
      return;
    }
    emit(AddExpenseLoading());
    try {
      final exchangeRate =
          await _resolveRate(originalCurrency, groupCurrency, existing);
      final baseMinor = toMinor(amount * exchangeRate);
      final baseAmount = fromMinor(baseMinor);
      final baseSplits = _toBaseSplits(splits, baseMinor);
      final cleanNote = note?.trim().isEmpty ?? true ? null : note!.trim();

      await _repo.updateExpense(
        groupId: existing.groupId,
        expenseId: existing.id,
        title: title.trim(),
        amount: baseAmount,
        originalAmount: amount,
        originalCurrency: originalCurrency,
        exchangeRate: exchangeRate,
        category: category,
        paidById: paidById,
        paidByName: paidByName,
        splits: baseSplits,
        date: date ?? existing.date,
        note: cleanNote,
        receiptUrl: receiptUrl,
      );

      // Edit log: what changed, and who changed it.
      final after = ExpenseEntity(
        id: existing.id,
        groupId: existing.groupId,
        title: title.trim(),
        amount: baseAmount,
        originalAmount: amount,
        originalCurrency: originalCurrency,
        exchangeRate: exchangeRate,
        category: category,
        paidById: paidById,
        paidByName: paidByName,
        splits: baseSplits,
        createdAt: existing.createdAt,
        createdById: existing.createdById,
        date: date ?? existing.date,
        note: cleanNote,
        receiptUrl: receiptUrl,
      );
      final changes =
          describeExpenseChanges(existing, after, groupCurrency: groupCurrency);
      if (changes.isNotEmpty) {
        await _repo.addHistory(existing.groupId, existing.id,
            by: currentUserId, byName: currentUserName, changes: changes);
      }

      // Notify everyone involved before or after the edit, except the editor.
      final affected = <String>{
        ...existing.splits.map((s) => s.userId),
        ...splits.map((s) => s.userId),
      }..remove(currentUserId);
      await Future.wait(affected.map((id) => _notifRepo.push(
            targetUserId: id,
            type: 'expense_updated',
            title: '$currentUserName edited an expense',
            body: '"${title.trim()}" in $groupName was updated.',
            groupId: existing.groupId,
            groupName: groupName,
            actorId: currentUserId,
            actorName: currentUserName,
          )));

      emit(AddExpenseSuccess());
    } catch (e) {
      emit(AddExpenseError(e.toString()));
    }
  }

  Future<double> _resolveRate(
      String from, String to, ExpenseEntity? existing) async {
    if (from == to) return 1.0;
    if (existing != null && existing.originalCurrency == from) {
      return existing.exchangeRate;
    }
    return _rateService.getRate(from, to);
  }

  /// Converts the shares to the group currency so they total [baseMinor]
  /// *exactly* (rounding each share on its own would drift by a paisa or two).
  List<ExpenseSplitEntity> _toBaseSplits(
      List<ExpenseSplitEntity> splits, int baseMinor) {
    final minors = rescaleShares([for (final s in splits) s.amount], baseMinor);
    return [
      for (var i = 0; i < splits.length; i++)
        ExpenseSplitEntity(
          userId: splits[i].userId,
          userName: splits[i].userName,
          amount: fromMinor(minors[i]),
        ),
    ];
  }
}
