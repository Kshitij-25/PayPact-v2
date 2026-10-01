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
    super.adminIds,
    super.inviteCode,
    super.coverUrl,
    super.customCategories,
    super.balances,
    super.totalSpentMinor,
    super.expenseCount,
    super.lastActivityAt,
    super.lastExpenseTitle,
    super.netBalance,
  });

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final memberIds = List<String>.from(data['memberIds'] as List? ?? []);
    final memberNamesRaw = data['memberNames'] as Map<String, dynamic>? ?? {};
    final memberNames = memberNamesRaw.map((k, v) => MapEntry(k, v as String));
    final createdBy = data['createdBy'] as String? ?? '';
    // Only trust the summary once the backend has marked it complete.
    final summary = data['summaryVersion'] == 1 && data['balances'] is Map;
    // Groups created before admin roles existed only have a creator.
    final adminIds = data['adminIds'] is List
        ? List<String>.from(data['adminIds'] as List)
        : <String>[createdBy];
    return GroupModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      emoji: data['emoji'] as String? ?? '✨',
      category: data['category'] as String? ?? 'other',
      currency: data['currency'] as String? ?? 'INR',
      memberIds: memberIds,
      memberNames: memberNames,
      createdBy: createdBy,
      adminIds: adminIds,
      inviteCode: data['inviteCode'] as String?,
      coverUrl: data['coverUrl'] as String?,
      customCategories: [
        for (final c in (data['customCategories'] as List? ?? []))
          if (c is Map && c['id'] is String)
            CustomCategory(
              id: c['id'] as String,
              name: c['name'] as String? ?? '',
              emoji: c['emoji'] as String? ?? '✨',
            ),
      ],
      balances: summary
          ? {
              for (final e in (data['balances'] as Map? ?? {}).entries)
                e.key as String: (e.value as num).toInt(),
            }
          : null,
      totalSpentMinor: (data['totalSpentMinor'] as num?)?.toInt(),
      expenseCount: (data['expenseCount'] as num?)?.toInt(),
      lastActivityAt: (data['lastActivityAt'] as Timestamp?)?.toDate(),
      lastExpenseTitle: data['lastExpenseTitle'] as String?,
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
        'adminIds': adminIds,
        if (inviteCode != null) 'inviteCode': inviteCode,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
