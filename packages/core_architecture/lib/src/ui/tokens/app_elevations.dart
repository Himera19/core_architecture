import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_opacities.dart';

final class AppElevations {
  AppElevations._();

  // Material Elevation Values (for widgets taking double elevation)
  static const double none = 0;
  static const double level1 = 1;
  static const double level2 = 3;
  static const double level3 = 6;
  static const double level4 = 8;
  static const double level5 = 12;

  // Semantic Aliases
  static const double low = level1;
  static const double medium = level2;
  static const double high = level3;
  static const double highest = level5;

  // Custom Box Shadows (for Container decoration)
  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: AppColors.black.withAlpha(AppOpacities.extraLow),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: AppColors.black.withAlpha(AppOpacities.low),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: AppColors.black.withAlpha(AppOpacities.medium),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
}
