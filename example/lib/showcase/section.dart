import 'package:core_architecture/core_architecture.dart';
import 'package:flutter/material.dart';

/// One titled block of a showcase screen.
///
/// Every showcase page is a column of these, so the pages stay a list of
/// "here is the API, here is it running" pairs rather than bespoke layouts.
class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.title,
    required this.api,
    required this.children,
  });

  /// What the block demonstrates, in plain words.
  final String title;

  /// The exact package member being exercised, shown so the screen doubles as
  /// a reference.
  final String api;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colorScheme;

    return Padding(
      padding: SpacingUtils.onlyBottom(AppSpacings.hLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTypography.titleMd),
          Gap.hXxs,
          Text(
            api,
            style: AppTypography.bodySm.copyWith(color: colors.onSurfaceVariant),
          ),
          Gap.hSm,
          Container(
            padding: SpacingUtils.all(AppSpacings.rMd),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: RadiusUtils.all(AppRadius.lg),
              border: Border.fromBorderSide(BorderUtils.thin(colors.outline)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// A label/value row, for the many APIs whose output is just a string.
class Readout extends StatelessWidget {
  const Readout(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: SpacingUtils.onlyBottom(AppSpacings.hXxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppSizes.thumbnailMd,
            child: Text(
              label,
              style: AppTypography.bodySm.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Gap.wSm,
          Expanded(child: Text(value, style: AppTypography.bodyMd)),
        ],
      ),
    );
  }
}

/// Wraps a showcase page in the padding and scrolling every one of them wants.
class ShowcasePage extends StatelessWidget {
  const ShowcasePage({super.key, required this.title, required this.sections});

  final String title;
  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          // The page margin follows the breakpoint rather than a fixed value.
          padding: SpacingUtils.all(
            ResponsiveSpacings.pagePadding.resolve(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: sections,
          ),
        ),
      ),
    );
  }
}
