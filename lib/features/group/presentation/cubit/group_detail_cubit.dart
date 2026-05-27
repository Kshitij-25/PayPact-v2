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

  StreamSubscription<GroupEntity?>? _groupSub;
  StreamSubscription<List<ExpenseEntity>>? _expenseSub;

  GroupEntity? _latestGroup;
  List<ExpenseEntity> _latestExpenses = [];

  GroupDetailCubit(
      this._groupRepo, this._expenseRepo, this._groupId, this._currentUserId)
      : super(GroupDetailInitial());

  void load() {
    emit(GroupDetailLoading());

    _groupSub = _groupRepo.watchGroup(_groupId).listen(
      (group) {
        if (group == null) {
          emit(GroupDetailError('Group not found'));
          return;
        }
        _latestGroup = group;
        _emitLoaded();
      },
      onError: (e) => emit(GroupDetailError(e.toString())),
    );

    _expenseSub = _expenseRepo.watchGroupExpenses(_groupId).listen(
      (expenses) {
        _latestExpenses = expenses;
        _emitLoaded();
      },
      onError: (e) => emit(GroupDetailError(e.toString())),
    );
  }

  Future<void> _emitLoaded() async {
    final group = _latestGroup;
    if (group == null) return;

    final settlements = await _expenseRepo.getGroupSettlements(_groupId);
    final netBalance = _myBalance(_latestExpenses, settlements, _currentUserId);
    final memberBalances =
        _memberBalances(_latestExpenses, settlements, group);

    emit(GroupDetailLoaded(
      group: group,
      expenses: _latestExpenses,
      netBalance: netBalance,
      memberBalances: memberBalances,
    ));
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
        for (final split in e.splits) {
          if (split.userId != _currentUserId) {
            bal[split.userId] = (bal[split.userId] ?? 0) + split.amount;
          }
        }
      } else {
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
    _groupSub?.cancel();
    _expenseSub?.cancel();
    return super.close();
  }
}
