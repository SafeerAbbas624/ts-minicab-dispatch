import 'package:flutter/material.dart';

/// Simple (icon, label) pair — enough to build both a [NavigationBar]
/// destination (mobile/bottom) and a [NavigationRail] destination (desktop/
/// side) from the same list, since those two widgets take different
/// destination types.
class NavItem {
  const NavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Sub-tab navigation that renders as a bottom [NavigationBar] on phone-width
/// screens (matching the native app) and a side [NavigationRail] on wider
/// (desktop/web) screens, so the web build stops looking like the mobile app
/// stretched into a browser window. Content also gets capped to
/// [maxContentWidth] and centered on wide screens — an edge-to-edge list on
/// an ultrawide monitor reads as an unfinished app, not a website.
class ResponsiveNavScaffold extends StatelessWidget {
  const ResponsiveNavScaffold({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.destinations,
    required this.body,
    this.floatingActionButton,
    this.maxContentWidth = 1100,
  });

  static const double desktopBreakpoint = 900;

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<NavItem> destinations;
  final Widget body;
  final Widget? floatingActionButton;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= desktopBreakpoint;

    final content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isDesktop ? maxContentWidth : double.infinity),
      child: body,
    );
    final positionedContent = isDesktop ? Align(alignment: Alignment.topCenter, child: content) : content;

    if (!isDesktop) {
      return Stack(
        children: [
          Column(
            children: [
              Expanded(child: positionedContent),
              NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: onSelect,
                destinations: [
                  for (final d in destinations) NavigationDestination(icon: Icon(d.icon), label: d.label),
                ],
              ),
            ],
          ),
          if (floatingActionButton != null)
            Positioned(right: 16, bottom: 110, child: floatingActionButton!),
        ],
      );
    }

    return Stack(
      children: [
        Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelect,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(icon: Icon(d.icon), label: Text(d.label)),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: positionedContent),
          ],
        ),
        if (floatingActionButton != null)
          Positioned(right: 24, bottom: 24, child: floatingActionButton!),
      ],
    );
  }
}
