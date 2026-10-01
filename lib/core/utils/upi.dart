// UPI helpers: validating a payment address and building the `upi://pay`
// deep link that opens the user's UPI app (GPay, PhonePe, Paytm, BHIM…).

final _upiRe = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9.\-_]{1,255}@[a-zA-Z][a-zA-Z0-9]{1,63}$');

/// Trims and lower-cases a typed UPI ID; null when it isn't one.
String? normalizeUpiId(String? raw) {
  final v = raw?.trim().toLowerCase();
  if (v == null || !_upiRe.hasMatch(v)) return null;
  return v;
}

/// `upi://pay` link. [amount] is in rupees; UPI only supports INR, so callers
/// should only offer this for INR groups.
Uri buildUpiUri({
  required String upiId,
  required String payeeName,
  double? amount,
  String? note,
}) {
  return Uri(
    scheme: 'upi',
    host: 'pay',
    queryParameters: {
      'pa': upiId,
      'pn': payeeName,
      if (amount != null && amount > 0) 'am': amount.toStringAsFixed(2),
      'cu': 'INR',
      if (note != null && note.isNotEmpty)
        'tn': note.length > 50 ? note.substring(0, 50) : note,
    },
  );
}
