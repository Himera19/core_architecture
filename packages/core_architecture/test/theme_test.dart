import 'package:core_architecture/core_architecture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'theme_regression_reference.dart';

/// Resolves a switch thumb color for the selected / unselected state, since
/// two `WidgetStateProperty.resolveWith` closures are never `==` to each other.
Color? _thumb(ThemeData theme, {required bool selected}) => theme
    .switchTheme
    .thumbColor
    ?.resolve(selected ? {WidgetState.selected} : <WidgetState>{});

void main() {
  group('AppTheme reproduces the pre-refactor themes', () {
    final pairs = <String, (ThemeData, ThemeData)>{
      'light': (lightTheme, oldLightTheme()),
      'dark': (darkTheme, oldDarkTheme()),
    };

    pairs.forEach((mode, pair) {
      final (built, reference) = pair;

      group(mode, () {
        test('colorScheme', () {
          expect(built.colorScheme, reference.colorScheme);
        });

        test('brightness and fontFamily', () {
          expect(built.brightness, reference.brightness);
          expect(
            built.textTheme.bodyMedium?.fontFamily,
            reference.textTheme.bodyMedium?.fontFamily,
          );
        });

        test('textTheme', () {
          expect(built.textTheme, reference.textTheme);
        });

        test('appBarTheme', () {
          expect(built.appBarTheme, reference.appBarTheme);
        });

        test('cardTheme', () {
          expect(built.cardTheme, reference.cardTheme);
        });

        test('inputDecorationTheme', () {
          expect(built.inputDecorationTheme, reference.inputDecorationTheme);
        });

        test('button themes', () {
          expect(built.elevatedButtonTheme, reference.elevatedButtonTheme);
          expect(built.filledButtonTheme, reference.filledButtonTheme);
          expect(built.outlinedButtonTheme, reference.outlinedButtonTheme);
          expect(built.textButtonTheme, reference.textButtonTheme);
        });

        test('switchTheme thumb color', () {
          expect(
            _thumb(built, selected: true),
            _thumb(reference, selected: true),
          );
          expect(
            _thumb(built, selected: false),
            _thumb(reference, selected: false),
          );
        });
      });
    });
  });

  group('default color schemes', () {
    test('light keeps the shipped palette', () {
      expect(lightColorScheme.primary, AppColors.primary);
      expect(lightColorScheme.onPrimary, AppColors.onPrimary);
      expect(lightColorScheme.surface, AppColors.surfaceLight);
      expect(lightColorScheme.outline, AppColors.borderLight);
    });

    test('dark keeps the shipped palette, now via tokens', () {
      expect(darkColorScheme.primary, const Color(0xFF60A5FA));
      expect(darkColorScheme.onPrimary, const Color(0xFF1E3A8A));
      expect(darkColorScheme.secondary, const Color(0xFF93C5FD));
      expect(darkColorScheme.onSecondary, const Color(0xFF1E3A8A));

      // The literals that used to be inline are now named tokens.
      expect(darkColorScheme.primary, AppColors.primaryDark);
      expect(darkColorScheme.onPrimary, AppColors.onPrimaryDark);
      expect(darkColorScheme.secondary, AppColors.secondaryDark);
      expect(darkColorScheme.onSecondary, AppColors.onSecondaryDark);
    });

    test('colorSchemeFor without a brand color returns the defaults', () {
      expect(colorSchemeFor(brightness: Brightness.light), lightColorScheme);
      expect(colorSchemeFor(brightness: Brightness.dark), darkColorScheme);
    });
  });

  group('brandColor', () {
    const brand = Color(0xFF7C3AED); // violet

    test('replaces the accent slots in both modes', () {
      for (final brightness in Brightness.values) {
        final base = colorSchemeFor(brightness: brightness);
        final branded = colorSchemeFor(
          brightness: brightness,
          brandColor: brand,
        );

        expect(
          branded.primary,
          isNot(base.primary),
          reason: '$brightness primary should change',
        );
        expect(
          branded.secondary,
          isNot(base.secondary),
          reason: '$brightness secondary should change',
        );
      }
    });

    test('carries the brand into the derived accent slots too', () {
      // Regression: the scheme used to be built with `base.copyWith(primary:
      // …)`, which froze every slot the const base left unset on the default
      // blue — a green brand still rendered a blue progress track.
      for (final brightness in Brightness.values) {
        final base = colorSchemeFor(brightness: brightness);
        final branded = colorSchemeFor(
          brightness: brightness,
          brandColor: brand,
        );

        for (final slot in {
          'primaryContainer': (branded.primaryContainer, base.primaryContainer),
          'onPrimaryContainer': (
            branded.onPrimaryContainer,
            base.onPrimaryContainer,
          ),
          'secondaryContainer': (
            branded.secondaryContainer,
            base.secondaryContainer,
          ),
          'tertiary': (branded.tertiary, base.tertiary),
          'inversePrimary': (branded.inversePrimary, base.inversePrimary),
        }.entries) {
          expect(
            slot.value.$1,
            isNot(slot.value.$2),
            reason: '$brightness ${slot.key} should follow the brand color',
          );
        }
      }
    });

    test('leaves the neutral palette and error pair untouched', () {
      for (final brightness in Brightness.values) {
        final base = colorSchemeFor(brightness: brightness);
        final branded = colorSchemeFor(
          brightness: brightness,
          brandColor: brand,
        );

        // The whole neutral family, not just the slots the base sets: the
        // rest resolve to the flat Slate surface, and a seeded scheme would
        // quietly tint them with the brand hue.
        for (final slot in {
          'surface': (branded.surface, base.surface),
          'onSurface': (branded.onSurface, base.onSurface),
          'surfaceDim': (branded.surfaceDim, base.surfaceDim),
          'surfaceBright': (branded.surfaceBright, base.surfaceBright),
          'surfaceContainerLowest': (
            branded.surfaceContainerLowest,
            base.surfaceContainerLowest,
          ),
          'surfaceContainerLow': (
            branded.surfaceContainerLow,
            base.surfaceContainerLow,
          ),
          'surfaceContainer': (branded.surfaceContainer, base.surfaceContainer),
          'surfaceContainerHigh': (
            branded.surfaceContainerHigh,
            base.surfaceContainerHigh,
          ),
          'surfaceContainerHighest': (
            branded.surfaceContainerHighest,
            base.surfaceContainerHighest,
          ),
          'onSurfaceVariant': (branded.onSurfaceVariant, base.onSurfaceVariant),
          'outline': (branded.outline, base.outline),
          'outlineVariant': (branded.outlineVariant, base.outlineVariant),
          'inverseSurface': (branded.inverseSurface, base.inverseSurface),
          'onInverseSurface': (branded.onInverseSurface, base.onInverseSurface),
          'error': (branded.error, base.error),
          'onError': (branded.onError, base.onError),
        }.entries) {
          expect(
            slot.value.$1,
            slot.value.$2,
            reason: '$brightness ${slot.key} must stay on the base palette',
          );
        }
        expect(branded.brightness, base.brightness);
      }
    });

    test('derives readable on-colors even for a light seed', () {
      // A lightness-only shift would put white on yellow here.
      const yellow = Color(0xFFFDE047);

      for (final brightness in Brightness.values) {
        final scheme = colorSchemeFor(
          brightness: brightness,
          brandColor: yellow,
        );

        final contrast =
            (scheme.primary.computeLuminance() + 0.05) /
            (scheme.onPrimary.computeLuminance() + 0.05);

        expect(
          contrast > 4.5 || contrast < 1 / 4.5,
          isTrue,
          reason: '$brightness onPrimary must contrast with primary',
        );
      }
    });

    test('flows through AppTheme into the built ThemeData', () {
      final themed = AppTheme.light(brandColor: brand);

      expect(
        themed.colorScheme.primary,
        colorSchemeFor(brightness: Brightness.light, brandColor: brand).primary,
      );
      expect(themed.colorScheme.primary, isNot(lightTheme.colorScheme.primary));

      // The focus ring and outlined button border follow the scheme.
      final focused =
          themed.inputDecorationTheme.focusedBorder as OutlineInputBorder;
      expect(focused.borderSide.color, themed.colorScheme.primary);
    });
  });

  group('fontFamily', () {
    test('defaults to the AppTypography placeholder', () {
      expect(
        lightTheme.textTheme.bodyMedium?.fontFamily,
        AppTypography.fontFamily,
      );
    });

    test('override reaches ThemeData and every text style', () {
      final themed = AppTheme.dark(fontFamily: 'Inter');

      expect(themed.textTheme.bodyMedium?.fontFamily, 'Inter');
      expect(themed.textTheme.headlineLarge?.fontFamily, 'Inter');
      expect(themed.textTheme.labelSmall?.fontFamily, 'Inter');
    });
  });

  group('colorScheme override', () {
    test('wins over brandColor', () {
      const custom = ColorScheme.light(primary: Color(0xFF123456));

      final themed = AppTheme.light(
        brandColor: const Color(0xFF7C3AED),
        colorScheme: custom,
      );

      expect(themed.colorScheme, custom);
      expect(themed.colorScheme.primary, const Color(0xFF123456));
    });
  });

  group('tokens drive the theme', () {
    test('corners come from AppRadius.lg', () {
      final card = lightTheme.cardTheme.shape as RoundedRectangleBorder;
      expect(card.borderRadius, BorderRadius.circular(AppRadius.lg));
    });

    test('focus ring width comes from AppBorders.normal', () {
      for (final theme in [lightTheme, darkTheme]) {
        final focused =
            theme.inputDecorationTheme.focusedBorder as OutlineInputBorder;
        expect(focused.borderSide.width, AppBorders.normal);
      }
    });

    test('flat surfaces come from AppElevations.none', () {
      expect(lightTheme.appBarTheme.elevation, AppElevations.none);
      expect(lightTheme.cardTheme.elevation, AppElevations.none);
    });

    test('input padding comes from AppSpacings', () {
      expect(
        lightTheme.inputDecorationTheme.contentPadding,
        const EdgeInsets.symmetric(
          horizontal: AppSpacings.wMd,
          vertical: AppSpacings.hMd,
        ),
      );
    });
  });
}
