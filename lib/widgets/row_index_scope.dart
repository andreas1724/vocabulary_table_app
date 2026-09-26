import 'package:flutter/material.dart';

/// Provides the current row index down the widget tree to avoid prop-drilling.
class RowIndexScope extends InheritedWidget {
  const RowIndexScope({super.key, required this.row, required super.child});

  final ({int globalIndex, int uiIndex}) row;

  static RowIndexScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RowIndexScope>();
  }

  static ({int globalIndex, int uiIndex}) of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RowIndexScope>();
    assert(scope != null, 'No RowIndexScope found in context');
    return scope!.row;
  }

  @override
  bool updateShouldNotify(RowIndexScope oldWidget) => row != oldWidget.row;
}
