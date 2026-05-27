class NotificationEntity {
  final String id;
  final String type; // expense_added | member_added | settlement
  final String title;
  final String body;
  final String? groupId;
  final String? groupName;
  final String actorId;
  final String actorName;
  final bool isRead;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.groupId,
    this.groupName,
    required this.actorId,
    required this.actorName,
    required this.isRead,
    required this.createdAt,
  });

  NotificationEntity copyWith({bool? isRead}) => NotificationEntity(
        id: id,
        type: type,
        title: title,
        body: body,
        groupId: groupId,
        groupName: groupName,
        actorId: actorId,
        actorName: actorName,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}
