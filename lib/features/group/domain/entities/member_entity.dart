import 'package:equatable/equatable.dart';

enum MemberRole { admin, member }

class MemberEntity extends Equatable {
  const MemberEntity({
    required this.userId,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.joinedAt,
    this.role = MemberRole.member,
    this.balance = 0.0,
  });

  final String userId;
  final String displayName;
  final String email;
  final String? photoUrl;
  final DateTime joinedAt;
  final MemberRole role;

  /// Positive = owed money, Negative = owes money
  final double balance;

  bool get isAdmin => role == MemberRole.admin;

  bool get isInDebt => balance < 0;

  bool get isOwed => balance > 0;

  bool get isSettled => balance == 0;

  MemberEntity copyWith({
    String? userId,
    String? displayName,
    String? email,
    String? photoUrl,
    DateTime? joinedAt,
    MemberRole? role,
    double? balance,
  }) {
    return MemberEntity(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      joinedAt: joinedAt ?? this.joinedAt,
      role: role ?? this.role,
      balance: balance ?? this.balance,
    );
  }

  @override
  List<Object?> get props =>
      [userId, displayName, email, photoUrl, joinedAt, role, balance];
}
