abstract class NotificationPrefsRepository {
  /// Saved preferences merged over the defaults. When nothing is saved yet,
  /// [legacy] (values from the old device-local settings) is used and persisted.
  Future<Map<String, bool>> loadPrefs(String userId,
      {Map<String, bool>? legacy});
  Future<void> setPref(String userId, String category, bool enabled);

  Future<Set<String>> loadMutedGroups(String userId);
  Future<void> setGroupMuted(String userId, String groupId, bool muted);
}
