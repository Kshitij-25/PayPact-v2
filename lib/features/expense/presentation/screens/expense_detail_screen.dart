import 'package:paypact/widgets/doc_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/utils/currency_utils.dart';
import 'package:paypact/core/utils/responsive.dart';
import 'package:paypact/design_system/components/paypact_button.dart';
import 'package:paypact/design_system/components/paypact_card.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/spacing.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/expense/presentation/cubit/expense_detail_cubit.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/features/notification/domain/repositories/notifications_repository.dart';
import 'package:paypact/features/expense/presentation/widgets/expense_detail_extras.dart';
import 'package:paypact/widgets/pp_atoms.dart';
import 'package:share_plus/share_plus.dart';

class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen(
      {super.key, required this.expenseId, required this.groupId});

  final String expenseId;
  final String groupId;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final userId =
        authState is AuthAuthenticated ? authState.user.id : '';

    return BlocProvider(
      create: (_) => ExpenseDetailCubit(
        locator<ExpenseRepository>(),
        locator<NotificationsRepository>(),
        locator<GroupRepository>(),
        groupId,
        expenseId,
        userId,
      )..load(),
      child: _ExpenseDetailBody(groupId: groupId, expenseId: expenseId),
    );
  }
}

class _ExpenseDetailBody extends StatelessWidget {
  const _ExpenseDetailBody(
      {required this.groupId, required this.expenseId});

  final String groupId;
  final String expenseId;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;

