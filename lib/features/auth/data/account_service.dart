import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:paypact/features/auth/data/user_directory.dart';
import 'package:paypact/features/auth/domain/account_deletion_plan.dart';
import 'package:paypact/features/group/data/summary_service.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/features/notification/domain/repositories/notifications_repository.dart';

/// A group where the user still has money outstanding.
class AccountDeletionBlocker {
  const AccountDeletionBlocker(
      {required this.groupName, required this.currency, required this.netMinor});
  final String groupName;
  final String currency;

  /// + = they are owed money, − = they owe money (minor units).
  final int netMinor;
}

/// Deletion was refused because of unsettled balances.
class AccountDeletionBlocked implements Exception {
  const AccountDeletionBlocked(this.blockers);
  final List<AccountDeletionBlocker> blockers;
}

/// The sign-in is too old to delete an account; re-authenticate and retry.
class RecentLoginRequired implements Exception {
  const RecentLoginRequired();
}

class AccountService {
  AccountService(this._auth, this._firestore, this._groups, this._summaries,
      this._notifications);
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GroupRepository _groups;
  final SummaryService _summaries;
  final NotificationsRepository _notifications;

  List<String> get providers =>
      _auth.currentUser?.providerData.map((p) => p.providerId).toList() ?? [];

  bool get usesPassword => providers.contains('password');
  bool get usesGoogle => providers.contains('google.com');
  bool get usesApple => providers.contains('apple.com');

  String? get email => _auth.currentUser?.email;

  Future<void> reauthenticateWithPassword(String password) async {
    final user = _auth.currentUser!;
    await user.reauthenticateWithCredential(
        fb.EmailAuthProvider.credential(email: user.email!, password: password));
  }

  /// Re-authenticates with whichever social provider the account uses.
  Future<void> reauthenticateWithProvider() async {
    final user = _auth.currentUser!;
    if (usesApple) {
      final provider = fb.AppleAuthProvider();
      if (kIsWeb) {
        await user.reauthenticateWithPopup(provider);
      } else {
        await user.reauthenticateWithProvider(provider);
      }
      return;
    }
    if (kIsWeb) {
      await user.reauthenticateWithPopup(fb.GoogleAuthProvider());
      return;
    }
    await GoogleSignIn.instance.initialize();
    final google = await GoogleSignIn.instance.authenticate();
    final idToken = google.authentication.idToken;
    if (idToken == null) throw Exception('Google re-authentication failed');
    await user.reauthenticateWithCredential(
        fb.GoogleAuthProvider.credential(idToken: idToken));
  }

  /// Permanently deletes the account and its data. Throws
  /// [AccountDeletionBlocked] when money is still outstanding.
  ///
  /// There's no server to do this, so the app does it step by step while the
  /// user is still signed in: leave (or remove) every group, clear their
  /// personal documents, and only then delete the sign-in itself. Every step
  /// is safe to repeat if something fails half-way.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw const RecentLoginRequired();
    final uid = user.uid;

    final memberships = await _firestore
        .collection('groups')
        .where('memberIds', arrayContains: uid)
        .get();

    final groups = <GroupForDeletion>[];
    for (final g in memberships.docs) {
      final d = g.data();
      final memberIds = List<String>.from(d['memberIds'] as List? ?? const []);
      var net = 0;
      if (memberIds.length > 1) {
        // Always rebuild: a stale summary must never let someone leave in debt.
        final summary = await _summaries.rebuild(g.id);
        net = summary?.balances[uid] ?? 0;
      }
      groups.add(GroupForDeletion(
        id: g.id,
        name: d['name'] as String? ?? '',
        currency: d['currency'] as String? ?? 'INR',
        memberIds: memberIds,
        adminIds: d['adminIds'] is List
            ? List<String>.from(d['adminIds'] as List)
            : [d['createdBy'] as String? ?? ''],
        createdBy: d['createdBy'] as String? ?? '',
        netMinor: net,
      ));
    }

    final plan = planAccountDeletion(uid, groups);
    if (plan.blockers.isNotEmpty) {
      throw AccountDeletionBlocked([
        for (final b in plan.blockers)
          AccountDeletionBlocker(
              groupName: b.name, currency: b.currency, netMinor: b.netMinor),
      ]);
    }

    final profile = (await _firestore.collection('users').doc(uid).get()).data();
    final name = (profile?['name'] as String?)?.trim().isNotEmpty == true
        ? profile!['name'] as String
        : 'A member';

    for (final action in plan.actions) {
      final g = action.group;
      if (action.type == DeletionActionType.deleteGroup) {
        await _groups.deleteGroup(g.id);
        continue;
      }
      final admins = <String>{
        ...(g.adminIds.isEmpty ? [g.createdBy] : g.adminIds)
            .where((a) => a != uid),
        if (action.promote != null) action.promote!,
      }.toList();
      await _firestore.collection('groups').doc(g.id).update({
        'memberIds': FieldValue.arrayRemove([uid]),
        'memberNames.$uid': FieldValue.delete(),
        'adminIds': admins,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      for (final m in g.memberIds.where((m) => m != uid)) {
        await _notifications
            .push(
              targetUserId: m,
              type: 'member_removed',
              title: '$name left "${g.name}"',
              body: 'Their account was deleted.',
              groupId: g.id,
              groupName: g.name,
              actorId: uid,
              actorName: name,
            )
            .catchError((_) {});
      }
    }

    // Personal documents. (The profile goes last: it is what the rules and the
    // other steps lean on.)
    final me = _firestore.collection('users').doc(uid);
    for (final sub in const ['notifications', 'private', 'photos']) {
      await _deleteAll(me.collection(sub));
    }
    await UserDirectory.remove(_firestore, uid);
    await me.delete();

    try {
      await user.delete();
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') throw const RecentLoginRequired();
      rethrow;
    }
    // The account no longer exists; clear the local session.
    try {
      await _auth.signOut();
      // Never initialised in this session (email sign-in) = nothing to sign
      // out of, and the call can wait forever: don't let it hold things up.
      await GoogleSignIn.instance
          .signOut()
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  Future<void> _deleteAll(CollectionReference<Map<String, dynamic>> col) async {
    while (true) {
      final snap = await col.limit(200).get();
      if (snap.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }
}
