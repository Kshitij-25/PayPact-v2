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
      double exchangeRate = 1.0;
      double baseAmount = amount;

      if (originalCurrency != groupCurrency) {
        exchangeRate =
            await _rateService.getRate(originalCurrency, groupCurrency);
        baseAmount = amount * exchangeRate;
      }

      final baseSplits = splits
          .map((s) => ExpenseSplitEntity(
                userId: s.userId,
                userName: s.userName,
                amount:
                    double.parse((s.amount * exchangeRate).toStringAsFixed(2)),
              ))
          .toList();

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
}
