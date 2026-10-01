import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/services/photo_picker.dart';
import 'package:paypact/core/services/storage_service.dart';
import 'package:paypact/core/utils/currency_utils.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/expense/domain/entities/expense_extras.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/widgets/photo_source_sheet.dart';

Widget _card(PayPactThemeExtension pt, List<Widget> children) => Container(
      decoration: BoxDecoration(
        color: pt.surface,
        borderRadius: PayPactRadius.lg,
        border: Border.all(color: pt.border),
        boxShadow: pt.shadowSm,
      ),
      child: Column(children: children),
    );

Widget _label(PayPactThemeExtension pt, String text) => Text(text,
    style: PayPactTypography.label.copyWith(color: pt.ink3, letterSpacing: 1.5));

// ── Cover photo & categories (admins) ─────────────────────────────────────────

class GroupCustomiseSection extends StatefulWidget {
  const GroupCustomiseSection(
      {super.key, required this.group, required this.onChanged});
  final GroupEntity group;

  /// Called after a change is saved so the screen can reload the group.
  final VoidCallback onChanged;

  @override
  State<GroupCustomiseSection> createState() => _GroupCustomiseSectionState();
}

class _GroupCustomiseSectionState extends State<GroupCustomiseSection> {
  bool _busy = false;

  Future<void> _setCover() async {
    final group = widget.group;
    final source = await choosePhotoSource(context,
        allowRemove: group.coverUrl != null, onRemove: _removeCover);
    if (source == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final bytes = await locator<PhotoPicker>().pickBytes(source);
      if (bytes == null) return;
      final storage = locator<StorageService>();
      final url = await storage.uploadGroupCover(group.id, bytes);
      await locator<GroupRepository>().setCoverUrl(group.id, url);
      await storage.deleteByUrl(group.coverUrl);
      widget.onChanged();
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text("Couldn't update the cover photo.")));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeCover() async {
    final group = widget.group;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await locator<GroupRepository>().setCoverUrl(group.id, null);
      await locator<StorageService>().deleteByUrl(group.coverUrl);
      widget.onChanged();
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text("Couldn't remove the cover photo.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final group = widget.group;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(pt, 'CUSTOMISE'),
        const SizedBox(height: 10),
        _card(pt, [
          InkWell(
            onTap: _busy ? null : _setCover,
            borderRadius: PayPactRadius.lg,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 56,
                    height: 40,
                    color: pt.surfaceAlt,
                    child: group.coverUrl == null
                        ? Icon(Icons.image_outlined, color: pt.ink3)
                        : Image.network(group.coverUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Icon(Icons.image_outlined, color: pt.ink3)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text('Cover photo',
                      style: PayPactTypography.bodyMd.copyWith(
                          color: pt.ink, fontWeight: FontWeight.w500)),
                ),
                if (_busy)
                  const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                else
                  Text(group.coverUrl == null ? 'Add' : 'Change',
                      style: PayPactTypography.bodySm.copyWith(
                          color: pt.accent, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          Divider(height: 1, color: pt.border, indent: 16),
          InkWell(
            onTap: () => showCategoriesEditor(context,
                group: group, onChanged: widget.onChanged),
            borderRadius: PayPactRadius.lg,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Icon(Icons.category_outlined, size: 20, color: pt.ink2),
                const SizedBox(width: 14),
                Expanded(
                  child: Text('Expense categories',
                      style: PayPactTypography.bodyMd.copyWith(
                          color: pt.ink, fontWeight: FontWeight.w500)),
                ),
                Text(
                    group.customCategories.isEmpty
                        ? 'Add your own'
                        : '${group.customCategories.length} custom',
                    style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
                Icon(Icons.chevron_right_rounded, color: pt.ink3),
              ]),
            ),
          ),
        ]),
      ],
    );
  }
}

const _categoryEmojis = [
  '🍽', '☕', '🛒', '🏠', '💡', '📶', '🚕', '⛽', '✈️', '🎬', '🎁', '💊',
  '🐶', '🧹', '🎉', '🏋️',
];

/// Lets an admin add / remove the group's own expense categories.
Future<void> showCategoriesEditor(BuildContext context,
    {required GroupEntity group, required VoidCallback onChanged}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CategoriesEditor(group: group, onChanged: onChanged),
  );
}

class _CategoriesEditor extends StatefulWidget {
  const _CategoriesEditor({required this.group, required this.onChanged});
  final GroupEntity group;
  final VoidCallback onChanged;

