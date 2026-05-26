import 'package:cloud_firestore/cloud_firestore.dart';
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
  Future<void> deleteGroup(String groupId) async {
    await _firestore.collection('groups').doc(groupId).delete();
  }
}
