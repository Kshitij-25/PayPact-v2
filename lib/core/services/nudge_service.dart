import 'package:paypact/core/utils/currency_utils.dart';
import 'package:paypact/features/group/presentation/cubit/groups_cubit.dart';
import 'package:paypact/features/notification/domain/repositories/notifications_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sends the gentle "you still owe…" reminder behind Home's smart nudge, and
/// remembers when, so the same person isn't nagged more than once per cooldown.
class NudgeService {
  NudgeService(this._notifRepo, this._prefs, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final NotificationsRepository _notifRepo;
  final SharedPreferences _prefs;
  final DateTime Function() _now;

  static const cooldown = Duration(days: 3);

  String _key(String actorId, SmartNudgeData n) =>
      'nudge_${actorId}_${n.groupId}_${n.fromUserId}';

  bool canNudge(String actorId, SmartNudgeData nudge) {
    final last = _prefs.getInt(_key(actorId, nudge));
    if (last == null) return true;
    return _now()
            .difference(DateTime.fromMillisecondsSinceEpoch(last)) >=
        cooldown;
  }

  /// Delivers the nudge to the person who owes. The recipient's "Smart
  /// nudges" preference is honoured by the notifications repository.
  Future<void> send({
    required SmartNudgeData nudge,
    required String actorId,
    required String actorName,
  }) async {
    final sym = currencySymbol(nudge.currency);
    final amount = nudge.amountOwed;
    final amountText =
        '$sym${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}';
    final first = actorName.trim().split(' ').first;

    await _notifRepo.push(
      targetUserId: nudge.fromUserId,
      type: 'nudge',
      title: '${first.isEmpty ? 'A friend' : first} sent a gentle reminder',
      body: 'You still owe $amountText in "${nudge.groupName}".',
      groupId: nudge.groupId,
      groupName: nudge.groupName,
      actorId: actorId,
      actorName: actorName,
    );
    await _prefs.setInt(
        _key(actorId, nudge), _now().millisecondsSinceEpoch);
  }
}
