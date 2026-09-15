import 'package:flutter/material.dart';

/// Builds the widget shown while something is loading.
///
/// [color] is the foreground of the control asking for it — a button's own
/// label colour — so one builder can serve every [ButtonType] without the app
/// having to branch on it.
typedef LoadingIndicatorBuilder =
    Widget Function(BuildContext context, Color color);

/// App-wide defaults for the package's own widgets, carried on [ThemeData].
///
/// The package ships no animation library, so a spinner is the app's choice.
/// Passing `loadingIndicator:` to every [CustomButton] makes that choice one
/// call site at a time; setting it here makes it once:
///
/// ```dart
/// MaterialApp(
///   theme: AppTheme.light(
///     brandColor: myPurple,
///     loadingIndicatorBuilder: (context, color) =>
///         SpinKitPulse(color: color, size: AppSizes.iconMd),
///   ),
/// );
/// ```
///
/// A widget's own `loadingIndicator` still wins over this, and with neither
/// set the fallback is Material's [CircularProgressIndicator].
@immutable
class CoreComponentsTheme extends ThemeExtension<CoreComponentsTheme> {
  const CoreComponentsTheme({this.loadingIndicatorBuilder});

  /// The app-wide loading indicator, or null to keep the Material default.
  final LoadingIndicatorBuilder? loadingIndicatorBuilder;

  /// The extension on [context]'s theme, or `null` when none was installed.
  static CoreComponentsTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<CoreComponentsTheme>();

  @override
  CoreComponentsTheme copyWith({
    LoadingIndicatorBuilder? loadingIndicatorBuilder,
  }) {
    return CoreComponentsTheme(
      loadingIndicatorBuilder:
          loadingIndicatorBuilder ?? this.loadingIndicatorBuilder,
    );
  }

  /// A builder is a function, and functions do not interpolate. The animation
  /// snaps to [other] at the halfway point rather than pretending otherwise —
  /// which is also what a theme swap looks like in practice.
  @override
  CoreComponentsTheme lerp(CoreComponentsTheme? other, double t) {
    if (other == null) return this;
    return t < 0.5 ? this : other;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreComponentsTheme &&
          other.loadingIndicatorBuilder == loadingIndicatorBuilder;

  @override
  int get hashCode => loadingIndicatorBuilder.hashCode;
}
