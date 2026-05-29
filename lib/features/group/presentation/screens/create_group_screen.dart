import 'dart:ui';
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

        if (context.isDesktop) {
          return _buildWebModal(context, loading);
        }

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

  // ───────────────────────────────────────────────────────────────────
  // Web modal (desktop only)
  // ───────────────────────────────────────────────────────────────────

  PpCategory _catEnum(String id) {
    switch (id) {
      case 'home':
        return PpCategory.home;
      case 'couple':
        return PpCategory.couple;
      case 'friends':
        return PpCategory.friends;
      case 'trip':
        return PpCategory.trip;
      default:
        return PpCategory.other;
    }
  }

  Widget _buildWebModal(BuildContext context, bool loading) {
    final pt = context.pt;
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
                width: 800,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.9,
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
                        height: 472,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                    28, 24, 28, 24),
                                child: _webLeftPanel(context, pt),
                              ),
                            ),
                            VerticalDivider(
                                width: 1, thickness: 1, color: pt.border),
                            SizedBox(
                              width: 330,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                    24, 24, 24, 24),
                                child: _webRightPanel(context, pt),
                              ),
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

  Widget _webHeader(BuildContext context, PayPactThemeExtension pt) {
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
            child: Icon(Icons.group_outlined, size: 18, color: pt.accent),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New group',
                  style: PayPactTypography.bodyMd.copyWith(
                      color: pt.ink, fontWeight: FontWeight.w700)),
              Text('Step 1 of 2 · Name & vibe',
                  style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
            ],
          ),
          const Spacer(),
          _webStep(pt, '1', 'Name & vibe', active: true),
          Container(
            width: 28,
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: pt.border,
          ),
          _webStep(pt, '2', 'Members', active: false),
        ],
      ),
    );
  }

  Widget _webStep(PayPactThemeExtension pt, String num, String label,
      {required bool active}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: active ? pt.accent : Colors.transparent,
            shape: BoxShape.circle,
            border: active ? null : Border.all(color: pt.borderStrong),
          ),
          alignment: Alignment.center,
          child: Text(num,
              style: PayPactTypography.label.copyWith(
                  color: active ? Colors.white : pt.ink3,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 7),
        Text(label,
            style: PayPactTypography.bodySm.copyWith(
                color: active ? pt.ink : pt.ink3,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12)),
      ],
    );
  }

  Widget _webLeftPanel(BuildContext context, PayPactThemeExtension pt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Name it, set the vibe.',
            style: PayPactTypography.displayLg
                .copyWith(color: pt.ink, fontSize: 32)),
        const SizedBox(height: 6),
        Text('You can change all of this later.',
            style: PayPactTypography.bodyLg.copyWith(color: pt.ink2)),
        const SizedBox(height: 22),
        Text('GROUP NAME',
            style: PayPactTypography.label.copyWith(
                color: pt.ink3, letterSpacing: 1.4, fontSize: 10)),
        const SizedBox(height: 8),
        TextField(
          controller: _nameCtrl,
          style: PayPactTypography.headingLg.copyWith(color: pt.ink),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'e.g. Goa Trip',
            hintStyle:
                PayPactTypography.headingLg.copyWith(color: pt.ink3),
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
                borderSide: BorderSide(color: pt.accent, width: 1.4)),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 18),
        Text('CATEGORY',
            style: PayPactTypography.label.copyWith(
                color: pt.ink3, letterSpacing: 1.4, fontSize: 10)),
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
                child: _CatChip(c: c, selected: _selectedCategory == c.id),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text('CURRENCY',
            style: PayPactTypography.label.copyWith(
                color: pt.ink3, letterSpacing: 1.4, fontSize: 10)),
        const SizedBox(height: 8),
        _WebCurrencyDropdown(
          selected: _selectedCurrency,
          onPick: (code) => setState(() => _selectedCurrency = code),
        ),
      ],
    );
  }

  Widget _webRightPanel(BuildContext context, PayPactThemeExtension pt) {
    final tones = PpCategoryDisc.tone(context, _catEnum(_selectedCategory));
    final cur = currencyOf(_selectedCurrency);
    final name = _nameCtrl.text.trim().isEmpty
        ? 'Your group name'
        : _nameCtrl.text.trim();
    final catLabel = _categories
        .firstWhere((c) => c.id == _selectedCategory,
            orElse: () => _categories.last)
        .label;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('COVER PREVIEW',
            style: PayPactTypography.label.copyWith(
                color: pt.ink3, letterSpacing: 1.6, fontSize: 10)),
        const SizedBox(height: 10),
        Container(
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [pt.accentSoft, tones[0]],
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(_selectedEmoji,
                    style: const TextStyle(fontSize: 56)),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Cover photos — coming soon'))),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: pt.bg.withValues(alpha: 0.9),
                      borderRadius: PayPactRadius.full,
                      border: Border.all(color: pt.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_camera_outlined,
                            size: 14, color: pt.ink2),
                        const SizedBox(width: 6),
                        Text('Replace cover',
                            style: PayPactTypography.bodySm.copyWith(
                                color: pt.ink2,
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: PayPactTypography.headingXl.copyWith(
                color: name == 'Your group name' ? pt.ink3 : pt.ink)),
        const SizedBox(height: 5),
        Text('$_selectedEmoji $catLabel · ${cur.code} · created today',
            style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: pt.surface,
            borderRadius: PayPactRadius.md,
            border: Border.all(color: pt.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.bolt_rounded, color: pt.accent, size: 15),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: PayPactTypography.bodySm
                        .copyWith(color: pt.ink2, height: 1.45),
                    children: [
                      TextSpan(
                          text: 'Tip: ',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: pt.ink)),
                      const TextSpan(
                          text:
                              "add a cover photo once you're done — PayPact can also auto-pick one based on the trip name."),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _webFooter(
      BuildContext context, PayPactThemeExtension pt, bool loading) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          PayPactButton(
            onPressed: () => context.pop(),
            label: 'Cancel',
            variant: PayPactButtonVariant.secondary,
            size: PayPactButtonSize.large,
          ),
          const Spacer(),
          PayPactButton(
            onPressed: loading ? null : _submit,
            label: loading ? 'Creating…' : 'Add members',
            variant: PayPactButtonVariant.accent,
            size: PayPactButtonSize.large,
            rightIcon: Icons.arrow_forward_rounded,
          ),
        ],
      ),
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

// ─────────────────────────────────────────────────────────────────────
// Web — currency dropdown (anchored menu, not a bottom sheet)
// ─────────────────────────────────────────────────────────────────────

class _WebCurrencyDropdown extends StatefulWidget {
  const _WebCurrencyDropdown({required this.selected, required this.onPick});
  final String selected;
  final ValueChanged<String> onPick;

  @override
  State<_WebCurrencyDropdown> createState() => _WebCurrencyDropdownState();
}

class _WebCurrencyDropdownState extends State<_WebCurrencyDropdown> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final cur = currencyOf(widget.selected);

    return MenuAnchor(
      onOpen: () => setState(() => _open = true),
      onClose: () => setState(() => _open = false),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(pt.surface),
        elevation: const WidgetStatePropertyAll(8),
        shadowColor:
            WidgetStatePropertyAll(Colors.black.withValues(alpha: 0.2)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: PayPactRadius.md,
          side: BorderSide(color: pt.border),
        )),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
      ),
      menuChildren: [
        for (final c in kCurrencies)
          MenuItemButton(
            onPressed: () => widget.onPick(c.code),
            style: ButtonStyle(
              backgroundColor: c.code == widget.selected
                  ? WidgetStatePropertyAll(pt.accentSoft)
                  : null,
              padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                  borderRadius: PayPactRadius.sm)),
            ),
            child: SizedBox(
              width: 352,
              child: Row(
                children: [
                  SizedBox(
                    width: 26,
                    child: Text(c.symbol,
                        style: PayPactTypography.amountMd
                            .copyWith(color: pt.ink, fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
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
                  if (c.code == widget.selected)
                    Icon(Icons.check_rounded, color: pt.accent, size: 16),
                ],
              ),
            ),
          ),
      ],
      builder: (context, controller, _) {
        return GestureDetector(
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: pt.surface,
              borderRadius: PayPactRadius.md,
              border:
                  Border.all(color: _open ? pt.accent : pt.border, width: _open ? 1.4 : 1),
            ),
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
                    style:
                        PayPactTypography.headingMd.copyWith(color: pt.ink)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cur.name,
                        style: PayPactTypography.bodyMd.copyWith(
                            color: pt.ink, fontWeight: FontWeight.w600)),
                    Text('${cur.code} · ${cur.symbol} symbol',
                        style: PayPactTypography.bodySm
                            .copyWith(color: pt.ink3)),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: _open ? 0.5 : 0,
                duration: const Duration(milliseconds: 150),
                child:
                    Icon(Icons.expand_more_rounded, color: pt.ink3, size: 20),
              ),
            ]),
          ),
        );
      },
    );
  }
}
