import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'dart:math' show log, ln2;

/// The minimum width of a column as a fraction of the total row width.
const _minColumnRatio = 0.05;

enum AppMode { edit, play }

extension AppModeX on AppMode {
  String get title => switch (this) {
    .edit => 'Edit',
    .play => 'Play (TTS)',
  };

  IconData get icon => switch (this) {
    .edit => Icons.edit,
    .play => Icons.play_arrow,
  };
}

class TableLayoutController {
  static const fontSize = 14.0;

  static const minScale = 0.5;
  static const maxScale = 2.0;

  /// For use in Slider (2^minScaleExp = minScale).
  static final minScaleExp = log(minScale) / ln2;

  /// For use in Slider (2^maxScaleExp = maxScale).
  static final maxScaleExp = log(maxScale) / ln2;

  static const _initialScale = 1.0;

  static const _standardBorderWidth = 1.0;

  final scale = signal(_initialScale);
  double _baseScale = _initialScale;

  final appMode = signal<AppMode>(.edit);

  late final borderWidth = computed(() => scale.value * _standardBorderWidth);

  final _ratio1 = signal(1.0 / 3.0);
  final _ratio2 = signal(1.0 / 3.0);
  final _savedRatio3 = signal(1.0 / 3.0);
  final _showComment = signal(true);

  late final showComment = _showComment.readonly();

  // COMPUTED SIGNALS: Let the controller do the math, keep the UI dumb!
  late final col1Ratio = computed(() => _ratio1.value);

  // If comment is hidden, column 2 takes the remaining space.
  late final col2Ratio = computed(
    () => _showComment.value ? _ratio2.value : 1.0 - _ratio1.value,
  );

  // If comment is hidden, its ratio is effectively 0 for the UI.
  late final col3Ratio = computed(
    () => _showComment.value ? (1.0 - _ratio1.value - _ratio2.value) : 0.0,
  );

  void dispose() {
    scale.dispose();
    borderWidth.dispose();
    appMode.dispose();
    _ratio1.dispose();
    _ratio2.dispose();
    _showComment.dispose();
    _savedRatio3.dispose();
    col1Ratio.dispose();
    col2Ratio.dispose();
    col3Ratio.dispose();
  }

  /// Call in GestureDetectors onScaleStart.
  void scaleStart() {
    _baseScale = scale.peek();
  }

  /// Call in GestureDetectors onScaleUpdate.
  void scaleUpdate(double factor) {
    final newScale = _baseScale * factor;
    scale.value = newScale.clamp(minScale, maxScale);
  }

  void toggleComment() {
    final isShowing = _showComment.peek();
    final r1 = _ratio1.peek();
    final r2 = _ratio2.peek();

    batch(() {
      _showComment.value = !isShowing;

      if (isShowing) {
        // HIDING COMMENT
        final currentR3 = 1.0 - r1 - r2;
        // Securely save the ratio, ensuring it respects our min limits
        _savedRatio3.value = currentR3.clamp(_minColumnRatio, 1.0);

        // Scale up r1 and r2 proportional to fill the whole 1.0 space.
        // Since r1 + r2 is guaranteed to be > 0 by minColumnRatio, this is perfectly safe.
        final factor = 1.0 / (r1 + r2);
        _ratio1.value = r1 * factor;
        _ratio2.value = r2 * factor;
      } else {
        // SHOWING COMMENT
        final r3 = _savedRatio3.peek();

        // Scale down r1 and r2 to make room for the saved r3.
        final factor = 1.0 - r3;
        _ratio1.value = r1 * factor;
        _ratio2.value = r2 * factor;
      }
    });
  }

  void updateFirstHandle(double targetRatio) {
    final r1 = _ratio1.peek();
    final r2 = _ratio2.peek();
    final combined = r1 + r2;

    final clampedR1 = targetRatio.clamp(
      _minColumnRatio,
      combined - _minColumnRatio,
    );

    batch(() {
      _ratio1.value = clampedR1;
      _ratio2.value = combined - clampedR1;
    });
  }

  void updateSecondHandle(double targetRatio) {
    final r1 = _ratio1.peek();

    final clampedBoundary = targetRatio.clamp(
      r1 + _minColumnRatio,
      1.0 - _minColumnRatio,
    );

    _ratio2.value = clampedBoundary - r1;
  }
}

@visibleForTesting
extension TableLayoutControllerTestingX on TableLayoutController {
  void setRatios({required double col1Ratio, required double col2Ratio}) {
    _ratio1.value = col1Ratio;
    _ratio2.value = col2Ratio;
  }

  void setShowComment(bool value) {
    _showComment.value = value;
  }
}
