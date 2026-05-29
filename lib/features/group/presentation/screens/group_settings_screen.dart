import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/features/group/presentation/cubit/group_settings_cubit.dart';
import 'package:paypact/features/notification/domain/repositories/notifications_repository.dart';
import 'package:paypact/widgets/pp_atoms.dart';

class GroupSettingsScreen extends StatelessWidget {
  const GroupSettingsScreen({super.key, required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GroupSettingsCubit(
            locator<GroupRepository>(),
            locator<NotificationsRepository>(),
            groupId,
          )..load(),
      child: _GroupSettingsBody(groupId: groupId),
    );
  }
}

class _GroupSettingsBody extends StatefulWidget {
  const _GroupSettingsBody({required this.groupId});
  final String groupId;

  @override
  State<_GroupSettingsBody> createState() => _GroupSettingsBodyState();
}

class _GroupSettingsBodyState extends State<_GroupSettingsBody> {
  late final TextEditingController _nameCtrl;
  String _emoji = '';
  String _category = '';
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _nameCtrl.addListener(_onEdit);
  }

  void _onEdit() => setState(() => _dirty = true);

  void _syncFromGroup(GroupEntity g) {
    if (_emoji.isEmpty) _emoji = g.emoji;
    if (_category.isEmpty) _category = g.category;
    if (_nameCtrl.text.isEmpty) {
      _nameCtrl.removeListener(_onEdit);
      _nameCtrl.text = g.name;
      _nameCtrl.addListener(_onEdit);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save(BuildContext context, String actorId, String actorName) {
    context.read<GroupSettingsCubit>().save(
          name: _nameCtrl.text.trim(),
          emoji: _emoji,
          category: _category,
          actorId: actorId,
          actorName: actorName,
        );
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final authState = context.watch<AuthCubit>().state;
    final currentUserId =
        authState is AuthAuthenticated ? authState.user.id : '';
    final currentUserName =
        authState is AuthAuthenticated ? authState.user.name : '';

    return BlocConsumer<GroupSettingsCubit, GroupSettingsState>(
      listener: (context, state) {
        if (state is GroupSettingsSaved) {
          setState(() => _dirty = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved')),
          );
        }
        if (state is GroupSettingsDeleted) {
          context.go('/');
        }
        if (state is GroupSettingsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        GroupEntity? group;
        if (state is GroupSettingsLoaded) group = state.group;
        if (state is GroupSettingsSaving) group = state.group;
        if (state is GroupSettingsSaved) group = state.group;

        if (group != null) _syncFromGroup(group);

        final loading =
            state is GroupSettingsLoading || state is GroupSettingsInitial;
        final saving = state is GroupSettingsSaving;
        final isAdmin = group?.createdBy == currentUserId;

        return Scaffold(
          backgroundColor: pt.bg,
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(context, pt, group!, isAdmin, saving,
                  currentUserId, currentUserName),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    PayPactThemeExtension pt,
    GroupEntity group,
    bool isAdmin,
    bool saving,
    String currentUserId,
    String currentUserName,
  ) {
    return Stack(
      children: [
        const PpBackdropGlow(intensity: 0.1),
        SafeArea(
          child: Column(
            children: [
              _AppBar(
                dirty: _dirty,
                saving: saving,
                onBack: () => context.pop(),
                onSave: _dirty && !saving
                    ? () => _save(context, currentUserId, currentUserName)
                    : null,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      _IdentityCard(
                        group: group,
                        emoji: _emoji,
                        nameCtrl: _nameCtrl,
                        category: _category,
                        onEmojiTap: () => _pickEmoji(context),
                        onCategoryTap: () => _pickCategory(context),
                      ),
                      const SizedBox(height: 28),
                      _MembersSection(
                        group: group,
                        currentUserId: currentUserId,
                        isAdmin: isAdmin,
                        onRemove: (uid) => _confirmRemove(
                            context, group, uid, currentUserId, currentUserName),
                        onAddMembers: () => context.push(
                            '/group/add-members',
                            extra: {'groupId': group.id}),
                      ),
                      const SizedBox(height: 28),
                      _InviteSection(groupId: group.id, groupName: group.name),
                      const SizedBox(height: 28),
                      _PreferencesSection(
                        group: group,
                        isAdmin: isAdmin,
                        onDelete: () => _confirmDelete(
                            context, currentUserId, currentUserName),
                        onLeave: () => _confirmLeave(
                            context, currentUserId, currentUserName),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _pickEmoji(BuildContext context) {
    final emojis = ['🏖', '🏠', '💑', '🍕', '💼', '✨', '🌍', '🎉', '🏕', '🚗', '🍿', '🎸'];
    showModalBottomSheet(
      context: context,
      backgroundColor: context.pt.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pick an emoji',
                style: PayPactTypography.headingMd
                    .copyWith(color: context.pt.ink)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: emojis
                  .map((e) => GestureDetector(
                        onTap: () {
                          setState(() {
                            _emoji = e;
                            _dirty = true;
                          });
                          Navigator.pop(sheetCtx);
                        },
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: context.pt.surfaceAlt,
                            borderRadius: PayPactRadius.md,
                            border: Border.all(
                              color: e == _emoji
                                  ? context.pt.accent
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(e,
                              style: const TextStyle(fontSize: 24)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _pickCategory(BuildContext context) {
    const cats = [
      ('trip', 'Trip', '🏖'),
      ('home', 'Home', '🏠'),
      ('couple', 'Couple', '💑'),
      ('friends', 'Friends', '🍕'),
      ('work', 'Work', '💼'),
      ('other', 'Other', '✨'),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: context.pt.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category',
                style: PayPactTypography.headingMd
                    .copyWith(color: context.pt.ink)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cats
                  .map((c) {
                    final selected = _category == c.$1;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _category = c.$1;
                          _dirty = true;
                        });
                        Navigator.pop(sheetCtx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: selected
                              ? context.pt.accent
                              : context.pt.surfaceAlt,
                          borderRadius: PayPactRadius.full,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(c.$3,
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(c.$2,
                                style: PayPactTypography.bodyMd.copyWith(
                                  color: selected
                                      ? Colors.white
                                      : context.pt.ink,
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),
                    );
                  })
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(BuildContext context, GroupEntity group, String userId,
      String actorId, String actorName) {
    final name = group.memberNames[userId] ?? 'this member';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove member'),
        content: Text('Remove $name from the group?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<GroupSettingsCubit>().removeMember(
                    userId,
                    actorId: actorId,
                    actorName: actorName,
                  );
            },
            child: Text('Remove',
                style: TextStyle(color: context.pt.negative)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, String actorId, String actorName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete group'),
        content: const Text(
            'This will permanently delete the group and all expenses. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<GroupSettingsCubit>().deleteGroup(
                    actorId: actorId,
                    actorName: actorName,
                  );
            },
            child: Text('Delete',
                style: TextStyle(color: context.pt.negative)),
          ),
        ],
      ),
    );
  }

  void _confirmLeave(
      BuildContext context, String userId, String actorName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave group'),
        content: const Text('You will be removed from this group.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<GroupSettingsCubit>().removeMember(
                    userId,
                    actorId: userId,
                    actorName: actorName,
                  );
            },
            child: Text('Leave',
                style: TextStyle(color: context.pt.negative)),
          ),
        ],
      ),
    );
  }
}

// ── App bar ───────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  const _AppBar({
    required this.dirty,
    required this.saving,
    required this.onBack,
    required this.onSave,
  });
  final bool dirty;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Row(
        children: [
          PpGlassIconButton(
              icon: Icons.arrow_back_rounded, onTap: onBack),
          const Spacer(),
          Text('Group settings',
              style: PayPactTypography.bodyMd.copyWith(
                  color: pt.ink, fontWeight: FontWeight.w600)),
          const Spacer(),
          SizedBox(
            width: 56,
            child: Align(
              alignment: Alignment.centerRight,
              child: dirty
                  ? GestureDetector(
                      onTap: onSave,
                      child: saving
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: pt.accent))
                          : Text('Save',
                              style: PayPactTypography.bodyMd.copyWith(
                                  color: pt.accent,
                                  fontWeight: FontWeight.w600)),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Identity card ─────────────────────────────────────────────────────────────

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.group,
    required this.emoji,
    required this.nameCtrl,
    required this.category,
    required this.onEmojiTap,
    required this.onCategoryTap,
  });
  final GroupEntity group;
  final String emoji;
  final TextEditingController nameCtrl;
  final String category;
  final VoidCallback onEmojiTap;
  final VoidCallback onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final catLabel = _catLabel(category);
    final catEmoji = _catEmoji(category);
    final created =
        DateFormat('MMM d').format(group.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: pt.surface,
        borderRadius: PayPactRadius.lg,
        border: Border.all(color: pt.border),
        boxShadow: pt.shadowSm,
      ),
      child: Column(
        children: [
          // Emoji banner
          GestureDetector(
            onTap: onEmojiTap,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: pt.surfaceAlt,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(emoji,
                      style: const TextStyle(fontSize: 48)),
                  Positioned(
                    bottom: 10,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: pt.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: pt.border),
                      ),
                      child: Icon(Icons.edit_rounded,
                          size: 13, color: pt.ink3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Fields
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name field
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: nameCtrl,
                        style: PayPactTypography.headingLg
                            .copyWith(color: pt.ink),
                        decoration: InputDecoration(
                          hintText: 'Group name',
                          hintStyle: PayPactTypography.headingLg
                              .copyWith(color: pt.ink3),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Icon(Icons.edit_rounded, size: 14, color: pt.ink3),
                  ],
                ),
                const SizedBox(height: 8),
                // Category + meta row
                Row(
                  children: [
                    GestureDetector(
                      onTap: onCategoryTap,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(catEmoji,
                              style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          Text(catLabel,
                              style: PayPactTypography.bodySm
                                  .copyWith(color: pt.ink2)),
                        ],
                      ),
                    ),
                    Text(' · ',
                        style: PayPactTypography.bodySm
                            .copyWith(color: pt.ink3)),
                    Text(group.currency,
                        style: PayPactTypography.bodySm
                            .copyWith(color: pt.ink2)),
                    Text(' · ',
                        style: PayPactTypography.bodySm
                            .copyWith(color: pt.ink3)),
                    Text('Created $created',
                        style: PayPactTypography.bodySm
                            .copyWith(color: pt.ink3)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Members section ───────────────────────────────────────────────────────────

class _MembersSection extends StatelessWidget {
  const _MembersSection({
    required this.group,
    required this.currentUserId,
    required this.isAdmin,
    required this.onRemove,
    required this.onAddMembers,
  });
  final GroupEntity group;
  final String currentUserId;
  final bool isAdmin;
  final void Function(String uid) onRemove;
  final VoidCallback onAddMembers;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('MEMBERS',
                style: PayPactTypography.label.copyWith(
                    color: pt.ink3, letterSpacing: 1.5)),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: pt.surfaceAlt,
                borderRadius: PayPactRadius.full,
              ),
              child: Text('${group.memberIds.length} members',
                  style: PayPactTypography.bodySm.copyWith(
                      color: pt.accent, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: pt.surface,
            borderRadius: PayPactRadius.lg,
            border: Border.all(color: pt.border),
            boxShadow: pt.shadowSm,
          ),
          child: Column(
            children: [
              // Sort so current user appears first
              ..._sortedMembers(group, currentUserId)
                  .asMap()
                  .entries
                  .map((e) {
                final uid = e.key;
                final memberId = e.value;
                final isLast = uid == group.memberIds.length - 1;
                return _MemberRow(
                  name: group.memberNames[memberId] ?? memberId,
                  isCurrentUser: memberId == currentUserId,
                  isCreator: memberId == group.createdBy,
                  isAdmin: isAdmin,
                  showDivider: !isLast,
                  onRemove: memberId != currentUserId
                      ? () => onRemove(memberId)
                      : null,
                );
              }),
              // Add members row
              const _RowDivider(),
              _AddMembersRow(onTap: onAddMembers),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _sortedMembers(GroupEntity group, String currentUserId) {
    final ids = List<String>.from(group.memberIds);
    ids.remove(currentUserId);
    ids.insert(0, currentUserId);
    return ids;
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.name,
    required this.isCurrentUser,
    required this.isCreator,
    required this.isAdmin,
    required this.showDivider,
    this.onRemove,
  });
  final String name;
  final bool isCurrentUser;
  final bool isCreator;
  final bool isAdmin;
  final bool showDivider;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              PpAvatar(name: name, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(isCurrentUser ? 'You' : name,
                            style: PayPactTypography.bodyMd.copyWith(
                                color: pt.ink,
                                fontWeight: FontWeight.w600)),
                        if (isCreator) ...[
                          const SizedBox(width: 6),
                          _Badge(label: 'ADMIN', tone: _BadgeTone.accent),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCurrentUser
                          ? 'That\'s you'
                          : isCreator
                              ? 'Group admin'
                              : name.split(' ').first,
                      style: PayPactTypography.bodySm
                          .copyWith(color: pt.ink3),
                    ),
                  ],
                ),
              ),
              if (!isCurrentUser && isAdmin)
                GestureDetector(
                  onTap: () => _showMenu(context),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.more_horiz_rounded,
                        color: pt.ink3, size: 20),
                  ),
                ),
            ],
          ),
        ),
        if (showDivider) const _RowDivider(),
      ],
    );
  }

  void _showMenu(BuildContext context) {
    final pt = context.pt;
    showModalBottomSheet(
      context: context,
      backgroundColor: pt.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: pt.border,
                borderRadius: PayPactRadius.full,
              ),
            ),
            const SizedBox(height: 20),
            _BottomSheetAction(
              icon: Icons.person_remove_outlined,
              label: 'Remove $name',
              color: pt.negative,
              onTap: () {
                Navigator.pop(context);
                onRemove?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMembersRow extends StatelessWidget {
  const _AddMembersRow({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: pt.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded, color: pt.accent, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Add members',
                style: PayPactTypography.bodyMd
                    .copyWith(color: pt.accent, fontWeight: FontWeight.w600)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: pt.ink3, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Invite section ────────────────────────────────────────────────────────────

class _InviteSection extends StatelessWidget {
  const _InviteSection({required this.groupId, required this.groupName});
  final String groupId;
  final String groupName;

  String get _link =>
      'paypact.link/${groupName.toLowerCase().replaceAll(' ', '-')}';

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('INVITE',
            style: PayPactTypography.label
                .copyWith(color: pt.ink3, letterSpacing: 1.5)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: pt.surface,
            borderRadius: PayPactRadius.lg,
            border: Border.all(color: pt.border),
            boxShadow: pt.shadowSm,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: pt.surfaceAlt,
                  borderRadius: PayPactRadius.md,
                ),
                child: Icon(Icons.qr_code_rounded,
                    color: pt.ink2, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_link,
                        style: PayPactTypography.bodyMd.copyWith(
                            color: pt.ink, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('Anyone with the link can request to join',
                        style: PayPactTypography.bodySm
                            .copyWith(color: pt.ink3)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _link));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: pt.accentSoft,
                    borderRadius: PayPactRadius.full,
                    border: Border.all(
                        color: pt.accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.ios_share_rounded,
                          size: 14, color: pt.accent),
                      const SizedBox(width: 5),
                      Text('Share',
                          style: PayPactTypography.bodySm.copyWith(
                              color: pt.accent,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Preferences section ───────────────────────────────────────────────────────

class _PreferencesSection extends StatelessWidget {
  const _PreferencesSection({
    required this.group,
    required this.isAdmin,
    required this.onDelete,
    required this.onLeave,
  });
  final GroupEntity group;
  final bool isAdmin;
  final VoidCallback onDelete;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PREFERENCES',
            style: PayPactTypography.label
                .copyWith(color: pt.ink3, letterSpacing: 1.5)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: pt.surface,
            borderRadius: PayPactRadius.lg,
            border: Border.all(color: pt.border),
            boxShadow: pt.shadowSm,
          ),
          child: Column(
            children: [
              _PrefRow(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                trailing: Switch(
                  value: true,
                  onChanged: (_) {},
                  activeThumbColor: pt.accent,
                  activeTrackColor: pt.accentSoft,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                showDivider: true,
              ),
              _PrefRow(
                icon: Icons.currency_rupee_rounded,
                label: 'Currency',
                trailing: Text(group.currency,
                    style: PayPactTypography.bodySm
                        .copyWith(color: pt.ink3)),
                showDivider: isAdmin,
              ),
              if (isAdmin)
                _PrefRow(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete group',
                  color: pt.negative,
                  onTap: onDelete,
                  showDivider: false,
                )
              else
                _PrefRow(
                  icon: Icons.logout_rounded,
                  label: 'Leave group',
                  color: pt.negative,
                  onTap: onLeave,
                  showDivider: false,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrefRow extends StatelessWidget {
  const _PrefRow({
    required this.icon,
    required this.label,
    required this.showDivider,
    this.trailing,
    this.color,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final Widget? trailing;
  final Color? color;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final fg = color ?? pt.ink;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: PayPactRadius.lg,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color ?? pt.ink2),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label,
                      style: PayPactTypography.bodyMd
                          .copyWith(color: fg, fontWeight: FontWeight.w500)),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
        if (showDivider) const _RowDivider(),
      ],
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _RowDivider extends StatelessWidget {
  const _RowDivider();
  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        indent: 16,
        endIndent: 0,
        color: context.pt.border,
      );
}

class _BottomSheetAction extends StatelessWidget {
  const _BottomSheetAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label,
          style:
              PayPactTypography.bodyMd.copyWith(color: color)),
      onTap: onTap,
    );
  }
}

enum _BadgeTone { accent }

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.tone});
  final String label;
  final _BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final bg = pt.accentSoft;
    final fg = pt.accentInk;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: PayPactRadius.sm,
      ),
      child: Text(
        label,
        style: PayPactTypography.micro.copyWith(
            color: fg,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _catLabel(String cat) {
  const m = {
    'trip': 'Trip',
    'home': 'Home',
    'couple': 'Couple',
    'friends': 'Friends',
    'work': 'Work',
    'other': 'Other',
  };
  return m[cat] ?? 'Other';
}

String _catEmoji(String cat) {
  const m = {
    'trip': '🏖',
    'home': '🏠',
    'couple': '💑',
    'friends': '🍕',
    'work': '💼',
    'other': '✨',
  };
  return m[cat] ?? '✨';
}
