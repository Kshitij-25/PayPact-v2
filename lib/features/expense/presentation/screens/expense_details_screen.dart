import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paypact/core/utils/currency_formatter.dart';
import 'package:paypact/core/utils/responsive.dart';
import 'package:paypact/features/expense/presentation/bloc/expense_bloc.dart';
import 'package:paypact/features/group/presentation/bloc/group_bloc.dart';

class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({super.key, required this.expenseId});
  final String expenseId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final expense = context
        .read<ExpenseBloc>()
        .state
        .expenses
        .where((e) => e.id == expenseId)
        .firstOrNull;

    if (expense == null) {
      return const Scaffold(body: Center(child: Text('Expense not found')));
    }

    final group = context
        .read<GroupBloc>()
        .state
        .groups
        .where((g) => g.id == expense.groupId)
        .firstOrNull;

    String memberName(String uid) =>
        group?.getMember(uid)?.displayName ?? uid.substring(0, 6);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => context.push(
              '/group/${expense.groupId}/expense/${expense.id}/edit',
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: cs.error),
            tooltip: 'Delete',
            onPressed: () {
              context
                  .read<ExpenseBloc>()
                  .add(ExpenseDeleteRequested(expenseId));
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ResponsiveCenter(
        maxWidth: 720,
        child: ListView(
          padding: EdgeInsets.all(Responsive.hPadding(context)),
          children: [
            _buildHeader(context, expense.title, expense.amount,
                expense.currency),
            const SizedBox(height: 24),
            _buildInfoRow(context, 'Date',
                DateFormat('MMM d, yyyy · h:mm a').format(expense.createdAt)),
            _buildInfoRow(context, 'Category', expense.category.name),
            _buildInfoRow(context, 'Split type', expense.splitType.name),
            if (expense.description != null)
              _buildInfoRow(context, 'Note', expense.description!),
            const Divider(height: 32),
            Text('Paid by',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: cs.onSurface)),
            const SizedBox(height: 12),
            ...expense.paidBy.entries.map(
              (e) => _buildSplitRow(
                context,
                memberName(e.key),
                expense.currency,
                e.value,
                isPositive: true,
              ),
            ),
            const Divider(height: 32),
            Text('Split among',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: cs.onSurface)),
            const SizedBox(height: 12),
            ...expense.splits.map(
              (s) => _buildSplitRow(
                context,
                memberName(s.userId),
                expense.currency,
                s.amount,
                isPositive: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, String title, double amount, String currency) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: cs.onPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(amount, currency),
            style: TextStyle(
              color: cs.onPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w500, color: cs.onSurface)),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitRow(BuildContext context, String name, String currency,
      double amount,
      {required bool isPositive}) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: cs.primaryContainer.withValues(alpha: 0.4),
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: TextStyle(color: cs.onSurface))),
          Text(
            CurrencyFormatter.format(amount, currency),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isPositive ? cs.secondary : cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
