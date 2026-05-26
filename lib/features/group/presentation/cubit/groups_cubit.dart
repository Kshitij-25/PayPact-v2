import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';

part 'groups_state.dart';

class GroupsCubit extends Cubit<GroupsState> {
  final GroupRepository _groupRepo;
  final ExpenseRepository _expenseRepo;
  final String _userId;
  StreamSubscription<List<GroupEntity>>? _sub;

  GroupsCubit(this._groupRepo, this._expenseRepo, this._userId)
      : super(GroupsInitial());

  void loadGroups() {
    emit(GroupsLoading());
    _sub = _groupRepo.watchUserGroups(_userId).listen(
      (groups) async {
        for (final group in groups) {
          final expenses = await _expenseRepo.getGroupExpenses(group.id);
          final settlements =
              await _expenseRepo.getGroupSettlements(group.id);
          group.netBalance =
              _computeBalance(expenses, settlements, _userId);
        }
        final total = groups.fold<double>(
            0, (sum, g) => sum + g.netBalance);
        emit(GroupsLoaded(groups: groups, totalNetBalance: total));
      },
      onError: (e) => emit(GroupsError(e.toString())),
    );
  }

  double _computeBalance(List expenses, List<Map<String, dynamic>> settlements,
      String userId) {
    double balance = 0;
    for (final e in expenses) {
      final myShare = e.splitAmountFor(userId);
      if (e.paidById == userId) {
        balance += (e.amount - myShare);
      } else {
        balance -= myShare;
      }
    }
    for (final s in settlements) {
      if (s['toUserId'] == userId) {
        balance += (s['amount'] as num).toDouble();
      } else if (s['fromUserId'] == userId) {
        balance -= (s['amount'] as num).toDouble();
      }
    }
    return balance;
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
