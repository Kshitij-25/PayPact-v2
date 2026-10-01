// Per-user notification preferences. Stored on `users/{uid}` as `notifPrefs`
// (category → bool) and `mutedGroups` (list of group ids) so the *sender* can
// honour them — a client can't read another device's local settings.

const kNotifDefaults = <String, bool>{
  'settlements': true,
  'nudges': true,
  'expenses': true,
  'digest': false, // opt-in
};

/// Which preference governs a notification [type]. Null means the type is
/// always delivered (membership and group events).
String? notifCategoryFor(String type) => switch (type) {
      'expense_added' ||
      'expense_updated' ||
      'expense_deleted' ||
      'expense_comment' =>
        'expenses',
      'settlement' => 'settlements',
      'nudge' => 'nudges',
      'digest' => 'digest',
      _ => null,
    };

/// Whether a notification should be written for a user, given their profile
/// document data (null/empty = no preferences saved = defaults).
bool shouldDeliver({
  required String type,
  String? groupId,
  Map<String, dynamic>? userData,
}) {
  final category = notifCategoryFor(type);
  if (category == null) return true;

  final prefs = userData?['notifPrefs'];
  final enabled = prefs is Map && prefs[category] is bool
      ? prefs[category] as bool
      : kNotifDefaults[category] ?? true;
  if (!enabled) return false;

  final muted = userData?['mutedGroups'];
  if (groupId != null && muted is List && muted.contains(groupId)) {
    return false;
  }
  return true;
}
