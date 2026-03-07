import 'package:dartz/dartz.dart';
import 'package:paypact/core/failures/faliures.dart';

abstract class NotificationRepository {
  Future<Either<Failure, String?>> getFcmToken();

  Future<Either<Failure, Unit>> requestPermission();

  Stream<Map<String, dynamic>> get onMessageReceived;

  Stream<Map<String, dynamic>> get onMessageOpenedApp;

  Future<Either<Failure, Unit>> sendExpenseNotification({
    required String groupId,
    required String expenseTitle,
    required double amount,
    required List<String> memberTokens,
    required String addedBy,
  });

  Future<Either<Failure, Unit>> sendSettlementNotification({
    required String toUserToken,
    required String fromUserName,
    required double amount,
  });
}
