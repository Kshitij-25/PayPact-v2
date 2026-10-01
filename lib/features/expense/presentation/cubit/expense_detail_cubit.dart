import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/services/nudge_service.dart';
import 'package:paypact/core/utils/currency_utils.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/features/notification/domain/repositories/notifications_repository.dart';

part 'expense_detail_state.dart';

class ExpenseDetailCubit extends Cubit<ExpenseDetailState> {
  final ExpenseRepository _expenseRepo;
  final NotificationsRepository _notifRepo;
  final GroupRepository _groupRepo;
  final String _groupId;
  final String _expenseId;
  final String _currentUserId;

  ExpenseDetailCubit(
    this._expenseRepo,
    this._notifRepo,
    this._groupRepo,
    this._groupId,
    this._expenseId,
    this._currentUserId,
  ) : super(ExpenseDetailInitial());

  Future<void> load() async {
    try {
      emit(ExpenseDetailLoading());
      final expense = await _expenseRepo.getExpense(_groupId, _expenseId);
      if (expense == null) {
        emit(ExpenseDetailError('Expense not found'));
        return;
      }
      // The group's currency is the unit of every amount on this screen.
      String currency = kDefaultCurrency;
      String groupName = '';
      CustomCategory? custom;
      var remindable = expense.splits
          .where((s) => s.userId != expense.paidById)
          .toList();
      try {
        final group = await _groupRepo.getGroup(_groupId);
        if (group != null) {
          currency = group.currency;
          groupName = group.name;
          custom = group.customCategories
              .where((c) => c.id == expense.category)
              .firstOrNull;
          // Only people who actually still owe something need a reminder.
          if (group.hasSummary) {
            remindable = remindable
                .where((s) => (group.balances![s.userId] ?? 0) < 0)
                .toList();
          }
        }
      } catch (_) {}
      emit(ExpenseDetailLoaded(
        expense: expense,
        currentUserId: _currentUserId,
        currency: currency,
        groupName: groupName,
        customCategoryName: custom?.name,
        customCategoryEmoji: custom?.emoji,
        remindable: remindable,
      ));
    } catch (e) {
      emit(ExpenseDetailError(e.toString()));
    }
  }

  /// Deletes the expense and returns it so the caller can offer "Undo".
  Future<ExpenseEntity?> delete({
    required String actorName,
    String? groupName,
  }) async {
    final current = state;
    final expense =
        current is ExpenseDetailLoaded ? current.expense : null;
    groupName ??= current is ExpenseDetailLoaded ? current.groupName : null;

    await _expenseRepo.deleteExpense(_groupId, _expenseId);

    if (expense != null) {
      final others =
          expense.splits.where((s) => s.userId != _currentUserId).toList();
      await Future.wait(others.map((s) => _notifRepo.push(
            targetUserId: s.userId,
            type: 'expense_deleted',
            title: '$actorName deleted an expense',
            body: '"${expense.title}" has been removed'
                '${groupName != null ? ' from $groupName' : ''}.',
            groupId: _groupId,
            groupName: groupName,
            actorId: _currentUserId,
            actorName: actorName,
          )));
    }
    return expense;
  }

  /// Reminds everyone in [ExpenseDetailLoaded.remindable] who hasn't been
  /// reminded in the last day. Returns how many reminders went out.
  Future<int> remind({required String actorName}) async {
    final current = state;
    if (current is! ExpenseDetailLoaded) return 0;
    final nudges = locator<NudgeService>();
    var sent = 0;
    for (final s in current.remindable) {
      if (!nudges.canRemind(_currentUserId, current.expense.id, s.userId)) {
        continue;
      }
      await nudges.remindAbout(
        expenseId: current.expense.id,
        expenseTitle: current.expense.title,
        groupId: _groupId,
        groupName: current.groupName,
        currency: current.currency,
        amountOwed: s.amount,
        targetId: s.userId,
        actorId: _currentUserId,
        actorName: actorName,
      );
      sent++;
    }
    return sent;
  }

  /// A copy of this expense dated today (receipt not copied).
  Future<void> duplicate({required String actorName}) async {
    final current = state;
    if (current is! ExpenseDetailLoaded) return;
    final e = current.expense;
    await _expenseRepo.createExpense(
      groupId: _groupId,
      title: e.title,
      amount: e.amount,
      originalAmount: e.originalAmount,
      originalCurrency: e.originalCurrency,
      exchangeRate: e.exchangeRate,
      category: e.category,
      paidById: e.paidById,
      paidByName: e.paidByName,
      splits: e.splits,
      createdById: _currentUserId,
      date: DateTime.now(),
      note: e.note,
    );
  }
}

/// Puts a just-deleted expense back (the "Undo" on the delete snackbar) and
/// lets the others know it's back.
Future<void> restoreDeletedExpense({
  required ExpenseRepository expenses,
  required NotificationsRepository notifications,
  required ExpenseEntity expense,
  required String actorId,
  required String actorName,
  String? groupName,
}) async {
  await expenses.restoreExpense(expense, restoredById: actorId);
  final others =
      expense.splits.where((s) => s.userId != actorId).toList();
  await Future.wait(others.map((s) => notifications.push(
        targetUserId: s.userId,
        type: 'expense_added',
        title: '$actorName restored an expense',
        body: '"${expense.title}" is back${groupName != null ? ' in $groupName' : ''}.',
        groupId: expense.groupId,
        groupName: groupName,
        actorId: actorId,
        actorName: actorName,
      )));
}
