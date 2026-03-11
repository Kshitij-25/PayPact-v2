import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/core/theme/app_theme.dart';
import 'package:paypact/features/auth/domain/entities/user_entity.dart';
import 'package:paypact/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:paypact/features/group/presentation/bloc/group_bloc.dart';

/// Shown when the app is opened via the invite deep link:
///   https://paypact-fec8e.web.app/invite/<code>
///   paypact://invite/<code>
///
/// If the user is already signed in it auto-dispatches the join request.
/// If not signed in it shows a prompt — GoRouter's redirect will have already
/// sent them to sign-in, so this screen is a fallback / manual trigger.
class InviteJoinScreen extends StatefulWidget {
  const InviteJoinScreen({super.key, required this.inviteCode});

  final String inviteCode;

  @override
  State<InviteJoinScreen> createState() => _InviteJoinScreenState();
}

class _InviteJoinScreenState extends State<InviteJoinScreen> {
  _Phase _phase = _Phase.idle;
  StreamSubscription<GroupState>? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryAutoJoin());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _tryAutoJoin() {
    final user = context.read<AuthBloc>().state.user;
    if (user != null) _startJoin(user);
  }

  void _startJoin(UserEntity user) {
    setState(() => _phase = _Phase.joining);
    context.read<GroupBloc>().add(
          GroupJoinRequested(
            inviteCode: widget.inviteCode,
            user: user,
          ),
        );
    _sub = context.read<GroupBloc>().stream.listen(_onGroupState);
  }

  void _onGroupState(GroupState state) {
    if (state.status == GroupStatus.success) {
      _sub?.cancel();
      if (mounted) {
        setState(() => _phase = _Phase.success);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 You joined the group!'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) context.go('/');
        });
      }
    } else if (state.status == GroupStatus.failure) {
      _sub?.cancel();
      if (mounted) setState(() => _phase = _Phase.error(state.errorMessage));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              // ── Top back button ────────────────────────────────────────────
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/'),
                ),
              ),

              const Spacer(),

              // ── Icon ────────────────────────────────────────────────────────
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.4)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.group_add_rounded,
                    size: 44, color: Colors.white),
              ),
              const SizedBox(height: 28),

              // ── Title ───────────────────────────────────────────────────────
              const Text(
                "You've been invited!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Join this Paypact group to start splitting expenses together.',
                style:
                    TextStyle(fontSize: 14, color: PaypactColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // ── Invite code pill ────────────────────────────────────────────
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: widget.inviteCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invite code copied')),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.07),
                    border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.inviteCode,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.copy_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // ── Status / action area ────────────────────────────────────────
              _buildAction(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAction() {
    switch (_phase) {
      case _Phase.idle:
        final user = context.read<AuthBloc>().state.user;
        if (user == null) {
          return Column(children: [
            Text(
              'Sign in to join this group',
              style: TextStyle(color: PaypactColors.textSecondary),
            ),
            const SizedBox(height: 12),
            _JoinButton(
              label: 'Sign in & Join',
              onTap: () => context.go('/sign-in'),
            ),
          ]);
        }
        return _JoinButton(
          label: 'Join Group',
          onTap: () => _startJoin(user),
        );

      case _Phase.joining:
        return Column(children: [
          CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text('Joining group…',
              style: TextStyle(color: PaypactColors.textSecondary)),
        ]);

      case _Phase.success:
        return Column(children: [
          Icon(Icons.check_circle_rounded,
              color: Theme.of(context).colorScheme.secondary, size: 48),
          const SizedBox(height: 12),
          const Text('Joined! Taking you home…',
              style: TextStyle(color: PaypactColors.textSecondary)),
        ]);

      case _Phase.error:
        return Column(children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.error.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              (_phase as _ErrorPhase).message ??
                  'Could not join the group. The invite may be invalid or expired.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          _JoinButton(
            label: 'Try Again',
            onTap: () {
              final user = context.read<AuthBloc>().state.user;
              if (user != null) {
                setState(() => _phase = _Phase.idle);
                _startJoin(user);
              }
            },
          ),
        ]);
      case _IdlePhase():
        throw UnimplementedError();
      case _JoiningPhase():
        throw UnimplementedError();
      case _SuccessPhase():
        throw UnimplementedError();
      case _ErrorPhase():
        throw UnimplementedError();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _JoinButton extends StatelessWidget {
  const _JoinButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: Text(label,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      );
}

// ── Simple sealed-class-style state ──────────────────────────────────────────

sealed class _Phase {
  const _Phase();
  static const idle = _IdlePhase();
  static const joining = _JoiningPhase();
  static const success = _SuccessPhase();
  static _ErrorPhase error(String? msg) => _ErrorPhase(msg);
}

class _IdlePhase extends _Phase {
  const _IdlePhase();
}

class _JoiningPhase extends _Phase {
  const _JoiningPhase();
}

class _SuccessPhase extends _Phase {
  const _SuccessPhase();
}

class _ErrorPhase extends _Phase {
  const _ErrorPhase(this.message);
  final String? message;
}
