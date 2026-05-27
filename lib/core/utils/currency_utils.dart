const kPrefCurrencyKey = 'pref_currency';
const kDefaultCurrency = 'INR';

class AppCurrency {
  final String code;
  final String symbol;
  final String name;
  const AppCurrency(this.code, this.symbol, this.name);
}

const kCurrencies = [
  AppCurrency('INR', '₹', 'Indian Rupee'),
  AppCurrency('USD', '\$', 'US Dollar'),
  AppCurrency('EUR', '€', 'Euro'),
  AppCurrency('GBP', '£', 'British Pound'),
  AppCurrency('JPY', '¥', 'Japanese Yen'),
  AppCurrency('AED', 'د.إ', 'UAE Dirham'),
  AppCurrency('SGD', 'S\$', 'Singapore Dollar'),
  AppCurrency('AUD', 'A\$', 'Australian Dollar'),
  AppCurrency('CAD', 'C\$', 'Canadian Dollar'),
];

String currencySymbol(String code) {
  try {
    return kCurrencies.firstWhere((c) => c.code == code).symbol;
  } catch (_) {
    return code;
  }
}

AppCurrency currencyOf(String code) {
  try {
    return kCurrencies.firstWhere((c) => c.code == code);
  } catch (_) {
    return AppCurrency(code, code, code);
  }
}
