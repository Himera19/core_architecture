import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_colors.dart';

final class AppTypography {
  AppTypography._();

  // MAIN FONT
  static const String fontFamily = "Rubik";

  // DISPLAY
  static TextStyle get displayLg => TextStyle(
    fontSize: 57.sp,
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get displayMd => TextStyle(
    fontSize: 45.sp,
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get displaySm => TextStyle(
    fontSize: 36.sp,
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimaryLight,
  );

  // HEADLINE
  static TextStyle get headlineLg => TextStyle(
    fontSize: 32.sp,
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get headlineMd => TextStyle(
    fontSize: 28.sp,
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get headlineSm => TextStyle(
    fontSize: 24.sp,
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryLight,
  );

  // TITLE
  static TextStyle get titleLg => TextStyle(
    fontSize: 22.sp,
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get titleMd => TextStyle(
    fontSize: 16.sp,
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get titleSm => TextStyle(
    fontSize: 14.sp,
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimaryLight,
  );

  // BODY
  static TextStyle get bodyLg => TextStyle(
    fontSize: 16.sp,
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get bodyMd => TextStyle(
    fontSize: 14.sp,
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get bodySm => TextStyle(
    fontSize: 12.sp,
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimaryLight,
  );

  // LABEL
  static TextStyle get labelLg => TextStyle(
    fontSize: 14.sp,
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get labelMd => TextStyle(
    fontSize: 12.sp,
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimaryLight,
  );

  static TextStyle get labelSm => TextStyle(
    fontSize: 11.sp,
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimaryLight,
  );
}
