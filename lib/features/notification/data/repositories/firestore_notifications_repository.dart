import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paypact/features/notification/data/models/notification_model.dart';
import 'package:paypact/features/notification/domain/entities/notification_entity.dart';
import 'package:paypact/features/notification/domain/notification_prefs.dart';
import 'package:paypact/features/notification/domain/repositories/notifications_repository.dart';

class FirestoreNotificationsRepository implements NotificationsRepository {
  final FirebaseFirestore _firestore;

  FirestoreNotificationsRepository(this._firestore);

  CollectionReference _notifRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('notifications');

  @override
  Stream<List<NotificationEntity>> watchNotifications(String userId) {
    return _notifRef(userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => NotificationModel.fromFirestore(d)).toList());
  }

  @override
  Future<void> markRead(String userId, String notifId) async {
    await _notifRef(userId).doc(notifId).update({'isRead': true});
  }

  @override
  Future<void> markAllRead(String userId) async {
    final snap = await _notifRef(userId)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  @override
  Future<void> push({
    required String targetUserId,
    required String type,
    required String title,
    required String body,
    String? groupId,
    String? groupName,
    required String actorId,
    required String actorName,
  }) async {
    // Respect the recipient's preferences / muted groups. If their profile
    // can't be read, deliver rather than silently drop the notification.
    try {
      final data =
          (await _firestore.collection('users').doc(targetUserId).get()).data();
      if (!shouldDeliver(type: type, groupId: groupId, userData: data)) return;
    } catch (_) {}

    await _notifRef(targetUserId).add(NotificationModel(
      id: '',
      type: type,
      title: title,
      body: body,
      groupId: groupId,
      groupName: groupName,
      actorId: actorId,
      actorName: actorName,
      isRead: false,
      createdAt: DateTime.now(),
    ).toMap());
  }
}
