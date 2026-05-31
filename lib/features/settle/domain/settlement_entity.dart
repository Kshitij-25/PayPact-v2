// A settle-up transaction: a record that one user actually paid another.
//
// This is fundamentally different from debt simplification (see
// debt_simplifier.dart). Simplification rewrites a virtual graph; a settlement
// is a real payment event that is appended to the ledger and reduces existing
// balances. Settlements are additive and immutable — recording one never
// mutates historical expenses.
//
// The authoritative amount is amountPaise (integer paise). amount (rupees,
// double) is kept only for display and backward compatibility with documents
// and balance readers written before paise existed. Currency math must never be
// done in amount; convert via toPaise/fromPaise in debt_simplifier.dart.

/// Lifecycle of a settlement. Defaults to [completed] (a recorded cash payment);
/// [pending]/[failed] exist so external payment providers can be layered on
/// without a data migration.
class PaymentStatus {
  static const completed = 'completed';
  static const pending = 'pending';
  static const failed = 'failed';

  /// Allowed values, used for validation/normalization on read.
  static const all = {completed, pending, failed};

  /// Normalizes an arbitrary stored value to a known status, defaulting to
  /// [completed] for legacy/unknown values.
  static String normalize(String? raw) =>
      all.contains(raw) ? raw! : completed;
}

/// How the money moved. Open-ended on purpose (free-form string) so new methods
/// and external providers (UPI / Stripe / Razorpay / PayPal) can be added later
/// without touching this enum-like surface.
class PaymentMethod {
  static const cash = 'cash';
  static const wallet = 'wallet';
  static const upi = 'upi';
  static const bankTransfer = 'bank_transfer';

  static const fallback = cash;
}

/// Discriminator stored on every ledger entry so settlements can be told apart
/// from future entry kinds (e.g. reversals) when reading the collection.
const String kSettlementType = 'settlement';

class SettlementEntity {
  final String id;
  final String groupId;

  /// Always [kSettlementType] for now.
  final String type;

  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;

  /// Authoritative amount in integer paise. Always > 0 for a valid settlement.
  final int amountPaise;

  /// Currency code of the group (e.g. 'INR'). Settlements are recorded in the
  /// group's base currency, like balances.
  final String currency;

  /// Optional free-text note ("dinner split", "rent").
  final String? note;

  /// One of [PaymentMethod] (free-form to stay extensible).
  final String paymentMethod;

  /// One of [PaymentStatus].
  final String status;

  /// Optional external provider reference (id/txn) for UPI/Stripe/etc.
  final String? provider;

  /// User who recorded the settlement (audit trail).
  final String createdById;

  /// Idempotency key — also the Firestore document id. Re-recording with the
  /// same key is a no-op, preventing duplicate payments from double-taps/retries.
  final String idempotencyKey;

  /// Human-facing receipt id, persisted (not regenerated) for auditability.
  final String receiptId;

  final DateTime createdAt;

  const SettlementEntity({
    required this.id,
    required this.groupId,
    this.type = kSettlementType,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.amountPaise,
    required this.currency,
    this.note,
    this.paymentMethod = PaymentMethod.cash,
    this.status = PaymentStatus.completed,
    this.provider,
    required this.createdById,
    required this.idempotencyKey,
    required this.receiptId,
    required this.createdAt,
  });

  /// Amount in rupees, for display only.
  double get amount => amountPaise / 100.0;
}
