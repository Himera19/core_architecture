import 'package:flutter/widgets.dart';

import 'app_breakpoints.dart';

/// A value that changes based on the current [WindowSizeClass].
///
/// Use this for spacing, font sizes, column counts, or any value
/// that should adapt to screen size.
///
/// ```dart
/// final padding = ResponsiveValue<double>(
///   compact: 16,
///   medium: 24,
///   expanded: 32,
///   large: 40,
/// );
///
/// Container(padding: EdgeInsets.all(padding.resolve(context)));
/// ```
class ResponsiveValue<T> {
  final T compact;
  final T? medium;
  final T? expanded;
  final T? large;

  const ResponsiveValue({
    required this.compact,
    this.medium,
    this.expanded,
    this.large,
  });

  /// Resolve the value based on the current screen size.
  T resolve(BuildContext context) {
    final sizeClass = AppBreakpoints.of(context);

    return switch (sizeClass) {
      WindowSizeClass.large => large ?? expanded ?? medium ?? compact,
      WindowSizeClass.expanded => expanded ?? medium ?? compact,
      WindowSizeClass.medium => medium ?? compact,
      WindowSizeClass.compact => compact,
    };
  }

  /// Resolve from a given [WindowSizeClass] directly.
  T resolveFor(WindowSizeClass sizeClass) {
    return switch (sizeClass) {
      WindowSizeClass.large => large ?? expanded ?? medium ?? compact,
      WindowSizeClass.expanded => expanded ?? medium ?? compact,
      WindowSizeClass.medium => medium ?? compact,
      WindowSizeClass.compact => compact,
    };
  }
}

/// Pre-built responsive spacing values.
///
/// ```dart
/// Container(
///   padding: EdgeInsets.all(ResponsiveSpacings.pagePadding.resolve(context)),
/// )
/// ```
class ResponsiveSpacings {
  ResponsiveSpacings._();

  static const pagePadding = ResponsiveValue<double>(
    compact: 16,
    medium: 24,
    expanded: 32,
    large: 40,
  );

  static const sectionSpacing = ResponsiveValue<double>(
    compact: 24,
    medium: 32,
    expanded: 48,
    large: 64,
  );

  static const gridColumns = ResponsiveValue<int>(
    compact: 1,
    medium: 2,
    expanded: 3,
    large: 4,
  );
}
