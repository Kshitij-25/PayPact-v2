import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/features/search/search_logic.dart';

sealed class SearchState {
  const SearchState();
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchReady extends SearchState {
  const SearchReady({
    required this.query,
    required this.results,
    required this.groups,
    this.loadingExpenses = false,
  });
  final String query;
  final SearchResults results;

  /// Every group, shown as suggestions before anything is typed.
  final List<GroupEntity> groups;

  /// Recent expenses are still being fetched; results may grow.
  final bool loadingExpenses;
}

class SearchCubit extends Cubit<SearchState> {
  SearchCubit(this._groupRepo, this._expenseRepo, this._userId, this.scope)
      : super(const SearchLoading());

  final GroupRepository _groupRepo;
  final ExpenseRepository _expenseRepo;
  final String _userId;
  final SearchScope scope;

  /// How far back we look for expenses per group — search is on demand, so
  /// this is bounded rather than downloading whole histories.
  static const expensesPerGroup = 300;

  List<GroupEntity> _groups = [];
  final Map<String, List<ExpenseEntity>> _expenses = {};
  bool _loadingExpenses = false;
  bool _expensesLoaded = false;
  String _query = '';

  Future<void> load() async {
    try {
      _groups = await _groupRepo.watchUserGroups(_userId).first;
      _emit();
    } catch (_) {
      _groups = [];
      _emit();
    }
  }

  Future<void> search(String query) async {
    _query = query;
    _emit();
    if (query.trim().length >= 2 &&
        scope != SearchScope.groups &&
        !_expensesLoaded &&
        !_loadingExpenses) {
      _loadingExpenses = true;
      _emit();
      await Future.wait(_groups.map((g) async {
        try {
          _expenses[g.id] = await _expenseRepo.getGroupExpenses(g.id,
              limit: expensesPerGroup);
        } catch (_) {
          _expenses[g.id] = const [];
        }
      }));
      _loadingExpenses = false;
      _expensesLoaded = true;
      if (!isClosed) _emit();
    }
  }

  void _emit() {
    if (isClosed) return;
    emit(SearchReady(
      query: _query,
      results: searchEverything(
        query: _query,
        groups: _groups,
        expensesByGroup: _expenses,
        currentUserId: _userId,
        scope: scope,
      ),
      groups: _groups,
      loadingExpenses: _loadingExpenses,
    ));
  }
}
