import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/design_system/components/paypact_button.dart';
import 'package:paypact/design_system/components/paypact_card.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/spacing.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/features/group/presentation/cubit/add_members_cubit.dart';
import 'package:paypact/widgets/pp_atoms.dart';

class AddMembersScreen extends StatefulWidget {
  final String? groupId;
  final bool fromCreate;
  const AddMembersScreen({super.key, this.groupId, this.fromCreate = false});

  @override
  State<AddMembersScreen> createState() => _AddMembersScreenState();
}

class _AddMembersScreenState extends State<AddMembersScreen> {
  final _searchCtrl = TextEditingController();
  final Set<String> _selectedIds = {};
  final Map<String, UserResult> _selectedUsers = {};
  String? _groupName;
  List<_CircleUser> _circleUsers = [];

  @override
  void initState() {
    super.initState();
    _loadGroupAndCircle();
  }

  Future<void> _loadGroupAndCircle() async {
    final authState = locator<AuthCubit>().state;
    final currentUserId =
        authState is AuthAuthenticated ? authState.user.id : null;
    if (currentUserId == null) return;

    if (widget.groupId != null) {
      final group =
          await locator<GroupRepository>().getGroup(widget.groupId!);
      if (mounted) setState(() => _groupName = group?.name);
    }

    // Build circle from existing groups (no extra Firestore calls — memberNames already has names)
    final groups = await locator<GroupRepository>()
        .watchUserGroups(currentUserId)
        .first;

    final seen = <String>{currentUserId};
    final sharedGroupCount = <String, int>{};
    for (final g in groups) {
      for (final id in g.memberIds) {
        if (!seen.contains(id)) {
          sharedGroupCount[id] = (sharedGroupCount[id] ?? 0) + 1;
        } else if (id != currentUserId) {
          sharedGroupCount[id] = (sharedGroupCount[id] ?? 0) + 1;
        }
      }
      seen.addAll(g.memberIds);
    }

    final circle = <_CircleUser>[];
    for (final g in groups) {
      for (final entry in g.memberNames.entries) {
        if (entry.key == currentUserId) continue;
        if (circle.any((c) => c.id == entry.key)) continue;
        circle.add(_CircleUser(
          id: entry.key,
          name: entry.value,
          sharedGroups: sharedGroupCount[entry.key] ?? 1,
        ));
      }
    }
    // Sort by most shared groups first
    circle.sort((a, b) => b.sharedGroups.compareTo(a.sharedGroups));

    if (mounted) setState(() => _circleUsers = circle);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Set<String> get _existingIds => <String>{};

  void _goToGroup() {
    if (widget.groupId != null) {
      context.go('/group/${widget.groupId}');
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final authState = context.watch<AuthCubit>().state;
    final currentUserId =
        authState is AuthAuthenticated ? authState.user.id : null;

    return BlocProvider(
      create: (_) => AddMembersCubit(
        locator<GroupRepository>(),
        locator(),
        locator(),
      ),
      child: Builder(builder: (ctx) {
        return BlocListener<AddMembersCubit, AddMembersState>(
          listener: (context, state) {
            if (state is AddMembersDone) {
              if (widget.fromCreate) {
                _goToGroup();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Members added!')),
                );
                context.pop();
              }
            } else if (state is AddMembersError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          child: Scaffold(
            backgroundColor: pt.bg,
            body: Stack(
              children: [
                const PpBackdropGlow(intensity: 0.08),
                SafeArea(
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 10, 20, 14),
                        child: Row(children: [
                          PpGlassIconButton(
                            icon: Icons.arrow_back_rounded,
                            onTap: () => widget.fromCreate
                                ? _goToGroup()
                                : context.pop(),
                          ),
                          const Spacer(),
                          Column(
                            children: [
                              Text('Add members',
                                  style: PayPactTypography.bodyMd.copyWith(
                                      color: pt.ink,
                                      fontWeight: FontWeight.w600)),
                              if (widget.fromCreate) ...[
                                const SizedBox(height: 3),
                                Text('STEP 2 OF 2',
                                    style: PayPactTypography.label.copyWith(
                                        color: pt.ink3,
                                        letterSpacing: 1.4,
                                        fontSize: 10)),
                              ],
                            ],
                          ),
                          const Spacer(),
                          if (widget.fromCreate)
                            GestureDetector(
                              onTap: _goToGroup,
                              child: Text('Skip',
                                  style: PayPactTypography.bodyMd
                                      .copyWith(color: pt.ink3)),
                            )
                          else
                            const SizedBox(width: 40),
                        ]),
                      ),

                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(
                              PayPactSpacing.s6, 4, PayPactSpacing.s6, 160),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_groupName != null) ...[
                                Text(_groupName!.toUpperCase(),
                                    style: PayPactTypography.label.copyWith(
                                        color: pt.accent,
                                        letterSpacing: 1.6)),
                                const SizedBox(height: 14),
                              ],
                              Text("Who's in?",
                                  style: PayPactTypography.displayLg
                                      .copyWith(color: pt.ink)),
                              const SizedBox(height: 8),
                              Text(
                                  'Search by name or email to add people to this group.',
                                  style: PayPactTypography.bodyLg
                                      .copyWith(color: pt.ink2)),
                              const SizedBox(height: 22),

                              // Selected chips
                              if (_selectedUsers.isNotEmpty) ...[
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      for (final u
                                          in _selectedUsers.values) ...[
                                        _SelectedChip(
                                          name: u.name,
                                          onRemove: () => setState(() {
                                            _selectedIds.remove(u.id);
                                            _selectedUsers.remove(u.id);
                                          }),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Search field
                              TextField(
                                controller: _searchCtrl,
                                style: PayPactTypography.bodyMd
                                    .copyWith(color: pt.ink),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.search_rounded,
                                      color: pt.ink3, size: 18),
                                  hintText: 'Search by name or email…',
                                  hintStyle: PayPactTypography.bodyMd
                                      .copyWith(color: pt.ink3),
                                  filled: true,
                                  fillColor: pt.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: PayPactRadius.md,
                                    borderSide:
                                        BorderSide(color: pt.borderStrong),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: PayPactRadius.md,
                                    borderSide:
                                        BorderSide(color: pt.borderStrong),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: PayPactRadius.md,
                                    borderSide: BorderSide(
                                        color: pt.accent, width: 1.4),
                                  ),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 14),
                                ),
                                onChanged: (v) => ctx
                                    .read<AddMembersCubit>()
                                    .search(v,
                                        existingMemberIds: _existingIds),
                              ),
                              const SizedBox(height: 16),

                              // Search results
                              BlocBuilder<AddMembersCubit, AddMembersState>(
                                builder: (context, state) {
                                  if (state is AddMembersSearching) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 24),
                                      child: Center(
                                          child:
                                              CircularProgressIndicator()),
                                    );
                                  }
                                  final results = switch (state) {
                                    AddMembersSearchDone s => s.results,
                                    _ => <UserResult>[],
                                  };

                                  if (_searchCtrl.text.isNotEmpty) {
                                    if (results.isEmpty) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 24),
                                        child: Center(
                                          child: Text(
                                              'No users found. Try their exact email.',
                                              style: PayPactTypography
                                                  .bodyMd
                                                  .copyWith(
                                                      color: pt.ink3)),
                                        ),
                                      );
                                    }
                                    return PayPactCard(
                                      padding: EdgeInsets.zero,
                                      child: Column(
                                        children: [
                                          for (int i = 0;
                                              i < results.length;
                                              i++) ...[
                                            if (i > 0)
                                              Divider(
                                                  color: pt.border,
                                                  height: 1),
                                            _UserRow(
                                              user: results[i],
                                              selected:
                                                  _selectedIds.contains(
                                                      results[i].id),
                                              isMe: results[i].id ==
                                                  currentUserId,
                                              onToggle: () =>
                                                  setState(() {
                                                final u = results[i];
                                                if (_selectedIds
                                                    .contains(u.id)) {
                                                  _selectedIds.remove(u.id);
                                                  _selectedUsers
                                                      .remove(u.id);
                                                } else {
                                                  _selectedIds.add(u.id);
                                                  _selectedUsers[u.id] = u;
                                                }
                                              }),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  }

                                  // Circle section when not searching
                                  if (_circleUsers.isEmpty) {
                                    return const SizedBox.shrink();
                                  }

                                  final circleFiltered = _circleUsers
                                      .where((c) =>
                                          !_selectedIds.contains(c.id))
                                      .toList();

                                  if (circleFiltered.isEmpty) {
                                    return const SizedBox.shrink();
                                  }

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('FROM YOUR CIRCLE',
                                          style: PayPactTypography.label
                                              .copyWith(
                                                  color: pt.ink3,
                                                  letterSpacing: 1.5)),
                                      const SizedBox(height: 10),
                                      PayPactCard(
                                        padding: EdgeInsets.zero,
                                        child: Column(
                                          children: [
                                            for (int i = 0;
                                                i < circleFiltered.length;
                                                i++) ...[
                                              if (i > 0)
                                                Divider(
                                                    color: pt.border,
                                                    height: 1),
                                              _CircleRow(
                                                user: circleFiltered[i],
                                                selected: _selectedIds
                                                    .contains(
                                                        circleFiltered[i].id),
                                                onToggle: () =>
                                                    setState(() {
                                                  final u =
                                                      circleFiltered[i];
                                                  if (_selectedIds
                                                      .contains(u.id)) {
                                                    _selectedIds.remove(u.id);
                                                    _selectedUsers
                                                        .remove(u.id);
                                                  } else {
                                                    _selectedIds.add(u.id);
                                                    _selectedUsers[u.id] =
                                                        UserResult(
                                                            id: u.id,
                                                            name: u.name,
                                                            email: '');
                                                  }
                                                }),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Sticky CTA
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.fromLTRB(24, 14, 24, 32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [pt.bg, pt.bg.withValues(alpha: 0)],
                        stops: const [0.7, 1.0],
                      ),
                    ),
                    child: BlocBuilder<AddMembersCubit, AddMembersState>(
                      builder: (context, state) {
                        final loading = state is AddMembersAdding;
                        return PayPactButton(
                          onPressed: _selectedIds.isEmpty || loading
                              ? null
                              : () {
                                  if (widget.groupId == null) {
                                    context.pop();
                                    return;
                                  }
                                  final auth =
                                      context.read<AuthCubit>().state;
                                  final actorId = auth is AuthAuthenticated
                                      ? auth.user.id
                                      : '';
                                  final actorName =
                                      auth is AuthAuthenticated
                                          ? auth.user.name
                                          : '';
                                  context
                                      .read<AddMembersCubit>()
                                      .addMembers(
                                        widget.groupId!,
                                        _selectedUsers.values.toList(),
                                        actorId: actorId,
                                        actorName: actorName,
                                        groupName: _groupName,
                                      );
                                },
                          label: loading
                              ? 'Adding…'
                              : _selectedIds.isEmpty
                                  ? widget.fromCreate
                                      ? 'Select members to add'
                                      : 'Select members to add'
                                  : widget.fromCreate
                                      ? 'Add ${_selectedIds.length} member${_selectedIds.length == 1 ? '' : 's'} & open group'
                                      : 'Add ${_selectedIds.length} member${_selectedIds.length == 1 ? '' : 's'}',
                          variant: PayPactButtonVariant.accent,
                          size: PayPactButtonSize.large,
                          isFullWidth: true,
                          leftIcon: loading ? null : Icons.check_rounded,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _CircleUser {
  final String id;
  final String name;
  final int sharedGroups;
  const _CircleUser(
      {required this.id, required this.name, required this.sharedGroups});
}

class _SelectedChip extends StatelessWidget {
  const _SelectedChip({required this.name, required this.onRemove});
  final String name;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: pt.surface,
        borderRadius: PayPactRadius.full,
        border: Border.all(color: pt.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        PpAvatar(name: name, size: 22),
        const SizedBox(width: 7),
        Text(name.split(' ').first,
            style: PayPactTypography.bodyMd.copyWith(
                color: pt.ink, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(width: 6),
        GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 14, color: pt.ink3)),
      ]),
    );
  }
}

class _CircleRow extends StatelessWidget {
  const _CircleRow({
    required this.user,
    required this.selected,
    required this.onToggle,
  });
  final _CircleUser user;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          PpAvatar(name: user.name, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(user.name,
                      style: PayPactTypography.bodyMd.copyWith(
                          color: pt.ink, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  _Badge(label: 'RECENT', color: pt.accent),
                ]),
                const SizedBox(height: 2),
                Text(
                    'In ${user.sharedGroups} group${user.sharedGroups == 1 ? '' : 's'} with you',
                    style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: selected ? pt.accent : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? pt.accent : pt.border,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              selected ? Icons.check_rounded : Icons.add_rounded,
              color: selected ? Colors.white : pt.ink3,
              size: 16,
            ),
          ),
        ]),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: PayPactTypography.label.copyWith(
              color: color, fontSize: 9, letterSpacing: 0.8)),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.selected,
    required this.isMe,
    required this.onToggle,
  });
  final UserResult user;
  final bool selected;
  final bool isMe;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return InkWell(
      onTap: isMe ? null : onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          PpAvatar(name: user.name, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: PayPactTypography.bodyMd.copyWith(
                        color: pt.ink, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(user.email,
                    style:
                        PayPactTypography.bodySm.copyWith(color: pt.ink3)),
              ],
            ),
          ),
          if (!isMe)
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected ? pt.accent : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? pt.accent : pt.border,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                selected ? Icons.check_rounded : Icons.add_rounded,
                color: selected ? Colors.white : pt.ink3,
                size: 16,
              ),
            )
          else
            Text('You',
                style:
                    PayPactTypography.bodySm.copyWith(color: pt.ink3)),
        ]),
      ),
    );
  }
}
