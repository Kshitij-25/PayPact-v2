/// Where a notification should take the user when tapped — from the push
/// payload (`type`, `groupId`) or an item in the in-app inbox.
String routeForNotification({String? type, String? groupId}) {
  if (type == 'digest') return '/';
  if (type == 'group_deleted' || type == 'member_removed') {
    // The group may no longer be reachable; the inbox explains what happened.
    return '/notifications';
  }
  if (groupId != null && groupId.isNotEmpty) return '/group/$groupId';
  return '/notifications';
}
