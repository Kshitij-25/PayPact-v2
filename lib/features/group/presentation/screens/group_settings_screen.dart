import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/core/theme/app_theme.dart';
import 'package:paypact/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/group/domain/entities/member_entity.dart';
import 'package:paypact/features/group/presentation/bloc/group_bloc.dart';
import 'package:paypact/features/group/presentation/screens/qr_invite_sheet.dart';
import 'package:share_plus/share_plus.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Group Settings Screen
// ─────────────────────────────────────────────────────────────────────────────

class GroupSettingsScreen extends StatelessWidget {
  const GroupSettingsScreen({super.key, required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context) {
    return BlocListener<GroupBloc, GroupState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (ctx, state) {
        // Deleted or left — pop all the way home
        if (state.status == GroupStatus.success &&
            state.groups.every((g) => g.id != groupId)) {
          ctx.go('/');
        }
        if (state.status == GroupStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(ctx)
              .showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      child: BlocBuilder<GroupBloc, GroupState>(
        buildWhen: (p, c) => p.groups != c.groups,
        builder: (ctx, state) {
          final group = state.groups.where((g) => g.id == groupId).firstOrNull;
          final currentUserId = ctx.read<AuthBloc>().state.user?.id ?? '';
          final isAdmin = group?.getMember(currentUserId)?.isAdmin ?? false;

          return Scaffold(
            appBar: AppBar(title: const Text('Group Settings')),
            body: group == null
                ? const SizedBox()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                    children: [
                      // ── Group identity card ──────────────────────────
                      _GroupIdentityCard(group: group),
                      const SizedBox(height: 24),

                      // ── General settings (admin only) ────────────────
                      if (isAdmin) ...[
                        _SectionLabel('General'),
                        const SizedBox(height: 8),
                        _SettingsCard(children: [
                          _SettingsTile(
                            icon: Icons.edit_outlined,
                            iconColor: Theme.of(context).colorScheme.primary,
                            title: 'Edit Name & Category',
                            onTap: () => _showEditSheet(ctx, group),
                          ),
                          _Divider(),
                          _SettingsTile(
                            icon: Icons.currency_exchange,
                            iconColor: PaypactColors.warning,
                            title: 'Default Currency',
                            trailing: Text(group.currency,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                            onTap: () => _showCurrencySheet(ctx, group),
                          ),
                        ]),
                        const SizedBox(height: 20),
                      ],

                      // ── Invite section ───────────────────────────────
                      _SectionLabel('Invite'),
                      const SizedBox(height: 8),
                      _SettingsCard(children: [
                        _SettingsTile(
                          icon: Icons.person_add_outlined,
                          iconColor: Theme.of(context).colorScheme.secondary,
                          title: 'Add Member by Email',
                          onTap: () => _showAddMemberSheet(ctx),
                        ),
                        _Divider(),
                        _SettingsTile(
                          icon: Icons.share_outlined,
                          iconColor: Theme.of(context).colorScheme.primary,
                          title: 'Share Invite Link',
                          onTap: () => _shareInviteLink(ctx),
                        ),
                        if (group.inviteCode != null) ...[
                          _Divider(),
                          _SettingsTile(
                            icon: Icons.qr_code_rounded,
                            iconColor: Theme.of(context).colorScheme.primary,
                            title: 'Show QR Code',
                            subtitle: 'Let someone scan to join instantly',
                            onTap: () {
                              final code = group.inviteCode;
                              if (code == null || code.isEmpty) return;
                              final link =
                                  'https://paypact-fec8e.web.app/invite/$code';
                              QrInviteSheet.show(
                                ctx,
                                groupName: group.name,
                                inviteCode: code,
                                inviteLink: link,
                              );
                            },
                          ),
                        ],
                        _Divider(),
                        _SettingsTile(
                          icon: Icons.qr_code_scanner_outlined,
                          iconColor: Theme.of(context).colorScheme.secondary,
                          title: 'Scan QR to Add',
                          subtitle: "Scan a member's invite QR code",
                          onTap: () => ctx.push('/scan'),
                        ),
                      ]),
                      const SizedBox(height: 20),

                      // ── Members section ──────────────────────────────
                      _SectionLabel('Members (${group.memberCount})'),
                      const SizedBox(height: 8),
                      _MembersCard(
                        group: group,
                        currentUserId: currentUserId,
                        isAdmin: isAdmin,
                        onKick: (memberId) =>
                            _confirmKick(ctx, group, memberId),
                        onRoleChange: (memberId, newRole) =>
                            ctx.read<GroupBloc>().add(
                                  GroupUpdateRequested(group.copyWith(
                                    members: group.members
                                        .map((m) => m.userId == memberId
                                            ? m.copyWith(role: newRole)
                                            : m)
                                        .toList(),
                                  )),
                                ),
                      ),
                      const SizedBox(height: 24),

                      // ── Danger zone ──────────────────────────────────
                      _SectionLabel('Danger Zone'),
                      const SizedBox(height: 8),
                      _SettingsCard(children: [
                        _SettingsTile(
                          icon: Icons.exit_to_app_outlined,
                          iconColor: PaypactColors.warning,
                          title: 'Leave Group',
                          titleColor: PaypactColors.warning,
                          showChevron: false,
                          onTap: () => _confirmLeave(ctx, group, currentUserId),
                        ),
                        if (isAdmin) ...[
                          _Divider(),
                          _SettingsTile(
                            icon: Icons.delete_outline,
                            iconColor: Theme.of(context).colorScheme.error,
                            title: 'Delete Group',
                            titleColor: Theme.of(context).colorScheme.error,
                            showChevron: false,
                            onTap: () => _confirmDelete(ctx, group),
                          ),
                        ],
                      ]),
                    ],
                  ),
          );
        },
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _showEditSheet(BuildContext ctx, GroupEntity group) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: ctx.read<GroupBloc>(),
        child: _EditGroupSheet(group: group),
      ),
    );
  }

  void _showCurrencySheet(BuildContext ctx, GroupEntity group) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: ctx.read<GroupBloc>(),
        child: _CurrencySheet(group: group),
      ),
    );
  }

  void _showAddMemberSheet(BuildContext ctx) {
    ctx.read<GroupBloc>().add(GroupMemberSearchCleared());
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: ctx.read<GroupBloc>(),
        child: _AddMemberSheet(groupId: groupId),
      ),
    );
  }

  void _shareInviteLink(BuildContext ctx) {
    final group = ctx.read<GroupBloc>().state.groups.firstWhere(
        (g) => g.id == groupId,
        orElse: () => throw StateError('Group not found'));

    final code = group.inviteCode;
    if (code == null || code.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
            content: Text('No invite code available for this group.')),
      );
      return;
    }

    final link = 'https://paypact-fec8e.web.app/invite/$code';
    SharePlus.instance.share(ShareParams(
        title: 'Join my group "${group.name}" on Paypact!',
        text:
            'Tap the link to join:\n$link\n\n' 'or enter invite code: $code'));
  }

  void _confirmLeave(
      BuildContext ctx, GroupEntity group, String currentUserId) {
    final isLastAdmin = group.members.where((m) => m.isAdmin).length == 1 &&
        group.getMember(currentUserId)?.isAdmin == true;

    if (isLastAdmin && group.memberCount > 1) {
      showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
          title: const Text('Cannot Leave'),
          content: const Text(
              'You are the only admin. Assign another admin before leaving.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('Leave Group'),
        content: Text('Leave "${group.name}"? '
            '${isLastAdmin ? 'The group will be deleted since you are the last member.' : 'You will lose access to all expenses.'}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: PaypactColors.warning),
            onPressed: () {
              Navigator.pop(dCtx);
              if (isLastAdmin) {
                // Last member leaving — just delete the group
                ctx.read<GroupBloc>().add(GroupDeleteRequested(group.id));
              } else {
                ctx.read<GroupBloc>().add(GroupLeaveRequested(
                    groupId: group.id, userId: currentUserId));
              }
            },
            child: const Text('Leave', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmKick(BuildContext ctx, GroupEntity group, String memberId) {
    final member = group.getMember(memberId);
    if (member == null) return;
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove ${member.displayName} from "${group.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () {
              Navigator.pop(dCtx);
              ctx.read<GroupBloc>().add(GroupKickMemberRequested(
                  groupId: group.id, userId: memberId));
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, GroupEntity group) {
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text(
            'Permanently delete "${group.name}"? All expenses, settlements, and data will be removed. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () {
              Navigator.pop(dCtx);
              ctx.read<GroupBloc>().add(GroupDeleteRequested(group.id));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Group identity card
// ─────────────────────────────────────────────────────────────────────────────

class _GroupIdentityCard extends StatelessWidget {
  const _GroupIdentityCard({required this.group});
  final GroupEntity group;

  static String _catEmoji(GroupCategory c) => switch (c) {
        GroupCategory.home => '🏠',
        GroupCategory.trip => '✈️',
        GroupCategory.couple => '❤️',
        GroupCategory.friends => '👯',
        GroupCategory.work => '💼',
        GroupCategory.other => '📂',
      };

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.8)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14)),
              child: Center(
                  child: Text(_catEmoji(group.category),
                      style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      '${group.memberCount} member${group.memberCount != 1 ? 's' : ''} · ${group.currency}',
                      style: TextStyle(
                          fontSize: 13,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ]),
            ),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Members card
// ─────────────────────────────────────────────────────────────────────────────

class _MembersCard extends StatelessWidget {
  const _MembersCard({
    required this.group,
    required this.currentUserId,
    required this.isAdmin,
    required this.onKick,
    required this.onRoleChange,
  });
  final GroupEntity group;
  final String currentUserId;
  final bool isAdmin;
  final void Function(String memberId) onKick;
  final void Function(String memberId, MemberRole newRole) onRoleChange;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: group.members.asMap().entries.map((entry) {
          final i = entry.key;
          final m = entry.value;
          final isMe = m.userId == currentUserId;
          final isLast = i == group.members.length - 1;

          return Column(children: [
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                backgroundImage:
                    m.photoUrl != null ? NetworkImage(m.photoUrl!) : null,
                child: m.photoUrl == null
                    ? Text(m.displayName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13))
                    : null,
              ),
              title: Row(children: [
                Flexible(
                    child: Text(m.displayName,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500))),
                if (isMe) _Chip('You', Theme.of(context).colorScheme.primary),
                if (m.isAdmin) _Chip('Admin', PaypactColors.warning),
              ]),
              subtitle: Text(m.email,
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              trailing: isAdmin && !isMe
                  ? _MemberMenu(
                      isTargetAdmin: m.isAdmin,
                      onPromote: m.isAdmin
                          ? null
                          : () => onRoleChange(m.userId, MemberRole.admin),
                      onDemote: m.isAdmin
                          ? () => onRoleChange(m.userId, MemberRole.member)
                          : null,
                      onKick: () => onKick(m.userId),
                    )
                  : null,
            ),
            if (!isLast)
              const Divider(
                  height: 1, indent: 56, endIndent: 0, thickness: 0.5),
          ]);
        }).toList(),
      ),
    );
  }
}

