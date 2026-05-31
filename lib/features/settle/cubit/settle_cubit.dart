import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/features/notification/domain/repositories/notifications_repository.dart';
import 'package:paypact/features/settle/domain/debt_simplifier.dart';
import 'package:paypact/features/settle/domain/settlement_entity.dart';
import 'package:paypact/features/settle/domain/settlement_validator.dart';

part 'settle_state.dart';

class SettleCubit extends Cubit<SettleState> {
  final ExpenseRepository _expenseRepo;
  final NotificationsRepository _notifRepo;
  final GroupRepository _groupRepo;

  SettleCubit(this._expenseRepo, this._notifRepo, this._groupRepo)
      : super(SettleInitial());

  Future<void> settle({
    required String groupId,
    required String groupName,
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    required String toUserName,
    required double amount,
    required String idempotencyKey,
    String paymentMethod = PaymentMethod.cash,
    String? note,
  }) async {
    try {
      emit(SettleLoading());

      // ── Recompute current balances from the immutable ledger, in paise ──
      final group = await _groupRepo.getGroup(groupId);
      if (group == null) {
        emit(SettleError('Group not found.'));
        return;
      }
      final expenses = await _expenseRepo.getGroupExpenses(groupId);
      final settlements = await _expenseRepo.getGroupSettlements(groupId);
      final netBalances = computeNetBalances(
        expenses: expenses,
        settlements: settlements,
        memberIds: group.memberIds,
      );

      // ── Validate (hard rules block; overpayment is allowed) ──
      final amountPaise = toPaise(amount);
      final validation = validateSettlement(
        fromUserId: fromUserId,
        toUserId: toUserId,
        amountPaise: amountPaise,
        memberIds: group.memberIds,
        netBalancesPaise: netBalances,
      );
      if (!validation.isValid) {
        emit(SettleError(validation.error!.message));
        return;
      }

      // ── Record the payment (idempotent + atomic in the repository) ──
      final receiptId =
          'PP-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
      final settlement = await _expenseRepo.recordSettlement(
        groupId: groupId,
        fromUserId: fromUserId,
        fromUserName: fromUserName,
        toUserId: toUserId,
        toUserName: toUserName,
        amountPaise: amountPaise,
        currency: group.currency,
        createdById: fromUserId,
        idempotencyKey: idempotencyKey,
        receiptId: receiptId,
        paymentMethod: paymentMethod,
        note: note,
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

      emit(SettleSuccess(
        receiptId: settlement.receiptId,
        fromUserName: fromUserName,
        toUserName: toUserName,
        amount: settlement.amount,
      ));
    } catch (e) {
      emit(SettleError(e.toString()));
    }
  }
}
