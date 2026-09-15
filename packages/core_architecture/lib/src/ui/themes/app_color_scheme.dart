import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';

/// Default light scheme, built from the [AppColors] palette.
const ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: AppColors.primary,
  onPrimary: AppColors.onPrimary,
  secondary: AppColors.secondary,
  onSecondary: AppColors.onSecondary,
  error: AppColors.error,
  onError: AppColors.onError,
  surface: AppColors.surfaceLight,
  onSurface: AppColors.textPrimaryLight,
  surfaceContainerHighest: AppColors.surfaceContainerLight,
  outline: AppColors.borderLight,
);

/// Default dark scheme, built from the [AppColors] palette.
const ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: AppColors.primaryDark,
  onPrimary: AppColors.onPrimaryDark,
  secondary: AppColors.secondaryDark,
  onSecondary: AppColors.onSecondaryDark,
  error: AppColors.error,
  onError: AppColors.onError,
  surface: AppColors.surfaceDark,
  onSurface: AppColors.textPrimaryDark,
  surfaceContainerHighest: AppColors.surfaceContainerDark,
  outline: AppColors.borderDark,
);

/// Returns the scheme for [brightness], optionally re-branded from [brandColor].
///
/// With [brandColor] omitted this returns [lightColorScheme] or
/// [darkColorScheme] **unchanged** — the hand-tuned default palette.
///
/// When [brandColor] is given, only the four brand slots — `primary`,
/// `onPrimary`, `secondary`, `onSecondary` — are replaced. Their tones come
/// from [ColorScheme.fromSeed], so Material 3's own tonal-palette algorithm
/// picks them: it shifts hue and chroma, not just lightness, and guarantees
/// readable `on*` pairs for any seed, including light ones like yellow.
///
/// Everything else — the Slate surfaces, borders, text and the `error` pair —
/// is kept from the base scheme, so re-branding changes the accent without
/// disturbing the neutral palette the rest of the design system is built on.
ColorScheme colorSchemeFor({
  required Brightness brightness,
  Color? brandColor,
}) {
  final ColorScheme base = brightness == Brightness.dark
      ? darkColorScheme
      : lightColorScheme;

  if (brandColor == null) return base;

  final ColorScheme seeded = ColorScheme.fromSeed(
    seedColor: brandColor,
    brightness: brightness,
  );

  return base.copyWith(
    primary: seeded.primary,
    onPrimary: seeded.onPrimary,
    secondary: seeded.secondary,
    onSecondary: seeded.onSecondary,
  );
}
