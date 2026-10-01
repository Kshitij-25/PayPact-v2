import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:paypact/core/services/notification_service.dart';
import 'package:paypact/features/notification/domain/entities/notification_entity.dart';
import 'package:paypact/features/notification/domain/inbox_delivery.dart';
import 'package:paypact/features/notification/domain/repositories/notifications_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Turns the live Firestore inbox into device notifications.
///
/// Whoever causes an event (an expense, a payment, a reminder) writes a
/// document to the affected person's `users/{uid}/notifications`. While the
/// app is running — in the foreground or kept alive in the background — this
/// listener sees it the moment it lands and raises a local notification; when
/// the app was closed, the same check runs on launch and resume, so nothing
/// is missed, only delayed until the app next wakes.
class InboxWatcher {
  InboxWatcher(this._repo, this._prefs, {DateTime Function()? now, Shower? show})
      : _now = now ?? DateTime.now,
        _show = show ?? _defaultShow;

  /// Shows one notification; replaceable in tests.
  static Future<void> _defaultShow(
          {required String title,
          required String body,
          required int id,
          required Map<String, dynamic> data}) =>
      NotificationService.show(title: title, body: body, id: id, data: data);

  final NotificationsRepository _repo;
  final SharedPreferences _prefs;
  final DateTime Function() _now;
  final Shower _show;

  StreamSubscription<List<NotificationEntity>>? _sub;
  String? _uid;

  /// Beyond this many at once, one summary replaces the individual alerts.
  static const maxIndividual = 3;
  static const _rememberLimit = 200;

  static String shownKey(String uid) => 'shown_notifs_$uid';

  void start(String uid) {
    if (_uid == uid && _sub != null) return;
    stop();
    _uid = uid;
    _sub = _repo.watchNotifications(uid).listen(
          (inbox) => process(uid, inbox),
          onError: (Object e) => debugPrint('Inbox watcher error: $e'),
        );
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _uid = null;
  }

  /// Shows whatever in [inbox] is new. Visible for testing.
  Future<int> process(String uid, List<NotificationEntity> inbox) async {
    // The background check (another isolate) records what it showed too.
    await _prefs.reload();
    final shown = (_prefs.getStringList(shownKey(uid)) ?? const <String>[]);
    final fresh = pickToShow(
        inbox: inbox, alreadyShown: shown.toSet(), now: _now());
    if (fresh.isEmpty) return 0;

    // Remember before showing so an overlapping snapshot can't repeat them.
    final remembered = [...shown, ...fresh.map((n) => n.id)];
    await _prefs.setStringList(
        shownKey(uid),
        remembered.length > _rememberLimit
            ? remembered.sublist(remembered.length - _rememberLimit)
            : remembered);

    try {
      if (fresh.length <= maxIndividual) {
        for (final n in fresh) {
          await _show(
            title: n.title,
            body: n.body,
            id: n.id.hashCode & 0x7fffffff,
            data: {'type': n.type, 'groupId': n.groupId},
          );
        }
      } else {
        await _show(
          title: 'PayPact',
          body: '${fresh.length} new updates',
          id: 1,
          data: const {'type': 'summary'},
        );
      }
    } catch (e) {
      debugPrint('Showing notifications failed: $e');
    }
    return fresh.length;
  }
}

typedef Shower = Future<void> Function(
    {required String title,
    required String body,
    required int id,
    required Map<String, dynamic> data});
