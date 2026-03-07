import 'package:paypact/domain/entities/member_entity.dart';

class MemberModel {
  const MemberModel({
    required this.userId,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.joinedAt,
    required this.role,
    required this.balance,
  });

  final String userId;
  final String displayName;
  final String email;
  final String? photoUrl;
  final DateTime joinedAt;
  final String role;
  final double balance;

  factory MemberModel.fromMap(Map<String, dynamic> map) => MemberModel(
        userId: map['userId'] as String,
        displayName: map['displayName'] as String? ?? '',
        email: map['email'] as String? ?? '',
        photoUrl: map['photoUrl'] as String?,
        joinedAt: map['joinedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                (map['joinedAt'] as dynamic).millisecondsSinceEpoch as int)
            : DateTime.now(),
        role: map['role'] as String? ?? 'member',
        balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'joinedAt': joinedAt,
        'role': role,
        'balance': balance,
      };

  MemberEntity toEntity() => MemberEntity(
        userId: userId,
        displayName: displayName,
        email: email,
        photoUrl: photoUrl,
        joinedAt: joinedAt,
        role: role == 'admin' ? MemberRole.admin : MemberRole.member,
        balance: balance,
      );

  factory MemberModel.fromEntity(MemberEntity e) => MemberModel(
        userId: e.userId,
        displayName: e.displayName,
        email: e.email,
        photoUrl: e.photoUrl,
        joinedAt: e.joinedAt,
        role: e.role == MemberRole.admin ? 'admin' : 'member',
        balance: e.balance,
      );
}
