import 'package:dartz/dartz.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:paypact/core/failures/faliures.dart';
import 'package:paypact/features/notification/domain/repositories/notification_repository.dart';

class FirebaseNotificationRepository implements NotificationRepository {
  FirebaseNotificationRepository({required FirebaseMessaging messaging})
      : _messaging = messaging;

  final FirebaseMessaging _messaging;

  @override
  Future<Either<Failure, String?>> getFcmToken() async {
    try {
      final token = await _messaging.getToken();
      return Right(token);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return const Left(PermissionFailure('Notification permission denied'));
      }
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Map<String, dynamic>> get onMessageReceived =>
      FirebaseMessaging.onMessage.map((msg) => {
            'title': msg.notification?.title,
            'body': msg.notification?.body,
            'data': msg.data,
          });

  @override
  Stream<Map<String, dynamic>> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp.map((msg) => {
            'title': msg.notification?.title,
            'body': msg.notification?.body,
            'data': msg.data,
          });

  @override
  Future<Either<Failure, Unit>> sendExpenseNotification({
    required String groupId,
    required String expenseTitle,
    required double amount,
    required List<String> memberTokens,
    required String addedBy,
  }) async {
    // NOTE: In production, this is done via Cloud Functions.
    // The client triggers the function, which dispatches FCM messages.
    // This stub represents the client-side contract.
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> sendSettlementNotification({
    required String toUserToken,
    required String fromUserName,
    required double amount,
  }) async {
    // Same — dispatched via Cloud Functions
    return const Right(unit);
  }
}
