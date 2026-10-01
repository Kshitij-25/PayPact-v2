import 'package:paypact/features/expense/domain/entities/expense_entity.dart';

class ExpenseComment {
  const ExpenseComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.createdAt,
  });
  final String id;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime createdAt;
}

/// One line of an expense's edit log ("Amount ₹100 → ₹120").
class ExpenseHistoryEntry {
  const ExpenseHistoryEntry({
    required this.id,
    required this.by,
    required this.byName,
    required this.changes,
    required this.at,
  });
  final String id;
  final String by;
  final String byName;
  final List<String> changes;
  final DateTime at;
}

enum RecurrenceInterval { weekly, monthly }

/// A template that a daily Cloud Function turns into real expenses.
class RecurringExpense {
  const RecurringExpense({
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
    required this.interval,
    required this.nextRunAt,
    required this.active,
    required this.createdById,
    required this.createdByName,
    this.note,
  });

  final String id;
  final String groupId;
  final String title;
  final double amount; // group currency
  final double originalAmount;
  final String originalCurrency;
  final double exchangeRate;
  final String category;
  final String paidById;
  final String paidByName;
  final List<ExpenseSplitEntity> splits;
  final RecurrenceInterval interval;
  final DateTime nextRunAt;
  final bool active;
  final String createdById;
  final String createdByName;
  final String? note;
}
