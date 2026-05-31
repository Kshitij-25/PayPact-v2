import 'package:flutter_test/flutter_test.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/settle/domain/debt_simplifier.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Test fixtures
// ─────────────────────────────────────────────────────────────────────────────

/// Builds an expense where [paidBy] paid [splits] on behalf of each member.
/// `amount` is the sum of split amounts; values are in rupees.
ExpenseEntity expense({
  required String paidBy,
  required Map<String, double> splits,
  String id = 'e',
}) {
  final total = splits.values.fold<double>(0, (a, b) => a + b);
  return ExpenseEntity(
    id: id,
    groupId: 'g',
    title: id,
    amount: total,
    originalAmount: total,
    originalCurrency: 'INR',
    exchangeRate: 1.0,
    category: 'general',
    paidById: paidBy,
    paidByName: paidBy,
    splits: [
      for (final e in splits.entries)
        ExpenseSplitEntity(userId: e.key, userName: e.key, amount: e.value),
    ],
    createdAt: DateTime(2024, 1, 1),
    createdById: paidBy,
  );
}

Map<String, dynamic> settlement(String from, String to, double amount) =>
    {'fromUserId': from, 'toUserId': to, 'amount': amount};

const _names = {'A': 'Alice', 'B': 'Bob', 'C': 'Carol', 'D': 'Dave'};

