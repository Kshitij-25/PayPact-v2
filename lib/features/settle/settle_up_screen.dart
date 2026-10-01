import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/utils/currency_utils.dart';
import 'package:paypact/core/utils/upi.dart';
import 'package:paypact/core/utils/responsive.dart';
import 'package:paypact/design_system/components/paypact_button.dart';
import 'package:paypact/design_system/components/paypact_card.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/features/notification/domain/repositories/notifications_repository.dart';
import 'package:paypact/features/settle/cubit/settle_cubit.dart';
import 'package:paypact/features/settle/domain/settlement_entity.dart';
import 'package:paypact/widgets/pp_atoms.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettleUpScreen extends StatelessWidget {
  const SettleUpScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.suggestedAmount,
    this.currency = kDefaultCurrency,
  });

  final String groupId;
  final String groupName;
  final String fromUserId;
  final String fromUserName;
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
        locator<GroupRepository>(),
      ),
      child: _SettleUpBody(
        groupId: groupId,
        groupName: groupName,
        fromUserId: fromUserId,
        fromUserName: fromUserName,
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
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.suggestedAmount,
    required this.currency,
  });

  final String groupId;
  final String groupName;
  final String fromUserId;
  final String fromUserName;
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

  // One key per settle flow: a double-tap on Confirm reuses it, so the
  // repository dedupes the write instead of recording two payments. A fresh
  // navigation to this screen mints a new key = a legitimately separate payment.
  final String _idempotencyKey = const Uuid().v4();

  // Index-aligned with [_methods]. Cash and bank transfer just record a payment
  // that happened outside the app; UPI opens the payer's UPI app first.
  static const _methodIds = [
    PaymentMethod.cash,
    PaymentMethod.upi,
    PaymentMethod.bankTransfer,
  ];

  String get _paymentMethod => _selectedMethod < _methodIds.length
      ? _methodIds[_selectedMethod]
      : PaymentMethod.cash;

  /// The payee's UPI address, if they've added one.
  String? _payeeUpi;
  bool _payeeUpiLoaded = false;

  bool get _upiAvailable => widget.currency == 'INR' && _payeeUpi != null;

  List<_Method> get _methods => [
        const _Method('Mark as paid in cash', 'No transfer · just record it',
            Icons.payments_outlined),
        _Method(
          'Pay with UPI',
          widget.currency != 'INR'
              ? 'UPI only works for ₹ groups'
              : !_payeeUpiLoaded
                  ? 'Checking…'
                  : _payeeUpi == null
                      ? '${widget.toUserName.split(' ').first} hasn\'t added a UPI ID'
                      : 'Opens your UPI app · pays $_payeeUpi',
          Icons.smartphone_rounded,
        ),
        const _Method('Bank transfer', 'Sent by NEFT / IMPS · just record it',
            Icons.account_balance_outlined),
      ];

  bool _methodEnabled(int i) => i != 1 || _upiAvailable;

  Future<void> _loadPayeeUpi() async {
    try {
      final doc = await locator<FirebaseFirestore>()
          .collection('users')
          .doc(widget.toUserId)
          .get();
      final upi = normalizeUpiId(doc.data()?['upiId'] as String?);
      if (mounted) {
        setState(() {
          _payeeUpi = upi;
          _payeeUpiLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _payeeUpiLoaded = true);
    }
  }

  /// Opens the payer's UPI app for the payment; returns true once they
  /// confirm it went through (we can't see the result of a UPI payment).
  Future<bool> _payViaUpi(BuildContext context) async {
    final upi = _payeeUpi!;
    final uri = buildUpiUri(
      upiId: upi,
      payeeName: widget.toUserName,
      amount: _amount,
      note: 'PayPact · ${widget.groupName}',
    );
    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!context.mounted) return false;

    final pt = context.pt;
    final paid = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(launched ? 'Did the payment go through?' : 'Pay with UPI'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              launched
                  ? 'Finish paying ${_fmt(_amount)} to ${widget.toUserName} in your UPI app, then come back and confirm.'
                  : "No UPI app opened. Scan this with a UPI app on your phone, or pay $upi yourself, then confirm.",
            ),
            if (!launched) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.white,
                child: QrImageView(
                    data: uri.toString(), size: 180, padding: EdgeInsets.zero),
              ),
              TextButton.icon(
                onPressed: () => Clipboard.setData(ClipboardData(text: upi)),
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy UPI ID'),
              ),
            ],
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(launched ? 'Not yet' : 'Cancel',
                  style: TextStyle(color: pt.ink3))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes, I paid')),
        ],
      ),
    );
    return paid ?? false;
  }

  /// Confirm button: UPI opens the app first; bank transfer asks to be sure the
  /// money was really sent, since recording it settles the balance.
  Future<void> _onConfirm(BuildContext context) async {
    if (_paymentMethod == PaymentMethod.upi) {
      if (!await _payViaUpi(context) || !context.mounted) return;
    } else if (_paymentMethod == PaymentMethod.bankTransfer) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Record bank transfer?'),
          content: Text(
              'Only record this once you\'ve actually sent ${_fmt(_amount)} to ${widget.toUserName}. '
              'It will settle the balance.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Not yet')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Yes, I've sent it")),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
    }
    context.read<SettleCubit>().settle(
          groupId: widget.groupId,
          groupName: widget.groupName,
          fromUserId: widget.fromUserId,
          fromUserName: widget.fromUserName,
          toUserId: widget.toUserId,
          toUserName: widget.toUserName,
          amount: _amount,
          idempotencyKey: _idempotencyKey,
          paymentMethod: _paymentMethod,
        );
  }

  String _money(double v) {
    final sym = currencyOf(widget.currency).symbol;
    return '$sym${NumberFormat('#,##0').format(v)}';
  }

  @override
  void initState() {
    super.initState();
    _amount = widget.suggestedAmount;
    _loadPayeeUpi();
  }

  String _fmt(double v) =>
      '${currencyOf(widget.currency).symbol}${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)}';

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final authState = context.watch<AuthCubit>().state;
    final currentUserId =
        authState is AuthAuthenticated ? authState.user.id : null;

    // Determine display direction: who is paying whom
    final bool currentUserIsPaying = widget.fromUserId == currentUserId;
    final String payerLabel = currentUserIsPaying ? 'You' : widget.fromUserName.split(' ').first;
    final String receiverLabel = widget.toUserName.split(' ').first;

    return BlocListener<SettleCubit, SettleState>(
      listener: (context, state) {
        if (state is SettleSuccess) {
          context.pushReplacement(
            '/group/${widget.groupId}/settle-success',
            extra: {
              'groupName': widget.groupName,
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
      child: context.isDesktop
          ? _buildWebModal(
              context,
              currentUserIsPaying: currentUserIsPaying,
              payerLabel: payerLabel,
              receiverLabel: receiverLabel,
            )
          : Scaffold(
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
                                PpAvatar(name: widget.fromUserName, size: 68),
                                const SizedBox(height: 8),
                                Text('FROM',
                                    style: PayPactTypography.label.copyWith(
                                        color: pt.ink3, letterSpacing: 1.5)),
                                const SizedBox(height: 2),
                                Text(payerLabel,
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
                                  receiverLabel,
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
                                  enabled: _methodEnabled(i),
                                  onTap: _methodEnabled(i)
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
                      onPressed: loading
                          ? null
                          : () => _onConfirm(context),
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

  // ───────────────────────────────────────────────────────────────────
  // Web modal (desktop only)
  // ───────────────────────────────────────────────────────────────────

  Widget _buildWebModal(
    BuildContext context, {
    required bool currentUserIsPaying,
    required String payerLabel,
    required String receiverLabel,
  }) {
    final pt = context.pt;
    final sugg = widget.suggestedAmount;
    final firstName = widget.toUserName.split(' ').first;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => context.pop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child:
                    Container(color: Colors.black.withValues(alpha: 0.18)),
              ),
            ),
          ),
          Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 600,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.92,
                ),
                decoration: BoxDecoration(
                  color: pt.bg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 80,
                      offset: const Offset(0, 24),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: Row(children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: pt.accentSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.swap_horiz_rounded,
                                size: 18, color: pt.accent),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Settle up',
                                  style: PayPactTypography.bodyMd.copyWith(
                                      color: pt.ink,
                                      fontWeight: FontWeight.w700)),
                              Text('Step 1 of 2 · Pick method',
                                  style: PayPactTypography.bodySm
                                      .copyWith(color: pt.ink3)),
                            ],
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: pt.surface,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Icon(Icons.close_rounded,
                                  size: 16, color: pt.ink3),
                            ),
                          ),
                        ]),
                      ),
                      Divider(height: 1, color: pt.border),
                      // Body
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Text('WHO PAID WHO',
                                    style: PayPactTypography.label.copyWith(
                                        color: pt.accent,
                                        letterSpacing: 1.6,
                                        fontSize: 10)),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _party(pt, widget.fromUserName,
                                        'FROM', payerLabel),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(_money(_amount),
                                          style: PayPactTypography.amountHero
                                              .copyWith(
                                                  color: pt.accent,
                                                  fontSize: 40)),
                                      const SizedBox(height: 2),
                                      Text('Clears all balances',
                                          style: PayPactTypography.bodySm
                                              .copyWith(color: pt.ink3)),
                                    ],
                                  ),
                                  Expanded(
                                    child: _party(pt, widget.toUserName, 'TO',
                                        receiverLabel),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    if (sugg > 0) ...[
                                      _WebAmtChip(
                                        top: _money(sugg / 2),
                                        bottom: 'partial',
                                        selected: _amount == sugg / 2,
                                        onTap: () => setState(
                                            () => _amount = sugg / 2),
                                      ),
                                      _WebAmtChip(
                                        top: _money(sugg),
                                        bottom: 'all open',
                                        selected: _amount == sugg,
                                        onTap: () =>
                                            setState(() => _amount = sugg),
                                      ),
                                      _WebAmtChip(
                                        top: _money(sugg * 2),
                                        bottom: '+future',
                                        selected: _amount == sugg * 2,
                                        onTap: () => setState(
                                            () => _amount = sugg * 2),
                                      ),
                                    ],
                                    _WebAmtChip(
                                      top: 'Custom',
                                      bottom: 'enter amount',
                                      selected: sugg <= 0 ||
                                          (_amount != sugg / 2 &&
                                              _amount != sugg &&
                                              _amount != sugg * 2),
                                      onTap: () =>
                                          _showCustomAmountDialog(context),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text('METHOD',
                                  style: PayPactTypography.label.copyWith(
                                      color: pt.ink3,
                                      letterSpacing: 1.4,
                                      fontSize: 10)),
                              const SizedBox(height: 8),
                              PayPactCard(
                                padding: EdgeInsets.zero,
                                child: Column(children: [
                                  for (var i = 0;
                                      i < _methods.length;
                                      i++) ...[
                                    if (i > 0)
                                      Divider(color: pt.border, height: 1),
                                    _MethodTile(
                                      m: _methods[i],
                                      selected: _selectedMethod == i,
                                      enabled: _methodEnabled(i),
                                      onTap: _methodEnabled(i)
                                          ? () => setState(
                                              () => _selectedMethod = i)
                                          : null,
                                    ),
                                  ],
                                ]),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(height: 1, color: pt.border),
                      // Footer
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(
                          children: [
                            PayPactButton(
                              onPressed: () => context.pop(),
                              label: 'Cancel',
                              variant: PayPactButtonVariant.secondary,
                              size: PayPactButtonSize.large,
                            ),
                            const Spacer(),
                            BlocBuilder<SettleCubit, SettleState>(
                              builder: (context, state) {
                                final loading = state is SettleLoading;
                                return PayPactButton(
                                  onPressed: loading
                                      ? null
                                      : () => _onConfirm(context),
                                  label: loading
                                      ? 'Recording…'
                                      : 'Confirm — ${_money(_amount)} to $firstName',
                                  variant: PayPactButtonVariant.accent,
                                  size: PayPactButtonSize.large,
                                  leftIcon:
                                      loading ? null : Icons.check_rounded,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _party(PayPactThemeExtension pt, String name, String role,
      String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PpAvatar(name: name, size: 56),
        const SizedBox(height: 8),
        Text(role,
            style: PayPactTypography.label
                .copyWith(color: pt.ink3, letterSpacing: 1.5, fontSize: 10)),
        const SizedBox(height: 2),
        Text(label,
            style: PayPactTypography.bodyMd
                .copyWith(color: pt.ink, fontWeight: FontWeight.w600)),
      ],
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

// Two-line amount chip used in the web settle modal.
class _WebAmtChip extends StatelessWidget {
  const _WebAmtChip({
    required this.top,
    required this.bottom,
    required this.selected,
    required this.onTap,
  });
  final String top;
  final String bottom;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? pt.accent : pt.surface,
          borderRadius: PayPactRadius.md,
          border: Border.all(color: selected ? pt.accent : pt.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(top,
                style: PayPactTypography.bodyMd.copyWith(
                    color: selected ? Colors.white : pt.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
            const SizedBox(height: 1),
            Text(bottom,
                style: PayPactTypography.micro.copyWith(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.8)
                        : pt.ink3)),
          ],
        ),
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
