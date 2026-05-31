import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paypact/core/utils/responsive.dart';
import 'package:paypact/design_system/components/paypact_bottom_nav.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:paypact/features/group/presentation/cubit/groups_cubit.dart';
import 'package:paypact/widgets/pp_atoms.dart';

const double _sidebarW = 264;

/// Scaffold that swaps between bottom nav (phone), a compact NavigationRail
/// (tablet ≥600px), and a full web sidebar + topbar (desktop ≥900px).
class AdaptiveNavScaffold extends StatelessWidget {
  const AdaptiveNavScaffold({
    super.key,
    required this.currentIndex,
    required this.onNavTap,
    required this.onFabTap,
    required this.body,
    this.backgroundColor,
    // Web shell metadata — used only on desktop
    this.webEyebrow,
    this.webTitle,
    this.webSubtitle,
    this.webActionLabel,
    this.webActionOnTap,
    this.webUserName = 'You',
    this.webUserHandle = '',
    this.webBalance = '',
    this.webBalancePositive = true,
    this.onInsightsTap,
    this.onNotificationsTap,
    this.onSettingsTap,
    this.webActiveId,
    this.notificationCount = 0,
    this.groupCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onNavTap;
  final VoidCallback onFabTap;
  final Widget body;
  final Color? backgroundColor;

  // Web sidebar / topbar
  final String? webEyebrow;
  final String? webTitle;
  final String? webSubtitle;
  final String? webActionLabel;
  final VoidCallback? webActionOnTap;
  final String webUserName;
  final String webUserHandle;
  final String webBalance;
  final bool webBalancePositive;
  final VoidCallback? onInsightsTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onSettingsTap;
  // Override active sidebar item (e.g. 'insights', 'notifications')
  final String? webActiveId;
  final int notificationCount;
  final int groupCount;

  static const _destinations = [
    NavigationRailDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: Text('Home'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.group_outlined),
      selectedIcon: Icon(Icons.group_rounded),
      label: Text('Groups'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.show_chart_rounded),
      selectedIcon: Icon(Icons.show_chart_rounded),
      label: Text('Activity'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: Text('You'),
    ),
  ];

  String get _sidebarActiveId {
    if (webActiveId != null) return webActiveId!;
    return ['home', 'groups', 'activity', 'profile'][currentIndex];
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final bg = backgroundColor ?? pt.bg;

    if (context.isPhone) {
      return Scaffold(
        backgroundColor: bg,
        bottomNavigationBar: PayPactBottomNav(
          currentIndex: currentIndex,
          onTap: onNavTap,
          onFabTap: onFabTap,
        ),
        body: body,
      );
    }

    if (context.isTablet) {
      return Scaffold(
        backgroundColor: bg,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: onNavTap,
              extended: false,
              minWidth: 72,
              backgroundColor: pt.surface,
              useIndicator: true,
              indicatorColor: pt.accentSoft,
              selectedIconTheme: IconThemeData(color: pt.accent),
              unselectedIconTheme: IconThemeData(color: pt.ink3),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: GestureDetector(
                  onTap: onFabTap,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: pt.accent,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
              destinations: _destinations,
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    // ── Desktop: full web sidebar + topbar ──────────────────────────────
    // Derive the workspace net balance + identity from the globally-provided
    // cubits so the sidebar is consistent on every screen, falling back to the
    // explicit props when a screen supplies them or the cubit isn't ready.
    final groupsState = context.watch<GroupsCubit>().state;
    final authState = context.watch<AuthCubit>().state;

    final String sidebarBalance;
    final bool sidebarOwe;
    final bool sidebarSettled;
    final int sidebarGroupCount;
    if (groupsState is GroupsLoaded) {
      final t = groupsState.totalNetBalance;
      sidebarBalance = PpAmount.format(t.abs().round());
      sidebarOwe = t < -0.5;
      sidebarSettled = t.abs() <= 0.5;
      sidebarGroupCount = groupsState.groups.length;
    } else {
      sidebarBalance = webBalance.replaceAll(RegExp(r'^[+\-−]'), '');
      sidebarOwe = !webBalancePositive;
      sidebarSettled = webBalance.isEmpty;
      sidebarGroupCount = groupCount;
    }

    final sidebarUserName =
        authState is AuthAuthenticated ? authState.user.name : webUserName;
    final sidebarUserHandle = authState is AuthAuthenticated
        ? '@${authState.user.name.split(' ').first.toLowerCase()}'
        : webUserHandle;

    return Scaffold(
      backgroundColor: bg,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WebSidebar(
            activeId: _sidebarActiveId,
            currentIndex: currentIndex,
            onNavTap: onNavTap,
            onFabTap: onFabTap,
            onInsightsTap: onInsightsTap,
            onNotificationsTap: onNotificationsTap,
            onSettingsTap: onSettingsTap,
            userName: sidebarUserName,
            userHandle: sidebarUserHandle,
            balance: sidebarBalance,
            balanceOwe: sidebarOwe,
            balanceSettled: sidebarSettled,
            notificationCount: notificationCount,
            groupCount: sidebarGroupCount,
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (webTitle != null)
                  _WebTopBar(
                    eyebrow: webEyebrow,
                    title: webTitle!,
                    subtitle: webSubtitle,
                    actionLabel: webActionLabel,
                    actionOnTap: webActionOnTap,
                  ),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Web Sidebar
// ─────────────────────────────────────────────────────────────────────────────

class _WebSidebar extends StatelessWidget {
  const _WebSidebar({
    required this.activeId,
    required this.currentIndex,
    required this.onNavTap,
    required this.onFabTap,
    required this.userName,
    required this.userHandle,
    required this.balance,
    required this.balanceOwe,
    required this.balanceSettled,
    required this.notificationCount,
    required this.groupCount,
    this.onInsightsTap,
    this.onNotificationsTap,
    this.onSettingsTap,
  });

  final String activeId;
  final int currentIndex;
  final ValueChanged<int> onNavTap;
  final VoidCallback onFabTap;
  final String userName;
  final String userHandle;
  final String balance;
  final bool balanceOwe;
  final bool balanceSettled;
  final int notificationCount;
  final int groupCount;
  final VoidCallback? onInsightsTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;

    return Container(
      width: _sidebarW,
      color: pt.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  _SidebarLogo(pt: pt),
                  const SizedBox(height: 20),

                  // Balance widget
                  if (balance.isNotEmpty) ...[
                    _BalanceCard(
                      balance: balance,
                      owe: balanceOwe,
                      settled: balanceSettled,
                      groupCount: groupCount,
                      pt: pt,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Workspace label
                  Padding(
                    padding: const EdgeInsets.only(left: 14, bottom: 8),
                    child: Text(
                      'WORKSPACE',
                      style: GoogleFonts.geistMono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.12 * 9.5,
                        color: pt.ink3,
                      ),
                    ),
                  ),

                  // Primary nav
                  _SidebarItem(
                    id: 'home',
                    activeId: activeId,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                    onTap: () => onNavTap(0),
                    pt: pt,
                  ),
                  _SidebarItem(
                    id: 'groups',
                    activeId: activeId,
                    icon: Icons.group_outlined,
                    activeIcon: Icons.group_rounded,
                    label: 'Groups',
                    count: groupCount > 0 ? groupCount : null,
                    onTap: () => onNavTap(1),
                    pt: pt,
                  ),
                  _SidebarItem(
                    id: 'activity',
                    activeId: activeId,
                    icon: Icons.show_chart_rounded,
                    activeIcon: Icons.show_chart_rounded,
                    label: 'Activity',
                    onTap: () => onNavTap(2),
                    pt: pt,
                  ),
                  _SidebarItem(
                    id: 'insights',
                    activeId: activeId,
                    icon: Icons.pie_chart_outline_rounded,
                    activeIcon: Icons.pie_chart_rounded,
                    label: 'Insights',
                    onTap: onInsightsTap ?? () {},
                    pt: pt,
                  ),
                  _SidebarItem(
                    id: 'notifications',
                    activeId: activeId,
                    icon: Icons.notifications_outlined,
                    activeIcon: Icons.notifications_rounded,
                    label: 'Notifications',
                    count: notificationCount > 0 ? notificationCount : null,
                    onTap: onNotificationsTap ?? () {},
                    pt: pt,
                  ),

                  const SizedBox(height: 20),

                  // Secondary nav
                  _SidebarItem(
                    id: 'profile',
                    activeId: activeId,
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
                    onTap: () => onNavTap(3),
                    pt: pt,
                  ),
                  _SidebarItem(
                    id: 'settings',
                    activeId: activeId,
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings_rounded,
                    label: 'Settings',
                    onTap: onSettingsTap ?? () {},
                    pt: pt,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // User block
          _SidebarUserBlock(
            userName: userName,
            userHandle: userHandle,
            pt: pt,
          ),
        ],
      ),
    );
  }
}

class _SidebarLogo extends StatelessWidget {
  const _SidebarLogo({required this.pt});
  final PayPactThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Row(
        children: [
          CustomPaint(
            size: const Size(28, 28),
            painter: _LogoPainter(accent: pt.accent, ink: pt.ink),
          ),
          const SizedBox(width: 11),
          Text(
            'PayPact',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.02 * 20,
              color: pt.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter({required this.accent, required this.ink});
  final Color accent;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    paint.color = accent;
    canvas.drawCircle(Offset(size.width * 0.38, size.height / 2), size.width * 0.25, paint);

    paint.color = ink;
    canvas.drawCircle(Offset(size.width * 0.62, size.height / 2), size.width * 0.25, paint);
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.accent != accent || old.ink != ink;
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.owe,
    required this.settled,
    required this.groupCount,
    required this.pt,
  });
  final String balance;
  final bool owe;
  final bool settled;
  final int groupCount;
  final PayPactThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final balanceColor =
        settled ? pt.ink2 : (owe ? pt.negative : pt.positive);
    final eyebrow =
        settled ? 'NET BALANCE' : (owe ? 'YOU OWE' : "YOU'RE OWED");
    final groupsLabel =
        groupCount > 0 ? 'across $groupCount groups' : 'across your groups';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: pt.bg,
        borderRadius: PayPactRadius.md,
        border: Border.all(color: pt.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: GoogleFonts.geistMono(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.12 * 9.5,
              color: settled ? pt.ink3 : balanceColor,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  settled ? 'Settled up' : balance,
                  style: GoogleFonts.geistMono(
                    fontSize: settled ? 18 : 22,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.02 * 22,
                    color: balanceColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (!settled)
                Icon(
                    owe
                        ? Icons.trending_down_rounded
                        : Icons.trending_up_rounded,
                    size: 14,
                    color: balanceColor),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            settled ? 'across your groups' : groupsLabel,
            style: GoogleFonts.geist(
              fontSize: 11,
              color: pt.ink3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.id,
    required this.activeId,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
    required this.pt,
    this.count,
  });

  final String id;
  final String activeId;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;
  final PayPactThemeExtension pt;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final isActive = id == activeId;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isActive ? pt.ink : Colors.transparent,
          borderRadius: PayPactRadius.md,
        ),
        child: Row(
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 18,
              color: isActive ? const Color(0xFFFAF7F1) : pt.ink2,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.geist(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: -0.005 * 14,
                  color: isActive ? const Color(0xFFFAF7F1) : pt.ink2,
                ),
              ),
            ),
            if (count != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0x26FAF7F1)
                      : pt.surfaceAlt,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.geistMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? const Color(0xFFFAF7F1) : pt.ink3,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SidebarUserBlock extends StatelessWidget {
  const _SidebarUserBlock({
    required this.userName,
    required this.userHandle,
    required this.pt,
  });

  final String userName;
  final String userHandle;
  final PayPactThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: pt.bg,
        borderRadius: PayPactRadius.md,
        border: Border.all(color: pt.border),
      ),
      child: Row(
        children: [
          PpAvatar(name: userName.isEmpty ? 'You' : userName, size: 34),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userName.isEmpty ? 'You' : userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.geist(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: pt.ink,
                  ),
                ),
                if (userHandle.isNotEmpty)
                  Text(
                    userHandle,
                    style: GoogleFonts.geistMono(
                      fontSize: 11,
                      color: pt.ink3,
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 14, color: pt.ink3),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Web TopBar
// ─────────────────────────────────────────────────────────────────────────────

class _WebTopBar extends StatelessWidget {
  const _WebTopBar({
    this.eyebrow,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.actionOnTap,
  });

  final String? eyebrow;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? actionOnTap;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: title block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!,
                    style: GoogleFonts.geistMono(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.12 * 10.5,
                      color: pt.accent,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.028 * 36,
                    height: 1.05,
                    color: pt.ink,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: GoogleFonts.geist(
                      fontSize: 15,
                      color: pt.ink2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 32),

          // Right: search + bell + CTA
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                // Search pill
                Container(
                  height: 44,
                  width: 280,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: pt.surface,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: pt.border),
                    boxShadow: pt.shadowSm,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, size: 16, color: pt.ink3),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Search…',
                          style: GoogleFonts.geist(
                            fontSize: 13.5,
                            color: pt.ink3,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: pt.surfaceAlt,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '⌘ K',
                          style: GoogleFonts.geistMono(
                            fontSize: 10,
                            color: pt.ink3,
                            letterSpacing: 0.05 * 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Bell button
                Stack(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: pt.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: pt.border),
                        boxShadow: pt.shadowSm,
                      ),
                      child: Icon(Icons.notifications_outlined,
                          size: 18, color: pt.ink2),
                    ),
                    Positioned(
                      top: 11,
                      right: 12,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: pt.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: pt.surface, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),

                // CTA button
                if (actionLabel != null) ...[
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: actionOnTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: pt.accent,
                      foregroundColor: const Color(0xFFFAF7F1),
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(
                      actionLabel!,
                      style: GoogleFonts.geist(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
