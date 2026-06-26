import 'dart:ui';

import 'package:flutter/material.dart';

class WindowMetricsService with WidgetsBindingObserver {
  WindowMetricsService({required this.onLayoutChanged});

  final void Function({required bool isLandscape}) onLayoutChanged;

  void init() {
    WidgetsBinding.instance.addObserver(this);
    _checkAndNotify();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _checkAndNotify();
  }

  void _checkAndNotify() {
    final view = PlatformDispatcher.instance.implicitView;
    if (view == null) return;

    final logicalSize = view.physicalSize / view.devicePixelRatio;

    final isLandscapeLayout =
        logicalSize.width > 1.25 * logicalSize.height &&
        logicalSize.height < 500;

    onLayoutChanged(isLandscape: isLandscapeLayout);
  }
}