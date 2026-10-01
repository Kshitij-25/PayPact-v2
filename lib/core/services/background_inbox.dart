import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:paypact/core/services/inbox_watcher.dart';
import 'package:paypact/core/services/notification_service.dart';
import 'package:paypact/features/notification/data/repositories/firestore_notifications_repository.dart';
import 'package:paypact/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

const _uniqueName = 'paypact_inbox_check';
const _taskName = 'paypact.inbox.check';

/// Entry point Android runs (in its own isolate) every ~15 minutes.
@pragma('vm:entry-point')
void backgroundInboxDispatcher() {
  Workmanager().executeTask((task, input) async {
    try {
      await BackgroundInbox.checkOnce();
    } catch (e) {
      debugPrint('Background inbox check failed: $e');
    }
    return true; // never ask for a retry storm; the next period tries again
  });
}

/// A periodic inbox check for when the app is closed.
///
/// Without a push service the only way to hear about something while the app
/// is not running is to look. Android lets an app do that about every 15
/// minutes (batched by the system, and paused in Doze), so a notification can
/// arrive up to ~15+ minutes late, but it does arrive. iOS offers nothing
/// comparable, so there delivery happens when the app is next opened.
class BackgroundInbox {
  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static const interval = Duration(minutes: 15);

  static Future<void> schedule() async {
    if (!supported) return;
    try {
      await Workmanager().initialize(backgroundInboxDispatcher);
      await Workmanager().registerPeriodicTask(
        _uniqueName,
        _taskName,
        frequency: interval,
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } catch (e) {
      debugPrint('Scheduling the background inbox check failed: $e');
    }
  }

  static Future<void> cancel() async {
    if (!supported) return;
    try {
      await Workmanager().cancelByUniqueName(_uniqueName);
    } catch (_) {}
  }

  static String _sinceKey(String uid) => 'bg_inbox_since_$uid';

  /// Where to start looking: after the last check, a little earlier to allow
  /// for server timestamps landing out of order, never older than a day.
  @visibleForTesting
  static DateTime sinceFor(int? lastMs, DateTime now) {
    final floor = now.subtract(const Duration(hours: 24));
    if (lastMs == null) return floor;
    final last = DateTime.fromMillisecondsSinceEpoch(lastMs)
        .subtract(const Duration(minutes: 2));
    return last.isBefore(floor) ? floor : last;
  }

  /// One pass, run in the background isolate: fetch what's new, show it.
  static Future<void> checkOnce() async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // The saved session loads asynchronously in a fresh isolate.
    final user = FirebaseAuth.instance.currentUser ??
        await FirebaseAuth.instance
            .authStateChanges()
            .first
            .timeout(const Duration(seconds: 10), onTimeout: () => null);
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // pick up what the foreground app already showed
    final now = DateTime.now();
    final repo = FirestoreNotificationsRepository(FirebaseFirestore.instance);
    final fresh = await repo.fetchSince(
        user.uid, sinceFor(prefs.getInt(_sinceKey(user.uid)), now));
    if (fresh.isEmpty) return;

    await NotificationService.initPlugin();
    await InboxWatcher(repo, prefs).process(user.uid, fresh);
    await prefs.setInt(
        _sinceKey(user.uid),
        fresh
            .map((n) => n.createdAt)
            .reduce((a, b) => a.isAfter(b) ? a : b)
            .millisecondsSinceEpoch);
  }
}
