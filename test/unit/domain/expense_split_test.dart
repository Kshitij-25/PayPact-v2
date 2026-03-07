import 'package:flutter_test/flutter_test.dart';
import 'package:paypact/core/services/expense_split_service.dart';
import 'package:paypact/domain/entities/expense_entity.dart';

void main() {
  late ExpenseSplitService service;

  setUp(() => service = const ExpenseSplitService());

  group('ExpenseSplitService', () {
    test('equal split divides correctly', () {
      final splits = service.computeSplits(
        splitType: SplitType.equal,
        totalAmount: 90.0,
        memberIds: ['a', 'b', 'c'],
      );
      expect(splits.length, 3);
      final total = splits.fold(0.0, (s, e) => s + e.amount);
      expect(total, closeTo(90.0, 0.02));
      for (final s in splits) {
        expect(s.amount, closeTo(30.0, 0.01));
      }
    });

    test('exact split with custom amounts', () {
      final splits = service.computeSplits(
        splitType: SplitType.exact,
        totalAmount: 100.0,
        memberIds: ['a', 'b'],
        exactAmounts: {'a': 60.0, 'b': 40.0},
      );
      expect(splits.firstWhere((s) => s.userId == 'a').amount, 60.0);
      expect(splits.firstWhere((s) => s.userId == 'b').amount, 40.0);
    });

    test('percentage split adds to 100%', () {
      final splits = service.computeSplits(
        splitType: SplitType.percentage,
        totalAmount: 200.0,
        memberIds: ['a', 'b'],
        percentages: {'a': 70.0, 'b': 30.0},
      );
      expect(splits.firstWhere((s) => s.userId == 'a').amount,
          closeTo(140.0, 0.02));
      expect(splits.firstWhere((s) => s.userId == 'b').amount,
          closeTo(60.0, 0.02));
    });

    test('shares split by ratio', () {
      final splits = service.computeSplits(
        splitType: SplitType.shares,
        totalAmount: 120.0,
        memberIds: ['a', 'b', 'c'],
        shares: {'a': 2, 'b': 1, 'c': 1},
      );
      expect(splits.firstWhere((s) => s.userId == 'a').amount,
          closeTo(60.0, 0.02));
      expect(splits.firstWhere((s) => s.userId == 'b').amount,
          closeTo(30.0, 0.02));
    });

    test('validateSplits returns true for correct sum', () {
      final splits = service.computeSplits(
        splitType: SplitType.equal,
        totalAmount: 99.99,
        memberIds: ['a', 'b', 'c'],
      );
      expect(service.validateSplits(splits, 99.99), isTrue);
    });
  });
}
