import 'package:paypact/domain/entities/expense_entity.dart';
import 'package:paypact/domain/entities/expense_split_entity.dart';

/// Computes expense splits based on SplitType.
/// Pure domain logic — zero dependencies.
class ExpenseSplitService {
  const ExpenseSplitService();

  List<ExpenseSplitEntity> computeSplits({
    required SplitType splitType,
    required double totalAmount,
    required List<String> memberIds,
    Map<String, double>? exactAmounts,
    Map<String, double>? percentages,
    Map<String, int>? shares,
  }) {
    switch (splitType) {
      case SplitType.equal:
        return _splitEqually(totalAmount, memberIds);
      case SplitType.exact:
        return _splitByExactAmounts(exactAmounts ?? {}, memberIds);
      case SplitType.percentage:
        return _splitByPercentage(totalAmount, percentages ?? {}, memberIds);
      case SplitType.shares:
        return _splitByShares(totalAmount, shares ?? {}, memberIds);
    }
  }

  List<ExpenseSplitEntity> _splitEqually(double total, List<String> ids) {
    if (ids.isEmpty) return [];
    final perPerson = _round(total / ids.length);
    final splits = ids
        .map((id) => ExpenseSplitEntity(userId: id, amount: perPerson))
        .toList();
    // Adjust last person for rounding
    final sumRounded = perPerson * (ids.length - 1);
    return [
      ...splits.sublist(0, splits.length - 1),
      splits.last.copyWith(amount: _round(total - sumRounded)),
    ];
  }

  List<ExpenseSplitEntity> _splitByExactAmounts(
    Map<String, double> amounts,
    List<String> ids,
  ) {
    return ids.map((id) {
      return ExpenseSplitEntity(userId: id, amount: amounts[id] ?? 0.0);
    }).toList();
  }

  List<ExpenseSplitEntity> _splitByPercentage(
    double total,
    Map<String, double> pcts,
    List<String> ids,
  ) {
    return ids.map((id) {
      final pct = pcts[id] ?? 0.0;
      return ExpenseSplitEntity(
        userId: id,
        amount: _round(total * pct / 100),
        percentage: pct,
      );
    }).toList();
  }

  List<ExpenseSplitEntity> _splitByShares(
    double total,
    Map<String, int> shareMap,
    List<String> ids,
  ) {
    final totalShares = shareMap.values.fold(0, (a, b) => a + b);
    if (totalShares == 0) return _splitEqually(total, ids);
    return ids.map((id) {
      final userShares = shareMap[id] ?? 0;
      return ExpenseSplitEntity(
        userId: id,
        amount: _round(total * userShares / totalShares),
        shares: userShares,
      );
    }).toList();
  }

  double _round(double value) => (value * 100).round() / 100;

  /// Validates that all splits sum to the total amount
  bool validateSplits(List<ExpenseSplitEntity> splits, double total,
      {double epsilon = 0.02}) {
    final sum = splits.fold(0.0, (acc, s) => acc + s.amount);
    return (sum - total).abs() <= epsilon;
  }
}
