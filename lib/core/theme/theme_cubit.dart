import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const _key = 'theme_mode';
  final SharedPreferences _prefs;

  ThemeCubit(this._prefs) : super(_fromString(_prefs.getString(_key)));

  /// Honours a saved preference. When nothing has been chosen yet, web
  /// defaults to light (the user can switch in settings); other platforms
  /// follow the system setting.
  static ThemeMode _fromString(String? v) => switch (v) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => kIsWeb ? ThemeMode.light : ThemeMode.system,
      };

  Future<void> set(ThemeMode mode) async {
    await _prefs.setString(_key, mode.name);
    emit(mode);
  }
}
