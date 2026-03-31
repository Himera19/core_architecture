import 'package:flutter/widgets.dart';

/// Material 3 Window Size Classes
///
/// Based on Material Design 3 responsive layout guidelines:
/// https://m3.material.io/foundations/layout/applying-layout
///
/// These breakpoints define how the UI should adapt across devices:
/// - **compact**: Phones in portrait (< 600dp)
/// - **medium**: Tablets in portrait, foldables (600–840dp)
/// - **expanded**: Tablets in landscape, small desktops (840–1200dp)
/// - **large**: Desktops, wide screens (≥ 1200dp)
enum WindowSizeClass { compact, medium, expanded, large }

final class AppBreakpoints {
  AppBreakpoints._();

  /// Breakpoint thresholds (in logical pixels)
  static const double compact = 0;
  static const double medium = 600;
  static const double expanded = 840;
  static const double large = 1200;

  /// Get the current [WindowSizeClass] for the given width.
  static WindowSizeClass fromWidth(double width) {
    if (width >= large) return WindowSizeClass.large;
    if (width >= expanded) return WindowSizeClass.expanded;
    if (width >= medium) return WindowSizeClass.medium;
    return WindowSizeClass.compact;
  }

  /// Get the current [WindowSizeClass] from [BuildContext].
  static WindowSizeClass of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return fromWidth(width);
  }

  // ==================== Layout Recommendations ====================

  /// Recommended content max width (for centering content on large screens)
  static const double maxContentWidth = 1200;

  /// Recommended number of grid columns per breakpoint
  static int columns(WindowSizeClass sizeClass) {
    return switch (sizeClass) {
      WindowSizeClass.compact => 4,
      WindowSizeClass.medium => 8,
      WindowSizeClass.expanded => 12,
      WindowSizeClass.large => 12,
    };
  }

  /// Recommended body margin per breakpoint
  static double margin(WindowSizeClass sizeClass) {
    return switch (sizeClass) {
      WindowSizeClass.compact => 16,
      WindowSizeClass.medium => 24,
      WindowSizeClass.expanded => 24,
      WindowSizeClass.large => 24,
    };
  }

  /// Recommended gutter width per breakpoint
  static double gutter(WindowSizeClass sizeClass) {
    return switch (sizeClass) {
      WindowSizeClass.compact => 8,
      WindowSizeClass.medium => 16,
      WindowSizeClass.expanded => 16,
      WindowSizeClass.large => 24,
    };
  }
}
