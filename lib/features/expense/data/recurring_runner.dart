import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paypact/features/expense/data/models/expense_model.dart';
import 'package:paypact/features/expense/data/repositories/firestore_expense_repository.dart';
import 'package:paypact/features/expense/domain/expense_changes.dart';
import 'package:paypact/features/group/domain/group_summary.dart';
import 'package:paypact/features/notification/domain/repositories/notifications_repository.dart';

/// Turns due recurring-expense templates into real expenses.
///
/// There's no scheduled server job on the free plan, so whoever in the group
/// opens the app first after a template falls due creates the expenses (a
/// monthly rent logged "on the 1st" appears the next time anyone opens the
/// app). The work happens in a transaction that re-reads the template, so two
/// members opening the app at once can't both create the same occurrence.
class RecurringRunner {
  RecurringRunner(this._firestore, this._notifications, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final FirebaseFirestore _firestore;
  final NotificationsRepository _notifications;
  final DateTime Function() _now;

  final Set<String> _checked = {};

  /// Checks one group, at most once per session. Returns how many expenses
  /// were created. Never throws: this is background housekeeping.
  Future<int> runForGroup({
    required String groupId,
    required String groupName,
    required List<String> memberIds,
    required String actorId,
    required String actorName,
  }) async {
    if (!_checked.add(groupId)) return 0;
    try {
      return await _run(groupId, groupName, memberIds, actorId, actorName);
    } catch (_) {
      _checked.remove(groupId); // retry on the next refresh
      return 0;
    }
  }

  Future<int> _run(String groupId, String groupName, List<String> memberIds,
      String actorId, String actorName) async {
    final now = _now();
    final groupRef = _firestore.collection('groups').doc(groupId);
    final due = await groupRef
        .collection('recurring')
        .where('nextRunAt', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .get();

    var created = 0;
    for (final doc in due.docs) {
      final template = FirestoreExpenseRepository.recurringFromMap(
          doc.id, groupId, doc.data());
      if (!template.active) continue;

      // The owner or payer left: stop the template instead of running it.
      if (!memberIds.contains(template.createdById) ||
          !memberIds.contains(template.paidById)) {
        await doc.reference.update({'active': false});
        continue;
      }

      final made = await _firestore.runTransaction<int>((txn) async {
        final fresh = await txn.get(doc.reference);
        final data = fresh.data();
        if (data == null || data['active'] == false) return 0;
        final t = FirestoreExpenseRepository.recurringFromMap(
            doc.id, groupId, data);
        final plan = dueOccurrences(t.nextRunAt, t.interval, now);
        if (plan.due.isEmpty) return 0; // another member already ran it

        final group = await txn.get(groupRef);
        final withSummary =
            groupHasSummary(group.data());

        var delta = const SummaryDelta({}, 0, 0);
        for (final date in plan.due) {
          final expense = ExpenseModel(
            id: '',
            groupId: groupId,
            title: t.title,
            amount: t.amount,
            originalAmount: t.originalAmount,
            originalCurrency: t.originalCurrency,
            exchangeRate: t.exchangeRate,
            category: t.category,
            paidById: t.paidById,
            paidByName: t.paidByName,
            splits: t.splits,
            createdAt: now,
            createdById: t.createdById,
            date: date,
            note: t.note,
            recurringId: t.id,
          );
          txn.set(groupRef.collection('expenses').doc(), expense.toMap());
          delta = delta + expenseDelta(null, expense);
        }
        txn.update(doc.reference, {
          'nextRunAt': Timestamp.fromDate(plan.next),
          'lastRunAt': Timestamp.fromDate(now),
        });
        txn.update(groupRef, {
          'updatedAt': FieldValue.serverTimestamp(),
          if (withSummary) ...summaryUpdate(delta, title: t.title),
        });
        return plan.due.length;
      });

      if (made == 0) continue;
      created += made;
      // Tell the others (their own preferences decide whether it is shown).
      for (final m in memberIds.where((m) => m != actorId)) {
        await _notifications
            .push(
              targetUserId: m,
              type: 'expense_added',
              title: 'Recurring expense added',
              body: '"${template.title}" was added to $groupName.',
              groupId: groupId,
              groupName: groupName,
              actorId: actorId,
              actorName: actorName,
            )
            .catchError((_) {});
      }
    }
    return created;
  }
}
