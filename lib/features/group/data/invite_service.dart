import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:paypact/core/utils/invite_code.dart';

class InvitePreview {
  const InvitePreview({
    required this.name,
    required this.emoji,
    required this.memberCount,
    required this.alreadyMember,
  });
  final String name;
  final String emoji;
  final int memberCount;
  final bool alreadyMember;
}

class JoinResult {
  const JoinResult({
    required this.groupId,
    required this.name,
    required this.alreadyMember,
  });
  final String groupId;
  final String name;
  final bool alreadyMember;
}

/// A failure with a message that is safe to show to the user.
class InviteException implements Exception {
  const InviteException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Invite links without Cloud Functions.
///
/// Every group publishes `invites/{code}` (group id, name, emoji). The code is
/// the secret: a document can be fetched by id but never listed. Joining is a
/// direct update of the group document that the security rules only accept
/// when it adds the caller and quotes a code that points at this group.
class InviteService {
  InviteService(this._firestore, this._auth);
  final FirebaseFirestore _firestore;
  final fb.FirebaseAuth _auth;

  Future<_Invite> _lookup(String raw) async {
    final code = normalizeInviteCode(raw);
    if (code == null) {
      throw const InviteException("That doesn't look like a valid invite link.");
    }
    try {
      final doc = await _firestore.collection('invites').doc(code).get();
      final data = doc.data();
      if (!doc.exists || data == null || data['groupId'] is! String) {
        throw const InviteException('This invite link is no longer valid.');
      }
      return _Invite(
        code: code,
        groupId: data['groupId'] as String,
        name: data['name'] as String? ?? '',
        emoji: data['emoji'] as String? ?? '✨',
      );
    } on InviteException {
      rethrow;
    } on FirebaseException catch (e) {
      throw _friendly(e);
    }
  }

  /// A non-member can't read a group, so a successful read means they're in.
  Future<bool> _isMember(String groupId) async {
    try {
      final group = await _firestore.collection('groups').doc(groupId).get();
      final uid = _auth.currentUser?.uid;
      final members = (group.data()?['memberIds'] as List?) ?? const [];
      return group.exists && uid != null && members.contains(uid);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return false;
      throw _friendly(e);
    }
  }

  Future<InvitePreview> preview(String code) async {
    if (_auth.currentUser == null) {
      throw const InviteException('Please sign in to join this group.');
    }
    final invite = await _lookup(code);
    return InvitePreview(
      name: invite.name,
      emoji: invite.emoji,
      memberCount: 0, // not published: it would go stale as people join
      alreadyMember: await _isMember(invite.groupId),
    );
  }

  Future<JoinResult> join(String code) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const InviteException('Please sign in to join this group.');
    }
    final invite = await _lookup(code);
    if (await _isMember(invite.groupId)) {
      return JoinResult(
          groupId: invite.groupId, name: invite.name, alreadyMember: true);
    }
    try {
      final profile =
          (await _firestore.collection('users').doc(user.uid).get()).data();
      final name = (profile?['name'] as String?)?.trim().isNotEmpty == true
          ? profile!['name'] as String
          : (user.displayName?.trim().isNotEmpty == true
              ? user.displayName!
              : (user.email ?? 'Member').split('@').first);
      await _firestore.collection('groups').doc(invite.groupId).update({
        'memberIds': FieldValue.arrayUnion([user.uid]),
        'memberNames.${user.uid}': name,
        'joinCode': invite.code,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw _friendly(e);
    }
    return JoinResult(
        groupId: invite.groupId, name: invite.name, alreadyMember: false);
  }

  InviteException _friendly(FirebaseException e) => InviteException(switch (e.code) {
        'not-found' => 'This invite link is no longer valid.',
        'permission-denied' => 'This invite link is no longer valid.',
        'unavailable' || 'deadline-exceeded' =>
          'No connection. Check your internet and try again.',
        _ => 'Could not use this invite. Please try again.',
      });
}

class _Invite {
  const _Invite(
      {required this.code,
      required this.groupId,
      required this.name,
      required this.emoji});
  final String code;
  final String groupId;
  final String name;
  final String emoji;
}
