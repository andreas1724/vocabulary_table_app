import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:vocabulary_table_app/app_constants.dart';

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
        logicalSize.width > AppDimens.landscapeThreshold * logicalSize.height &&
        logicalSize.height < AppDimens.portraitHeightThreshold;

    onLayoutChanged(isLandscape: isLandscapeLayout);
  }
}
