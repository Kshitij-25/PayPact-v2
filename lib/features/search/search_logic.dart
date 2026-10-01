import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';

enum SearchScope { all, groups, expenses }

class ExpenseHit {
  const ExpenseHit(this.expense, this.group);
  final ExpenseEntity expense;
  final GroupEntity group;
}

class PersonHit {
  const PersonHit(this.id, this.name, this.groups);
  final String id;
  final String name;

  /// Groups you share with them.
  final List<GroupEntity> groups;
}

class SearchResults {
  const SearchResults({
    this.groups = const [],
    this.expenses = const [],
    this.people = const [],
  });
  final List<GroupEntity> groups;
  final List<ExpenseHit> expenses;
  final List<PersonHit> people;
  bool get isEmpty => groups.isEmpty && expenses.isEmpty && people.isEmpty;
}

bool _has(String? haystack, String needle) =>
    haystack != null && haystack.toLowerCase().contains(needle);

/// Case-insensitive search over groups (name), expenses (title, note, payer,
/// category, amount) and the people you share groups with.
SearchResults searchEverything({
  required String query,
  required List<GroupEntity> groups,
  required Map<String, List<ExpenseEntity>> expensesByGroup,
  required String currentUserId,
  SearchScope scope = SearchScope.all,
  int maxExpenses = 50,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const SearchResults();

  final groupHits = scope == SearchScope.expenses
      ? <GroupEntity>[]
      : groups.where((g) => _has(g.name, q)).toList();

  final expenseHits = <ExpenseHit>[];
  if (scope != SearchScope.groups) {
    for (final g in groups) {
      for (final e in expensesByGroup[g.id] ?? const <ExpenseEntity>[]) {
        final categoryName = g.customCategories
            .where((c) => c.id == e.category)
            .map((c) => c.name)
            .firstOrNull;
        final amount = e.amount.toStringAsFixed(
            e.amount.truncateToDouble() == e.amount ? 0 : 2);
        if (_has(e.title, q) ||
            _has(e.note, q) ||
            _has(e.paidByName, q) ||
            _has(e.category, q) ||
            _has(categoryName, q) ||
            amount.contains(q)) {
          expenseHits.add(ExpenseHit(e, g));
        }
      }
    }
    expenseHits.sort((a, b) => b.expense.date.compareTo(a.expense.date));
  }

  final people = <String, PersonHit>{};
  if (scope == SearchScope.all) {
    for (final g in groups) {
      g.memberNames.forEach((id, name) {
        if (id == currentUserId || !_has(name, q)) return;
        final prev = people[id];
        people[id] = PersonHit(id, name, [...?prev?.groups, g]);
      });
    }
  }

  return SearchResults(
    groups: groupHits,
    expenses: expenseHits.take(maxExpenses).toList(),
    people: people.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
  );
}
