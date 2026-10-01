/// A category an admin added to a group, beyond the built-in ones.
class CustomCategory {
  const CustomCategory({required this.id, required this.name, required this.emoji});
  final String id;
  final String name;
  final String emoji;

  @override
  bool operator ==(Object other) =>
      other is CustomCategory &&
      other.id == id &&
      other.name == name &&
      other.emoji == emoji;

  @override
  int get hashCode => Object.hash(id, name, emoji);
}

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

  /// Cover photo download URL.
  final String? coverUrl;

  /// Group-specific categories, shown after the built-in ones.
  final List<CustomCategory> customCategories;

  // ── Server-maintained summary (null for groups that predate it) ───────────
  // Kept up to date by Cloud Functions, so balances and totals don't require
  // downloading every expense.

  /// Net position per member in minor units (paise/cents); + means owed money.
  final Map<String, int>? balances;
  final int? totalSpentMinor;
  final int? expenseCount;
  final DateTime? lastActivityAt;
  final String? lastExpenseTitle;

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
    this.coverUrl,
    this.customCategories = const [],
    this.balances,
    this.totalSpentMinor,
    this.expenseCount,
    this.lastActivityAt,
    this.lastExpenseTitle,
    this.netBalance = 0,
  }) : adminIds = adminIds ?? [createdBy];

  /// True when [balances] etc. can be trusted instead of re-reading expenses.
  bool get hasSummary => balances != null;

  /// [userId]'s net balance in the group currency, from the summary.
  double? balanceOf(String userId) =>
      balances == null ? null : (balances![userId] ?? 0) / 100.0;

  bool isAdmin(String userId) =>
      memberIds.contains(userId) && adminIds.contains(userId);
}
