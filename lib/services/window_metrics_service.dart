import 'dart:ui';

import 'package:flutter/material.dart';

/// The minimum width-to-height aspect ratio required to switch to landscape mode.
const _landscapeThreshold = 1.25;

/// The height threshold in logical pixels above which the app
/// automatically forces portrait mode, regardless of the aspect ratio.
const _portraitHeightThreshold = 500.0; // iPhone 15 Pro Max: 430 pt (x 932 pt)

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
        logicalSize.width > _landscapeThreshold * logicalSize.height &&
        logicalSize.height < _portraitHeightThreshold;
    onLayoutChanged(isLandscape: isLandscapeLayout);
  }
}
