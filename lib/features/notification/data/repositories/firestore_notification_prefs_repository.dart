import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paypact/features/notification/domain/notification_prefs.dart';
import 'package:paypact/features/notification/domain/repositories/notification_prefs_repository.dart';

class FirestoreNotificationPrefsRepository
    implements NotificationPrefsRepository {
  FirestoreNotificationPrefsRepository(this._firestore);
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _firestore.collection('users').doc(uid);

  @override
  Future<Map<String, bool>> loadPrefs(String userId,
      {Map<String, bool>? legacy}) async {
    final data = (await _user(userId).get()).data();
    final saved = data?['notifPrefs'];
    if (saved is! Map && legacy != null) {
      final migrated = {...kNotifDefaults, ...legacy};
      await _user(userId)
          .set({'notifPrefs': migrated}, SetOptions(merge: true));
      return migrated;
    }
    return {
      ...kNotifDefaults,
      if (saved is Map)
        for (final e in saved.entries)
          if (e.value is bool) e.key as String: e.value as bool,
    };
  }

  @override
  Future<void> setPref(String userId, String category, bool enabled) =>
      _user(userId).set({
        'notifPrefs': {category: enabled},
      }, SetOptions(merge: true));

  @override
  Future<Set<String>> loadMutedGroups(String userId) async {
    final muted = (await _user(userId).get()).data()?['mutedGroups'];
    return muted is List ? muted.whereType<String>().toSet() : <String>{};
  }

  @override
  Future<void> setGroupMuted(String userId, String groupId, bool muted) =>
      _user(userId).set({
        'mutedGroups': muted
            ? FieldValue.arrayUnion([groupId])
            : FieldValue.arrayRemove([groupId]),
      }, SetOptions(merge: true));
}
