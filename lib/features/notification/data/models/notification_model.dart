import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paypact/features/notification/domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.type,
    required super.title,
    required super.body,
    super.groupId,
    super.groupName,
    required super.actorId,
    required super.actorName,
    required super.isRead,
    required super.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      type: d['type'] as String? ?? '',
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      groupId: d['groupId'] as String?,
      groupName: d['groupName'] as String?,
      actorId: d['actorId'] as String? ?? '',
      actorName: d['actorName'] as String? ?? '',
      isRead: d['isRead'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type,
        'title': title,
        'body': body,
        'groupId': groupId,
        'groupName': groupName,
        'actorId': actorId,
        'actorName': actorName,
        'isRead': isRead,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
