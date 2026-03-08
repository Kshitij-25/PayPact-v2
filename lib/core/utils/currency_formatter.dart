import 'package:intl/intl.dart';

/// Formats monetary amounts with thousands separators, correct decimal places,
/// and the proper symbol/position for every supported currency.
///
/// Usage:
///   CurrencyFormatter.format(1234567.89, 'USD')  → '$1,234,567.89'
///   CurrencyFormatter.format(1234567.89, 'EUR')  → '€1,234,567.89'
///   CurrencyFormatter.format(150000,     'JPY')  → '¥150,000'
///   CurrencyFormatter.format(1234.5,     'INR')  → '₹1,234.50'
///
///   // Signed variant (for balance display)
///   CurrencyFormatter.signed(50.0,  'USD')  → '+$50.00'
///   CurrencyFormatter.signed(-50.0, 'USD')  → '-$50.00'
class CurrencyFormatter {
  CurrencyFormatter._();

  // ── Per-currency metadata ──────────────────────────────────────────────────

  static const Map<String, _CurrencyMeta> _meta = {
    'USD': _CurrencyMeta('\$', 'en_US', 2),
    'EUR': _CurrencyMeta('€', 'de_DE', 2),
    'GBP': _CurrencyMeta('£', 'en_GB', 2),
    'JPY': _CurrencyMeta('¥', 'ja_JP', 0),
    'AUD': _CurrencyMeta('A\$', 'en_AU', 2),
    'CAD': _CurrencyMeta('C\$', 'en_CA', 2),
    'CHF': _CurrencyMeta('Fr', 'de_CH', 2),
    'INR': _CurrencyMeta('₹', 'en_IN', 2),
    'BRL': _CurrencyMeta('R\$', 'pt_BR', 2),
    'MXN': _CurrencyMeta('MX\$', 'es_MX', 2),
    'SGD': _CurrencyMeta('S\$', 'en_SG', 2),
    'HKD': _CurrencyMeta('HK\$', 'en_HK', 2),
    'NOK': _CurrencyMeta('kr', 'nb_NO', 2),
    'SEK': _CurrencyMeta('kr', 'sv_SE', 2),
    'DKK': _CurrencyMeta('kr', 'da_DK', 2),
  };

  // Cache formatters — creating NumberFormat is relatively expensive
  static final Map<String, NumberFormat> _cache = {};

  static NumberFormat _formatterFor(String currencyCode) {
    return _cache.putIfAbsent(currencyCode, () {
      final meta = _meta[currencyCode] ??
          const _CurrencyMeta('\$', 'en_US', 2); // safe fallback
      return NumberFormat.currency(
        locale: meta.locale,
        symbol: meta.symbol,
        decimalDigits: meta.decimals,
      );
    });
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns the formatted amount with symbol and thousands separator.
  /// e.g. format(1234.5, 'USD') → '$1,234.50'
  static String format(double amount, String currencyCode) {
    return _formatterFor(currencyCode).format(amount);
  }

  /// Like [format] but prefixes + or - for balance displays.
  /// e.g. signed(50.0, 'USD') → '+$50.00'   signed(-50.0, 'USD') → '-$50.00'
  static String signed(double amount, String currencyCode) {
    final abs = _formatterFor(currencyCode).format(amount.abs());
    if (amount >= 0) return '+$abs';
    return '-$abs';
  }

  /// Returns just the symbol for a currency code, useful for chart labels.
  static String symbolFor(String currencyCode) =>
      _meta[currencyCode]?.symbol ?? currencyCode;
}

class _CurrencyMeta {
  const _CurrencyMeta(this.symbol, this.locale, this.decimals);
  final String symbol;
  final String locale;
  final int decimals;
}
