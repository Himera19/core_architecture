import 'package:core_architecture/core_architecture.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../showcase/section.dart';

/// Exercises the theming layer: [AppTheme], [colorSchemeFor], the two default
/// schemes, and [themeProvider] driving the live mode.
class ThemeScreen extends ConsumerWidget {
  const ThemeScreen({super.key});

  static const String path = '/theme';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = context.colorScheme;
    final ThemeMode mode = ref.watch(themeProvider);

    return ShowcasePage(
      title: 'Theme',
      sections: [
        Section(
          title: 'Live theme mode',
          api: 'themeProvider · ThemeNotifier.setThemeMode / toggleTheme',
          children: [
            Readout('current', mode.name),
            Gap.hSm,
            // Every mode, including system — which the notifier can hold even
            // though toggleTheme only walks light and dark.
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.light, label: Text('light')),
                ButtonSegment(value: ThemeMode.dark, label: Text('dark')),
                ButtonSegment(value: ThemeMode.system, label: Text('system')),
              ],
              selected: {mode},
              onSelectionChanged: (selection) =>
                  ref.read(themeProvider.notifier).setThemeMode(selection.first),
            ),
            Gap.hSm,
            CustomButton(
              text: 'toggleTheme()',
              type: ButtonType.outlined,
              onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
            ),
            Gap.hXs,
            Text(
              'The choice is written to secure storage, so it survives a '
              'restart.',
              style: AppTypography.bodySm.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),

        const Section(
          title: 'The scheme this app is running on',
          api: 'AppTheme.light(brandColor: ...) · colorSchemeFor',
          children: [
            // Accent slots follow the brand seed; the neutrals stay on the
            // design system's own Slate ramp.
            _SwatchGrid(
              labels: [
                'primary',
                'onPrimary',
                'primaryContainer',
                'secondary',
                'tertiary',
                'error',
              ],
            ),
            Gap.hSm,
            _SwatchGrid(
              labels: [
                'surface',
                'surfaceContainerHighest',
                'onSurface',
                'onSurfaceVariant',
                'outline',
                'inverseSurface',
              ],
            ),
          ],
        ),

        Section(
          title: 'Defaults, untouched by branding',
          api: 'lightColorScheme · darkColorScheme · lightTheme · darkTheme',
          children: [
            Readout('lightColorScheme.primary', hexOf(lightColorScheme.primary)),
            Readout('darkColorScheme.primary', hexOf(darkColorScheme.primary)),
            Readout('lightTheme.brightness', lightTheme.brightness.name),
            Readout('darkTheme.brightness', darkTheme.brightness.name),
            Gap.hXs,
            Readout(
              'seeded from brand',
              hexOf(
                colorSchemeFor(
                  brightness: Brightness.light,
                  brandColor: brandColor,
                ).primary,
              ),
            ),
          ],
        ),

        Section(
          title: 'Material widgets read the same slots',
          api: 'ThemeData built by AppTheme',
          children: [
            const LinearProgressIndicator(value: 0.6),
            Gap.hSm,
            Row(
              children: [
                Switch(value: true, onChanged: (_) {}),
                Gap.wSm,
                Checkbox(value: true, onChanged: (_) {}),
                Gap.wSm,
                const RadioGroup<bool>(
                  groupValue: true,
                  onChanged: _ignoreRadio,
                  child: Radio<bool>(value: true),
                ),
                Gap.wSm,
                const Chip(label: Text('chip')),
              ],
            ),
            Gap.hSm,
            FilledButton(onPressed: () {}, child: const Text('FilledButton')),
            Gap.hXs,
            OutlinedButton(
              onPressed: () {},
              child: const Text('OutlinedButton'),
            ),
            Gap.hXs,
            TextButton(onPressed: () {}, child: const Text('TextButton')),
          ],
        ),

        const Section(
          title: 'The type ramp',
          api: 'AppTypography — sizes and weights, no font family',
          children: [
            Text('displaySm', style: AppTypography.displaySm),
            Text('headlineMd', style: AppTypography.headlineMd),
            Text('titleLg', style: AppTypography.titleLg),
            Text('titleMd', style: AppTypography.titleMd),
            Text('titleSm', style: AppTypography.titleSm),
            Text('bodyLg', style: AppTypography.bodyLg),
            Text('bodyMd', style: AppTypography.bodyMd),
            Text('bodySm', style: AppTypography.bodySm),
            Text('labelLg', style: AppTypography.labelLg),
            Text('labelMd', style: AppTypography.labelMd),
            Text('labelSm', style: AppTypography.labelSm),
          ],
        ),
      ],
    );
  }
}

/// The radio here is a swatch, not a control — it is on display to show that
/// Material widgets pick up the theme's accent without being told to.
void _ignoreRadio(bool? _) {}

/// `#RRGGBB` for a colour, so schemes can be compared by eye in a readout.
String hexOf(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Resolves scheme slots by name, so the grid stays a list of strings.
class _SwatchGrid extends StatelessWidget {
  const _SwatchGrid({required this.labels});

  final List<String> labels;

  Color _resolve(ColorScheme c, String name) => switch (name) {
    'primary' => c.primary,
    'onPrimary' => c.onPrimary,
    'primaryContainer' => c.primaryContainer,
    'secondary' => c.secondary,
    'tertiary' => c.tertiary,
    'error' => c.error,
    'surface' => c.surface,
    'surfaceContainerHighest' => c.surfaceContainerHighest,
    'onSurface' => c.onSurface,
    'onSurfaceVariant' => c.onSurfaceVariant,
    'outline' => c.outline,
    'inverseSurface' => c.inverseSurface,
    _ => c.surface,
  };

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colorScheme;

    return Wrap(
      spacing: AppSpacings.wSm,
      runSpacing: AppSpacings.hSm,
      children: [
        for (final label in labels)
          SizedBox(
            width: AppSizes.thumbnailSm + AppSpacings.wLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: AppSizes.buttonSm,
                  decoration: BoxDecoration(
                    color: _resolve(colors, label),
                    borderRadius: RadiusUtils.all(AppRadius.md),
                    border: Border.fromBorderSide(
                      BorderUtils.thin(colors.outline),
                    ),
                  ),
                ),
                Gap.hXxs,
                Text(
                  label,
                  style: AppTypography.labelSm,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
