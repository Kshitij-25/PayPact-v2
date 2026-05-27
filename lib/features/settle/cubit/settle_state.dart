part of 'settle_cubit.dart';

abstract class SettleState {}

class SettleInitial extends SettleState {}

class SettleLoading extends SettleState {}

class SettleSuccess extends SettleState {
  final String receiptId;
  final String fromUserName;
  final String toUserName;
  final double amount;

  SettleSuccess({
    required this.receiptId,
    required this.fromUserName,
    required this.toUserName,
    required this.amount,
  });
}

class SettleError extends SettleState {
  final String message;
  SettleError(this.message);
}
