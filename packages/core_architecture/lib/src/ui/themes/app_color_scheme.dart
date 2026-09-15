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
/// When [brandColor] is given, every accent slot follows it — not just
/// `primary` and `secondary` but the containers, `tertiary` and
/// `inversePrimary` that Material widgets reach for on their own (a progress
/// track, a filled chip, a snackbar action). The tones come from
/// [ColorScheme.fromSeed], so Material 3's own tonal-palette algorithm picks
/// them: it shifts hue and chroma, not just lightness, and guarantees
/// readable `on*` pairs for any seed, including light ones like yellow.
///
/// The design system's own neutrals — the Slate surfaces, borders and text —
/// and the `error` pair are put back on top, so re-branding changes the accent
/// without disturbing the palette the rest of the system is built on.
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

  // Seeded scheme first, neutrals back on top — not `base.copyWith(primary:
  // …)`. The base schemes are `const` and leave the derived accent slots
  // unset, where they resolve off `primary`; `copyWith` reads them through
  // those getters and writes the results back as literals, freezing
  // `primaryContainer` and friends on the *default* blue accent. Branding
  // then reached `primary` but left a blue progress track behind it.
  //
  // Every neutral is listed, not just the ones the base sets: the unset ones
  // resolve to the flat Slate surface, and leaving them to the seeded scheme
  // would tint cards and dividers with the brand hue.
  return seeded.copyWith(
    surface: base.surface,
    onSurface: base.onSurface,
    surfaceDim: base.surfaceDim,
    surfaceBright: base.surfaceBright,
    surfaceContainerLowest: base.surfaceContainerLowest,
    surfaceContainerLow: base.surfaceContainerLow,
    surfaceContainer: base.surfaceContainer,
    surfaceContainerHigh: base.surfaceContainerHigh,
    surfaceContainerHighest: base.surfaceContainerHighest,
    onSurfaceVariant: base.onSurfaceVariant,
    outline: base.outline,
    outlineVariant: base.outlineVariant,
    inverseSurface: base.inverseSurface,
    onInverseSurface: base.onInverseSurface,
    error: base.error,
    onError: base.onError,
  );
}
