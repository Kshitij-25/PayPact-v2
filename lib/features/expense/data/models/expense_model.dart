import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/entities/expense_split_entity.dart';

class ExpenseModel {
  const ExpenseModel({
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
    required this.category,
    required this.splitType,
    required this.currency,
    required this.isSettled,
  });

  final String id;
  final String groupId;
  final String title;
  final double amount;
  final Map<String, double> paidBy;
  final List<Map<String, dynamic>> splits;
  final DateTime createdAt;
  final String createdBy;
  final String? description;
  final String? receiptUrl;
  final String category;
  final String splitType;
  final String currency;
  final bool isSettled;

  factory ExpenseModel.fromFirestore(Map<String, dynamic> map, String id) {
    final rawPaidBy = map['paidBy'] as Map<String, dynamic>? ?? {};
    final rawSplits = map['splits'] as List<dynamic>? ?? [];
    return ExpenseModel(
      id: id,
      groupId: map['groupId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paidBy: rawPaidBy.map((k, v) => MapEntry(k, (v as num).toDouble())),
      splits: rawSplits.cast<Map<String, dynamic>>(),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['createdAt'] as dynamic).millisecondsSinceEpoch as int)
          : DateTime.now(),
      createdBy: map['createdBy'] as String? ?? '',
      description: map['description'] as String?,
      receiptUrl: map['receiptUrl'] as String?,
      category: map['category'] as String? ?? 'other',
      splitType: map['splitType'] as String? ?? 'equal',
      currency: map['currency'] as String? ?? 'USD',
      isSettled: map['isSettled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'groupId': groupId,
        'title': title,
        'amount': amount,
        'paidBy': paidBy,
        'splits': splits,
        'createdAt': createdAt,
        'createdBy': createdBy,
        'description': description,
        'receiptUrl': receiptUrl,
        'category': category,
        'splitType': splitType,
        'currency': currency,
        'isSettled': isSettled,
      };

  ExpenseEntity toEntity() => ExpenseEntity(
        id: id,
        groupId: groupId,
        title: title,
        amount: amount,
        paidBy: paidBy,
        splits: splits
            .map((s) => ExpenseSplitEntity(
                  userId: s['userId'] as String,
                  amount: (s['amount'] as num).toDouble(),
                  percentage: (s['percentage'] as num?)?.toDouble(),
                  shares: s['shares'] as int?,
                  isSettled: s['isSettled'] as bool? ?? false,
                ))
            .toList(),
        createdAt: createdAt,
        createdBy: createdBy,
        description: description,
        receiptUrl: receiptUrl,
        category: ExpenseCategory.values.firstWhere(
          (c) => c.name == category,
          orElse: () => ExpenseCategory.other,
        ),
        splitType: SplitType.values.firstWhere(
          (s) => s.name == splitType,
          orElse: () => SplitType.equal,
        ),
        currency: currency,
        isSettled: isSettled,
      );

  factory ExpenseModel.fromEntity(ExpenseEntity e) => ExpenseModel(
        id: e.id,
        groupId: e.groupId,
        title: e.title,
        amount: e.amount,
        paidBy: e.paidBy,
        splits: e.splits
            .map((s) => {
                  'userId': s.userId,
                  'amount': s.amount,
                  'percentage': s.percentage,
                  'shares': s.shares,
                  'isSettled': s.isSettled,
                })
            .toList(),
        createdAt: e.createdAt,
        createdBy: e.createdBy,
        description: e.description,
        receiptUrl: e.receiptUrl,
        category: e.category.name,
        splitType: e.splitType.name,
        currency: e.currency,
        isSettled: e.isSettled,
      );
}
