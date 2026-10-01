import 'package:paypact/features/notification/domain/entities/notification_entity.dart';

/// Decides which inbox entries should pop up as device notifications.
///
/// With no push service on the free plan, delivery is the app itself watching
/// the person's inbox in Firestore: anything unread that hasn't been shown yet
/// is shown. Entries older than [freshness] are left to the in-app inbox — a
/// fresh install or a long absence mustn't produce a burst of stale alerts.
List<NotificationEntity> pickToShow({
  required List<NotificationEntity> inbox,
  required Set<String> alreadyShown,
  required DateTime now,
  Duration freshness = const Duration(hours: 24),
}) {
  final picked = [
    for (final n in inbox)
      if (!n.isRead &&
          !alreadyShown.contains(n.id) &&
          now.difference(n.createdAt) <= freshness)
        n,
  ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return picked;
}
