import 'package:equatable/equatable.dart';

import 'expense_split_entity.dart';

enum SplitType { equal, exact, percentage, shares }

enum ExpenseCategory {
  food,
  transport,
  accommodation,
  entertainment,
  shopping,
  utilities,
  health,
  education,
  other
}

class ExpenseEntity extends Equatable {
  const ExpenseEntity({
    required this.id,
    required this.groupId,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.splits,
    required this.createdAt,
    required this.createdBy,
    this.description,
    this.receiptUrl,
    this.category = ExpenseCategory.other,
    this.splitType = SplitType.equal,
    this.currency = 'USD',
    this.isSettled = false,
  });

  final String id;
  final String groupId;
  final String title;
  final double amount;

  /// Map of userId -> amount paid (supports multi-payer)
  final Map<String, double> paidBy;

  final List<ExpenseSplitEntity> splits;
  final DateTime createdAt;
  final String createdBy;
  final String? description;
  final String? receiptUrl;
  final ExpenseCategory category;
  final SplitType splitType;
  final String currency;
  final bool isSettled;

  double get totalSplitAmount => splits.fold(0.0, (sum, s) => sum + s.amount);

  double splitAmountFor(String userId) => splits
      .firstWhere(
        (s) => s.userId == userId,
        orElse: () => const ExpenseSplitEntity(userId: '', amount: 0),
      )
      .amount;

  double paidAmountFor(String userId) => paidBy[userId] ?? 0.0;

  /// Net balance change for a user in this expense
  double netBalanceFor(String userId) =>
      paidAmountFor(userId) - splitAmountFor(userId);

  ExpenseEntity copyWith({
    String? id,
    String? groupId,
    String? title,
    double? amount,
    Map<String, double>? paidBy,
    List<ExpenseSplitEntity>? splits,
    DateTime? createdAt,
    String? createdBy,
    String? description,
    String? receiptUrl,
    ExpenseCategory? category,
    SplitType? splitType,
    String? currency,
    bool? isSettled,
  }) {
    return ExpenseEntity(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      paidBy: paidBy ?? this.paidBy,
      splits: splits ?? this.splits,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      description: description ?? this.description,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      category: category ?? this.category,
      splitType: splitType ?? this.splitType,
      currency: currency ?? this.currency,
      isSettled: isSettled ?? this.isSettled,
    );
  }

  @override
  List<Object?> get props => [
        id,
        groupId,
        title,
        amount,
        paidBy,
        splits,
        createdAt,
        createdBy,
        description,
        receiptUrl,
        category,
        splitType,
        currency,
        isSettled
      ];
}
