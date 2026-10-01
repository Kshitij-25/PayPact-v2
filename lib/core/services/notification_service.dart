import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // FCM auto-displays the notification on mobile when app is in background/terminated.
  // Nothing extra needed here.
}

class NotificationService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  static final _localNotif = FlutterLocalNotificationsPlugin();

  static const _androidChannelId = 'paypact_default';
  static const _androidChannelName = 'PayPact Notifications';
  static const _androidChannelDesc = 'Expense and settlement alerts';

  NotificationService(this._messaging, this._firestore);

  /// Called when the user taps a notification, with its data payload
  /// (`type`, `groupId`, …). The app sets this to navigate.
  void Function(Map<String, dynamic> data)? onOpen;

  void _open(Map<String, dynamic> data) => onOpen?.call(data);

  Future<void> initialize() async {
    try {
      if (kIsWeb) {
        // Web push needs the Notification API + a service worker, which many
        // mobile browsers (notably iOS Safari outside an installed PWA) don't
        // support. Bail out there so we never prompt for — or crash on —
        // notification permissions, which would otherwise blank the page.
        if (!await _messaging.isSupported()) return;
        await _messaging.requestPermission(alert: true, badge: true, sound: true);
        return;
      }

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      await _initLocalNotifications();

      // Tapping a push (app in background) or launching the app from one.
      FirebaseMessaging.onMessageOpenedApp.listen((m) => _open(m.data));
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _open(initial.data);

      await _messaging.requestPermission(alert: true, badge: true, sound: true);

      // Show a local notification for foreground FCM messages (mobile only).
      FirebaseMessaging.onMessage.listen((message) {
        final n = message.notification;
        if (n != null) {
          showLocalNotification(
              title: n.title ?? '', body: n.body ?? '', data: message.data);
        }
      });
    } catch (e) {
      debugPrint('NotificationService.initialize failed: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotif.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      // Tapping the banner shown for a push that arrived while the app was open.
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          _open(Map<String, dynamic>.from(jsonDecode(payload) as Map));
        } catch (_) {}
      },
    );

    final androidImpl = _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description: _androidChannelDesc,
        importance: Importance.high,
      ),
    );
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    int id = 0,
    Map<String, dynamic>? data,
  }) async {
    if (kIsWeb) return;
    await _localNotif.show(
      id: id,
      title: title,
      body: body,
      payload: data == null ? null : jsonEncode(data),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Tokens live under `users/{uid}/private/push`, readable only by their
  /// owner (and the Cloud Functions that send pushes) — never on the public
  /// profile document. Any legacy token on the profile is scrubbed.
  Future<void> _writeToken(String userId, String token) async {
    final user = _firestore.collection('users').doc(userId);
    await user.collection('private').doc('push').set({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await user.set({
      'fcmToken': FieldValue.delete(),
      'fcmTokenUpdatedAt': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  /// Called before sign-out (while the user can still write) so the next
  /// person to sign in on this device doesn't leave pushes going to the last.
  Future<void> clearToken(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('private')
          .doc('push')
          .delete();
      await _messaging.deleteToken();
    } catch (_) {
      // Best-effort; a stale token is dropped by the push function on failure.
    }
  }

  Future<void> saveToken(String userId) async {
    try {
      if (kIsWeb && !await _messaging.isSupported()) return;
      final token = kIsWeb
          ? await _messaging.getToken(
              vapidKey:
                  'BL0m9V9R4zE-dRv3kl7PD3YVVcl0Niq8K_FQlNBkUibsUEyPJxeSmH7OQJQ4OmpO3fMCL7j2t5JkzBJhJfJT1Qc',
            )
          : await _messaging.getToken();

      if (token == null) return;

      await _writeToken(userId, token);

      _messaging.onTokenRefresh.listen((newToken) => _writeToken(userId, newToken));
    } catch (_) {
      // Token saving is best-effort
    }
  }
}
