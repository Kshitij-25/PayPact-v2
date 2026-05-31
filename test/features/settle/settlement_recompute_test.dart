import 'package:flutter_test/flutter_test.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/settle/data/settlement_model.dart';
import 'package:paypact/features/settle/domain/debt_simplifier.dart';
import 'package:paypact/features/settle/domain/settlement_entity.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fixtures
// ─────────────────────────────────────────────────────────────────────────────

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

/// A settlement map as `getGroupSettlements` returns it.
Map<String, dynamic> settlement(
  String from,
  String to, {
  int? amountPaise,
  double? amount,
}) =>
    {
      'fromUserId': from,
      'toUserId': to,
      if (amountPaise != null) 'amountPaise': amountPaise,
      if (amount != null) 'amount': amount,
    };

void main() {
  // Alice owes Bob ₹500.
  final aliceOwesBob = [
    expense(paidBy: 'Bob', splits: {'Alice': 500}),
  ];

  group('computeNetBalances with settlements', () {
    test('the spec example: settle ₹200 leaves -300 / +300', () {
      final net = computeNetBalances(
        expenses: aliceOwesBob,
        settlements: [settlement('Alice', 'Bob', amountPaise: 20000)],
        memberIds: ['Alice', 'Bob'],
      );
      expect(net['Alice'], -30000); // owes ₹300
      expect(net['Bob'], 30000); // owed ₹300
      expect(isZeroSum(net), isTrue);
    });

    test('exact settlement clears the debt to zero', () {
      final net = computeNetBalances(
        expenses: aliceOwesBob,
        settlements: [settlement('Alice', 'Bob', amountPaise: 50000)],
        memberIds: ['Alice', 'Bob'],
      );
      expect(net['Alice'], 0);
      expect(net['Bob'], 0);
    });

    test('multiple partial settlements accumulate', () {
      final net = computeNetBalances(
        expenses: aliceOwesBob,
        settlements: [
          settlement('Alice', 'Bob', amountPaise: 20000),
          settlement('Alice', 'Bob', amountPaise: 10000),
        ],
        memberIds: ['Alice', 'Bob'],
      );
      expect(net['Alice'], -20000); // ₹500 - ₹200 - ₹100 = ₹200 owed
      expect(net['Bob'], 20000);
    });

    test('amountPaise is preferred over a conflicting legacy amount', () {
      final net = computeNetBalances(
        expenses: aliceOwesBob,
        // amountPaise is authoritative; the stale `amount` must be ignored.
        settlements: [
          settlement('Alice', 'Bob', amountPaise: 20000, amount: 999.0),
        ],
        memberIds: ['Alice', 'Bob'],
      );
      expect(net['Alice'], -30000);
    });

    test('legacy settlement with only `amount` still reconciles', () {
      final net = computeNetBalances(
        expenses: aliceOwesBob,
        settlements: [settlement('Alice', 'Bob', amount: 200.0)],
        memberIds: ['Alice', 'Bob'],
      );
      expect(net['Alice'], -30000);
      expect(net['Bob'], 30000);
    });

    test('decimal settlement (₹10.25) reduces debt exactly in paise', () {
      final net = computeNetBalances(
        expenses: [
          expense(paidBy: 'Bob', splits: {'Alice': 10.25}),
        ],
        settlements: [settlement('Alice', 'Bob', amountPaise: 500)],
        memberIds: ['Alice', 'Bob'],
      );
      expect(net['Alice'], -525); // 1025 - 500
      expect(net['Bob'], 525);
    });
  });

  group('SettlementModel serialization', () {
    SettlementModel sample() => SettlementModel(
          id: 'idem-1',
          groupId: 'g1',
          fromUserId: 'A',
          fromUserName: 'Alice',
          toUserId: 'B',
          toUserName: 'Bob',
          amountPaise: 20000,
          currency: 'INR',
          note: 'dinner',
          paymentMethod: PaymentMethod.upi,
          status: PaymentStatus.completed,
          provider: 'razorpay:txn_123',
          createdById: 'A',
          idempotencyKey: 'idem-1',
          receiptId: 'PP-ABC',
          createdAt: DateTime(2024, 5, 1, 12, 0, 0),
        );

    test('toMap -> fromMap round-trips all fields', () {
      final original = sample();
      final map = original.toMap(serverTimestamp: false);
      final restored = SettlementModel.fromMap('idem-1', 'g1', map);

      expect(restored.amountPaise, 20000);
      expect(restored.amount, 200.0);
      expect(restored.currency, 'INR');
      expect(restored.note, 'dinner');
      expect(restored.paymentMethod, PaymentMethod.upi);
      expect(restored.status, PaymentStatus.completed);
      expect(restored.provider, 'razorpay:txn_123');
      expect(restored.createdById, 'A');
      expect(restored.idempotencyKey, 'idem-1');
      expect(restored.receiptId, 'PP-ABC');
      expect(restored.type, kSettlementType);
      expect(restored.createdAt, DateTime(2024, 5, 1, 12, 0, 0));
    });

    test('missing optional fields fall back to safe defaults', () {
      final restored = SettlementModel.fromMap('doc-x', 'g1', {
        'fromUserId': 'A',
        'toUserId': 'B',
        'amount': 50.0, // legacy: rupees only, no amountPaise
      });
      expect(restored.amountPaise, 5000); // derived from amount
      expect(restored.paymentMethod, PaymentMethod.cash);
      expect(restored.status, PaymentStatus.completed);
      expect(restored.idempotencyKey, 'doc-x'); // falls back to doc id
      expect(restored.note, isNull);
      expect(restored.provider, isNull);
    });

    test('unknown status normalizes to completed', () {
      final restored = SettlementModel.fromMap('doc-y', 'g1', {
        'fromUserId': 'A',
        'toUserId': 'B',
        'amountPaise': 100,
        'status': 'bogus',
      });
      expect(restored.status, PaymentStatus.completed);
    });
  });
}
