import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paypact/core/theme/app_theme.dart';
import 'package:paypact/core/utils/currency_formatter.dart';
import 'package:paypact/features/group/domain/entities/member_entity.dart';

class ExactRow extends StatelessWidget {
  const ExactRow({
    super.key,
    required this.member,
    required this.checked,
    required this.controller,
    required this.currency,
    required this.onCheckChanged,
    required this.onAmountChanged,
  });
  final MemberEntity member;
  final bool checked;
  final TextEditingController controller;
  final String currency;
  final ValueChanged<bool> onCheckChanged;
  final VoidCallback onAmountChanged;

  @override
  Widget build(BuildContext context) {
    final symbol = CurrencyFormatter.symbolFor(currency);
    return SizedBox(
      height: 52,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Checkbox(
              value: checked,
              activeColor: Theme.of(context).colorScheme.primary,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (v) => onCheckChanged(v ?? false),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              member.displayName,
              style: TextStyle(
                fontSize: 14,
                color: checked
                    ? Theme.of(context).colorScheme.onSurface
                    : PaypactColors.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: 114,
            child: TextField(
              controller: controller,
              enabled: checked,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (_) => onAmountChanged(),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                // symbol ("₹", "$") — never the ISO code
                prefixText: '$symbol ',
                isDense: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
