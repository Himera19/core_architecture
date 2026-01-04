import 'package:flutter_screenutil/flutter_screenutil.dart';

final class AppSizes {
  AppSizes._();

  // Icon sizes
  static double get iconXxs => 4.h;
  static double get iconXs => 8.h;
  static double get iconSm => 16.h;
  static double get iconMd => 24.h;
  static double get iconLg => 32.h;
  static double get iconXl => 64.h;
  static double get iconXxl => 128.h;

  // Button heights
  static double get buttonSm => 40.h;
  static double get buttonMd => 48.h;
  static double get buttonLg => 56.h;

  // Inputs
  static double get inputHeight => 56.h;

  // Cards
  static double get cardWidth => 300.w;
  static double get cardHeight => 180.h;

  // Dialogs
  static double get dialogMaxWidth => 500.w;
  static double get dialogButtonWidth => 120.w;
  static double get dialogMaxHeight => 600.h;
  static double get dialogMaxHeightLarge => 700.h;

  // Lists
  static double get listItemHeight => 80.h;
  static double get listItemMinHeight => 60.h;

  // Handles (drag handles, etc.)
  static double get handleWidth => 40.w;
  static double get handleHeight => 4.h;

  // Avatar/Profile
  static double get avatarSm => 32.h;
  static double get avatarMd => 48.h;
  static double get avatarLg => 64.h;

  // Thumbnails
  static double get thumbnailSm => 60.h;
  static double get thumbnailMd => 100.h;
  static double get thumbnailLg => 150.h;

  // Thumbnails
  static double get onBoard => 250.h;
}