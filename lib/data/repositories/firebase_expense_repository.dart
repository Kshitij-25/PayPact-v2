import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:paypact/core/failures/faliures.dart';
import 'package:paypact/core/services/debt_simplification_service.dart';
import 'package:paypact/data/models/expense_model.dart';
import 'package:paypact/domain/entities/debt_entity.dart';
import 'package:paypact/domain/entities/expense_entity.dart';
import 'package:paypact/domain/entities/settlement_entity.dart';
import 'package:paypact/domain/repositories/expense_repository.dart';

class FirebaseExpenseRepository implements ExpenseRepository {
  FirebaseExpenseRepository({
    required FirebaseFirestore firestore,
    required DebtSimplificationService debtService,
  })  : _firestore = firestore,
        _debtService = debtService;

  final FirebaseFirestore _firestore;
  final DebtSimplificationService _debtService;

  static const _expenses = 'expenses';
  static const _settlements = 'settlements';
  static const _groups = 'groups';

  @override
  Stream<List<ExpenseEntity>> watchGroupExpenses(String groupId) {
    return _firestore
        .collection(_expenses)
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ExpenseModel.fromFirestore(d.data(), d.id).toEntity())
            .toList());
  }

  @override
  Stream<List<ExpenseEntity>> watchUserExpenses(List<String> groupIds) {
    if (groupIds.isEmpty) return const Stream.empty();
    // Firestore whereIn supports up to 30 values; chunk if needed
    final ids = groupIds.take(30).toList();
    return _firestore
        .collection(_expenses)
        .where('groupId', whereIn: ids)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ExpenseModel.fromFirestore(d.data(), d.id).toEntity())
            .toList());
  }

  @override
  Stream<List<SettlementEntity>> watchUserSettlements(List<String> groupIds) {
    if (groupIds.isEmpty) return const Stream.empty();
    final ids = groupIds.take(30).toList();
    return _firestore
        .collection(_settlements)
        .where('groupId', whereIn: ids)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final m = d.data();
              return SettlementEntity(
                id: m['id'] as String,
                groupId: m['groupId'] as String,
                fromUserId: m['fromUserId'] as String,
                toUserId: m['toUserId'] as String,
                amount: (m['amount'] as num).toDouble(),
                createdAt: (m['createdAt'] as Timestamp).toDate(),
                currency: m['currency'] as String? ?? 'USD',
                status: SettlementStatus.values.firstWhere(
                  (s) => s.name == m['status'],
                  orElse: () => SettlementStatus.completed,
                ),
                note: m['note'] as String?,
              );
            }).toList());
  }

  @override
  Future<Either<Failure, ExpenseEntity>> getExpenseById(
      String expenseId) async {
    try {
      final doc = await _firestore.collection(_expenses).doc(expenseId).get();
      if (!doc.exists) return const Left(NotFoundFailure('Expense not found'));
      return Right(ExpenseModel.fromFirestore(doc.data()!, doc.id).toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExpenseEntity>> createExpense(
      ExpenseEntity expense) async {
    try {
      final model = ExpenseModel.fromEntity(expense);
      await _firestore
          .collection(_expenses)
          .doc(expense.id)
          .set(model.toFirestore());
      // Update group total
      await _updateGroupTotalAndBalances(expense, isAdd: true);
      return Right(expense);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExpenseEntity>> updateExpense(
      ExpenseEntity expense) async {
    try {
      // Fetch old expense to reverse its balance effects
      final oldDoc =
          await _firestore.collection(_expenses).doc(expense.id).get();
      if (oldDoc.exists) {
        final old =
            ExpenseModel.fromFirestore(oldDoc.data()!, oldDoc.id).toEntity();
        await _updateGroupTotalAndBalances(old, isAdd: false);
      }
      final model = ExpenseModel.fromEntity(expense);
      await _firestore
          .collection(_expenses)
          .doc(expense.id)
          .update(model.toFirestore());
      await _updateGroupTotalAndBalances(expense, isAdd: true);
      return Right(expense);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteExpense(String expenseId) async {
    try {
      final doc = await _firestore.collection(_expenses).doc(expenseId).get();
      if (doc.exists) {
        final expense =
            ExpenseModel.fromFirestore(doc.data()!, doc.id).toEntity();
        await _updateGroupTotalAndBalances(expense, isAdd: false);
      }
      await _firestore.collection(_expenses).doc(expenseId).delete();
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ExpenseEntity>>> getExpensesByUser(
    String groupId,
    String userId,
  ) async {
    try {
      final snap = await _firestore
          .collection(_expenses)
          .where('groupId', isEqualTo: groupId)
          .orderBy('createdAt', descending: true)
          .get();
      final expenses = snap.docs
          .map((d) => ExpenseModel.fromFirestore(d.data(), d.id).toEntity())
          .where((e) =>
              e.paidBy.containsKey(userId) ||
              e.splits.any((s) => s.userId == userId))
          .toList();
      return Right(expenses);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SettlementEntity>> recordSettlement(
    SettlementEntity settlement,
  ) async {
    try {
      final data = {
        'id': settlement.id,
        'groupId': settlement.groupId,
        'fromUserId': settlement.fromUserId,
        'toUserId': settlement.toUserId,
        'amount': settlement.amount,
        'createdAt': settlement.createdAt,
        'currency': settlement.currency,
        'status': settlement.status.name,
        'settledAt': settlement.settledAt,
        'note': settlement.note,
      };
      await _firestore.collection(_settlements).doc(settlement.id).set(data);
      // Adjust group member balances
      await _adjustBalancesForSettlement(settlement);
      return Right(settlement);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<SettlementEntity>> watchGroupSettlements(String groupId) {
    return _firestore
        .collection(_settlements)
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final m = d.data();
              return SettlementEntity(
                id: m['id'] as String,
                groupId: m['groupId'] as String,
                fromUserId: m['fromUserId'] as String,
                toUserId: m['toUserId'] as String,
                amount: (m['amount'] as num).toDouble(),
                createdAt: DateTime.fromMillisecondsSinceEpoch(
                  (m['createdAt'] as Timestamp).millisecondsSinceEpoch,
                ),
                currency: m['currency'] as String? ?? 'USD',
                status: SettlementStatus.values.firstWhere(
                  (s) => s.name == m['status'],
                  orElse: () => SettlementStatus.completed,
                ),
                note: m['note'] as String?,
              );
            }).toList());
  }

  @override
  Future<Either<Failure, List<DebtEntity>>> getSimplifiedDebts(
      String groupId) async {
    try {
      // Fetch balances and group currency in parallel
      final groupDoc = await _firestore.collection(_groups).doc(groupId).get();
      final currency = (groupDoc.data()?['currency'] as String?) ?? 'USD';

      final balancesResult = await getUserBalances(groupId);
      return balancesResult.fold(
        Left.new,
        (b) => Right(_debtService.simplify(b, currency: currency)),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, double>>> getUserBalances(
      String groupId) async {
    try {
      final doc = await _firestore.collection(_groups).doc(groupId).get();
      if (!doc.exists) return const Left(NotFoundFailure('Group not found'));
      final members = (doc.data()!['members'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final balances = <String, double>{};
      for (final m in members) {
        balances[m['userId'] as String] =
            (m['balance'] as num?)?.toDouble() ?? 0.0;
      }
      return Right(balances);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<void> _updateGroupTotalAndBalances(
    ExpenseEntity expense, {
    required bool isAdd,
  }) async {
    final sign = isAdd ? 1 : -1;
    final groupRef = _firestore.collection(_groups).doc(expense.groupId);
    await _firestore.runTransaction((tx) async {
      final doc = await tx.get(groupRef);
      if (!doc.exists) return;
      final members = List<Map<String, dynamic>>.from(
        (doc.data()!['members'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>(),
      );
      final updatedMembers = members.map((m) {
        final userId = m['userId'] as String;
        final netChange = expense.netBalanceFor(userId) * sign;
        return {
          ...m,
          'balance': ((m['balance'] as num?)?.toDouble() ?? 0.0) + netChange
        };
      }).toList();
      tx.update(groupRef, {
        'members': updatedMembers,
        'totalExpenses': FieldValue.increment(expense.amount * sign),
      });
    });
  }

  Future<void> _adjustBalancesForSettlement(SettlementEntity s) async {
    final groupRef = _firestore.collection(_groups).doc(s.groupId);
    await _firestore.runTransaction((tx) async {
      final doc = await tx.get(groupRef);
      if (!doc.exists) return;
      final members = List<Map<String, dynamic>>.from(
        (doc.data()!['members'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>(),
      );
      final updatedMembers = members.map((m) {
        final uid = m['userId'] as String;
        double balance = (m['balance'] as num?)?.toDouble() ?? 0.0;
        if (uid == s.fromUserId) balance += s.amount;
        if (uid == s.toUserId) balance -= s.amount;
        return {...m, 'balance': balance};
      }).toList();
      tx.update(groupRef, {'members': updatedMembers});
    });
  }
}
