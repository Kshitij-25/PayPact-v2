import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/design_system/components/paypact_button.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/expense/presentation/cubit/add_expense_cubit.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/widgets/pp_atoms.dart';

class AddExpenseScreen extends StatelessWidget {
  const AddExpenseScreen({super.key, this.groupId});
  final String? groupId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddExpenseCubit(locator<ExpenseRepository>()),
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

  static const _cats = [
    _CatChoice('Food', '🍽', PpCategory.food, 'food'),
    _CatChoice('Stay', '🛏', PpCategory.stay, 'stay'),
    _CatChoice('Transport', '🚕', PpCategory.transport, 'transport'),
    _CatChoice('Shopping', '🛍', PpCategory.shopping, 'shopping'),
    _CatChoice('Other', '✨', PpCategory.other, 'other'),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        final amountText = _amountCtrl.text;
        final parsedAmount = double.tryParse(amountText) ?? 0;

        return Scaffold(
          backgroundColor: pt.bg,
          body: Stack(
            children: [
              Opacity(
                opacity: 0.35,
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(24, 70, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ADD EXPENSE',
                          style: PayPactTypography.label
                              .copyWith(color: pt.ink3)),
                      const SizedBox(height: 10),
                      Text('Split it easily',
                          style: PayPactTypography.amountHero
                              .copyWith(color: pt.ink, fontSize: 32)),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter:
                      ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    color: (isDark
                            ? Colors.black
                            : const Color(0xFF1F1B16))
                        .withValues(
                            alpha: isDark ? 0.45 : 0.32),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 120,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                      24, 14, 24, 0),
                  decoration: BoxDecoration(
                    color: pt.bg,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black
                              .withValues(alpha: 0.18),
                          offset: const Offset(0, -24),
                          blurRadius: 60),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 38,
                            height: 5,
                            margin: const EdgeInsets.only(
                                bottom: 18),
                            decoration: BoxDecoration(
                              color: pt.borderStrong
                                  .withValues(alpha: 0.5),
                              borderRadius:
                                  BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Text('Cancel',
                                  style: PayPactTypography
                                      .bodyMd
                                      .copyWith(color: pt.ink3)),
                            ),
                            Text('New expense',
                                style: PayPactTypography.headingMd
                                    .copyWith(color: pt.ink)),
                            GestureDetector(
                              onTap: loading ? null : _save,
                              child: Text('Save',
                                  style: PayPactTypography
                                      .bodyMd
                                      .copyWith(
                                          color: loading
                                              ? pt.ink3
                                              : pt.accent,
                                          fontWeight:
                                              FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Column(
                            children: [
                              Text('AMOUNT',
                                  style: PayPactTypography.label
                                      .copyWith(
                                          color: pt.ink3,
                                          letterSpacing: 1.6)),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: 200,
                                child: TextField(
                                  controller: _amountCtrl,
                                  keyboardType:
                                      const TextInputType
                                          .numberWithOptions(
                                          decimal: true),
                                  textAlign: TextAlign.center,
                                  style: PayPactTypography
                                      .amountHero
                                      .copyWith(
                                          color: pt.accent,
                                          fontSize: 52),
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    hintStyle: PayPactTypography
                                        .amountHero
                                        .copyWith(
                                            color: pt.ink3
                                                .withValues(
                                                    alpha: 0.4),
                                            fontSize: 52),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    prefixText: '₹',
                                    prefixStyle:
                                        PayPactTypography
                                            .amountHero
                                            .copyWith(
                                                color: pt.accent,
                                                fontSize: 30),
                                    isDense: true,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16),
                          decoration: BoxDecoration(
                            color: pt.surface,
                            borderRadius: PayPactRadius.md,
                            border: Border.all(
                                color: pt.accent, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                  color: pt.accentSoft,
                                  spreadRadius: 3,
                                  blurRadius: 0)
                            ],
                          ),
                          child: Row(children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 18, color: pt.ink2),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _titleCtrl,
                                style: PayPactTypography.bodyLg
                                    .copyWith(
                                        color: pt.ink,
                                        fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: 'What was it?',
                                  hintStyle:
                                      PayPactTypography.bodyLg
                                          .copyWith(
                                              color: pt.ink3,
                                              fontSize: 15),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 14),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(children: [
                            for (var i = 0;
                                i < _cats.length;
                                i++) ...[
                              GestureDetector(
                                onTap: () => setState(() =>
                                    _selectedCategory =
                                        _cats[i].catId),
                                child: _CategoryChip(
                                  c: _cats[i],
                                  selected: _selectedCategory ==
                                      _cats[i].catId,
                                ),
                              ),
                              if (i < _cats.length - 1)
                                const SizedBox(width: 8),
                            ],
                          ]),
                        ),
                        const SizedBox(height: 18),
                        if (parsedAmount > 0)
                          PpGlassCard(
                            padding: const EdgeInsets.all(14),
                            radius: PayPactRadius.md,
                            child: Row(children: [
                              Icon(Icons.bolt_rounded,
                                  color: pt.accent, size: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Split equally among group members · ₹${parsedAmount.toStringAsFixed(2)} total',
                                  style: PayPactTypography.bodySm
                                      .copyWith(
                                          color: pt.ink2,
                                          height: 1.5),
                                ),
                              ),
                            ]),
                          ),
                        const SizedBox(height: 18),
                        PayPactButton(
                          onPressed: loading ? null : _save,
                          label: loading
                              ? 'Saving…'
                              : 'Save expense',
                          variant: PayPactButtonVariant.accent,
                          size: PayPactButtonSize.large,
                          isFullWidth: true,
                          leftIcon: Icons.check_rounded,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
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

    final group = await locator<GroupRepository>().getGroup(gid);
    final members = group?.memberNames ?? {
      authState.user.id: authState.user.name
    };

    if (!mounted) return;
    context.read<AddExpenseCubit>().saveExpense(
          groupId: gid,
          title: _titleCtrl.text,
          amount: double.tryParse(_amountCtrl.text) ?? 0,
          category: _selectedCategory,
          paidById: authState.user.id,
          paidByName: authState.user.name,
          members: members,
          currentUserId: authState.user.id,
        );
  }
}

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
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color:
            selected ? tones[0] : Colors.transparent,
        borderRadius: PayPactRadius.full,
        border: Border.all(
            color:
                selected ? Colors.transparent : pt.border),
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
