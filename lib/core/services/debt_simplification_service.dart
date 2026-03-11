import 'package:paypact/features/group/domain/entities/debt_entity.dart';
import 'package:paypact/features/group/domain/entities/member_entity.dart';

/// Pure domain service — no Flutter/Firebase dependencies.
/// Implements Greedy Debt Simplification using net-balance settling.
///
/// Algorithm:
/// 1. Compute net balance for each member (positive = owed, negative = owes)
/// 2. Greedily match largest creditor with largest debtor
/// 3. Repeat until all balances are settled
class DebtSimplificationService {
  const DebtSimplificationService();

  /// Takes raw balances map {userId: netBalance} and returns
  /// the minimum set of transactions to settle all debts.
  List<DebtEntity> simplify(
    Map<String, double> balances, {
    String currency = 'USD',
    double epsilon = 0.01,
  }) {
    final List<DebtEntity> result = [];

    // Separate into creditors (positive) and debtors (negative)
    final creditors = <String, double>{};
    final debtors = <String, double>{};

    balances.forEach((userId, balance) {
      if (balance > epsilon) {
        creditors[userId] = balance;
      } else if (balance < -epsilon) {
        debtors[userId] = balance.abs();
      }
    });

    while (creditors.isNotEmpty && debtors.isNotEmpty) {
      // Pick max creditor and max debtor
      final creditorEntry =
          creditors.entries.reduce((a, b) => a.value >= b.value ? a : b);
      final debtorEntry =
          debtors.entries.reduce((a, b) => a.value >= b.value ? a : b);

      final creditorId = creditorEntry.key;
      final debtorId = debtorEntry.key;
      final creditAmount = creditorEntry.value;
      final debtAmount = debtorEntry.value;

      final settleAmount =
          creditAmount <= debtAmount ? creditAmount : debtAmount;

      result.add(DebtEntity(
        debtorId: debtorId,
        creditorId: creditorId,
        amount: _round(settleAmount),
        currency: currency,
      ));

      final newCredit = creditAmount - settleAmount;
      final newDebt = debtAmount - settleAmount;

      if (newCredit < epsilon) {
        creditors.remove(creditorId);
      } else {
        creditors[creditorId] = newCredit;
      }

      if (newDebt < epsilon) {
        debtors.remove(debtorId);
      } else {
        debtors[debtorId] = newDebt;
      }
    }

    return result;
  }

  /// Compute net balances from expense-based raw balance map and members.
  Map<String, double> computeNetBalances(
    List<MemberEntity> members,
  ) {
    return {for (final m in members) m.userId: m.balance};
  }

  double _round(double value) => (value * 100).round() / 100;
}
