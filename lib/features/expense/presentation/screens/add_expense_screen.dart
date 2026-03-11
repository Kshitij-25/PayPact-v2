import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/core/utils/currency_formatter.dart';
import 'package:paypact/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/use_cases/create_expense_use_case.dart';
import 'package:paypact/features/expense/domain/use_cases/update_expense_use_case.dart';
import 'package:paypact/features/expense/presentation/bloc/expense_bloc.dart';
import 'package:paypact/features/expense/presentation/widgets/amount_field.dart';
import 'package:paypact/features/expense/presentation/widgets/category_chips.dart';
import 'package:paypact/features/expense/presentation/widgets/desc_field.dart';
import 'package:paypact/features/expense/presentation/widgets/equal_row.dart';
import 'package:paypact/features/expense/presentation/widgets/exact_row.dart';
import 'package:paypact/features/expense/presentation/widgets/paid_by_dropdown.dart';
import 'package:paypact/features/expense/presentation/widgets/percentage_row.dart';
import 'package:paypact/features/expense/presentation/widgets/share_row.dart';
import 'package:paypact/features/expense/presentation/widgets/split_preview.dart';
import 'package:paypact/features/expense/presentation/widgets/split_type_selector.dart';
import 'package:paypact/features/expense/presentation/widgets/submit_bar.dart';
import 'package:paypact/features/expense/presentation/widgets/title_field.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/group/domain/entities/member_entity.dart';
import 'package:paypact/features/group/presentation/bloc/group_bloc.dart';
import 'package:paypact/features/profile/presentation/bloc/settings_bloc.dart';
import 'package:paypact/widgets/section_label.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({
    super.key,
    required this.groupId,
    this.expenseId,
  });

  final String groupId;
  final String? expenseId;

  bool get isEditing => expenseId != null;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  SplitType _splitType = SplitType.equal;
  ExpenseCategory _category = ExpenseCategory.other;

  late List<MemberEntity> _groupMembers;
  late Set<String> _includedIds;
  late String _paidBy;

  final Map<String, TextEditingController> _splitCtrl = {};
  final Map<String, int> _shareCount = {};
  ExpenseEntity? _editingExpense;

  @override
  void initState() {
    super.initState();
    _initGroup();
    if (widget.isEditing) _populateForEdit();
  }

  void _initGroup() {
    final group = _group;
    _groupMembers = group?.members ?? [];
    _includedIds = _groupMembers.map((m) => m.userId).toSet();
    _paidBy = context.read<AuthBloc>().state.user?.id ??
        (_groupMembers.isNotEmpty ? _groupMembers.first.userId : '');
    for (final m in _groupMembers) {
      _splitCtrl[m.userId] = TextEditingController();
      _shareCount[m.userId] = 1;
    }
  }

  void _populateForEdit() {
    final expense = context
        .read<ExpenseBloc>()
        .state
        .expenses
        .where((e) => e.id == widget.expenseId)
        .firstOrNull;
    if (expense == null) return;
    _editingExpense = expense;

    _titleCtrl.text = expense.title;
    _amountCtrl.text = expense.amount.toString();
    _descCtrl.text = expense.description ?? '';
    _category = expense.category;
    _splitType = expense.splitType;
    _paidBy = expense.paidBy.keys.first;
    _includedIds = expense.splits.map((s) => s.userId).toSet();

    for (final split in expense.splits) {
      _splitCtrl[split.userId]?.text = switch (expense.splitType) {
        SplitType.exact => split.amount.toStringAsFixed(2),
        SplitType.percentage => (split.percentage ?? 0.0).toStringAsFixed(1),
        SplitType.shares => (split.shares ?? 1).toString(),
        SplitType.equal => '',
      };
      if (expense.splitType == SplitType.shares) {
        _shareCount[split.userId] = split.shares ?? 1;
      }
    }
  }

  GroupEntity? get _group => context
      .read<GroupBloc>()
      .state
      .groups
      .where((g) => g.id == widget.groupId)
      .firstOrNull;

  /// Group currency takes priority; falls back to the user's profile
  /// currency setting rather than a hardcoded 'USD'.
  String get _effectiveCurrency =>
      _group?.currency ?? context.read<SettingsBloc>().state.currency;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    for (final c in _splitCtrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<MemberEntity> get _includedMembers =>
      _groupMembers.where((m) => _includedIds.contains(m.userId)).toList();

  String? _validateSplits(double total) {
    final included = _includedMembers;
    if (included.isEmpty) return 'Select at least one member';
    switch (_splitType) {
      case SplitType.equal:
        return null;
      case SplitType.exact:
        final sum = included.fold(
            0.0,
            (s, m) =>
                s + (double.tryParse(_splitCtrl[m.userId]?.text ?? '') ?? 0));
        if ((sum - total).abs() > 0.01) {
          final cur = _effectiveCurrency;
          return 'Exact amounts must sum to ${CurrencyFormatter.format(total, cur)} '
              '(currently ${CurrencyFormatter.format(sum, cur)})';
        }
        return null;
      case SplitType.percentage:
        final sum = included.fold(
            0.0,
            (s, m) =>
                s + (double.tryParse(_splitCtrl[m.userId]?.text ?? '') ?? 0));
        if ((sum - 100).abs() > 0.1) {
          return 'Percentages must sum to 100% (currently ${sum.toStringAsFixed(1)}%)';
        }
        return null;
      case SplitType.shares:
        final totalShares =
            included.fold(0, (s, m) => s + (_shareCount[m.userId] ?? 0));
        if (totalShares == 0) return 'At least one share required';
        return null;
    }
  }

  Map<String, double>? get _exactAmounts {
    if (_splitType != SplitType.exact) return null;
    return {
      for (final m in _includedMembers)
        m.userId: double.tryParse(_splitCtrl[m.userId]?.text ?? '') ?? 0.0,
    };
  }

  Map<String, double>? get _percentages {
    if (_splitType != SplitType.percentage) return null;
    return {
      for (final m in _includedMembers)
        m.userId: double.tryParse(_splitCtrl[m.userId]?.text ?? '') ?? 0.0,
    };
  }

  Map<String, int>? get _shares {
    if (_splitType != SplitType.shares) return null;
    return {
      for (final m in _includedMembers) m.userId: _shareCount[m.userId] ?? 1,
    };
  }

  Map<String, double> _previewAmounts(double total) {
    final ids = _includedMembers.map((m) => m.userId).toList();
    if (ids.isEmpty || total <= 0) return {};
    switch (_splitType) {
      case SplitType.equal:
        final per = total / ids.length;
        return {for (final id in ids) id: per};
      case SplitType.exact:
        return {
          for (final m in _includedMembers)
            m.userId: double.tryParse(_splitCtrl[m.userId]?.text ?? '') ?? 0.0,
        };
      case SplitType.percentage:
        return {
          for (final m in _includedMembers)
            m.userId: total *
                (double.tryParse(_splitCtrl[m.userId]?.text ?? '') ?? 0.0) /
                100,
        };
      case SplitType.shares:
        final totalShares = ids.fold(0, (s, id) => s + (_shareCount[id] ?? 0));
        if (totalShares == 0) return {};
        return {
          for (final id in ids)
            id: total * (_shareCount[id] ?? 0) / totalShares,
        };
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final total = double.tryParse(_amountCtrl.text) ?? 0;
    if (total <= 0) return;

    final splitError = _validateSplits(total);
    if (splitError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(splitError)));
      return;
    }

    final memberIds = _includedMembers.map((m) => m.userId).toList();
    final currency = _effectiveCurrency;

    if (widget.isEditing && _editingExpense != null) {
      context.read<ExpenseBloc>().add(ExpenseUpdateRequested(
            UpdateExpenseParams(
              expense: _editingExpense!.copyWith(
                title: _titleCtrl.text.trim(),
                amount: total,
                paidBy: {_paidBy: total},
                description: _descCtrl.text.trim().isNotEmpty
                    ? _descCtrl.text.trim()
                    : null,
                category: _category,
                currency: currency,
              ),
              splitType: _splitType,
              memberIds: memberIds,
              exactAmounts: _exactAmounts,
              percentages: _percentages,
              shares: _shares,
            ),
          ));
    } else {
      context.read<ExpenseBloc>().add(ExpenseCreateRequested(
            CreateExpenseParams(
              groupId: widget.groupId,
              title: _titleCtrl.text.trim(),
              amount: total,
              paidBy: {_paidBy: total},
              splitType: _splitType,
              memberIds: memberIds,
              createdBy: context.read<AuthBloc>().state.user?.id ?? '',
              description: _descCtrl.text.trim().isNotEmpty
                  ? _descCtrl.text.trim()
                  : null,
              category: _category,
              currency: currency,
              exactAmounts: _exactAmounts,
              percentages: _percentages,
              shares: _shares,
            ),
          ));
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final currency = _effectiveCurrency;
    final total = double.tryParse(_amountCtrl.text) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Expense' : 'Add Expense'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            TitleField(controller: _titleCtrl),
            const SizedBox(height: 14),
            AmountField(
              controller: _amountCtrl,
              currency: currency,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 14),
            DescField(controller: _descCtrl),
            const SizedBox(height: 20),
            const SectionLabel('Category'),
            const SizedBox(height: 8),
            CategoryChips(
              selected: _category,
              onChanged: (c) => setState(() => _category = c),
            ),
            const SizedBox(height: 20),
            const SectionLabel('Paid by'),
            const SizedBox(height: 8),
            PaidByDropdown(
              members: _groupMembers,
              value: _paidBy,
              onChanged: (v) => setState(() => _paidBy = v),
            ),
            const SizedBox(height: 20),
            const SectionLabel('Split type'),
            const SizedBox(height: 8),
            SplitTypeSelector(
              value: _splitType,
              onChanged: (t) => setState(() {
                _splitType = t;
                for (final c in _splitCtrl.values) {
                  c.clear();
                }
              }),
            ),
            const SizedBox(height: 20),
            const SectionLabel('Split between'),
            const SizedBox(height: 8),
            ..._buildSplitRows(currency),
            if (total > 0 && _includedMembers.isNotEmpty) ...[
              const SizedBox(height: 16),
              SplitPreview(
                preview: _previewAmounts(total),
                members: _groupMembers,
                currency: currency,
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SubmitBar(
        label: widget.isEditing ? 'Save Changes' : 'Add Expense',
        onTap: _submit,
      ),
    );
  }

  List<Widget> _buildSplitRows(String currency) {
    switch (_splitType) {
      case SplitType.equal:
        return _groupMembers
            .map((m) => EqualRow(
                  member: m,
                  checked: _includedIds.contains(m.userId),
                  onChanged: (v) => setState(() {
                    if (v) {
                      _includedIds.add(m.userId);
                    } else {
                      _includedIds.remove(m.userId);
                    }
                  }),
                ))
            .toList();

      case SplitType.exact:
        return _groupMembers
            .map((m) => ExactRow(
                  member: m,
                  checked: _includedIds.contains(m.userId),
                  controller: _splitCtrl[m.userId]!,
                  currency: currency,
                  onCheckChanged: (v) => setState(() {
                    if (v) {
                      _includedIds.add(m.userId);
                    } else {
                      _includedIds.remove(m.userId);
                      _splitCtrl[m.userId]?.clear();
                    }
                  }),
                  onAmountChanged: () => setState(() {}),
                ))
            .toList();

      case SplitType.percentage:
        return _groupMembers
            .map((m) => PercentageRow(
                  member: m,
                  checked: _includedIds.contains(m.userId),
                  controller: _splitCtrl[m.userId]!,
                  onCheckChanged: (v) => setState(() {
                    if (v) {
                      _includedIds.add(m.userId);
                    } else {
                      _includedIds.remove(m.userId);
                      _splitCtrl[m.userId]?.clear();
                    }
                  }),
                  onPctChanged: () => setState(() {}),
                ))
            .toList();

      case SplitType.shares:
        return _groupMembers
            .map((m) => SharesRow(
                  member: m,
                  checked: _includedIds.contains(m.userId),
                  shares: _shareCount[m.userId] ?? 1,
                  onCheckChanged: (v) => setState(() {
                    if (v) {
                      _includedIds.add(m.userId);
                    } else {
                      _includedIds.remove(m.userId);
                    }
                  }),
                  onSharesChanged: (v) =>
                      setState(() => _shareCount[m.userId] = v),
                ))
            .toList();
    }
  }
}
