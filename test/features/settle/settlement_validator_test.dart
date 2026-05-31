import 'package:flutter_test/flutter_test.dart';
import 'package:paypact/features/settle/domain/settlement_validator.dart';

void main() {
  // Alice owes Bob ₹500: Alice net -50000 paise, Bob net +50000 paise.
  const members = ['A', 'B'];
  const aliceOwesBob = {'A': -50000, 'B': 50000};

  group('hard rules (block the settlement)', () {
    test('zero amount is rejected', () {
      final v = validateSettlement(
        fromUserId: 'A',
        toUserId: 'B',
        amountPaise: 0,
        memberIds: members,
        netBalancesPaise: aliceOwesBob,
      );
      expect(v.isValid, isFalse);
      expect(v.error, SettlementError.nonPositiveAmount);
    });

    test('negative amount is rejected', () {
      final v = validateSettlement(
        fromUserId: 'A',
        toUserId: 'B',
        amountPaise: -100,
        memberIds: members,
        netBalancesPaise: aliceOwesBob,
      );
      expect(v.error, SettlementError.nonPositiveAmount);
    });

    test('paying yourself is rejected', () {
      final v = validateSettlement(
        fromUserId: 'A',
        toUserId: 'A',
        amountPaise: 10000,
        memberIds: members,
        netBalancesPaise: aliceOwesBob,
      );
      expect(v.error, SettlementError.sameUser);
    });

    test('non-member payer is rejected', () {
      final v = validateSettlement(
        fromUserId: 'Z',
        toUserId: 'B',
        amountPaise: 10000,
        memberIds: members,
        netBalancesPaise: aliceOwesBob,
      );
      expect(v.error, SettlementError.payerNotMember);
    });

    test('non-member receiver is rejected', () {
      final v = validateSettlement(
        fromUserId: 'A',
        toUserId: 'Z',
        amountPaise: 10000,
        memberIds: members,
        netBalancesPaise: aliceOwesBob,
      );
      expect(v.error, SettlementError.receiverNotMember);
    });

    test('every error exposes a non-empty message', () {
      for (final e in SettlementError.values) {
        expect(e.message, isNotEmpty);
      }
    });
  });

  group('advisories (never block — Splitwise-style)', () {
    test('partial settlement: valid, within max, not overpayment', () {
      // Alice owes Bob ₹500, settles ₹200.
      final v = validateSettlement(
        fromUserId: 'A',
        toUserId: 'B',
        amountPaise: 20000,
        memberIds: members,
        netBalancesPaise: aliceOwesBob,
      );
      expect(v.isValid, isTrue);
      expect(v.payerOwes, isTrue);
      expect(v.receiverOwed, isTrue);
      expect(v.maxToClearPaise, 50000);
      expect(v.isOverpayment, isFalse);
    });

    test('exact settlement is not an overpayment', () {
      final v = validateSettlement(
        fromUserId: 'A',
        toUserId: 'B',
        amountPaise: 50000,
        memberIds: members,
        netBalancesPaise: aliceOwesBob,
      );
      expect(v.isValid, isTrue);
      expect(v.isOverpayment, isFalse);
    });

    test('overpayment is allowed but flagged', () {
      // Alice owes ₹500 but settles ₹600.
      final v = validateSettlement(
        fromUserId: 'A',
        toUserId: 'B',
        amountPaise: 60000,
        memberIds: members,
        netBalancesPaise: aliceOwesBob,
      );
      expect(v.isValid, isTrue); // not blocked
      expect(v.isOverpayment, isTrue);
      expect(v.maxToClearPaise, 50000);
    });

    test('paying when you owe nothing: valid, maxToClear 0, overpayment', () {
      // A is a creditor (+500) paying B who also is owed (+ -? ) — A doesn't owe.
      final v = validateSettlement(
        fromUserId: 'A',
        toUserId: 'B',
        amountPaise: 10000,
        memberIds: members,
        netBalancesPaise: const {'A': 50000, 'B': -50000},
      );
      expect(v.isValid, isTrue);
      expect(v.payerOwes, isFalse);
      expect(v.receiverOwed, isFalse);
      expect(v.maxToClearPaise, 0);
      expect(v.isOverpayment, isTrue);
    });

    test('maxToClear caps at the smaller side', () {
      // A owes 300, B is owed 500 -> can only clear 300 in this direction.
      final v = validateSettlement(
        fromUserId: 'A',
        toUserId: 'B',
        amountPaise: 10000,
        memberIds: ['A', 'B', 'C'],
        netBalancesPaise: const {'A': -30000, 'B': 50000, 'C': -20000},
      );
      expect(v.maxToClearPaise, 30000);
    });
  });
}
