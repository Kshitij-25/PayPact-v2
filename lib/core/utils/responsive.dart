import 'package:flutter/material.dart';

/// Breakpoints matching Material Design adaptive layout guidelines.
///   mobile  :  0 – 599 dp   (phone portrait / small phone landscape)
///   tablet  :  600 – 1023 dp (tablet, large phone landscape)
///   desktop :  1024 dp +      (desktop, large tablet)
class Responsive {
  Responsive._();

  static const double _tabletBreak = 600;
  static const double _desktopBreak = 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < _tabletBreak;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= _tabletBreak && w < _desktopBreak;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= _desktopBreak;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= _tabletBreak;

  /// Horizontal content padding that scales with screen width.
  static double hPadding(BuildContext context) {
    if (isDesktop(context)) return 40;
    if (isTablet(context)) return 28;
    return 20;
  }

  /// Max content width for centered layouts on large screens.
  static double maxContentWidth(BuildContext context) {
    if (isDesktop(context)) return 900;
    if (isTablet(context)) return 720;
    return double.infinity;
  }
}

/// Wraps [child] in a centered, max-width constrained box on tablet/desktop.
/// On mobile it renders [child] as-is with no extra constraints.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  final Widget child;

  /// Defaults to [Responsive.maxContentWidth] if not provided.
  final double? maxWidth;

  /// Extra padding applied inside the center container.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return padding != null ? Padding(padding: padding!, child: child) : child;
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? Responsive.maxContentWidth(context),
        ),
        child:
            padding != null ? Padding(padding: padding!, child: child) : child,
      ),
    );
  }
}

/// Adaptive scaffold navigation:
///   mobile  → [bottomBar]
///   tablet+ → [NavigationRail] on the left
///
/// Provide [destinations] that map to both nav rail and bottom bar items.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AdaptiveDestination> destinations;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isWide(context);
    final isDesktop = Responsive.isDesktop(context);

    if (isWide) {
      return Scaffold(
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              // extended and labelType are mutually exclusive:
              // when extended=true, labelType must be null (labels are shown inline).
              labelType: isDesktop
                  ? null
                  : NavigationRailLabelType.selected,
              minWidth: isDesktop ? 200 : 72,
              extended: isDesktop,
              destinations: destinations
                  .map((d) => NavigationRailDestination(
                        icon: d.icon,
                        selectedIcon: d.selectedIcon ?? d.icon,
                        label: Text(d.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onDestinationSelected,
        items: destinations
            .map((d) => BottomNavigationBarItem(
                  icon: d.icon,
                  activeIcon: d.selectedIcon ?? d.icon,
                  label: d.label,
                ))
            .toList(),
      ),
    );
  }
}

class AdaptiveDestination {
  const AdaptiveDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });

  final Widget icon;
  final Widget? selectedIcon;
  final String label;
}
