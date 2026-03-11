import 'package:equatable/equatable.dart';

enum SettlementStatus { pending, completed, cancelled }

class SettlementEntity extends Equatable {
  const SettlementEntity({
    required this.id,
    required this.groupId,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.createdAt,
    this.currency = 'USD',
    this.status = SettlementStatus.pending,
    this.settledAt,
    this.note,
  });

  final String id;
  final String groupId;
  final String fromUserId;
  final String toUserId;
  final double amount;
  final DateTime createdAt;
  final String currency;
  final SettlementStatus status;
  final DateTime? settledAt;
  final String? note;

  bool get isCompleted => status == SettlementStatus.completed;

  SettlementEntity copyWith({
    String? id,
    String? groupId,
    String? fromUserId,
    String? toUserId,
    double? amount,
    DateTime? createdAt,
    String? currency,
    SettlementStatus? status,
    DateTime? settledAt,
    String? note,
  }) {
    return SettlementEntity(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      settledAt: settledAt ?? this.settledAt,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [
        id,
        groupId,
        fromUserId,
        toUserId,
        amount,
        createdAt,
        currency,
        status,
        settledAt,
        note
      ];
}
