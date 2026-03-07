import 'package:paypact/domain/entities/user_entity.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.fcmToken,
  });

  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final String? fcmToken;

  factory UserModel.fromFirestore(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['createdAt'] as dynamic).millisecondsSinceEpoch as int)
          : DateTime.now(),
      fcmToken: map['fcmToken'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'createdAt': createdAt,
        'fcmToken': fcmToken,
      };

  UserEntity toEntity() => UserEntity(
        id: id,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        createdAt: createdAt,
        fcmToken: fcmToken,
      );

  factory UserModel.fromEntity(UserEntity entity) => UserModel(
        id: entity.id,
        email: entity.email,
        displayName: entity.displayName,
        photoUrl: entity.photoUrl,
        createdAt: entity.createdAt,
        fcmToken: entity.fcmToken,
      );
}
