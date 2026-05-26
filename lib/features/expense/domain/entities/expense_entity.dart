class ExpenseSplitEntity {
  final String userId;
  final String userName;
  final double amount;

  const ExpenseSplitEntity({
    required this.userId,
    required this.userName,
    required this.amount,
  });
}

class ExpenseEntity {
  final String id;
  final String groupId;
  final String title;
  final double amount;
  final String category;
  final String paidById;
  final String paidByName;
  final List<ExpenseSplitEntity> splits;
  final DateTime createdAt;
  final String createdById;

  const ExpenseEntity({
    required this.id,
    required this.groupId,
    required this.title,
    required this.amount,
    required this.category,
    required this.paidById,
    required this.paidByName,
    required this.splits,
    required this.createdAt,
    required this.createdById,
  });

  double splitAmountFor(String userId) {
    for (final s in splits) {
      if (s.userId == userId) return s.amount;
    }
    return 0;
  }
}
