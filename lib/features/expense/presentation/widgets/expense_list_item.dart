import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import 'package:paypact/core/utils/currency_formatter.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';

class ExpenseListItem extends StatelessWidget {
  const ExpenseListItem({
    super.key,
    required this.expense,
    required this.currentUserId,
    required this.onTap,
    required this.onDelete,
  });

  final ExpenseEntity expense;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final net = expense.netBalanceFor(currentUserId);
    final isLent = net > 0;
    final isSettled = net == 0;

    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Delete',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _buildIcon(context),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 15),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        DateFormat('MMM d').format(expense.createdAt),
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(
                          expense.amount, expense.currency),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isSettled
                          ? 'you paid'
                          : isLent
                              ? '+${CurrencyFormatter.format(net, expense.currency)}'
                              : '-${CurrencyFormatter.format(net.abs(), expense.currency)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSettled
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : isLent
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          _categoryEmoji(expense.category),
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  String _categoryEmoji(ExpenseCategory cat) => switch (cat) {
        ExpenseCategory.food => '🍕',
        ExpenseCategory.transport => '🚗',
        ExpenseCategory.accommodation => '🏨',
        ExpenseCategory.entertainment => '🎬',
        ExpenseCategory.shopping => '🛍️',
        ExpenseCategory.utilities => '💡',
        ExpenseCategory.health => '💊',
        ExpenseCategory.education => '📚',
        ExpenseCategory.other => '📦',
      };
}
