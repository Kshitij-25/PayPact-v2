import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';

GroupEntity makeGroup({
  String id = 'g1',
  String name = 'Trip',
  String currency = 'INR',
  List<String> members = const ['alice', 'bob'],
  List<String>? admins,
  String createdBy = 'alice',
  String? inviteCode,
}) =>
    GroupEntity(
      id: id,
      name: name,
      emoji: '🏖',
      category: 'trip',
      currency: currency,
      memberIds: List.of(members),
      memberNames: {for (final m in members) m: m[0].toUpperCase() + m.substring(1)},
      createdBy: createdBy,
      adminIds: admins,
      inviteCode: inviteCode,
      createdAt: DateTime(2026, 1, 1),
    );

/// [payer] paid [total]; split evenly across [among].
ExpenseEntity makeExpense({
  required String payer,
  required double total,
  required List<String> among,
  String groupId = 'g1',
  String title = 'Dinner',
  DateTime? at,
}) =>
    ExpenseEntity(
      id: 'e-$title-$payer',
      groupId: groupId,
      title: title,
      amount: total,
      originalAmount: total,
      originalCurrency: 'INR',
      exchangeRate: 1,
      category: 'food',
      paidById: payer,
      paidByName: payer[0].toUpperCase() + payer.substring(1),
      splits: [
        for (final u in among)
          ExpenseSplitEntity(
              userId: u, userName: u, amount: total / among.length),
      ],
      createdAt: at ?? DateTime(2026, 1, 2),
      createdById: payer,
    );
