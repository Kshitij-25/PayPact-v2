import 'package:flutter_test/flutter_test.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/group/domain/group_summary.dart';

ExpenseEntity _expense({
  String id = 'e',
  double amount = 300,
  String payer = 'a',
  Map<String, double>? split,
  String title = 'Dinner',
  DateTime? createdAt,
}) {
  final shares = split ?? {'a': amount / 3, 'b': amount / 3, 'c': amount / 3};
  return ExpenseEntity(
    id: id,
    groupId: 'g',
    title: title,
    amount: amount,
    originalAmount: amount,
    originalCurrency: 'INR',
    exchangeRate: 1,
    category: 'food',
    paidById: payer,
    paidByName: payer,
    splits: [
      for (final e in shares.entries)
        ExpenseSplitEntity(userId: e.key, userName: e.key, amount: e.value),
    ],
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    createdById: payer,
    date: DateTime(2026, 1, 1),
  );
}

Map<String, int> _apply(Map<String, int> into, SummaryDelta d) {
  final out = {...into};
  for (final e in d.balances.entries) {
    out[e.key] = (out[e.key] ?? 0) + e.value;
  }
  return out;
}

void main() {
  test('an expense credits the payer and debits every split', () {
    expect(expenseContribution(_expense()), {'a': 20000, 'b': -10000, 'c': -10000});
  });

  test('a delta nets out to zero across members', () {
    final d = expenseDelta(null, _expense());
    expect(d.balances.values.fold<int>(0, (a, b) => a + b), 0);
    expect(d.totalSpentMinor, 30000);
    expect(d.expenseCount, 1);
  });

  test('editing applies only the difference; deleting reverses it', () {
    final before = _expense(amount: 300);
    final after = _expense(amount: 600, payer: 'b');
    final edit = expenseDelta(before, after);
    expect(edit.totalSpentMinor, 30000);
    expect(edit.expenseCount, 0);
    // before + edit == contribution of the edited expense
    expect(_apply(expenseContribution(before), edit), expenseContribution(after));

    final gone = expenseDelta(after, null);
    expect(gone.expenseCount, -1);
    expect(_apply(expenseContribution(after), gone).values.every((v) => v == 0), isTrue);
  });

  test('a settlement moves money from payer to payee and nets to zero', () {
    final d = settlementDelta(
        {'fromUserId': 'b', 'toUserId': 'a', 'amountPaise': 5000});
    expect(d.balances, {'b': 5000, 'a': -5000});
    expect(d.totalSpentMinor, 0);
  });

  test('legacy settlements with only a rupee amount still count', () {
    expect(
        settlementContribution(
            {'fromUserId': 'b', 'toUserId': 'a', 'amount': 12.5}),
        {'b': 1250, 'a': -1250});
  });

  test('applying deltas one by one equals a full rebuild', () {
    final e1 = _expense(id: '1', amount: 300);
    final e2 = _expense(id: '2', amount: 90, payer: 'b', split: {'a': 45, 'b': 45});
    final e2b = _expense(id: '2', amount: 120, payer: 'b', split: {'a': 60, 'b': 60});
    final s = {'fromUserId': 'c', 'toUserId': 'a', 'amountPaise': 4000};

    // history: add e1, add e2, edit e2 -> e2b, settle, delete e1
    var running = <String, int>{};
    var total = 0;
    var count = 0;
    for (final d in [
      expenseDelta(null, e1),
      expenseDelta(null, e2),
      expenseDelta(e2, e2b),
      settlementDelta(s),
      expenseDelta(e1, null),
    ]) {
      running = _apply(running, d);
      total += d.totalSpentMinor;
      count += d.expenseCount;
    }

    final rebuilt = buildSummary(
        expenses: [e2b], settlements: [s], memberIds: ['a', 'b', 'c']);
    expect(total, rebuilt.totalSpentMinor);
    expect(count, rebuilt.expenseCount);
    for (final id in ['a', 'b', 'c']) {
      expect(running[id] ?? 0, rebuilt.balances[id] ?? 0, reason: id);
    }
  });

  test('rebuild records the newest expense title and activity', () {
    final older = _expense(id: '1', title: 'Lunch', createdAt: DateTime(2026, 2, 1));
    final newer = _expense(id: '2', title: 'Cab', createdAt: DateTime(2026, 3, 1));
    final r = buildSummary(
        expenses: [older, newer], settlements: const [], memberIds: ['a']);
    expect(r.lastExpenseTitle, 'Cab');
    expect(r.lastActivityAt, DateTime(2026, 3, 1));
    expect(r.balances.containsKey('a'), isTrue);
  });

  test('deltas add together (used for several recurring occurrences)', () {
    final one = expenseDelta(null, _expense());
    final sum = one + one;
    expect(sum.expenseCount, 2);
    expect(sum.totalSpentMinor, 60000);
    expect(sum.balances['a'], 40000);
  });

  test('only a version-1 summary with balances is trusted', () {
    expect(groupHasSummary(null), isFalse);
    expect(groupHasSummary({'balances': {}}), isFalse);
    expect(groupHasSummary({'summaryVersion': 1}), isFalse);
    expect(groupHasSummary({'summaryVersion': 1, 'balances': {'a': 0}}), isTrue);
  });
}
