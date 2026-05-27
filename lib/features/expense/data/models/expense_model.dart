import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';

class ExpenseModel extends ExpenseEntity {
  const ExpenseModel({
    required super.id,
    required super.groupId,
    required super.title,
    required super.amount,
    required super.originalAmount,
    required super.originalCurrency,
    required super.exchangeRate,
    required super.category,
    required super.paidById,
    required super.paidByName,
    required super.splits,
    required super.createdAt,
    required super.createdById,
  });

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc, String groupId) {
    final data = doc.data() as Map<String, dynamic>;
    final splitsRaw = data['splits'] as List<dynamic>? ?? [];
    final splits = splitsRaw.map((s) {
      final map = s as Map<String, dynamic>;
      return ExpenseSplitEntity(
        userId: map['userId'] as String,
        userName: map['userName'] as String? ?? '',
        amount: (map['amount'] as num).toDouble(),
      );
    }).toList();

    final baseAmount = (data['amount'] as num?)?.toDouble() ?? 0;

    return ExpenseModel(
      id: doc.id,
      groupId: groupId,
      title: data['title'] as String? ?? '',
      amount: baseAmount,
      originalAmount:
          (data['originalAmount'] as num?)?.toDouble() ?? baseAmount,
      originalCurrency: data['originalCurrency'] as String? ?? 'INR',
      exchangeRate: (data['exchangeRate'] as num?)?.toDouble() ?? 1.0,
      category: data['category'] as String? ?? 'other',
      paidById: data['paidById'] as String? ?? '',
      paidByName: data['paidByName'] as String? ?? '',
      splits: splits,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdById: data['createdById'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'amount': amount,
        'originalAmount': originalAmount,
        'originalCurrency': originalCurrency,
        'exchangeRate': exchangeRate,
        'category': category,
        'paidById': paidById,
        'paidByName': paidByName,
        'splits': splits
            .map((s) => {
                  'userId': s.userId,
                  'userName': s.userName,
                  'amount': s.amount,
                })
            .toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdById': createdById,
      };
}
