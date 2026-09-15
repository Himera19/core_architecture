import 'package:flutter/material.dart';

import '../tokens/app_borders.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_elevations.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacings.dart';
import '../tokens/app_typography.dart';
import 'app_color_scheme.dart';

/// Vertical padding inside buttons.
///
/// Deliberately off the [AppSpacings] ramp: 12 makes a 48dp button feel
/// cramped and 16 pushes it past the `AppSizes.buttonMd` height. 14 is what
/// button heights were designed around.
const double _buttonPaddingVertical = 14;

/// Builds the light and dark [ThemeData] for the design system.
///
/// Both modes come from one builder, so a change to card corners or button
/// padding lands in both at once — the two themes differ only in their
/// [ColorScheme] and the base typography they tint.
///
/// ```dart
/// // Defaults — identical to the `lightTheme` / `darkTheme` getters.
/// AppTheme.light();
///
/// // Re-branded and using your own font.
/// MaterialApp(
///   theme:     AppTheme.light(brandColor: myPurple, fontFamily: 'Inter'),
///   darkTheme: AppTheme.dark(brandColor: myPurple,  fontFamily: 'Inter'),
///   themeMode: ref.watch(themeProvider),
/// );
/// ```
final class AppTheme {
  AppTheme._();

  /// Light theme. See [AppTheme] for the parameters.
  static ThemeData light({
    Color? brandColor,
    String? fontFamily,
    ColorScheme? colorScheme,
  }) => _build(
    brightness: Brightness.light,
    brandColor: brandColor,
    fontFamily: fontFamily,
    colorScheme: colorScheme,
  );

  /// Dark theme. See [AppTheme] for the parameters.
  static ThemeData dark({
    Color? brandColor,
    String? fontFamily,
    ColorScheme? colorScheme,
  }) => _build(
    brightness: Brightness.dark,
    brandColor: brandColor,
    fontFamily: fontFamily,
    colorScheme: colorScheme,
  );

  /// [brandColor] re-brands the accent slots — see [colorSchemeFor].
  ///
  /// [colorScheme] replaces the scheme outright and takes precedence over
  /// [brandColor], for apps that keep a full hand-built scheme.
  ///
  /// [fontFamily] overrides [AppTypography.fontFamily], which ships as a
  /// placeholder. Register the family in your app's `pubspec.yaml`.
  static ThemeData _build({
    required Brightness brightness,
    Color? brandColor,
    String? fontFamily,
    ColorScheme? colorScheme,
  }) {
    final bool isDark = brightness == Brightness.dark;

    final ColorScheme scheme =
        colorScheme ??
        colorSchemeFor(brightness: brightness, brandColor: brandColor);

    final String font = fontFamily ?? AppTypography.fontFamily;

    // The only two things that still branch on mode: the base typography,
    // and the muted text color, which has no ColorScheme slot.
    final TextTheme baseTextTheme = isDark
        ? Typography.material2021().white
        : Typography.material2021().black;

    final Color mutedText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    OutlineInputBorder inputBorder(BorderSide side) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: side,
    );

    final RoundedRectangleBorder buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
    );

    const EdgeInsets buttonPadding = EdgeInsets.symmetric(
      horizontal: AppSpacings.wLg,
      vertical: _buttonPaddingVertical,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,

      fontFamily: font,

      textTheme: baseTextTheme.apply(
        fontFamily: font,
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: AppElevations.none,
        surfaceTintColor: AppColors.transparent,
        centerTitle: false,
      ),

      cardTheme: CardThemeData(
        elevation: AppElevations.none,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: scheme.outline),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        hintStyle: TextStyle(color: mutedText),
        labelStyle: TextStyle(color: mutedText),
        border: inputBorder(BorderSide(color: scheme.outline)),
        enabledBorder: inputBorder(BorderSide(color: scheme.outline)),
        focusedBorder: inputBorder(
          BorderSide(color: scheme.primary, width: AppBorders.normal),
        ),
        errorBorder: inputBorder(BorderSide(color: scheme.error)),
        focusedErrorBorder: inputBorder(
          BorderSide(color: scheme.error, width: AppBorders.normal),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacings.wMd,
          vertical: AppSpacings.hMd,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: AppElevations.none,
          shape: buttonShape,
          padding: buttonPadding,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: buttonShape,
          padding: buttonPadding,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: buttonShape,
          side: BorderSide(color: scheme.primary),
          padding: buttonPadding,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: buttonShape,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacings.wMd,
            vertical: _buttonPaddingVertical,
          ),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.white;
          }
          return null;
        }),
      ),
    );
  }
}
