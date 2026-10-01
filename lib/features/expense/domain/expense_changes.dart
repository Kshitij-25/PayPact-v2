import 'package:intl/intl.dart';
import 'package:paypact/core/utils/currency_utils.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/entities/expense_extras.dart';

String _money(double v, String currency) {
  final sym = currencySymbol(currency);
  return '$sym${v.truncateToDouble() == v ? v.toStringAsFixed(0) : v.toStringAsFixed(2)}';
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool _sameSplits(List<ExpenseSplitEntity> a, List<ExpenseSplitEntity> b) {
  if (a.length != b.length) return false;
  final m = {for (final s in a) s.userId: s.amount};
  for (final s in b) {
    final old = m[s.userId];
    if (old == null || (old - s.amount).abs() > 0.005) return false;
  }
  return true;
}

/// Human-readable lines describing what changed between two versions of an
/// expense, for the edit history. Empty when nothing user-visible changed.
List<String> describeExpenseChanges(
  ExpenseEntity before,
  ExpenseEntity after, {
  required String groupCurrency,
}) {
  final out = <String>[];
  if (before.title != after.title) {
    out.add('Title: "${before.title}" → "${after.title}"');
  }
  if ((before.originalAmount - after.originalAmount).abs() > 0.005 ||
      before.originalCurrency != after.originalCurrency) {
    out.add('Amount: ${_money(before.originalAmount, before.originalCurrency)}'
        ' → ${_money(after.originalAmount, after.originalCurrency)}');
  }
  if (before.category != after.category) {
    out.add('Category: ${before.category} → ${after.category}');
  }
  if (before.paidById != after.paidById) {
    out.add('Paid by: ${before.paidByName} → ${after.paidByName}');
  }
  if (!_sameSplits(before.splits, after.splits)) out.add('Split changed');
  if (!_sameDay(before.date, after.date)) {
    final f = DateFormat('MMM d, yyyy');
    out.add('Date: ${f.format(before.date)} → ${f.format(after.date)}');
  }
  if ((before.note ?? '') != (after.note ?? '')) {
    out.add(after.note == null || after.note!.isEmpty
        ? 'Note removed'
        : 'Note updated');
  }
  if ((before.receiptUrl ?? '') != (after.receiptUrl ?? '')) {
    out.add(after.receiptUrl == null ? 'Receipt removed' : 'Receipt attached');
  }
  return out;
}

/// The next occurrence after [from] (calendar-based, clamped for short months
/// so Jan 31 → Feb 28). Mirrors functions/lib/recurring.js.
DateTime nextRecurrence(DateTime from, RecurrenceInterval interval) {
  if (interval == RecurrenceInterval.weekly) {
    return from.add(const Duration(days: 7));
  }
  final firstOfNext = DateTime(from.year, from.month + 1, 1, from.hour,
      from.minute, from.second);
  final lastDay = DateTime(firstOfNext.year, firstOfNext.month + 1, 0).day;
  return DateTime(firstOfNext.year, firstOfNext.month,
      from.day < lastDay ? from.day : lastDay, from.hour, from.minute,
      from.second);
}