class _MemberMenu extends StatelessWidget {
  const _MemberMenu({
    required this.isTargetAdmin,
    required this.onPromote,
    required this.onDemote,
    required this.onKick,
  });
  final bool isTargetAdmin;
  final VoidCallback? onPromote;
  final VoidCallback? onDemote;
  final VoidCallback onKick;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        icon: Icon(Icons.more_vert,
            size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
        onSelected: (v) {
          if (v == 'promote' && onPromote != null) onPromote!();
          if (v == 'demote' && onDemote != null) onDemote!();
          if (v == 'kick') onKick();
        },
        itemBuilder: (_) => [
          if (onPromote != null)
            const PopupMenuItem(value: 'promote', child: Text('Make Admin')),
          if (onDemote != null)
            const PopupMenuItem(value: 'demote', child: Text('Remove Admin')),
          PopupMenuItem(
            value: 'kick',
            child: Text('Remove from Group',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      );
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(left: 5),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4)),
        child: Text(text,
            style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w700, color: color)),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared UI helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0.8),
        ),
      );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Column(children: children),
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 52, endIndent: 0, thickness: 0.5);
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.titleColor,
    this.showChevron = true,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? titleColor;
  final bool showChevron;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        title: Text(title,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: titleColor ?? Theme.of(context).colorScheme.onSurface)),
        subtitle: subtitle != null
            ? Text(subtitle!,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant))
            : null,
        trailing: trailing ??
            (showChevron
                ? Icon(Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 20)
                : null),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Name & Category Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _EditGroupSheet extends StatefulWidget {
  const _EditGroupSheet({required this.group});
  final GroupEntity group;

  @override
  State<_EditGroupSheet> createState() => _EditGroupSheetState();
}

