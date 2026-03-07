import 'package:flutter/material.dart';
import 'package:paypact/core/theme/app_theme.dart';
import 'package:paypact/domain/entities/debt_entity.dart';
import 'package:paypact/domain/entities/member_entity.dart';

class DebtCard extends StatelessWidget {
  const DebtCard({
    super.key,
    required this.debt,
    required this.members,
    required this.currentUserId,
    required this.onSettle,
  });

  final DebtEntity debt;
  final List<MemberEntity> members;
  final String currentUserId;
  final VoidCallback onSettle;

  String _name(String id) =>
      members.where((m) => m.userId == id).firstOrNull?.displayName ??
      id.substring(0, 6);

  @override
  Widget build(BuildContext context) {
    final isMyDebt = debt.debtorId == currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 14, color: PaypactColors.textPrimary),
                      children: [
                        TextSpan(
                          text: isMyDebt ? 'You' : _name(debt.debtorId),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const TextSpan(text: ' owe '),
                        TextSpan(
                          text: isMyDebt
                              ? _name(debt.creditorId)
                              : _name(debt.creditorId),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${debt.currency} ${debt.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: PaypactColors.danger,
                    ),
                  ),
                ],
              ),
            ),
            if (isMyDebt)
              ElevatedButton(
                onPressed: onSettle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PaypactColors.secondary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('Settle'),
              ),
          ],
        ),
      ),
    );
  }
}
