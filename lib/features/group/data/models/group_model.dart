import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';

class GroupModel extends GroupEntity {
  GroupModel({
    required super.id,
    required super.name,
    required super.emoji,
    required super.category,
    required super.currency,
    required super.memberIds,
    required super.memberNames,
    required super.createdBy,
    required super.createdAt,
    super.netBalance,
  });

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final memberIds = List<String>.from(data['memberIds'] as List? ?? []);
    final memberNamesRaw = data['memberNames'] as Map<String, dynamic>? ?? {};
    final memberNames = memberNamesRaw.map((k, v) => MapEntry(k, v as String));
    return GroupModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      emoji: data['emoji'] as String? ?? '✨',
      category: data['category'] as String? ?? 'other',
      currency: data['currency'] as String? ?? 'INR',
      memberIds: memberIds,
      memberNames: memberNames,
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'emoji': emoji,
        'category': category,
        'currency': currency,
        'memberIds': memberIds,
        'memberNames': memberNames,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
