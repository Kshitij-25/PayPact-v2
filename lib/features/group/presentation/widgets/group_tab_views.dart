import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/utils/currency_utils.dart';
import 'package:paypact/design_system/components/paypact_button.dart';
import 'package:paypact/design_system/components/paypact_card.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/group/presentation/cubit/group_detail_cubit.dart';
import 'package:paypact/features/group/presentation/widgets/invite_sheet.dart';
import 'package:paypact/features/settle/cubit/settle_cubit.dart';
import 'package:paypact/widgets/pp_atoms.dart';

String _money(String currency, double v) {
  final sym = currencySymbol(currency);
  final abs = v.abs();
  return '$sym${abs.toStringAsFixed(abs.truncateToDouble() == abs ? 0 : 2)}';
}

// ── Balances ──────────────────────────────────────────────────────────────────

/// Net position of every member of the group (positive = is owed money).
class GroupBalancesView extends StatelessWidget {
  const GroupBalancesView(
      {super.key, required this.loaded, required this.currentUserId});
  final GroupDetailLoaded loaded;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final group = loaded.group;
    final entries = group.memberIds
        .map((id) => MapEntry(id, loaded.globalMemberBalances[id] ?? 0.0))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxAbs = entries.fold<double>(
        0, (m, e) => e.value.abs() > m ? e.value.abs() : m);

    return PayPactCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) Divider(color: pt.border, height: 1, indent: 16),
            _BalanceRow(
              name: entries[i].key == currentUserId
                  ? 'You'
                  : (group.memberNames[entries[i].key] ?? 'Member'),
              avatarName: group.memberNames[entries[i].key] ?? 'Member',
              value: entries[i].value,
              fraction: maxAbs == 0 ? 0 : entries[i].value.abs() / maxAbs,
              money: _money(group.currency, entries[i].value),
            ),
          ],
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({
    required this.name,
    required this.avatarName,
    required this.value,
    required this.fraction,
    required this.money,
  });
  final String name;
  final String avatarName;
  final double value;
  final double fraction;
  final String money;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final settled = value.abs() < 0.005;
    final color = settled ? pt.ink3 : (value > 0 ? pt.positive : pt.negative);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        PpAvatar(name: avatarName, size: 38),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: PayPactTypography.bodyMd
                      .copyWith(color: pt.ink, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: PayPactRadius.full,
                child: LinearProgressIndicator(
                  value: settled ? 0 : fraction.clamp(0.04, 1.0),
                  minHeight: 5,
                  backgroundColor: pt.surfaceAlt,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(settled ? 'Settled' : money,
                style: PayPactTypography.bodyMd
                    .copyWith(color: color, fontWeight: FontWeight.w700)),
            Text(settled ? 'all square' : (value > 0 ? 'gets back' : 'owes'),
                style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
          ],
        ),
      ]),
    );
  }
}

// ── Activity ──────────────────────────────────────────────────────────────────

class GroupActivityItem {
  const GroupActivityItem({
    required this.at,
    required this.isSettlement,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.settlementId,
    this.fromUserId,
    this.toUserId,
    this.fromUserName,
    this.toUserName,
    this.amountPaise,
    this.isReversal = false,
    this.reversed = false,
  });
  final DateTime at;
  final bool isSettlement;
  final String title;
  final String subtitle;
  final double amount;

  // Settlement details (null for expenses).
  final String? settlementId;
  final String? fromUserId;
  final String? toUserId;
  final String? fromUserName;
  final String? toUserName;
  final int? amountPaise;

  /// This entry undoes an earlier payment.
  final bool isReversal;

  /// A later entry has already reversed this payment.
  final bool reversed;

  /// Payments can be disputed for two weeks.
  static const reversalWindow = Duration(days: 14);

  /// Only the person who was paid can say "this never arrived", once, and only
  /// for a payment that hasn't already been reversed.
  bool canReverse(String userId, DateTime now) =>
      isSettlement &&
      !isReversal &&
      !reversed &&
      settlementId != null &&
      toUserId == userId &&
      now.difference(at) <= reversalWindow;
}

/// Expenses and settle-up payments merged into one newest-first timeline.
List<GroupActivityItem> buildGroupActivity(GroupDetailLoaded loaded) {
  final reversedIds = {
    for (final s in loaded.settlements)
      if (s['type'] == 'reversal' && s['reversesId'] is String)
        s['reversesId'] as String,
  };
  final items = <GroupActivityItem>[
    for (final e in loaded.expenses)
      GroupActivityItem(
        at: e.createdAt,
        isSettlement: false,
        title: e.title,
        subtitle: '${e.paidByName} paid',
        amount: e.amount,
      ),
    for (final s in loaded.settlements)
      () {
        final isReversal = s['type'] == 'reversal';
        final paise = s['amountPaise'] is num
            ? (s['amountPaise'] as num).toInt()
            : (((s['amount'] as num?)?.toDouble() ?? 0) * 100).round();
        final id = s['id'] as String?;
        return GroupActivityItem(
          at: (s['createdAt'] as DateTime?) ??
              DateTime.fromMillisecondsSinceEpoch(0),
          isSettlement: true,
          isReversal: isReversal,
          reversed: id != null && reversedIds.contains(id),
          title:
              '${s['fromUserName'] ?? 'Someone'} paid ${s['toUserName'] ?? 'someone'}',
          subtitle: isReversal ? 'Payment reversed' : 'Settled up',
          amount: paise / 100,
          settlementId: id,
          fromUserId: s['fromUserId'] as String?,
          toUserId: s['toUserId'] as String?,
          fromUserName: s['fromUserName'] as String?,
          toUserName: s['toUserName'] as String?,
          amountPaise: paise,
        );
      }(),
  ]..sort((a, b) => b.at.compareTo(a.at));
  return items;
}

