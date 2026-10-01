import '../entities/notification_entity.dart';

abstract class NotificationsRepository {
  Stream<List<NotificationEntity>> watchNotifications(String userId);

  /// Entries created after [since], newest first — a cheap poll (it reads only
  /// what is new) for the background check on a closed app.
  Future<List<NotificationEntity>> fetchSince(String userId, DateTime since,
      {int limit = 20});
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
