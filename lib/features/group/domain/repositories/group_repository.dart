import 'package:dartz/dartz.dart';
import 'package:paypact/core/failures/faliures.dart';
import 'package:paypact/features/auth/domain/entities/user_entity.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/group/domain/entities/member_entity.dart';

abstract class GroupRepository {
  Stream<List<GroupEntity>> watchUserGroups(String userId);

  Future<Either<Failure, GroupEntity>> getGroupById(String groupId);

  Future<Either<Failure, GroupEntity>> createGroup({
    required String name,
    required String createdBy,
    required GroupCategory category,
    String? imageUrl,
    String? currency,
    String creatorDisplayName = '',
    String creatorEmail = '',
    String? creatorPhotoUrl,
  });

  Future<Either<Failure, GroupEntity>> updateGroup(GroupEntity group);

  Future<Either<Failure, Unit>> deleteGroup(String groupId);

  Future<Either<Failure, GroupEntity>> joinGroupByInviteCode(
      String inviteCode, UserEntity userId);

  Future<Either<Failure, String>> generateInviteLink(String groupId);

  Future<Either<Failure, Unit>> addMember(String groupId, MemberEntity member);

  Future<Either<Failure, Unit>> removeMember(String groupId, String userId);

  Future<Either<Failure, Unit>> updateMemberRole(
    String groupId,
    String userId,
    MemberRole role,
  );

  /// Search for a registered user by exact email address.
  Future<Either<Failure, UserEntity?>> searchUserByEmail(String email);
}
