import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paypact/core/utils/invite_code.dart';
import 'package:paypact/features/group/data/models/group_model.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/group/domain/group_summary.dart';
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
    final ref = _firestore.collection('groups').doc();
    // A brand-new group starts with an (empty) summary, so its balances are
    // maintained from the first expense on.
    final batch = _firestore.batch()
      ..set(ref, {
        ...model.toMap(),
        'balances': {createdByUid: 0},
        'totalSpentMinor': 0,
        'expenseCount': 0,
        'summaryVersion': kSummaryVersion,
      })
      ..set(_invite(model.inviteCode!),
          _inviteData(ref.id, name: name, emoji: emoji));
    await batch.commit();
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
  Future<void> setCoverUrl(String groupId, String? url) => _firestore
      .collection('groups')
      .doc(groupId)
      .update({'coverUrl': url ?? FieldValue.delete()});

  @override
  Future<void> setCustomCategories(
          String groupId, List<CustomCategory> categories) =>
      _firestore.collection('groups').doc(groupId).update({
        'customCategories': [
          for (final c in categories)
            {'id': c.id, 'name': c.name, 'emoji': c.emoji},
        ],
      });

  DocumentReference<Map<String, dynamic>> _invite(String code) =>
      _firestore.collection('invites').doc(code);

  /// The public side of an invite: just enough to preview the group.
  Map<String, dynamic> _inviteData(String groupId,
          {required String name, required String emoji}) =>
      {'groupId': groupId, 'name': name, 'emoji': emoji};

  @override
  Future<String> ensureInviteCode(String groupId) async {
    final ref = _firestore.collection('groups').doc(groupId);
    final data = (await ref.get()).data() ?? {};
    final existing = data['inviteCode'] as String?;
    if (existing == null || existing.isEmpty) return resetInviteCode(groupId);
    // Groups from before invites were published get their entry now (and an
    // admin re-publishing an existing one is harmless).
    await _invite(existing).set(_inviteData(groupId,
        name: data['name'] as String? ?? '',
        emoji: data['emoji'] as String? ?? '✨'));
    return existing;
  }

  @override
  Future<String> resetInviteCode(String groupId) async {
    final ref = _firestore.collection('groups').doc(groupId);
    final data = (await ref.get()).data() ?? {};
    final old = data['inviteCode'] as String?;
    final code = generateInviteCode();
    final batch = _firestore.batch()
      ..update(ref, {'inviteCode': code})
      ..set(_invite(code), _inviteData(groupId,
          name: data['name'] as String? ?? '',
          emoji: data['emoji'] as String? ?? '✨'));
    if (old != null && old.isNotEmpty) batch.delete(_invite(old));
    await batch.commit();
    return code;
  }

  @override
  Future<void> updateGroup(String groupId,
      {String? name, String? emoji, String? category}) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (emoji != null) updates['emoji'] = emoji;
    if (category != null) updates['category'] = category;
    if (updates.isEmpty) return;
    final ref = _firestore.collection('groups').doc(groupId);
    String? code;
    if (name != null || emoji != null) {
      code = (await ref.get()).data()?['inviteCode'] as String?;
    }
    final batch = _firestore.batch()..update(ref, updates);
    // Keep the invite preview in step with the group's name and emoji.
    if (code != null && code.isNotEmpty) {
      batch.set(
          _invite(code),
          {
            if (name != null) 'name': name,
            if (emoji != null) 'emoji': emoji,
          },
          SetOptions(merge: true));
    }
    await batch.commit();
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    final ref = _firestore.collection('groups').doc(groupId);
    final snap = await ref.get();
    if (!snap.exists) return;
    final code = snap.data()?['inviteCode'] as String?;

    // No Cloud Function to clean up afterwards, so empty the group first.
    // Marking it `deleting` is what lets the rules accept removing the ledger
    // (settlements are otherwise immutable); the mark can't be taken back.
    await ref.update({'deleting': true});
    for (final name in const [
      'expenses',
      'settlements',
      'recurring',
      'photos',
    ]) {
      await _deleteCollection(ref.collection(name),
          nested: name == 'expenses' ? const ['comments', 'history'] : const []);
    }
    final batch = _firestore.batch()..delete(ref);
    if (code != null && code.isNotEmpty) batch.delete(_invite(code));
    await batch.commit();
  }

  /// Deletes every document of [col] (and the [nested] sub-collections of each).
  Future<void> _deleteCollection(CollectionReference<Map<String, dynamic>> col,
      {List<String> nested = const []}) async {
    while (true) {
      final snap = await col.limit(200).get();
      if (snap.docs.isEmpty) return;
      for (final doc in snap.docs) {
        for (final sub in nested) {
          await _deleteCollection(doc.reference.collection(sub));
        }
      }
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
