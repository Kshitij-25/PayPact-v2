class GroupEntity {
  final String id;
  final String name;
  final String emoji;
  final String category;
  final String currency;
  final List<String> memberIds;
  final Map<String, String> memberNames;
  final String createdBy;

  /// Members allowed to edit/delete the group and manage members. Always
  /// contains at least the creator (older groups fall back to [createdBy]).
  final List<String> adminIds;

  /// Secret code behind the shareable invite link; null until an admin
  /// generates one (older groups).
  final String? inviteCode;
  final DateTime createdAt;
  double netBalance;

  GroupEntity({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.currency,
    required this.memberIds,
    required this.memberNames,
    required this.createdBy,
    required this.createdAt,
    List<String>? adminIds,
    this.inviteCode,
    this.netBalance = 0,
  }) : adminIds = adminIds ?? [createdBy];

  bool isAdmin(String userId) =>
      memberIds.contains(userId) && adminIds.contains(userId);
}
