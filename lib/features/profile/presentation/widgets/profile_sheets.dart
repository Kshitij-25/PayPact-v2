import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/core/utils/upi.dart';
import 'package:paypact/design_system/components/paypact_button.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/auth/domain/entities/user_entity.dart';
import 'package:paypact/features/profile/cubit/profile_cubit.dart';
import 'package:qr_flutter/qr_flutter.dart';

Widget _sheet(BuildContext context, {required List<Widget> children}) {
  final pt = context.pt;
  return Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      decoration: BoxDecoration(
        color: pt.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    ),
  );
}

/// Where friends should send money: the user's UPI ID.
Future<void> showPaymentMethodsSheet(BuildContext context, UserEntity user) {
  final cubit = context.read<ProfileCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _PaymentMethodsSheet(user: user),
    ),
  );
}

class _PaymentMethodsSheet extends StatefulWidget {
  const _PaymentMethodsSheet({required this.user});
  final UserEntity user;

  @override
  State<_PaymentMethodsSheet> createState() => _PaymentMethodsSheetState();
}

class _PaymentMethodsSheetState extends State<_PaymentMethodsSheet> {
  late final _ctrl = TextEditingController(text: widget.user.upiId ?? '');
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await context.read<ProfileCubit>().updateUpiId(_ctrl.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_ctrl.text.trim().isEmpty
              ? 'UPI ID removed.'
              : 'UPI ID saved. Friends can now pay you from settle-up.')));
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return _sheet(context, children: [
      Text('Payment methods',
          style: PayPactTypography.headingMd.copyWith(color: pt.ink)),
      const SizedBox(height: 6),
      Text(
          'Add your UPI ID so friends can pay you straight from the settle-up '
          'screen, and share your QR code to be paid in person.',
          style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
      const SizedBox(height: 18),
      TextField(
        controller: _ctrl,
        autofocus: true,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        style: PayPactTypography.bodyMd.copyWith(color: pt.ink),
        decoration: InputDecoration(
          labelText: 'UPI ID',
          hintText: 'name@okbank',
          errorText: _error,
          prefixIcon: Icon(Icons.account_balance_wallet_outlined, color: pt.ink3),
        ),
      ),
      const SizedBox(height: 18),
      PayPactButton(
        onPressed: _saving ? null : _save,
        label: _saving ? 'Saving…' : 'Save',
        variant: PayPactButtonVariant.accent,
        size: PayPactButtonSize.large,
        isFullWidth: true,
      ),
      if (widget.user.upiId != null)
        Center(
          child: TextButton(
            onPressed: _saving
                ? null
                : () {
                    _ctrl.clear();
                    _save();
                  },
            child: Text('Remove UPI ID',
                style: PayPactTypography.bodyMd.copyWith(color: pt.negative)),
          ),
        ),
    ]);
  }
}

/// A QR code others can scan with any UPI app to pay this user.
Future<void> showReceiveQrSheet(
    BuildContext context, UserEntity user, VoidCallback onAddUpi) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final pt = ctx.pt;
      final upi = user.upiId;
      if (upi == null) {
        return _sheet(ctx, children: [
          Text('Get paid by QR',
              style: PayPactTypography.headingMd.copyWith(color: pt.ink)),
          const SizedBox(height: 6),
          Text('Add your UPI ID first, then friends can scan a QR code to pay you.',
              style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
          const SizedBox(height: 18),
          PayPactButton(
            onPressed: () {
              Navigator.pop(ctx);
              onAddUpi();
            },
            label: 'Add UPI ID',
            variant: PayPactButtonVariant.accent,
            size: PayPactButtonSize.large,
            isFullWidth: true,
          ),
        ]);
      }
      final link = buildUpiUri(upiId: upi, payeeName: user.name).toString();
      return _sheet(ctx, children: [
        Center(
          child: Text('Pay ${user.name}',
              style: PayPactTypography.headingMd.copyWith(color: pt.ink)),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text('Scan with any UPI app',
              style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
        ),
        const SizedBox(height: 18),
        Center(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: PayPactRadius.lg,
              border: Border.all(color: pt.border),
            ),
            child: QrImageView(data: link, size: 200, padding: EdgeInsets.zero),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: SelectableText(upi,
              style: PayPactTypography.bodyMd
                  .copyWith(color: pt.ink, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 14),
        PayPactButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: upi));
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('UPI ID copied')));
            }
          },
          label: 'Copy UPI ID',
          variant: PayPactButtonVariant.secondary,
          size: PayPactButtonSize.large,
          isFullWidth: true,
          leftIcon: Icons.copy_rounded,
        ),
      ]);
    },
  );
}
