import 'package:flutter/material.dart';

import '../tokens/app_borders.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_sizes.dart';
import '../tokens/app_spacings.dart';
import '../tokens/app_typography.dart';
import '../../utils/extensions/context_extensions.dart';
import '../../utils/spacing_utils.dart';
import '../../utils/spin_kit_indicator.dart';

/// Button visual styles
enum ButtonType { primary, secondary, outlined, danger }

/// Button size presets
enum ButtonSize { small, medium, large }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  final ButtonType type;
  final ButtonSize size;
  final bool isLoading;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colorScheme;
    final TextTheme textTheme = context.textTheme;

    final double resolvedHeight = _resolveHeight(size);

    final _ButtonStyles style = _resolveStyle(type, colors);

    return SizedBox(
      height: resolvedHeight,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? () {} : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: style.background,
          foregroundColor: style.foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: style.border,
          ),
          padding:
              SpacingUtils.horizontal(AppSpacings.wMd) +
              SpacingUtils.vertical(AppSpacings.hSm),
        ),
        child: _buildContent(textTheme, colors, context),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Resolve button height
  double _resolveHeight(ButtonSize size) {
    return switch (size) {
      ButtonSize.small => AppSizes.buttonSm,
      ButtonSize.medium => AppSizes.buttonMd,
      ButtonSize.large => AppSizes.buttonLg,
    };
  }

  // ---------------------------------------------------------------------------
  // Resolve button content
  Widget _buildContent(
    TextTheme textTheme,
    ColorScheme colors,
    BuildContext context,
  ) {
    if (isLoading) {
      return SpinKitIndicator.onPrimaryColored(context, size: AppSpacings.hLg);
    }

    // Get the button style to use the correct foreground color
    final _ButtonStyles buttonStyle = _resolveStyle(type, colors);

    final TextStyle? style = textTheme.labelLarge?.copyWith(
      color: buttonStyle.foreground,
      fontFamily: AppTypography.fontFamily,
    );

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconSm, color: style?.color),
          const SizedBox(width: AppSpacings.wSm),
          Text(text, style: style),
        ],
      );
    }

    return Text(text, style: style);
  }

  // ---------------------------------------------------------------------------
  // Resolve visual style for each ButtonType
  _ButtonStyles _resolveStyle(ButtonType type, ColorScheme colors) {
    switch (type) {
      case ButtonType.primary:
        return _ButtonStyles(
          background: colors.primary,
          foreground: colors.onPrimary,
          border: BorderSide.none,
        );

      case ButtonType.secondary:
        return _ButtonStyles(
          background: colors.secondary,
          foreground: colors.onSecondary,
          border: BorderSide.none,
        );

      case ButtonType.outlined:
        return _ButtonStyles(
          background: Colors.transparent,
          foreground: colors.primary,
          border: BorderSide(color: colors.primary, width: AppBorders.normal),
        );

      case ButtonType.danger:
        return _ButtonStyles(
          background: colors.error,
          foreground: colors.onError,
          border: BorderSide.none,
        );
    }
  }
}

// Internal styling model
class _ButtonStyles {
  final Color background;
  final Color foreground;
  final BorderSide border;

  const _ButtonStyles({
    required this.background,
    required this.foreground,
    required this.border,
  });
}
