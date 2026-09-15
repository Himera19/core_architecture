import 'package:flutter/material.dart';

import '../ui/tokens/app_borders.dart';

final class BorderUtils {
  BorderUtils._();

  static BorderSide thin(Color color) => BorderSide(color: color);

  static BorderSide normal(Color color) =>
      BorderSide(width: AppBorders.normal, color: color);

  static BorderSide thick(Color color) =>
      BorderSide(width: AppBorders.thick, color: color);
}
