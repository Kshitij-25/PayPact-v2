import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/core/utils/currency_utils.dart';
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
      // The server-maintained summary is the ledger's running total; only
      // groups that predate it need the full history re-read.
      final Map<String, int> netBalances;
      if (group.hasSummary) {
        netBalances = group.balances!;
      } else {
        netBalances = computeNetBalances(
          expenses: await _expenseRepo.getGroupExpenses(groupId),
          settlements: await _expenseRepo.getGroupSettlements(groupId),
          memberIds: group.memberIds,
        );
      }

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
            '$fromUserName paid you ${currencySymbol(group.currency)}${amount.toStringAsFixed(0)} in $groupName',
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

  /// Undoes a settlement by appending its opposite (settlements are an
  /// immutable ledger, so nothing is edited or deleted). Only the person who
  /// *received* the payment can reverse it — "this never arrived" — and each
  /// settlement can be reversed once (the reversal's id is derived from it).
  /// Returns an error message, or null on success.
  Future<String?> reverseSettlement({
    required String groupId,
    required String groupName,
    required String settlementId,
    required String payerId,
    required String payerName,
    required String payeeId,
    required String payeeName,
    required int amountPaise,
    required String currency,
    String? note,
  }) async {
    try {
      await _expenseRepo.recordSettlement(
        groupId: groupId,
        fromUserId: payeeId,
        fromUserName: payeeName,
        toUserId: payerId,
        toUserName: payerName,
        amountPaise: amountPaise,
        currency: currency,
        createdById: payeeId,
        idempotencyKey: 'rev_$settlementId',
        receiptId: 'PP-REV-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}',
        note: note ?? 'Reversal: payment not received',
        type: kReversalType,
        reversesId: settlementId,
        paymentMethod: PaymentMethod.cash,
      );
      await _notifRepo.push(
        targetUserId: payerId,
        type: 'settlement',
        title: '$payeeName reversed a payment',
        body:
            '$payeeName marked ${currencySymbol(currency)}${(amountPaise / 100).toStringAsFixed(0)} in $groupName as not received.',
        groupId: groupId,
        groupName: groupName,
        actorId: payeeId,
        actorName: payeeName,
      );
      return null;
    } catch (e) {
      return "Couldn't reverse that payment. Try again.";
    }
  }
}
