import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Crash reporting and (opt-in) analytics, both controlled from Settings.
///
///  * Crash reports are on by default — they're how real-world failures get
///    noticed — and can be switched off.
///  * Usage analytics are OFF until the user turns them on.
class TelemetryService {
  TelemetryService(this._prefs);
  final SharedPreferences _prefs;

  static const analyticsKey = 'pref_analytics';
  static const crashKey = 'pref_crash_reports';

  bool get analyticsEnabled => _prefs.getBool(analyticsKey) ?? false;
  bool get crashReportsEnabled => _prefs.getBool(crashKey) ?? true;

  /// Crashlytics doesn't support the web; there errors just print.
  bool get _crashlyticsAvailable => !kIsWeb;

  Future<void> init() async {
    try {
      if (_crashlyticsAvailable) {
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(crashReportsEnabled);
      }
      await FirebaseAnalytics.instance
          .setAnalyticsCollectionEnabled(analyticsEnabled);
    } catch (e) {
      debugPrint('Telemetry init failed: $e');
    }

    // Always show the error in debug output; only *send* it if allowed. The
    // setting is read at the time of the error, so toggling applies at once.
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (_crashlyticsAvailable && crashReportsEnabled) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      }
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      if (_crashlyticsAvailable && crashReportsEnabled) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
      return true;
    };
  }

  Future<void> setAnalytics(bool enabled) async {
    await _prefs.setBool(analyticsKey, enabled);
    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
    } catch (_) {}
  }

  Future<void> setCrashReports(bool enabled) async {
    await _prefs.setBool(crashKey, enabled);
    if (!_crashlyticsAvailable) return;
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enabled);
    } catch (_) {}
  }

  /// A handled problem worth knowing about (not a crash).
  void recordError(Object error, StackTrace? stack, {String? reason}) {
    if (_crashlyticsAvailable && crashReportsEnabled) {
      FirebaseCrashlytics.instance.recordError(error, stack, reason: reason);
    }
  }

  /// Product event (only sent when analytics are switched on). No amounts,
  /// names or other personal content — just that something happened.
  void event(String name, [Map<String, Object>? params]) {
    if (!analyticsEnabled) return;
    FirebaseAnalytics.instance
        .logEvent(name: name, parameters: params)
        .catchError((_) {});
  }
}
