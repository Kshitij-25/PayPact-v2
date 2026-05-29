import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/utils/currency_utils.dart';
import 'package:paypact/core/utils/responsive.dart';
import 'package:paypact/design_system/components/paypact_button.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/presentation/cubit/add_expense_cubit.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/widgets/pp_atoms.dart';

typedef _SplitResult = ({String splitType, Map<String, double> customSplits});

class AddExpenseScreen extends StatelessWidget {
  const AddExpenseScreen({super.key, this.groupId});
  final String? groupId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddExpenseCubit(locator(), locator(), locator()),
      child: _AddExpenseBody(groupId: groupId),
    );
  }
}

class _AddExpenseBody extends StatefulWidget {
  const _AddExpenseBody({this.groupId});
  final String? groupId;

  @override
  State<_AddExpenseBody> createState() => _AddExpenseBodyState();
}

class _AddExpenseBodyState extends State<_AddExpenseBody> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  String _selectedCategory = 'food';
  String _groupCurrency = kDefaultCurrency;
  String _selectedCurrency = kDefaultCurrency;

  GroupEntity? _group;
  String _paidById = '';
  String _paidByName = '';

  String _splitType = 'equally';
  Map<String, double> _customSplits = {};

  bool _useYesterday = false;

  static const _cats = [
    _CatChoice('Food', '🍽', PpCategory.food, 'food'),
    _CatChoice('Stay', '🛏', PpCategory.stay, 'stay'),
    _CatChoice('Transport', '🚕', PpCategory.transport, 'transport'),
    _CatChoice('Shop', '🛍', PpCategory.shopping, 'shopping'),
    _CatChoice('Fun', '🎬', PpCategory.entertainment, 'entertainment'),
    _CatChoice('Other', '✨', PpCategory.other, 'other'),
  ];

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  Future<void> _loadGroup() async {
    final gid = widget.groupId;
    if (gid == null) return;
    final group = await locator<GroupRepository>().getGroup(gid);
    if (!mounted || group == null) return;

    final authState = context.read<AuthCubit>().state;
    final currentUserId =
        authState is AuthAuthenticated ? authState.user.id : '';
    final currentUserName =
        authState is AuthAuthenticated ? authState.user.name : '';

    setState(() {
      _group = group;
      _groupCurrency = group.currency;
      _selectedCurrency = group.currency;
      _paidById = currentUserId;
      _paidByName = currentUserName;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  double get _parsedAmount => double.tryParse(_amountCtrl.text) ?? 0;

  List<ExpenseSplitEntity> _buildUiSplits(double amount) {
    final members = _group?.memberNames ?? {};
    if (members.isEmpty) return [];

    switch (_splitType) {
      case 'equally':
        final each = amount / members.length;
        return members.entries
            .map((e) => ExpenseSplitEntity(
                  userId: e.key,
                  userName: e.value,
                  amount: double.parse(each.toStringAsFixed(2)),
                ))
            .toList();
      case 'exact':
        return members.entries
            .map((e) => ExpenseSplitEntity(
                  userId: e.key,
                  userName: e.value,
                  amount: _customSplits[e.key] ?? 0,
                ))
            .toList();
      case 'percent':
        return members.entries
            .map((e) => ExpenseSplitEntity(
                  userId: e.key,
                  userName: e.value,
                  amount: double.parse(
                      (amount * (_customSplits[e.key] ?? 0) / 100)
                          .toStringAsFixed(2)),
                ))
            .toList();
      case 'shares':
        final totalShares =
            members.keys.fold(0.0, (s, id) => s + (_customSplits[id] ?? 1));
        return members.entries
            .map((e) {
              final shares = _customSplits[e.key] ?? 1;
              return ExpenseSplitEntity(
                userId: e.key,
                userName: e.value,
                amount: totalShares > 0
                    ? double.parse(
                        (amount * shares / totalShares).toStringAsFixed(2))
                    : 0,
              );
            })
            .toList();
      default:
        return [];
    }
  }

  String _splitLabel() {
    final n = _group?.memberNames.length ?? 0;
    switch (_splitType) {
      case 'equally':
        return 'Equally · $n people';
      case 'exact':
        return 'Exact amounts · $n people';
      case 'percent':
        return 'By percentage · $n people';
      case 'shares':
        return 'By shares · $n people';
      default:
        return 'Equally · $n people';
    }
  }

  String _smartSplitText(String currentUserId) {
    final amount = _parsedAmount;
    if (amount <= 0) return '';
    final splits = _buildUiSplits(amount);
    if (splits.isEmpty) return '';

    final cur = currencyOf(_selectedCurrency);
    final n = splits.length;

    final mySplit = splits.firstWhere(
      (s) => s.userId == currentUserId,
      orElse: () =>
          ExpenseSplitEntity(userId: '', userName: '', amount: 0),
    );

    if (_paidById == currentUserId) {
      final othersTotal = amount - mySplit.amount;
      if (_splitType == 'equally') {
        return '$n × ${cur.symbol}${(amount / n).toStringAsFixed(2)} — others owe you ${cur.symbol}${othersTotal.toStringAsFixed(2)}';
      }
      return 'others owe you ${cur.symbol}${othersTotal.toStringAsFixed(2)} total';
    } else {
      return 'you owe $_paidByName ${cur.symbol}${mySplit.amount.toStringAsFixed(2)}';
    }
  }

  // Web preview banner text: "5 × ₹480.00. You'll owe Priya ₹480"
  String _webSmartSplitText(String currentUserId) {
    final amount = _parsedAmount;
    if (amount <= 0) return '';
    final splits = _buildUiSplits(amount);
    if (splits.isEmpty) return '';

    final cur = currencyOf(_selectedCurrency);
    final n = splits.length;
    final mySplit = splits.firstWhere(
      (s) => s.userId == currentUserId,
      orElse: () =>
          ExpenseSplitEntity(userId: '', userName: '', amount: 0),
    );

    if (_splitType == 'equally') {
      final each = amount / n;
      final tail = _paidById == currentUserId
          ? "You'll get back ${cur.symbol}${(amount - mySplit.amount).toStringAsFixed(0)}"
          : "You'll owe $_paidByName ${cur.symbol}${mySplit.amount.toStringAsFixed(0)}";
      return '$n × ${cur.symbol}${each.toStringAsFixed(2)}. $tail';
    }

    if (_paidById == currentUserId) {
      return "You'll get back ${cur.symbol}${(amount - mySplit.amount).toStringAsFixed(0)}";
    }
    return "You'll owe $_paidByName ${cur.symbol}${mySplit.amount.toStringAsFixed(0)}";
  }

  void _pickCurrency() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CurrencyPickerSheet(
        selected: _selectedCurrency,
        onPick: (code) => setState(() => _selectedCurrency = code),
      ),
    );
  }

  void _pickPaidBy() {
    final members = _group?.memberNames ?? {};
    if (members.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaidByPickerSheet(
        members: members,
        selectedId: _paidById,
        onPick: (id, name) => setState(() {
          _paidById = id;
          _paidByName = name;
        }),
      ),
    );
  }

  void _adjustSplit() async {
    final members = _group?.memberNames ?? {};
    if (members.isEmpty) return;
    final result = await showModalBottomSheet<_SplitResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SplitAdjustSheet(
        members: members,
        currentSplitType: _splitType,
        currentCustomSplits: _customSplits,
        totalAmount: _parsedAmount,
        currency: _selectedCurrency,
      ),
    );
    if (result != null) {
      setState(() {
        _splitType = result.splitType;
        _customSplits = result.customSplits;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = context.read<AuthCubit>().state;
    final currentUserId =
        authState is AuthAuthenticated ? authState.user.id : '';

    return BlocConsumer<AddExpenseCubit, AddExpenseState>(
      listener: (context, state) {
        if (state is AddExpenseSuccess) {
          context.pop();
        } else if (state is AddExpenseError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final loading = state is AddExpenseLoading;
        final parsedAmount = _parsedAmount;
        final selectedCur = currencyOf(_selectedCurrency);
        final isForeign = _selectedCurrency != _groupCurrency;
        final smartText = _smartSplitText(currentUserId);
        final memberCount = _group?.memberNames.length ?? 0;

        if (context.isDesktop) {
          return _buildWebModal(context, state, currentUserId, parsedAmount,
              selectedCur, memberCount, _webSmartSplitText(currentUserId), loading);
        }

        final sheetContent = Container(
          decoration: BoxDecoration(
            color: pt.bg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                offset: const Offset(0, -24),
                blurRadius: 60,
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                0, 14, 0, MediaQuery.of(context).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 38,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: pt.borderStrong.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),

                // Header: Cancel | New expense | Save
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text('Cancel',
                            style: PayPactTypography.bodyMd
                                .copyWith(color: pt.ink3)),
                      ),
                      const Spacer(),
                      Text('New expense',
                          style: PayPactTypography.headingMd
                              .copyWith(color: pt.ink)),
                      const Spacer(),
                      GestureDetector(
                        onTap: loading ? null : _save,
                        child: Text('Save',
                            style: PayPactTypography.bodyMd.copyWith(
                              color: loading ? pt.ink3 : pt.accent,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Amount display
                Column(
                  children: [
                    Text('AMOUNT',
                        style: PayPactTypography.label
                            .copyWith(color: pt.ink3, letterSpacing: 1.6)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: context.sw(240),
                      child: TextField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        textAlign: TextAlign.center,
                        style: PayPactTypography.amountHero
                            .copyWith(color: pt.accent, fontSize: context.sp(52)),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: PayPactTypography.amountHero.copyWith(
                              color: pt.ink3.withValues(alpha: 0.4),
                              fontSize: context.sp(52)),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          prefixText: selectedCur.symbol,
                          prefixStyle: PayPactTypography.amountHero
                              .copyWith(color: pt.accent, fontSize: context.sp(30)),
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    if (parsedAmount > 0 && memberCount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        _splitType == 'equally'
                            ? '≈ ${selectedCur.symbol}${(parsedAmount / memberCount).toStringAsFixed(2)} each, equally'
                            : _splitLabel(),
                        style: PayPactTypography.bodySm
                            .copyWith(color: pt.ink3),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Currency selector pill
                    GestureDetector(
                      onTap: _pickCurrency,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isForeign ? pt.accentSoft : pt.surface,
                          borderRadius: PayPactRadius.full,
                          border: Border.all(
                              color: isForeign ? pt.accent : pt.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_selectedCurrency,
                                style: PayPactTypography.bodyMd.copyWith(
                                    color:
                                        isForeign ? pt.accent : pt.ink,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            const SizedBox(width: 4),
                            Icon(Icons.unfold_more_rounded,
                                size: 14,
                                color: isForeign ? pt.accent : pt.ink3),
                          ],
                        ),
                      ),
                    ),
                    if (isForeign && parsedAmount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Will be converted to $_groupCurrency at live rate',
                        style: PayPactTypography.bodySm
                            .copyWith(color: pt.ink3),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 20),

                // Description field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    controller: _titleCtrl,
                    style: PayPactTypography.bodyLg
                        .copyWith(color: pt.ink, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'What was it for?',
                      hintStyle: PayPactTypography.bodyLg
                          .copyWith(color: pt.ink3, fontSize: 15),
                      prefixIcon: Icon(Icons.receipt_long_outlined,
                          size: 18, color: pt.ink2),
                      filled: true,
                      fillColor: pt.surface,
                      border: OutlineInputBorder(
                          borderRadius: PayPactRadius.md,
                          borderSide: BorderSide(color: pt.borderStrong)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: PayPactRadius.md,
                          borderSide: BorderSide(color: pt.borderStrong)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: PayPactRadius.md,
                          borderSide:
                              BorderSide(color: pt.accent, width: 1.4)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Category chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      for (var i = 0; i < _cats.length; i++) ...[
                        GestureDetector(
                          onTap: () => setState(
                              () => _selectedCategory = _cats[i].catId),
                          child: _CategoryChip(
                              c: _cats[i],
                              selected:
                                  _selectedCategory == _cats[i].catId),
                        ),
                        if (i < _cats.length - 1)
                          const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Divider(height: 1, color: pt.border),

                // Group row
                _InfoRow(
                  leading: _group != null
                      ? Text(_group!.emoji,
                          style: const TextStyle(fontSize: 22))
                      : Icon(Icons.group_outlined,
                          color: pt.ink3, size: 22),
                  label: 'Group',
                  value: _group?.name ?? 'Loading…',
                  pt: pt,
                  onTap: null,
                ),

                Divider(height: 1, color: pt.border, indent: 56),

                // Paid by row
                _InfoRow(
                  leading: _paidByName.isNotEmpty
                      ? PpAvatar(name: _paidByName, size: 30)
                      : Icon(Icons.person_outline,
                          color: pt.ink3, size: 22),
                  label: 'Paid by',
                  value: _paidByName.isEmpty ? 'Select' : _paidByName,
                  pt: pt,
                  onTap: _pickPaidBy,
                ),

                Divider(height: 1, color: pt.border, indent: 56),

                // Split row
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: pt.surface,
                          borderRadius: PayPactRadius.sm,
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.call_split_rounded,
                            color: pt.ink2, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Split',
                                style: PayPactTypography.bodySm
                                    .copyWith(color: pt.ink3)),
                            Text(_splitLabel(),
                                style: PayPactTypography.bodyMd.copyWith(
                                    color: pt.ink,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _adjustSplit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: pt.surface,
                            borderRadius: PayPactRadius.full,
                            border: Border.all(color: pt.border),
                          ),
                          child: Text('Adjust',
                              style: PayPactTypography.bodyMd.copyWith(
                                  color: pt.ink,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, color: pt.border),
                const SizedBox(height: 12),

                // Quick actions
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      _QuickChip(
                        icon: Icons.calendar_today_rounded,
                        label: _useYesterday ? 'Yesterday' : 'Today',
                        active: _useYesterday,
                        pt: pt,
                        onTap: () =>
                            setState(() => _useYesterday = !_useYesterday),
                      ),
                      const SizedBox(width: 8),
                      _QuickChip(
                        icon: Icons.document_scanner_outlined,
                        label: 'Scan receipt',
                        active: false,
                        pt: pt,
                        onTap: () => ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                                content:
                                    Text('Scan receipt — coming soon'))),
                      ),
                      const SizedBox(width: 8),
                      _QuickChip(
                        icon: Icons.call_split_rounded,
                        label: 'Split shortcut',
                        active: false,
                        pt: pt,
                        onTap: _adjustSplit,
                      ),
                    ],
                  ),
                ),

                // Smart split banner
                if (parsedAmount > 0 && smartText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: PpGlassCard(
                      padding: const EdgeInsets.all(12),
                      radius: PayPactRadius.md,
                      child: Row(
                        children: [
                          Icon(Icons.bolt_rounded,
                              color: pt.accent, size: 16),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Smart split: $smartText',
                              style: PayPactTypography.bodySm
                                  .copyWith(color: pt.ink2, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Save button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: PayPactButton(
                    onPressed: loading ? null : _save,
                    label: loading ? 'Saving…' : 'Save expense',
                    variant: PayPactButtonVariant.accent,
                    size: PayPactButtonSize.large,
                    isFullWidth: true,
                    leftIcon: Icons.check_rounded,
                  ),
                ),
              ],
            ),
          ),
        );

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: (isDark ? Colors.black : const Color(0xFF1F1B16))
                        .withValues(alpha: isDark ? 0.5 : 0.38),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: sheetContent,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;

    final gid = widget.groupId;
    if (gid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No group selected')));
      return;
    }

    final parsedAmount = _parsedAmount;
    final uiSplits = _buildUiSplits(parsedAmount);

    if (!mounted) return;
    context.read<AddExpenseCubit>().saveExpense(
          groupId: gid,
          groupCurrency: _groupCurrency,
          title: _titleCtrl.text,
          amount: parsedAmount,
          originalCurrency: _selectedCurrency,
          category: _selectedCategory,
          paidById: _paidById,
          paidByName: _paidByName,
          splits: uiSplits,
          currentUserId: authState.user.id,
        );
  }

// ─────────────────────────────────────────────────────────────────────
// Web modal (desktop only)
// ─────────────────────────────────────────────────────────────────────

  Widget _buildWebModal(
    BuildContext context,
    AddExpenseState state,
    String currentUserId,
    double parsedAmount,
    AppCurrency selectedCur,
    int memberCount,
    String smartText,
    bool loading,
  ) {
    final pt = context.pt;
    final liveSplits =
        parsedAmount > 0 ? _buildUiSplits(parsedAmount) : <ExpenseSplitEntity>[];
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final dateLabel = _useYesterday
        ? 'Yesterday · ${DateFormat('MMM d').format(yesterday)}'
        : 'Today · ${DateFormat('MMM d').format(now)}';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => context.pop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                    color: Colors.black.withValues(alpha: 0.18)),
              ),
            ),
          ),
          Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 716,
                constraints: BoxConstraints(
                  maxHeight:
                      MediaQuery.sizeOf(context).height * 0.9,
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
                      _webHeader(context, pt),
                      Divider(height: 1, color: pt.border),
                      SizedBox(
                        height: 488,
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                    24, 20, 24, 20),
                                child: _webLeftPanel(context, pt,
                                    parsedAmount, selectedCur,
                                    memberCount, dateLabel),
                              ),
                            ),
                            VerticalDivider(
                                width: 1,
                                thickness: 1,
                                color: pt.border),
                            SizedBox(
                              width: 300,
                              child: _webRightPanel(
                                  context, pt, currentUserId,
                                  parsedAmount, selectedCur,
                                  liveSplits, smartText),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: pt.border),
                      _webFooter(context, pt, loading),
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

  Widget _webHeader(
      BuildContext context, PayPactThemeExtension pt) {
    final now = DateTime.now();
    final d = _useYesterday
        ? now.subtract(const Duration(days: 1))
        : now;
    final subtitle = _group != null
        ? '${_group!.name} · ${DateFormat('MMM d').format(d)} · saved as you type'
        : 'saved as you type';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: pt.accentSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.receipt_long_outlined,
                size: 18, color: pt.accent),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New expense',
                  style: PayPactTypography.bodyMd.copyWith(
                      color: pt.ink, fontWeight: FontWeight.w700)),
              Text(subtitle,
                  style: PayPactTypography.bodySm
                      .copyWith(color: pt.ink3)),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: pt.border),
              ),
              child: Text('ESC',
                  style: PayPactTypography.label.copyWith(
                      color: pt.ink3,
                      fontSize: 11,
                      letterSpacing: 0.5)),
            ),
          ),
          const SizedBox(width: 8),
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
        ],
      ),
    );
  }

  Widget _webLeftPanel(
    BuildContext context,
    PayPactThemeExtension pt,
    double parsedAmount,
    AppCurrency selectedCur,
    int memberCount,
    String dateLabel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Amount
        Center(
          child: Column(
            children: [
              Text('AMOUNT',
                  style: PayPactTypography.label.copyWith(
                      color: pt.ink3,
                      letterSpacing: 1.6,
                      fontSize: 10)),
              const SizedBox(height: 8),
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                          decimal: true),
                  textAlign: TextAlign.center,
                  style: PayPactTypography.amountHero.copyWith(
                      color: pt.accent, fontSize: 48),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle:
                        PayPactTypography.amountHero.copyWith(
                            color:
                                pt.ink3.withValues(alpha: 0.35),
                            fontSize: 48),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    prefixText: selectedCur.symbol,
                    prefixStyle:
                        PayPactTypography.amountHero.copyWith(
                            color: pt.accent, fontSize: 28),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (parsedAmount > 0 && memberCount > 0) ...[
                const SizedBox(height: 4),
                Text(
                  _splitType == 'equally'
                      ? '≈ ${selectedCur.symbol}${(parsedAmount / memberCount).toStringAsFixed(0)} each, equally'
                      : _splitLabel(),
                  style: PayPactTypography.bodySm
                      .copyWith(color: pt.ink3),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Description
        Text('DESCRIPTION',
            style: PayPactTypography.label.copyWith(
                color: pt.ink3,
                letterSpacing: 1.4,
                fontSize: 10)),
        const SizedBox(height: 6),
        TextField(
          controller: _titleCtrl,
          style: PayPactTypography.bodyMd.copyWith(color: pt.ink),
          decoration: InputDecoration(
            hintText: 'Beach shack dinner',
            hintStyle: PayPactTypography.bodyMd
                .copyWith(color: pt.ink3),
            prefixIcon: Icon(Icons.receipt_long_outlined,
                size: 16, color: pt.ink2),
            filled: true,
            fillColor: pt.surface,
            border: OutlineInputBorder(
                borderRadius: PayPactRadius.md,
                borderSide: BorderSide(color: pt.borderStrong)),
            enabledBorder: OutlineInputBorder(
                borderRadius: PayPactRadius.md,
                borderSide: BorderSide(color: pt.borderStrong)),
            focusedBorder: OutlineInputBorder(
                borderRadius: PayPactRadius.md,
                borderSide:
                    BorderSide(color: pt.accent, width: 1.4)),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 14),
        // Category
        Text('CATEGORY',
            style: PayPactTypography.label.copyWith(
                color: pt.ink3,
                letterSpacing: 1.4,
                fontSize: 10)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final cat in _cats)
              GestureDetector(
                onTap: () =>
                    setState(() => _selectedCategory = cat.catId),
                child: _CategoryChip(
                    c: cat,
                    selected: _selectedCategory == cat.catId),
              ),
          ],
        ),
        const SizedBox(height: 14),
        // Date + Group
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DATE',
                      style: PayPactTypography.label.copyWith(
                          color: pt.ink3,
                          letterSpacing: 1.4,
                          fontSize: 10)),
                  const SizedBox(height: 6),
                  _WebSelector(
                    pt: pt,
                    leading: Icon(Icons.calendar_today_outlined,
                        size: 14, color: pt.ink2),
                    label: dateLabel,
                    onTap: () => setState(
                        () => _useYesterday = !_useYesterday),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GROUP',
                      style: PayPactTypography.label.copyWith(
                          color: pt.ink3,
                          letterSpacing: 1.4,
                          fontSize: 10)),
                  const SizedBox(height: 6),
                  _WebSelector(
                    pt: pt,
                    leading: _group != null
                        ? Text(_group!.emoji,
                            style: const TextStyle(fontSize: 15))
                        : Icon(Icons.group_outlined,
                            size: 14, color: pt.ink2),
                    label: _group?.name ?? 'Loading…',
                    onTap: null,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Paid by + Split
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PAID BY',
                      style: PayPactTypography.label.copyWith(
                          color: pt.ink3,
                          letterSpacing: 1.4,
                          fontSize: 10)),
                  const SizedBox(height: 6),
                  _WebSelector(
                    pt: pt,
                    leading: _paidByName.isNotEmpty
                        ? PpAvatar(name: _paidByName, size: 22)
                        : Icon(Icons.person_outline,
                            size: 14, color: pt.ink2),
                    label: _paidByName.isEmpty
                        ? 'Select'
                        : _paidByName,
                    onTap: _pickPaidBy,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SPLIT',
                      style: PayPactTypography.label.copyWith(
                          color: pt.ink3,
                          letterSpacing: 1.4,
                          fontSize: 10)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _WebSelector(
                          pt: pt,
                          leading: Icon(Icons.call_split_rounded,
                              size: 14, color: pt.ink2),
                          label:
                              'Equally · ${_group?.memberNames.length ?? 0} people',
                          onTap: null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _adjustSplit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            color: pt.surface,
                            borderRadius: PayPactRadius.full,
                            border: Border.all(color: pt.border),
                          ),
                          child: Text('Adjust',
                              style: PayPactTypography.bodySm
                                  .copyWith(
                                      color: pt.ink,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _webRightPanel(
    BuildContext context,
    PayPactThemeExtension pt,
    String currentUserId,
    double parsedAmount,
    AppCurrency selectedCur,
    List<ExpenseSplitEntity> liveSplits,
    String smartText,
  ) {
    return Container(
      color: pt.bg,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('SMART SPLIT PREVIEW',
              style: PayPactTypography.label.copyWith(
                  color: pt.ink3,
                  letterSpacing: 1.6,
                  fontSize: 10)),
          const SizedBox(height: 12),
          Expanded(
            child: liveSplits.isEmpty
                ? Center(
                    child: Text('Enter an amount to preview',
                        style: PayPactTypography.bodySm
                            .copyWith(color: pt.ink3)),
                  )
                : ListView.separated(
                    itemCount: liveSplits.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final split = liveSplits[i];
                      final isMe = split.userId == currentUserId;
                      final isPayer = split.userId == _paidById;
                      final displayName = isMe
                          ? '${split.userName} (you)'
                          : split.userName;
                      final subtitle = isPayer
                          ? 'paid · ${selectedCur.symbol}${parsedAmount.toStringAsFixed(0)}'
                          : 'owes $_paidByName';
                      return _WebSplitPreviewRow(
                        pt: pt,
                        name: displayName,
                        rawName: split.userName,
                        subtitle: subtitle,
                        amount:
                            '${selectedCur.symbol}${split.amount.toStringAsFixed(0)}',
                        amountColor: isPayer ? pt.positive : pt.ink,
                      );
                    },
                  ),
          ),
          if (liveSplits.isNotEmpty && smartText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: pt.accentSoft,
                borderRadius: PayPactRadius.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.bolt_rounded,
                      color: pt.accent, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Smart split: $smartText — added to your ${_group?.name ?? 'group'} balance.',
                      style: PayPactTypography.bodySm.copyWith(
                          color: pt.ink2, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _webFooter(
      BuildContext context, PayPactThemeExtension pt, bool loading) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          _WebFooterBtn(
            pt: pt,
            icon: Icons.photo_camera_outlined,
            label: 'Scan receipt',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Scan receipt — coming soon'))),
          ),
          const SizedBox(width: 8),
          _WebFooterBtn(
            pt: pt,
            icon: Icons.edit_outlined,
            label: 'Add note',
            onTap: () {},
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Press ',
                  style: PayPactTypography.bodySm
                      .copyWith(color: pt.ink3, fontSize: 12)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: pt.border),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('⌘↩',
                    style: PayPactTypography.bodySm.copyWith(
                        color: pt.ink3, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: PayPactRadius.full,
                border: Border.all(color: pt.border),
              ),
              child: Text('Cancel',
                  style: PayPactTypography.bodyMd.copyWith(
                      color: pt.ink,
                      fontWeight: FontWeight.w500,
                      fontSize: 13)),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: loading ? null : _save,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: loading ? pt.ink3 : pt.accent,
                borderRadius: PayPactRadius.full,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(loading ? 'Saving…' : 'Save expense',
                      style: PayPactTypography.bodyMd.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} // end _AddExpenseBodyState

// ─────────────────────────────────────────────────────────────────────
// Info row (Group / Paid by)
// ─────────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.leading,
    required this.label,
    required this.value,
    required this.pt,
    this.onTap,
  });
  final Widget leading;
  final String label;
  final String value;
  final PayPactThemeExtension pt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            SizedBox(
                width: 36,
                height: 36,
                child: Center(child: leading)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: PayPactTypography.bodySm
                          .copyWith(color: pt.ink3)),
                  Text(value,
                      style: PayPactTypography.bodyMd.copyWith(
                          color: pt.ink, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded,
                  color: pt.ink3, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Quick action chip
// ─────────────────────────────────────────────────────────────────────

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.pt,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool active;
  final PayPactThemeExtension pt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? pt.accentSoft : pt.surface,
          borderRadius: PayPactRadius.full,
          border:
              Border.all(color: active ? pt.accent : pt.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: active ? pt.accent : pt.ink3),
            const SizedBox(width: 6),
            Text(label,
                style: PayPactTypography.bodyMd.copyWith(
                  color: active ? pt.accent : pt.ink2,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Paid by picker sheet
// ─────────────────────────────────────────────────────────────────────

class _PaidByPickerSheet extends StatelessWidget {
  const _PaidByPickerSheet({
    required this.members,
    required this.selectedId,
    required this.onPick,
  });
  final Map<String, String> members;
  final String selectedId;
  final void Function(String id, String name) onPick;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
      decoration: BoxDecoration(
        color: pt.bg,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 5,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: pt.borderStrong.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Text('Who paid?',
              style:
                  PayPactTypography.headingMd.copyWith(color: pt.ink)),
          const SizedBox(height: 16),
          ...members.entries.map((e) {
            final isSelected = e.key == selectedId;
            return GestureDetector(
              onTap: () {
                onPick(e.key, e.value);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? pt.accentSoft : pt.surface,
                  borderRadius: PayPactRadius.md,
                  border: Border.all(
                      color: isSelected ? pt.accent : pt.border),
                ),
                child: Row(
                  children: [
                    PpAvatar(name: e.value, size: 32),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Text(e.value,
                            style: PayPactTypography.bodyMd.copyWith(
                                color: pt.ink,
                                fontWeight: FontWeight.w600))),
                    if (isSelected)
                      Icon(Icons.check_rounded,
                          color: pt.accent, size: 18),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Split adjust sheet
// ─────────────────────────────────────────────────────────────────────

class _SplitAdjustSheet extends StatefulWidget {
  const _SplitAdjustSheet({
    required this.members,
    required this.currentSplitType,
    required this.currentCustomSplits,
    required this.totalAmount,
    required this.currency,
  });
  final Map<String, String> members;
  final String currentSplitType;
  final Map<String, double> currentCustomSplits;
  final double totalAmount;
  final String currency;

  @override
  State<_SplitAdjustSheet> createState() => _SplitAdjustSheetState();
}

class _SplitAdjustSheetState extends State<_SplitAdjustSheet> {
  late String _splitType;
  late Map<String, TextEditingController> _controllers;

  static const _types = ['equally', 'exact', 'percent', 'shares'];
  static const _typeLabels = ['Equally', 'Exact', '%', 'Shares'];
  static const _typeIcons = [
    Icons.horizontal_distribute,
    Icons.attach_money_rounded,
    Icons.percent_rounded,
    Icons.stacked_bar_chart_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _splitType = widget.currentSplitType;
    _controllers = {
      for (final e in widget.members.entries)
        e.key: TextEditingController(
          text: widget.currentCustomSplits[e.key]?.toString() ?? '',
        ),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, double> _buildCustomSplits() => {
        for (final e in _controllers.entries)
          e.key: double.tryParse(e.value.text) ??
              (_splitType == 'shares' ? 1 : 0),
      };

  String? _validate() {
    if (_splitType == 'equally') return null;
    final values =
        _controllers.values.map((c) => double.tryParse(c.text) ?? 0);
    final sum = values.fold(0.0, (a, b) => a + b);
    if (_splitType == 'exact') {
      if ((sum - widget.totalAmount).abs() > 0.01) {
        final cur = currencyOf(widget.currency);
        return 'Total must equal ${cur.symbol}${widget.totalAmount.toStringAsFixed(2)}. Currently: ${cur.symbol}${sum.toStringAsFixed(2)}';
      }
    } else if (_splitType == 'percent') {
      if ((sum - 100).abs() > 0.01) {
        return 'Percentages must sum to 100%. Currently: ${sum.toStringAsFixed(1)}%';
      }
    }
    return null;
  }

  void _done() {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.pop(context,
        (splitType: _splitType, customSplits: _buildCustomSplits()));
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final cur = currencyOf(widget.currency);

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 14, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: pt.bg,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 38,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: pt.borderStrong.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Row(
            children: [
              Text('Split type',
                  style: PayPactTypography.headingMd
                      .copyWith(color: pt.ink)),
              const Spacer(),
              GestureDetector(
                onTap: _done,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: pt.accent,
                    borderRadius: PayPactRadius.full,
                  ),
                  child: Text('Done',
                      style: PayPactTypography.bodyMd.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Split type tabs
          Row(
            children: [
              for (var i = 0; i < _types.length; i++) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _splitType = _types[i]),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _splitType == _types[i]
                            ? pt.accent
                            : pt.surface,
                        borderRadius: PayPactRadius.md,
                        border: Border.all(
                            color: _splitType == _types[i]
                                ? pt.accent
                                : pt.border),
                      ),
                      child: Column(
                        children: [
                          Icon(_typeIcons[i],
                              size: 18,
                              color: _splitType == _types[i]
                                  ? Colors.white
                                  : pt.ink2),
                          const SizedBox(height: 4),
                          Text(_typeLabels[i],
                              style: PayPactTypography.bodySm.copyWith(
                                color: _splitType == _types[i]
                                    ? Colors.white
                                    : pt.ink2,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
                if (i < _types.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // Member rows
          if (_splitType == 'equally') ...[
            ...widget.members.entries.map((e) {
              final each = widget.members.isNotEmpty && widget.totalAmount > 0
                  ? widget.totalAmount / widget.members.length
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    PpAvatar(name: e.value, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(e.value,
                            style: PayPactTypography.bodyMd
                                .copyWith(color: pt.ink))),
                    Text(
                        '${cur.symbol}${each.toStringAsFixed(2)}',
                        style: PayPactTypography.bodyMd.copyWith(
                            color: pt.ink2,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }),
          ] else ...[
            ...widget.members.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      PpAvatar(name: e.value, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(e.value,
                              style: PayPactTypography.bodyMd
                                  .copyWith(color: pt.ink))),
                      SizedBox(
                        width: 110,
                        child: TextField(
                          controller: _controllers[e.key],
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          textAlign: TextAlign.right,
                          style: PayPactTypography.bodyMd
                              .copyWith(color: pt.ink),
                          decoration: InputDecoration(
                            hintText: _splitType == 'shares'
                                ? '1'
                                : '0',
                            hintStyle: PayPactTypography.bodyMd
                                .copyWith(color: pt.ink3),
                            suffixText:
                                _splitType == 'percent' ? '%' : '',
                            prefixText: _splitType == 'exact'
                                ? cur.symbol
                                : '',
                            prefixStyle: PayPactTypography.bodyMd
                                .copyWith(color: pt.ink2),
                            filled: true,
                            fillColor: pt.surface,
                            border: OutlineInputBorder(
                                borderRadius: PayPactRadius.sm,
                                borderSide:
                                    BorderSide(color: pt.border)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: PayPactRadius.sm,
                                borderSide:
                                    BorderSide(color: pt.border)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: PayPactRadius.sm,
                                borderSide: BorderSide(
                                    color: pt.accent, width: 1.4)),
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                )),

            // Total summary for exact / percent
            if (_splitType == 'exact' || _splitType == 'percent') ...[
              const SizedBox(height: 4),
              Divider(color: pt.border),
              const SizedBox(height: 4),
              Builder(builder: (context) {
                final vals = _controllers.values
                    .map((c) => double.tryParse(c.text) ?? 0);
                final sum = vals.fold(0.0, (a, b) => a + b);
                final isValid = _splitType == 'exact'
                    ? (sum - widget.totalAmount).abs() < 0.01
                    : (sum - 100).abs() < 0.01;
                return Row(
                  children: [
                    Text('Total',
                        style: PayPactTypography.bodyMd
                            .copyWith(color: pt.ink3)),
                    const Spacer(),
                    Text(
                      _splitType == 'exact'
                          ? '${cur.symbol}${sum.toStringAsFixed(2)} / ${cur.symbol}${widget.totalAmount.toStringAsFixed(2)}'
                          : '${sum.toStringAsFixed(1)}% / 100%',
                      style: PayPactTypography.bodyMd.copyWith(
                          color: isValid ? pt.accent : Colors.red,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                );
              }),
            ],
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Currency picker sheet
// ─────────────────────────────────────────────────────────────────────

class _CurrencyPickerSheet extends StatelessWidget {
  const _CurrencyPickerSheet(
      {required this.selected, required this.onPick});
  final String selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
      decoration: BoxDecoration(
        color: pt.bg,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 5,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: pt.borderStrong.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Text('Expense currency',
              style:
                  PayPactTypography.headingMd.copyWith(color: pt.ink)),
          const SizedBox(height: 4),
          Text('Converted to group base currency on save',
              style:
                  PayPactTypography.bodySm.copyWith(color: pt.ink3)),
          const SizedBox(height: 16),
          ...kCurrencies.map((c) {
            final isSelected = c.code == selected;
            return GestureDetector(
              onTap: () {
                onPick(c.code);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 13),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isSelected ? pt.accentSoft : pt.surface,
                  borderRadius: PayPactRadius.md,
                  border: Border.all(
                      color: isSelected ? pt.accent : pt.border),
                ),
                child: Row(children: [
                  Text(c.symbol,
                      style: PayPactTypography.amountMd
                          .copyWith(color: pt.ink, fontSize: 18)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.code,
                            style: PayPactTypography.bodyMd.copyWith(
                                color: pt.ink,
                                fontWeight: FontWeight.w600)),
                        Text(c.name,
                            style: PayPactTypography.bodySm
                                .copyWith(color: pt.ink3)),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_rounded,
                        color: pt.accent, size: 18),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Category chip
// ─────────────────────────────────────────────────────────────────────

class _CatChoice {
  final String label;
  final String emoji;
  final PpCategory cat;
  final String catId;
  const _CatChoice(this.label, this.emoji, this.cat, this.catId);
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.c, required this.selected});
  final _CatChoice c;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final tones = PpCategoryDisc.tone(context, c.cat);
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? tones[0] : Colors.transparent,
        borderRadius: PayPactRadius.full,
        border: Border.all(
            color: selected ? Colors.transparent : pt.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(c.emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(c.label,
            style: PayPactTypography.bodyMd.copyWith(
                color: selected ? tones[1] : pt.ink2,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Web — pill-style field selector (Date / Group / Paid by / Split)
// ─────────────────────────────────────────────────────────────────────

class _WebSelector extends StatelessWidget {
  const _WebSelector({
    required this.pt,
    required this.leading,
    required this.label,
    required this.onTap,
  });
  final PayPactThemeExtension pt;
  final Widget leading;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: pt.surface,
          borderRadius: PayPactRadius.md,
          border: Border.all(color: pt.border),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PayPactTypography.bodyMd.copyWith(
                      color: pt.ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
            Icon(Icons.expand_more_rounded,
                size: 16, color: pt.ink3),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Web — smart split preview row
// ─────────────────────────────────────────────────────────────────────

class _WebSplitPreviewRow extends StatelessWidget {
  const _WebSplitPreviewRow({
    required this.pt,
    required this.name,
    required this.rawName,
    required this.subtitle,
    required this.amount,
    required this.amountColor,
  });
  final PayPactThemeExtension pt;
  final String name;
  final String rawName;
  final String subtitle;
  final String amount;
  final Color amountColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: pt.surface,
        borderRadius: PayPactRadius.md,
        border: Border.all(color: pt.border),
      ),
      child: Row(
        children: [
          PpAvatar(name: rawName, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PayPactTypography.bodyMd.copyWith(
                        color: pt.ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PayPactTypography.bodySm
                        .copyWith(color: pt.ink3, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(amount,
              style: PayPactTypography.amountMd.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Web — footer ghost button (Scan receipt / Add note)
// ─────────────────────────────────────────────────────────────────────

class _WebFooterBtn extends StatelessWidget {
  const _WebFooterBtn({
    required this.pt,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final PayPactThemeExtension pt;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: PayPactRadius.full,
          border: Border.all(color: pt.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: pt.ink2),
            const SizedBox(width: 6),
            Text(label,
                style: PayPactTypography.bodySm.copyWith(
                    color: pt.ink2,
                    fontWeight: FontWeight.w500,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
