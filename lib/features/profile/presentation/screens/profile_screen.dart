import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/core/constants/locale_constant.dart';
import 'package:paypact/core/theme/paypact_theme_extension.dart';
import 'package:paypact/core/utils/responsive.dart';
import 'package:paypact/features/profile/presentation/bloc/settings_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data — sourced from the shared locale_constants.dart
// ─────────────────────────────────────────────────────────────────────────────

// Aliases for readability inside this file
const _currencies = kSupportedCurrencies;
const _languages = kSupportedLanguages;

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (ctx, s) => ResponsiveCenter(
          maxWidth: 720,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // ── Notifications ─────────────────────────────────────────────
              _SectionHeader('Notifications', Icons.notifications_outlined,
                  context.pt.primary),
              _ToggleTile(
                title: 'Expense added',
                subtitle: 'When a new expense is added to your group',
                value: s.notifyExpenseAdded,
                onChanged: (v) => ctx
                    .read<SettingsBloc>()
                    .add(SettingsNotifyExpenseAddedChanged(v)),
              ),
              _ToggleTile(
                title: 'Settlement recorded',
                subtitle: 'When someone marks a debt as settled',
                value: s.notifySettlement,
                onChanged: (v) => ctx
                    .read<SettingsBloc>()
                    .add(SettingsNotifySettlementChanged(v)),
              ),
              _ToggleTile(
                title: 'Group invites',
                subtitle: 'When you are added to a new group',
                value: s.notifyGroupInvite,
                onChanged: (v) => ctx
                    .read<SettingsBloc>()
                    .add(SettingsNotifyGroupInviteChanged(v)),
              ),
              _ToggleTile(
                title: 'Weekly digest',
                subtitle: 'Summary of your open balances every Monday',
                value: s.notifyWeeklyDigest,
                onChanged: (v) => ctx
                    .read<SettingsBloc>()
                    .add(SettingsNotifyWeeklyDigestChanged(v)),
              ),

              const SizedBox(height: 8),

              // ── Appearance ────────────────────────────────────────────────
              _SectionHeader(
                  'Appearance', Icons.palette_outlined, context.pt.warning),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Theme',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.pt.textSecondary)),
                    const SizedBox(height: 10),
                    Row(
                      children: ThemeMode.values.map((mode) {
                        final selected = s.themeMode == mode;
                        final label = switch (mode) {
                          ThemeMode.system => 'System',
                          ThemeMode.light => 'Light',
                          ThemeMode.dark => 'Dark',
                        };
                        final icon = switch (mode) {
                          ThemeMode.system => Icons.brightness_auto_outlined,
                          ThemeMode.light => Icons.light_mode_outlined,
                          ThemeMode.dark => Icons.dark_mode_outlined,
                        };
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => ctx
                                .read<SettingsBloc>()
                                .add(SettingsThemeModeChanged(mode)),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: EdgeInsets.only(
                                  right: mode != ThemeMode.dark ? 8 : 0),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: selected
                                    ? context.pt.primary
                                    : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? context.pt.primary
                                      : context.pt.divider,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon,
                                      size: 22,
                                      color: selected
                                          ? Colors.white
                                          : context.pt.textSecondary),
                                  const SizedBox(height: 6),
                                  Text(label,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: selected
                                              ? Colors.white
                                              : context.pt.textSecondary)),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Currency ──────────────────────────────────────────────────
              _SectionHeader('Currency & Language', Icons.language_outlined,
                  context.pt.secondary),
              _PickerTile(
                icon: Icons.currency_exchange_outlined,
                title: 'Default currency',
                value: () {
                  final match =
                      _currencies.where((c) => c.$1 == s.currency).firstOrNull;
                  return match != null
                      ? '${match.$3}  ${match.$2}'
                      : s.currency;
                }(),
                onTap: () => _showCurrencyPicker(ctx, s.currency),
              ),
              _PickerTile(
                icon: Icons.translate_outlined,
                title: 'Language',
                value: () {
                  final match = _languages
                      .where((l) => l.$1 == s.languageCode)
                      .firstOrNull;
                  return match != null
                      ? '${match.$3}  ${match.$2}'
                      : s.languageCode;
                }(),
                onTap: () => _showLanguagePicker(ctx, s.languageCode),
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext ctx, String current) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: ctx.read<SettingsBloc>(),
        child: _SearchPickerSheet(
          title: 'Select Currency',
          items: _currencies
              .map((c) => _PickerItem(
                    code: c.$1,
                    label: c.$2,
                    prefix: c.$3,
                    selected: c.$1 == current,
                  ))
              .toList(),
          onSelected: (code) =>
              ctx.read<SettingsBloc>().add(SettingsCurrencyChanged(code)),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext ctx, String current) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: ctx.read<SettingsBloc>(),
        child: _SearchPickerSheet(
          title: 'Select Language',
          items: _languages
              .map((l) => _PickerItem(
                    code: l.$1,
                    label: l.$2,
                    prefix: l.$3,
                    selected: l.$1 == current,
                  ))
              .toList(),
          onSelected: (code) =>
              ctx.read<SettingsBloc>().add(SettingsLanguageChanged(code)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, this.icon, this.color);
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Text(title.toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.8)),
        ]),
      );
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: context.pt.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        title: Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 12, color: context.pt.textSecondary)),
      );
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: context.pt.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: context.pt.secondary),
        ),
        title: Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        subtitle: Text(value,
            style: TextStyle(fontSize: 13, color: context.pt.textSecondary)),
        trailing: Icon(Icons.chevron_right, color: context.pt.textSecondary),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Search picker bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _PickerItem {
  const _PickerItem({
    required this.code,
    required this.label,
    required this.prefix,
    required this.selected,
  });
  final String code;
  final String label;
  final String prefix;
  final bool selected;
}

class _SearchPickerSheet extends StatefulWidget {
  const _SearchPickerSheet({
    required this.title,
    required this.items,
    required this.onSelected,
  });
  final String title;
  final List<_PickerItem> items;
  final ValueChanged<String> onSelected;

  @override
  State<_SearchPickerSheet> createState() => _SearchPickerSheetState();
}

class _SearchPickerSheetState extends State<_SearchPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<_PickerItem> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    _searchCtrl.addListener(_filter);
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = widget.items
          .where((i) =>
              i.label.toLowerCase().contains(q) ||
              i.code.toLowerCase().contains(q))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(children: [
        // Handle
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Expanded(
              child: Text(widget.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ]),
        ),
        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search…',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        // List
        Expanded(
          child: ListView.builder(
            itemCount: _filtered.length,
            itemBuilder: (_, i) {
              final item = _filtered[i];
              return ListTile(
                leading:
                    Text(item.prefix, style: const TextStyle(fontSize: 20)),
                title: Text(item.label,
                    style: TextStyle(
                        fontWeight:
                            item.selected ? FontWeight.w700 : FontWeight.w400)),
                subtitle: Text(item.code,
                    style: TextStyle(
                        fontSize: 12, color: context.pt.textSecondary)),
                trailing: item.selected
                    ? Icon(Icons.check_circle, color: context.pt.primary)
                    : null,
                onTap: () {
                  widget.onSelected(item.code);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
