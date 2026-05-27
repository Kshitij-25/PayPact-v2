import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/design_system/components/paypact_button.dart';
import 'package:paypact/design_system/components/paypact_card.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/notification/domain/repositories/notifications_repository.dart';
import 'package:paypact/features/settle/cubit/settle_cubit.dart';
import 'package:paypact/widgets/pp_atoms.dart';

class SettleUpScreen extends StatelessWidget {
  const SettleUpScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.toUserId,
    required this.toUserName,
    required this.suggestedAmount,
    this.currency = '₹',
  });

  final String groupId;
  final String groupName;
  final String toUserId;
  final String toUserName;
  final double suggestedAmount;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettleCubit(
        locator<ExpenseRepository>(),
        locator<NotificationsRepository>(),
      ),
      child: _SettleUpBody(
        groupId: groupId,
        groupName: groupName,
        toUserId: toUserId,
        toUserName: toUserName,
        suggestedAmount: suggestedAmount,
        currency: currency,
      ),
    );
  }
}

class _SettleUpBody extends StatefulWidget {
  const _SettleUpBody({
    required this.groupId,
    required this.groupName,
    required this.toUserId,
    required this.toUserName,
    required this.suggestedAmount,
    required this.currency,
  });

  final String groupId;
  final String groupName;
  final String toUserId;
  final String toUserName;
  final double suggestedAmount;
  final String currency;

  @override
  State<_SettleUpBody> createState() => _SettleUpBodyState();
}

class _SettleUpBodyState extends State<_SettleUpBody> {
  late double _amount;
  int _selectedMethod = 0;

