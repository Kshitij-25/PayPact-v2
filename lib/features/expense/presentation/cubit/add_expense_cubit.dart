import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/core/services/exchange_rate_service.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
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
    required String title,
    required double amount,
    required String originalCurrency,
    required String category,
    required String paidById,
    required String paidByName,
    required List<ExpenseSplitEntity> splits,
    required String currentUserId,
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
      final baseAmount = amount * exchangeRate;
      final baseSplits = _toBaseSplits(splits, exchangeRate);

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
      );

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
      final baseAmount = amount * exchangeRate;
      final baseSplits = _toBaseSplits(splits, exchangeRate);

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
      );

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

  List<ExpenseSplitEntity> _toBaseSplits(
          List<ExpenseSplitEntity> splits, double rate) =>
      splits
          .map((s) => ExpenseSplitEntity(
                userId: s.userId,
                userName: s.userName,
                amount: double.parse((s.amount * rate).toStringAsFixed(2)),
              ))
          .toList();
}
