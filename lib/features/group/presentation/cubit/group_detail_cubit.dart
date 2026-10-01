import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/group/data/summary_service.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/features/settle/domain/debt_simplifier.dart';

part 'group_detail_state.dart';

class GroupDetailCubit extends Cubit<GroupDetailState> {
  final GroupRepository _groupRepo;
  final ExpenseRepository _expenseRepo;
  final String _groupId;
  final String _currentUserId;

  /// Expenses shown per page; "load more" raises the live query's limit.
  static const pageSize = 50;

  StreamSubscription<GroupEntity?>? _groupSub;
  StreamSubscription<List<ExpenseEntity>>? _expenseSub;

  GroupEntity? _latestGroup;
  List<ExpenseEntity> _latestExpenses = [];
  bool _expensesReady = false;
  int _limit = pageSize;
  // Groups that predate summaries need the whole history for balances.
  bool _watchingAll = false;

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
        final first = _latestGroup == null;
        _latestGroup = group;
        if (first) {
          _watchExpenses(all: !group.hasSummary);
          if (!group.hasSummary) _ensureSummary();
        } else if (group.hasSummary && _watchingAll) {
          // The backend finished building the summary: stop reading everything.
          _watchExpenses(all: false);
        }
        if (_expensesReady) _emitLoaded();
      },
      onError: (e) => emit(GroupDetailError(e.toString())),
    );
  }

  void _ensureSummary() {
    try {
      locator<SummaryService>().ensure(_groupId);
    } catch (_) {}
  }

  void _watchExpenses({required bool all}) {
    _expenseSub?.cancel();
    _watchingAll = all;
    _expenseSub = _expenseRepo
        .watchGroupExpenses(_groupId, limit: all ? null : _limit)
        .listen(
      (expenses) {
        _latestExpenses = expenses;
        _expensesReady = true;
        _emitLoaded();
      },
      onError: (e) => emit(GroupDetailError(e.toString())),
    );
  }

  /// Shows the next page of older expenses.
  void loadMore() {
    final group = _latestGroup;
    if (group == null || _watchingAll || !canLoadMore) return;
    _limit += pageSize;
    _watchExpenses(all: false);
  }

  /// More expenses exist beyond what's loaded (the last page came back full).
  bool get canLoadMore => !_watchingAll && _latestExpenses.length >= _limit;

  Future<void> _emitLoaded() async {
    final group = _latestGroup;
    if (group == null) return;

    final settlements = _watchingAll
        ? await _expenseRepo.getGroupSettlements(_groupId)
        : await _expenseRepo.getGroupSettlements(_groupId, limit: 100);

    // Newest *spent-on* date first (the query is ordered by entry time).
    final expenses = List<ExpenseEntity>.of(_latestExpenses)
      ..sort((a, b) => b.date.compareTo(a.date));

    final Map<String, double> globalBalances;
    final double netBalance;
    final Map<String, double> memberBalances;
    if (group.hasSummary) {
      // Balances come from the server summary — correct however many expenses
      // are currently loaded.
      globalBalances = {
        for (final id in group.memberIds) id: group.balanceOf(id) ?? 0,
      };
      netBalance = globalBalances[_currentUserId] ?? 0;
      memberBalances = _planAgainstMe(group, globalBalances);
    } else {
      netBalance = _myBalance(expenses, settlements, _currentUserId);
      memberBalances = _memberBalances(expenses, settlements, group);
      globalBalances = _globalMemberBalances(expenses, settlements, group);
    }

    emit(GroupDetailLoaded(
      group: group,
      expenses: expenses,
      netBalance: netBalance,
      memberBalances: memberBalances,
      globalMemberBalances: globalBalances,
      settlements: settlements,
      canLoadMore: canLoadMore,
    ));
  }

  /// Who owes me / whom I owe, per the minimised settle-up plan
  /// (+ = they owe me, − = I owe them).
  Map<String, double> _planAgainstMe(
      GroupEntity group, Map<String, double> balances) {
    final out = {
      for (final id in group.memberIds)
        if (id != _currentUserId) id: 0.0,
    };
    final debts = simplifyDebtsFromBalances(
        balances, Map<String, String>.from(group.memberNames));
    for (final d in debts) {
      if (d.toUserId == _currentUserId) out[d.fromUserId] = d.amount;
      if (d.fromUserId == _currentUserId) out[d.toUserId] = -d.amount;
    }
    return out;
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
      if (s['fromUserId'] == userId) {
        balance += (s['amount'] as num).toDouble();
      } else if (s['toUserId'] == userId) {
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

  /// Net balance per member, in the group's base currency. Delegates to the
  /// decimal-safe [computeNetBalances] (integer paise) so this matches exactly
  /// what the debt simplifier settles, then converts back to rupees for display.
  Map<String, double> _globalMemberBalances(List<ExpenseEntity> expenses,
      List<Map<String, dynamic>> settlements, GroupEntity group) {
    final paise = computeNetBalances(
      expenses: expenses,
      settlements: settlements,
      memberIds: group.memberIds,
    );
    return {for (final e in paise.entries) e.key: fromPaise(e.value)};
  }

  @override
  Future<void> close() {
    _groupSub?.cancel();
    _expenseSub?.cancel();
    return super.close();
  }
}
