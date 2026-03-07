import 'package:equatable/equatable.dart';

class ExpenseSplitEntity extends Equatable {
  const ExpenseSplitEntity({
    required this.userId,
    required this.amount,
    this.percentage,
    this.shares,
    this.isSettled = false,
  });

  final String userId;
  final double amount;
  final double? percentage;
  final int? shares;
  final bool isSettled;

  ExpenseSplitEntity copyWith({
    String? userId,
    double? amount,
    double? percentage,
    int? shares,
    bool? isSettled,
  }) {
    return ExpenseSplitEntity(
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      percentage: percentage ?? this.percentage,
      shares: shares ?? this.shares,
      isSettled: isSettled ?? this.isSettled,
    );
  }

  @override
  List<Object?> get props => [userId, amount, percentage, shares, isSettled];
}
