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

      await _messaging.requestPermission(alert: true, badge: true, sound: true);

      // Show a local notification for foreground FCM messages (mobile only).
      FirebaseMessaging.onMessage.listen((message) {
        final n = message.notification;
        if (n != null) {
          showLocalNotification(title: n.title ?? '', body: n.body ?? '');
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
  }) async {
    if (kIsWeb) return;
    await _localNotif.show(
      id: id,
      title: title,
      body: body,
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

      await _firestore.collection('users').doc(userId).set(
        {
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _messaging.onTokenRefresh.listen((newToken) {
        _firestore.collection('users').doc(userId).set(
          {
            'fcmToken': newToken,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
    } catch (_) {
      // Token saving is best-effort
    }
  }
}
