import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// A group where the user still has money outstanding.
class AccountDeletionBlocker {
  const AccountDeletionBlocker(
      {required this.groupName, required this.currency, required this.netMinor});
  final String groupName;
  final String currency;

  /// + = they are owed money, − = they owe money (minor units).
  final int netMinor;

  factory AccountDeletionBlocker.fromMap(Map<Object?, Object?> m) =>
      AccountDeletionBlocker(
        groupName: m['name'] as String? ?? '',
        currency: m['currency'] as String? ?? 'INR',
        netMinor: (m['netMinor'] as num?)?.toInt() ?? 0,
      );
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
  AccountService(this._auth, this._functions);
  final fb.FirebaseAuth _auth;
  final FirebaseFunctions _functions;

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

  /// Permanently deletes the account and its data via the `deleteAccount`
  /// function. Throws [AccountDeletionBlocked] / [RecentLoginRequired].
  Future<void> deleteAccount() async {
    // The function checks how recently the user signed in; make sure the
    // token it sees is the fresh one from the re-authentication.
    await _auth.currentUser?.getIdToken(true);
    try {
      await _functions.httpsCallable('deleteAccount').call<void>();
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition') {
        final details = e.details;
        final list = details is Map ? details['blockers'] : null;
        throw AccountDeletionBlocked([
          if (list is List)
            for (final b in list)
              if (b is Map) AccountDeletionBlocker.fromMap(b),
        ]);
      }
      if (e.code == 'unauthenticated') throw const RecentLoginRequired();
      rethrow;
    }
    // The account no longer exists server-side; clear the local session.
    try {
      await _auth.signOut();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }
}
