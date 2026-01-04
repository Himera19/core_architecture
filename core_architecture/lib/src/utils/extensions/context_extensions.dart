import 'package:flutter/material.dart';
import 'package:core_architecture/core_architecture.dart' show AppTypography;

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;

  void showSuccess(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontFamily: AppTypography.fontFamily),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showError(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontFamily: AppTypography.fontFamily),
        ),
        backgroundColor: colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showInfo(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontFamily: AppTypography.fontFamily),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
