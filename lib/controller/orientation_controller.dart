import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/services/window_metrics_service.dart';

class OrientationController {
  OrientationController() {
    _windowMetricsService = WindowMetricsService(
      onLayoutChanged: ({required isLandscape}) {
        if (_isLandscape.peek() != isLandscape) {
          _isLandscape.value = isLandscape;
        }
      },
    );
  }
  late final WindowMetricsService _windowMetricsService;
  final _isLandscape = signal(false);

  late final isLandscape = _isLandscape.readonly();

  void init() => _windowMetricsService.init();

  void dispose() {
    _isLandscape.dispose();
    _windowMetricsService.dispose();
  }
}
