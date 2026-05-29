import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/notification/domain/repositories/notifications_repository.dart';

part 'expense_detail_state.dart';

class ExpenseDetailCubit extends Cubit<ExpenseDetailState> {
  final ExpenseRepository _expenseRepo;
  final NotificationsRepository _notifRepo;
  final String _groupId;
  final String _expenseId;
  final String _currentUserId;

  ExpenseDetailCubit(
    this._expenseRepo,
    this._notifRepo,
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
      emit(ExpenseDetailLoaded(expense: expense, currentUserId: _currentUserId));
    } catch (e) {
      emit(ExpenseDetailError(e.toString()));
    }
  }

  Future<void> delete({
    required String actorName,
    String? groupName,
  }) async {
    final current = state;
    final expense =
        current is ExpenseDetailLoaded ? current.expense : null;

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
  }
}
