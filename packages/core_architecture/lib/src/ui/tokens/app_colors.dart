import 'package:flutter/material.dart';

final class AppColors {
  AppColors._();

  // BRAND
  static const Color primary = Color(0xFF2563EB);
  static const Color secondary = Color(0xFF3B82F6);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // SURFACE
  static const Color surfaceLight = Color(0xFFF8FAFC); // Slate-50
  static const Color surfaceDark = Color(0xFF0F172A);  // Slate-950

  static const Color surfaceContainerLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerDark = Color(0xFF1E293B); // Slate-800

  // TEXT
  static const Color textPrimaryLight = Color(0xFF1E293B); // Slate-800
  static const Color textPrimaryDark = Color(0xFFF1F5F9);  // Slate-100

  static const Color textSecondaryLight = Color(0xFF64748B); // Slate-500
  static const Color textSecondaryDark = Color(0xFF94A3B8);  // Slate-400

  // BORDERS
  static const Color borderLight = Color(0xFFCBD5E1); // Slate-300
  static const Color borderDark = Color(0xFF334155);  // Slate-700

  // STATUS
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF06B6D4);
  static const Color promotion = Color(0xFFA855F7);

  // NEUTRALS & BASICS
  static const Color transparent = Colors.transparent;
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color amber = Colors.amber;
  static const Color grey = Colors.grey;
}