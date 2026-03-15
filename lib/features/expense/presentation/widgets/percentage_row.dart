import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paypact/core/theme/app_theme.dart';
import 'package:paypact/features/group/domain/entities/member_entity.dart';

class PercentageRow extends StatelessWidget {
  const PercentageRow({
    super.key,
    required this.member,
    required this.checked,
    required this.controller,
    required this.onCheckChanged,
    required this.onPctChanged,
  });
  final MemberEntity member;
  final bool checked;
  final TextEditingController controller;
  final ValueChanged<bool> onCheckChanged;
  final VoidCallback onPctChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
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
              width: 90,
              child: TextField(
                controller: controller,
                enabled: checked,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                ],
                onChanged: (_) => onPctChanged(),
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  suffixText: '%',
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                ),
              ),
            ),
          ],
        ),
      );
}