    return BlocBuilder<ExpenseDetailCubit, ExpenseDetailState>(
      builder: (context, state) {
        if (state is ExpenseDetailLoading || state is ExpenseDetailInitial) {
          return Scaffold(
            backgroundColor: pt.bg,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (state is ExpenseDetailError) {
          return Scaffold(
            backgroundColor: pt.bg,
            body: Center(child: Text(state.message)),
          );
        }

        final loaded = state as ExpenseDetailLoaded;
        final expense = loaded.expense;
        final currentUserId = loaded.currentUserId;
        final cat = _catFromString(expense.category);
        final catTone = PpCategoryDisc.tone(context, cat);
        final iPaid = expense.paidById == currentUserId;
        final myShare = expense.splitAmountFor(currentUserId);
        final myNet = iPaid ? expense.amount - myShare : -myShare;
        final sym = currencySymbol(loaded.currency);
        final evenSplit = _isEvenSplit(expense);

        return Scaffold(
          backgroundColor: pt.bg,
          body: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: context.sh(280),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [catTone[0], pt.bg],
                      stops: const [0, 0.95],
                    ),
                  ),
                  child: Stack(clipBehavior: Clip.none, children: [
                    Positioned(
                      top: 30,
                      right: -30,
                      child: Opacity(
                        opacity: 0.18,
                        child: Text(
                          _emojiForCategory(cat),
                          style: TextStyle(fontSize: context.sp(200)),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Row(children: [
                          PpGlassIconButton(
                              icon: Icons.arrow_back_rounded,
                              onTap: () => context.pop()),
                          const Spacer(),
                          PpGlassIconButton(
                            icon: Icons.edit_outlined,
                            onTap: () async {
                              final cubit =
                                  context.read<ExpenseDetailCubit>();
                              await context.push(
                                  '/group/$groupId/expense/$expenseId/edit');
                              if (!cubit.isClosed) cubit.load();
                            },
                          ),
                          const SizedBox(width: 10),
                          PpGlassIconButton(
                              icon: Icons.more_horiz_rounded,
                              onTap: () => _showMenu(context, loaded)),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 26, 28, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PpChip(
                              label:
                                  '${loaded.customCategoryEmoji ?? _emojiForCategory(cat)}  ${loaded.customCategoryName ?? _capitalize(_isBuiltin(expense.category) ? expense.category : 'other')} · ${expense.splits.length} people',
                              tone: PpChipTone.neutral,
                            ),
                            const SizedBox(height: 14),
                            Text(expense.title,
                                style: PayPactTypography.headingXl
                                    .copyWith(color: pt.ink)),
                            const SizedBox(height: 8),
                            Text(
                              '$sym${expense.amount.toStringAsFixed(expense.amount.truncateToDouble() == expense.amount ? 0 : 2)}',
                              style: PayPactTypography.amountHero
                                  .copyWith(color: pt.ink, fontSize: context.sp(56)),
                            ),
                            const SizedBox(height: 8),
                            Text.rich(
                              TextSpan(
                                style: PayPactTypography.bodyMd
                                    .copyWith(color: pt.ink2),
                                children: [
                                  TextSpan(
                                    text: iPaid
                                        ? 'You paid · ${evenSplit ? 'split equally' : 'split unevenly'} · '
                                        : '${expense.paidByName} paid · your share · ',
                                  ),
                                  TextSpan(
                                    text: myNet >= 0
                                        ? '+$sym${myNet.abs().toStringAsFixed(0)} to you'
                                        : '−$sym${myNet.abs().toStringAsFixed(0)} you owe',
                                    style: TextStyle(
                                      color: myNet >= 0
                                          ? pt.positive
                                          : pt.negative,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: PayPactSpacing.s6),
                        child: PpSectionLabel(
                          label:
                              'SPLIT · ${expense.splits.length} PEOPLE',
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: PayPactSpacing.s6),
                        child: PayPactCard(
                          padding: EdgeInsets.zero,
                          child: Column(children: [
                            for (var i = 0;
                                i < expense.splits.length;
                                i++) ...[
                              if (i > 0) Divider(color: pt.border, height: 1),
                              _SplitTile(
                                split: expense.splits[i],
                                paidById: expense.paidById,
                                currentUserId: currentUserId,
                                sym: sym,
                              ),
                            ],
                          ]),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: PayPactSpacing.s6),
                        child: PayPactCard(
                          padding: EdgeInsets.zero,
                          child: Column(children: [
                            _MetaRow(
                              icon: Icons.calendar_today_outlined,
                              label: 'Date',
                              value: DateFormat('MMM d, yyyy')
                                  .format(expense.date),
                            ),
                            if (expense.recurringId != null) ...[
                              Divider(color: pt.border, height: 1),
                              const _MetaRow(
                                icon: Icons.repeat_rounded,
                                label: 'Repeats',
                                value: 'Recurring expense',
                              ),
                            ],
                            if (expense.createdAt.difference(expense.date).abs() >
                                const Duration(days: 1)) ...[
                              Divider(color: pt.border, height: 1),
                              _MetaRow(
                                icon: Icons.edit_calendar_outlined,
                                label: 'Added',
                                value: DateFormat('MMM d, yyyy')
                                    .format(expense.createdAt),
                              ),
                            ],
                          ]),
                        ),
                      ),
                      if ((expense.note ?? '').isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: PayPactSpacing.s6),
                          child: PayPactCard(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.notes_rounded,
                                    size: 18, color: pt.ink2),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SelectableText(expense.note!,
                                      style: PayPactTypography.bodyMd
                                          .copyWith(color: pt.ink)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (expense.receiptUrl != null) ...[
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: PayPactSpacing.s6),
                          child: GestureDetector(
                            onTap: () =>
                                showReceiptViewer(context, expense.receiptUrl!),
                            child: PayPactCard(
                              padding: const EdgeInsets.all(10),
                              child: Row(children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: DocImage(expense.receiptUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: const Icon(
                                            Icons.receipt_long_outlined)),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text('Receipt',
                                      style: PayPactTypography.bodyMd.copyWith(
                                          color: pt.ink,
                                          fontWeight: FontWeight.w600)),
                                ),
                                Icon(Icons.open_in_full_rounded,
                                    size: 18, color: pt.ink3),
                              ]),
                            ),
                          ),
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            PayPactSpacing.s6, 12, PayPactSpacing.s6, 0),
                        child: Row(children: [
                          if (iPaid && loaded.remindable.isNotEmpty) ...[
                            Expanded(
                              child: PayPactButton(
                                onPressed: () => _remind(context, loaded),
                                label:
                                    'Remind ${loaded.remindable.length} ${loaded.remindable.length == 1 ? 'person' : 'people'}',
                                variant: PayPactButtonVariant.secondary,
                                isFullWidth: true,
                                leftIcon: Icons.notifications_none_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: PayPactButton(
                              onPressed: () =>
                                  _confirmDelete(context, loaded),
                              label: 'Delete',
                              variant: PayPactButtonVariant.danger,
                              isFullWidth: true,
                              leftIcon: Icons.delete_outline_rounded,
                            ),
                          ),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(PayPactSpacing.s6,
                            24, PayPactSpacing.s6, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const PpSectionLabel(
                                label: 'COMMENTS', padding: EdgeInsets.zero),
                            const SizedBox(height: 10),
                            ExpenseCommentsSection(
                              expense: expense,
                              groupName: loaded.groupName,
                              currentUserId: currentUserId,
                              currentUserName: _userName(context),
                            ),
                            ExpenseHistorySection(expense: expense),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _userName(BuildContext context) {
    final auth = context.read<AuthCubit>().state;
    return auth is AuthAuthenticated ? auth.user.name : '';
  }

  Future<void> _remind(BuildContext context, ExpenseDetailLoaded loaded) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final sent = await context
          .read<ExpenseDetailCubit>()
          .remind(actorName: _userName(context));
      messenger.showSnackBar(SnackBar(
        content: Text(sent == 0
            ? "You've already reminded everyone today."
            : 'Reminder sent to $sent ${sent == 1 ? 'person' : 'people'}.'),
      ));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text("Couldn't send reminders. Try again.")));
    }
  }

  String _details(ExpenseDetailLoaded l) {
    final e = l.expense;
    final sym = currencySymbol(l.currency);
    final lines = <String>[
      '${e.title} — $sym${e.amount.toStringAsFixed(e.amount.truncateToDouble() == e.amount ? 0 : 2)}',
      '${e.paidByName} paid on ${DateFormat('MMM d, yyyy').format(e.date)}',
      if (l.groupName.isNotEmpty) 'Group: ${l.groupName}',
      for (final s in e.splits)
        '  • ${s.userName}: $sym${s.amount.toStringAsFixed(2)}',
      if ((e.note ?? '').isNotEmpty) 'Note: ${e.note}',
    ];
    return lines.join('\n');
  }

  void _showMenu(BuildContext context, ExpenseDetailLoaded loaded) {
    final pt = context.pt;
    final cubit = context.read<ExpenseDetailCubit>();
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: pt.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit'),
            onTap: () async {
              Navigator.pop(sheet);
              await context
                  .push('/group/$groupId/expense/$expenseId/edit');
              if (!cubit.isClosed) cubit.load();
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy_all_outlined),
            title: const Text('Duplicate (dated today)'),
            onTap: () async {
              Navigator.pop(sheet);
              try {
                await cubit.duplicate(actorName: _userName(context));
                messenger.showSnackBar(const SnackBar(
                    content: Text('Duplicated. Find it in the group.')));
              } catch (_) {
                messenger.showSnackBar(const SnackBar(
                    content: Text("Couldn't duplicate the expense.")));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.ios_share_rounded),
            title: const Text('Share details'),
            onTap: () async {
              Navigator.pop(sheet);
              final text = _details(loaded);
              try {
                final r = await SharePlus.instance.share(ShareParams(text: text));
                if (r.status != ShareResultStatus.unavailable) return;
              } catch (_) {}
              await Clipboard.setData(ClipboardData(text: text));
              messenger.showSnackBar(
                  const SnackBar(content: Text('Details copied')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.content_copy_rounded),
            title: const Text('Copy details'),
            onTap: () async {
              Navigator.pop(sheet);
              await Clipboard.setData(ClipboardData(text: _details(loaded)));
              messenger.showSnackBar(
                  const SnackBar(content: Text('Details copied')));
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline_rounded, color: pt.negative),
            title: Text('Delete', style: TextStyle(color: pt.negative)),
            onTap: () {
              Navigator.pop(sheet);
              _confirmDelete(context, loaded);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ExpenseDetailLoaded loaded) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete expense?'),
        content: const Text(
            'This will remove the expense and update all balances. You can undo right after.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final actorName = _userName(context);
              final actorId = loaded.currentUserId;
              final removed = await context
                  .read<ExpenseDetailCubit>()
                  .delete(actorName: actorName);
              if (context.mounted) context.pop();
              if (removed == null) return;
              messenger.showSnackBar(SnackBar(
                content: Text('"${removed.title}" deleted'),
                duration: const Duration(seconds: 8),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () => restoreDeletedExpense(
                    expenses: locator<ExpenseRepository>(),
                    notifications: locator<NotificationsRepository>(),
                    expense: removed,
                    actorId: actorId,
                    actorName: actorName,
                    groupName: loaded.groupName,
                  ),
                ),
              ));
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

const _builtinCategories = {
  'food', 'stay', 'transport', 'shopping', 'entertainment', 'other',
  'trip', 'home', 'friends', 'couple',
};
bool _isBuiltin(String c) => _builtinCategories.contains(c);

/// Whether every share is (within rounding) the same.
bool _isEvenSplit(ExpenseEntity e) {
  if (e.splits.isEmpty) return true;
  final first = e.splits.first.amount;
  return e.splits.every((s) => (s.amount - first).abs() <= 0.011);
}

class _SplitTile extends StatelessWidget {
  const _SplitTile({
    required this.split,
    required this.paidById,
    required this.currentUserId,
    required this.sym,
  });

  final ExpenseSplitEntity split;
  final String paidById;
  final String currentUserId;
  final String sym;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final isPayer = split.userId == paidById;
    final isCurrentUser = split.userId == currentUserId;
    final displayName = isCurrentUser ? 'You' : split.userName;
    final subLabel = isPayer
        ? 'paid · $sym${split.amount.toStringAsFixed(0)}'
        : 'owes · $sym${split.amount.toStringAsFixed(0)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        PpAvatar(name: split.userName, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName,
                  style: PayPactTypography.bodyMd.copyWith(
                      color: pt.ink, fontWeight: FontWeight.w600)),
              Text(subLabel,
                  style:
                      PayPactTypography.bodySm.copyWith(color: pt.ink3)),
            ],
          ),
        ),
        if (isPayer) ...[
          PpChip(label: 'PAID', tone: PpChipTone.positive),
          const SizedBox(width: 8),
        ],
        Text(
          '$sym${split.amount.toStringAsFixed(0)}',
          style: PayPactTypography.amountLg.copyWith(
              color: pt.ink, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ]),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: pt.surfaceAlt, borderRadius: PayPactRadius.sm),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: pt.ink2),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      PayPactTypography.bodySm.copyWith(color: pt.ink3)),
              Text(value,
                  style: PayPactTypography.bodyMd.copyWith(color: pt.ink)),
            ],
          ),
        ),
      ]),
    );
  }
}

PpCategory _catFromString(String cat) {
  switch (cat) {
    case 'trip':
      return PpCategory.trip;
    case 'home':
      return PpCategory.home;
    case 'food':
      return PpCategory.food;
    case 'friends':
      return PpCategory.friends;
    case 'stay':
      return PpCategory.stay;
    case 'couple':
      return PpCategory.couple;
    case 'transport':
      return PpCategory.transport;
    case 'shopping':
      return PpCategory.shopping;
    default:
      return PpCategory.other;
  }
}

String _emojiForCategory(PpCategory cat) {
  switch (cat) {
    case PpCategory.food:
      return '🍔';
    case PpCategory.stay:
      return '🏨';
    case PpCategory.transport:
      return '🚗';
    case PpCategory.shopping:
      return '🛍️';
    case PpCategory.trip:
      return '✈️';
    case PpCategory.home:
      return '🏠';
    case PpCategory.friends:
      return '👥';
    case PpCategory.couple:
      return '💑';
    default:
      return '🧾';
  }
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
