import 'package:flutter/material.dart';

/// Provides the current row index down the widget tree to avoid prop-drilling.
class RowIndexScope extends InheritedWidget {
  const RowIndexScope({
    super.key,
    required this.rowIndex,
    required super.child,
  });

  final int rowIndex;

  static int of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RowIndexScope>();
    assert(scope != null, 'No RowIndexScope found in context');
    return scope!.rowIndex;
  }

  @override
  bool updateShouldNotify(RowIndexScope oldWidget) =>
      rowIndex != oldWidget.rowIndex;
}
