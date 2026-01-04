import 'package:flutter/material.dart';
import 'package:core_architecture/core_architecture.dart';

final class BorderUtils {
  BorderUtils._();

  static BorderSide thin(Color color) =>
      BorderSide(width: AppBorders.thin, color: color);

  static BorderSide normal(Color color) =>
      BorderSide(width: AppBorders.normal, color: color);

  static BorderSide thick(Color color) =>
      BorderSide(width: AppBorders.thick, color: color);
}
