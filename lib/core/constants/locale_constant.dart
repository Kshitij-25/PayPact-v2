/// Single source of truth for supported currencies and languages.
/// Import this wherever you need to display or select a currency/language.
library;

/// Each record: (ISO code, display name, symbol)
const List<(String, String, String)> kSupportedCurrencies = [
  ('USD', 'US Dollar', '\$'),
  ('EUR', 'Euro', '€'),
  ('GBP', 'British Pound', '£'),
  ('INR', 'Indian Rupee', '₹'),
  ('JPY', 'Japanese Yen', '¥'),
  ('CAD', 'Canadian Dollar', 'CA\$'),
  ('AUD', 'Australian Dollar', 'A\$'),
  ('CHF', 'Swiss Franc', 'CHF'),
  ('CNY', 'Chinese Yuan', '¥'),
  ('BRL', 'Brazilian Real', 'R\$'),
  ('MXN', 'Mexican Peso', 'MX\$'),
  ('SGD', 'Singapore Dollar', 'S\$'),
  ('HKD', 'Hong Kong Dollar', 'HK\$'),
  ('KRW', 'Korean Won', '₩'),
  ('SEK', 'Swedish Krona', 'kr'),
  ('NOK', 'Norwegian Krone', 'kr'),
  ('DKK', 'Danish Krone', 'kr'),
  ('NZD', 'New Zealand Dollar', 'NZ\$'),
  ('ZAR', 'South African Rand', 'R'),
  ('AED', 'UAE Dirham', 'د.إ'),
  ('THB', 'Thai Baht', '฿'),
];

/// Convenience: just the ISO codes (for DropdownButtonFormField etc.)
const List<String> kCurrencyCodes = [
  'USD',
  'EUR',
  'GBP',
  'INR',
  'JPY',
  'CAD',
  'AUD',
  'CHF',
  'CNY',
  'BRL',
  'MXN',
  'SGD',
  'HKD',
  'KRW',
  'SEK',
  'NOK',
  'DKK',
  'NZD',
  'ZAR',
  'AED',
  'THB'
];

/// Each record: (BCP-47 code, display name, flag emoji)
const List<(String, String, String)> kSupportedLanguages = [
  ('en', 'English', '🇺🇸'),
  ('es', 'Español', '🇪🇸'),
  ('fr', 'Français', '🇫🇷'),
  ('de', 'Deutsch', '🇩🇪'),
  ('pt', 'Português', '🇧🇷'),
  ('hi', 'हिन्दी', '🇮🇳'),
  ('ja', '日本語', '🇯🇵'),
  ('zh', '中文', '🇨🇳'),
  ('ar', 'العربية', '🇸🇦'),
  ('ko', '한국어', '🇰🇷'),
  ('it', 'Italiano', '🇮🇹'),
  ('nl', 'Nederlands', '🇳🇱'),
  ('ru', 'Русский', '🇷🇺'),
  ('tr', 'Türkçe', '🇹🇷'),
  ('pl', 'Polski', '🇵🇱'),
];

/// Returns the display name for a language code, e.g. 'en' → 'English'
String languageDisplayName(String code) =>
    kSupportedLanguages
        .where((l) => l.$1 == code)
        .map((l) => l.$2)
        .firstOrNull ??
    code;

/// Returns the symbol for a currency code, e.g. 'USD' → '\$'
String currencySymbol(String code) =>
    kSupportedCurrencies
        .where((c) => c.$1 == code)
        .map((c) => c.$3)
        .firstOrNull ??
    code;
