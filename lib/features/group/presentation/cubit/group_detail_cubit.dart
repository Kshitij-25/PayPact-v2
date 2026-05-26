import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';

part 'group_detail_state.dart';

class GroupDetailCubit extends Cubit<GroupDetailState> {
  final GroupRepository _groupRepo;
  final ExpenseRepository _expenseRepo;
  final String _groupId;
  final String _currentUserId;
  StreamSubscription<List<ExpenseEntity>>? _sub;

  GroupDetailCubit(
      this._groupRepo, this._expenseRepo, this._groupId, this._currentUserId)
      : super(GroupDetailInitial());

  void load() async {
    emit(GroupDetailLoading());
    try {
      final group = await _groupRepo.getGroup(_groupId);
      if (group == null) {
        emit(GroupDetailError('Group not found'));
        return;
      }
      _sub = _expenseRepo.watchGroupExpenses(_groupId).listen(
        (expenses) async {
          final settlements =
              await _expenseRepo.getGroupSettlements(_groupId);
          final netBalance =
              _myBalance(expenses, settlements, _currentUserId);
          final memberBalances =
              _memberBalances(expenses, settlements, group);
          emit(GroupDetailLoaded(
            group: group,
            expenses: expenses,
            netBalance: netBalance,
            memberBalances: memberBalances,
          ));
        },
        onError: (e) => emit(GroupDetailError(e.toString())),
      );
    } catch (e) {
      emit(GroupDetailError(e.toString()));
    }
  }

  double _myBalance(List<ExpenseEntity> expenses,
      List<Map<String, dynamic>> settlements, String userId) {
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

  // Returns balance from _currentUserId's perspective per other member.
  // Positive = that member owes currentUser. Negative = currentUser owes them.
  Map<String, double> _memberBalances(List<ExpenseEntity> expenses,
      List<Map<String, dynamic>> settlements, GroupEntity group) {
    final Map<String, double> bal = {};
    for (final memberId in group.memberIds) {
      if (memberId == _currentUserId) continue;
      bal[memberId] = 0;
    }

    for (final e in expenses) {
      final myShare = e.splitAmountFor(_currentUserId);
      if (e.paidById == _currentUserId) {
        // Others owe me their share
        for (final split in e.splits) {
          if (split.userId != _currentUserId) {
            bal[split.userId] = (bal[split.userId] ?? 0) + split.amount;
          }
        }
      } else {
        // I owe the payer my share
        if (bal.containsKey(e.paidById)) {
          bal[e.paidById] = (bal[e.paidById] ?? 0) - myShare;
        }
      }
    }

    for (final s in settlements) {
      final from = s['fromUserId'] as String;
      final to = s['toUserId'] as String;
      final amount = (s['amount'] as num).toDouble();
      if (from == _currentUserId && bal.containsKey(to)) {
        bal[to] = (bal[to] ?? 0) + amount;
      } else if (to == _currentUserId && bal.containsKey(from)) {
        bal[from] = (bal[from] ?? 0) - amount;
      }
    }

    return bal;
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
