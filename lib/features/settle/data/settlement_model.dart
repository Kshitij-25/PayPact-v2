import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paypact/features/settle/domain/settlement_entity.dart';

/// Firestore (de)serialization for [SettlementEntity]. Mirrors the pattern in
/// expense_model.dart.
///
/// Backward compatibility: documents written before the paise migration only
/// have `amount` (double rupees). [fromFirestore] reconstructs [amountPaise]
/// from `amount` in that case so old settlements still reconcile.
class SettlementModel extends SettlementEntity {
  const SettlementModel({
    required super.id,
    required super.groupId,
    super.type,
    required super.fromUserId,
    required super.fromUserName,
    required super.toUserId,
    required super.toUserName,
    required super.amountPaise,
    required super.currency,
    super.note,
    super.paymentMethod,
    super.status,
    super.provider,
    required super.createdById,
    required super.idempotencyKey,
    required super.receiptId,
    required super.createdAt,
  });

  factory SettlementModel.fromFirestore(DocumentSnapshot doc, String groupId) {
    final data = doc.data() as Map<String, dynamic>;

    // Prefer the authoritative integer paise; fall back to legacy rupee amount.
    final rawPaise = (data['amountPaise'] as num?)?.toInt();
    final rawAmount = (data['amount'] as num?)?.toDouble() ?? 0;
    final amountPaise = rawPaise ?? (rawAmount * 100).round();

    return SettlementModel(
      id: doc.id,
      groupId: groupId,
      type: data['type'] as String? ?? kSettlementType,
      fromUserId: data['fromUserId'] as String? ?? '',
      fromUserName: data['fromUserName'] as String? ?? '',
      toUserId: data['toUserId'] as String? ?? '',
      toUserName: data['toUserName'] as String? ?? '',
      amountPaise: amountPaise,
      currency: data['currency'] as String? ?? 'INR',
      note: data['note'] as String?,
      paymentMethod: data['paymentMethod'] as String? ?? PaymentMethod.fallback,
      status: PaymentStatus.normalize(data['status'] as String?),
      provider: data['provider'] as String?,
      createdById: data['createdById'] as String? ?? '',
      // Older docs used the auto-generated doc id and had no explicit key.
      idempotencyKey: data['idempotencyKey'] as String? ?? doc.id,
      receiptId: data['receiptId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Builds an in-memory model from an already-fetched data map (e.g. the value
  /// read inside a transaction), without a [DocumentSnapshot].
  factory SettlementModel.fromMap(
    String id,
    String groupId,
    Map<String, dynamic> data,
  ) {
    final rawPaise = (data['amountPaise'] as num?)?.toInt();
    final rawAmount = (data['amount'] as num?)?.toDouble() ?? 0;
    final createdAt = data['createdAt'];

    return SettlementModel(
      id: id,
      groupId: groupId,
      type: data['type'] as String? ?? kSettlementType,
      fromUserId: data['fromUserId'] as String? ?? '',
      fromUserName: data['fromUserName'] as String? ?? '',
      toUserId: data['toUserId'] as String? ?? '',
      toUserName: data['toUserName'] as String? ?? '',
      amountPaise: rawPaise ?? (rawAmount * 100).round(),
      currency: data['currency'] as String? ?? 'INR',
      note: data['note'] as String?,
      paymentMethod: data['paymentMethod'] as String? ?? PaymentMethod.fallback,
      status: PaymentStatus.normalize(data['status'] as String?),
      provider: data['provider'] as String?,
      createdById: data['createdById'] as String? ?? '',
      idempotencyKey: data['idempotencyKey'] as String? ?? id,
      receiptId: data['receiptId'] as String? ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
  }

  /// Map written to Firestore. Stores both [amountPaise] (authoritative) and
  /// [amount] (rupees) so legacy balance readers keep working unchanged.
  /// `createdAt` is a server timestamp unless [serverTimestamp] is false (tests).
  Map<String, dynamic> toMap({bool serverTimestamp = true}) => {
        'type': type,
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
        'toUserId': toUserId,
        'toUserName': toUserName,
        'amountPaise': amountPaise,
        'amount': amount,
        'currency': currency,
        if (note != null) 'note': note,
        'paymentMethod': paymentMethod,
        'status': status,
        if (provider != null) 'provider': provider,
        'createdById': createdById,
        'idempotencyKey': idempotencyKey,
        'receiptId': receiptId,
        'createdAt':
            serverTimestamp ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt),
      };
}
