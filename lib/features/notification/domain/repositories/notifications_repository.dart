import '../entities/notification_entity.dart';

abstract class NotificationsRepository {
  Stream<List<NotificationEntity>> watchNotifications(String userId);
  Future<void> markRead(String userId, String notifId);
  Future<void> markAllRead(String userId);
  Future<void> push({
    required String targetUserId,
    required String type,
    required String title,
    required String body,
    String? groupId,
    String? groupName,
    required String actorId,
    required String actorName,
  });
}
