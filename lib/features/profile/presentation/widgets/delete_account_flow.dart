import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/core/utils/currency_utils.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/features/auth/data/account_service.dart';

String _money(AccountDeletionBlocker b) {
  final v = b.netMinor.abs() / 100;
  return '${currencySymbol(b.currency)}${v.truncateToDouble() == v ? v.toStringAsFixed(0) : v.toStringAsFixed(2)}';
}

/// Walks the user through deleting their account:
/// confirm (type DELETE) → re-authenticate → delete → explain any blockers.
Future<void> runDeleteAccountFlow(BuildContext context) async {
  final accounts = locator<AccountService>();
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);

  // 1. Make sure they mean it.
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => const _ConfirmDeleteDialog(),
  );
  if (confirmed != true || !context.mounted) return;

  // 2. Re-authenticate (deleting an account needs a recent sign-in).
  try {
    if (accounts.usesPassword) {
      final password = await showDialog<String>(
        context: context,
        builder: (_) => const _PasswordDialog(),
      );
      if (password == null || !context.mounted) return;
      await accounts.reauthenticateWithPassword(password);
    } else {
      await accounts.reauthenticateWithProvider();
    }
  } catch (e) {
    final wrong = e.toString().contains('wrong-password') ||
        e.toString().contains('invalid-credential');
    messenger.showSnackBar(SnackBar(
        content: Text(wrong
            ? 'That password is incorrect.'
            : "Couldn't confirm it's you, so nothing was deleted.")));
    return;
  }
  if (!context.mounted) return;

  // 3. Delete, with a blocking progress dialog.
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(children: [
          SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5)),
          SizedBox(width: 16),
          Expanded(child: Text('Deleting your account…')),
        ]),
      ),
    ),
  );
  try {
    await accounts.deleteAccount();
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    messenger.showSnackBar(
        const SnackBar(content: Text('Your account has been deleted.')));
    router.go(AppRoutes.signIn);
  } on AccountDeletionBlocked catch (blocked) {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    if (context.mounted) await _showBlockers(context, blocked.blockers);
  } on RecentLoginRequired {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    messenger.showSnackBar(const SnackBar(
        content: Text('Please try again — we need a fresh sign-in first.')));
  } catch (_) {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    messenger.showSnackBar(const SnackBar(
        content: Text("Couldn't delete your account. Nothing was changed — try again.")));
  }
}

Future<void> _showBlockers(
    BuildContext context, List<AccountDeletionBlocker> blockers) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Settle up first'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              "You can't delete your account while money is outstanding — the people in those groups would be left with unbalanced books. Settle these, then try again:"),
          const SizedBox(height: 12),
          for (final b in blockers)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                  '• ${b.groupName}: ${b.netMinor > 0 ? "you're owed" : 'you owe'} ${_money(b)}'),
            ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
      ],
    ),
  );
}

class _ConfirmDeleteDialog extends StatefulWidget {
  const _ConfirmDeleteDialog();
  @override
  State<_ConfirmDeleteDialog> createState() => _ConfirmDeleteDialogState();
}

class _ConfirmDeleteDialogState extends State<_ConfirmDeleteDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final ready = _ctrl.text.trim().toUpperCase() == 'DELETE';
    return AlertDialog(
      title: const Text('Delete your account?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'This permanently deletes your profile, photo and notifications, '
                'and removes you from all your groups. Groups where you are the only '
                'member are deleted. Expenses you added to shared groups stay with '
                'those groups. This cannot be undone.'),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Type DELETE to confirm'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        TextButton(
          onPressed: ready ? () => Navigator.pop(context, true) : null,
          child: Text('Delete account',
              style: TextStyle(color: ready ? pt.negative : null)),
        ),
      ],
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();
  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _ctrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm your password'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        obscureText: _obscure,
        onSubmitted: (v) => Navigator.pop(context, v),
        decoration: InputDecoration(
          labelText: 'Password',
          suffixIcon: IconButton(
            tooltip: _obscure ? 'Show password' : 'Hide password',
            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
            onPressed: () => Navigator.pop(context, _ctrl.text),
            child: const Text('Continue')),
      ],
    );
  }
}