class _EditGroupSheetState extends State<_EditGroupSheet> {
  late final TextEditingController _nameCtrl;
  late GroupCategory _category;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.group.name);
    _category = widget.group.category;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    context.read<GroupBloc>().add(GroupUpdateRequested(
        widget.group.copyWith(name: name, category: _category)));
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Group updated')));
  }

  static String _catLabel(GroupCategory c) => switch (c) {
        GroupCategory.home => '🏠 Home',
        GroupCategory.trip => '✈️ Trip',
        GroupCategory.couple => '❤️ Couple',
        GroupCategory.friends => '👯 Friends',
        GroupCategory.work => '💼 Work',
        GroupCategory.other => '📂 Other',
      };

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Handle(),
            const SizedBox(height: 18),
            const Text('Edit Name & Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                  labelText: 'Group name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 16),
            const Text('Category',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: GroupCategory.values.map((cat) {
                final sel = cat == _category;
                return ChoiceChip(
                  label: Text(_catLabel(cat)),
                  selected: sel,
                  selectedColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                      color: sel ? Theme.of(context).colorScheme.primary : null,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.normal),
                  onSelected: (_) => setState(() => _category = cat),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Save Changes',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Currency Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CurrencySheet extends StatelessWidget {
  const _CurrencySheet({required this.group});
  final GroupEntity group;

  static const _currencies = [
    ('USD', 'US Dollar', '\$'),
    ('EUR', 'Euro', '€'),
    ('GBP', 'British Pound', '£'),
    ('JPY', 'Japanese Yen', '¥'),
    ('AUD', 'Australian Dollar', 'A\$'),
    ('CAD', 'Canadian Dollar', 'C\$'),
    ('CHF', 'Swiss Franc', 'Fr'),
    ('INR', 'Indian Rupee', '₹'),
    ('BRL', 'Brazilian Real', 'R\$'),
    ('MXN', 'Mexican Peso', 'MX\$'),
    ('SGD', 'Singapore Dollar', 'S\$'),
    ('NOK', 'Norwegian Krone', 'kr'),
    ('SEK', 'Swedish Krona', 'kr'),
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: _Handle()),
              const SizedBox(height: 18),
              const Text('Group Currency',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('This sets the currency for new expenses in this group.',
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 16),
            ]),
          ),
          Expanded(
            child: ListView.separated(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: _currencies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (listCtx, i) {
                final (code, name, symbol) = _currencies[i];
                final selected = group.currency == code;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    context.read<GroupBloc>().add(
                        GroupUpdateRequested(group.copyWith(currency: code)));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Currency changed to $code')));
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : PaypactColors.divider,
                          width: selected ? 2 : 1),
                      color: selected
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.05)
                          : Theme.of(context).cardColor,
                    ),
                    child: Row(children: [
                      SizedBox(
                        width: 36,
                        child: Text(symbol,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: selected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface)),
                              Text(code,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant)),
                            ]),
                      ),
                      if (selected)
                        Icon(Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Member Sheet (reused from detail screen)
// ─────────────────────────────────────────────────────────────────────────────

class _AddMemberSheet extends StatefulWidget {
  const _AddMemberSheet({required this.groupId});
  final String groupId;

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _search() {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    context
        .read<GroupBloc>()
        .add(GroupMemberSearchRequested(email: email, groupId: widget.groupId));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _Handle()),
            const SizedBox(height: 18),
            const Text('Add Member',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Search by email to add someone.',
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: 'Enter email address',
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              BlocBuilder<GroupBloc, GroupState>(
                buildWhen: (p, c) =>
                    p.memberSearchStatus != c.memberSearchStatus,
                builder: (_, state) {
                  final loading =
                      state.memberSearchStatus == MemberSearchStatus.searching;
                  return ElevatedButton(
                    onPressed: loading ? null : _search,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Search'),
                  );
                },
              ),
            ]),
            const SizedBox(height: 20),
            BlocConsumer<GroupBloc, GroupState>(
              listenWhen: (p, c) =>
                  p.memberSearchStatus != c.memberSearchStatus,
              listener: (ctx, state) {
                if (state.memberSearchStatus == MemberSearchStatus.added) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Member added')));
                }
              },
              buildWhen: (p, c) =>
                  p.memberSearchStatus != c.memberSearchStatus ||
                  p.foundUser != c.foundUser,
              builder: (ctx, state) => switch (state.memberSearchStatus) {
                MemberSearchStatus.idle => const SizedBox.shrink(),
                MemberSearchStatus.searching => const Center(
                    child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator())),
                MemberSearchStatus.notFound => _StatusRow(
                    Icons.search_off,
                    Theme.of(context).colorScheme.error,
                    'No user found with that email.'),
                MemberSearchStatus.alreadyMember => _StatusRow(
                    Icons.check_circle_outline,
                    Theme.of(context).colorScheme.onSurfaceVariant,
                    '${state.foundUser?.displayName ?? 'User'} is already in the group.'),
                MemberSearchStatus.found => _FoundUserCard(
                    user: state.foundUser!,
                    onAdd: () => ctx.read<GroupBloc>().add(
                        GroupMemberAddRequested(
                            groupId: widget.groupId, user: state.foundUser!))),
                MemberSearchStatus.adding => _FoundUserCard(
                    user: state.foundUser!, loading: true, onAdd: () {}),
                MemberSearchStatus.added => const SizedBox.shrink(),
                MemberSearchStatus.addFailure => _StatusRow(
                    Icons.error_outline,
                    Theme.of(context).colorScheme.error,
                    state.memberSearchError ?? 'Failed to add member.'),
              },
            ),
          ]),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow(this.icon, this.color, this.text);
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: TextStyle(color: color, fontWeight: FontWeight.w500))),
      ]);
}

class _FoundUserCard extends StatelessWidget {
  const _FoundUserCard(
      {required this.user, required this.onAdd, this.loading = false});
  final dynamic user;
  final VoidCallback onAdd;
  final bool loading;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
            backgroundImage: (user.photoUrl as String?) != null
                ? NetworkImage(user.photoUrl as String)
                : null,
            child: (user.photoUrl as String?) == null
                ? Text(
                    (user.displayName as String).substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(user.displayName as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                Text(user.email as String,
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ])),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: loading ? null : onAdd,
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Add'),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tiny helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
            color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
      );
}
