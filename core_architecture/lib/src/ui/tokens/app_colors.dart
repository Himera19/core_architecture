import 'package:flutter/material.dart';

final class AppColors {
  AppColors._();

  // BRAND
  static const Color primary = Color(0xFF521a75);
  static const Color secondary = Color(0xFF7f5599);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // SURFACE
  static const Color surfaceLight = Color(0xFFF5F7FA); // Slightly cool grey
  static const Color surfaceDark = Color(0xFF121212);

  static const Color surfaceContainerLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerDark = Color(0xFF1E1E1E);

  // TEXT
  static const Color textPrimaryLight = Color(0xFF102A43); // Dark Blue-Grey
  static const Color textPrimaryDark = Color(0xFFFFFFFF);

  static const Color textSecondaryLight = Color(0xFF627D98); // Blue-Grey
  static const Color textSecondaryDark = Color(0xFFBDBDBD);

  // BORDERS
  static const Color borderLight = Color(0xFFD9E2EC);
  static const Color borderDark = Color(0xFF424242);

  // STATUS
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);
  static const Color promotion = Color(0xFFFFBF00);

  // NEUTRALS & BASICS
  static const Color transparent = Colors.transparent;
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color amber = Colors.amber;
  static const Color grey = Colors.grey;
}