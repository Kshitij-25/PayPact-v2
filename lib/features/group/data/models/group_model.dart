import 'package:paypact/features/group/data/models/member_model.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';

class GroupModel {
  const GroupModel({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.members,
    required this.createdAt,
    this.imageUrl,
    required this.category,
    this.inviteCode,
    required this.totalExpenses,
    required this.currency,
    required this.memberIds,
  });

  final String id;
  final String name;
  final String createdBy;
  final List<MemberModel> members;
  final DateTime createdAt;
  final String? imageUrl;
  final String category;
  final String? inviteCode;
  final double totalExpenses;
  final String currency;

  /// Flat list of user IDs — used for efficient Firestore arrayContains queries.
  /// Firestore cannot query inside nested maps reliably; this field solves that.
  final List<String> memberIds;

  factory GroupModel.fromFirestore(Map<String, dynamic> map, String id) {
    final rawMembers = map['members'] as List<dynamic>? ?? [];
    final parsedMembers = rawMembers
        .map((m) => MemberModel.fromMap(m as Map<String, dynamic>))
        .toList();

    // Derive memberIds from the members array if the field is missing
    // (backward-compatible with docs written before this fix)
    final rawMemberIds = map['memberIds'] as List<dynamic>?;
    final memberIds = rawMemberIds != null
        ? rawMemberIds.cast<String>()
        : parsedMembers.map((m) => m.userId).toList();

    return GroupModel(
      id: id,
      name: map['name'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      members: parsedMembers,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['createdAt'] as dynamic).millisecondsSinceEpoch as int)
          : DateTime.now(),
      imageUrl: map['imageUrl'] as String?,
      category: map['category'] as String? ?? 'other',
      inviteCode: map['inviteCode'] as String?,
      totalExpenses: (map['totalExpenses'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'USD',
      memberIds: memberIds,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'createdBy': createdBy,
        'members': members.map((m) => m.toMap()).toList(),
        'memberIds': memberIds,
        'createdAt': createdAt,
        'imageUrl': imageUrl,
        'category': category,
        'inviteCode': inviteCode,
        'totalExpenses': totalExpenses,
        'currency': currency,
      };

  GroupEntity toEntity() => GroupEntity(
        id: id,
        name: name,
        createdBy: createdBy,
        members: members.map((m) => m.toEntity()).toList(),
        createdAt: createdAt,
        imageUrl: imageUrl,
        category: _categoryFromString(category),
        inviteCode: inviteCode,
        totalExpenses: totalExpenses,
        currency: currency,
      );

  static GroupCategory _categoryFromString(String s) {
    return GroupCategory.values.firstWhere(
      (c) => c.name == s,
      orElse: () => GroupCategory.other,
    );
  }

  factory GroupModel.fromEntity(GroupEntity e) => GroupModel(
        id: e.id,
        name: e.name,
        createdBy: e.createdBy,
        members: e.members.map(MemberModel.fromEntity).toList(),
        createdAt: e.createdAt,
        imageUrl: e.imageUrl,
        category: e.category.name,
        inviteCode: e.inviteCode,
        totalExpenses: e.totalExpenses,
        currency: e.currency,
        memberIds: e.members.map((m) => m.userId).toList(),
      );
}
