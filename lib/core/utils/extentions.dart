import 'package:intl/intl.dart';
import 'package:paypact/core/utils/currency_formatter.dart';

extension DateTimeExtension on DateTime {
  String toFormattedDate() => DateFormat('MMM d, yyyy').format(this);
  String toShortDate() => DateFormat('MMM d').format(this);
  String toRelative() {
    final now = DateTime.now();
    final diff = now.difference(this);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return toFormattedDate();
  }
}

extension CurrencyExtension on double {
  /// Format with thousands separator for the given ISO currency code.
  String toCurrency(String currencyCode) =>
      CurrencyFormatter.format(this, currencyCode);

  /// Signed format (+/-) for balance displays.
  String toSignedCurrency(String currencyCode) =>
      CurrencyFormatter.signed(this, currencyCode);
}

extension StringExtension on String {
  String get initials {
    final parts = trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  bool get isValidEmail =>
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
          .hasMatch(this);
}

class DebtSimplifier {
  /// Simplifies debts among group members using the minimum cash flow algorithm.
  /// Returns a list of simplified transactions: (from, to, amount).
  static List<({String from, String to, double amount})> simplify(
    Map<String, double> balances,
  ) {
    final creditors = <MapEntry<String, double>>[];
    final debtors = <MapEntry<String, double>>[];

    for (final entry in balances.entries) {
      if (entry.value > 0.001) {
        creditors.add(entry);
      } else if (entry.value < -0.001) {
        debtors.add(MapEntry(entry.key, -entry.value));
      }
    }

    creditors.sort((a, b) => b.value.compareTo(a.value));
    debtors.sort((a, b) => b.value.compareTo(a.value));

    final transactions = <({String from, String to, double amount})>[];
    var ci = 0;
    var di = 0;

    final creditorAmounts = creditors.map((e) => e.value).toList();
    final debtorAmounts = debtors.map((e) => e.value).toList();

    while (ci < creditors.length && di < debtors.length) {
      final settle = creditorAmounts[ci] < debtorAmounts[di]
          ? creditorAmounts[ci]
          : debtorAmounts[di];

      transactions.add((
        from: debtors[di].key,
        to: creditors[ci].key,
        amount: double.parse(settle.toStringAsFixed(2)),
      ));

      creditorAmounts[ci] -= settle;
      debtorAmounts[di] -= settle;

      if (creditorAmounts[ci] < 0.001) ci++;
      if (debtorAmounts[di] < 0.001) di++;
    }

    return transactions;
  }
}
