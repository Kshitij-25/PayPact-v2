import 'dart:math' as math;

import 'package:paypact/features/expense/domain/entities/expense_entity.dart';

/// Splitwise-style "Simplify Debts".
///
/// The guiding idea (and the reason this lives in the domain layer instead of a
/// widget): we do **not** preserve the original payment graph. Once every
/// member's net balance is known, the original "who paid whom" edges are
/// irrelevant. We build a brand-new minimized settlement graph that reproduces
/// the exact same net balances with as few transactions as possible.
///
/// All arithmetic happens in **integer paise** (1 paise = 1/100 rupee). Currency
/// must never be added/subtracted as `double` — repeated float operations drift
/// (e.g. `0.1 + 0.2 != 0.3`) and a debt-simplification routine that loses a paise
/// here and there produces settlements that don't reconcile. Doubles only appear
/// at the boundaries, converted via [toPaise] / [fromPaise].

// ─────────────────────────────────────────────────────────────────────────────
// Money helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Converts rupees (as the rest of the app stores them) to integer paise,
/// rounding once at the boundary so all downstream math is exact.
int toPaise(double rupees) => (rupees * 100).round();

/// Converts integer paise back to rupees for display.
double fromPaise(int paise) => paise / 100.0;

// ─────────────────────────────────────────────────────────────────────────────
// Output model
// ─────────────────────────────────────────────────────────────────────────────

/// A single settlement instruction in the minimized graph: [fromUserId] pays
/// [toUserId] exactly [amountPaise]. This may be between two members who never
/// directly transacted — that is intentional and matches Splitwise.
class SimplifiedDebt {
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;

  /// Amount owed, in integer paise. Always > 0.
  final int amountPaise;

  const SimplifiedDebt({
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.amountPaise,
  });

  /// Amount in rupees, for currency formatting in the UI.
  double get amount => fromPaise(amountPaise);

  @override
  bool operator ==(Object other) =>
      other is SimplifiedDebt &&
      other.fromUserId == fromUserId &&
      other.toUserId == toUserId &&
      other.amountPaise == amountPaise;

  @override
  int get hashCode => Object.hash(fromUserId, toUserId, amountPaise);

