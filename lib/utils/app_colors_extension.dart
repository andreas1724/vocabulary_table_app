import 'package:flutter/material.dart';

class AppColors {
  const AppColors(this._theme);
  
  final ThemeData _theme;

  Color get borderColor => _theme.colorScheme.outlineVariant;
}

extension AppColorsExtension on BuildContext {
  AppColors get colors => AppColors(Theme.of(this));
}