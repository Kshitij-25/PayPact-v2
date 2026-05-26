import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';

part 'add_expense_state.dart';

class AddExpenseCubit extends Cubit<AddExpenseState> {
  final ExpenseRepository _repo;

  AddExpenseCubit(this._repo) : super(AddExpenseInitial());

  Future<void> saveExpense({
    required String groupId,
    required String title,
    required double amount,
    required String category,
    required String paidById,
    required String paidByName,
    required Map<String, String> members, // userId -> userName
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
      final perPerson = amount / members.length;
      final splits = members.entries
          .map((e) => ExpenseSplitEntity(
                userId: e.key,
                userName: e.value,
                amount: double.parse(perPerson.toStringAsFixed(2)),
              ))
          .toList();

      await _repo.createExpense(
        groupId: groupId,
        title: title.trim(),
        amount: amount,
        category: category,
        paidById: paidById,
        paidByName: paidByName,
        splits: splits,
        createdById: currentUserId,
      );
      emit(AddExpenseSuccess());
    } catch (e) {
      emit(AddExpenseError(e.toString()));
    }
  }
}
