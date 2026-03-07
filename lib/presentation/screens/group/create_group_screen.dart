import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/core/theme/app_theme.dart';
import 'package:paypact/domain/entities/group_entity.dart';
import 'package:paypact/domain/use_cases/create_group_use_case.dart';
import 'package:paypact/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:paypact/presentation/bloc/group_bloc/group_bloc.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  GroupCategory _selectedCategory = GroupCategory.other;
  String _currency = 'USD';

  static const _currencies = ['USD', 'EUR', 'GBP', 'INR', 'JPY', 'AUD', 'CAD'];
  static const _categories = GroupCategory.values;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;

    context.read<GroupBloc>().add(
          GroupCreateRequested(CreateGroupParams(
            name: _nameController.text.trim(),
            createdBy: user.id,
            category: _selectedCategory,
            currency: _currency,
            // Pass creator profile so the repository can embed them as
            // the first admin member and populate memberIds correctly.
            creatorDisplayName: user.displayName,
            creatorEmail: user.email,
            creatorPhotoUrl: user.photoUrl,
          )),
        );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Group')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionLabel('Group Name'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. Weekend Trip, Roommates...',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 24),
            _SectionLabel('Category'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = cat == _selectedCategory;
                return ChoiceChip(
                  label: Text(_categoryLabel(cat)),
                  selected: isSelected,
                  selectedColor: PaypactColors.primary.withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? PaypactColors.primary
                        : PaypactColors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? PaypactColors.primary
                        : PaypactColors.divider,
                  ),
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            _SectionLabel('Currency'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: const InputDecoration(),
              items: _currencies
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _currency = v ?? 'USD'),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Create Group'),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(GroupCategory cat) {
    return switch (cat) {
      GroupCategory.home => '🏠 Home',
      GroupCategory.trip => '✈️ Trip',
      GroupCategory.couple => '❤️ Couple',
      GroupCategory.friends => '👯 Friends',
      GroupCategory.work => '💼 Work',
      GroupCategory.other => '📂 Other',
    };
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: PaypactColors.textPrimary,
      ),
    );
  }
}