void main() {
  // ───────────────────────────────────────────────────────────────────────────
  group('toPaise / fromPaise', () {
    test('rounds rupees to integer paise at the boundary', () {
      expect(toPaise(10.25), 1025);
      expect(toPaise(0.1), 10);
      expect(toPaise(0.1 + 0.2), 30); // float drift rounded away
      expect(fromPaise(1025), 10.25);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('computeNetBalances', () {
    test('A pays 100 split equally between A and B', () {
      // A paid 100, B owes their 50 share to A.
      final net = computeNetBalances(
        expenses: [
          expense(paidBy: 'A', splits: {'A': 50, 'B': 50}),
        ],
        settlements: const [],
        memberIds: ['A', 'B'],
      );
      expect(net['A'], 5000);
      expect(net['B'], -5000);
      expect(isZeroSum(net), isTrue);
    });

    test('recorded settlements reduce open balances', () {
      final net = computeNetBalances(
        expenses: [
          expense(paidBy: 'A', splits: {'A': 50, 'B': 50}),
        ],
        // B already paid A back 30.
        settlements: [settlement('B', 'A', 30)],
        memberIds: ['A', 'B'],
      );
      expect(net['A'], 2000); // owed 20 now
      expect(net['B'], -2000);
      expect(isZeroSum(net), isTrue);
    });

    test('member referenced but absent from memberIds still reconciles', () {
      final net = computeNetBalances(
        expenses: [
          expense(paidBy: 'A', splits: {'A': 30, 'X': 30}),
        ],
        settlements: const [],
        memberIds: ['A'], // X not listed
      );
      expect(net['A'], 3000);
      expect(net['X'], -3000);
      expect(isZeroSum(net), isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('simplifyDebts — core behavior', () {
    test('removes the intermediary (Splitwise canonical example)', () {
      // A paid 100 for B, B paid 100 for C  =>  A:+100, B:0, C:-100
      // Simplified: C pays A 100, B drops out entirely.
      final debts = simplifyDebts({'A': 10000, 'B': 0, 'C': -10000}, _names);

      expect(debts.length, 1);
      expect(debts.single.fromUserId, 'C');
      expect(debts.single.toUserId, 'A');
      expect(debts.single.amountPaise, 10000);
      expect(debts.single.amount, 100.0);
      // Names are resolved.
      expect(debts.single.fromUserName, 'Carol');
      expect(debts.single.toUserName, 'Alice');
    });

    test('ignores zero-balance users', () {
      final debts = simplifyDebts(
        {'A': 5000, 'B': 0, 'C': 0, 'D': -5000},
        _names,
      );
      expect(debts.length, 1);
      final touched = {
        for (final d in debts) ...[d.fromUserId, d.toUserId]
      };
      expect(touched, isNot(contains('B')));
      expect(touched, isNot(contains('C')));
    });

    test('all balances zero => no transactions', () {
      expect(simplifyDebts({'A': 0, 'B': 0}, _names), isEmpty);
      expect(simplifyDebts(const {}, _names), isEmpty);
    });

    test('circular debts collapse to nothing (A->B->C->A equal)', () {
      // A owes B 50, B owes C 50, C owes A 50 => everyone nets to zero.
      final net = computeNetBalances(
        expenses: [
          expense(paidBy: 'B', splits: {'B': 0, 'A': 50}, id: 'e1'),
          expense(paidBy: 'C', splits: {'C': 0, 'B': 50}, id: 'e2'),
          expense(paidBy: 'A', splits: {'A': 0, 'C': 50}, id: 'e3'),
        ],
        settlements: const [],
        memberIds: ['A', 'B', 'C'],
      );
      expect(net.values.every((v) => v == 0), isTrue);
      expect(simplifyDebts(net, _names), isEmpty);
    });

    test('partial repayment: one debtor pays multiple creditors', () {
      // D owes 100; A is owed 60, B is owed 40.
      final debts = simplifyDebts(
        {'A': 6000, 'B': 4000, 'D': -10000},
        _names,
      );
      expect(debts.length, 2);
      expect(debts.every((d) => d.fromUserId == 'D'), isTrue);
      final byCreditor = {for (final d in debts) d.toUserId: d.amountPaise};
      expect(byCreditor['A'], 6000);
      expect(byCreditor['B'], 4000);
    });

    test('many-to-many: one creditor receives from multiple debtors', () {
      // A is owed 100; B owes 60, C owes 40.
      final debts = simplifyDebts(
        {'A': 10000, 'B': -6000, 'C': -4000},
        _names,
      );
      expect(debts.length, 2);
      expect(debts.every((d) => d.toUserId == 'A'), isTrue);
    });

    test('already-optimal graph stays minimal', () {
      final net = {'A': 5000, 'B': -5000};
      expect(simplifyDebts(net, _names).length, 1);
    });

    test('uneven splits across four members', () {
      // A:+150, B:+50, C:-90, D:-110  (sum 0)
      final debts = simplifyDebts(
        {'A': 15000, 'B': 5000, 'C': -9000, 'D': -11000},
        _names,
      );
      // n-1 = 3 members on each side worst case; here 4 nonzero => <= 3 txns.
      expect(debts.length, lessThanOrEqualTo(3));
      expect(settlementsPreserveBalances(
        {'A': 15000, 'B': 5000, 'C': -9000, 'D': -11000},
        debts,
      ), isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('simplifyDebtsFromBalances — decimal + drift safety', () {
    test('decimal currency amounts settle exactly in paise', () {
      // Two debtors of 10.25 each, one creditor owed 20.50.
      final debts = simplifyDebtsFromBalances(
        {'A': 20.50, 'B': -10.25, 'C': -10.25},
        _names,
      );
      final total = debts.fold<int>(0, (s, d) => s + d.amountPaise);
      expect(total, 2050);
      expect(debts.every((d) => d.toUserId == 'A'), isTrue);
    });

    test('residual rounding drift is corrected to an exact zero-sum', () {
      // Independent rounding: A=+10, B=C=D=-3 paise => totals to +1 (drift).
      // The correction folds the leftover +1 onto the largest-magnitude entry
      // (A: 10 -> 9), making the set exactly zero-sum: A:+9, B/C/D:-3 each.
      final balances = {'A': 0.10, 'B': -0.033, 'C': -0.033, 'D': -0.034};
      final debts = simplifyDebtsFromBalances(balances, _names);

      expect(debts.length, 3);
      expect(debts.every((d) => d.toUserId == 'A'), isTrue);
      final creditTotal = debts.fold<int>(0, (s, d) => s + d.amountPaise);
      expect(creditTotal, 9); // A receives exactly the corrected 9 paise — no leftover
    });

    test('empty balances produce no settlements', () {
      expect(simplifyDebtsFromBalances(const {}, _names), isEmpty);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('invariants & validation utilities', () {
    final cases = <String, Map<String, int>>{
      'intermediary': {'A': 10000, 'B': 0, 'C': -10000},
      'many-to-many': {'A': 10000, 'B': -6000, 'C': -4000},
      'uneven': {'A': 15000, 'B': 5000, 'C': -9000, 'D': -11000},
      'single pair': {'A': 5000, 'B': -5000},
    };

    cases.forEach((label, net) {
      test('[$label] settlements preserve exact balances', () {
        final debts = simplifyDebts(net, _names);
        expect(settlementsPreserveBalances(net, debts), isTrue);
        expect(debts.every((d) => d.amountPaise > 0), isTrue);
      });

      test('[$label] reconstructed net is the negation of input', () {
        // Paying flips the sign: a debtor's deficit becomes the +amount they
        // pay, a creditor's surplus becomes the -amount they receive.
        final debts = simplifyDebts(net, _names);
        final reconstructed = netFromSettlements(debts);
        for (final id in net.keys) {
          if (net[id] == 0) continue;
          expect(reconstructed[id], -net[id]!);
        }
      });
    });

    test('isZeroSum detects imbalance', () {
      expect(isZeroSum({'A': 100, 'B': -100}), isTrue);
      expect(isZeroSum({'A': 100, 'B': -99}), isFalse);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('determinism', () {
    test('identical input yields byte-identical output', () {
      final net = {'A': 9000, 'B': 1000, 'C': -4000, 'D': -6000};
      final first = simplifyDebts(net, _names);
      final second = simplifyDebts(net, _names);
      expect(first, second); // relies on SimplifiedDebt == / hashCode
      // Map iteration order shouldn't matter: a reordered map gives same result.
      final reordered = {'D': -6000, 'C': -4000, 'B': 1000, 'A': 9000};
      expect(simplifyDebts(reordered, _names), first);
    });
  });
}
