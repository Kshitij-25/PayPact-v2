import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/services/notification_service.dart';
import 'package:paypact/design_system/components/paypact_card.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/spacing.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:paypact/features/notification/domain/entities/notification_entity.dart';
import 'package:paypact/features/notification/domain/repositories/notifications_repository.dart';
import 'package:paypact/features/notification/presentation/cubit/notifications_cubit.dart';
import 'package:paypact/widgets/pp_atoms.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }
    return BlocProvider(
      create: (_) => NotificationsCubit(
        locator<NotificationsRepository>(),
        locator<NotificationService>(),
        authState.user.id,
      )..load(),
      child: const _NotificationsBody(),
    );
  }
}

class _NotificationsBody extends StatelessWidget {
  const _NotificationsBody();

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Scaffold(
      backgroundColor: pt.bg,
      body: Stack(
        children: [
          const PpBackdropGlow(intensity: 0.06),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                  child: Row(children: [
                    PpGlassIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => context.pop()),
                    const Spacer(),
                    Text('Notifications',
                        style: PayPactTypography.bodyMd.copyWith(
                            color: pt.ink, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    BlocBuilder<NotificationsCubit, NotificationsState>(
                      builder: (context, state) {
                        final hasUnread = state is NotificationsLoaded &&
                            state.unread.isNotEmpty;
                        return GestureDetector(
                          onTap: hasUnread
                              ? () =>
                                  context.read<NotificationsCubit>().markAllRead()
                              : null,
                          child: Text('Mark all read',
                              style: PayPactTypography.bodySm.copyWith(
                                  color: hasUnread ? pt.accent : pt.ink4,
                                  fontWeight: FontWeight.w600)),
                        );
                      },
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 14, 28, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('The quiet inbox.',
                          style: PayPactTypography.displayLg
                              .copyWith(color: pt.ink)),
                      const SizedBox(height: 6),
                      Text('We only ping you when it actually matters.',
                          style: PayPactTypography.bodyMd
                              .copyWith(color: pt.ink2)),
                    ],
                  ),
                ),
                Expanded(
                  child: BlocBuilder<NotificationsCubit, NotificationsState>(
                    builder: (context, state) {
                      if (state is NotificationsLoading ||
                          state is NotificationsInitial) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (state is NotificationsError) {
                        return Center(
                          child: Text(state.message,
                              style: PayPactTypography.bodyMd
                                  .copyWith(color: pt.ink3)),
                        );
                      }
                      if (state is NotificationsLoaded) {
                        if (state.notifications.isEmpty) {
                          return _EmptyState();
                        }
                        return _NotifList(state: state);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
                color: pt.surfaceAlt, shape: BoxShape.circle),
            child:
                Icon(Icons.notifications_none_rounded, color: pt.ink3, size: 28),
          ),
          const SizedBox(height: 16),
          Text('All clear',
              style:
                  PayPactTypography.headingMd.copyWith(color: pt.ink)),
          const SizedBox(height: 6),
          Text('No notifications yet.',
              style: PayPactTypography.bodyMd.copyWith(color: pt.ink3)),
        ],
      ),
    );
  }
}

class _NotifList extends StatelessWidget {
  const _NotifList({required this.state});
  final NotificationsLoaded state;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          PayPactSpacing.s6, 0, PayPactSpacing.s6, 120),
      children: [
        if (state.unread.isNotEmpty) ...[
          Text('NEW · ${state.unread.length}',
              style: PayPactTypography.label
                  .copyWith(color: pt.ink3, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          PayPactCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              for (var i = 0; i < state.unread.length; i++) ...[
                if (i > 0) Divider(color: pt.border, height: 1),
                _NotifTile(notif: state.unread[i], isRead: false),
              ],
            ]),
          ),
          const SizedBox(height: 20),
        ],
        if (state.read.isNotEmpty) ...[
          Text('EARLIER',
              style: PayPactTypography.label
                  .copyWith(color: pt.ink3, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          Opacity(
            opacity: 0.8,
            child: PayPactCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (var i = 0; i < state.read.length; i++) ...[
                  if (i > 0) Divider(color: pt.border, height: 1),
                  _NotifTile(notif: state.read[i], isRead: true),
                ],
              ]),
            ),
          ),
        ],
      ],
    );
  }
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.notif, required this.isRead});
  final NotificationEntity notif;
  final bool isRead;

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 7}w ago';
  }

  IconData get _icon => switch (notif.type) {
        'expense_added' => Icons.receipt_long_outlined,
        'expense_deleted' => Icons.delete_outline_rounded,
        'member_added' => Icons.group_add_outlined,
        'member_removed' => Icons.person_remove_outlined,
        'settlement' => Icons.handshake_outlined,
        'group_updated' => Icons.edit_outlined,
        'group_deleted' => Icons.delete_forever_outlined,
        _ => Icons.notifications_none_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return GestureDetector(
      onTap: isRead
          ? null
          : () => context.read<NotificationsCubit>().markRead(notif.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isRead)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 6, right: 4),
                decoration:
                    BoxDecoration(color: pt.accent, shape: BoxShape.circle),
              )
            else
              const SizedBox(width: 10),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: pt.accentSoft, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(_icon, size: 18, color: pt.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notif.title,
                      style: PayPactTypography.bodyMd.copyWith(
                          color: pt.ink, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(notif.body,
                      style: PayPactTypography.bodySm
                          .copyWith(color: pt.ink2, height: 1.5)),
                  const SizedBox(height: 6),
                  Text(_formatTime(notif.createdAt),
                      style:
                          PayPactTypography.bodySm.copyWith(color: pt.ink3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
