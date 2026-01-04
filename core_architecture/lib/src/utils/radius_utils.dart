import 'package:flutter/material.dart';
import 'package:core_architecture/core_architecture.dart';

final class RadiusUtils {
  RadiusUtils._();

  static BorderRadius all(double value) => BorderRadius.circular(value);

  static BorderRadius only({
    double topLeft = 0,
    double topRight = 0,
    double bottomLeft = 0,
    double bottomRight = 0,
  }) =>
      BorderRadius.only(
        topLeft: Radius.circular(topLeft),
        topRight: Radius.circular(topRight),
        bottomLeft: Radius.circular(bottomLeft),
        bottomRight: Radius.circular(bottomRight),
      );

  static BorderRadius get topMd =>
      BorderRadius.vertical(top: Radius.circular(AppRadius.md));

  static BorderRadius get bottomMd =>
      BorderRadius.vertical(bottom: Radius.circular(AppRadius.md));
}
