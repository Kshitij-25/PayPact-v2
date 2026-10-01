import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/core/utils/invite_code.dart';
import 'package:paypact/design_system/components/paypact_button.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/group/data/invite_service.dart';
import 'package:paypact/features/group/presentation/cubit/join_group_cubit.dart';
import 'package:paypact/widgets/pp_atoms.dart';

/// Landing screen for `/join/:code` and `/invite/:code` (web links, app links
/// and `paypact://invite/:code`). Shows what the user is joining and confirms.
class JoinGroupScreen extends StatelessWidget {
  const JoinGroupScreen({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final normalized = normalizeInviteCode(code);
    if (normalized == null) {
      return const _Shell(
        child: _Message(
          icon: Icons.link_off_rounded,
          title: 'Invalid invite link',
          body: "That doesn't look like a valid PayPact invite.",
        ),
      );
    }
    return BlocProvider(
      create: (_) => JoinGroupCubit(locator<InviteService>(), normalized)..load(),
      child: const _JoinBody(),
    );
  }
}

class _JoinBody extends StatelessWidget {
  const _JoinBody();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JoinGroupCubit, JoinGroupState>(
      listener: (context, state) {
        if (state is JoinGroupJoined) {
          if (!state.result.alreadyMember) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('You joined "${state.result.name}"')));
          }
          context.go('/group/${state.result.groupId}');
        }
      },
      builder: (context, state) => _Shell(
        child: switch (state) {
          JoinGroupLoading() || JoinGroupJoined() =>
            const CircularProgressIndicator(),
          JoinGroupReady(:final preview) => _Preview(preview: preview),
          JoinGroupJoining(:final preview) =>
            _Preview(preview: preview, busy: true),
          JoinGroupFailed(:final message) => _Message(
              icon: Icons.link_off_rounded,
              title: "Can't join this group",
              body: message,
              action: PayPactButton(
                onPressed: () => context.go(AppRoutes.home),
                label: 'Go to home',
                variant: PayPactButtonVariant.secondary,
                size: PayPactButtonSize.large,
                isFullWidth: true,
              ),
            ),
        },
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.preview, this.busy = false});
  final InvitePreview preview;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final n = preview.memberCount;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(preview.emoji, style: const TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        Text(preview.alreadyMember ? "You're already in" : "You're invited to",
            style: PayPactTypography.bodyMd.copyWith(color: pt.ink3)),
        const SizedBox(height: 6),
        Text(preview.name,
            textAlign: TextAlign.center,
            style: PayPactTypography.displayLg.copyWith(color: pt.ink)),
        if (n > 0) ...[
          const SizedBox(height: 8),
          Text('$n member${n == 1 ? '' : 's'}',
              style: PayPactTypography.bodyMd.copyWith(color: pt.ink2)),
        ],
        const SizedBox(height: 28),
        PayPactButton(
          onPressed: busy
              ? null
              : () => preview.alreadyMember
                  ? context.go(AppRoutes.home)
                  : context.read<JoinGroupCubit>().join(),
          label: busy
              ? 'Joining…'
              : preview.alreadyMember
                  ? 'Open PayPact'
                  : 'Join group',
          variant: PayPactButtonVariant.accent,
          size: PayPactButtonSize.large,
          isFullWidth: true,
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: busy ? null : () => context.go(AppRoutes.home),
          child: Text('Not now',
              style: PayPactTypography.bodyMd.copyWith(color: pt.ink3)),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(
      {required this.icon,
      required this.title,
      required this.body,
      this.action});
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 40, color: pt.ink3),
        const SizedBox(height: 16),
        Text(title,
            textAlign: TextAlign.center,
            style: PayPactTypography.headingMd.copyWith(color: pt.ink)),
        const SizedBox(height: 8),
        Text(body,
            textAlign: TextAlign.center,
            style: PayPactTypography.bodyMd.copyWith(color: pt.ink2)),
        if (action != null) ...[const SizedBox(height: 24), action!],
      ],
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Scaffold(
      backgroundColor: pt.bg,
      body: Stack(
        children: [
          const PpBackdropGlow(intensity: 0.12),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: pt.surface,
                      borderRadius: PayPactRadius.lg,
                      border: Border.all(color: pt.border),
                      boxShadow: pt.shadowSm,
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
