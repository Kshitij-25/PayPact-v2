import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shows device notifications for events from the person's Firestore inbox.
///
/// There is no push service behind this (FCM needs a server to send, which the
/// free Firebase plan doesn't include). [InboxWatcher] listens to the inbox and
/// calls [showLocalNotification]; this class owns the plugin, the permission
/// prompt and what happens when a notification is tapped.
class NotificationService {
  static final _localNotif = FlutterLocalNotificationsPlugin();

  static const channelId = 'paypact_default';
  static const channelName = 'PayPact Notifications';
  static const channelDesc = 'Expense and settlement alerts';

  /// Called when the user taps a notification, with its data payload
  /// (`type`, `groupId`, …). The app sets this to navigate.
  void Function(Map<String, dynamic> data)? onOpen;

  void _open(Map<String, dynamic> data) => onOpen?.call(data);

  /// Notifications can't be raised from a browser tab in the background, so
  /// on the web the in-app inbox is the only surface.
  bool get supported => !kIsWeb;

  Future<void> initialize() async {
    if (!supported) return;
    try {
      await initPlugin(onTap: _onTap);

      // Launched by tapping a notification while the app was closed.
      final launch = await _localNotif.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _onTap(launch!.notificationResponse);
      }

      await _requestPermission();
    } catch (e) {
      debugPrint('NotificationService.initialize failed: $e');
    }
  }

  void _onTap(NotificationResponse? response) {
    final payload = response?.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      _open(Map<String, dynamic>.from(jsonDecode(payload) as Map));
    } catch (_) {}
  }

  /// Sets the plugin up. Also used by the background isolate, which has no
  /// [NotificationService] instance of its own.
  static Future<void> initPlugin(
      {void Function(NotificationResponse?)? onTap}) async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotif.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: onTap,
    );
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDesc,
            importance: Importance.high,
          ),
        );
  }

  Future<void> _requestPermission() async {
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _localNotif
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    int id = 0,
    Map<String, dynamic>? data,
  }) =>
      show(title: title, body: body, id: id, data: data);

  static Future<void> show({
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
          channelId,
          channelName,
          channelDescription: channelDesc,
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
}
