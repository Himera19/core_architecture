import 'package:core_architecture/core_architecture.dart';
import 'package:flutter/material.dart';
import '../showcase/section.dart';

/// The responsive layer, live: resize the window (or rotate) and every readout
/// on this page moves.
class ResponsiveScreen extends StatelessWidget {
  const ResponsiveScreen({super.key});

  static const String path = '/responsive';

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colorScheme;
    final WindowSizeClass sizeClass = context.windowSizeClass;

    return ShowcasePage(
      title: 'Responsive',
      sections: [
        Section(
          title: 'Where this window sits',
          api: 'AppBreakpoints.of · ResponsiveContext',
          children: [
            Readout('windowSizeClass', sizeClass.name),
            Readout('screenWidth', context.screenWidth.toStringAsFixed(1)),
            Readout('screenHeight', context.screenHeight.toStringAsFixed(1)),
            Readout('isCompact', '${context.isCompact}'),
            Readout('isMedium', '${context.isMedium}'),
            Readout('isExpanded', '${context.isExpanded}'),
            Readout('isLarge', '${context.isLarge}'),
            Readout('isMobileNavigation', '${context.isMobileNavigation}'),
            Readout('isDesktopNavigation', '${context.isDesktopNavigation}'),
          ],
        ),

        Section(
          title: 'The thresholds',
          api: 'AppBreakpoints · WindowSizeClass · fromWidth',
          children: [
            for (final (name, from, klass) in const [
              ('compact', AppBreakpoints.compact, WindowSizeClass.compact),
              ('medium', AppBreakpoints.medium, WindowSizeClass.medium),
              ('expanded', AppBreakpoints.expanded, WindowSizeClass.expanded),
              ('large', AppBreakpoints.large, WindowSizeClass.large),
            ])
              Padding(
                padding: SpacingUtils.onlyBottom(AppSpacings.hXxs),
                child: Container(
                  padding: SpacingUtils.all(AppSpacings.rXs),
                  decoration: BoxDecoration(
                    // The band this window is currently in is filled in.
                    color: klass == sizeClass
                        ? colors.primaryContainer
                        : Colors.transparent,
                    borderRadius: RadiusUtils.all(AppRadius.sm),
                    border: Border.fromBorderSide(
                      BorderUtils.thin(colors.outlineVariant),
                    ),
                  ),
                  // A Wrap, not a Row: at compact width the two halves do not
                  // fit on one line, and this section is the one place that
                  // gets read on a narrow window.
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: AppSpacings.wSm,
                    runSpacing: AppSpacings.hXxs,
                    children: [
                      Text(
                        '$name  ≥ ${from.toInt()}dp',
                        style: AppTypography.bodySm,
                      ),
                      Text(
                        'cols ${AppBreakpoints.columns(klass)} · '
                        'margin ${AppBreakpoints.margin(klass).toInt()} · '
                        'gutter ${AppBreakpoints.gutter(klass).toInt()}',
                        style: AppTypography.labelSm,
                      ),
                    ],
                  ),
                ),
              ),
            Gap.hXs,
            Readout(
              'maxContentWidth',
              '${AppBreakpoints.maxContentWidth.toInt()}',
            ),
            Readout(
              'fromWidth(1400)',
              AppBreakpoints.fromWidth(1400).name,
            ),
          ],
        ),

        Section(
          title: 'A layout that swaps per breakpoint',
          api: 'ResponsiveBuilder',
          children: [
            ResponsiveBuilder(
              compact: (context) => const _Band(
                label: 'compact builder — one column',
                columns: 1,
              ),
              medium: (context) => const _Band(
                label: 'medium builder — two columns',
                columns: 2,
              ),
              expanded: (context) => const _Band(
                label: 'expanded builder — three columns',
                columns: 3,
              ),
              large: (context) => const _Band(
                label: 'large builder — four columns',
                columns: 4,
              ),
            ),
          ],
        ),

        Section(
          title: 'A value that changes per breakpoint',
          api: 'ResponsiveValue · ResponsiveSpacings · context.responsive',
          children: [
            Readout(
              'pagePadding',
              ResponsiveSpacings.pagePadding.resolve(context).toStringAsFixed(0),
            ),
            Readout(
              'sectionSpacing',
              ResponsiveSpacings.sectionSpacing
                  .resolve(context)
                  .toStringAsFixed(0),
            ),
            Readout(
              'gridColumns',
              '${ResponsiveSpacings.gridColumns.resolve(context)}',
            ),
            Readout(
              'context.responsive<String>',
              context.responsive<String>(
                compact: 'phone',
                medium: 'tablet',
                expanded: 'small desktop',
                large: 'wide desktop',
              ),
            ),
            Gap.hXs,
            // resolveFor answers for a class other than the current one, which
            // is what a preview or a test needs.
            for (final klass in WindowSizeClass.values)
              Readout(
                'resolveFor(${klass.name})',
                '${ResponsiveSpacings.gridColumns.resolveFor(klass)} columns',
              ),
          ],
        ),

        Section(
          title: 'This device',
          api: 'PlatformInfo',
          children: [
            Readout('platformName', PlatformInfo.platformName),
            Readout('isWeb', '${PlatformInfo.isWeb}'),
            Readout('isMobile', '${PlatformInfo.isMobile}'),
            Readout('isDesktop', '${PlatformInfo.isDesktop}'),
            Readout('isAndroid', '${PlatformInfo.isAndroid}'),
            Readout('isIOS', '${PlatformInfo.isIOS}'),
            Readout('isWindows', '${PlatformInfo.isWindows}'),
            Readout('isMacOS', '${PlatformInfo.isMacOS}'),
            Readout('isLinux', '${PlatformInfo.isLinux}'),
          ],
        ),
      ],
    );
  }
}

/// A row of cells, one per column the current breakpoint calls for.
class _Band extends StatelessWidget {
  const _Band({required this.label, required this.columns});

  final String label;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: AppTypography.bodyMd),
        Gap.hSm,
        Row(
          children: [
            for (int i = 0; i < columns; i++)
              Expanded(
                child: Padding(
                  padding: SpacingUtils.onlyRight(AppSpacings.wXxs),
                  child: Container(
                    height: AppSizes.buttonSm,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: RadiusUtils.all(AppRadius.sm),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
