import 'package:flutter_test/flutter_test.dart';
import 'package:paypact/core/services/debt_simplification_service.dart';

void main() {
  late DebtSimplificationService service;

  setUp(() => service = const DebtSimplificationService());

  group('DebtSimplificationService', () {
    test('returns empty list when all balances are zero', () {
      final result = service.simplify({'a': 0, 'b': 0, 'c': 0});
      expect(result, isEmpty);
    });

    test('simple two-person debt', () {
      final result = service.simplify({'alice': 50.0, 'bob': -50.0});
      expect(result.length, 1);
      expect(result.first.debtorId, 'bob');
      expect(result.first.creditorId, 'alice');
      expect(result.first.amount, 50.0);
    });

    test('three-person debt simplification reduces transactions', () {
      // alice paid for bob and carol
      // bob owes 30, carol owes 30, alice gets back 60
      final balances = {'alice': 60.0, 'bob': -30.0, 'carol': -30.0};
      final result = service.simplify(balances);
      expect(result.length, 2);
      final totalDebt = result.fold(0.0, (sum, d) => sum + d.amount);
      expect(totalDebt, closeTo(60.0, 0.01));
    });

    test('complex group minimizes transactions', () {
      final balances = {
        'a': 30.0,
        'b': -10.0,
        'c': -20.0,
        'd': 15.0,
        'e': -15.0,
      };
      final result = service.simplify(balances);
      // Verify net balance after transactions
      final netAfter = <String, double>{
        for (final k in balances.keys) k: balances[k]!
      };
      for (final d in result) {
        netAfter[d.debtorId] = (netAfter[d.debtorId] ?? 0) + d.amount;
        netAfter[d.creditorId] = (netAfter[d.creditorId] ?? 0) - d.amount;
      }
      for (final v in netAfter.values) {
        expect(v.abs(), lessThan(0.02));
      }
    });
  });
}