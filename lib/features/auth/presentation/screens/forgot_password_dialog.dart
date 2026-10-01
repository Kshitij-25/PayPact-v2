import 'package:flutter/material.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/design_system/components/paypact_button.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';

/// Asks for an email (prefilled with whatever is already typed on the sign-in
/// form) and sends a password-reset link.
Future<void> showForgotPasswordDialog(
  BuildContext context, {
  String initialEmail = '',
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ForgotPasswordDialog(initialEmail: initialEmail),
  );
}

class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({required this.initialEmail});
  final String initialEmail;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final _ctrl = TextEditingController(text: widget.initialEmail);
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _ctrl.text.trim();
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final error = await locator<AuthCubit>().sendPasswordReset(email);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _error = error;
      _sent = error == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Dialog(
      backgroundColor: pt.bg,
      shape: RoundedRectangleBorder(
        borderRadius: PayPactRadius.lg,
        side: BorderSide(color: pt.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _sent ? _sentBody(pt) : _formBody(pt),
          ),
        ),
      ),
    );
  }

  List<Widget> _formBody(PayPactThemeExtension pt) => [
        Text('Reset your password',
            style: PayPactTypography.headingMd.copyWith(color: pt.ink)),
        const SizedBox(height: 8),
        Text("Enter your email and we'll send you a link to set a new one.",
            style: PayPactTypography.bodyMd.copyWith(color: pt.ink2)),
        const SizedBox(height: 18),
        TextField(
          controller: _ctrl,
          autofocus: true,
          enabled: !_sending,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _sending ? null : _send(),
          style: PayPactTypography.bodyMd.copyWith(color: pt.ink),
          decoration: InputDecoration(
            hintText: 'you@example.com',
            errorText: _error,
            prefixIcon: Icon(Icons.mail_outline_rounded, color: pt.ink3),
          ),
        ),
        const SizedBox(height: 20),
        PayPactButton(
          onPressed: _sending ? null : _send,
          label: _sending ? 'Sending…' : 'Send reset link',
          variant: PayPactButtonVariant.accent,
          size: PayPactButtonSize.large,
          isFullWidth: true,
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.center,
          child: TextButton(
            onPressed: _sending ? null : () => Navigator.pop(context),
            child: Text('Cancel',
                style: PayPactTypography.bodyMd.copyWith(color: pt.ink3)),
          ),
        ),
      ];

  List<Widget> _sentBody(PayPactThemeExtension pt) => [
        Icon(Icons.mark_email_read_outlined, color: pt.accent, size: 32),
        const SizedBox(height: 14),
        Text('Check your inbox',
            style: PayPactTypography.headingMd.copyWith(color: pt.ink)),
        const SizedBox(height: 8),
        Text(
          "If an account exists for ${_ctrl.text.trim()}, we've sent a link to "
          "reset the password. It may take a minute — check spam too.",
          style: PayPactTypography.bodyMd.copyWith(color: pt.ink2),
        ),
        const SizedBox(height: 20),
        PayPactButton(
          onPressed: () => Navigator.pop(context),
          label: 'Done',
          variant: PayPactButtonVariant.accent,
          size: PayPactButtonSize.large,
          isFullWidth: true,
        ),
      ];
}
