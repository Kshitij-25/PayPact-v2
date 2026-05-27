import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';

part 'expense_detail_state.dart';

class ExpenseDetailCubit extends Cubit<ExpenseDetailState> {
  final ExpenseRepository _expenseRepo;
  final String _groupId;
  final String _expenseId;
  final String _currentUserId;

  ExpenseDetailCubit(
    this._expenseRepo,
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

  Future<void> delete() async {
    await _expenseRepo.deleteExpense(_groupId, _expenseId);
  }
}
