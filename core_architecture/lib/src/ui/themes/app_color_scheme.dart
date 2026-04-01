import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';

const ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: AppColors.primary,
  onPrimary: Colors.white,
  secondary: AppColors.secondary,
  onSecondary:AppColors.onSecondary,
  error: AppColors.error,
  onError: Colors.white,
  surface: AppColors.surfaceLight,
  onSurface: AppColors.textPrimaryLight,
  surfaceContainerHighest: AppColors.surfaceContainerLight,
  outline: AppColors.borderLight,
);

const ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: AppColors.primary,
  onPrimary: Colors.white,
  secondary: AppColors.secondary,
  onSecondary: AppColors.onSecondary,
  error: AppColors.error,
  onError: Colors.white,
  surface: AppColors.surfaceDark,
  onSurface: AppColors.textPrimaryDark,
  surfaceContainerHighest: AppColors.surfaceContainerDark,
  outline: AppColors.borderDark,
);
