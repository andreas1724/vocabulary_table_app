import 'package:flutter/material.dart';

/// Provides the current row index down the widget tree to avoid prop-drilling.
class RowIndexScope extends InheritedWidget {
  const RowIndexScope({
    super.key,
    required this.uiIndex,
    required this.globalIndex,
    required super.child,
  });

  final int uiIndex;
  final int globalIndex;

  static RowIndexScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RowIndexScope>();
    assert(scope != null, 'No RowIndexScope found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(RowIndexScope oldWidget) =>
      uiIndex != oldWidget.uiIndex || globalIndex != oldWidget.globalIndex;
}
