import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/notification/domain/digest.dart';
import 'package:paypact/features/notification/domain/notification_prefs.dart';
import 'package:paypact/features/notification/domain/repositories/notifications_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The opt-in weekly digest, without a scheduled server job: when the app is
/// opened and a week has passed since the last one, the digest is written to
/// the person's own inbox, from where it is shown like any other notification.
class DigestService {
  DigestService(this._firestore, this._notifications, this._prefs,
      {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final FirebaseFirestore _firestore;
  final NotificationsRepository _notifications;
  final SharedPreferences _prefs;
  final DateTime Function() _now;

  static const interval = Duration(days: 7);

  String _key(String uid) => 'digest_last_$uid';

  bool isDue(String uid) {
    final last = _prefs.getInt(_key(uid));
    return last == null ||
        _now().difference(DateTime.fromMillisecondsSinceEpoch(last)) >=
            interval;
  }

  /// Sends this week's digest if the person opted in and one is due. Never
  /// throws.
  bool _busy = false;

  Future<bool> maybeSend(String uid, List<GroupEntity> groups) async {
    if (_busy || groups.isEmpty || !isDue(uid)) return false;
    _busy = true;
    try {
      final user = (await _firestore.collection('users').doc(uid).get()).data();
      if (!shouldDeliver(type: 'digest', userData: user)) return false;

      final weekAgo = Timestamp.fromDate(_now().subtract(interval));
      var expenses = 0;
      final net = <String, int>{};
      for (final g in groups) {
        final recent = await _firestore
            .collection('groups')
            .doc(g.id)
            .collection('expenses')
            .where('createdAt', isGreaterThanOrEqualTo: weekAgo)
            .count()
            .get();
        expenses += recent.count ?? 0;
        net[g.currency] = (net[g.currency] ?? 0) + (g.balances?[uid] ?? 0);
      }

      await _prefs.setInt(_key(uid), _now().millisecondsSinceEpoch);
      final digest = buildDigest(
          expenseCount: expenses, groupCount: groups.length, net: net);
      if (digest == null) return false;
      await _notifications.push(
        targetUserId: uid,
        type: 'digest',
        title: digest.title,
        body: digest.body,
        actorId: uid,
        actorName: 'PayPact',
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      _busy = false;
    }
  }
}
