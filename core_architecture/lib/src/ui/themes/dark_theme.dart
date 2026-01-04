import 'package:flutter/material.dart';
import 'package:core_architecture/core_architecture.dart';

ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: darkColorScheme,

  fontFamily: AppTypography.fontFamily,
  
  textTheme: Typography.material2021().white.apply(
    fontFamily: AppTypography.fontFamily,
    bodyColor: AppColors.textPrimaryDark,
    displayColor: AppColors.textPrimaryDark,
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
