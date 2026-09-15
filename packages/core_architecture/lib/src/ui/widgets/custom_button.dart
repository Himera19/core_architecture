import 'package:flutter/material.dart';

import '../themes/core_components_theme.dart';
import '../tokens/app_borders.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_sizes.dart';
import '../tokens/app_spacings.dart';
import '../../utils/extensions/context_extensions.dart';
import '../../utils/spacing_utils.dart';

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

  /// Shown in place of the label while [isLoading].
  ///
  /// Defaults to a [CircularProgressIndicator] tinted to this button's own
  /// foreground. The package deliberately ships no animation library, so an
  /// app that wants a different spinner — flutter_spinkit, Lottie, a brand
  /// animation — passes it here and keeps that dependency to itself:
  ///
  /// ```dart
  /// CustomButton(
  ///   text: 'Save',
  ///   isLoading: saving,
  ///   loadingIndicator: SpinKitPulse(color: Colors.white, size: 24),
  ///   onPressed: save,
  /// );
  /// ```
  ///
  /// Give it a bounded size: the button is only as tall as its [size].
  final Widget? loadingIndicator;

  /// Whether the button takes the full width it is offered.
  ///
  /// True is the shape most screens want — a button at the bottom of a form.
  /// It used to be the only shape, which made two buttons side by side
  /// impossible without wrapping each in an [Expanded] and left
  /// `mainAxisSize.min` rows stretched to the edge of the screen. Pass false
  /// to size to the label instead:
  ///
  /// ```dart
  /// Row(
  ///   children: [
  ///     CustomButton(text: 'Cancel', fullWidth: false, type: ButtonType.outlined, onPressed: back),
  ///     Gap.wSm,
  ///     CustomButton(text: 'Save', fullWidth: false, onPressed: save),
  ///   ],
  /// );
  /// ```
  final bool fullWidth;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.loadingIndicator,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colorScheme;
    final TextTheme textTheme = context.textTheme;

    final double resolvedHeight = _resolveHeight(size);

    final _ButtonStyles style = _resolveStyle(type, colors);

    return SizedBox(
      height: resolvedHeight,
      // Null, not zero: an unset width lets the button size to its label,
      // where `double.infinity` forced every one of them edge to edge.
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        // Null, not an empty callback: a loading button used to stay enabled
        // as far as Material was concerned — it rippled, showed a click
        // cursor, and answered to the keyboard, while doing nothing.
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: style.background,
          foregroundColor: style.foreground,
          // Loading is not the same as disabled: the button keeps its own
          // colours so the spinner stays legible on them, and only stops
          // accepting input. A button disabled by a null onPressed still
          // greys out the usual way, because these are then left unset.
          disabledBackgroundColor: isLoading ? style.background : null,
          disabledForegroundColor: isLoading ? style.foreground : null,
          // AppRadius.lg, matching what AppTheme gives every Material button.
          // This used to be AppRadius.md, so a CustomButton and a FilledButton
          // on the same screen had different corners.
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
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
    // Get the button style to use the correct foreground color
    final _ButtonStyles buttonStyle = _resolveStyle(type, colors);

    if (isLoading) {
      // Narrowest wins: this button's own widget, then the app-wide builder
      // on the theme, then Material's spinner.
      final LoadingIndicatorBuilder? fromTheme =
          CoreComponentsTheme.maybeOf(context)?.loadingIndicatorBuilder;

      return loadingIndicator ??
          fromTheme?.call(context, buttonStyle.foreground) ??
          SizedBox(
            height: AppSizes.iconMd,
            width: AppSizes.iconMd,
            child: CircularProgressIndicator(
              strokeWidth: AppBorders.normal,
              // The button's own foreground, not onPrimary: an outlined
              // button has a transparent background, where an onPrimary
              // spinner is white on white.
              color: buttonStyle.foreground,
            ),
          );
    }

    // No fontFamily here: labelLarge already carries the theme font, and
    // stamping one would override AppTheme(fontFamily: ...).
    final TextStyle? style = textTheme.labelLarge?.copyWith(
      color: buttonStyle.foreground,
    );

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconSm, color: style?.color),
          const SizedBox(width: AppSpacings.wSm),
          // Flexible, and ellipsized: the button is full width, but a label
          // longer than that width has nothing to give in a `mainAxisSize.min`
          // Row, so it overflowed the button instead of being trimmed.
          Flexible(
            child: Text(
              text,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
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
