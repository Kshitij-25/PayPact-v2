import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paypact/core/utils/invite_code.dart';
import 'package:paypact/features/group/data/models/group_model.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';

class FirestoreGroupRepository implements GroupRepository {
  final FirebaseFirestore _firestore;

  FirestoreGroupRepository(this._firestore);

  @override
  Stream<List<GroupEntity>> watchUserGroups(String userId) {
    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => GroupModel.fromFirestore(d)).toList());
  }

  @override
  Stream<GroupEntity?> watchGroup(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .snapshots()
        .map((doc) => doc.exists ? GroupModel.fromFirestore(doc) : null);
  }

  @override
  Future<GroupEntity?> getGroup(String groupId) async {
    final doc = await _firestore.collection('groups').doc(groupId).get();
    if (!doc.exists) return null;
    return GroupModel.fromFirestore(doc);
  }

  @override
  Future<GroupEntity> createGroup({
    required String name,
    required String emoji,
    required String category,
    required String currency,
    required String createdByUid,
    required String createdByName,
  }) async {
    final model = GroupModel(
      id: '',
      name: name,
      emoji: emoji,
      category: category,
      currency: currency,
      memberIds: [createdByUid],
      memberNames: {createdByUid: createdByName},
      createdBy: createdByUid,
      adminIds: [createdByUid],
      inviteCode: generateInviteCode(),
      createdAt: DateTime.now(),
    );
    final ref = await _firestore.collection('groups').add(model.toMap());
    final doc = await ref.get();
    return GroupModel.fromFirestore(doc);
  }

  @override
  Future<void> addMember(
      String groupId, String userId, String userName) async {
    await _firestore.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
      'memberNames.$userId': userName,
    });
  }

  @override
  Future<void> removeMember(String groupId, String userId) async {
    final ref = _firestore.collection('groups').doc(groupId);
    final data = (await ref.get()).data() ?? {};
    final names = Map<String, dynamic>.from((data['memberNames'] as Map?) ?? {});
    names.remove(userId);
    // Write the whole list (never arrayRemove): on a group that predates
    // `adminIds` that would create an empty list and silently demote the creator.
    final admins = _adminsOf(data)..remove(userId);
    await ref.update({
      'memberIds': FieldValue.arrayRemove([userId]),
      'memberNames': names,
      'adminIds': admins,
    });
  }

  @override
  Future<void> setAdmin(String groupId, String userId,
      {required bool isAdmin}) async {
    final ref = _firestore.collection('groups').doc(groupId);
    final data = (await ref.get()).data() ?? {};
    final admins = _adminsOf(data);
    if (isAdmin) {
      if (!admins.contains(userId)) admins.add(userId);
    } else {
      admins.remove(userId);
    }
    await ref.update({'adminIds': admins});
  }

  List<String> _adminsOf(Map<String, dynamic> data) => data['adminIds'] is List
      ? List<String>.from(data['adminIds'] as List)
      : <String>[if (data['createdBy'] is String) data['createdBy'] as String];

  @override
  Future<String> ensureInviteCode(String groupId) async {
    final ref = _firestore.collection('groups').doc(groupId);
    final existing = (await ref.get()).data()?['inviteCode'] as String?;
    if (existing != null && existing.isNotEmpty) return existing;
    return resetInviteCode(groupId);
  }

  @override
  Future<String> resetInviteCode(String groupId) async {
    final code = generateInviteCode();
    await _firestore.collection('groups').doc(groupId).update({
      'inviteCode': code,
    });
    return code;
  }

  @override
  Future<void> updateGroup(String groupId,
      {String? name, String? emoji, String? category}) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (emoji != null) updates['emoji'] = emoji;
    if (category != null) updates['category'] = category;
    if (updates.isNotEmpty) {
      await _firestore.collection('groups').doc(groupId).update(updates);
    }
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    await _firestore.collection('groups').doc(groupId).delete();
  }
}
