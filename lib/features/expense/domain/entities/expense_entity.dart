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

  /// Amount in the group's base currency (used for all balance calculations).
  final double amount;

  /// The amount as the user originally entered it (may be in a different currency).
  final double originalAmount;

  /// The currency the user entered the expense in.
  final String originalCurrency;

  /// Snapshot exchange rate: originalCurrency → group base currency at the time of entry.
  /// 1.0 when originalCurrency == group currency.
  final double exchangeRate;

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
    required this.originalAmount,
    required this.originalCurrency,
    required this.exchangeRate,
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
