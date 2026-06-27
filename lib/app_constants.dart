import 'package:flutter/material.dart';

class AppDimens {
  const AppDimens._();

  /// Minimum scale factor for table.
  static const minScale = 0.5;

  /// Maximum scale factor for table.
  static const maxScale = 2.0;

  /// Size for the drag area between columns.
  static const dragHandleWidth = 48.0;

  /// The height threshold in logical pixels above which the app
  /// automatically forces portrait mode, regardless of the aspect ratio.
  static const double portraitHeightThreshold = 500.0;

  /// The minimum width-to-height aspect ratio required to switch to landscape mode.
  static const landscapeThreshold = 1.25;

  /// The minimum width of a column as a fraction of the total row width.
  static const double minColumnRatio = 0.05;
}

class AppColors {
  const AppColors._();

  /// Color of table borders.
  static const borderColor = Colors.black54;
}
