import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/domain/entities/expense_entity.dart';
import 'package:paypact/domain/use_cases/create_expense_use_case.dart';
import 'package:paypact/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:paypact/presentation/bloc/expense_bloc/expense_bloc.dart';
import 'package:paypact/presentation/bloc/group_bloc/group_bloc.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, required this.groupId});
  final String groupId;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  SplitType _splitType = SplitType.equal;
  ExpenseCategory _category = ExpenseCategory.other;
  late List<String> _selectedMembers;
  late String _paidBy;

  @override
  void initState() {
    super.initState();
    final group = context
        .read<GroupBloc>()
        .state
        .groups
        .where((g) => g.id == widget.groupId)
        .firstOrNull;
    _selectedMembers = group?.members.map((m) => m.userId).toList() ?? [];
    _paidBy = context.read<AuthBloc>().state.user?.id ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    final group = context
        .read<GroupBloc>()
        .state
        .groups
        .where((g) => g.id == widget.groupId)
        .firstOrNull;

    context.read<ExpenseBloc>().add(
          ExpenseCreateRequested(
            CreateExpenseParams(
              groupId: widget.groupId,
              title: _titleController.text.trim(),
              amount: amount,
              paidBy: {_paidBy: amount},
              splitType: _splitType,
              memberIds: _selectedMembers,
              createdBy: context.read<AuthBloc>().state.user?.id ?? '',
              description: _descController.text.isNotEmpty
                  ? _descController.text.trim()
                  : null,
              category: _category,
              currency: group?.currency ?? 'USD',
            ),
          ),
        );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final group = context
        .read<GroupBloc>()
        .state
        .groups
        .where((g) => g.id == widget.groupId)
        .firstOrNull;
    final currency = group?.currency ?? 'USD';

    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildTitleField(),
            const SizedBox(height: 16),
            _buildAmountField(currency),
            const SizedBox(height: 16),
            _buildDescriptionField(),
            const SizedBox(height: 24),
            _buildCategorySelector(),
            const SizedBox(height: 24),
            _buildPaidBySelector(group?.members ?? []),
            const SizedBox(height: 24),
            _buildSplitTypeSelector(),
            const SizedBox(height: 24),
            _buildMemberSelector(group?.members ?? []),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Add Expense'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() => TextFormField(
        controller: _titleController,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Title',
          hintText: 'e.g. Dinner, Hotel, Groceries...',
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Title is required' : null,
      );

  Widget _buildAmountField(String currency) => TextFormField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Amount',
          prefixText: '$currency ',
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Amount is required';
          if (double.tryParse(v) == null) return 'Enter a valid amount';
          if (double.parse(v) <= 0) return 'Amount must be positive';
          return null;
        },
      );

  Widget _buildDescriptionField() => TextFormField(
        controller: _descController,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Description (optional)',
          hintText: 'Add a note...',
        ),
      );

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ExpenseCategory.values.map((cat) {
              final isSelected = cat == _category;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_categoryEmoji(cat)),
                  selected: isSelected,
                  selectedColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.15),
                  onSelected: (_) => setState(() => _category = cat),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPaidBySelector(List members) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Paid by',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _paidBy,
            decoration: const InputDecoration(),
            items: (members)
                .map((m) => DropdownMenuItem<String>(
                      value: m.userId as String,
                      child: Text(m.displayName as String),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _paidBy = v ?? _paidBy),
          ),
        ],
      );

  Widget _buildSplitTypeSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Split type',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          SegmentedButton<SplitType>(
            segments: const [
              ButtonSegment(value: SplitType.equal, label: Text('Equal')),
              ButtonSegment(value: SplitType.exact, label: Text('Exact')),
              ButtonSegment(value: SplitType.percentage, label: Text('%')),
              ButtonSegment(value: SplitType.shares, label: Text('Shares')),
            ],
            selected: {_splitType},
            onSelectionChanged: (s) => setState(() => _splitType = s.first),
          ),
        ],
      );

  Widget _buildMemberSelector(List members) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Split between',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          ...(members).map((m) => CheckboxListTile(
                value: _selectedMembers.contains(m.userId),
                title: Text(m.displayName as String),
                activeColor: Theme.of(context).colorScheme.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedMembers.add(m.userId as String);
                    } else {
                      _selectedMembers.remove(m.userId);
                    }
                  });
                },
              )),
        ],
      );

  String _categoryEmoji(ExpenseCategory cat) => switch (cat) {
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
}
