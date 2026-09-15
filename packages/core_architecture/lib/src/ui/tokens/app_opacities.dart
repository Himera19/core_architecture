// lib/src/ui/tokens/app_opacities.dart

/// Alpha values (0–255) for use with [Color.withAlpha].
/// These are NOT opacity fractions (0.0–1.0).
final class AppOpacities {
  AppOpacities._();

  static int get extraLow => 30;
  static int get low => 80;
  static int get medium => 160;
  static int get high => 255;
}
