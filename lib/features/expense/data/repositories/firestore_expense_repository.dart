import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paypact/features/expense/data/models/expense_model.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/entities/expense_extras.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/settle/data/settlement_model.dart';
import 'package:paypact/features/settle/domain/settlement_entity.dart';

class FirestoreExpenseRepository implements ExpenseRepository {
  final FirebaseFirestore _firestore;

  FirestoreExpenseRepository(this._firestore);

  CollectionReference _expensesRef(String groupId) =>
      _firestore.collection('groups').doc(groupId).collection('expenses');

  CollectionReference _settlementsRef(String groupId) =>
      _firestore.collection('groups').doc(groupId).collection('settlements');

  @override
  Stream<List<ExpenseEntity>> watchGroupExpenses(String groupId, {int? limit}) {
    Query q = _expensesRef(groupId).orderBy('createdAt', descending: true);
    if (limit != null) q = q.limit(limit);
    return q
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ExpenseModel.fromFirestore(d, groupId)).toList());
  }

  @override
  Future<List<ExpenseEntity>> getGroupExpenses(String groupId,
      {DateTime? since, int? limit}) async {
    Query q = _expensesRef(groupId).orderBy('createdAt', descending: true);
    if (since != null) {
      q = q.where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(since));
    }
    if (limit != null) q = q.limit(limit);
    final snap = await q.get();
    return snap.docs.map((d) => ExpenseModel.fromFirestore(d, groupId)).toList();
  }

  @override
  Future<ExpenseEntity?> getExpense(String groupId, String expenseId) async {
    final doc = await _expensesRef(groupId).doc(expenseId).get();
    if (!doc.exists) return null;
    return ExpenseModel.fromFirestore(doc, groupId);
  }

  @override
  Future<ExpenseEntity> createExpense({
    required String groupId,
    required String title,
    required double amount,
    required double originalAmount,
    required String originalCurrency,
    required double exchangeRate,
    required String category,
    required String paidById,
    required String paidByName,
    required List<ExpenseSplitEntity> splits,
    required String createdById,
    DateTime? date,
    String? note,
    String? receiptUrl,
  }) async {
    final model = ExpenseModel(
      id: '',
      groupId: groupId,
      title: title,
      amount: amount,
      originalAmount: originalAmount,
      originalCurrency: originalCurrency,
      exchangeRate: exchangeRate,
      category: category,
      paidById: paidById,
      paidByName: paidByName,
      splits: splits,
      createdAt: DateTime.now(),
      createdById: createdById,
      date: date ?? DateTime.now(),
      note: _clean(note),
      receiptUrl: receiptUrl,
    );
    final ref = await _expensesRef(groupId).add(model.toMap());
    // Touch the group document so watchUserGroups fires and home balances refresh
    await _firestore
        .collection('groups')
        .doc(groupId)
        .update({'updatedAt': FieldValue.serverTimestamp()});
    final doc = await ref.get();
    return ExpenseModel.fromFirestore(doc, groupId);
  }

  @override
  Future<void> updateExpense({
    required String groupId,
    required String expenseId,
    required String title,
    required double amount,
    required double originalAmount,
    required String originalCurrency,
    required double exchangeRate,
    required String category,
    required String paidById,
    required String paidByName,
    required List<ExpenseSplitEntity> splits,
    DateTime? date,
    String? note,
    String? receiptUrl,
  }) async {
    final model = ExpenseModel(
      id: expenseId,
      groupId: groupId,
      title: title,
      amount: amount,
      originalAmount: originalAmount,
      originalCurrency: originalCurrency,
      exchangeRate: exchangeRate,
      category: category,
      paidById: paidById,
      paidByName: paidByName,
      splits: splits,
      createdAt: DateTime.now(),
      createdById: '',
      date: date ?? DateTime.now(),
      note: _clean(note),
      receiptUrl: receiptUrl,
    );
    await _expensesRef(groupId).doc(expenseId).update(model.toUpdateMap());
    // Touch the group document so watchUserGroups fires and balances refresh
    await _firestore
        .collection('groups')
        .doc(groupId)
        .update({'updatedAt': FieldValue.serverTimestamp()});
  }

  static String? _clean(String? s) {
    final t = s?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  @override
  Future<void> restoreExpense(ExpenseEntity e,
      {required String restoredById}) async {
    // Written under the restorer's id (the rules require the creator field to
    // match the writer) but keeping the original dates and content.
    final map = ExpenseModel(
      id: e.id,
      groupId: e.groupId,
      title: e.title,
      amount: e.amount,
      originalAmount: e.originalAmount,
      originalCurrency: e.originalCurrency,
      exchangeRate: e.exchangeRate,
      category: e.category,
      paidById: e.paidById,
      paidByName: e.paidByName,
      splits: e.splits,
      createdAt: e.createdAt,
      createdById: restoredById,
      date: e.date,
      note: e.note,
      receiptUrl: e.receiptUrl,
      recurringId: e.recurringId,
    ).toMap();
    map['createdAt'] = Timestamp.fromDate(e.createdAt);
    await _expensesRef(e.groupId).doc(e.id).set(map);
  }

  // ── Discussion & history ────────────────────────────────────────────────

  CollectionReference _comments(String g, String e) =>
      _expensesRef(g).doc(e).collection('comments');
  CollectionReference _history(String g, String e) =>
      _expensesRef(g).doc(e).collection('history');

  @override
  Stream<List<ExpenseComment>> watchComments(String groupId, String expenseId) =>
      _comments(groupId, expenseId).orderBy('createdAt').snapshots().map(
            (snap) => snap.docs.map((d) {
              final m = d.data() as Map<String, dynamic>;
              return ExpenseComment(
                id: d.id,
                authorId: m['authorId'] as String? ?? '',
                authorName: m['authorName'] as String? ?? '',
                text: m['text'] as String? ?? '',
                createdAt:
                    (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              );
            }).toList(),
          );

  @override
  Future<void> addComment(String groupId, String expenseId,
      {required String authorId,
      required String authorName,
      required String text}) async {
    await _comments(groupId, expenseId).add({
      'authorId': authorId,
      'authorName': authorName,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteComment(
          String groupId, String expenseId, String commentId) =>
      _comments(groupId, expenseId).doc(commentId).delete();

  @override
  Stream<List<ExpenseHistoryEntry>> watchHistory(
          String groupId, String expenseId) =>
      _history(groupId, expenseId)
          .orderBy('at', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map((d) {
                final m = d.data() as Map<String, dynamic>;
                return ExpenseHistoryEntry(
                  id: d.id,
                  by: m['by'] as String? ?? '',
                  byName: m['byName'] as String? ?? '',
                  changes: List<String>.from(m['changes'] as List? ?? []),
                  at: (m['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
                );
              }).toList());

  @override
  Future<void> addHistory(String groupId, String expenseId,
      {required String by,
      required String byName,
      required List<String> changes}) async {
    await _history(groupId, expenseId).add({
      'by': by,
      'byName': byName,
      'changes': changes,
      'at': FieldValue.serverTimestamp(),
    });
  }

  // ── Recurring ────────────────────────────────────────────────────────────

  CollectionReference _recurring(String g) =>
      _firestore.collection('groups').doc(g).collection('recurring');

  @override
  Stream<List<RecurringExpense>> watchRecurring(String groupId) =>
      _recurring(groupId).snapshots().map((snap) => snap.docs.map((d) {
            final m = d.data() as Map<String, dynamic>;
            return RecurringExpense(
              id: d.id,
              groupId: groupId,
              title: m['title'] as String? ?? '',
              amount: (m['amount'] as num?)?.toDouble() ?? 0,
              originalAmount: (m['originalAmount'] as num?)?.toDouble() ??
                  (m['amount'] as num?)?.toDouble() ??
                  0,
              originalCurrency: m['originalCurrency'] as String? ?? 'INR',
              exchangeRate: (m['exchangeRate'] as num?)?.toDouble() ?? 1,
              category: m['category'] as String? ?? 'other',
              paidById: m['paidById'] as String? ?? '',
              paidByName: m['paidByName'] as String? ?? '',
              splits: [
                for (final s in (m['splits'] as List? ?? []))
                  ExpenseSplitEntity(
                    userId: (s as Map)['userId'] as String,
                    userName: s['userName'] as String? ?? '',
                    amount: (s['amount'] as num).toDouble(),
                  ),
              ],
              interval: m['interval'] == 'weekly'
                  ? RecurrenceInterval.weekly
                  : RecurrenceInterval.monthly,
              nextRunAt:
                  (m['nextRunAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              active: m['active'] as bool? ?? true,
              createdById: m['createdById'] as String? ?? '',
              createdByName: m['createdByName'] as String? ?? '',
              note: m['note'] as String?,
            );
          }).toList()
            ..sort((a, b) => a.nextRunAt.compareTo(b.nextRunAt)));

  @override
  Future<void> createRecurring(RecurringExpense t) async {
    await _recurring(t.groupId).add({
      'title': t.title,
      'amount': t.amount,
      'originalAmount': t.originalAmount,
      'originalCurrency': t.originalCurrency,
      'exchangeRate': t.exchangeRate,
      'category': t.category,
      'paidById': t.paidById,
      'paidByName': t.paidByName,
      'splits': [
        for (final s in t.splits)
          {'userId': s.userId, 'userName': s.userName, 'amount': s.amount},
      ],
      'interval':
          t.interval == RecurrenceInterval.weekly ? 'weekly' : 'monthly',
      'nextRunAt': Timestamp.fromDate(t.nextRunAt),
      'active': t.active,
      'createdById': t.createdById,
      'createdByName': t.createdByName,
      'note': _clean(t.note),
    });
  }

  @override
  Future<void> setRecurringActive(
          String groupId, String recurringId, bool active) =>
      _recurring(groupId).doc(recurringId).update({'active': active});

  @override
  Future<void> deleteRecurring(String groupId, String recurringId) =>
      _recurring(groupId).doc(recurringId).delete();

  @override
  Future<void> deleteExpense(String groupId, String expenseId) async {
    await _expensesRef(groupId).doc(expenseId).delete();
  }

  @override
  Future<SettlementEntity> recordSettlement({
    required String groupId,
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    required String toUserName,
    required int amountPaise,
    required String currency,
    required String createdById,
    required String idempotencyKey,
    required String receiptId,
    String paymentMethod = PaymentMethod.cash,
    String status = PaymentStatus.completed,
    String? note,
    String? provider,
    String type = kSettlementType,
    String? reversesId,
  }) async {
    // The idempotency key IS the document id: writing the same settlement twice
    // (double-tap, retry) lands on the same doc, so we can detect and skip it.
    final settlementRef = _settlementsRef(groupId).doc(idempotencyKey);
    final groupRef = _firestore.collection('groups').doc(groupId);

    final model = SettlementModel(
      id: idempotencyKey,
      groupId: groupId,
      type: type,
      reversesId: reversesId,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      toUserId: toUserId,
      toUserName: toUserName,
      amountPaise: amountPaise,
      currency: currency,
      note: note,
      paymentMethod: paymentMethod,
      status: status,
      provider: provider,
      createdById: createdById,
      idempotencyKey: idempotencyKey,
      receiptId: receiptId,
      createdAt: DateTime.now(),
    );

    // Single transaction makes the settlement-create and the group touch atomic,
    // and guarantees the duplicate check + write can't interleave.
    return _firestore.runTransaction<SettlementEntity>((txn) async {
      final existing = await txn.get(settlementRef);
      if (existing.exists) {
        // Already recorded under this key — return it unchanged (no double pay).
        return SettlementModel.fromFirestore(existing, groupId);
      }
      txn.set(settlementRef, model.toMap());
      // Touch group so watchUserGroups fires and home balances refresh.
      txn.update(groupRef, {'updatedAt': FieldValue.serverTimestamp()});
      return model;
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getGroupSettlements(String groupId,
      {DateTime? since, int? limit}) async {
    Query q = _settlementsRef(groupId).orderBy('createdAt', descending: true);
    if (since != null) {
      q = q.where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(since));
    }
    if (limit != null) q = q.limit(limit);
    final snap = await q.get();
    return snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      final ts = data['createdAt'];
      return {
        'id': d.id,
        ...data,
        'createdAt': ts is Timestamp ? ts.toDate() : null,
      };
    }).toList();
  }
}
