import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:paypact/core/failures/faliures.dart';
import 'package:paypact/features/auth/data/models/user_model.dart';
import 'package:paypact/features/auth/domain/entities/user_entity.dart';
import 'package:paypact/features/group/data/models/group_model.dart';
import 'package:paypact/features/group/data/models/member_model.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/group/domain/entities/member_entity.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:uuid/uuid.dart';

class FirebaseGroupRepository implements GroupRepository {
  FirebaseGroupRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const _groups = 'groups';

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(_groups);

  // ── BUG FIX #1: Query the flat `memberIds` string array instead of
  // arrayContains on the nested `members` map array. Firestore's
  // arrayContains on maps requires an exact full-object match, which
  // means partial {userId: x} never matches. A flat string array is
  // the correct and reliable pattern.
  @override
  Stream<List<GroupEntity>> watchUserGroups(String userId) {
    return _col
        .where('memberIds', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => GroupModel.fromFirestore(d.data(), d.id).toEntity())
            .toList());
  }

  @override
  Future<Either<Failure, GroupEntity>> getGroupById(String groupId) async {
    try {
      final doc = await _col.doc(groupId).get();
      if (!doc.exists) return const Left(NotFoundFailure('Group not found'));
      return Right(GroupModel.fromFirestore(doc.data()!, doc.id).toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── BUG FIX #2: createGroup now adds the creator as the first member
  // with role admin, and populates `memberIds`. Without this the stream
  // query above never returns the new group because the creator's ID is
  // absent from `memberIds`.
  @override
  Future<Either<Failure, GroupEntity>> createGroup({
    required String name,
    required String createdBy,
    required GroupCategory category,
    String? imageUrl,
    String? currency,
    // Optional: pass the creator's profile so we can embed their member record.
    String creatorDisplayName = '',
    String creatorEmail = '',
    String? creatorPhotoUrl,
  }) async {
    try {
      final inviteCode = const Uuid().v4().substring(0, 8).toUpperCase();
      final ref = _col.doc();

      final creatorMember = MemberModel(
        userId: createdBy,
        displayName: creatorDisplayName,
        email: creatorEmail,
        photoUrl: creatorPhotoUrl,
        joinedAt: DateTime.now(),
        role: 'admin',
        balance: 0.0,
      );

      final model = GroupModel(
        id: ref.id,
        name: name,
        createdBy: createdBy,
        members: [creatorMember],
        memberIds: [createdBy],
        createdAt: DateTime.now(),
        imageUrl: imageUrl,
        category: category.name,
        inviteCode: inviteCode,
        totalExpenses: 0,
        currency: currency ?? 'USD',
      );

      await ref.set(model.toFirestore());
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GroupEntity>> updateGroup(GroupEntity group) async {
    try {
      final model = GroupModel.fromEntity(group);
      await _col.doc(group.id).update(model.toFirestore());
      return Right(group);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteGroup(String groupId) async {
    try {
      await _col.doc(groupId).delete();
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GroupEntity>> joinGroupByInviteCode(
    String inviteCode,
    UserEntity user,
  ) async {
    try {
      final snap =
          await _col.where('inviteCode', isEqualTo: inviteCode).limit(1).get();
      if (snap.docs.isEmpty) {
        return const Left(NotFoundFailure('Invalid invite code'));
      }
      final doc = snap.docs.first;
      final group = GroupModel.fromFirestore(doc.data(), doc.id).toEntity();
      if (group.isMember(user.id)) return Right(group);
      return Left(const ValidationFailure('Already a member'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> generateInviteLink(String groupId) async {
    try {
      final doc = await _col.doc(groupId).get();
      if (!doc.exists) return const Left(NotFoundFailure('Group not found'));
      final inviteCode = doc.data()!['inviteCode'] as String? ?? '';
      // Use custom URI scheme so the OS routes directly to the app.
      // https:// links require domain ownership + App Links / Universal Links
      // verification. paypact:// works immediately on both platforms with
      // just the native manifest/plist configuration below.
      return Right('paypact://invite/$inviteCode');
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Keep memberIds in sync whenever members change ──────────────────────

  @override
  Future<Either<Failure, Unit>> addMember(
    String groupId,
    MemberEntity member,
  ) async {
    try {
      await _col.doc(groupId).update({
        'members':
            FieldValue.arrayUnion([MemberModel.fromEntity(member).toMap()]),
        // Also update the flat ID list so the stream query stays in sync
        'memberIds': FieldValue.arrayUnion([member.userId]),
      });
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeMember(
    String groupId,
    String userId,
  ) async {
    try {
      final doc = await _col.doc(groupId).get();
      if (!doc.exists) return const Left(NotFoundFailure('Group not found'));
      final group = GroupModel.fromFirestore(doc.data()!, doc.id).toEntity();
      final updatedMembers = group.members
          .where((m) => m.userId != userId)
          .map((m) => MemberModel.fromEntity(m).toMap())
          .toList();
      final updatedMemberIds = group.members
          .where((m) => m.userId != userId)
          .map((m) => m.userId)
          .toList();
      await _col.doc(groupId).update({
        'members': updatedMembers,
        'memberIds': updatedMemberIds,
      });
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateMemberRole(
    String groupId,
    String userId,
    MemberRole role,
  ) async {
    try {
      final doc = await _col.doc(groupId).get();
      if (!doc.exists) return const Left(NotFoundFailure('Group not found'));
      final group = GroupModel.fromFirestore(doc.data()!, doc.id).toEntity();
      final updatedMembers = group.members
          .map((m) {
            if (m.userId == userId) return m.copyWith(role: role);
            return m;
          })
          .map((m) => MemberModel.fromEntity(m).toMap())
          .toList();
      // memberIds doesn't change on a role update
      await _col.doc(groupId).update({'members': updatedMembers});
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> searchUserByEmail(String email) async {
    try {
      final snap = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return const Right(null);
      final doc = snap.docs.first;
      return Right(UserModel.fromFirestore(doc.data(), doc.id).toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
