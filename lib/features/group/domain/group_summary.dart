import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/split_allocator.dart';

/// Per-group running summary kept on the group document so the app can show
/// balances and totals without downloading every expense:
///
///   balances          { uid: net minor units }   (+ is owed, − owes)
///   totalSpentMinor   sum of expense amounts
///   expenseCount
///   lastActivityAt / lastExpenseTitle
///   summaryVersion    [kSummaryVersion] once the summary exists
///
/// Whoever writes an expense or settlement applies its *delta* in the same
/// batch (increments commute, so concurrent writers don't clobber each other);
/// [buildSummary] rebuilds from scratch for groups that predate the summary
/// and for the "Recalculate balances" repair.
const kSummaryVersion = 1;

/// The change a single write makes to a group's summary.
class SummaryDelta {
  const SummaryDelta(this.balances, this.totalSpentMinor, this.expenseCount);
  final Map<String, int> balances;
  final int totalSpentMinor;
  final int expenseCount;

  SummaryDelta operator +(SummaryDelta o) {
    final merged = {...balances};
    for (final e in o.balances.entries) {
      merged[e.key] = (merged[e.key] ?? 0) + e.value;
    }
    return SummaryDelta(merged, totalSpentMinor + o.totalSpentMinor,
        expenseCount + o.expenseCount);
  }

  bool get isEmpty =>
      balances.isEmpty && totalSpentMinor == 0 && expenseCount == 0;
}

/// Net minor-unit contribution of one expense, per member.
Map<String, int> expenseContribution(ExpenseEntity? e) {
  final out = <String, int>{};
  if (e == null) return out;
  void add(String id, int v) {
    if (id.isEmpty) return;
    out[id] = (out[id] ?? 0) + v;
  }

  add(e.paidById, toMinor(e.amount));
  for (final s in e.splits) {
    add(s.userId, -toMinor(s.amount));
  }
  return out;
}

/// Net contribution of one settlement or reversal ([fromUserId] paid
/// [toUserId]); accepts the stored map form.
Map<String, int> settlementContribution(Map<String, dynamic> s) {
  final out = <String, int>{};
  final raw = (s['amountPaise'] as num?)?.toInt();
  final minor =
      raw ?? toMinor((s['amount'] as num?)?.toDouble() ?? 0);
  final from = s['fromUserId'] as String?;
  final to = s['toUserId'] as String?;
  if (from != null && from.isNotEmpty) out[from] = (out[from] ?? 0) + minor;
  if (to != null && to.isNotEmpty) out[to] = (out[to] ?? 0) - minor;
  return out;
}

Map<String, int> _diff(Map<String, int> after, Map<String, int> before) {
  final out = <String, int>{};
  for (final id in {...after.keys, ...before.keys}) {
    final d = (after[id] ?? 0) - (before[id] ?? 0);
    if (d != 0) out[id] = d;
  }
  return out;
}

/// What changed when an expense went from [before] to [after] (null for a
/// create / delete).
SummaryDelta expenseDelta(ExpenseEntity? before, ExpenseEntity? after) =>
    SummaryDelta(
      _diff(expenseContribution(after), expenseContribution(before)),
      (after == null ? 0 : toMinor(after.amount)) -
          (before == null ? 0 : toMinor(before.amount)),
      (after == null ? 0 : 1) - (before == null ? 0 : 1),
    );

SummaryDelta settlementDelta(Map<String, dynamic> settlement) =>
    SummaryDelta(settlementContribution(settlement), 0, 0);

/// Firestore field updates applying [d] (and stamping the activity), to be
/// merged into the group's `update` call.
Map<String, dynamic> summaryUpdate(SummaryDelta d, {String? title}) => {
      if (d.totalSpentMinor != 0)
        'totalSpentMinor': FieldValue.increment(d.totalSpentMinor),
      if (d.expenseCount != 0)
        'expenseCount': FieldValue.increment(d.expenseCount),
      for (final e in d.balances.entries)
        'balances.${e.key}': FieldValue.increment(e.value),
      'lastActivityAt': FieldValue.serverTimestamp(),
      if (title != null) 'lastExpenseTitle': title,
    };

/// Whether a group document holds a trustworthy summary.
bool groupHasSummary(Map<String, dynamic>? data) =>
    data != null &&
    data['summaryVersion'] == kSummaryVersion &&
    data['balances'] is Map;

/// A full rebuild from every expense and settlement.
class RebuiltSummary {
  const RebuiltSummary({
    required this.balances,
    required this.totalSpentMinor,
    required this.expenseCount,
    required this.lastExpenseTitle,
    required this.lastActivityAt,
  });
  final Map<String, int> balances;
  final int totalSpentMinor;
  final int expenseCount;
  final String lastExpenseTitle;
  final DateTime? lastActivityAt;

  Map<String, dynamic> toUpdate() => {
        'balances': balances,
        'totalSpentMinor': totalSpentMinor,
        'expenseCount': expenseCount,
        'lastExpenseTitle': lastExpenseTitle,
        if (lastActivityAt != null)
          'lastActivityAt': Timestamp.fromDate(lastActivityAt!),
        'summaryVersion': kSummaryVersion,
      };
}

RebuiltSummary buildSummary({
  required List<ExpenseEntity> expenses,
  required List<Map<String, dynamic>> settlements,
  required Iterable<String> memberIds,
}) {
  final balances = <String, int>{for (final id in memberIds) id: 0};
  void merge(Map<String, int> m) {
    for (final e in m.entries) {
      balances[e.key] = (balances[e.key] ?? 0) + e.value;
    }
  }

  var total = 0;
  DateTime? lastExpenseAt;
  var lastTitle = '';
  DateTime? lastActivity;
  void touch(DateTime? t) {
    if (t != null && (lastActivity == null || t.isAfter(lastActivity!))) {
      lastActivity = t;
    }
  }

  for (final e in expenses) {
    merge(expenseContribution(e));
    total += toMinor(e.amount);
    if (lastExpenseAt == null || !e.createdAt.isBefore(lastExpenseAt)) {
      lastExpenseAt = e.createdAt;
      lastTitle = e.title;
    }
    touch(e.createdAt);
  }
  for (final s in settlements) {
    merge(settlementContribution(s));
    touch(s['createdAt'] as DateTime?);
  }

  return RebuiltSummary(
    balances: balances,
    totalSpentMinor: total,
    expenseCount: expenses.length,
    lastExpenseTitle: lastTitle,
    lastActivityAt: lastActivity,
  );
}
