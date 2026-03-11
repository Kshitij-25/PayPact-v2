import 'package:equatable/equatable.dart';

/// A simplified debt between two users after debt simplification algorithm
class DebtEntity extends Equatable {
  const DebtEntity({
    required this.debtorId,
    required this.creditorId,
    required this.amount,
    this.currency = 'USD',
  });

  final String debtorId;
  final String creditorId;
  final double amount;
  final String currency;

  DebtEntity copyWith({
    String? debtorId,
    String? creditorId,
    double? amount,
    String? currency,
  }) {
    return DebtEntity(
      debtorId: debtorId ?? this.debtorId,
      creditorId: creditorId ?? this.creditorId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
    );
  }

  @override
  List<Object?> get props => [debtorId, creditorId, amount, currency];
}
