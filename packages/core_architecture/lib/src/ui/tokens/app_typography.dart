import 'package:flutter/material.dart';

/// The type ramp: sizes and weights only, deliberately carrying no font
/// family.
///
/// These styles are merged onto the theme's own text style, which is where the
/// family comes from — so naming one here would override whatever the app
/// passed to `AppTheme.light(fontFamily: ...)`.
final class AppTypography {
  AppTypography._();

  // DISPLAY
  static const TextStyle displayLg = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle displayMd = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle displaySm = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
  );

  // HEADLINE
  static const TextStyle headlineLg = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle headlineMd = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle headlineSm = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  // TITLE
  static const TextStyle titleLg = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleMd = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleSm = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  // BODY
  static const TextStyle bodyLg = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyMd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodySm = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  // LABEL
  static const TextStyle labelLg = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle labelMd = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle labelSm = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );
}
