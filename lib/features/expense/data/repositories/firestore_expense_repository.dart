import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paypact/features/expense/data/models/expense_model.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';

class FirestoreExpenseRepository implements ExpenseRepository {
  final FirebaseFirestore _firestore;

  FirestoreExpenseRepository(this._firestore);

  CollectionReference _expensesRef(String groupId) =>
      _firestore.collection('groups').doc(groupId).collection('expenses');

  CollectionReference _settlementsRef(String groupId) =>
      _firestore.collection('groups').doc(groupId).collection('settlements');

  @override
  Stream<List<ExpenseEntity>> watchGroupExpenses(String groupId) {
    return _expensesRef(groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ExpenseModel.fromFirestore(d, groupId)).toList());
  }

  @override
  Future<List<ExpenseEntity>> getGroupExpenses(String groupId) async {
    final snap = await _expensesRef(groupId)
        .orderBy('createdAt', descending: true)
        .get();
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
    required String category,
    required String paidById,
    required String paidByName,
    required List<ExpenseSplitEntity> splits,
    required String createdById,
  }) async {
    final model = ExpenseModel(
      id: '',
      groupId: groupId,
      title: title,
      amount: amount,
      category: category,
      paidById: paidById,
      paidByName: paidByName,
      splits: splits,
      createdAt: DateTime.now(),
      createdById: createdById,
    );
    final ref = await _expensesRef(groupId).add(model.toMap());
    final doc = await ref.get();
    return ExpenseModel.fromFirestore(doc, groupId);
  }

  @override
  Future<void> deleteExpense(String groupId, String expenseId) async {
    await _expensesRef(groupId).doc(expenseId).delete();
  }

  @override
  Future<void> recordSettlement({
    required String groupId,
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    required String toUserName,
    required double amount,
  }) async {
    await _settlementsRef(groupId).add({
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'toUserId': toUserId,
      'toUserName': toUserName,
      'amount': amount,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getGroupSettlements(
      String groupId) async {
    final snap = await _settlementsRef(groupId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .toList();
  }
}
