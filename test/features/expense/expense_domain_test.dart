import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/entities/expense_extras.dart';
import 'package:paypact/features/expense/domain/expense_changes.dart';
import 'package:paypact/features/expense/domain/split_allocator.dart';

ExpenseEntity _e({
  String title = 'Dinner',
  double amount = 100,
  String currency = 'INR',
  String category = 'food',
  String payer = 'a',
  List<double> shares = const [50, 50],
  DateTime? date,
  String? note,
  String? receipt,
}) =>
    ExpenseEntity(
      id: 'e',
      groupId: 'g',
      title: title,
      amount: amount,
      originalAmount: amount,
      originalCurrency: currency,
      exchangeRate: 1,
      category: category,
      paidById: payer,
      paidByName: payer.toUpperCase(),
      splits: [
        for (var i = 0; i < shares.length; i++)
          ExpenseSplitEntity(
              userId: 'u$i', userName: 'U$i', amount: shares[i]),
      ],
      createdAt: DateTime(2026, 1, 1),
      createdById: 'a',
      date: date ?? DateTime(2026, 1, 1),
      note: note,
      receiptUrl: receipt,
    );

void main() {
  group('split allocation', () {
    test('₹100 three ways is 33.34 / 33.33 / 33.33 and totals exactly', () {
      final parts = allocateEqually(10000, 3);
      expect(parts, [3334, 3333, 3333]);
      expect(parts.reduce((a, b) => a + b), 10000);
    });

    test('divides evenly when it can', () {
      expect(allocateEqually(9000, 3), [3000, 3000, 3000]);
    });

    test('weights: percentages and shares keep proportions and the total', () {
      final byPercent = allocateByWeights(10000, [50, 30, 20]);
      expect(byPercent, [5000, 3000, 2000]);
      final byShares = allocateByWeights(1000, [1, 1, 1]);
      expect(byShares.reduce((a, b) => a + b), 1000);
      final odd = allocateByWeights(10001, [33.3, 33.3, 33.4]);
      expect(odd.reduce((a, b) => a + b), 10001);
    });

    test('largest remainders get the extra paise (ties to the earliest)', () {
      // 100 / 3 shares weighted 1:1:2 → exact 25, 25, 50
      expect(allocateByWeights(100, [1, 1, 2]), [25, 25, 50]);
      // 1 paisa across two equal weights goes to the first
      expect(allocateEqually(1, 2), [1, 0]);
    });

    test('all-zero weights fall back to an equal split; empty is empty', () {
      expect(allocateByWeights(100, [0, 0]), [50, 50]);
      expect(allocateByWeights(100, []), isEmpty);
      expect(allocateEqually(0, 3), [0, 0, 0]);
    });

    test('rescaling keeps the total exact for any amounts', () {
      final rng = Random(7);
      for (var i = 0; i < 300; i++) {
        final n = 1 + rng.nextInt(8);
        final weights = List.generate(n, (_) => rng.nextDouble() * 500);
        final total = rng.nextInt(2000000);
        final parts = rescaleShares(weights, total);
        expect(parts.reduce((a, b) => a + b), total);
        expect(parts.every((p) => p >= 0), isTrue);
      }
    });

    test('toMinor / fromMinor round-trip', () {
      expect(toMinor(33.335), 3334);
      expect(toMinor(0.1 + 0.2), 30);
      expect(fromMinor(1999), 19.99);
    });
  });

  group('describeExpenseChanges', () {
    List<String> diff(ExpenseEntity a, ExpenseEntity b) =>
        describeExpenseChanges(a, b, groupCurrency: 'INR');

    test('nothing changed → nothing reported', () {
      expect(diff(_e(), _e()), isEmpty);
    });

    test('reports each visible change on its own line', () {
      final out = diff(
        _e(),
        _e(
          title: 'Dinner out',
          amount: 120,
          category: 'fun',
          payer: 'b',
          shares: [70, 50],
          date: DateTime(2026, 1, 5),
          note: 'with friends',
          receipt: 'https://x/r.jpg',
        ),
      );
      expect(out, contains('Title: "Dinner" → "Dinner out"'));
      expect(out, contains('Amount: ₹100 → ₹120'));
      expect(out, contains('Category: food → fun'));
      expect(out, contains('Paid by: A → B'));
      expect(out, contains('Split changed'));
      expect(out, contains('Date: Jan 1, 2026 → Jan 5, 2026'));
      expect(out, contains('Note updated'));
      expect(out, contains('Receipt attached'));
    });

    test('currency changes are part of the amount line', () {
      expect(diff(_e(), _e(currency: 'USD')),
          ['Amount: ₹100 → \$100']);
    });

    test('removing a note or receipt says so; same-day edits are ignored', () {
      expect(diff(_e(note: 'x'), _e()), ['Note removed']);
      expect(diff(_e(receipt: 'u'), _e()), ['Receipt removed']);
      expect(
          diff(_e(date: DateTime(2026, 1, 1, 9)),
              _e(date: DateTime(2026, 1, 1, 23))),
          isEmpty);
    });

    test('sub-paisa noise in shares is not a change', () {
      expect(diff(_e(shares: [50, 50]), _e(shares: [50.001, 49.999])), isEmpty);
    });
  });

  group('nextRecurrence', () {
    test('weekly adds seven days', () {
      expect(nextRecurrence(DateTime(2026, 1, 1), RecurrenceInterval.weekly),
          DateTime(2026, 1, 8));
    });

    test('monthly keeps the day, and clamps to short months', () {
      expect(nextRecurrence(DateTime(2026, 1, 15), RecurrenceInterval.monthly),
          DateTime(2026, 2, 15));
      expect(nextRecurrence(DateTime(2026, 1, 31), RecurrenceInterval.monthly),
          DateTime(2026, 2, 28));
      expect(nextRecurrence(DateTime(2028, 1, 31), RecurrenceInterval.monthly),
          DateTime(2028, 2, 29));
      expect(nextRecurrence(DateTime(2026, 12, 20), RecurrenceInterval.monthly),
          DateTime(2027, 1, 20));
    });
  });

  test('expense date falls back to the entry time for older documents', () {
    final e = ExpenseEntity(
      id: 'x',
      groupId: 'g',
      title: 't',
      amount: 1,
      originalAmount: 1,
      originalCurrency: 'INR',
      exchangeRate: 1,
      category: 'food',
      paidById: 'a',
      paidByName: 'A',
      splits: const [],
      createdAt: DateTime(2026, 2, 3),
      createdById: 'a',
    );
    expect(e.date, DateTime(2026, 2, 3));
  });
}
