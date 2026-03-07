import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paypact/core/theme/app_theme.dart';
import 'package:paypact/presentation/bloc/expense_bloc/expense_bloc.dart';
import 'package:paypact/presentation/bloc/group_bloc/group_bloc.dart';

class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({super.key, required this.expenseId});
  final String expenseId;

  @override
  Widget build(BuildContext context) {
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
            icon: Icon(Icons.delete_outline,
                color: Theme.of(context).colorScheme.error),
            onPressed: () {
              context
                  .read<ExpenseBloc>()
                  .add(ExpenseDeleteRequested(expenseId));
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(
              context, expense.title, expense.amount, expense.currency),
          const SizedBox(height: 24),
          _buildInfoRow('Date',
              DateFormat('MMM d, yyyy · h:mm a').format(expense.createdAt)),
          _buildInfoRow('Category', expense.category.name),
          _buildInfoRow('Split type', expense.splitType.name),
          if (expense.description != null)
            _buildInfoRow('Note', expense.description!),
          const Divider(height: 32),
          const Text('Paid by',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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
          const Text('Split among',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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
    );
  }

  Widget _buildHeader(
      BuildContext context, String title, double amount, String currency) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$currency ${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(color: PaypactColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitRow(
      BuildContext context, String name, String currency, double amount,
      {required bool isPositive}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.15),
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name)),
          Text(
            '$currency ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isPositive
                  ? PaypactColors.secondary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
