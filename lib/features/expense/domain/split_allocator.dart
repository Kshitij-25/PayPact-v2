// Exact money splitting in integer minor units (paise/cents).
//
// Dividing ₹100 three ways can't be 33.33 × 3. These helpers hand the leftover
// paise to the shares with the largest remainders (ties to the earliest), so
// the parts always add up to the total exactly.

int toMinor(double amount) => (amount * 100).round();
double fromMinor(int minor) => minor / 100.0;

/// Splits [totalMinor] across [weights] proportionally. Weights must be
/// non-negative with a positive sum; an all-zero weight list gets an equal split.
List<int> allocateByWeights(int totalMinor, List<double> weights) {
  if (weights.isEmpty) return [];
  final sum = weights.fold<double>(0, (a, b) => a + b);
  final effective = sum > 0 ? weights : List<double>.filled(weights.length, 1);
  final effectiveSum = sum > 0 ? sum : weights.length.toDouble();

  final exact = [for (final w in effective) totalMinor * w / effectiveSum];
  final floors = [for (final e in exact) e.floor()];
  var leftover = totalMinor - floors.fold<int>(0, (a, b) => a + b);

  final order = List<int>.generate(weights.length, (i) => i)
    ..sort((a, b) {
      final byRemainder =
          (exact[b] - floors[b]).compareTo(exact[a] - floors[a]);
      return byRemainder != 0 ? byRemainder : a.compareTo(b);
    });
  final result = List<int>.of(floors);
  for (var i = 0; leftover > 0; i = (i + 1) % order.length) {
    result[order[i]]++;
    leftover--;
  }
  return result;
}

/// Equal split of [totalMinor] among [count] people.
List<int> allocateEqually(int totalMinor, int count) =>
    allocateByWeights(totalMinor, List<double>.filled(count, 1));

/// Re-scales existing [shares] (in any unit) so they total exactly [targetMinor],
/// keeping their proportions. Used when an expense is converted between
/// currencies, so rounding each share separately can't drift from the total.
List<int> rescaleShares(List<double> shares, int targetMinor) =>
    allocateByWeights(targetMinor, shares);
