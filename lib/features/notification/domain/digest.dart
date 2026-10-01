import 'package:paypact/core/utils/currency_utils.dart';

/// "₹1200", "$25.50" — [minor] units in [currency]; unknown codes read
/// "XYZ 50".
String formatMoney(int minor, String currency) {
  final sym = currencySymbol(currency);
  final whole = minor.abs() / 100;
  final text = whole == whole.truncateToDouble()
      ? whole.toInt().toString()
      : whole.toStringAsFixed(2);
  return sym == currency ? '$sym $text' : '$sym$text';
}

class Digest {
  const Digest(this.title, this.body);
  final String title;
  final String body;
}

/// The weekly digest line for one person, or null when there's nothing to say.
/// [net] is keyed by currency code, in minor units (+ owed, − owes).
Digest? buildDigest({
  required int expenseCount,
  required int groupCount,
  required Map<String, int> net,
}) {
  final owed = <String>[];
  final owe = <String>[];
  for (final e in net.entries) {
    if (e.value >= 100) owed.add(formatMoney(e.value, e.key));
    if (e.value <= -100) owe.add(formatMoney(e.value, e.key));
  }
  if (expenseCount == 0 && owed.isEmpty && owe.isEmpty) return null;

  final parts = <String>[
    if (expenseCount > 0)
      '$expenseCount new expense${expenseCount == 1 ? '' : 's'} across '
          '$groupCount group${groupCount == 1 ? '' : 's'}',
    if (owed.isNotEmpty) "you're owed ${owed.join(' + ')}",
    if (owe.isNotEmpty) 'you owe ${owe.join(' + ')}',
  ];
  final body = parts.join(' · ');
  return Digest('Your weekly PayPact digest',
      '${body[0].toUpperCase()}${body.substring(1)}.');
}
