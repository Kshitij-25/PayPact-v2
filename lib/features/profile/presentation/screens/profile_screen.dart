import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/core/utils/responsive.dart';
import 'package:paypact/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:paypact/features/profile/presentation/bloc/settings_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Profile Screen
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ResponsiveCenter(
        maxWidth: 640,
        child: ListView(
          padding: EdgeInsets.all(Responsive.hPadding(context)),
          children: [
            // ── Avatar + name ──────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.4),
                    backgroundImage: user?.photoUrl != null
                        ? CachedNetworkImageProvider(user!.photoUrl!)
                        : null,
                    child: user?.photoUrl == null
                        ? Text(
                            user?.displayName.substring(0, 1).toUpperCase() ??
                                'U',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w600),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.displayName ?? '',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Settings group ─────────────────────────────────────────────
            _GroupLabel('Preferences'),
            const SizedBox(height: 8),
            _SettingsCard(children: [
              _SettingsTile(
                icon: Icons.notifications_outlined,
                iconColor: Theme.of(context).colorScheme.primary,
                title: 'Notifications',
                subtitle: Text('Expenses, settlements, invites'),
                onTap: () => _showSheet(context, _NotificationsSheet()),
              ),
              _Divider(),
              _SettingsTile(
                icon: Icons.palette_outlined,
                iconColor: const Color(0xFF8B5CF6),
                title: 'Appearance',
                subtitle: BlocBuilder<SettingsBloc, SettingsState>(
                  buildWhen: (p, c) => p.themeMode != c.themeMode,
                  builder: (_, s) => Text(_themeName(s.themeMode),
                      style: TextStyle(
                          fontSize: 13,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ),
                onTap: () => _showSheet(context, _AppearanceSheet()),
              ),
              _Divider(),
              _SettingsTile(
                icon: Icons.language_outlined,
                iconColor: Theme.of(context).colorScheme.secondary,
                title: 'Currency & Language',
                subtitle: BlocBuilder<SettingsBloc, SettingsState>(
                  buildWhen: (p, c) =>
                      p.currency != c.currency ||
                      p.languageCode != c.languageCode,
                  builder: (_, s) => Text(
                    '${s.currency} · ${_langName(s.languageCode)}',
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
                onTap: () => _showSheet(context, _CurrencyLanguageSheet()),
              ),
            ]),

            const SizedBox(height: 20),
            _GroupLabel('Legal'),
            const SizedBox(height: 8),
            _SettingsCard(children: [
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
                title: 'Privacy Policy',
                onTap: () {},
              ),
              _Divider(),
              _SettingsTile(
                icon: Icons.description_outlined,
                iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
                title: 'Terms of Service',
                onTap: () {},
              ),
            ]),

            const SizedBox(height: 20),
            _SettingsCard(children: [
              _SettingsTile(
                icon: Icons.logout,
                iconColor: Theme.of(context).colorScheme.error,
                title: 'Sign Out',
                titleColor: Theme.of(context).colorScheme.error,
                showChevron: false,
                onTap: () =>
                    context.read<AuthBloc>().add(AuthSignOutRequested()),
              ),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _themeName(ThemeMode m) => switch (m) {
        ThemeMode.system => 'System default',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  String _langName(String code) => switch (code) {
        'en' => 'English',
        'es' => 'Spanish',
        'fr' => 'French',
        'de' => 'German',
        'zh' => 'Chinese',
        'ja' => 'Japanese',
        'pt' => 'Portuguese',
        'ar' => 'Arabic',
        _ => code.toUpperCase(),
      };

  void _showSheet(BuildContext context, Widget sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<SettingsBloc>(),
        child: sheet,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0.8),
        ),
      );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Column(children: children),
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 52, endIndent: 0, thickness: 0.5);
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.showChevron = true,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? subtitle;
  final Color? titleColor;
  final bool showChevron;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: titleColor ?? Theme.of(context).colorScheme.onSurface),
      ),
      subtitle: subtitle,
      trailing: showChevron
          ? Icon(Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20)
          : null,
    );
  }
}

// shared bottom sheet shell
class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),
          Text(title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifications Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Notifications',
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (ctx, state) {
          final bloc = ctx.read<SettingsBloc>();
          return Column(
            children: [
              _NotifyTile(
                icon: Icons.receipt_outlined,
                title: 'New expense added',
                subtitle:
                    'Get notified when someone adds an expense to your group',
                value: state.notifyExpenseAdded,
                onChanged: (v) =>
                    bloc.add(SettingsNotifyExpenseAddedChanged(v)),
              ),
              const SizedBox(height: 8),
              _NotifyTile(
                icon: Icons.handshake_outlined,
                title: 'Settlement recorded',
                subtitle: 'Get notified when a debt is paid off',
                value: state.notifySettlement,
                onChanged: (v) => bloc.add(SettingsNotifySettlementChanged(v)),
              ),
              const SizedBox(height: 8),
              _NotifyTile(
                icon: Icons.group_add_outlined,
                title: 'Group invite',
                subtitle: 'Get notified when someone invites you to a group',
                value: state.notifyGroupInvite,
                onChanged: (v) => bloc.add(SettingsNotifyGroupInviteChanged(v)),
              ),
              const SizedBox(height: 8),
              _NotifyTile(
                icon: Icons.bar_chart_outlined,
                title: 'Weekly digest',
                subtitle: 'Receive a weekly summary of your group activity',
                value: state.notifyWeeklyDigest,
                onChanged: (v) =>
                    bloc.add(SettingsNotifyWeeklyDigestChanged(v)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotifyTile extends StatelessWidget {
  const _NotifyTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        secondary: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: (value ? cs.primary : cs.onSurfaceVariant)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon,
              size: 18, color: value ? cs.primary : cs.onSurfaceVariant),
        ),
        title: Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        value: value,
        activeThumbColor: cs.primary,
        onChanged: onChanged,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Appearance Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AppearanceSheet extends StatelessWidget {
  static const _modes = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];

  static String _label(ThemeMode m) => switch (m) {
        ThemeMode.system => 'System default',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  static String _description(ThemeMode m) => switch (m) {
        ThemeMode.system => 'Follow your device\'s appearance setting',
        ThemeMode.light => 'Always use light mode',
        ThemeMode.dark => 'Always use dark mode',
      };

  static IconData _icon(ThemeMode m) => switch (m) {
        ThemeMode.system => Icons.brightness_auto_outlined,
        ThemeMode.light => Icons.light_mode_outlined,
        ThemeMode.dark => Icons.dark_mode_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _SheetShell(
      title: 'Appearance',
      child: BlocBuilder<SettingsBloc, SettingsState>(
        buildWhen: (p, c) => p.themeMode != c.themeMode,
        builder: (ctx, state) {
          return Column(
            children: _modes.map((mode) {
              final selected = state.themeMode == mode;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => ctx
                      .read<SettingsBloc>()
                      .add(SettingsThemeModeChanged(mode)),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? cs.primary : cs.outline,
                        width: selected ? 2 : 1,
                      ),
                      color:
                          selected ? cs.primary.withValues(alpha: 0.05) : null,
                    ),
                    child: Row(children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            color: (selected ? cs.primary : cs.onSurfaceVariant)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: Icon(_icon(mode),
                            size: 18,
                            color: selected ? cs.primary : cs.onSurfaceVariant),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_label(mode),
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        selected ? cs.primary : cs.onSurface)),
                            const SizedBox(height: 2),
                            Text(_description(mode),
                                style: TextStyle(
                                    fontSize: 12, color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      if (selected)
                        Icon(Icons.check_circle, color: cs.primary, size: 20),
                    ]),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Currency & Language Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CurrencyLanguageSheet extends StatelessWidget {
  static const _currencies = [
    ('USD', 'US Dollar', '\$'),
    ('EUR', 'Euro', '€'),
    ('GBP', 'British Pound', '£'),
    ('JPY', 'Japanese Yen', '¥'),
    ('AUD', 'Australian Dollar', 'A\$'),
    ('CAD', 'Canadian Dollar', 'C\$'),
    ('CHF', 'Swiss Franc', 'Fr'),
    ('INR', 'Indian Rupee', '₹'),
    ('BRL', 'Brazilian Real', 'R\$'),
    ('MXN', 'Mexican Peso', 'MX\$'),
    ('SGD', 'Singapore Dollar', 'S\$'),
    ('HKD', 'Hong Kong Dollar', 'HK\$'),
    ('NOK', 'Norwegian Krone', 'kr'),
    ('SEK', 'Swedish Krona', 'kr'),
    ('DKK', 'Danish Krone', 'kr'),
  ];

  static const _languages = [
    ('en', 'English', '🇬🇧'),
    ('es', 'Spanish', '🇪🇸'),
    ('fr', 'French', '🇫🇷'),
    ('de', 'German', '🇩🇪'),
    ('zh', 'Chinese', '🇨🇳'),
    ('ja', 'Japanese', '🇯🇵'),
    ('pt', 'Portuguese', '🇵🇹'),
    ('ar', 'Arabic', '🇸🇦'),
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: BlocBuilder<SettingsBloc, SettingsState>(
          buildWhen: (p, c) =>
              p.currency != c.currency || p.languageCode != c.languageCode,
          builder: (ctx, state) {
            final bloc = ctx.read<SettingsBloc>();
            return CustomScrollView(
              controller: scrollCtrl,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                                borderRadius: BorderRadius.circular(2)),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text('Currency & Language',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color:
                                    Theme.of(context).colorScheme.onSurface)),
                        const SizedBox(height: 24),
                        // ── Currency section ──────────────────────────
                        _SectionLabel('Currency'),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final (code, name, symbol) = _currencies[i];
                      final selected = state.currency == code;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                        child: _SelectTile(
                          leading: Text(symbol,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface)),
                          title: name,
                          subtitle: code,
                          selected: selected,
                          onTap: () => bloc.add(SettingsCurrencyChanged(code)),
                        ),
                      );
                    },
                    childCount: _currencies.length,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 10),
                    child: _SectionLabel('Language'),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final (code, name, flag) = _languages[i];
                      final selected = state.languageCode == code;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                        child: _SelectTile(
                          leading:
                              Text(flag, style: const TextStyle(fontSize: 20)),
                          title: name,
                          subtitle: null,
                          selected: selected,
                          onTap: () => bloc.add(SettingsLanguageChanged(code)),
                        ),
                      );
                    },
                    childCount: _languages.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.8),
      );
}

class _SelectTile extends StatelessWidget {
  const _SelectTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final Widget leading;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : cs.outline,
            width: selected ? 2 : 1,
          ),
          color: selected
              ? cs.primary.withValues(alpha: 0.05)
              : Theme.of(context).cardColor,
        ),
        child: Row(children: [
          SizedBox(width: 32, child: Center(child: leading)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: selected ? cs.primary : cs.onSurface)),
                if (subtitle != null)
                  Text(subtitle!,
                      style:
                          TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          if (selected) Icon(Icons.check_circle, color: cs.primary, size: 18),
        ]),
      ),
    );
  }
}
