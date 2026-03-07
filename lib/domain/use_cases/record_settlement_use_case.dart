import 'package:dartz/dartz.dart';
import 'package:paypact/core/failures/faliures.dart';
import 'package:paypact/domain/entities/settlement_entity.dart';
import 'package:paypact/domain/repositories/expense_repository.dart';
import 'package:uuid/uuid.dart';

class RecordSettlementParams {
  const RecordSettlementParams({
    required this.groupId,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    this.currency = 'USD',
    this.note,
  });
  final String groupId;
  final String fromUserId;
  final String toUserId;
  final double amount;
  final String currency;
  final String? note;
}

class RecordSettlementUseCase {
  const RecordSettlementUseCase(this._repository);
  final ExpenseRepository _repository;

  Future<Either<Failure, SettlementEntity>> call(
      RecordSettlementParams params) {
    final settlement = SettlementEntity(
      id: const Uuid().v4(),
      groupId: params.groupId,
      fromUserId: params.fromUserId,
      toUserId: params.toUserId,
      amount: params.amount,
      createdAt: DateTime.now(),
      currency: params.currency,
      note: params.note,
      status: SettlementStatus.completed,
      settledAt: DateTime.now(),
    );
    return _repository.recordSettlement(settlement);
  }
}
