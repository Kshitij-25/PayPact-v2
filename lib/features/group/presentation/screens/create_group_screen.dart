import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/utils/currency_utils.dart';
import 'package:paypact/core/utils/responsive.dart';
import 'package:paypact/design_system/components/paypact_button.dart';
import 'package:paypact/design_system/components/paypact_card.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/features/group/presentation/cubit/create_group_cubit.dart';
import 'package:paypact/widgets/pp_atoms.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateGroupScreen extends StatelessWidget {
  const CreateGroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CreateGroupCubit(locator<GroupRepository>()),
      child: const _CreateGroupBody(),
    );
  }
}

class _CreateGroupBody extends StatefulWidget {
  const _CreateGroupBody();

  @override
  State<_CreateGroupBody> createState() => _CreateGroupBodyState();
}

class _CreateGroupBodyState extends State<_CreateGroupBody> {
  final _nameCtrl = TextEditingController();
  String _selectedCategory = 'trip';
  String _selectedEmoji = '🏖';
  String _selectedCurrency = kDefaultCurrency;

  static const _categories = [
    _Cat('trip', 'Trip', '🏖'),
    _Cat('home', 'Home', '🏠'),
    _Cat('couple', 'Couple', '💑'),
    _Cat('friends', 'Friends', '🍕'),
    _Cat('work', 'Work', '💼'),
    _Cat('other', 'Other', '✨'),
  ];

  @override
  void initState() {
    super.initState();
    final prefs = locator<SharedPreferences>();
    _selectedCurrency =
        prefs.getString(kPrefCurrencyKey) ?? kDefaultCurrency;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final tripTone = PpCategoryDisc.tone(context, PpCategory.trip);
    final cur = currencyOf(_selectedCurrency);

    return BlocConsumer<CreateGroupCubit, CreateGroupState>(
      listener: (context, state) {
        if (state is CreateGroupSuccess) {
          context.pop();
          context.push(
            AppRoutes.addMembers,
            extra: {'groupId': state.group.id, 'fromCreate': true},
          );
        } else if (state is CreateGroupError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final loading = state is CreateGroupLoading;

        return Scaffold(
          backgroundColor: pt.bg,
          body: Stack(
            children: [
              const PpBackdropGlow(intensity: 0.12),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(20, 10, 20, 14),
                      child: Row(children: [
                        PpGlassIconButton(
                            icon: Icons.close_rounded,
                            onTap: () => context.pop()),
                        const Spacer(),
                        Column(
                          children: [
                            Text('New group',
                                style: PayPactTypography.bodyMd.copyWith(
                                    color: pt.ink,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 3),
                            Text('STEP 1 OF 2',
                                style: PayPactTypography.label.copyWith(
                                    color: pt.ink3,
                                    letterSpacing: 1.4,
                                    fontSize: 10)),
                          ],
                        ),
                        const Spacer(),
                        const SizedBox(width: 40),
                      ]),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 18, 28, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Name it,\nset the vibe.',
                                style: PayPactTypography.displayLg
                                    .copyWith(color: pt.ink)),
                            const SizedBox(height: 8),
                            Text('You can change all of this later.',
                                style: PayPactTypography.bodyLg
                                    .copyWith(color: pt.ink2)),
                            const SizedBox(height: 28),
                            Container(
                              height: context.sh(140),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [pt.accentSoft, tripTone[0]],
                                ),
                              ),
                              child: Center(
                                child: Text(_selectedEmoji,
                                    style: TextStyle(fontSize: context.sp(54))),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text('GROUP NAME',
                                style: PayPactTypography.label.copyWith(
                                    color: pt.ink3, letterSpacing: 1.5)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _nameCtrl,
                              style: PayPactTypography.headingLg
                                  .copyWith(color: pt.ink),
                              decoration: InputDecoration(
                                hintText: 'e.g. Goa Trip',
                                hintStyle: PayPactTypography.headingLg
                                    .copyWith(color: pt.ink3),
                                filled: true,
                                fillColor: pt.surface,
                                border: OutlineInputBorder(
                                  borderRadius: PayPactRadius.md,
                                  borderSide:
                                      BorderSide(color: pt.borderStrong),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: PayPactRadius.md,
                                  borderSide:
                                      BorderSide(color: pt.borderStrong),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: PayPactRadius.md,
                                  borderSide: BorderSide(
                                      color: pt.accent, width: 1.4),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text('CATEGORY',
                                style: PayPactTypography.label.copyWith(
                                    color: pt.ink3, letterSpacing: 1.5)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final c in _categories)
                                  GestureDetector(
                                    onTap: () => setState(() {
                                      _selectedCategory = c.id;
                                      _selectedEmoji = c.emoji;
                                    }),
                                    child: _CatChip(
                                        c: c,
                                        selected:
                                            _selectedCategory == c.id),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text('CURRENCY',
                                style: PayPactTypography.label.copyWith(
                                    color: pt.ink3, letterSpacing: 1.5)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _pickCurrency,
                              child: PayPactCard(
                                padding: const EdgeInsets.all(14),
                                child: Row(children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: pt.surfaceAlt,
                                      borderRadius: PayPactRadius.sm,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(cur.symbol,
                                        style: PayPactTypography.headingMd
                                            .copyWith(color: pt.ink)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(cur.name,
                                            style: PayPactTypography.bodyMd
                                                .copyWith(
                                                    color: pt.ink,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                        Text(
                                            '${cur.code} · ${cur.symbol} symbol',
                                            style: PayPactTypography.bodySm
                                                .copyWith(color: pt.ink3)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded,
                                      color: pt.ink3),
                                ]),
                              ),
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
                  padding:
                      const EdgeInsets.fromLTRB(24, 14, 24, 32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [pt.bg, pt.bg.withValues(alpha: 0)],
                      stops: const [0.7, 1.0],
                    ),
                  ),
                  child: PayPactButton(
                    onPressed: loading ? null : _submit,
                    label: loading ? 'Creating…' : 'Create group',
                    variant: PayPactButtonVariant.accent,
                    size: PayPactButtonSize.large,
                    isFullWidth: true,
                    rightIcon: Icons.arrow_forward_rounded,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _submit() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;
    context.read<CreateGroupCubit>().createGroup(
          name: _nameCtrl.text,
          emoji: _selectedEmoji,
          category: _selectedCategory,
          currency: _selectedCurrency,
          userId: authState.user.id,
          userName: authState.user.name,
        );
  }
}

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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
          Text('Group currency',
              style: PayPactTypography.headingMd.copyWith(color: pt.ink)),
          const SizedBox(height: 4),
          Text('All expenses are tracked in this currency',
              style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
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
                    Icon(Icons.check_rounded, color: pt.accent, size: 18),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Cat {
  final String id;
  final String label;
  final String emoji;
  const _Cat(this.id, this.label, this.emoji);
}

class _CatChip extends StatelessWidget {
  const _CatChip({required this.c, required this.selected});
  final _Cat c;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? pt.accent : pt.surface,
        borderRadius: PayPactRadius.full,
        border: Border.all(color: selected ? pt.accent : pt.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(c.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(c.label,
              style: PayPactTypography.bodyMd.copyWith(
                color: selected ? Colors.white : pt.ink,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              )),
        ],
      ),
    );
  }
}
