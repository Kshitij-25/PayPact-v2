import 'package:flutter/material.dart';
import 'package:paypact/core/theme/app_theme.dart';
import 'package:paypact/features/group/domain/entities/member_entity.dart';

class SharesRow extends StatelessWidget {
  const SharesRow({
    super.key,
    required this.member,
    required this.checked,
    required this.shares,
    required this.onCheckChanged,
    required this.onSharesChanged,
  });
  final MemberEntity member;
  final bool checked;
  final int shares;
  final ValueChanged<bool> onCheckChanged;
  final ValueChanged<int> onSharesChanged;

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
                      ? Theme.of(context).colorScheme.onPrimary
                      : PaypactColors.textSecondary,
                ),
              ),
            ),
            _StepBtn(
              icon: Icons.remove,
              enabled: checked && shares > 0,
              onTap: () => onSharesChanged((shares - 1).clamp(0, 99)),
            ),
            SizedBox(
              width: 36,
              child: Text(
                '$shares',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            _StepBtn(
              icon: Icons.add,
              enabled: checked,
              onTap: () => onSharesChanged((shares + 1).clamp(0, 99)),
            ),
            const SizedBox(width: 6),
            Text(
              'share${shares != 1 ? 's' : ''}',
              style: const TextStyle(
                  fontSize: 12, color: PaypactColors.textSecondary),
            ),
          ],
        ),
      );
}

class _StepBtn extends StatelessWidget {
  const _StepBtn(
      {required this.icon, required this.enabled, required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
              color: enabled
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6)),
          child: Icon(icon,
              size: 16,
              color: enabled
                  ? Theme.of(context).colorScheme.primary
                  : PaypactColors.textSecondary),
        ),
      );
}
