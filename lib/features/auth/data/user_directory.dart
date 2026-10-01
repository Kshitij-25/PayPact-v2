import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

/// The searchable public face of an account: `directory/{uid}`.
///
/// People search can't list the `users` collection (it holds e-mail addresses
/// and payment details), and there are no Cloud Functions to do it on the free
/// plan. So each account publishes a small directory entry instead: its name
/// (for prefix search), its photo, a *hash* of its e-mail (so an exact address
/// can be looked up without anyone being able to read the addresses) and a
/// masked e-mail for display.
class UserDirectory {
  static String normalizeEmail(String email) => email.trim().toLowerCase();

  static String emailHash(String email) =>
      sha256.convert(utf8.encode(normalizeEmail(email))).toString();

  /// `k••••@gmail.com`
  static String maskEmail(String email) {
    if (!email.contains('@')) return '';
    final parts = email.split('@');
    final local = parts.first;
    final dots = (local.length - 1).clamp(1, 4);
    return '${local.isEmpty ? '' : local[0]}${'•' * dots}@${parts.sublist(1).join('@')}';
  }

  static Map<String, dynamic> entry({
    required String name,
    required String email,
    String? photoUrl,
  }) =>
      {
        'name': name,
        'nameLower': name.trim().toLowerCase(),
        if (email.isNotEmpty) 'emailHash': emailHash(email),
        'emailMasked': maskEmail(email),
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  /// Creates or refreshes the directory entry. Best-effort: search being a
  /// little stale must never break sign-in.
  static Future<void> upsert(
    FirebaseFirestore db,
    String uid, {
    required String name,
    required String email,
    String? photoUrl,
  }) async {
    if (name.trim().isEmpty) return;
    try {
      await db
          .collection('directory')
          .doc(uid)
          .set(entry(name: name, email: email, photoUrl: photoUrl));
    } catch (_) {}
  }

  static Future<void> remove(FirebaseFirestore db, String uid) async {
    try {
      await db.collection('directory').doc(uid).delete();
    } catch (_) {}
  }
}
