class GroupEntity {
  final String id;
  final String name;
  final String emoji;
  final String category;
  final String currency;
  final List<String> memberIds;
  final Map<String, String> memberNames;
  final String createdBy;
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
    this.netBalance = 0,
  });
}
