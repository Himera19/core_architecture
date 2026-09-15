import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../utils/extensions/context_extensions.dart';

/// Reusable bottom navigation bar widget
/// Projects should pass their own navigation items and routes
class Navbar extends StatelessWidget {
  final Widget child;
  final List<NavigationItem> items;
  final String Function(String) getCurrentRoute;

  const Navbar({
    super.key,
    required this.child,
    required this.items,
    required this.getCurrentRoute,
  });

  int _getCurrentIndex(String location) {
    final route = getCurrentRoute(location);
    final index = items.indexWhere((item) => item.route == route);
    return index >= 0 ? index : 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    context.go(items[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colorScheme;
    final TextTheme textTheme = context.textTheme;
    final String location = GoRouterState.of(context).uri.toString();

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _getCurrentIndex(location),
        onTap: (index) => _onItemTapped(context, index),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.onSurfaceVariant,
        selectedLabelStyle: textTheme.labelMedium?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.labelMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
        items: items
            .map((item) => BottomNavigationBarItem(
          icon: Icon(item.icon),
          activeIcon: Icon(item.activeIcon ?? item.icon),
          label: item.label,
        ))
            .toList(),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final String route;

  const NavigationItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.route,
  });
}
