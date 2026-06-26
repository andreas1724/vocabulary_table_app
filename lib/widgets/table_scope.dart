import 'package:flutter/material.dart';
import 'package:vocabulary_table_app/controller/app_mode_controller.dart';
import 'package:vocabulary_table_app/controller/orientation_controller.dart';

class TableScope extends InheritedWidget {
  const TableScope({
    super.key,
    required this.orientationController,
    required this.appModeController,
    required super.child,
  });

  final OrientationController orientationController;
  final AppModeController appModeController;

  static TableScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TableScope>();
    if (scope == null) {
      throw StateError('TableScope missing in context tree.');
    }
    return scope;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}