import 'package:flutter/material.dart';

import 'package:core_architecture/core_architecture.dart';

final class SpacingUtils {
  SpacingUtils._();
  static EdgeInsets all(double value) => EdgeInsets.all(value);
  static EdgeInsets zero = EdgeInsets.zero ;

  // Only
  static EdgeInsets onlyRight(double value) => EdgeInsets.only(right: value);
  static EdgeInsets onlyLeft(double value) => EdgeInsets.only(left: value);
  static EdgeInsets onlyTop(double value) => EdgeInsets.only(top: value);
  static EdgeInsets onlyBottom(double value) => EdgeInsets.only(bottom: value);

  // Symmetric
  static EdgeInsets horizontal(double value) =>
      EdgeInsets.symmetric(horizontal: value);

  static EdgeInsets vertical(double value) =>
      EdgeInsets.symmetric(vertical: value);

  static EdgeInsets symmetric({
    required double vertical,
    required double horizontal,
  }) => EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal);

  // Presets
  static EdgeInsets get page => EdgeInsets.symmetric(
    horizontal: AppSpacings.rMd,
    vertical: AppSpacings.hSm,
  );

  static EdgeInsets get card => EdgeInsets.all(AppSpacings.rSm);
}
