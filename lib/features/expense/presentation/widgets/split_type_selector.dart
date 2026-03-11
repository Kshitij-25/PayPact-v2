import 'package:flutter/material.dart';
import 'package:paypact/core/theme/app_theme.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';

class SplitTypeSelector extends StatelessWidget {
  const SplitTypeSelector(
      {super.key, required this.value, required this.onChanged});
  final SplitType value;
  final ValueChanged<SplitType> onChanged;

  static String _label(SplitType t) => switch (t) {
        SplitType.equal => 'Equal',
        SplitType.exact => 'Exact',
        SplitType.percentage => 'Percent',
        SplitType.shares => 'Shares',
      };

  static IconData _icon(SplitType t) => switch (t) {
        SplitType.equal => Icons.balance_outlined,
        SplitType.exact => Icons.attach_money,
        SplitType.percentage => Icons.percent,
        SplitType.shares => Icons.pie_chart_outline,
      };

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Row(
          children: SplitType.values.map(
            (t) {
              final sel = t == value;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: sel
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _icon(t),
                          size: 18,
                          color:
                              sel ? Colors.white : PaypactColors.textSecondary,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _label(t),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                sel ? FontWeight.w700 : FontWeight.normal,
                            color: sel
                                ? Colors.white
                                : PaypactColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ).toList(),
        ),
      );
}
