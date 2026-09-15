import 'package:flutter/widgets.dart';

import 'app_breakpoints.dart';

/// A widget that rebuilds its child based on the current [WindowSizeClass].
///
/// Provide builders for each breakpoint. Falls back to smaller breakpoints
/// if a specific builder is not provided.
///
/// ```dart
/// ResponsiveBuilder(
///   compact: (context) => MobileLayout(),
///   medium: (context) => TabletLayout(),
///   expanded: (context) => DesktopLayout(),
/// )
/// ```
class ResponsiveBuilder extends StatelessWidget {
  /// Required — layout for phones (< 600dp).
  final Widget Function(BuildContext context) compact;

  /// Optional — layout for tablets (600–840dp). Falls back to [compact].
  final Widget Function(BuildContext context)? medium;

  /// Optional — layout for small desktops (840–1200dp). Falls back to [medium] → [compact].
  final Widget Function(BuildContext context)? expanded;

  /// Optional — layout for large desktops (≥ 1200dp). Falls back to [expanded] → [medium] → [compact].
  final Widget Function(BuildContext context)? large;

  const ResponsiveBuilder({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
    this.large,
  });

  @override
  Widget build(BuildContext context) {
    final sizeClass = AppBreakpoints.of(context);

    return switch (sizeClass) {
      WindowSizeClass.large => (large ?? expanded ?? medium ?? compact)(context),
      WindowSizeClass.expanded => (expanded ?? medium ?? compact)(context),
      WindowSizeClass.medium => (medium ?? compact)(context),
      WindowSizeClass.compact => compact(context),
    };
  }
}

/// Extension on [BuildContext] for responsive utilities.
extension ResponsiveContext on BuildContext {
  /// Get the current [WindowSizeClass].
  WindowSizeClass get windowSizeClass => AppBreakpoints.of(this);

  /// Screen width in logical pixels.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Screen height in logical pixels.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Whether the screen is compact (phone).
  bool get isCompact => windowSizeClass == WindowSizeClass.compact;

  /// Whether the screen is medium (tablet portrait).
  bool get isMedium => windowSizeClass == WindowSizeClass.medium;

  /// Whether the screen is expanded (tablet landscape / small desktop).
  bool get isExpanded => windowSizeClass == WindowSizeClass.expanded;

  /// Whether the screen is large (desktop).
  bool get isLarge => windowSizeClass == WindowSizeClass.large;

  /// Whether the current layout should show mobile-style navigation (bottom nav).
  bool get isMobileNavigation =>
      windowSizeClass == WindowSizeClass.compact;

  /// Whether the current layout should show desktop-style navigation (rail/drawer).
  bool get isDesktopNavigation =>
      windowSizeClass == WindowSizeClass.expanded ||
      windowSizeClass == WindowSizeClass.large;

  /// Select a value based on the current breakpoint.
  ///
  /// ```dart
  /// final columns = context.responsive<int>(
  ///   compact: 1,
  ///   medium: 2,
  ///   expanded: 3,
  ///   large: 4,
  /// );
  /// ```
  T responsive<T>({
    required T compact,
    T? medium,
    T? expanded,
    T? large,
  }) {
    return switch (windowSizeClass) {
      WindowSizeClass.large => large ?? expanded ?? medium ?? compact,
      WindowSizeClass.expanded => expanded ?? medium ?? compact,
      WindowSizeClass.medium => medium ?? compact,
      WindowSizeClass.compact => compact,
    };
  }
}
