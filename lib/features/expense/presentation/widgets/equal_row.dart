import 'package:flutter/material.dart';
import 'package:paypact/core/theme/app_theme.dart';
import 'package:paypact/features/group/domain/entities/member_entity.dart';

class EqualRow extends StatelessWidget {
  const EqualRow({
    super.key,
    required this.member,
    required this.checked,
    required this.onChanged,
  });
  final MemberEntity member;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
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
                onChanged: (v) => onChanged(v ?? false),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                member.displayName,
                style: TextStyle(
                  fontSize: 14,
                  color: checked
                      ? Theme.of(context).colorScheme.onPrimary
                      : PaypactColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
}
