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
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/features/group/presentation/cubit/add_members_cubit.dart';
import 'package:paypact/widgets/pp_atoms.dart';

class AddMembersScreen extends StatefulWidget {
  final String? groupId;
  const AddMembersScreen({super.key, this.groupId});

  @override
  State<AddMembersScreen> createState() => _AddMembersScreenState();
}

class _AddMembersScreenState extends State<AddMembersScreen> {
  final _searchCtrl = TextEditingController();
  final Set<String> _selectedIds = {};
  final Map<String, UserResult> _selectedUsers = {};
  GroupEntity? _group;

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  Future<void> _loadGroup() async {
    if (widget.groupId == null) return;
    final group =
        await locator<GroupRepository>().getGroup(widget.groupId!);
    if (mounted) setState(() => _group = group);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Set<String> get _existingIds =>
      Set<String>.from(_group?.memberIds ?? []);

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
      ),
      child: Builder(builder: (ctx) {
        return BlocListener<AddMembersCubit, AddMembersState>(
          listener: (context, state) {
            if (state is AddMembersDone) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Members added!')),
              );
              context.pop();
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
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 10, 20, 14),
                        child: Row(children: [
                          PpGlassIconButton(
                            icon: Icons.arrow_back_rounded,
                            onTap: () => context.pop(),
                          ),
                          const Spacer(),
                          Text('Add members',
                              style: PayPactTypography.bodyMd.copyWith(
                                  color: pt.ink,
                                  fontWeight: FontWeight.w600)),
                          const Spacer(),
                          if (_group != null)
                            Text('${_group!.memberIds.length} members',
                                style: PayPactTypography.bodyMd
                                    .copyWith(color: pt.ink3)),
                        ]),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(
                              PayPactSpacing.s6, 4, PayPactSpacing.s6, 160),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_group != null) ...[
                                Text(_group!.name.toUpperCase(),
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
                              Container(
                                height: 52,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14),
                                decoration: BoxDecoration(
                                  color: pt.surface,
                                  borderRadius: PayPactRadius.md,
                                  border: Border.all(color: pt.border),
                                  boxShadow: pt.shadowSm,
                                ),
                                child: Row(children: [
                                  Icon(Icons.search_rounded,
                                      color: pt.ink3, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchCtrl,
                                      style: PayPactTypography.bodyMd
                                          .copyWith(color: pt.ink),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText:
                                            'Search by name or email…',
                                        hintStyle:
                                            PayPactTypography.bodyMd
                                                .copyWith(color: pt.ink3),
                                      ),
                                      onChanged: (v) => ctx
                                          .read<AddMembersCubit>()
                                          .search(v,
                                              existingMemberIds:
                                                  _existingIds),
                                    ),
                                  ),
                                ]),
                              ),
                              const SizedBox(height: 16),

                              // Search results
                              BlocBuilder<AddMembersCubit,
                                  AddMembersState>(
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
                                  if (_searchCtrl.text.isNotEmpty &&
                                      results.isEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 24),
                                      child: Center(
                                        child: Text(
                                            'No users found. Try their exact email.',
                                            style:
                                                PayPactTypography.bodyMd
                                                    .copyWith(
                                                        color: pt.ink3)),
                                      ),
                                    );
                                  }
                                  if (results.isEmpty) {
                                    return const SizedBox.shrink();
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
                                                color: pt.border, height: 1),
                                          _UserRow(
                                            user: results[i],
                                            selected: _selectedIds.contains(
                                                results[i].id),
                                            isMe: results[i].id ==
                                                currentUserId,
                                            onToggle: () => setState(() {
                                              final u = results[i];
                                              if (_selectedIds
                                                  .contains(u.id)) {
                                                _selectedIds.remove(u.id);
                                                _selectedUsers.remove(u.id);
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
                                  context
                                      .read<AddMembersCubit>()
                                      .addMembers(
                                        widget.groupId!,
                                        _selectedUsers.values.toList(),
                                      );
                                },
                          label: loading
                              ? 'Adding…'
                              : _selectedIds.isEmpty
                                  ? 'Select members to add'
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
