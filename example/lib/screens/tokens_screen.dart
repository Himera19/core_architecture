import 'package:core_architecture/core_architecture.dart';
import 'package:flutter/material.dart';
import '../showcase/section.dart';

/// Every design token the package ships, rendered at its real value:
/// [AppSpacings], [AppRadius], [AppSizes], [AppBorders], [AppElevations],
/// [AppOpacities], [AppColors] and [AppDurations].
class TokensScreen extends StatefulWidget {
  const TokensScreen({super.key});

  static const String path = '/tokens';

  @override
  State<TokensScreen> createState() => _TokensScreenState();
}

class _TokensScreenState extends State<TokensScreen> {
  /// Driven by the AppDurations section, to show each duration as motion
  /// rather than as a number.
  bool _expanded = false;
  Duration _duration = AppDurations.normal;

  /// A dialog whose box is the AppSizes dialog tokens, rather than a readout
  /// of the numbers.
  Future<void> _showSizedDialog() {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sized by tokens'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSizes.dialogMaxWidth,
            maxHeight: AppSizes.dialogMaxHeight,
          ),
          child: Text(
            'maxWidth ${AppSizes.dialogMaxWidth.toInt()} · '
            'maxHeight ${AppSizes.dialogMaxHeight.toInt()}.\n\n'
            'The action below is dialogButtonWidth '
            '(${AppSizes.dialogButtonWidth.toInt()}) wide.',
            style: AppTypography.bodyMd,
          ),
        ),
        actions: [
          SizedBox(
            width: AppSizes.dialogButtonWidth,
            child: CustomButton(
              text: 'Close',
              size: ButtonSize.small,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colorScheme;

    return ShowcasePage(
      title: 'Tokens',
      sections: [
        Section(
          title: 'Spacing ramp',
          api: 'AppSpacings.w* / h* / r* · Gap · SpacingUtils',
          children: [
            for (final (name, value) in const [
              ('wXxs / hXxs / rXxs', AppSpacings.wXxs),
              ('wXs / hXs / rXs', AppSpacings.wXs),
              ('wSm / hSm / rSm', AppSpacings.wSm),
              ('wMd / hMd / rMd', AppSpacings.wMd),
              ('wLg / hLg / rLg', AppSpacings.wLg),
              ('wXl / hXl / rXl', AppSpacings.wXl),
              ('wXxl / hXxl / rXxl', AppSpacings.wXxl),
            ])
              Padding(
                padding: SpacingUtils.onlyBottom(AppSpacings.hXxs),
                child: Row(
                  children: [
                    SizedBox(
                      width: AppSizes.thumbnailMd,
                      child: Text(name, style: AppTypography.labelSm),
                    ),
                    Container(
                      width: value,
                      height: AppSpacings.hMd,
                      color: colors.primary,
                    ),
                    Gap.wSm,
                    Text('${value.toInt()}', style: AppTypography.bodySm),
                  ],
                ),
              ),
            Gap.hSm,
            Text(
              'Gap turns these into const SizedBoxes: Gap.hMd, Gap.wSm, and so '
              'on — the vertical ones separate these very rows.',
              style: AppTypography.bodySm.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),

        Section(
          title: 'Corner radii',
          api: 'AppRadius · RadiusUtils',
          children: [
            Wrap(
              spacing: AppSpacings.wSm,
              runSpacing: AppSpacings.hSm,
              children: [
                for (final (name, value) in const [
                  ('sm', AppRadius.sm),
                  ('md', AppRadius.md),
                  ('lg', AppRadius.lg),
                  ('xl', AppRadius.xl),
                ])
                  Column(
                    children: [
                      Container(
                        width: AppSizes.thumbnailSm,
                        height: AppSizes.thumbnailSm,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: RadiusUtils.all(value),
                        ),
                      ),
                      Gap.hXxs,
                      Text(
                        '$name · ${value.toInt()}',
                        style: AppTypography.labelSm,
                      ),
                    ],
                  ),
                // The two presets, which only round one edge.
                Column(
                  children: [
                    Container(
                      width: AppSizes.thumbnailSm,
                      height: AppSizes.thumbnailSm,
                      decoration: BoxDecoration(
                        color: colors.secondaryContainer,
                        borderRadius: RadiusUtils.topMd,
                      ),
                    ),
                    Gap.hXxs,
                    const Text('topMd', style: AppTypography.labelSm),
                  ],
                ),
                Column(
                  children: [
                    Container(
                      width: AppSizes.thumbnailSm,
                      height: AppSizes.thumbnailSm,
                      decoration: BoxDecoration(
                        color: colors.secondaryContainer,
                        borderRadius: RadiusUtils.bottomMd,
                      ),
                    ),
                    Gap.hXxs,
                    const Text('bottomMd', style: AppTypography.labelSm),
                  ],
                ),
                Column(
                  children: [
                    Container(
                      width: AppSizes.thumbnailSm,
                      height: AppSizes.thumbnailSm,
                      decoration: BoxDecoration(
                        color: colors.secondaryContainer,
                        borderRadius: RadiusUtils.only(
                          topLeft: AppRadius.xl,
                          bottomRight: AppRadius.xl,
                        ),
                      ),
                    ),
                    Gap.hXxs,
                    const Text('only(...)', style: AppTypography.labelSm),
                  ],
                ),
              ],
            ),
          ],
        ),

        Section(
          title: 'Border widths',
          api: 'AppBorders · BorderUtils',
          children: [
            for (final (name, side) in [
              ('thin · ${AppBorders.thin.toInt()}', BorderUtils.thin(colors.primary)),
              ('normal · ${AppBorders.normal.toInt()}', BorderUtils.normal(colors.primary)),
              ('thick · ${AppBorders.thick.toInt()}', BorderUtils.thick(colors.primary)),
            ])
              Padding(
                padding: SpacingUtils.onlyBottom(AppSpacings.hXs),
                child: Container(
                  padding: SpacingUtils.all(AppSpacings.rSm),
                  decoration: BoxDecoration(
                    border: Border.fromBorderSide(side),
                    borderRadius: RadiusUtils.all(AppRadius.md),
                  ),
                  child: Text(name, style: AppTypography.bodySm),
                ),
              ),
          ],
        ),

        Section(
          title: 'Sizes',
          api: 'AppSizes',
          children: [
            Wrap(
              spacing: AppSpacings.wMd,
              runSpacing: AppSpacings.hSm,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                for (final (name, value) in const [
                  ('iconSm', AppSizes.iconSm),
                  ('iconMd', AppSizes.iconMd),
                  ('iconLg', AppSizes.iconLg),
                  ('iconXl', AppSizes.iconXl),
                ])
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: value, color: colors.primary),
                      Text(name, style: AppTypography.labelSm),
                    ],
                  ),
              ],
            ),
            Gap.hMd,

            // Control heights, drawn at the height they name.
            const Text('Control heights', style: AppTypography.labelLg),
            Gap.hXs,
            Wrap(
              spacing: AppSpacings.wSm,
              runSpacing: AppSpacings.hSm,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                for (final (name, height) in const [
                  ('buttonSm', AppSizes.buttonSm),
                  ('buttonMd', AppSizes.buttonMd),
                  ('buttonLg', AppSizes.buttonLg),
                  ('inputHeight', AppSizes.inputHeight),
                ])
                  Container(
                    height: height,
                    padding: SpacingUtils.horizontal(AppSpacings.wSm),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: RadiusUtils.all(AppRadius.md),
                    ),
                    child: Text(
                      '$name · ${height.toInt()}',
                      style: AppTypography.labelSm,
                    ),
                  ),
              ],
            ),
            Gap.hMd,

            const Text('Avatars', style: AppTypography.labelLg),
            Gap.hXs,
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (name, size) in const [
                  ('avatarSm', AppSizes.avatarSm),
                  ('avatarMd', AppSizes.avatarMd),
                  ('avatarLg', AppSizes.avatarLg),
                ])
                  Padding(
                    padding: SpacingUtils.onlyRight(AppSpacings.wSm),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: size / 2,
                          backgroundColor: colors.primaryContainer,
                          child: Icon(
                            Icons.person,
                            size: size / 2,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                        Gap.hXxs,
                        Text(name, style: AppTypography.labelSm),
                      ],
                    ),
                  ),
              ],
            ),
            Gap.hMd,

            const Text('Thumbnails', style: AppTypography.labelLg),
            Gap.hXs,
            Wrap(
              spacing: AppSpacings.wSm,
              runSpacing: AppSpacings.hSm,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                for (final (name, size) in const [
                  ('thumbnailSm', AppSizes.thumbnailSm),
                  ('thumbnailMd', AppSizes.thumbnailMd),
                  ('thumbnailLg', AppSizes.thumbnailLg),
                ])
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: colors.secondaryContainer,
                          borderRadius: RadiusUtils.all(AppRadius.md),
                        ),
                        child: Icon(
                          Icons.image,
                          color: colors.onSecondaryContainer,
                        ),
                      ),
                      Gap.hXxs,
                      Text(name, style: AppTypography.labelSm),
                    ],
                  ),
              ],
            ),
            Gap.hMd,

            const Text('List rows', style: AppTypography.labelLg),
            Gap.hXs,
            for (final (name, height) in const [
              ('listItemHeight', AppSizes.listItemHeight),
              ('listItemMinHeight', AppSizes.listItemMinHeight),
            ])
              Container(
                height: height,
                padding: SpacingUtils.horizontal(AppSpacings.wMd),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderUtils.thin(colors.outlineVariant),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: AppSizes.avatarSm / 2,
                      backgroundColor: colors.primaryContainer,
                    ),
                    Gap.wSm,
                    Expanded(
                      child: Text(
                        '$name · ${height.toInt()}',
                        style: AppTypography.bodyMd,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: AppSizes.iconSm),
                  ],
                ),
              ),
            Gap.hMd,

            const Text('Card', style: AppTypography.labelLg),
            Gap.hXs,
            // cardWidth is wider than a phone's content column, so it is the
            // one size that has to be allowed to shrink.
            SizedBox(
              width: AppSizes.cardWidth,
              height: AppSizes.cardHeight,
              child: Card(
                child: Center(
                  child: Text(
                    'cardWidth × cardHeight\n'
                    '${AppSizes.cardWidth.toInt()} × ${AppSizes.cardHeight.toInt()}',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMd,
                  ),
                ),
              ),
            ),
            Gap.hMd,

            const Text('Onboarding illustration', style: AppTypography.labelLg),
            Gap.hXs,
            Container(
              height: AppSizes.onBoard,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: RadiusUtils.all(AppRadius.lg),
                border: Border.fromBorderSide(
                  BorderUtils.thin(colors.outlineVariant),
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: AppSizes.iconXl,
                    color: colors.onSurfaceVariant,
                  ),
                  Gap.hXs,
                  Text(
                    'onBoard · ${AppSizes.onBoard.toInt()} tall',
                    style: AppTypography.labelSm,
                  ),
                ],
              ),
            ),
            Gap.hMd,

            const Text('Dialog', style: AppTypography.labelLg),
            Gap.hXs,
            CustomButton(
              text: 'Open a dialog sized by the tokens',
              type: ButtonType.outlined,
              size: ButtonSize.small,
              onPressed: _showSizedDialog,
            ),
          ],
        ),

        Section(
          title: 'Elevation and shadow',
          api: 'AppElevations',
          children: [
            Wrap(
              spacing: AppSpacings.wSm,
              runSpacing: AppSpacings.hSm,
              children: [
                for (final (name, elevation) in const [
                  ('none', AppElevations.none),
                  ('low', AppElevations.low),
                  ('medium', AppElevations.medium),
                  ('high', AppElevations.high),
                  ('highest', AppElevations.highest),
                ])
                  Material(
                    elevation: elevation,
                    borderRadius: RadiusUtils.all(AppRadius.md),
                    color: colors.surface,
                    child: Padding(
                      padding: SpacingUtils.all(AppSpacings.rSm),
                      child: Text(name, style: AppTypography.labelSm),
                    ),
                  ),
              ],
            ),
            Gap.hMd,
            // Wrap, not Row: the three shadowed boxes do not fit side by side
            // at phone width, and a shadow needs the gap around it anyway.
            Wrap(
              spacing: AppSpacings.wMd,
              runSpacing: AppSpacings.hMd,
              children: [
                for (final (name, shadow) in [
                  ('shadowSm', AppElevations.shadowSm),
                  ('shadowMd', AppElevations.shadowMd),
                  ('shadowLg', AppElevations.shadowLg),
                ])
                  Container(
                    padding: SpacingUtils.all(AppSpacings.rSm),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: RadiusUtils.all(AppRadius.md),
                      boxShadow: shadow,
                    ),
                    child: Text(name, style: AppTypography.labelSm),
                  ),
              ],
            ),
          ],
        ),

        Section(
          title: 'Alpha values',
          api: 'AppOpacities — 0–255, for Color.withAlpha',
          children: [
            Row(
              children: [
                for (final (name, alpha) in [
                  ('extraLow', AppOpacities.extraLow),
                  ('low', AppOpacities.low),
                  ('medium', AppOpacities.medium),
                  ('high', AppOpacities.high),
                ])
                  Expanded(
                    child: Padding(
                      padding: SpacingUtils.onlyRight(AppSpacings.wXxs),
                      child: Column(
                        children: [
                          Container(
                            height: AppSizes.buttonSm,
                            color: colors.primary.withAlpha(alpha),
                          ),
                          Gap.hXxs,
                          Text(
                            '$name\n$alpha',
                            textAlign: TextAlign.center,
                            style: AppTypography.labelSm,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),

        Section(
          title: 'Status palette',
          api: 'AppColors — the fixed, non-branded colours',
          children: [
            Wrap(
              spacing: AppSpacings.wSm,
              runSpacing: AppSpacings.hSm,
              children: [
                for (final (name, color) in const [
                  ('success', AppColors.success),
                  ('warning', AppColors.warning),
                  ('info', AppColors.info),
                  ('error', AppColors.error),
                  ('promotion', AppColors.promotion),
                ])
                  Chip(
                    backgroundColor: color,
                    label: Text(
                      name,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),

        Section(
          title: 'Durations',
          api: 'AppDurations — tap a value to animate at it',
          children: [
            Wrap(
              spacing: AppSpacings.wXs,
              children: [
                for (final (name, duration) in const [
                  ('fast', AppDurations.fast),
                  ('normal', AppDurations.normal),
                  ('slow', AppDurations.slow),
                  ('shimmer', AppDurations.shimmer),
                  ('splash', AppDurations.splash),
                ])
                  ChoiceChip(
                    label: Text('$name · ${duration.inMilliseconds}ms'),
                    selected: _duration == duration,
                    onSelected: (_) => setState(() => _duration = duration),
                  ),
              ],
            ),
            Gap.hSm,
            // Align, because this Section's Column stretches its children:
            // that hands them a tight width, which overrides the box's own and
            // left it full width in both states — the tap changed nothing you
            // could see. Align passes loose constraints instead.
            //
            // The expanded width also has to be a real number: a tween cannot
            // interpolate towards double.infinity, and the first animated
            // frame asserts on the infinite constraint. LayoutBuilder turns
            // "as wide as this row allows" into that number.
            Align(
              alignment: Alignment.centerLeft,
              child: LayoutBuilder(
                builder: (context, constraints) => GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: AnimatedContainer(
                    duration: _duration,
                    curve: Curves.easeInOut,
                    height: AppSizes.buttonMd,
                    width: _expanded
                        ? constraints.maxWidth
                        : AppSizes.thumbnailMd,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: RadiusUtils.all(AppRadius.md),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'tap me',
                      style: AppTypography.labelLg.copyWith(
                        color: colors.onPrimary,
                      ),
                    ),
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
