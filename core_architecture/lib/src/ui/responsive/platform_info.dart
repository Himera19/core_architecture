import 'package:flutter/foundation.dart';

/// Provides information about the current platform.
///
/// Useful for making platform-specific decisions in shared code.
///
/// ```dart
/// if (PlatformInfo.isWeb) {
///   // Use web-specific storage
/// } else {
///   // Use secure storage
/// }
/// ```
final class PlatformInfo {
  PlatformInfo._();

  /// Whether the app is running on the web.
  static bool get isWeb => kIsWeb;

  /// Whether the app is running on a mobile device (Android or iOS).
  static bool get isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Whether the app is running on a desktop (Windows, macOS, Linux).
  static bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  /// Whether the app is running on Android.
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Whether the app is running on iOS.
  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Whether the app is running on Windows.
  static bool get isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  /// Whether the app is running on macOS.
  static bool get isMacOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  /// Whether the app is running on Linux.
  static bool get isLinux =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

  /// Returns a human-readable platform name.
  static String get platformName {
    if (kIsWeb) return 'Web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.fuchsia => 'Fuchsia',
    };
  }
}
