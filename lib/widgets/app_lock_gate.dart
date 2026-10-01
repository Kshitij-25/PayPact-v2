import 'package:paypact/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:paypact/core/services/app_lock_service.dart';
import 'package:paypact/design_system/components/paypact_button.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/typography.dart';

/// Covers the app with an unlock screen when App Lock is on: at launch, and
/// when the app comes back after being away longer than the grace period.
class AppLockGate extends StatefulWidget {
  const AppLockGate({
    super.key,
    required this.service,
    required this.child,
    this.clock,
  });
  final AppLockService service;
  final Widget child;

  /// Injectable clock (tests).
  final DateTime Function()? clock;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  late bool _locked = widget.service.enabled;
  DateTime? _leftAt;
  bool _prompting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_locked) WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // The system's own Face ID sheet also backgrounds the app briefly; don't
      // restart the clock while we're the ones prompting.
      if (!_prompting) _leftAt ??= _now();
    } else if (state == AppLifecycleState.resumed) {
      final left = _leftAt;
      _leftAt = null;
      if (left != null &&
          !_locked &&
          widget.service.shouldLockAfter(_now().difference(left))) {
        setState(() => _locked = true);
        _unlock();
      }
    }
  }

  DateTime _now() => (widget.clock ?? DateTime.now)();

  Future<void> _unlock() async {
    if (_prompting) return;
    _prompting = true;
    final ok = await widget.service.authenticate();
    _prompting = false;
    if (ok && mounted) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_locked)
          Positioned.fill(child: _LockScreen(onUnlock: _unlock)),
      ],
    );
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({required this.onUnlock});
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Material(
      color: pt.bg,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded, size: 48, color: pt.accent),
                const SizedBox(height: 18),
                Text(context.l10n.lockTitle,
                    style: PayPactTypography.headingMd.copyWith(color: pt.ink)),
                const SizedBox(height: 6),
                Text(context.l10n.lockBody,
                    textAlign: TextAlign.center,
                    style: PayPactTypography.bodyMd.copyWith(color: pt.ink3)),
                const SizedBox(height: 24),
                PayPactButton(
                  onPressed: onUnlock,
                  label: context.l10n.unlock,
                  variant: PayPactButtonVariant.accent,
                  size: PayPactButtonSize.large,
                  leftIcon: Icons.lock_open_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