  @override
  String toString() =>
      'SimplifiedDebt($fromUserId -> $toUserId: $amountPaise paise)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — Net balances
// ─────────────────────────────────────────────────────────────────────────────

/// Computes each member's net balance across all expenses and recorded
/// settlements, in integer paise.
///
///   net_balance[user] = (what others owe user) - (what user owes others)
///
/// Positive => creditor (should receive money). Negative => debtor (owes money).
/// The sum over all members is always zero (modulo a possible paise of rounding
/// drift introduced by per-split rounding, which [simplifyDebtsFromBalances]
/// corrects before settling).
///
/// This mirrors the per-split accrual the app already uses: for every expense,
/// each split that isn't the payer's own share is credited to the payer and
/// debited from that member. Recorded settlements move balance back the other
/// way (a settlement is the debtor paying the creditor).
Map<String, int> computeNetBalances({
  required List<ExpenseEntity> expenses,
  required List<Map<String, dynamic>> settlements,
  required List<String> memberIds,
}) {
  final balances = {for (final id in memberIds) id: 0};

  // Ensures a member referenced by an expense/settlement but not in [memberIds]
  // (e.g. a since-removed member with open balances) still reconciles.
  void add(String userId, int paise) {
    balances[userId] = (balances[userId] ?? 0) + paise;
  }

  for (final expense in expenses) {
    for (final split in expense.splits) {
      if (split.userId == expense.paidById) continue; // payer's own share nets out
      final paise = toPaise(split.amount);
      add(expense.paidById, paise);
      add(split.userId, -paise);
    }
  }

  for (final settlement in settlements) {
    final from = settlement['fromUserId'] as String;
    final to = settlement['toUserId'] as String;
    // Prefer the authoritative integer paise; fall back to the legacy rupee
    // `amount` for settlements written before the paise field existed.
    final rawPaise = (settlement['amountPaise'] as num?)?.toInt();
    final paise =
        rawPaise ?? toPaise((settlement['amount'] as num?)?.toDouble() ?? 0);
    // The debtor paying reduces what they owe (their balance rises toward 0);
    // the creditor receiving reduces what they're owed.
    add(from, paise);
    add(to, -paise);
  }

  return balances;
}

// ─────────────────────────────────────────────────────────────────────────────
// Steps 2 & 3 — Split into creditors/debtors, then greedily minimize
// ─────────────────────────────────────────────────────────────────────────────

/// Internal mutable party (a creditor or debtor) used during settlement.
class _Party {
  final String userId;
  int amount; // remaining absolute amount in paise, always > 0 on entry
  _Party(this.userId, this.amount);
}

/// Builds a minimized settlement graph from net balances (in paise).
///
/// Uses a two-pointer greedy: sort creditors and debtors largest-first, then
/// repeatedly settle the biggest debtor against the biggest creditor for
/// `min(debt, credit)`. Each transaction zeroes out at least one party, so the
/// graph has at most `n - 1` edges for `n` non-zero members — aggressively
/// fewer than the original pairwise edges.
///
/// Output is deterministic: ties broken by `userId` so identical input always
/// yields an identical list. Zero-balance members are ignored entirely.
List<SimplifiedDebt> simplifyDebts(
  Map<String, int> netPaise,
  Map<String, String> names,
) {
  final creditors = <_Party>[];
  final debtors = <_Party>[];

  for (final entry in netPaise.entries) {
    if (entry.value > 0) {
      creditors.add(_Party(entry.key, entry.value));
    } else if (entry.value < 0) {
      debtors.add(_Party(entry.key, -entry.value)); // store absolute owed amount
    }
    // entry.value == 0 => settled, skip.
  }

  // Largest first, then userId ascending for deterministic output.
  int byAmountDescThenId(_Party a, _Party b) {
    final cmp = b.amount.compareTo(a.amount);
    return cmp != 0 ? cmp : a.userId.compareTo(b.userId);
  }

  creditors.sort(byAmountDescThenId);
  debtors.sort(byAmountDescThenId);

  String nameOf(String id) => names[id] ?? 'Member';

  final result = <SimplifiedDebt>[];
  var i = 0; // debtors pointer
  var j = 0; // creditors pointer

  while (i < debtors.length && j < creditors.length) {
    final debtor = debtors[i];
    final creditor = creditors[j];
    final settlement = math.min(debtor.amount, creditor.amount);

    result.add(SimplifiedDebt(
      fromUserId: debtor.userId,
      fromUserName: nameOf(debtor.userId),
      toUserId: creditor.userId,
      toUserName: nameOf(creditor.userId),
      amountPaise: settlement,
    ));

    debtor.amount -= settlement;
    creditor.amount -= settlement;

    if (debtor.amount == 0) i++;
    if (creditor.amount == 0) j++;
  }

  return result;
}

/// UI-facing convenience: simplify directly from rupee balances (the shape the
/// app already computes for display).
///
/// Converts to paise and applies **residual-drift correction**: rounding each
/// balance independently can leave the paise totals off zero by a paise or two.
/// We fold that residual into the largest-magnitude balance so the set is
/// exactly zero-sum before settling — otherwise the two-pointer pass could leave
/// a stray unsettled paise.
List<SimplifiedDebt> simplifyDebtsFromBalances(
  Map<String, double> rupeeBalances,
  Map<String, String> names,
) {
  final paise = <String, int>{
    for (final e in rupeeBalances.entries) e.key: toPaise(e.value),
  };

  final residual = paise.values.fold<int>(0, (sum, v) => sum + v);
  if (residual != 0 && paise.isNotEmpty) {
    // Push the leftover onto whichever member has the largest absolute balance;
    // a sub-paise correction there is invisible and keeps the invariant exact.
    final target = paise.entries
        .reduce((a, b) => a.value.abs() >= b.value.abs() ? a : b)
        .key;
    paise[target] = paise[target]! - residual;
  }

  return simplifyDebts(paise, names);
}

// ─────────────────────────────────────────────────────────────────────────────
// Validation utilities
// ─────────────────────────────────────────────────────────────────────────────

/// True if balances sum to exactly zero (the fundamental invariant — every
/// paise owed is a paise owed to someone).
bool isZeroSum(Map<String, int> paise) =>
    paise.values.fold<int>(0, (sum, v) => sum + v) == 0;

/// Reconstructs net balances implied by a settlement list, in paise. Paying
/// reduces the debtor's deficit (+) and the creditor's surplus (-), so this is
/// the negative of the original balances when settlements fully reconcile.
Map<String, int> netFromSettlements(List<SimplifiedDebt> settlements) {
  final net = <String, int>{};
  for (final s in settlements) {
    net[s.fromUserId] = (net[s.fromUserId] ?? 0) + s.amountPaise;
    net[s.toUserId] = (net[s.toUserId] ?? 0) - s.amountPaise;
  }
  return net;
}

/// Verifies the generated settlements exactly preserve the input balances:
/// every debtor pays precisely what they owe and every creditor receives
/// precisely what they're owed. Applying the settlements to the input must
/// zero every member out.
bool settlementsPreserveBalances(
  Map<String, int> inputPaise,
  List<SimplifiedDebt> settlements,
) {
  final remaining = Map<String, int>.from(inputPaise);
  for (final s in settlements) {
    if (s.amountPaise <= 0) return false; // no zero/negative transactions
    remaining[s.fromUserId] = (remaining[s.fromUserId] ?? 0) + s.amountPaise;
    remaining[s.toUserId] = (remaining[s.toUserId] ?? 0) - s.amountPaise;
  }
  return remaining.values.every((v) => v == 0);
}
