import 'dart:math' as math;

/// Validation for a proposed settle-up payment.
///
/// Split into two tiers, deliberately:
///
///  - **Hard rules** that must hold for the payment to make any sense at all
///    (positive amount, distinct users who both belong to the group). These
///    block the settlement.
///  - **Advisories** about the payment's relationship to current balances
///    (does the payer actually owe? does the receiver get owed? is this an
///    overpayment?). These NEVER block — PayPact follows Splitwise's permissive
///    model where you may pay anyone any amount and the excess simply flips the
///    balance. They exist so the UI can pre-fill "the amount that clears" and
///    warn before creating a reverse balance.
///
/// All amounts are integer paise. Net balances follow the same sign convention
/// as `computeNetBalances`: positive => creditor (owed money), negative =>
/// debtor (owes money).

/// Why a settlement was rejected (hard failure only).
enum SettlementError {
  nonPositiveAmount,
  sameUser,
  payerNotMember,
  receiverNotMember,
}

extension SettlementErrorMessage on SettlementError {
  /// Human-facing message suitable for a snackbar.
  String get message => switch (this) {
        SettlementError.nonPositiveAmount =>
          'Enter an amount greater than zero.',
        SettlementError.sameUser =>
          "You can't settle up with yourself.",
        SettlementError.payerNotMember =>
          'The payer is not a member of this group.',
        SettlementError.receiverNotMember =>
          'The recipient is not a member of this group.',
      };
}

class SettlementValidation {
  /// Null when the settlement passes all hard rules.
  final SettlementError? error;

  /// Payer currently owes money overall (net balance < 0).
  final bool payerOwes;

  /// Receiver is currently owed money overall (net balance > 0).
  final bool receiverOwed;

  /// The largest amount (paise) that reduces real debt without flipping anyone
  /// into the opposite position: `min(|payerDebt|, receiverCredit)`. Zero when
  /// there's nothing meaningful to clear in this direction. The UI can use this
  /// as the suggested "settles all open balances" amount.
  final int maxToClearPaise;

  /// True when the proposed amount exceeds [maxToClearPaise] — allowed, but it
  /// will create a reverse balance (Splitwise behaviour).
  final bool isOverpayment;

  const SettlementValidation({
    required this.error,
    required this.payerOwes,
    required this.receiverOwed,
    required this.maxToClearPaise,
    required this.isOverpayment,
  });

  /// True when no hard rule was violated. Advisories do not affect this.
  bool get isValid => error == null;
}

/// Validates a proposed settlement of [amountPaise] from [fromUserId] to
/// [toUserId], given the group's [memberIds] and current [netBalancesPaise].
SettlementValidation validateSettlement({
  required String fromUserId,
  required String toUserId,
  required int amountPaise,
  required List<String> memberIds,
  required Map<String, int> netBalancesPaise,
}) {
  final members = memberIds.toSet();

  // Advisories are computed regardless of hard-rule outcome so the UI always
  // has a meaningful "max to clear" to show.
  final payerNet = netBalancesPaise[fromUserId] ?? 0;
  final receiverNet = netBalancesPaise[toUserId] ?? 0;
  final payerOwes = payerNet < 0;
  final receiverOwed = receiverNet > 0;
  final maxToClear = math.max(0, math.min(-payerNet, receiverNet));
  final isOverpayment = amountPaise > maxToClear;

  SettlementError? error;
  if (amountPaise <= 0) {
    error = SettlementError.nonPositiveAmount;
  } else if (fromUserId == toUserId) {
    error = SettlementError.sameUser;
  } else if (!members.contains(fromUserId)) {
    error = SettlementError.payerNotMember;
  } else if (!members.contains(toUserId)) {
    error = SettlementError.receiverNotMember;
  }

  return SettlementValidation(
    error: error,
    payerOwes: payerOwes,
    receiverOwed: receiverOwed,
    maxToClearPaise: maxToClear,
    isOverpayment: isOverpayment,
  );
}
