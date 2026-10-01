import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/utils/currency_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user's chosen default currency (Settings → Currency), used for
/// cross-group totals and as the fallback anywhere a currency is unknown.
String userDefaultCurrency() {
  try {
    return locator<SharedPreferences>().getString(kPrefCurrencyKey) ??
        kDefaultCurrency;
  } catch (_) {
    return kDefaultCurrency;
  }
}