  @override
  State<_CategoriesEditor> createState() => _CategoriesEditorState();
}

class _CategoriesEditorState extends State<_CategoriesEditor> {
  late List<CustomCategory> _items = List.of(widget.group.customCategories);
  final _name = TextEditingController();
  String _emoji = _categoryEmojis.first;
  bool _saving = false;
  static const _max = 12;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String _newId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random.secure();
    return 'c_${List.generate(6, (_) => chars[r.nextInt(chars.length)]).join()}';
  }

  Future<void> _save(List<CustomCategory> next) async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await locator<GroupRepository>().setCustomCategories(widget.group.id, next);
      setState(() => _items = next);
      widget.onChanged();
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text("Couldn't save categories.")));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _add() {
    final name = _name.text.trim();
    if (name.isEmpty || _items.length >= _max) return;
    if (_items.any((c) => c.name.toLowerCase() == name.toLowerCase())) return;
    _name.clear();
    _save([..._items, CustomCategory(id: _newId(), name: name, emoji: _emoji)]);
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: pt.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Expense categories',
                    style: PayPactTypography.headingMd.copyWith(color: pt.ink)),
                const SizedBox(height: 4),
                Text(
                    'Added to the built-in ones when anyone adds an expense. '
                    'Expenses keep their category if you remove it here (shown as Other).',
                    style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
                const SizedBox(height: 14),
                for (final c in _items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Text(c.emoji, style: const TextStyle(fontSize: 24)),
                    title: Text(c.name),
                    trailing: IconButton(
                      tooltip: 'Remove ${c.name}',
                      icon: Icon(Icons.delete_outline_rounded, color: pt.ink3),
                      onPressed: _saving
                          ? null
                          : () => _save([
                                for (final x in _items)
                                  if (x.id != c.id) x
                              ]),
                    ),
                  ),
                if (_items.length < _max) ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final e in _categoryEmojis)
                      ChoiceChip(
                        label: Text(e, style: const TextStyle(fontSize: 18)),
                        selected: _emoji == e,
                        onSelected: (_) => setState(() => _emoji = e),
                      ),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _name,
                        maxLength: 20,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _add(),
                        decoration: const InputDecoration(
                            hintText: 'New category, e.g. Groceries',
                            counterText: ''),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                        onPressed: _saving ? null : _add,
                        child: const Text('Add')),
                  ]),
                ] else
                  Text('You can have up to $_max categories.',
                      style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Recurring expenses (any member) ───────────────────────────────────────────

class GroupRecurringSection extends StatelessWidget {
  const GroupRecurringSection({super.key, required this.group});
  final GroupEntity group;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final repo = locator<ExpenseRepository>();
    return StreamBuilder<List<RecurringExpense>>(
      stream: repo.watchRecurring(group.id),
      builder: (context, snap) {
        final items = snap.data ?? const <RecurringExpense>[];
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label(pt, 'RECURRING EXPENSES'),
              const SizedBox(height: 10),
              _card(pt, [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: pt.border, indent: 16),
                  _RecurringTile(item: items[i], currency: group.currency),
                ],
              ]),
            ],
          ),
        );
      },
    );
  }
}

class _RecurringTile extends StatelessWidget {
  const _RecurringTile({required this.item, required this.currency});
  final RecurringExpense item;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final repo = locator<ExpenseRepository>();
    final sym = currencySymbol(currency);
    final every =
        item.interval == RecurrenceInterval.weekly ? 'Weekly' : 'Monthly';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title,
                style: PayPactTypography.bodyMd
                    .copyWith(color: pt.ink, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
                '$every · $sym${item.amount.toStringAsFixed(item.amount.truncateToDouble() == item.amount ? 0 : 2)}'
                '${item.active ? ' · next ${DateFormat('MMM d').format(item.nextRunAt)}' : ' · paused'}',
                style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
          ]),
        ),
        Switch(
          value: item.active,
          onChanged: (v) => repo.setRecurringActive(item.groupId, item.id, v),
        ),
        IconButton(
          tooltip: 'Delete ${item.title}',
          icon: Icon(Icons.delete_outline_rounded, color: pt.ink3, size: 20),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Stop this recurring expense?'),
                content: Text(
                    '"${item.title}" won\'t be added again. Expenses already created stay.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Keep')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Stop')),
                ],
              ),
            );
            if (ok == true) await repo.deleteRecurring(item.groupId, item.id);
          },
        ),
      ]),
    );
  }
}