class GroupActivityView extends StatelessWidget {
  const GroupActivityView({
    super.key,
    required this.loaded,
    this.currentUserId = '',
    this.now,
  });
  final GroupDetailLoaded loaded;
  final String currentUserId;

  /// Injectable clock (tests).
  final DateTime? now;

  Future<void> _reverse(BuildContext context, GroupActivityItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final group = loaded.group;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payment not received?'),
        content: Text(
            '${item.fromUserName} will owe you ${_money(group.currency, item.amount)} again. '
            'This is recorded in the group and ${item.fromUserName} is told.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Mark as not received')),
        ],
      ),
    );
    if (ok != true) return;
    final error = await SettleCubit(locator(), locator(), locator())
        .reverseSettlement(
      groupId: group.id,
      groupName: group.name,
      settlementId: item.settlementId!,
      payerId: item.fromUserId!,
      payerName: item.fromUserName ?? '',
      payeeId: item.toUserId!,
      payeeName: item.toUserName ?? '',
      amountPaise: item.amountPaise!,
      currency: group.currency,
    );
    messenger.showSnackBar(SnackBar(
        content: Text(error ?? 'Marked as not received. Balances updated.')));
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final items = buildGroupActivity(loaded);
    if (items.isEmpty) {
      return _Empty(
          icon: Icons.history_rounded, label: 'No activity yet in this group');
    }
    final currency = loaded.group.currency;
    final clock = now ?? DateTime.now();
    return PayPactCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(color: pt.border, height: 1, indent: 16),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: items[i].isReversal
                        ? pt.negativeSoft
                        : items[i].isSettlement
                            ? pt.positiveSoft
                            : pt.surfaceAlt,
                    borderRadius: PayPactRadius.sm,
                  ),
                  child: Icon(
                    items[i].isReversal
                        ? Icons.undo_rounded
                        : items[i].isSettlement
                            ? Icons.handshake_outlined
                            : Icons.receipt_long_outlined,
                    size: 18,
                    color: items[i].isReversal
                        ? pt.negative
                        : items[i].isSettlement
                            ? pt.positive
                            : pt.ink2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(items[i].title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PayPactTypography.bodyMd.copyWith(
                              color: pt.ink,
                              fontWeight: FontWeight.w600,
                              decoration: items[i].reversed
                                  ? TextDecoration.lineThrough
                                  : null)),
                      Text(
                          '${items[i].reversed ? 'Reversed' : items[i].subtitle} · ${_when(items[i].at)}',
                          style: PayPactTypography.bodySm
                              .copyWith(color: pt.ink3)),
                      if (items[i].canReverse(currentUserId, clock))
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: GestureDetector(
                            onTap: () => _reverse(context, items[i]),
                            child: Text('Not received?',
                                style: PayPactTypography.bodySm.copyWith(
                                    color: pt.accent,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(_money(currency, items[i].amount),
                    style: PayPactTypography.bodyMd.copyWith(
                        color: items[i].reversed
                            ? pt.ink3
                            : items[i].isReversal
                                ? pt.negative
                                : items[i].isSettlement
                                    ? pt.positive
                                    : pt.ink,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  static String _when(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'today';
    if (d == today.subtract(const Duration(days: 1))) return 'yesterday';
    return DateFormat('MMM d').format(dt);
  }
}

// ── Members ───────────────────────────────────────────────────────────────────

class GroupMembersView extends StatelessWidget {
  const GroupMembersView(
      {super.key, required this.loaded, required this.currentUserId});
  final GroupDetailLoaded loaded;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final group = loaded.group;
    final ids = [
      if (group.memberIds.contains(currentUserId)) currentUserId,
      ...group.memberIds.where((id) => id != currentUserId),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PayPactCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < ids.length; i++) ...[
                if (i > 0) Divider(color: pt.border, height: 1, indent: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 13),
                  child: Row(children: [
                    PpAvatar(
                        name: group.memberNames[ids[i]] ?? 'Member', size: 38),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                          ids[i] == currentUserId
                              ? 'You'
                              : (group.memberNames[ids[i]] ?? 'Member'),
                          style: PayPactTypography.bodyMd.copyWith(
                              color: pt.ink, fontWeight: FontWeight.w600)),
                    ),
                    if (group.isAdmin(ids[i]))
                      PpChip(label: 'Admin', tone: PpChipTone.ghost),
                  ]),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: PayPactButton(
              onPressed: () => context.push('/group/add-members',
                  extra: {'groupId': group.id}),
              label: 'Add people',
              variant: PayPactButtonVariant.secondary,
              isFullWidth: true,
              leftIcon: Icons.person_add_alt_1_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: PayPactButton(
              onPressed: () => showInviteSheet(context,
                  group: group, currentUserId: currentUserId),
              label: 'Invite link',
              variant: PayPactButtonVariant.accent,
              isFullWidth: true,
              leftIcon: Icons.qr_code_rounded,
            ),
          ),
        ]),
        if (group.isAdmin(currentUserId)) ...[
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () => context.push('/group/${group.id}/settings'),
              child: Text('Manage roles & members',
                  style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
            ),
          ),
        ],
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Column(children: [
        Icon(icon, size: 32, color: pt.ink3),
        const SizedBox(height: 8),
        Text(label, style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
      ]),
    );
  }
}