  static const _methods = [
    _Method('Mark as paid in cash', 'No transfer · just record it',
        Icons.payments_outlined),
    _Method('PayPact wallet', 'Coming soon',
        Icons.qr_code_rounded),
    _Method('External UPI', 'Coming soon',
        Icons.link_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _amount = widget.suggestedAmount;
  }

  String _fmt(double v) =>
      '${widget.currency}${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)}';

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final authState = context.watch<AuthCubit>().state;
    final currentUser =
        authState is AuthAuthenticated ? authState.user : null;

    return BlocListener<SettleCubit, SettleState>(
      listener: (context, state) {
        if (state is SettleSuccess) {
          context.pushReplacement(
            '/group/${widget.groupId}/settle-success',
            extra: {
              'fromUserName': state.fromUserName,
              'toUserName': state.toUserName,
              'amount': state.amount,
              'receiptId': state.receiptId,
              'currency': widget.currency,
            },
          );
        } else if (state is SettleError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: pt.bg,
        body: Stack(
          children: [
            const PpBackdropGlow(intensity: 0.12),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                    child: Row(children: [
                      PpGlassIconButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => context.pop()),
                      const Spacer(),
                      Text('Settle up',
                          style: PayPactTypography.bodyMd.copyWith(
                              color: pt.ink, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('Step 1 / 2',
                          style: PayPactTypography.bodyMd
                              .copyWith(color: pt.ink3)),
                    ]),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 18, 28, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('WHO PAID WHO',
                              style: PayPactTypography.label.copyWith(
                                  color: pt.accent, letterSpacing: 1.6)),
                          const SizedBox(height: 14),
                          Text("Just three taps —\nand you're square.",
                              style: PayPactTypography.displayLg
                                  .copyWith(color: pt.ink)),
                          const SizedBox(height: 24),
                          Row(children: [
                            Expanded(
                              child: Column(children: [
                                PpAvatar(
                                    name: currentUser?.name ?? 'You',
                                    size: 68),
                                const SizedBox(height: 8),
                                Text('FROM',
                                    style: PayPactTypography.label.copyWith(
                                        color: pt.ink3, letterSpacing: 1.5)),
                                const SizedBox(height: 2),
                                Text('You',
                                    style: PayPactTypography.bodyMd.copyWith(
                                        color: pt.ink,
                                        fontWeight: FontWeight.w600)),
                              ]),
                            ),
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: pt.surface,
                                shape: BoxShape.circle,
                                border: Border.all(color: pt.border),
                                boxShadow: pt.shadowSm,
                              ),
                              alignment: Alignment.center,
                              child: Icon(Icons.arrow_forward_rounded,
                                  color: pt.accent, size: 22),
                            ),
                            Expanded(
                              child: Column(children: [
                                PpAvatar(name: widget.toUserName, size: 68),
                                const SizedBox(height: 8),
                                Text('TO',
                                    style: PayPactTypography.label.copyWith(
                                        color: pt.ink3, letterSpacing: 1.5)),
                                const SizedBox(height: 2),
                                Text(
                                  widget.toUserName.split(' ').first,
                                  style: PayPactTypography.bodyMd.copyWith(
                                      color: pt.ink,
                                      fontWeight: FontWeight.w600),
                                ),
                              ]),
                            ),
                          ]),
                          const SizedBox(height: 30),
                          Center(
                            child: Column(children: [
                              Text('AMOUNT',
                                  style: PayPactTypography.label.copyWith(
                                      color: pt.ink3, letterSpacing: 1.6)),
                              const SizedBox(height: 10),
                              Text(_fmt(_amount),
                                  style: PayPactTypography.amountHero
                                      .copyWith(
                                          color: pt.accent, fontSize: 60)),
                              const SizedBox(height: 6),
                              Text(
                                'Suggested · clears all open balances with ${widget.toUserName.split(' ').first}',
                                style: PayPactTypography.bodySm
                                    .copyWith(color: pt.ink3),
                                textAlign: TextAlign.center,
                              ),
                            ]),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: Wrap(
                              spacing: 8,
                              children: [
                                if (widget.suggestedAmount > 0) ...[
                                  _AmtChip(
                                    label: _fmt(widget.suggestedAmount / 2),
                                    selected:
                                        _amount == widget.suggestedAmount / 2,
                                    onTap: () => setState(
                                        () => _amount =
                                            widget.suggestedAmount / 2),
                                  ),
                                  _AmtChip(
                                    label: _fmt(widget.suggestedAmount),
                                    selected:
                                        _amount == widget.suggestedAmount,
                                    onTap: () => setState(
                                        () => _amount = widget.suggestedAmount),
                                  ),
                                ],
                                _AmtChip(
                                  label: 'Custom',
                                  selected: _amount != widget.suggestedAmount &&
                                      _amount != widget.suggestedAmount / 2,
                                  onTap: () => _showCustomAmountDialog(context),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text('METHOD',
                              style: PayPactTypography.label.copyWith(
                                  color: pt.ink3, letterSpacing: 1.5)),
                          const SizedBox(height: 8),
                          PayPactCard(
                            padding: EdgeInsets.zero,
                            child: Column(children: [
                              for (var i = 0; i < _methods.length; i++) ...[
                                if (i > 0) Divider(color: pt.border, height: 1),
                                _MethodTile(
                                  m: _methods[i],
                                  selected: _selectedMethod == i,
                                  enabled: i == 0,
                                  onTap: i == 0
                                      ? () =>
                                          setState(() => _selectedMethod = i)
                                      : null,
                                ),
                              ],
                            ]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [pt.bg, pt.bg.withValues(alpha: 0)],
                    stops: const [0.7, 1.0],
                  ),
                ),
                child: BlocBuilder<SettleCubit, SettleState>(
                  builder: (context, state) {
                    final loading = state is SettleLoading;
                    final firstName =
                        widget.toUserName.split(' ').first;
                    return PayPactButton(
                      onPressed: loading || currentUser == null
                          ? null
                          : () {
                              context.read<SettleCubit>().settle(
                                    groupId: widget.groupId,
                                    groupName: widget.groupName,
                                    fromUserId: currentUser.id,
                                    fromUserName: currentUser.name,
                                    toUserId: widget.toUserId,
                                    toUserName: widget.toUserName,
                                    amount: _amount,
                                  );
                            },
                      label: loading
                          ? 'Recording…'
                          : 'Confirm — ${_fmt(_amount)} to $firstName',
                      variant: PayPactButtonVariant.accent,
                      size: PayPactButtonSize.large,
                      isFullWidth: true,
                      leftIcon:
                          loading ? null : Icons.check_rounded,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomAmountDialog(BuildContext context) {
    final controller =
        TextEditingController(text: _amount.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Custom amount'),
        content: TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
              prefixText: '${widget.currency} ',
              hintText: '0'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final v = double.tryParse(controller.text);
              if (v != null && v > 0) setState(() => _amount = v);
              Navigator.pop(context);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }
}

class _AmtChip extends StatelessWidget {
  const _AmtChip(
      {required this.label, required this.selected, this.onTap});
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? pt.accent : pt.surface,
          borderRadius: PayPactRadius.full,
          border: Border.all(color: selected ? pt.accent : pt.border),
        ),
        child: Text(label,
            style: PayPactTypography.bodyMd.copyWith(
                color: selected ? Colors.white : pt.ink,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ),
    );
  }
}

class _Method {
  final String label;
  final String sub;
  final IconData icon;
  const _Method(this.label, this.sub, this.icon);
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.m,
    required this.selected,
    required this.enabled,
    this.onTap,
  });
  final _Method m;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.45,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected ? pt.accentSoft : pt.surfaceAlt,
                borderRadius: PayPactRadius.sm,
              ),
              alignment: Alignment.center,
              child: Icon(m.icon,
                  size: 18,
                  color: selected ? pt.accentInk : pt.ink2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.label,
                      style: PayPactTypography.bodyMd.copyWith(
                          color: pt.ink, fontWeight: FontWeight.w600)),
                  Text(m.sub,
                      style: PayPactTypography.bodySm
                          .copyWith(color: pt.ink3)),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? pt.accent : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                    color: selected ? pt.accent : pt.border, width: 2),
              ),
              alignment: Alignment.center,
              child: selected
                  ? const Icon(Icons.check_rounded,
                      size: 12, color: Colors.white)
                  : null,
            ),
          ]),
        ),
      ),
    );
  }
}
