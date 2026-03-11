import 'package:flutter/material.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';

class CategoryChips extends StatelessWidget {
  const CategoryChips(
      {super.key, required this.selected, required this.onChanged});
  final ExpenseCategory selected;
  final ValueChanged<ExpenseCategory> onChanged;

  static String _label(ExpenseCategory c) => switch (c) {
        ExpenseCategory.food => '🍕 Food',
        ExpenseCategory.transport => '🚗 Transport',
        ExpenseCategory.accommodation => '🏨 Stay',
        ExpenseCategory.entertainment => '🎬 Fun',
        ExpenseCategory.shopping => '🛍️ Shop',
        ExpenseCategory.utilities => '💡 Bills',
        ExpenseCategory.health => '💊 Health',
        ExpenseCategory.education => '📚 Study',
        ExpenseCategory.other => '📦 Other',
      };

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ExpenseCategory.values.map((cat) {
            final sel = cat == selected;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_label(cat)),
                selected: sel,
                selectedColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.15),
                labelStyle: TextStyle(
                    color: sel ? Theme.of(context).colorScheme.primary : null,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.normal),
                onSelected: (_) => onChanged(cat),
              ),
            );
          }).toList(),
        ),
      );
}
