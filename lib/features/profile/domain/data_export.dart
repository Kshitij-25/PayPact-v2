import 'dart:convert';

import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';

/// Builds a complete, portable copy of everything the signed-in user can see:
/// profile, groups, every expense and every settlement.
class DataExporter {
  DataExporter(this._groups, this._expenses);
  final GroupRepository _groups;
  final ExpenseRepository _expenses;

  Future<Map<String, dynamic>> build({
    required String userId,
    required String name,
    required String email,
    DateTime? now,
  }) async {
    final groups = await _groups.watchUserGroups(userId).first;
    final out = <Map<String, dynamic>>[];
    for (final g in groups) {
      final expenses = await _expenses.getGroupExpenses(g.id);
      final settlements = await _expenses.getGroupSettlements(g.id);
      out.add(_group(g, expenses, settlements));
    }
    return {
      'exportedAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
      'app': 'PayPact',
      'profile': {'id': userId, 'name': name, 'email': email},
      'groups': out,
    };
  }

  Future<String> buildJson({
    required String userId,
    required String name,
    required String email,
    DateTime? now,
  }) async =>
      const JsonEncoder.withIndent('  ').convert(
          await build(userId: userId, name: name, email: email, now: now));

  static Map<String, dynamic> _group(GroupEntity g,
          List<ExpenseEntity> expenses, List<Map<String, dynamic>> settlements) =>
      {
        'id': g.id,
        'name': g.name,
        'category': g.category,
        'currency': g.currency,
        'createdAt': g.createdAt.toUtc().toIso8601String(),
        'createdBy': g.createdBy,
        'admins': g.adminIds,
        'members': [
          for (final id in g.memberIds) {'id': id, 'name': g.memberNames[id]},
        ],
        'expenses': [
          for (final e in expenses)
            {
              'id': e.id,
              'title': e.title,
              'amount': e.amount,
              'originalAmount': e.originalAmount,
              'originalCurrency': e.originalCurrency,
              'exchangeRate': e.exchangeRate,
              'category': e.category,
              'paidBy': {'id': e.paidById, 'name': e.paidByName},
              'splits': [
                for (final s in e.splits)
                  {'userId': s.userId, 'name': s.userName, 'amount': s.amount},
              ],
              'date': e.date.toUtc().toIso8601String(),
              'createdAt': e.createdAt.toUtc().toIso8601String(),
              'note': e.note,
              'receiptUrl': e.receiptUrl,
            },
        ],
        'settlements': [
          for (final s in settlements)
            {
              'id': s['id'],
              'type': s['type'] ?? 'settlement',
              'from': {'id': s['fromUserId'], 'name': s['fromUserName']},
              'to': {'id': s['toUserId'], 'name': s['toUserName']},
              'amount': s['amountPaise'] is num
                  ? (s['amountPaise'] as num) / 100
                  : s['amount'],
              'currency': s['currency'],
              'method': s['paymentMethod'],
              'receiptId': s['receiptId'],
              'reversesId': s['reversesId'],
              'createdAt':
                  (s['createdAt'] as DateTime?)?.toUtc().toIso8601String(),
            },
        ],
      };
}
