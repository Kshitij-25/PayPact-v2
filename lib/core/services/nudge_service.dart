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

  static const reminderCooldown = Duration(hours: 24);

  String _remindKey(String actorId, String expenseId, String targetId) =>
      'remind_${actorId}_${expenseId}_$targetId';

  /// Whether [targetId] can be reminded about [expenseId] again (once a day).
  bool canRemind(String actorId, String expenseId, String targetId) {
    final last = _prefs.getInt(_remindKey(actorId, expenseId, targetId));
    if (last == null) return true;
    return _now().difference(DateTime.fromMillisecondsSinceEpoch(last)) >=
        reminderCooldown;
  }

  /// Reminds [targetId] about an expense they still owe a share of. The
  /// recipient's "Smart nudges" preference decides whether it is delivered.
  Future<void> remindAbout({
    required String expenseId,
    required String expenseTitle,
    required String groupId,
    required String groupName,
    required String currency,
    required double amountOwed,
    required String targetId,
    required String actorId,
    required String actorName,
  }) async {
    final sym = currencySymbol(currency);
    final amountText =
        '$sym${amountOwed.toStringAsFixed(amountOwed.truncateToDouble() == amountOwed ? 0 : 2)}';
    final first = actorName.trim().split(' ').first;
    await _notifRepo.push(
      targetUserId: targetId,
      type: 'nudge',
      title: '${first.isEmpty ? 'A friend' : first} sent a gentle reminder',
      body: 'You still owe $amountText for "$expenseTitle" in "$groupName".',
      groupId: groupId,
      groupName: groupName,
      actorId: actorId,
      actorName: actorName,
    );
    await _prefs.setInt(_remindKey(actorId, expenseId, targetId),
        _now().millisecondsSinceEpoch);
  }

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
