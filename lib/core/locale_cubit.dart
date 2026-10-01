import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The language the user picked (null = follow the device).
class LocaleCubit extends Cubit<Locale?> {
  LocaleCubit(this._prefs) : super(_read(_prefs));
  final SharedPreferences _prefs;

  static const _key = 'pref_locale';

  static Locale? _read(SharedPreferences prefs) {
    final code = prefs.getString(_key);
    if (code == null) return null;
    final match =
        AppLocalizations.supportedLocales.where((l) => l.languageCode == code);
    return match.isEmpty ? null : match.first;
  }

  Future<void> set(Locale? locale) async {
    if (locale == null) {
      await _prefs.remove(_key);
    } else {
      await _prefs.setString(_key, locale.languageCode);
    }
    emit(locale);
  }
}
