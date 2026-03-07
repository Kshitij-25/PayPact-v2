import 'package:equatable/equatable.dart';

import 'member_entity.dart';

enum GroupCategory { home, trip, couple, friends, work, other }

class GroupEntity extends Equatable {
  const GroupEntity({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.members,
    required this.createdAt,
    this.imageUrl,
    this.category = GroupCategory.other,
    this.inviteCode,
    this.totalExpenses = 0.0,
    this.currency = 'USD',
  });

  final String id;
  final String name;
  final String createdBy;
  final List<MemberEntity> members;
  final DateTime createdAt;
  final String? imageUrl;
  final GroupCategory category;
  final String? inviteCode;
  final double totalExpenses;
  final String currency;

  bool get hasMembers => members.isNotEmpty;

  int get memberCount => members.length;

  bool isMember(String userId) => members.any((m) => m.userId == userId);

  MemberEntity? getMember(String userId) {
    try {
      return members.firstWhere((m) => m.userId == userId);
    } catch (_) {
      return null;
    }
  }

  GroupEntity copyWith({
    String? id,
    String? name,
    String? createdBy,
    List<MemberEntity>? members,
    DateTime? createdAt,
    String? imageUrl,
    GroupCategory? category,
    String? inviteCode,
    double? totalExpenses,
    String? currency,
  }) {
    return GroupEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      inviteCode: inviteCode ?? this.inviteCode,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      currency: currency ?? this.currency,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        createdBy,
        members,
        createdAt,
        imageUrl,
        category,
        inviteCode,
        totalExpenses,
        currency
      ];
}
