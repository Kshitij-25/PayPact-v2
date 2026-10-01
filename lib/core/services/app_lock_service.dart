import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "App lock": require Face ID / fingerprint / device passcode to open the app
/// after it has been in the background for a while. The setting is per-device.
class AppLockService {
  AppLockService(this._prefs, [LocalAuthentication? auth])
      : _auth = auth ?? LocalAuthentication();

  final SharedPreferences _prefs;
  final LocalAuthentication _auth;

  static const _key = 'app_lock_enabled';

  /// Leaving the app briefly (a notification, a UPI app) shouldn't lock it.
  static const gracePeriod = Duration(seconds: 30);

  bool get enabled => !kIsWeb && (_prefs.getBool(_key) ?? false);

  /// Whether this device has any screen lock / biometrics to unlock with.
  Future<bool> get supported async {
    if (kIsWeb) return false;
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<void> setEnabled(bool value) => _prefs.setBool(_key, value);

  /// Prompts the system's authentication UI. False if cancelled or failed.
  Future<bool> authenticate([String reason = 'Unlock PayPact']) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  /// Whether returning to the app after [away] should ask to unlock again.
  bool shouldLockAfter(Duration away) => enabled && away >= gracePeriod;
}
