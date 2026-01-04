import 'package:flutter/widgets.dart';
import 'package:core_architecture/core_architecture.dart';

final class Gap {
  Gap._();

  static SizedBox get xXs => SizedBox(height: AppSpacings.hXxs);
  static SizedBox get xs => SizedBox(height: AppSpacings.hXs);
  static SizedBox get sm => SizedBox(height: AppSpacings.hSm);
  static SizedBox get md => SizedBox(height: AppSpacings.hMd);
  static SizedBox get lg => SizedBox(height: AppSpacings.hLg);
  static SizedBox get xl => SizedBox(height: AppSpacings.hXl);
  static SizedBox get xxl => SizedBox(height: AppSpacings.hXxl);
}
