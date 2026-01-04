import 'package:flutter/material.dart';
import 'package:core_architecture/core_architecture.dart';

ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: lightColorScheme,

  fontFamily: AppTypography.fontFamily,
  
  textTheme: Typography.material2021().black.apply(
    fontFamily: AppTypography.fontFamily,
    bodyColor: AppColors.textPrimaryLight,
    displayColor: AppColors.textPrimaryLight,
  ),

  cardTheme: const CardThemeData(
    elevation: 0,
    surfaceTintColor: AppColors.transparent,
  ),

  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.white; // White thumb when active
      }
      return null; // Default for inactive
    }),
  ),
);
