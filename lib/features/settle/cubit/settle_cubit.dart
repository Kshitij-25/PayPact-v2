import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/notification/domain/repositories/notifications_repository.dart';

part 'settle_state.dart';

class SettleCubit extends Cubit<SettleState> {
  final ExpenseRepository _expenseRepo;
  final NotificationsRepository _notifRepo;

  SettleCubit(this._expenseRepo, this._notifRepo) : super(SettleInitial());

  Future<void> settle({
    required String groupId,
    required String groupName,
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    required String toUserName,
    required double amount,
  }) async {
    try {
      emit(SettleLoading());
      await _expenseRepo.recordSettlement(
        groupId: groupId,
        fromUserId: fromUserId,
        fromUserName: fromUserName,
        toUserId: toUserId,
        toUserName: toUserName,
        amount: amount,
      );
      await _notifRepo.push(
        targetUserId: toUserId,
        type: 'settlement',
        title: '$fromUserName settled up',
        body:
            '$fromUserName paid you ₹${amount.toStringAsFixed(0)} in $groupName',
        groupId: groupId,
        groupName: groupName,
        actorId: fromUserId,
        actorName: fromUserName,
      );
      final receiptId =
          'PP-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
      emit(SettleSuccess(
        receiptId: receiptId,
        fromUserName: fromUserName,
        toUserName: toUserName,
        amount: amount,
      ));
    } catch (e) {
      emit(SettleError(e.toString()));
    }
  }
}
